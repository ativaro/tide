"""External AST arm. Reuse the sealed search and add direct public example dispatch."""
import json
import sys


def main():
    mode, folder, target = sys.argv[1:]
    rows = json.load(sys.stdin)
    if mode == "accept":
        sys.path.insert(0, folder)
        import panel
        import route

        for name, function in (("main", panel.main), ("route", getattr(route, target))):
            for row in rows:
                value = function(**row["inputs"])
                if type(value) is not int or value != row["expect"]:
                    return {"status": "failed_" + name}
        return {"status": "accepted"}

    from pathlib import Path
    from importlib import import_module
    experiments = Path(__file__).resolve().parent.parent
    sys.path[:0] = [str(experiments / "70_strukturelle_reparatur"), str(experiments / "60_reparaturzeit")]
    import cpython_comparison as comparison
    search = import_module("cpython_suche").repair
    if mode == "after":
        agrees = comparison.agrees

        def agrees_at_target(entry, row):
            if "direct" in row:
                # load() creates new modules for each candidate. Take its actual imported function.
                function = entry.__globals__[target]
                assert function.__module__ == "route" and function.__name__ == target
                return agrees(function, row)
            return agrees(entry, row)

        comparison.agrees = agrees_at_target
        rows = rows + [dict(row, direct=True) for row in rows]
    elif mode != "before":
        raise ValueError(mode)
    return search(folder, rows, True)


if __name__ == "__main__":
    print(json.dumps(main(), separators=(",", ":")))
