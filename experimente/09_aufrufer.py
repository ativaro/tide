"""Kontrollfall für Änderungen an gemeinsam genutzten TIDE-Funktionen."""
from itertools import product
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / '07_dreiwege'))
from pruefer import compile_program, run

# Beide Verbraucher bevorzugen ursprünglich den alten Eintrag bei Gleichstand.
BODIES = {
    'wahl vorrang:&ii anderer:&ii > &ii':
        'if > first anderer first vorrang anderer vorrang',
    'anzeige alt:&ii neu:&ii > i': 'second wahl alt neu',
    'archiv_eintrag alt:&ii neu:&ii > &ii': 'wahl alt neu',
    'archiv alt:&ii neu:&ii > i': 'second archiv_eintrag alt neu',
}
FUNCTIONS = [(header, {'A': body}) for header, body in BODIES.items()]

# Der neue Auftrag gilt nur für die Anzeige. Das Archiv behält seinen Vertrag.
VERSIONS = {
    'Ausgangsfassung': {},
    'Gemeinsame Auswahl ändern': {'wahl': 'if > first vorrang first anderer vorrang anderer'},
    'Nur Anzeige ändern': {'anzeige': 'second wahl neu alt'},
}

def main():
    for label, edits in VERSIONS.items():
        program = compile_program(FUNCTIONS, 'A', edits)
        hits = [0, 0]
        for old, new in product(range(3, 8), repeat=2):
            args = (old, 11), (new, 19)
            results = tuple(run(program, name, *args) for name in ('anzeige', 'archiv'))
            expected = (19 if new >= old else 11, 19 if new > old else 11)
            for i in range(2):
                hits[i] += results[i] == expected[i]
            if old == new == 5:
                witness = results
        print(f'{label}: Anzeige {hits[0]}/25, Archiv {hits[1]}/25. '
              f'Bei 5:5 Anzeige-ID {witness[0]}, Archiv-ID {witness[1]}.')
        assert (hits, witness) == {
            'Ausgangsfassung': ([20, 25], (11, 11)),
            'Gemeinsame Auswahl ändern': ([25, 20], (19, 19)),
            'Nur Anzeige ändern': ([25, 25], (19, 11)),
        }[label]

if __name__ == '__main__':
    main()
