"""External CPython counterpart of measurements@1.3.0."""
MIN_I64, MAX_I64 = -(1 << 63), (1 << 63) - 1


class ReportError(Exception):
    def __init__(self, code, row=None, reason=None):
        self.fields = {"code": code}
        if row is not None:
            self.fields["input_line"] = row
        if reason:
            self.fields["reason"] = reason


def parse(raw, row):
    return decode_measurement(raw, row)


def decode_measurement(raw, row):
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
