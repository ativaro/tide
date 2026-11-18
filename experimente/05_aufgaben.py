"""Aufgaben und unabhängige Python-Referenz für den Schreibversuch (TIDE 0.3)."""
import random
from itertools import permutations

SEED = 917206
DEPTH = 6
PAIRS = (
    (('notiz', 'cursor', 'mark'), ('karte', 'position', 'saved')),
    (('plaetze', 'available', 'booked'), ('karten', 'credits', 'reserved')),
    (('spiel', 'score', 'bonus'), ('konto', 'total', 'pending')),
    (('timer', 'left', 'paused'), ('etappe', 'steps', 'stopped')),
)
STARTS = ((3, 7), (2, False), (4, 1), (3, True))
BRIEFS = (
    ('Position um zwei erhöhen.', 'Aktuelle Position als Marke sichern.',
     'Position und Marke tauschen.', 'Nur die Position zum Anfang zurückbringen.'),
    ('Wenn keine Reservierung besteht und etwas frei ist, eine Einheit reservieren und vom freien Bestand abziehen.',
     'Bestehende Reservierung stornieren und die Einheit zurückgeben.',
     'Reservierung einlösen. Die bereits abgezogene Einheit bleibt verbraucht.',
     'Für einen neuen Durchgang Bestand und Reservierung initialisieren.'),
    ('Bonus um zwei erhöhen.', 'Bonus auf den Kontostand buchen und den Bonus auf seinen Anfangswert zurückstellen.',
     'Nur den Kontostand auf seinen Anfangswert zurückstellen.',
     'Den Bonus auf den aktuellen Kontostand begrenzen, falls er darüber liegt.'),
    ('Während des Laufens einen Schritt verbrauchen. Beim Verbrauch des letzten Schritts sofort pausieren.',
     'Loslaufen. Nur bei vollständig verbrauchten Schritten vorher neu auffüllen.',
     'Pausieren, ohne Schritte zu verlieren.', 'Neu initialisieren, einschließlich des anfänglichen Pausenzustands.'),
)


def tasks():
    rng = random.Random(SEED)
    codes = rng.sample(list(permutations(range(1, 5))), 8)
    items = []
    for twin in range(2):
        for family, pair in enumerate(PAIRS):
            name, first, second = pair[twin]
            items.append(dict(name=name, fields=(first, second), family=family,
                              start=STARTS[family], codes=codes[len(items)],
                              rule=(twin + family) % 2 == 0))
    return items


def reference(family, cmd, state):
    a, b = state
    initial_a, initial_b = STARTS[family]
    if family == 0:
        transitions = ((a+2, b), (a, a), (b, a), (initial_a, b))
    elif family == 1:
        take = int(not b and a > 0)
        transitions = ((a-take, b or bool(take)), (a+int(b), False),
                       (a, False), (initial_a, initial_b))
    elif family == 2:
        transitions = ((a, b+2), (a+b, initial_b), (initial_a, b), (a, min(a,b)))
    else:
        remaining = max(0, a-int(not b))
        transitions = ((remaining, b or remaining == 0), (a or initial_a, False),
                       (a, True), (initial_a, initial_b))
    return state if cmd is None else transitions[cmd]


def after(task, state, event):
    codes = task['codes']
    return reference(task['family'], codes.index(event) if event in codes else None, state)


if __name__ == '__main__':
    for t in tasks():
        print(t['name'], 'Regel' if t['rule'] else 'Funktion', *zip(t['fields'], t['start']))
        for code, text in zip(t['codes'], BRIEFS[t['family']]):
            print(' ',code,text)
        print('  0: Beide Werte behalten. Sichtbares Beispiel (ein Ereignis):',
              t['codes'][0], '->', after(t,t['start'],t['codes'][0]))
