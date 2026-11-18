"""Comparison control: check all write candidates in one fresh CPython process."""
import json
import sys


if __name__ == "__main__":
    draft = json.load(sys.stdin)
    for i, source in enumerate(draft["sources"], 1):
        scope = {}
        exec(compile(source, "panel.py", "exec"), scope)
        if all(type(value := scope["main"](**row["inputs"])) is int and value == row["expect"]
               for row in draft["public"]):
            with open(sys.argv[1], "w", encoding="utf-8") as target:
                target.write(source)
            print(json.dumps({"tested": i, "source": source}))
            break
    else:
        print(json.dumps({"tested": len(draft["sources"]), "source": None}))
