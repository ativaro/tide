"""Orakel und vorab definierte Prüfdomänen, unabhängig von den drei Parsern."""
from itertools import product
from pathlib import Path
from random import Random

MIN = -(1 << 63)
MAX = (1 << 63) - 1
NUMBERS = (MIN, MIN+1, -3, -1, 0, 1, 2, 5, 7, 9, MAX-1, MAX)
OV = 'E_OVERFLOW'
BAD = 'E_DATA("invalid")'

def bounded(v):
    return v if MIN <= v <= MAX else OV

def truth(t, key):
    if t == 'S1':
        return tuple(sorted(key))
    if t == 'S2':
        (a,b), dx, dy = key
        result = bounded(a+dx), bounded(b+dy)
        return OV if OV in result else result
    if t == 'S3':
        x,lo,hi,urgent,locked = key
        if locked: return 4
        if lo <= x <= hi: return int(urgent)
        return 2 if x < lo else 3
    if t == 'S4':
        active, history = False, []
        for event in key:
            spent = active and event == 2
            if event in (1,2): active = event == 1
            history.append((active,spent))
        return tuple(history)
    if t == 'A1':
        name, *args = key
        fees = [bounded(x+2) if x > 0 else 0 for x in args]
        if OV in fees: return OV
        return bounded(fees[0]+1) if name == 'invoice' else tuple(fees)
    if t == 'A2':
        credit, history = 5, [5]
        for e in key:
            if e == 1: credit = 5
            if e == 2: credit += 1
            history.append(credit)
        return tuple(history)
    if t == 'A3':
        x,y,post,bad = key
        if bad: return BAD
        mid = x+y
        return bounded((mid if MIN <= mid <= MAX else x)+post)
    if t == 'A4':
        old,tick,clear = key
        return int(tick) if clear else bounded(old+int(tick))
    if t == 'R1':
        used,limit,delta = key
        return bounded(used+delta) if used < limit else 0
    if t == 'R2':
        x,y = key
        return min(7,max(0,x)), min(9,max(2,y))
    if t == 'R3':
        (good,reading), bias = key
        return bounded(reading+bias) if good else 0
    if t == 'R4':
        return max(key, key=lambda pair: pair[0])
    raise KeyError(t)

VISIBLE = {
    'S1': [((4,-2),(-2,4))], 'S2': [(((5,-2),-1,5),(4,3))],
    'S3': [((5,5,8,True,False),1)], 'S4': [((1,1,2,2),((True,False),(True,False),(False,True),(False,False)))],
    'A1': [(('invoice',0),1),(('quote',2,0),(4,0))], 'A2': [((),(5,)),((2,1),(5,6,5))],
    'A3': [((MAX,1,-1,False),MAX-1),((1,2,0,True),BAD)], 'A4': [((7,True,True),1)],
    'R1': [((2,5,3),5),((5,5,3),0)], 'R2': [((12,-1),(7,2))],
    'R3': [(((True,8),-2),6)], 'R4': [(((5,11),(5,19)),(5,11))]
}

def domain(t):
    rng = Random(Path(__file__).with_name('stichprobe.txt').read_text().strip() + t)
    nums = (*NUMBERS, *(rng.randrange(-10000,10001) for _ in range(3)))
    flags = (False, True)
    if t in ('S4','A2'):
        for n in range(6):
            yield from product((0,1,2,3), repeat=n)
    elif t in ('S1','R2'):
        yield from product(nums, repeat=2)
    elif t == 'S2':
        for p in product(nums, repeat=2):
            yield from product([p], (-1,0,2), (-2,0,1))
    elif t == 'S3':
        for lo,hi in ((0,0),(1,5),(-3,2),(MIN,MAX)):
            yield from product(nums,[lo],[hi],flags,flags)
    elif t == 'A1':
        yield from product(['invoice'],nums)
        yield from product(['quote'],nums,nums)
    elif t == 'A3':
        yield from product(nums,nums,(-2,-1,0,1,2,MIN,MAX),flags)
    elif t == 'A4':
        yield from product(nums,flags,flags)
    elif t == 'R1':
        yield from product(nums,nums,(-2,-1,0,1,2,MAX,MIN))
    elif t == 'R3':
        yield from product(product(flags,nums),nums)
    elif t == 'R4':
        yield from product(product(nums,(0,1)),repeat=2)
    else: raise KeyError(t)

def hidden(t):
    visible = {inputs for inputs,_ in VISIBLE[t]}
    return [key for key in dict.fromkeys(domain(t)) if key not in visible]
