"""Lokaler Papier-Debugging-Versuch mit zwei simulierten Regeln."""
import itertools
import json
import random
import sys
from pathlib import Path

PUMP = """def step(on, value):
    if value < 20:
        return True
    if value > 80:
        return False
    return on"""
LIGHT = """def step(state, motion):
    on, missed = state
    if motion:
        return True, 0
    missed += 1
    return on and missed < 2, missed"""

# Genau eine dieser kleinen Abweichungen wird pro Regel ausgelost.
MUTATIONS = {
    'Pumpe': [('value < 20', 'value <= 20'), ('value > 80', 'value >= 80'),
              ('return on', 'return False')],
    'Licht': [('return True, 0', 'return True, missed'),
              ('missed < 2', 'missed < 3'), ('missed < 2', 'missed < 1')],
}
SOURCES = {'Pumpe': PUMP, 'Licht': LIGHT}


def compile_step(rule, source):
    # Nur fest vorgegebene Versuchsfunktionen laden, auch bei der Auswertung.
    allowed = {SOURCES[rule]} | {SOURCES[rule].replace(a, b) for a, b in MUTATIONS[rule]}
    if source not in allowed:
        raise ValueError('Quellvariante außerhalb des Versuchs')
    scope = {}
    exec(source, {'__builtins__': {}}, scope)
    return scope['step']


def simulate(rule, step, inputs):
    state = False if rule == 'Pumpe' else (False, 0)
    result = []
    for value in inputs:
        state = step(state, value)
        result.append(state)
    return result


def outputs(rule, states):
    return states if rule == 'Pumpe' else [on for on, _ in states]


def reference(rule, inputs):
    # Definition über die Eingangshistorie, unabhängig von den Schritt-Funktionen.
    if rule == 'Pumpe':
        triggers = [v for v in inputs if v < 20 or v > 80]
        return bool(triggers) and triggers[-1] < 20
    return any(inputs[-2:])


def draw(seed):
    rng = random.Random(seed)
    with_trace = rng.choice(list(SOURCES))
    result = {}
    for rule, clean in SOURCES.items():
        old, new = rng.choice(MUTATIONS[rule])
        source = clean.replace(old, new)
        step = compile_step(rule, source)
        alphabet = [19, 20, 50, 80, 81] if rule == 'Pumpe' else [False, True]
        length = 5 if rule == 'Pumpe' else 6
        examples = []
        for seq in itertools.product(alphabet, repeat=length):
            actual = outputs(rule, simulate(rule, step, seq))
            if actual[-1] != reference(rule, seq) and len(set(seq)) > 1:
                examples.append(seq)
        seq = rng.choice(examples)
        candidates = [s for s in itertools.product(alphabet, repeat=6)
                      if len(set(s)) >= 2 and s != seq
                      and any(reference(rule, s[:i]) != reference(rule, s[:i+1])
                              for i in range(len(s)))]
        result[rule] = (source, seq, rng.choice(candidates), rule == with_trace)
    return result


def main():
    mode, seed, *extra = sys.argv[1:]
    answers = json.loads(Path(extra[0]).read_text()) if mode == 'werten' else None
    for rule, (source, seq, prediction, with_trace) in draw(int(seed)).items():
        step = compile_step(rule, source)
        if mode == 'aufgaben':
            states = simulate(rule, step, seq)
            print(rule, 'mit Spur' if with_trace else 'ohne Spur', '\n'+source)
            print('Eingaben:', seq, 'Endausgabe Ist:', outputs(rule, states)[-1],
                  'Soll:', reference(rule, seq))
            if with_trace:
                print('Ist-Zustand nach jeder Messung:', states)
        elif mode == 'vorhersage':
            print(rule, prediction)
        elif mode == 'werten':
            data = answers[rule]
            old, new = data['tausch']
            assert source.count(old) == 1 and old != new
            fixed = compile_step(rule, source.replace(old, new))
            actual = outputs(rule, simulate(rule, step, seq))
            first = next(i for i, state in enumerate(actual, 1) if state != reference(rule, seq[:i]))
            print(rule, 'erste falsche Ausgabe:', first, 'Diagnose trifft:', first == data['erste_abweichung'])
            expected = [reference(rule, prediction[:i]) for i in range(1, len(prediction)+1)]
            print('Vorhersage:', expected, 'trifft:', expected == data['vorhersage'])
            alphabet, length = ((19, 20, 50, 80, 81), 5) if rule == 'Pumpe' else ((False, True), 7)
            total = failed = 0
            for n in range(length+1):
                for seq2 in itertools.product(alphabet, repeat=n):
                    states = outputs(rule, simulate(rule, fixed, seq2))
                    failed += states != [reference(rule, seq2[:i]) for i in range(1, n+1)]
                    total += 1
            print('Reparierte Folgen korrekt:', total-failed, '/', total)
        else:
            raise SystemExit('aufgaben SEED | vorhersage SEED | werten SEED ANTWORTEN.json')


if __name__ == '__main__':
    main()
