"""Eingefrorene Aufgabenpakete. A/B/C bezeichnet nur die Schreibweise des Rumpfs."""

FORMS = 'ABC'
ORDERS = ['ABC', 'BCA', 'CAB', 'ACB', 'CBA', 'BAC'] * 2
# Kopf, vorhandener Rumpf je Oberfläche. Ein leerer Rumpf ist der Schreibauftrag.
def fn(header, a=None, b=None, c=None):
    return header, dict(zip(FORMS, (a, b, c)))

TASKS = {
'S1': ('Ordne zwei Endpunkte aufsteigend als Paar. Gleiche Werte bleiben erhalten.',
       'sort(4,-2) → (-2,4)', [fn('sort x:i y:i > &ii')]),
'S2': ('Verschiebe einen Punkt p um dx und dy. Addiere jeweils nur zur passenden Koordinate.',
       'move((5,-2),-1,5) → (4,3)', [fn('move p:&ii dx:i dy:i > &ii')]),
'S3': ('Klassifiziere eine Sendung. Sperre hat immer Code 4. Sonst liefert x unter lo Code 2, über hi Code 3, im geschlossenen Intervall bei Eilgut Code 1, sonst 0. lo ≤ hi.',
       'route(5,5,8,true,false) → 1. Reihenfolge: x,lo,hi,eil,sperre.',
       [fn('route x:i lo:i hi:i eil:b sperre:b > i')]),
'S4': ('Ein Gutschein ist anfangs inaktiv. Ereignis 1 aktiviert, 2 verbraucht ihn, andere lassen ihn wie er war. Liefere (danach aktiv, jetzt erfolgreich eingelöst). Erneutes Aktivieren sammelt keine Gutscheine.',
       'Folge 1,1,2,2 → (true,false),(true,false),(false,true),(false,false).',
       [fn('step aktiv:b event:i > &bb')]),
'A1': ('Ändere die gemeinsame Gebühr. Nur für strikt positives x gilt x+2. Sonst beträgt die Gebühr 0. Beide Aufrufer behalten ihre jeweilige Berechnung.',
       'invoice(0) → 1, quote(2,0) → (4,0).', [
       fn('fee x:i > i','+ x 2','(+ x 2)','x + 2'),
       fn('invoice x:i > i','+ fee x 1','(+ (fee x) 1)','fee(x) + 1'),
       fn('quote x:i y:i > &ii','pair fee x fee y','(pair (fee x) (fee y))','pair(fee(x), fee(y))')]),
'A2': ('Ein Kontingent startet bei 5 statt 2. Auch eine Verlängerung (Ereignis 1) setzt es auf denselben benannten Anfangswert. Bei 2 kommt eine Einheit hinzu, sonst bleibt es erhalten.',
       'Leere Folge startet bei 5. Folge 2,1 liefert 6,5.', [
       fn('basis > i','2','2','2'),
       fn('step alt:i event:i > i','if eq event 1 basis if eq event 2 + alt 1 alt',
          '(if (eq event 1) (basis) (if (eq event 2) (+ alt 1) alt))',
          'basis() if event == 1 else (alt + 1 if event == 2 else alt)')]),
'A3': ('Beim Berechnen des Zwischenergebnisses via subtotal soll ausschließlich E_OVERFLOW durch x ersetzt werden. Danach post addieren. Ein Überlauf dieser letzten Addition sowie E_DATA aus subtotal gelangen weiterhin zum Aufrufer.',
       'finish(MAX,1,-1,false) → MAX-1. finish(1,2,0,true) → E_DATA("invalid").', [
       fn('subtotal x:i y:i bad:b > i','if bad fail "invalid" + x y','(if bad (fail "invalid") (+ x y))','fail("invalid") if bad else x + y'),
       fn('finish x:i y:i post:i bad:b > i','+ subtotal x y bad post','(+ (subtotal x y bad) post)','subtotal(x,y,bad) + post')]),
'A4': ('Ein Schritt trägt zwei Merker. Bisher gewann tick bei gleichzeitigem clear. Neu zuerst clear auf 0 anwenden, dann bei tick um 1 erhöhen. Alle anderen Kombinationen behalten ihr Verhalten.',
       'step(7,true,true) → 1. Reihenfolge: alt,tick,clear.', [
       fn('step alt:i tick:b clear:b > i','if tick + alt 1 if clear 0 alt','(if tick (+ alt 1) (if clear 0 alt))','alt + 1 if tick else (0 if clear else alt)')]),
'R1': ('Ein Operand wurde gelöscht. Falls used < limit, erhöhe used um delta, andernfalls liefere 0. Notiere vor der Abgabe auch, bei welcher Operation und an welcher Argumentstelle die Ursache liegt.',
       'bump(2,5,3) → 5, bump(5,5,3) → 0.', [
       fn('bump used:i limit:i delta:i > i','if < used limit + used 0','(if (< used limit) (+ used) 0)','used +  if used < limit else 0')]),
'R2': ('cap wurde von zwei auf drei Parameter erweitert. Repariere die Aufrufe für zwei Kanäle. Links gilt das geschlossene Intervall [0,7], rechts [2,9].',
       'channels(12,-1) → (7,2).', [
       fn('cap x:i lo:i hi:i > i','if < x lo lo if > x hi hi x','(if (< x lo) lo (if (> x hi) hi x))','lo if x < lo else (hi if x > hi else x)'),
       fn('channels left:i right:i > &ii','pair cap left 0 cap right 2','(pair (cap left 0) (cap right 2))','pair(cap(left,0), cap(right,2))')]),
'R3': ('sample enthält (gültig,Messwert). Bei gültiger Probe Messwert plus bias liefern, andernfalls 0. Repariere die Verwechslung der Felder.',
       'adjust((true,8),-2) → 6.', [
       fn('adjust sample:&bi bias:i > i','if first sample + first sample bias 0','(if (first sample) (+ (first sample) bias) 0)','first(sample) + bias if first(sample) else 0')]),
'R4': ('Jedes Paar enthält (Punkte,Kennung). Wähle das höher bewertete Paar, bei Gleichstand das bereits vorhandene best. Der Starttext verletzt eine dieser Bedingungen.',
       'pick((5,11),(5,19)) → (5,11).', [
       fn('pick best:&ii neu:&ii > &ii','if > first best first neu best neu','(if (> (first best) (first neu)) best neu)','best if first(best) > first(neu) else neu')])
}

COMMON = ('Gib nur neue oder geänderte Rümpfe mit Funktionsnamen ab. Unveränderte Funktionen bleiben verfügbar. '
          'i = checked i64, b = bool, &XY = Paar. if wertet nur den gewählten Zweig aus. '
          'Aufrufe werten Argumente von links nach rechts aus. Fehlercodes und Paarreihenfolge sind beobachtbar.')
CARDS = {
'A':'Präfix mit fester Stelligkeit, auch eigene Funktionen. Beispiele: if < a b + a 1 b | pair a b | first p | second p | eq a b | true false | f a b | basis | catch E_OVERFLOW ausdruck _ ersatz | fail "invalid".',
'B':'Jede Operation und jeder Aufruf vollständig geklammert. Beispiele: (if (< a b) (+ a 1) b) | (pair a b) | (first p) | (second p) | (eq a b) | true false | (f a b) | (basis) | (catch E_OVERFLOW ausdruck _ ersatz) | (fail "invalid").',
'C':'Python-ähnliche Ausdrücke. Beispiele: a + 1 if a < b else b | pair(a,b) | first(p) | second(p) | a == b | True False | f(a,b) | basis() | catch(E_OVERFLOW, ausdruck, _, ersatz) | fail("invalid").'
}

def packet(task, form):
    brief, visible, funcs = TASKS[task]
    return '\n'.join([COMMON, CARDS[form], task + ' ' + brief, visible,
                      *[h + '\n' + (body[form] or '…') for h, body in funcs]])
