"""External CPython AST comparison for this experiment."""
import ast
import json
import pathlib
import sys

ARITHMETIC = {"+": ast.Add, "-": ast.Sub, "*": ast.Mult, "//": ast.FloorDiv, "%": ast.Mod}
COMPARISONS = {"<": ast.Lt, ">": ast.Gt, "==": ast.Eq, "<=": ast.LtE, ">=": ast.GtE}


def expression_sites(module, file):
    for definition in module.body:
        if not isinstance(definition, ast.FunctionDef):
            continue
        for node in ast.walk(definition):
            if isinstance(node, ast.BinOp) and type(node.op) in ARITHMETIC.values():
                group, operation = ARITHMETIC, node.op
            elif isinstance(node, ast.Compare) and len(node.ops) == 1 and type(node.ops[0]) in COMPARISONS.values():
                group, operation = COMPARISONS, node.ops[0]
            else:
                continue
            identifier = f"{file}:{node.lineno}:{node.col_offset + 1}:{node.end_lineno}:{node.end_col_offset + 1}"
            yield definition.name, identifier, node, group, operation


def integer_atom(node):
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
        return isinstance(node.operand, ast.Constant) and type(node.operand.value) is int
    return isinstance(node, ast.Name) or isinstance(node, ast.Constant) and type(node.value) is int


def small_replacements(node):
    if not isinstance(node, ast.BinOp) or not isinstance(node.op, ast.Add) or node.lineno != node.end_lineno:
        return []
    product, addend = node.left, node.right
    if not isinstance(product, ast.BinOp) or not isinstance(product.op, ast.Mult):
        product, addend = addend, product
    if not isinstance(product, ast.BinOp) or not isinstance(product.op, ast.Mult):
        return []
    if not all(map(integer_atom, (product.left, product.right, addend))):
        return []
    a, b, c = map(ast.unparse, (product.left, product.right, addend))
    return [f"{a} * ({b} + {c})", f"({a} + {c}) * {b}"]


def entries(cases, folder, packet, expressions=False):
    import resource
    resource.setrlimit(resource.RLIMIT_CPU, (5, 5))
    resource.setrlimit(resource.RLIMIT_AS, (268435456, 268435456))
    sys.path.insert(0, str(folder))
    from panel import main

    if not packet:
        return [main(**case) for case in cases]
    paths = sorted(folder.glob("*.py"))
    path_names = {str(path): path.name for path in paths}
    visited = {}

    def record(frame, event, _):
        if event == "call" and frame.f_code.co_filename in path_names:
            visited[(path_names[frame.f_code.co_filename], frame.f_code.co_name)] = None

    sys.setprofile(record)
    try:
        actual = main(**cases[0])
    finally:
        sys.setprofile(None)
    definitions, edits = {}, {}
    for path in paths:
        module = ast.parse(path.read_text())
        for fn in module.body:
            key = path.name, getattr(fn, "name", None)
            if isinstance(fn, ast.FunctionDef) and key in visited:
                signature = f"{fn.name}({ast.unparse(fn.args)}) -> {ast.unparse(fn.returns)}"
                definitions[key] = {"signature": signature, "body": "\n".join(map(ast.unparse, fn.body))}
        for name, ident, node, group, op in expression_sites(module, path.name):
            key = path.name, name
            if key in visited:
                edits.setdefault(key, []).append({
                    "node": ident, "expr": ast.unparse(node),
                    "type": "b" if group is COMPARISONS else "i",
                    "ops": [text for text, cls in group.items() if not isinstance(op, cls)],
                    **({"replacements": small_replacements(node)} if expressions else {}),
                })
    return {"actual": actual, "definitions": [definitions[key] for key in visited],
            "nodes": [item for key in visited for item in edits.get(key, [])]}


def patch(folder, edit):
    for path in sorted(folder.glob("*.py")):
        module = ast.parse(path.read_text())
        for _, ident, node, group, current in expression_sites(module, path.name):
            if ident != edit["node"]:
                continue
            text = edit["text"]
            if edit["kind"] == "op":
                if text not in group or isinstance(current, group[text]):
                    raise ValueError("operator not offered")
                if isinstance(node, ast.Compare):
                    node.ops[0] = group[text]()
                else:
                    node.op = group[text]()
            else:
                replacement = ast.parse(text, mode="eval").body

                class Replace(ast.NodeTransformer):
                    def visit(self, child):
                        return replacement if child is node else super().visit(child)

                module = Replace().visit(module)
            return {"file": path.name, "source": ast.unparse(ast.fix_missing_locations(module)) + "\n"}
    raise ValueError("unknown node")


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    data = json.load(sys.stdin)
    root = pathlib.Path(directory).resolve()
    out = patch(root, data) if mode == "patch" else entries(data, root, mode != "run", mode == "packet-expressions")
    print(json.dumps(out, ensure_ascii=False, separators=(",", ":")))
