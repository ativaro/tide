"""python3 versuch.py [vorprobe | runde 1 | werten | tokens]"""
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

from aufgaben import TASKS, FORMS, ORDERS, fn, packet
from pruefer import Fault, compile_program, parse, render, run
from soll import MAX, MIN, OV, VISIBLE, hidden, truth

HERE = Path(__file__).resolve().parent
ARMS = dict(zip(TASKS,ORDERS,strict=True))

def verify_manifest(file):
    for line in (HERE/file).read_text().splitlines():
        digest,name = line.split()
        assert hashlib.sha256((HERE/name).read_bytes()).hexdigest() == digest, name

def preflight():
    # Die alten, bekannten Regeln dienen nur der Kalibrierung.
    fixtures = [
        ('streak s:i t:i > i', ('if',('>','t','80'),('if',('<','s','3'),('+','s','1'),'3'),'0'), [( (2,81),3),((3,99),3),((2,80),0)]),
        ('pump old:b t:i > b', ('if',('<','t','20'),'true',('if',('>','t','80'),'false','old')), [((False,19),True),((True,80),True),((True,81),False)]),
        ('light old:i move:b > i', ('if','move','2',('if',('>','old','0'),('+','old','-1'),'0')), [((0,True),2),((2,False),1),((1,False),0)]),
        ('select x:i > i', ('if',('eq','x',str(MAX)),'x',('+','x','1')), [((MAX,),MAX),((MIN,),MIN+1)]),
        ('bounded x:i > i', ('catch','E_OVERFLOW',('+','x','1'),'_','-1'), [((MAX,),-1),((0,),1)]),
        ('overflow x:i > i', ('+','x','-1'), [((MIN,),OV)]),
        ('pairing p:&ii > &ii', ('pair',('second','p'),('first','p')), [(((2,3),),(3,2))]),
        ('failed x:i > i', ('if',('eq','x','0'),('fail','"invalid"'),'x'), [((0,),'E_DATA("invalid")'),((2,),2)]),
        ('denied h:r > t', ('read','h'), [(('unbound',),'E_CAPABILITY')]),
        ('basis > i','1',[((),1)]),
        ('add x:i y:i > i',('+','x','y'),[((2,3),5)]),
        ('client x:i > i',('add',('basis',),'x'),[((4,),5)])]
    funcs = [fn(h,*(render(tree,f) for f in FORMS)) for h,tree,_ in fixtures]
    for f in FORMS:
        compiled = compile_program(funcs,f,{})
        for header,tree,probes in fixtures:
            name = header.split()[0]
            assert tree == compiled[0][name]
            for args,want in probes:
                try: got = run(compiled,name,*args)
                except Fault as e: got = str(e)
                assert (got,type(got)) == (want,type(want))
        try: run(compiled,'bounded',0,budget=1)
        except Fault as e: assert str(e)=='E_LIMIT'
        else: raise AssertionError('Budget')
    for task,cases in VISIBLE.items():
        for args,want in cases: assert truth(task,args)==want, (task,args)
    assert Counter(ORDERS) == Counter({s:2 for s in ('ABC','ACB','BAC','BCA','CAB','CBA')})
    print('Vorprobe bestanden: 3 Frontends, gemeinsame Bäume, Grenzwerte, Rechte, Budget, Beispielverträge.')

def scenario(t, program, key):
    def call(f,*a): return run(program,f,*a)
    if t == 'S4':
        active,out = False,[]
        for e in key:
            step = call('step',active,e)
            out.append(step)
            active = step[0]
        return tuple(out)
    if t == 'A2':
        count = call('basis')
        out = [count]
        for e in key:
            count = call('step',count,e)
            out.append(count)
        return tuple(out)
    if t == 'A1': return call(*key)
    name = TASKS[t][2][-1][0].split()[0]
    return call(name,*key)

def grade(t,f,edits):
    try: program = compile_program(TASKS[t][2],f,edits)
    except Fault as e: return e.category,str(e),0
    cases = hidden(t)
    def match(key,want):
        try: got = scenario(t,program,key)
        except Fault as e: got = str(e)
        # JSON unterscheidet auch bool und int innerhalb eines Paars.
        return json.dumps(got) == json.dumps(want)
    if not all(match(k,v) for k,v in VISIBLE[t]): return 'fachlich','sichtbares Beispiel',len(cases)
    failed = sum(not match(key,truth(t,key)) for key in cases)
    return ('fachlich' if failed else 'ok'), (f'{failed} verdeckte Abweichungen' if failed else ''), len(cases)

def answers():
    records = [json.loads(line) for line in (HERE/'erstabgaben.jsonl').read_text().splitlines()]
    assert [(r['t'],r['f']) for r in records] == [(t,ARMS[t][k]) for k in range(3) for t in TASKS]
    return records

def starters():
    for t in list(TASKS)[4:]:
        programs = []
        for f in FORMS:
            try: p = compile_program(TASKS[t][2],f,{})
            except Fault as e:
                assert t in ('R1','R2','R3')
                print(t,f,e.category,str(e))
            else:
                assert t not in ('R1','R2','R3')
                assert grade(t,f,{})[0]=='fachlich', (t,f)
                programs.append(p[0])
        if programs: assert programs[0] == programs[1] == programs[2]

def tokens(records):
    import tiktoken
    for encoding in ('o200k_base','cl100k_base'):
        enc = tiktoken.get_encoding(encoding)
        sums = Counter()
        for r in records:
            t,f = r['t'],r['f']
            out = '\n'.join(name+' = '+body for name,body in r['edits'].items())
            if 'ursache' in r: out += '\n'+r['ursache']
            for k,v in [('in',packet(t,f)),('out',out),('rumpf','\n'.join(r['edits'].values()))]:
                sums[t[0],f,k] += len(enc.encode(v))
        print(encoding,'je Arm Eingabe / Abgabe / nur Rumpf')
        for g in 'SAR':
            print(g, *[tuple(sums[g,f,k] for k in ('in','out','rumpf')) for f in FORMS])
        print('Summe',*[tuple(sum(sums[g,f,k] for g in 'SAR') for k in ('in','out','rumpf')) for f in FORMS])

if __name__ == '__main__':
    verify_manifest('versuchsstand.sha256')
    mode = sys.argv[1]
    if mode == 'vorprobe': preflight()
    elif mode == 'runde':
        k = int(sys.argv[2])-1
        for t,order in ARMS.items(): print(packet(t,order[k]),'\n')
    elif mode in ('werten','tokens'):
        verify_manifest('erststand.sha256')
        records = answers()
        if mode=='tokens': tokens(records)
        else:
            preflight()
            starters()
            for r in records:
                print(r['t'],r['f'],*grade(r['t'],r['f'],r['edits']))
    else: raise SystemExit(__doc__)
