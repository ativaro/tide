from rulebook import policy


def relay(base: int, fee: int, units: int) -> int:
    return policy(base, fee, units)
