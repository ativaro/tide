"""External CPython comparison for the packaged TIDE report."""
import json
import os
import stat
import sys

import measurements
import rowtext

MAX_BYTES = 131072
MAX_LINES = 4096


class ReportError(Exception):
    def __init__(self, code, **fields):
        self.detail = {"code": code, **fields}


def report(source, limit):
    if source is None:
        raise ReportError("E_CAPABILITY")
    try:
        fd = os.open(source, os.O_RDONLY | os.O_NONBLOCK)
        try:
            if not stat.S_ISREG(os.fstat(fd).st_mode):
                raise ReportError("E_CAPABILITY")
            with os.fdopen(fd, "rb", closefd=False) as file:
                data = file.read(MAX_BYTES + 1)
        finally:
            os.close(fd)
    except OSError:
        raise ReportError("E_IO") from None
    if len(data) > MAX_BYTES:
        raise ReportError("E_LIMIT")
    try:
        rows = rowtext.parse(data.decode("utf-8"))
    except UnicodeDecodeError:
        raise ReportError("E_UTF8") from None
    if len(rows) > MAX_LINES:
        raise ReportError("E_LIMIT")

    above = 0
    peak = None
    for index, line in enumerate(rows, 1):
        try:
            value = measurements.parse(line, index)
        except ValueError:
            raise ReportError("E_DATA", reason="invalid_integer", input_line=index) from None
        above += value > limit
        if peak is None or value > peak:
            peak = value
    return {"above": above, "peak": {"none": True} if peak is None else {"some": peak}}


if __name__ == "__main__":
    options = dict(zip(sys.argv[1::2], sys.argv[2::2]))
    grant = options.get("--read")
    path = grant.removeprefix("input=") if grant else None
    try:
        if rowtext.__version__ != "2.0.0" or measurements.__version__ != "1.3.0":
            raise ReportError("E_PACKAGE")
        inputs = json.loads(options.get("--inputs", "{}"))
        limit = inputs.get("limit")
        if type(limit) is not int or not measurements.MIN_I64 <= limit <= measurements.MAX_I64:
            raise ReportError("E_INPUT")
        print(json.dumps(report(path, limit), separators=(",", ":")))
    except ReportError as error:
        print(json.dumps(error.detail, separators=(",", ":")), file=sys.stderr)
        sys.exit(1)
