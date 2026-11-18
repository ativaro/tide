def policy(ordered: int, delivered: int) -> int:
    return max(0, ordered - delivered)
