"""External CPython-AST reference for the three bounded repair rules."""
import json
import sys


def repair(folder, public, expanded_search):
    import ast
    import copy
    from itertools import combinations
    from pathlib import Path

    root = Path(folder)
    experiments = Path(__file__).resolve().parent.parent
    sys.path.insert(0, str(experiments / "60_reparaturzeit"))
    from cpython_comparison import MODULES, agrees, alternatives, first_failure, load, patch, variant

    sources = {name: (root / name).read_text() for name in MODULES}
    trees = {name: ast.parse(src, name) for name, src in sources.items()}
    program = {name: compile(tree, name, "exec") for name, tree in trees.items()}
    witness, visited = first_failure(load(program), public)
    functions = {(file, fn.name): fn for file, tree in trees.items() for fn in tree.body
                 if isinstance(fn, ast.FunctionDef)}
    scope = {file: {name: fn for (module, name), fn in functions.items() if module == file}
             for file in MODULES}
    for file, tree in trees.items():
        for item in tree.body:
            if isinstance(item, ast.ImportFrom):
                for alias in item.names:
                    fn = functions.get((str(item.module) + ".py", alias.name))
                    if fn:
                        scope[file][alias.asname or alias.name] = fn

    def text_value(expr, formals, names):
        if isinstance(expr, ast.Constant):
            return isinstance(expr.value, str)
        if isinstance(expr, ast.Name):
            return formals.get(expr.id) == "str"
        if isinstance(expr, ast.JoinedStr):
            return True
        if isinstance(expr, ast.Call) and isinstance(expr.func, ast.Name):
            fn = names.get(expr.func.id)
            return bool(fn and fn.returns and ast.unparse(fn.returns) == "str")
        if isinstance(expr, ast.Subscript) and isinstance(expr.slice, ast.Slice):
            return text_value(expr.value, formals, names)
        return False

    def expanded():
        for file, fn_name in visited:
            fn = functions[file, fn_name]
            formals = {arg.arg: ast.unparse(arg.annotation) for arg in fn.args.args if arg.annotation}
            names = scope[file]
            for node in ast.walk(fn):
                if not isinstance(node, ast.Call) or node.keywords:
                    continue
                ident = f"{file}:{node.lineno}:{node.col_offset+1}:{node.end_lineno}:{node.end_col_offset+1}"
                args = node.args
                changes = []
                if isinstance(node.func, ast.Name) and node.func.id in names:
                    params = names[node.func.id].args.args
                    if len(params) == len(args):
                        for a,b in combinations(range(len(args)),2):
                            left, right = params[a].annotation, params[b].annotation
                            if (left is None or right is None or ast.dump(left) != ast.dump(right)
                                    or ast.dump(args[a]) == ast.dump(args[b])):
                                continue
                            swapped = list(args)
                            swapped[a],swapped[b] = args[b],args[a]
                            changes.append(ast.unparse(ast.Call(node.func,swapped,[])))
                elif (isinstance(node.func, ast.Name) and node.func.id == "len" and len(args) == 1
                        and text_value(args[0],formals,names)):
                    encoded = ast.Call(ast.Attribute(args[0],"encode",ast.Load()),[ast.Constant("utf-8")],[])
                    changes.append(ast.unparse(ast.Call(node.func,[encoded],[])))
                elif (isinstance(node.func, ast.Attribute) and node.func.attr == "find"
                        and text_value(node.func.value,formals,names)
                        and (len(args) == 1 or (len(args) == 2 and isinstance(args[1],ast.Constant) and args[1].value == 0))):
                    changes.append(ast.unparse(ast.Call(ast.Attribute(node.func.value,"rfind",ast.Load()),args[:1],[])))
                for text in changes:
                    yield file, {"node":ident,"kind":"replace","text":text},node,None

    options = []
    singles, pairs = [], []
    truncated = [False,False]
    pair_checks = 0
    def singles_pass(items, extended):
        for file,edit,node,operator in items:
            if len(options) == 32:
                truncated[0] = True
                return
            changed = variant(trees[file],file,node,edit,operator)
            options.append((file,edit,node,changed,extended))
            entry = load(program | {file:changed})
            if all(agrees(entry,c) for c in public):
                singles.append([edit])
    singles_pass(alternatives(trees,visited),False)
    if expanded_search and not singles and not truncated[0]:
        singles_pass(expanded(),True)
    if not singles and not truncated[0]:
        for extended in ((False,True) if expanded_search else (False,)):
            for a,b in combinations(options,2):
                if a[0] == b[0] or (a[4] or b[4]) != extended:
                    continue
                if pair_checks == 64:
                    truncated[1] = True
                    break
                pair_checks += 1
                entry = load(program | {a[0]:a[3],b[0]:b[3]})
                if all(agrees(entry,c) for c in public):
                    pairs.append([a[1],b[1]])
            if pairs or truncated[1]:
                break
    candidates = singles or pairs

    def order(edit):
        file,line,col,*_ = edit["node"].split(":")
        text = {"//":"div","%":"mod","==":"eq"}.get(edit["text"],edit["text"])
        return file.split(".")[0],int(line),int(col),text

    candidates.sort(key=lambda es: sorted(map(order,es)))
    chosen = candidates[0] if candidates else []
    updated = dict(sources)
    for edit in chosen:
        file = edit["node"].split(":")[0]
        if edit["kind"] == "op":
            updated[file] = patch(root,edit)["source"]
        else:
            target = next(o[2] for o in options if o[1] == edit)
            new = ast.parse(edit["text"],mode="eval").body
            updated[file] = ast.unparse(ast.fix_missing_locations(copy.deepcopy(trees[file], {id(target):new}))) + "\n"
    if chosen:
        entry = load({file:compile(src,file,"exec") for file,src in updated.items()})
        assert all(agrees(entry,c) for c in public)
        for file,source in updated.items():
            if source != sources[file]:
                (root / file).write_text(source)
    def compact(edit):
        return {"node":edit["node"],edit["kind"]:edit["text"]}
    return {**witness,"tested":[len(options),pair_checks],"truncated":truncated,
            "candidates":[list(map(compact,edits)) for edits in candidates],
            "edits":list(map(compact,chosen))}


if __name__ == "__main__":
    mode,folder = sys.argv[1:]
    data = json.load(sys.stdin)
    if mode == "accept":
        sys.path.insert(0,folder)
        from panel import main
        result = all(type(value := main(**row["inputs"])) is int and value == row["expect"] for row in data)
    else:
        result = repair(folder,data,mode == "after")
    print(json.dumps(result,separators=(",",":")))
