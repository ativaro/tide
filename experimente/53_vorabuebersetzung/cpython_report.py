"""External CPython comparison for apps/report.tide."""
import json
import os
import re
import stat
import sys

MIN = -(1 << 63)
MAX = (1 << 63) - 1
MAX_BYTES = 131072
INTEGER = re.compile(r"-?[0-9]+\Z")
WORK = "Work budget exhausted"


class ReportError(Exception):
    def __init__(self, file, code, message, line, column, **detail):
        self.detail = dict(file=file, code=code, message=message,
                           line=line, column=column, **detail)


def split_rows(text):
    if not text:
        return []
    *rows, last = text.split("\n")
    rows = [s.removesuffix("\r") for s in rows]
    if last:
        rows.append(last)
    return rows


def parse_number(line):
    if not INTEGER.fullmatch(line):
        return None
    # Python may limit decimal conversion, even for a long series of zeros.
    digits = line.removeprefix("-").lstrip("0")
    if len(digits) > 19:
        return None
    value = int(digits or "0")
    value = -value if line.startswith("-") else value
    return value if MIN <= value <= MAX else None


def spend(work, steps):
    for file, line, column, cost in steps:
        work -= cost
        if work < 0:
            raise ReportError(file, "E_LIMIT", WORK, line, column)
    return work


def row_prefix(text_cost):
    s, r = "summary.tide", "readings.tide"
    return [(s, 8, col, 1) for col in (1, 11, 19, 24)] + [
        (r, 2, 1, 1), (r, 2, 6, 1), (r, 2, 10, 1), (r, 2, 6, text_cost)
    ]


def row_suffix(over, first, new_peak):
    s, r = "summary.tide", "readings.tide"
    test = [8, 12, 14, 20]
    increment = [28, 31, 41, 49] if over else [53, 63]
    return [(s, 9, 1, 1)] + [(s, 10, col, 1) for col in test + increment] + [
        (s, 11, col, 1) for col in (7, 14, 21, 30)
    ] + [
        (r, 5, col, 1) for col in
        ([1, 6, 11, 20] if first else [1, 6, 11, 30, 33, 35, 41, 45 if new_peak else 51])
    ]


def summarize(rows, limit, work):
    """Same application and observable work boundary as the TIDE source."""
    above, peak = 0, None
    for row, line in enumerate(rows, 1):
        text_units = len(line) // 32
        near_limit = work < 29 + text_units
        if near_limit:
            work = spend(work, row_prefix(1 + text_units))
        value = parse_number(line)
        if value is None:
            if near_limit:
                spend(work, [("readings.tide", 2, col, 1) for col in (15, 33)])
            raise ReportError("readings.tide", "E_DATA", "A value is required", 2, 1,
                              reason="invalid_integer", input_line=row)
        over = value > limit
        first = peak is None
        new_peak = first or value > peak
        if near_limit:
            work = spend(work, row_suffix(over, first, new_peak))
        else:
            work -= 27 + text_units + 2 * over - 4 * first
        above += over
        if new_peak:
            peak = value
    return above, peak


def run(path, limit, file="apps/report.tide"):
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_CLOEXEC)
    except OSError:
        raise ReportError(file, "E_IO", "Could not open read grant", 3, 1) from None
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise ReportError(file, "E_CAPABILITY", "A grant must name a regular file", 3, 1)
        try:
            with os.fdopen(fd, "rb", closefd=False) as handle:
                raw = handle.read(MAX_BYTES + 1)
        except OSError:
            raise ReportError(file, "E_IO", "Granted read failed", 4, 19) from None
    finally:
        os.close(fd)
    if len(raw) > MAX_BYTES:
        raise ReportError(file, "E_LIMIT", "Read byte budget exhausted", 4, 19)
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        raise ReportError(file, "E_UTF8", "Invalid UTF-8 input", 4, 19) from None
    rows = split_rows(text)
    if len(rows) > 4096:
        raise ReportError(file, "E_LIMIT", "Line count limit", 4, 12)
    # At most 1.6 MiB can be charged for this source under the read and line limits.
    above, peak = summarize(rows, limit, 100000 - 12 - len(raw) // 32 - len(text) // 32)
    return {"above": above, "peak": {"none": True} if peak is None else {"some": peak}}


if __name__ == "__main__":
    # The benchmark supplies the same bound file and JSON limit to both programs.
    _, _, grant, _, inputs = sys.argv
    try:
        print(json.dumps(run(grant.removeprefix("input="), json.loads(inputs)["limit"]),
                         separators=(",", ":")))
    except ReportError as error:
        print(json.dumps(error.detail, separators=(",", ":")), file=sys.stderr)
        sys.exit(1)
