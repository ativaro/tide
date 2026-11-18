"""Bewertet nur den Ausdrucksausschnitt der eingefrorenen Schreibprobe, kein TIDE-Runner."""
from collections import Counter
from functools import lru_cache
from hashlib import sha256
from pathlib import Path
import operator
import re
import runpy
import sys

HERE = Path(__file__).resolve().parent
STUDY = runpy.run_path(str(HERE / '05_aufgaben.py'))
FIRST = HERE / '05_erstloesungen.md'
DIGEST = '405946ef32a376768df7356efdfa453957b81bf470bc328d46d7c367d1d3d067'


def expression(text, names):
    """Typ und Auswertung eines Präfixausdrucks des Versuchsvokabulars."""
    tokens = iter(text.split())
    def parse(scope):
        op = next(tokens)
        if op == 'let':
            name = next(tokens)
            assert name not in scope
            atype, binding = parse(scope)
            rtype, body = parse({**scope, name: atype})
            return rtype, lambda env: body({**env, name: binding(env)})
        if op == 'if':
            ctype, cond = parse(scope)
            ytype, yes = parse(scope)
            ntype, no = parse(scope)
            assert ctype == 'b' and ytype == ntype
            return ytype, lambda env: yes(env) if cond(env) else no(env)
        if op in ('pair', 'eq', '>', '<', '+'):
            lt, left = parse(scope)
            rt, right = parse(scope)
            if op == 'pair':
                return '&'+lt+rt, lambda env: (left(env), right(env))
            assert lt == rt == 'i'
            fun = {'eq':operator.eq, '>':operator.gt, '<':operator.lt, '+':operator.add}[op]
            return ('i' if op == '+' else 'b'), lambda env: fun(left(env), right(env))
        if op in scope:
            return scope[op], lambda env: env[op]
        if op in ('false','true'):
            return 'b', lambda env: op == 'true'
        number = int(op)
        return 'i', lambda env: number
    parsed = parse(names)
    assert next(tokens, None) is None, text
    return parsed


def prepare(task, block):
    lines = block.splitlines()
    fields = task['fields']
    start = dict(zip(fields, task['start']))
    types = {f: ('b' if type(v) is bool else 'i') for f,v in start.items()}
    names = {**types,'event':'i'}
    result = '&'+''.join(types.values())
    def checked(text, typ):
        actual, ev = expression(text, names)
        assert actual == typ, text
        return ev
    def env(state,event):
        return {**dict(zip(fields,state)),'event':event}
    if not task['rule']:
        assert lines[0].split() == [task['name'],*(k+':'+v for k,v in names.items()),'>',result]
        body = checked(' '.join(lines[1:]),result)
        return lambda state,event: body(env(state,event))
    assert lines[0].split() == ['rule',task['name'],'event:i','>',result]
    expected = {f+':'+types[f]+'='+str(v).lower() for f,v in start.items()}
    assert lines[1].split()[0] == 'state' and len(lines[1].split()) == 1+len(fields)
    assert set(lines[1].split()[1:]) == expected
    rows = []
    for line in lines[2:-1]:
        guard, assignments = line.split(' -> ')
        assert guard == 'else' or guard.startswith('when ')
        cond = None if guard == 'else' else checked(guard[5:],'b')
        actions = {}
        for assignment in assignments.split(', '):
            f, action = assignment.split('=',1)
            assert f in types and f not in actions
            if action == 'keep':
                actions[f] = operator.itemgetter(f)
            elif action == 'reset':
                actions[f] = lambda env, value=start[f]: value
            else:
                assert action.startswith('set ')
                actions[f] = checked(action[4:],types[f])
        assert actions.keys() == types.keys()
        rows.append((cond,actions))
    assert rows and rows[-1][0] is None and all(c for c,_ in rows[:-1])
    assert lines[-1].startswith('out ')
    output = checked(lines[-1][4:],result)
    def step(state,event):
        old = env(state,event)
        actions = next(actions for cond,actions in rows if cond is None or cond(old))
        new = tuple(actions[f](old) for f in fields)
        # Die Aufgabe verlangt explizit beide Feldwerte als Ausgabe.
        assert output(env(new,event)) == new
        return new
    return step


def score(task, step):
    step = lru_cache(None)(step)
    expected = lru_cache(None)(lambda state,event: STUDY['after'](task,state,event))
    count, passed, first = 0, 0, None
    def visit(path, state, correct, valid):
        nonlocal count, passed, first
        count += 1
        passed += valid
        if len(path) == STUDY['DEPTH']:
            return
        for event in range(5):
            got = step(state,event)
            want = expected(correct,event)
            ok = (got == want)
            p = (*path,event)
            if not ok and (first is None or (len(p),p)<(len(first[0]),first[0])):
                first = (p,want,got)
            visit(p,got,want,valid and ok)
    visit((),task['start'],task['start'],True)
    assert count == sum(5**k for k in range(STUDY['DEPTH']+1))
    return passed,count,first


def main():
    assert sha256(FIRST.read_bytes()).hexdigest() == DIGEST
    blocks = re.findall(r'^```tide\n(.*?)\n```', FIRST.read_text(), re.M|re.S)
    tasks = STUDY['tasks']()
    assert len(blocks) == len(tasks) == 8
    token_mode = sys.argv[1:] == ['tokens']
    if token_mode:
        import tiktoken
        encoders = [tiktoken.get_encoding(n) for n in ('o200k_base','cl100k_base')]
    totals = Counter()
    for task,block in zip(tasks,blocks):
        label = 'Regel' if task['rule'] else 'Funktion'
        if token_mode:
            lines = block.splitlines()
            body = '\n'.join(lines[2:-1] if task['rule'] else lines[1:])
            for enc in encoders:
                for part,source in [('ganz',block),('Rumpf',body)]:
                    totals[label,enc.name,part] += len(enc.encode(source))
        else:
            good,n,first = score(task,prepare(task,block))
            print(task['name'],label,f'{good}/{n}',first or 'OK')
            totals[label,'vollständig korrekt'] += good==n
            totals[label,'korrekte Folgen'] += good
    for key,v in sorted(totals.items()):
        print(*key, v)


if __name__ == '__main__':
    main()
