"""External CPython-AST comparator with ordered integer-contract projections."""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "64_vertragsgrenzen"))
from cpython_contract import cpython_probes, derive_ranges


def domain(public):
    [requires] = [row["requires"] for row in public if "requires" in row]
    names = tuple(public[0]["inputs"])
    literal = {name: {op: v for op, v in values.items() if not isinstance(v, str)}
               for name, values in requires.items()}
    ranges = derive_ranges([{"inputs": public[0]["inputs"], "requires": literal}])
    orders = []
    for left, name in enumerate(names):
        for relation, value in sorted(requires[name].items()):
            if not isinstance(value, str):
                continue
            right = names.index(value)
            if relation in {"le", "lt", "eq"}:
                orders.append((left, right, int(relation == "lt")))
            if relation in {"ge", "gt", "eq"}:
                orders.append((right, left, int(relation == "gt")))
            if relation not in {"le", "lt", "ge", "gt", "eq"}:
                raise ValueError("unknown parameter comparison")

    bounds = [ranges[name] for name in names]
    for _ in names:
        for left, right, step in orders:
            lo, hi = bounds[left][0], bounds[right][1]
            if lo + step > hi:
                raise ValueError("contradictory requires")
            bounds[right][0] = max(bounds[right][0], lo + step)
            bounds[left][1] = min(bounds[left][1], hi - step)
            if any(lo > hi for lo, hi in (bounds[left], bounds[right])):
                raise ValueError("contradictory requires")
    if any(bounds[left][i] + step > bounds[right][i] for left, right, step in orders for i in (0, 1)):
        raise ValueError("contradictory requires")
    return names, ranges, orders


def follows(values, orders):
    return all(values[left] + step <= values[right] for left, right, step in orders)


def projections(values, orders):
    if follows(values, orders):
        yield values
        return
    for lift in (True, False):
        candidate = list(values)
        for _ in values:
            if follows(candidate, orders):
                break
            for left, right, step in orders:
                if candidate[left] + step <= candidate[right]:
                    continue
                if lift:
                    candidate[right] = candidate[left] + step
                else:
                    candidate[left] = candidate[right] - step
        yield candidate


def scan(folder, data, names, ranges, orders):
    comparator = cpython_probes.cpython_pairs
    prior_finder = comparator.find_probe
    generated_checked = 0
    origin = None

    def find_probe(candidates, fixed):
        nonlocal generated_checked, origin
        if len(candidates) < 2:
            return None, 0
        maximum = min(32, 128 // len(candidates))
        prefix = fixed[:maximum]
        admissible = []
        for i, item in enumerate(prefix, 1):
            if (all(lo <= item[key] <= hi for key, (lo, hi) in ranges.items())
                    and follows([item[key] for key in names], orders)):
                admissible.append((i, item))
        witness, checks = prior_finder(candidates, [item for _, item in admissible])
        if witness:
            origin = "fixed"
            return witness, admissible[checks - 1][0]
        if not isinstance(candidates[0][0], list):
            return None, len(prefix)
        public = [case["inputs"] for case in data["public"]]
        seen = {tuple(item[key] for key in names) for item in public + prefix}
        seeds = cpython_probes.vectors(names, ranges, public[0])
        for seed in seeds:
            for row in projections(seed, orders):
                key = tuple(row)
                if key in seen:
                    continue
                seen.add(key)
                witness, _ = prior_finder(candidates, [dict(zip(names, row))])
                generated_checked += 1
                if witness:
                    origin = "generated"
                    return witness, len(prefix)
                if generated_checked == maximum:
                    return None, len(prefix)
        return None, len(prefix)

    comparator.find_probe = find_probe
    try:
        result = comparator.scan(folder, data["public"], data["pool"])
    finally:
        comparator.find_probe = prior_finder
    return {**result, "probe_range": ranges, "generated_probes_checked": generated_checked,
            "counterexample_source": origin}


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    folder = pathlib.Path(directory)
    data = json.load(sys.stdin)
    names, ranges, orders = domain(data["public"])
    comparator = cpython_probes.cpython_pairs
    if mode == "scan":
        result = scan(folder, data, names, ranges, orders)
    elif mode == "preview":
        result = comparator.preview(folder, data)
    else:
        result = comparator.main(mode, folder, data)
    print(json.dumps(result, separators=(",", ":")))
