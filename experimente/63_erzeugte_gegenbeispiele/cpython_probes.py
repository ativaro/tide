"""External CPython-AST comparison for bounded counterexample generation."""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "61_dateiuebergreifende_paare"))
import cpython_pairs


def vectors(names, ranges, witness):
    low = [ranges[key][0] for key in names]
    high = [ranges[key][1] for key in names]
    middle = [(a + b) // 2 for a, b in zip(low, high)]
    pivot = [max(a, min(b, witness[key])) for key, a, b in zip(names, low, high)]
    yield from (middle, low, high, pivot)
    for index, (n, left, right) in enumerate(zip(pivot, low, high)):
        for value in (max(left, n - 1), min(right, n + 1), left, right):
            yield pivot[:index] + [value] + pivot[index + 1:]
    for mask in range(min(32, 2 ** len(names))):
        yield [b if mask & (1 << i) else a for i, (a, b) in enumerate(zip(low, high))]


def scan(folder, data):
    pool, public = data["pool"], data["public"]
    ranges = data.get("ranges")
    generated_checked = 0
    origin = None
    prior_finder = cpython_pairs.find_probe

    def find_probe(candidates, fixed):
        nonlocal generated_checked, origin
        witness, fixed_checked = prior_finder(candidates, fixed)
        if witness is not None:
            origin = "fixed"
        if witness is not None or ranges is None or len(candidates) < 2 or not isinstance(candidates[0][0], list):
            return witness, fixed_checked
        code = candidates[0][1].__code__
        names = code.co_varnames[:code.co_argcount]
        seen = {tuple(case[key] for key in names) for case in fixed[:fixed_checked]}
        seen.update(tuple(test["inputs"][key] for key in names) for test in public)
        generated = []
        for row in vectors(names, ranges, public[0]["inputs"]):
            key = tuple(row)
            if key in seen:
                continue
            seen.add(key)
            generated.append(dict(zip(names, row)))
            if len(generated) == min(32, 128 // len(candidates)):
                break
        witness, generated_checked = prior_finder(candidates, generated)
        if witness is not None:
            origin = "generated"
        return witness, fixed_checked

    # The external comparator reuses the same scan and compiled variants.
    cpython_pairs.find_probe = find_probe
    try:
        result = cpython_pairs.scan(folder, public, pool)
    finally:
        cpython_pairs.find_probe = prior_finder
    return {**result, "generated_probes_checked": generated_checked, "counterexample_source": origin}


if __name__ == "__main__":
    mode, directory = sys.argv[1:]
    folder = pathlib.Path(directory)
    data = json.load(sys.stdin)
    if mode == "scan":
        result = scan(folder, data)
    elif mode == "preview":
        result = cpython_pairs.preview(folder, data)
    else:
        result = cpython_pairs.main(mode, folder, data)
    print(json.dumps(result, separators=(",", ":")))
