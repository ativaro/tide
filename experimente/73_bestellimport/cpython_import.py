"""Independent CPython reference for the order import and position lookup."""
import json
import sqlite3
import sys


class Rejected(Exception):
    def __init__(self, reason, path="", code="E_DATA"):
        self.detail = {"code": code, "reason": reason, "path": path}
        if path.startswith("/events/"):
            self.detail["input_line"] = int(path.split("/")[2])


def pairs(items):
    result = {}
    for key, value in items:
        if key in result:
            raise Rejected("invalid_json")
        result[key] = value
    return result


def bad_number(_):
    raise Rejected("invalid_json")


def read_document(path):
    with open(path, "rb") as source:
        data = source.read(4194305)
    if len(data) > 4194304:
        raise Rejected("byte_budget", code="E_LIMIT")
    try:
        doc = json.loads(data.decode("utf-8"), object_pairs_hook=pairs, parse_constant=bad_number)
    except UnicodeDecodeError:
        raise Rejected("invalid_utf8", code="E_UTF8") from None
    except (json.JSONDecodeError, ValueError, RecursionError):
        raise Rejected("invalid_json") from None

    def require(obj, key, typ, pointer):
        if type(obj.get(key)) is not typ:
            raise Rejected("invalid_json", pointer + "/" + key)
        if typ is int and not -(2**63) <= obj[key] < 2**63:
            raise Rejected("invalid_json", pointer + "/" + key)

    if type(doc) is not dict:
        raise Rejected("invalid_json")
    require(doc, "supplier", str, "")
    require(doc, "events", list, "")
    for i, e in enumerate(doc["events"]):
        p = "/events/" + str(i)
        if type(e) is not dict:
            raise Rejected("invalid_json", p)
        for key in ("id", "kind", "order", "line"):
            require(e, key, str, p)
        require(e, "qty", int, p)
        for key, typ in (("sku", str), ("unit_cents", int)):
            if e.get(key) is not None:
                require(e, key, typ, p)
    return doc


def schema(db):
    db.execute("CREATE TABLE IF NOT EXISTS positions(supplier TEXT NOT NULL,ord TEXT NOT NULL,line TEXT NOT NULL,sku TEXT NOT NULL,original INTEGER NOT NULL,outstanding INTEGER NOT NULL,cents INTEGER NOT NULL,PRIMARY KEY(supplier,ord,line)) WITHOUT ROWID")
    db.execute("CREATE TABLE IF NOT EXISTS events(supplier TEXT NOT NULL,id TEXT NOT NULL,kind TEXT NOT NULL,ord TEXT NOT NULL,line TEXT NOT NULL,qty INTEGER NOT NULL,sku TEXT NOT NULL,cents INTEGER NOT NULL,PRIMARY KEY(supplier,id)) WITHOUT ROWID")


def identifier(text, path):
    if not text or len(text.encode("utf-8")) > 64:
        raise Rejected("invalid_identifier", path)


def apply(db, supplier, e, index):
    path = "/events/" + str(index)
    identifier(e["id"], path + "/id")
    kind = e["kind"]
    if kind not in ("order", "cancel"):
        raise Rejected("invalid_kind", path + "/kind")
    identifier(e["order"], path + "/order")
    identifier(e["line"], path + "/line")
    qty = e["qty"]
    if not 1 <= qty <= 1000000:
        raise Rejected("invalid_quantity", path + "/qty")
    sku, cents = "", 0
    if kind == "order":
        sku, cents = e.get("sku"), e.get("unit_cents")
        identifier(sku, path + "/sku")
        if cents is None or not 0 <= cents <= 100000000:
            raise Rejected("invalid_price", path + "/unit_cents")
    key = (supplier, e["id"])
    line = (supplier, e["order"], e["line"])
    fields = (kind, *line[1:], qty, sku, cents)
    previous = db.execute("SELECT kind,ord,line,qty,sku,cents FROM events WHERE supplier=? AND id=?", key).fetchone()
    if previous is not None:
        if previous != fields:
            raise Rejected("event_conflict", path + "/id")
        return 0
    if kind == "order":
        if not db.execute("INSERT INTO positions VALUES(?,?,?,?,?,?,?) ON CONFLICT DO NOTHING",
                          (*line, sku, qty, qty, cents)).rowcount:
            raise Rejected("position_conflict", path + "/line")
    else:
        changed = db.execute("UPDATE positions SET outstanding=outstanding-? WHERE supplier=? AND ord=? AND line=? AND outstanding>=?",
                             (qty, *line, qty)).rowcount
        if not changed:
            exists = db.execute("SELECT 1 FROM positions WHERE supplier=? AND ord=? AND line=?", line).fetchone()
            raise Rejected("over_cancel" if exists else "unknown_position", path + ("/qty" if exists else "/line"))
    db.execute("INSERT INTO events VALUES(?,?,?,?,?,?,?,?)", (*key, *fields))
    return 1


def import_document(db, doc):
    supplier, events = doc["supplier"], doc["events"]
    identifier(supplier, "/supplier")
    if len(events) > 1000:
        raise Rejected("too_many_events", "/events")
    with db:
        db.execute("BEGIN IMMEDIATE")
        schema(db)
        applied = sum(apply(db, supplier, e, i) for i, e in enumerate(events))
    return {"applied": applied, "duplicates": len(events) - applied}


def position(db, supplier, order, line):
    schema(db)
    p = db.execute("SELECT original,outstanding,outstanding*cents FROM positions WHERE supplier=? AND ord=? AND line=?",
                   (supplier, order, line)).fetchone()
    return {"none": True} if p is None else {"some": dict(zip(("original", "outstanding", "value_cents"), p))}


def main():
    mode, filename, *args = sys.argv[1:]
    db = sqlite3.connect(filename, timeout=0)
    try:
        if mode == "position":
            return position(db, *args)
        if mode != "import" or len(args) != 1:
            raise SystemExit("expected import DATABASE INPUT or position DATABASE SUPPLIER ORDER LINE")
        return import_document(db, read_document(args[0]))
    finally:
        db.close()


if __name__ == "__main__":
    try:
        print(json.dumps(main(), ensure_ascii=False, separators=(",", ":")))
    except Rejected as e:
        print(json.dumps(e.detail), file=sys.stderr)
        sys.exit(1)
    except UnicodeEncodeError:
        print(json.dumps({"code":"E_DATA","reason":"invalid_json"}), file=sys.stderr)
        sys.exit(1)
