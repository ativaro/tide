"""Streaming report core for the external CPython test comparison."""
import measurements

MAX_BYTES = 128 * 1024 * 1024
LINE_BYTES = 128 * 1024


def report(source, budget, limit):
    if not 0 <= budget <= MAX_BYTES:
        raise measurements.ReportError("E_LIMIT", 1)
    above, peak, row = 0, None, 0
    while raw := source.readline(min(LINE_BYTES, budget) + 1):
        row += 1
        size = len(raw)
        if size > budget or size > LINE_BYTES:
            raise measurements.ReportError("E_LIMIT", row)
        budget -= size
        if raw.endswith(b"\n"):
            raw = raw[:-1].removesuffix(b"\r")
        value = measurements.parse(raw, row)
        above += value > limit
        if peak is None or value > peak:
            peak = value
    return {"above": above, "peak": {"none": True} if peak is None else {"some": peak}}
