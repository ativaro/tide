from rulebook import policy


def relay(ordered: int, delivered: int) -> int:
    return policy(ordered, delivered)
