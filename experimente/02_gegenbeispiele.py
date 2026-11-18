"""Prüft die vorher festgehaltenen Beispiele gegen alle 121 kurzen Eingaben."""
from itertools import combinations, pairwise, product


def run_length(values, allow_equal):
    best = current = int(bool(values))
    for left, right in pairwise(values):
        if right > left or (allow_equal and right == left):
            current += 1
        else:
            current = 1
        best = max(best, current)
    return best


def sums(values):
    return (max(map(sum, pairwise(values)), default=None),
            max(map(sum, combinations(values, 2)), default=None))


def changes(values):
    return (sum(a != b for a, b in pairwise(values)), max(0, len(set(values)) - 1))


def rising(values):
    ups = sum(b > a for a, b in pairwise(values))
    downs = sum(b < a for a, b in pairwise(values))
    return (len(values) >= 2 and values[-1] > values[0], ups > downs)


if __name__ == '__main__':
    inputs = [x for n in range(5) for x in product(range(3), repeat=n)]
    cases = [
        ('Anstieg', lambda x: (run_length(x, False), run_length(x, True)), (1, 1), (1, 2)),
        ('Summe', sums, (2, 0, 2), (2, 4)),
        ('Änderungen', changes, (0, 1, 0), (2, 1)),
        ('Trend', rising, (0, 2, 1), (True, False)),
    ]
    assert len(inputs) == 121
    for name, rules, guess, expected in cases:
        witnesses = []
        for x in inputs:
            left, right = rules(x)
            if left != right:
                witnesses.append(x)
        shortest = witnesses[0]
        print(name, 'gültiger Erstvorschlag:', rules(guess) == expected and expected[0] != expected[1],
              'eigene Länge:', len(guess), 'kürzeste Länge:', len(shortest),
              'erstes Suchergebnis:', shortest, 'Treffer im Suchraum:', len(witnesses))
