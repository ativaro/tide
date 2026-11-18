"""External CPython streaming counterpart to the TIDE measurement report."""
import json
import os
import stat
import sys

MAX_BYTES = 128 * 1024 * 1024
LINE_BYTES = 128 * 1024
MIN_I64, MAX_I64 = -(1 << 63), (1 << 63) - 1


class ReportError(Exception):
    def __init__(self, code, row=None, reason=None):
        self.fields = {"code": code}
        if row is not None:
            self.fields["input_line"] = row
        if reason:
            self.fields["reason"] = reason


def parse(raw, row):
    negative = raw.startswith(b"-")
    digits = raw[1:] if negative else raw
    if digits.isdigit():
        if len(digits) > 19:
            digits = digits.lstrip(b"0") or b"0"
        if len(digits) <= 19:
            value = int(digits)
            value = -value if negative else value
            if MIN_I64 <= value <= MAX_I64:
                return value
    else:
        try:
            raw.decode("utf-8")
        except UnicodeDecodeError:
            raise ReportError("E_UTF8", row) from None
    raise ReportError("E_DATA", row, "invalid_integer")


def report(path, budget, limit):
    if path is None:
        raise ReportError("E_CAPABILITY")
    fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise ReportError("E_CAPABILITY")
        if not 0 <= budget <= MAX_BYTES:
            raise ReportError("E_LIMIT", 1)
        above, peak, row = 0, None, 0
        with os.fdopen(fd, "rb", buffering=65536, closefd=False) as source:
            while raw := source.readline(min(LINE_BYTES, budget) + 1):
                row += 1
                size = len(raw)
                if size > budget or size > LINE_BYTES:
                    raise ReportError("E_LIMIT", row)
                budget -= size
                if raw.endswith(b"\n"):
                    raw = raw[:-1].removesuffix(b"\r")
                value = parse(raw, row)
                above += value > limit
                if peak is None or value > peak:
                    peak = value
        return {"above": above, "peak": {"none": True} if peak is None else {"some": peak}}
    finally:
        os.close(fd)


if __name__ == "__main__":
    opts = dict(zip(sys.argv[1::2], sys.argv[2::2]))
    try:
        args = json.loads(opts["--inputs"])
        if set(args) != {"limit", "bytes"} or any(
            type(x) is not int or not MIN_I64 <= x <= MAX_I64 for x in args.values()
        ):
            raise ReportError("E_INPUT")
        grant = opts.get("--read", "")
        result = report(grant[6:] if grant.startswith("input=") else None, args["bytes"], args["limit"])
        print(json.dumps(result, separators=(",", ":")))
    except (OSError, ReportError) as error:
        fields = error.fields if isinstance(error, ReportError) else {"code": "E_IO"}
        print(json.dumps(fields, separators=(",", ":")), file=sys.stderr)
        sys.exit(1)
