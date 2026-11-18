def balance(opening, entries):
    total = opening
    minimum = -(1 << 63)
    maximum = (1 << 63) - 1
    for entry in entries:
        total += entry
        if total < minimum or total > maximum:
            raise OverflowError("balance exceeds signed 64-bit range")
    return total
