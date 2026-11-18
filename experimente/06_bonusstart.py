"""Wartungsprobe mit einer gemeinsamen, beim Laden gebundenen Startdefinition."""
import argparse
from functools import lru_cache
from pathlib import Path
import re
import runpy

HERE = Path(__file__).resolve().parent
PREPARE = runpy.run_path(str(HERE / '05_werten.py'))['prepare']
PROGRAM = HERE / '06_bonusstart.tide'
DEPTH = 6


def load(text):
    definition, rule, function = text.strip().split('\n\n')
    match = re.fullmatch(r'bonus_start > i\n(-?\d+)', definition)
    assert match, 'Genau eine gemeinsame unveränderliche Startdefinition erwartet'
    value = int(match[1])
    steps = {}
    for is_rule, source in ((True, rule), (False, function)):
        # Der alte Probeprüfer versteht nur Literale. Beide Formen erhalten
        # dieselbe konstante Bindung, bevor sie an diesen Prüfer gehen.
        bound = re.sub(r'\bbonus_start\b', str(value), source)
        task = dict(name='buchung_regel' if is_rule else 'buchung_funktion',
                    rule=is_rule, start=(4, value), fields=('total', 'bonus'))
        steps[task['name']] = PREPARE(task, bound)
    return (4, value), steps


def oracle(state, event, desired):
    total, bonus = state
    if event == 1:
        return total, bonus + 2
    if event == 2:
        return 4, bonus
    if event == 3:
        return total, min(bonus, total)
    if event == 4:
        return total + bonus, desired
    assert event == 0
    return state


def check_all(step, start, desired):
    step = lru_cache(None)(step)
    passed = count = 0
    def visit(state, expected, depth, valid):
        nonlocal passed, count
        valid = valid and state == expected
        count += 1
        passed += valid
        if depth < DEPTH:
            for event in range(5):
                visit(step(state,event), oracle(expected,event,desired), depth+1, valid)
    visit(start,(4,desired),0,True)
    assert count == sum(5**n for n in range(DEPTH+1))
    return passed,count


def verify(text, desired):
    start, steps = load(text)
    # Vorab aus dem Auftrag berechnete Sollwerte. Nach der ersten Buchung
    # folgt ein Kontoreset bei erhöhtem Bonus, dann Begrenzen, dann Buchen.
    examples = {
        1: [((4,4),[(5,1),(6,1)]),
            ((4,1,1,2,3,4),[(5,1),(5,3),(5,5),(4,5),(4,4),(8,1)])],
        3: [((4,4),[(7,3),(10,3)]),
            ((4,1,1,2,3,4),[(7,3),(7,5),(7,7),(4,7),(4,4),(8,3)])],
    }
    for name, step in steps.items():
        for events, expected in examples[desired]:
            state = start
            actual = []
            for event in events:
                state = step(state,event)
                actual.append(state)
            assert actual == expected, (name,events,actual,expected)
        passed,count = check_all(step,start,desired)
        print(f'{name}, Sollstart {desired}: {passed}/{count} Folgen')
        assert passed == count


def controls(text):
    # Fehlerimpfung in Kopien des Versuchsprogramms: alte 1 beim Buchen.
    for name, old, stale in (
        ('buchung_regel', 'bonus=reset', 'bonus=set 1'),
        ('buchung_funktion', 'pair + total bonus bonus_start', 'pair + total bonus 1'),
    ):
        assert text.count(old) == 1
        start, steps = load(text.replace(old,stale))
        got = steps[name](start,4)
        assert start == (4,3) and got == (7,1) and got != oracle(start,4,3)
        print(f'Negativkontrolle {name}: erste Buchung {got}, erwartet (7, 3)')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('soll', choices=(1,3), type=int)
    parser.add_argument('--vorher', action='store_true', help='ursprüngliche Deklaration in einer Kopie wiederholen')
    args = parser.parse_args()
    text = PROGRAM.read_text()
    if args.vorher:
        assert args.soll == 1
        text = re.sub(r'\Abonus_start > i\n3\n', 'bonus_start > i\n1\n', text)
    verify(text,args.soll)
    if args.soll == 3:
        controls(text)
