def balance(opening, entries):
    total = opening
    for entry in entries:
        total += entry
        if not -(1 << 63) <= total < (1 << 63):
            raise OverflowError
    return total
