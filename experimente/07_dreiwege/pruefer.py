"""Nur der verwendete TIDE-Ausschnitt. Alle Frontends liefern denselben Tupelbaum."""
import ast
import json
import operator
import re
from pathlib import Path
from runpy import run_path

HERE = Path(__file__).resolve().parent
prefix_render = run_path(str(HERE.parent / '01_schreibweise.py'))['render']
BIN = {'+':'+','<':'<','>':'>','eq':'=='}
OPS = {'if':3,'+':2,'<':2,'>':2,'eq':2,'pair':2,'first':1,'second':1,
       'catch':4,'fail':1,'read':1}
MIN, MAX = -(1 << 63), (1 << 63)-1

class Fault(Exception):
    def __init__(self, category, detail):
        super().__init__(detail)
        self.category = category

def render(tree, form):
    if form in 'AB': return prefix_render(tree, form == 'B')
    if isinstance(tree,str): return {'true':'True','false':'False'}.get(tree,tree)
    op,*xs = tree
    args = [render(x,form) for x in xs]
    if op == 'if': return f'({args[1]} if {args[0]} else {args[2]})'
    if op in BIN: return f'({args[0]} {BIN[op]} {args[1]})'
    return op + '(' + ', '.join(args) + ')'

def parse(source, form, arities):
    arity = OPS | arities
    def wrong(msg): raise Fault('syntax',msg)
    def count(op,n,pos):
        if op not in arity: wrong(f'Spalte {pos}: unbekannter Aufruf {op}')
        if arity[op] != n: wrong(f'Spalte {pos}: {op} erwartet {arity[op]} Operanden, hat {n}')
    if form == 'C':
        try: root = ast.parse(source,mode='eval').body
        except SyntaxError as e: wrong(f'Spalte {e.offset}: {e.msg}')
        def convert(n):
            if isinstance(n,ast.Name): return n.id
            if isinstance(n,ast.Constant) and type(n.value) in (bool,int,str):
                return json.dumps(n.value)
            if isinstance(n,ast.UnaryOp) and isinstance(n.op,ast.USub) and isinstance(n.operand,ast.Constant) and type(n.operand.value) is int:
                return str(-n.operand.value)
            if isinstance(n,ast.IfExp): return ('if',convert(n.test),convert(n.body),convert(n.orelse))
            if isinstance(n,ast.BinOp) and isinstance(n.op,ast.Add): return ('+',convert(n.left),convert(n.right))
            if isinstance(n,ast.Compare) and len(n.ops)==1:
                sym = {ast.Lt:'<',ast.Gt:'>',ast.Eq:'eq'}.get(type(n.ops[0]))
                if sym: return (sym,convert(n.left),convert(n.comparators[0]))
            if isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and not n.keywords:
                args = tuple(convert(x) for x in n.args)
                count(n.func.id,len(args),n.end_col_offset)
                return (n.func.id,*args)
            wrong(f'Spalte {n.col_offset+1}: Ausdruck außerhalb der Referenzkarte')
        return convert(root)

    tokens = [(m.group(),m.start()+1) for m in re.finditer(r'"(?:[^"\\]|\\.)*"|[()]|[^\s()]+',source)]
    i = 0
    def take(context):
        nonlocal i
        if i == len(tokens): wrong(f'Spalte {len(source)+1}: Ende, {context} fehlt')
        item = tokens[i]
        i += 1
        return item
    def expr(context):
        tok,pos = take(context)
        if form == 'A':
            if tok in ('(',')'): wrong(f'Spalte {pos}: Klammer in A')
            if tok in arity:
                return (tok,*(expr(f'{tok} Argument {j+1}') for j in range(arity[tok])))
            return tok
        if tok == '(':
            op,_ = take('Operation')
            args = []
            while i < len(tokens) and tokens[i][0] != ')':
                args.append(expr(op))
            _,end = take(')')
            count(op,len(args),end)
            return (op,*args)
        if tok == ')' or tok in arity: wrong(f'Spalte {pos}: unerwartet {tok}')
        return tok
    tree = expr('Ausdruck')
    if i < len(tokens): wrong(f'Spalte {tokens[i][1]}: Rest nach vollständigem Ausdruck')
    return tree

def signature(header):
    left,ret = header.split(' > ')
    name,*fields = left.split()
    return name, (dict(f.split(':') for f in fields),ret)

def literal(atom):
    if atom in ('true','false'): return 'b',atom=='true'
    if re.fullmatch(r'-?\d+',atom):
        value = int(atom)
        if MIN <= value <= MAX: return 'i',value
    if atom.startswith('"'): return 't',json.loads(atom)
    raise Fault('typ','unbekannter Wert '+atom)

def valid(condition, msg):
    if not condition: raise Fault('typ',msg)

def infer(node, scope, signatures):
    if isinstance(node,str):
        return scope[node] if node in scope else literal(node)[0]
    op,*args = node
    def typed(x): return infer(x,scope,signatures)
    if op == 'catch':
        code,body,binder,alt = args
        valid(code in ('E_DATA','E_OVERFLOW') and binder=='_', 'unzulässiger Handler')
        a,b = typed(body),typed(alt)
    elif op == 'if':
        valid(typed(args[0]) in ('b','!'), 'if Argument 1 erwartet b')
        a,b = typed(args[1]),typed(args[2])
    else:
        ts = [typed(arg) for arg in args]
        if op == 'pair': return '&'+''.join(ts)
        if op in ('first','second'):
            # Alle Paare in den Aufgaben haben zwei skalare Felder.
            valid(re.fullmatch('&[bit][bit]',ts[0]) is not None,op+' erwartet ein skalares Paar')
            return ts[0][1 if op=='first' else 2]
        if op in BIN: want,ret = ['i','i'], ('i' if op=='+' else 'b')
        elif op == 'fail': want,ret = ['t'],'!'
        elif op == 'read': want,ret = ['r'],'t'
        else:
            params,ret = signatures[op]
            want = list(params.values())
        for j,(got,expected) in enumerate(zip(ts,want),1):
            valid(got in (expected,'!'), f'{op} Argument {j}: erwartet {expected}, erhalten {got}')
        return ret
    valid(a==b or '!' in (a,b),op+' mit verschiedenen Ergebnistypen')
    return b if a=='!' else a

def compile_program(functions, form, edits):
    signatures = dict(signature(h) for h,_ in functions)
    if not edits.keys() <= signatures.keys(): raise ValueError('unbekannte Funktionsabgabe')
    arities = {name:len(args) for name,(args,_) in signatures.items()}
    trees = {}
    for header,by_form in functions:
        name = header.split()[0]
        source = edits.get(name,by_form[form])
        if source is None: raise Fault('syntax','leerer Rumpf '+name)
        tree = parse(source,form,arities)
        params,ret = signatures[name]
        valid(infer(tree,params,signatures) in (ret,'!'),'Ergebnistyp '+name)
        trees[name] = tree
    return trees, signatures

def run(program, name, *values, budget=128):
    trees,signatures = program
    def call(f,vs):
        return ev(trees[f],dict(zip(signatures[f][0],vs,strict=True)))
    def ev(node,env):
        nonlocal budget
        budget -= 1
        if budget < 0: raise Fault('laufzeit','E_LIMIT')
        if isinstance(node,str): return env[node] if node in env else literal(node)[1]
        op,*xs = node
        if op == 'if': return ev(xs[1] if ev(xs[0],env) else xs[2],env)
        if op == 'catch':
            try: return ev(xs[1],env)
            except Fault as e:
                if e.category!='laufzeit' or str(e).split('(')[0]!=xs[0]: raise
            return ev(xs[3],env)
        args = [ev(x,env) for x in xs]
        if op == '+':
            v = sum(args)
            if not MIN <= v <= MAX: raise Fault('laufzeit','E_OVERFLOW')
            return v
        if op in ('<','>','eq'): return {'<':operator.lt,'>':operator.gt,'eq':operator.eq}[op](*args)
        if op == 'pair': return tuple(args)
        if op in ('first','second'): return args[0][0 if op=='first' else 1]
        if op == 'fail': raise Fault('laufzeit','E_DATA('+json.dumps(args[0])+')')
        # Dieser Prüfstand vergibt keine Leserechte.
        if op == 'read': raise Fault('laufzeit','E_CAPABILITY')
        return call(op,args)
    return call(name,values)
