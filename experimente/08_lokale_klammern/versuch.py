"""Prüfstand für genau ein markiertes Teilstück. Aufruf: versuch.py [runde 1|probe|werten|tokens]."""
from collections import Counter
import itertools
import json
from pathlib import Path
import re
import sys

from aufgaben import TASKS, ORDERS, expected, inputs

HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'07_dreiwege'))
import pruefer as tide

FORMS = 'PLV'
TOK = re.compile(r'[()]|[^\s()]+')

def tokens(tree, form, focus, omit=None, path=()):
    """Pfad je Originaltoken bleibt auch nach Löschung erhalten, nur für die Wertung."""
    if path==omit: return
    if isinstance(tree,str):
        yield tree,path
        return
    marked = form=='V' or (form=='L' and path==focus)
    if marked: yield '(',path
    yield tree[0],path
    for j,child in enumerate(tree[1:],1):
        yield from tokens(child,form,focus,omit,(*path,j))
    if marked: yield ')',path

def source(items):
    return ' '.join(word for word,_ in items).replace('( ','(').replace(' )',')')

class ParseError(ValueError):
    def __init__(self, msg, owner, position):
        super().__init__(msg)
        self.owner,self.position = owner,position

def parse(words):
    """Alle drei Formen haben denselben Parser. Er sieht nur Wörter, niemals Sollpfade."""
    cursor = 0
    def read(owner=None, arg=None):
        nonlocal cursor
        if cursor == len(words) or words[cursor]==')':
            end = 'Ende' if cursor==len(words) else ')'
            at = 'Ausdruck' if owner is None else f'{words[owner]} Argument {arg}'
            raise ParseError(f'{end}: {at} fehlt',owner,cursor)
        marked = words[cursor]=='('
        if marked: cursor += 1
        if cursor==len(words) or words[cursor] in ('(',')'):
            raise ParseError('Operation erwartet',None,cursor)
        op,op_at = words[cursor],cursor
        cursor += 1
        if op not in tide.OPS:
            if marked: raise ParseError('Klammer um einzelnen Wert',None,op_at)
            return op
        tree = (op,*(read(op_at,j+1) for j in range(tide.OPS[op])))
        if marked:
            if cursor==len(words) or words[cursor]!=')':
                raise ParseError('Schließende Klammer erwartet',op_at,cursor)
            cursor += 1
        return tree
    result = read()
    if cursor!=len(words): raise ParseError('Weitere Eingabe',None,cursor)
    return result

def baseline(t):
    return tide.parse(TASKS[t][1],'A',{})

def packet(t, form):
    header,_,focus,missing,brief,visible = TASKS[t]
    label = {'P':'ohne Klammern','L':'ein Klammerpaar am Fokus','V':'alle Operationen geklammert'}[form]
    return '\n'.join((f'{t} {form} · {label}',header,brief,
                      f'Editorfokus: Operand {focus[0]} der äußeren Operation. Liefere den ganzen Rumpf.',
                      f'Beispiel {visible[0]} → {visible[1]}',
                      source(tokens(baseline(t),form,focus,missing))))

def preflight():
    for t,(_,_,focus,_,_,visible) in TASKS.items():
        root = baseline(t)
        assert expected(t,visible[0])==visible[1]
        for f in FORMS:
            words = TOK.findall(source(tokens(root,f,focus)))
            assert parse(words)==root
            if f in 'PV': assert tide.parse(source(tokens(root,f,focus)),'A' if f=='P' else 'B',{})==root
    for bad in ['+ ( + 1 ) 2','+ (+ 1 2 3) 4','+ 1 2 3','(+ 1 2','(+ 1 2))']:
        try: parse(TOK.findall(bad))
        except ParseError: pass
        else: raise AssertionError(bad)
    assert set(ORDERS.values())=={''.join(v) for v in itertools.permutations(FORMS)}

def grade(t,form,answer):
    header,_,focus,_,_,visible = TASKS[t]
    name,(params,ret) = tide.signature(header)
    words = TOK.findall(answer)
    try: tree = parse(words)
    except ParseError as e: return 'Syntax '+str(e)
    if words!=[word for word,_ in tokens(tree,form,focus)]: return 'Markierung weicht ab'
    try: typ = tide.infer(tree,params,{})
    except tide.Fault as e: return 'Typ '+str(e)
    if typ!=ret: return 'Ergebnistyp '+typ
    program = {name:tree},{name:(params,ret)}
    count = 0
    for key in itertools.chain([visible[0]],(k for k in inputs(t) if k!=visible[0])):
        want = expected(t,key)
        try: got = tide.run(program,name,*key)
        except tide.Fault as e: got = str(e)
        if json.dumps(got)!=json.dumps(want): return f'Fachlich {key}: {got} erwartet {want}'
        count += 1
    return count

def deletions(tree,path=()):
    """Jeder einzelne Wertoperand, ohne die Code- und Bindungsfelder von catch."""
    for j,child in enumerate(tree[1:],1):
        addr = (*path,j)
        if isinstance(child,tuple): yield from deletions(child,addr)
        elif tree[0]!='catch' or j not in (1,3): yield addr

def audit():
    counts = Counter()
    for t in TASKS:
        _,_,focus,missing,_,_ = TASKS[t]
        root = baseline(t)
        for leaf in deletions(root):
            inside = leaf[:len(focus)]==focus
            group = ('direkt' if leaf[:-1]==focus else 'tiefer') if inside else 'außerhalb'
            for form in FORMS:
                tagged = list(tokens(root,form,focus,leaf))
                words = [w for w,_ in tagged]
                try: parse(words)
                except ParseError as e:
                    owner = tagged[e.owner][1] if e.owner is not None else None
                    hit = owner==leaf[:-1]
                    counts[group,form,hit] += 1
                    if leaf==missing:
                        print(t,form,'|',source(tagged),'|',str(e),'|', 'Treffer' if hit else 'andere Operation')
                else: raise AssertionError(('unentdeckte Löschung',t,leaf,form))
    for group in ('direkt','tiefer','außerhalb'):
        print(group,*[f'{counts[group,f,True]}/{counts[group,f,True]+counts[group,f,False]}' for f in FORMS])

def records():
    rows = [json.loads(s) for s in (HERE/'erstabgaben.jsonl').read_text().splitlines()]
    assert [(t,f) for t,f,_ in rows]==[(t,order[k]) for k in range(3) for t,order in ORDERS.items()]
    return rows

if __name__=='__main__':
    mode = sys.argv[1]
    preflight()
    if mode=='probe': print('Vorprobe bestanden.')
    elif mode=='runde':
        k = int(sys.argv[2])-1
        for t in TASKS: print(packet(t,ORDERS[t][k]),'\n')
    elif mode=='werten':
        for t,f,answer in records(): print(t,f,grade(t,f,answer))
        audit()
    elif mode=='tokens':
        import tiktoken
        for enc in ('o200k_base','cl100k_base'):
            tokenizer = tiktoken.get_encoding(enc)
            for f in FORMS:
                rows = [s for t,form,s in records() if form==f]
                starts = [packet(t,f).splitlines()[-1] for t in TASKS]
                print(enc,f,*(sum(len(tokenizer.encode(s)) for s in texts) for texts in (starts,rows)))
    else: raise SystemExit(__doc__)
