"""Festgelegte Aufgaben und fachliche Sollwerte. Pfade zählen Operanden ab 1."""
from itertools import product

# Signatur, intakter Ausgangsbaum in TIDE-Präfix, Fokuspfad, Löschpfad, Auftrag, sichtbarer Fall.
TASKS = {
    'K1': ('porto base:i nah:b stueck:i ort:i fern:i > i',
           '+ base if nah + stueck ort + stueck fern', (2,), None,
           'Ändere die Tarifwahl. Bei Nahversand und stueck gleich 0 entfallen die Ortskosten. Sonst bleibt der gewählte Tarif erhalten. base wird wie bisher addiert.',
           ((4,True,0,3,8),4)),
    'K2': ('preis l:i r:i reserve:i ersatz:i k:i > &ii',
           'pair catch E_OVERFLOW + l reserve _ ersatz + r reserve', (1,), None,
           'Addiere neu k zum linken Ergebnis, auch zum Ersatzwert. Ein Überlauf dieser neuen Addition gelangt zum Aufrufer. Rechts bleibt r + reserve.',
           ((2,9,1,0,3),(6,10))),
    'K3': ('archiv aktiv:b neu:i tag:i alt:i alt_tag:i > &ii',
           'if aktiv pair neu tag if > neu alt pair neu tag pair alt alt_tag', (3,), None,
           'Aktiv übernimmt immer das neue Paar. Inaktiv gewinnt weiter der höhere Messwert. Neu gewinnt bei gleichem Messwert das Paar mit der kleineren Kennung.',
           ((False,7,3,7,9),(7,3))),
    'K4': ('bedarf frei:b soll:i reserve:i korrektur:i > i',
           'if frei + soll reserve + soll korrektur', (2,), (2,2),
           'Ein Wert fehlt. Bei Freigabe gilt soll plus reserve, sonst soll plus korrektur. Stelle das Verhalten wieder her.',
           ((True,4,3,2),7)),
    'K5': ('probe gueltig:b roh:i offset:i letzte:i zaehler:i > &ii',
           'pair if gueltig + roh offset letzte + zaehler 1', (1,), (1,2,2),
           'Ein Wert fehlt. Bei gültiger Probe liefert das erste Feld roh plus offset, sonst letzte. Das zweite Feld zählt immer um eins weiter.',
           ((True,2,6,99,1),(8,2))),
    'K6': ('angebot grund:i gebuehr:i aktiv:b neu:i bonus:i > &ii',
           'pair + grund gebuehr if aktiv + neu bonus neu', (2,), (1,2),
           'Ein Wert fehlt. Das Angebot enthält links grund plus gebuehr. Rechts steht bei aktiv neu plus bonus, andernfalls neu.',
           ((3,8,False,7,4),(11,7))),
}
ORDERS = dict(zip(TASKS, ('PLV','LVP','VPL','PVL','VLP','LPV'),strict=True))
LO,HI = -(1<<63),(1<<63)-1

def add(a,b):
    value = a+b
    if not LO <= value <= HI: raise OverflowError
    return value

def expected(task,args):
    try:
        if task == 'K1':
            base,nah,n,ort,fern = args
            tarif = 0 if nah and n==0 else add(n,ort if nah else fern)
            return add(base,tarif)
        if task == 'K2':
            l,r,reserve,fallback,k = args
            raw = l+reserve
            left = raw if LO <= raw <= HI else fallback
            return add(left,k),add(r,reserve)
        if task == 'K3':
            active,n,tag,old,prev = args
            if active: return n,tag
            return max(((old,prev),(n,tag)), key=lambda p:(p[0],-p[1]))
        if task == 'K4':
            free,need,reserve,correct = args
            return add(need,reserve if free else correct)
        if task == 'K5':
            ok,raw,offset,prev,n = args
            return (add(raw,offset) if ok else prev),add(n,1)
        if task == 'K6':
            base,fee,active,new,bonus = args
            return add(base,fee),(add(new,bonus) if active else new)
        raise KeyError(task)
    except OverflowError:
        return 'E_OVERFLOW'

def inputs(task):
    values = (LO,-1,0,2,HI)
    flags = (False,True)
    types = TASKS[task][0].split(' > ')[0].split()[1:]
    return product(*(flags if field.endswith(':b') else values for field in types))
