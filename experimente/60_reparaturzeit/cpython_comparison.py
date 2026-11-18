"""External CPython-AST arm for the three-file repair benchmark."""
import ast
import copy
import json
import pathlib
import sys
import types

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "55_knotenreparatur"))
from cpython_ast import expression_sites, patch, small_replacements


MODULES = ("rulebook.py", "route.py", "panel.py")


def load(program):
    modules = {}
    try:
        for name, code in program.items():
            module = types.ModuleType(name.removesuffix(".py"))
            modules[module.__name__] = sys.modules[module.__name__] = module
            exec(code, module.__dict__)
        return modules["panel"].main
    finally:
        for name in modules:
            del sys.modules[name]


def agrees(entry, case):
    try:
        value = entry(**case["inputs"])
        return type(value) is int and value == case["expect"]
    except ArithmeticError:
        return False


def first_failure(entry, public):
    visited = {}

    def capture(frame, event, _):
        code = frame.f_code
        if event == "call" and code.co_filename in MODULES:
            visited[(code.co_filename, code.co_name)] = None

    for case in public:
        visited.clear()
        sys.setprofile(capture)
        try:
            actual = entry(**case["inputs"])
        finally:
            sys.setprofile(None)
        if actual != case["expect"]:
            return {"inputs": case["inputs"], "actual": actual}, visited
    raise ValueError("no public failure")


def alternatives(trees, visited):
    sites = [
        (name, key, node, group, current)
        for name, function in visited
        for function_name, key, node, group, current in expression_sites(trees[name], name)
        if function_name == function
    ][:32]
    operators = (
        (name, {"node": key, "kind": "op", "text": text}, node, operator)
        for name, key, node, group, current in sites
        for text, operator in group.items()
        if not isinstance(current, operator)
    )
    replacements = (
        (name, {"node": key, "kind": "replace", "text": expression}, node, None)
        for name, key, node, _, _ in sites
        for expression in small_replacements(node)
    )
    yield from operators
    yield from replacements


def variant(tree, name, node, edit, operator):
    if operator is None:
        replacement = ast.parse(edit["text"], mode="eval").body

        class Replace(ast.NodeTransformer):
            def visit(self, child):
                return replacement if child is node else super().visit(child)

        tree = Replace().visit(copy.deepcopy(tree, {id(node): node}))
        return compile(ast.fix_missing_locations(tree), name, "exec")
    if isinstance(node, ast.Compare):
        original = node.ops[0]
        node.ops[0] = operator()
        try:
            return compile(tree, name, "exec")
        finally:
            node.ops[0] = original
    original = node.op
    node.op = operator()
    try:
        return compile(tree, name, "exec")
    finally:
        node.op = original


def find_probe(candidates, pool):
    if len(candidates) < 2:
        return None, 0
    checked = 0
    for inputs in pool[:min(32, 128 // len(candidates))]:
        checked += 1
        try:
            outcomes = [{"edit": edit, "actual": entry(**inputs)} for edit, entry in candidates]
        except ArithmeticError:
            continue
        if len({item["actual"] for item in outcomes}) > 1:
            return {"inputs": inputs, "outcomes": outcomes}, checked
    return None, checked


def scan(sources, public, pool):
    trees = {name: ast.parse(source, name) for name, source in sources.items()}
    program = {name: compile(tree, name, "exec") for name, tree in trees.items()}
    witness, visited = first_failure(load(program), public)
    tested = 0
    green = []
    for name, edit, node, operator in alternatives(trees, visited):
        if tested == 32:
            break
        tested += 1
        changed = variant(trees[name], name, node, edit, operator)
        entry = load(program | {name: changed})
        if all(agrees(entry, case) for case in public):
            green.append((edit, entry))
    probe, checked = find_probe(green, pool)
    return {
        **witness,
        "tested": tested,
        "candidates": [edit for edit, _ in green],
        "counterexample": probe,
        "probes_checked": checked,
    }


def main(mode, folder, data):
    sources = {name: (folder / name).read_text() for name in MODULES}
    if mode == "scan":
        return scan(sources, data["public"], data["pool"])
    if mode == "apply":
        result = patch(folder, data["edit"])
        sources[result["file"]] = result["source"]
    entry = load({name: compile(source, name, "exec") for name, source in sources.items()})
    passed = 0
    for case in data["public"] + data.get("hidden", []):
        if not agrees(entry, case):
            return {"passed": passed, "success": False}
        passed += 1
    if mode == "apply":
        destination = folder / result["file"]
        pending = destination.with_suffix(".pending")
        pending.write_text(result["source"])
        pending.replace(destination)
    return {"passed": passed, "success": True}


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    print(json.dumps(main(mode, pathlib.Path(directory), json.load(sys.stdin)), separators=(",", ":")))
