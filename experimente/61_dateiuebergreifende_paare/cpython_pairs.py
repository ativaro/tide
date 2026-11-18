"""External CPython-AST comparison with the same cross-file fallback."""
import ast
from itertools import combinations, islice
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "60_reparaturzeit"))
from cpython_comparison import (
    MODULES, agrees, alternatives, find_probe, first_failure, load, main, patch, variant,
)


def scan(folder, public, pool):
    trees = {name: ast.parse((folder / name).read_text(), name) for name in MODULES}
    program = {name: compile(tree, name, "exec") for name, tree in trees.items()}
    witness, visited = first_failure(load(program), public)
    options = list(islice(alternatives(trees, visited), 33))
    singles, compiled_edits = [], []
    for name, edit, node, operator in options[:32]:
        changed = variant(trees[name], name, node, edit, operator)
        compiled_edits.append((name, edit, changed))
        entry = load(program | {name: changed})
        if all(agrees(entry, case) for case in public):
            singles.append((edit, entry))

    pairs = []
    checks = 0
    truncated = False
    if not singles and len(options) <= 32:
        for (left, left_edit, left_code), (right, right_edit, right_code) in combinations(compiled_edits, 2):
            if left == right:
                continue
            if checks == 64:
                truncated = True
                break
            checks += 1
            entry = load(program | {left: left_code, right: right_code})
            if all(agrees(entry, case) for case in public):
                pairs.append(([left_edit, right_edit], entry))

    probe, checked = find_probe(singles or pairs, pool)
    return {
        **witness, "tested": len(compiled_edits), "truncated": len(options) > 32,
        "candidates": [edit for edit, _ in singles], "pair_tested": checks, "pair_truncated": truncated,
        "pair_candidates": [edits for edits, _ in pairs], "counterexample": probe, "probes_checked": checked,
    }


def preview(folder, data):
    files = [patch(folder, edit) for edit in data["edits"]]
    replacements = {item["file"]: item["source"] for item in files}
    if len(replacements) != 2:
        raise ValueError("expected edits to two distinct files")
    sources = {
        name: replacements[name] if name in replacements else (folder / name).read_text()
        for name in MODULES
    }
    entry = load({name: compile(source, name, "exec") for name, source in sources.items()})
    if not all(agrees(entry, case) for case in data["public"]):
        raise ValueError("pair does not pass the public tests")
    return {"examples": {"passed": len(data["public"])}, "written": False, "files": files}


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    folder = pathlib.Path(directory)
    arguments = json.load(sys.stdin)
    if mode == "scan":
        result = scan(folder, arguments["public"], arguments["pool"])
    elif mode == "preview":
        result = preview(folder, arguments)
    else:
        result = main(mode, folder, arguments)
    print(json.dumps(result, separators=(",", ":")))
