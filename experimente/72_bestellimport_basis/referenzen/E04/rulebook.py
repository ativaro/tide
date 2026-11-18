def policy(movements: list[int]) -> int:
    return sum(value for value in movements if value > 0)
