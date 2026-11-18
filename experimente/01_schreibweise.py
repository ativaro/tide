"""Kleiner Selbstversuch zu zwei Schreibweisen. Benötigt nur Python 3."""
import itertools
import json
import random
import re
import sys
from pathlib import Path

DOMAIN = list(itertools.product(range(-2, 3), repeat=3))
NAMES = ('x', 'y', 'z')
SEED = 161126


def render(tree, brackets):
    if not isinstance(tree, tuple):
        return str(tree)
    body = ' '.join(render(item, brackets) for item in tree)
    return f'({body})' if brackets else body


def value(tree, inputs):
    if isinstance(tree, int):
        return tree
    if isinstance(tree, str):
        return inputs[NAMES.index(tree)]
    op, *args = tree
    if op == 'if':
        condition, yes, no = args
        return value(yes if value(condition, inputs) else no, inputs)
    left, right = (value(arg, inputs) for arg in args)
    if op == '+':
        return left + right
    if op == '<':
        return left < right
    assert op == '>'
    return left > right


def mutations(tree):
    if not isinstance(tree, tuple):
        return
    op, *children = tree
    if op in ('<', '>'):
        yield ('>' if op == '<' else '<', *children)
    for i, child in enumerate(children):
        for changed in mutations(child):
            yield (op, *children[:i], changed, *children[i + 1:])


def program(rng, family):
    a, b, c = rng.sample(NAMES, 3)
    u, v, w = (rng.choice(('<', '>')) for _ in range(3))
    k = rng.choice((-1, 0, 1))
    left = ('if', (v, b, c), ('+', a, c), b)
    right = ('if', (w, a, c), ('+', b, k), c)
    if family % 2 == 0:
        return ('if', (u, a, b), left, ('+', right, a))
    return ('+', ('if', (u, a, b), ('+', left, b), right), c)


def cases():
    rng = random.Random(SEED)
    tasks = []
    for pair in range(8):
        editing = pair >= 4
        for brackets in (False, True):
            base = program(rng, pair)
            task = {'form': 'Klammer' if brackets else 'Präfix',
                    'auftrag': 'Ändern' if editing else 'Lesen',
                    'rumpf': render(base, brackets)}
            if editing:
                candidates = list(mutations(base))
                assert len(candidates) == 3
                outputs = [tuple(value(c, x) for x in DOMAIN) for c in candidates]
                assert len(set(outputs)) == len(candidates)
                target = rng.randrange(len(candidates))
                reference = tuple(value(base, x) for x in DOMAIN)
                alive = list(range(len(candidates))) + [len(candidates)]
                outputs.append(reference)
                order = rng.sample(range(len(DOMAIN)), len(DOMAIN))
                examples = []
                while len(alive) > 1:
                    def matches(i):
                        return [j for j in alive if outputs[j][i] == outputs[target][i]]
                    witness = min(order, key=lambda i: len(matches(i)))
                    survivors = matches(witness)
                    assert len(survivors) < len(alive)
                    alive = survivors
                    examples.append([DOMAIN[witness], outputs[target][witness]])
                task['soll'] = examples
                expected = render(candidates[target], brackets)
            else:
                inputs = rng.sample(DOMAIN, 3)
                task['eingaben'] = inputs
                expected = [value(base, x) for x in inputs]
            tasks.append((task, expected))
    rng.shuffle(tasks)
    return [(f'P{i:02d}', t, e) for i, (t, e) in enumerate(tasks, 1)]


def tokens(text):
    return re.findall(r'[()]|[^\s()]+', text)


def main():
    tasks = cases()
    if sys.argv[1:] == ['aufgaben']:
        for name, task, _ in tasks:
            print(name, json.dumps(task, ensure_ascii=False))
        return
    if len(sys.argv) != 3 or sys.argv[1] != 'werten':
        raise SystemExit('aufgaben | werten PFAD_ZU_ANTWORTEN')
    answers = json.loads(Path(sys.argv[2]).read_text())
    assert set(answers) == {name for name, _, _ in tasks}
    groups = {}
    for name, task, expected in tasks:
        actual = answers[name]
        ok = (tokens(actual) == tokens(expected) if isinstance(expected, str)
              else actual == expected)
        groups.setdefault((task['auftrag'], task['form']), []).append(ok)
        print(name, 'OK' if ok else f'Fehler, erwartet {expected}')
    for group, scores in sorted(groups.items()):
        print(*group, f'{sum(scores)}/{len(scores)}')


if __name__ == '__main__':
    main()
