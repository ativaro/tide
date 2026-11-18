from rulebook import policy


def relay(net: int, fee: int) -> int:
    return policy(net, fee)
