from route import relay


def main(label: str, booked: int, cancelled: int) -> int:
    return relay(label, booked, cancelled)
