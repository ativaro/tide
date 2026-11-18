"""External CPython-AST comparison using the same public requires conditions."""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "63_erzeugte_gegenbeispiele"))
import cpython_probes

MIN_I64, MAX_I64 = -(2**63), 2**63 - 1


def derive_ranges(public):
    [requires] = [case["requires"] for case in public if "requires" in case]
    names = public[0]["inputs"]
    if not isinstance(requires, dict) or not 1 <= len(names) <= 8 or requires.keys() != names.keys():
        raise ValueError("invalid requires parameters")
    ranges = {}
    for name, predicates in requires.items():
        low, high = MIN_I64, MAX_I64
        for relation, value in predicates.items():
            if type(value) is not int or not MIN_I64 <= value <= MAX_I64:
                raise ValueError("invalid integer bound")
            if relation in {"ge", "gt", "eq"}:
                low = max(low, value + (relation == "gt"))
            if relation in {"le", "lt", "eq"}:
                high = min(high, value - (relation == "lt"))
            if relation not in {"ge", "gt", "le", "lt", "eq"}:
                raise ValueError("unknown comparison")
        if low > high:
            raise ValueError("empty interval")
        ranges[name] = [low, high]
    return ranges


def scan(folder, data, ranges):
    comparator = cpython_probes.cpython_pairs
    find_probe = comparator.find_probe

    def within_contract(candidates, pool):
        if len(candidates) < 2:
            return None, 0
        prefix = pool[:min(32, 128 // len(candidates))]
        valid = [(i, inputs) for i, inputs in enumerate(prefix, 1)
                 if all(lo <= inputs[key] <= hi for key, (lo, hi) in ranges.items())]
        witness, count = find_probe(candidates, [inputs for _, inputs in valid])
        return witness, valid[count - 1][0] if witness else len(prefix)

    comparator.find_probe = within_contract
    try:
        return {**cpython_probes.scan(folder, {**data, "ranges": ranges}), "probe_range": ranges}
    finally:
        comparator.find_probe = find_probe


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    folder = pathlib.Path(directory)
    data = json.load(sys.stdin)
    ranges = derive_ranges(data["public"])
    comparator = cpython_probes.cpython_pairs
    if mode == "scan":
        result = scan(folder, data, ranges)
    elif mode == "preview":
        result = comparator.preview(folder, data)
    else:
        result = comparator.main(mode, folder, data)
    print(json.dumps(result, separators=(",", ":")))
