"""External Python counterpart to rowtext@2.0.0."""

__version__ = "2.0.0"
__all__ = ("parse",)


def parse(text):
    lines = text.split("\n")
    last = lines.pop()
    rows = [line.removesuffix("\r") for line in lines]
    if last:
        rows.append(last)
    return rows
