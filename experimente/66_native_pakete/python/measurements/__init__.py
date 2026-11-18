"""External Python counterpart to measurements@1.3.0."""
import re

__version__ = "1.3.0"
__all__ = ("parse",)
MIN_I64 = -(2**63)
MAX_I64 = 2**63 - 1
INTEGER = re.compile(r"-?[0-9]+")


def parse(line, row):
    if not INTEGER.fullmatch(line):
        raise ValueError(row)
    digits = line.removeprefix("-").lstrip("0")
    if len(digits) > 19:
        raise ValueError(row)
    value = int(digits or "0")
    if line.startswith("-"):
        value = -value
    if not MIN_I64 <= value <= MAX_I64:
        raise ValueError(row)
    return value
