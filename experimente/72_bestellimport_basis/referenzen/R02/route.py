from rulebook import balance, size


def relay(label: str, booked: int, cancelled: int) -> int:
    return balance(booked, cancelled) + size(label)
