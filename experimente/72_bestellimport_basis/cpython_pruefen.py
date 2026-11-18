"""Explicit CPython comparison: run the stored program or check targeted examples."""
import json
import sys


def main():
    folder, mode = sys.argv[1:3]
    sys.path.insert(0, folder)
    from panel import main as entry
    if mode == "run":
        return entry(**json.loads(sys.argv[3]))
    rows = json.load(sys.stdin)
    targets = [entry]
    if mode == "both":
        from route import relay
        targets.append(relay)
    for target in targets:
        for row in rows:
            result = target(**row["inputs"])
            if type(result) is not int or result != row["expect"]:
                return False
    return True


if __name__ == "__main__":
    print(json.dumps(main(), ensure_ascii=False))
