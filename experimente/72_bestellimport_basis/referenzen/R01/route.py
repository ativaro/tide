from rulebook import delta


def relay(ordered: int, delivered: int) -> int:
    return delta(ordered, delivered)
