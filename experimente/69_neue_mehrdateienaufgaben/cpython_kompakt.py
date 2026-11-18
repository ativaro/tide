"""External CPython comparison arm with a fresh acceptance interpreter."""
import json
import sys


def accept(folder, cases):
    sys.path.insert(0, folder)
    from panel import main
    for case in cases:
        actual = main(**case["inputs"])
        if type(actual) is not int or actual != case["expect"]:
            return False
    return True


def edit_key(edit):
    module, line, column, *_ = edit["node"].split(":")
    operator = {"//": "div", "%": "mod", "==": "eq"}.get(edit["text"], edit["text"])
    return module.split(".")[0], int(line), int(column), operator


def repair(directory, public):
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "61_dateiuebergreifende_paare"))
    from cpython_pairs import main, preview, scan
    folder = Path(directory)
    result = scan(folder, public, [])
    options = [[edit] for edit in result["candidates"]] or result["pair_candidates"]
    if not options:
        return []
    edits = min(options, key=lambda option: sorted(map(edit_key, option)))
    if len(edits) == 1:
        applied = main("apply", folder, {"edit": edits[0], "public": public})
        assert applied == {"success": True, "passed": len(public)}
    else:
        candidate = preview(folder, {"public": public, "edits": edits})
        assert candidate["examples"]["passed"] == len(public)
        for file in candidate["files"]:
            (folder / file["file"]).write_text(file["source"])
    return [{"node": e["node"], "op" if e["kind"] == "op" else "replace": e["text"]} for e in edits]


if __name__ == "__main__":
    mode, folder = sys.argv[1:]
    cases = json.load(sys.stdin)
    print(json.dumps(accept(folder, cases) if mode == "accept" else repair(folder, cases)))
