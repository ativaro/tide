from rulebook import policy


def relay(amount: int, threshold: int) -> int:
    return policy(amount, threshold)
