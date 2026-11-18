# Tokenmessung zur Modellschreibweise

Gemessen am 16. November 2026 mit tiktoken 0.14.0. Gezählt wurde jeweils der vollständige gezeigte Quelltext ohne abschließenden Zeilenumbruch, Markdown oder Chat-Hülle. Beide Kodierungen stammen aus derselben Tokenizer-Familie. Es gab keinen Modellaufruf. [tiktoken](https://github.com/openai/tiktoken)

| Funktion | Kodierung | Entwurf 0.1 | 0.1 minifiziert | Entwurf 0.2 |
|---|---|---:|---:|---:|
| twice | `o200k_base` | 16 | 14 | 10 |
| twice | `cl100k_base` | 16 | 14 | 10 |
| higher | `o200k_base` | 26 | 21 | 14 |
| higher | `cl100k_base` | 26 | 21 | 14 |
| maximum | `o200k_base` | 105 | 75 | 39 |
| maximum | `cl100k_base` | 105 | 74 | 39 |

Für das Messwertprogramm sinkt die Quelltextmenge von 105 auf 39 Tokens (63 %). Gegen die minifizierte Fassung des früheren Entwurfs beträgt die Einsparung 47 bis 48 %. Eine zusätzliche Kontrolle verwendet dieselben kurzen Namen und neuen Operationen wie 0.2 in einer minifizierten geklammerten Darstellung. Sie belegt 44 Tokens in beiden Kodierungen. Gegen diese Kontrollform spart das neue Format fünf Tokens (11 %). Der größere Teil des Gesamtgewinns liegt also in der Darstellung des Programms mit weniger expliziten Schritten und kürzeren Namen. Der Einfluss einzelner Operationen wurde hierbei nicht isoliert.

Für die Auswahl der Sprache sind Referenz, Eingangskontext, Änderungen, Reparaturen, Erfolg und Zeit ebenfalls zu messen. Die drei kurzen, von Hand geschriebenen Beispiele zeigen die Größe einer bestimmten Darstellung. Statistische Aussagen über Modellleistung oder Laufzeit brauchen eigene Versuche.

## Kosten aussagekräftiger Namen

In einer zweiten Messung haben wir ausschließlich die fünf lokalen Namen ausgetauscht. Aus `b k x n p` wurden an denselben Stellen `best row line value previous`. Die aktuellen Programme stehen im [Sprachentwurf](../SPEC.md). Beide Kodierungen ergaben dieselben Werte.

| Vollständiges Programm | Kurze Namen | Aussagekräftige Namen |
|---|---:|---:|
| Maximum | 39 Tokens | 39 Tokens |
| Maximum mit erster Fundstelle | 46 Tokens | 46 Tokens |

Für diese beiden Programme können wir die Bedeutung der Werte direkt ausdrücken, ohne zusätzliche Tokens zu verbrauchen. Ob ein Modell damit weniger fachliche Fehler macht, ist offen.

## Zählung wiederholen

Für jede unten gezeigte Zeichenfolge gilt folgender Zählweg. Die minifizierten Fassungen sind vollständig angegeben, damit Leerzeichen und Token-Grenzen reproduzierbar bleiben.

```python
import tiktoken

for name in ("o200k_base", "cl100k_base"):
    print(name, len(tiktoken.get_encoding(name).encode(source)))
```

## twice

Entwurf 0.1

```lisp
(fn twice ((x I64)) I64 (return (add x x)))
```

Minifizierter Entwurf 0.1

```lisp
(fn twice((x I64))I64(return(add x x)))
```

Entwurf 0.2

```tide
twice x:i > i
+ x x
```

## higher

Entwurf 0.1

```lisp
(fn higher ((a I64) (b I64)) I64 (return (if (gt a b) a b)))
```

Minifizierter Entwurf 0.1

```lisp
(fn higher((a I64)(b I64))I64(return(if(gt a b)a b)))
```

Entwurf 0.2

```tide
higher a:i b:i > i
if > a b a b
```

## maximum

Entwurf 0.1

```lisp
(fn main ((input ReadText)) (Option I64)
  (var best (none I64))
  (for (nr line) (lines (read_text input))
    (let n
      (match (to_i64 line)
        (none (fail "invalid_integer" nr))
        ((some value) value)))
    (set best
      (some (match best
        (none n)
        ((some old) (if (gt n old) n old))))))
  (return best))
```

Minifizierter Entwurf 0.1

```lisp
(fn main((input ReadText))(Option I64)(var best(none I64))(for(nr line)(lines(read_text input))(let n(match(to_i64 line)(none(fail "invalid_integer" nr))((some value)value)))(set best(some(match best(none n)((some old)(if(gt n old)n old))))))(return best))
```

Entwurf 0.2

```tide
main input:r > ?i
fold lines read input nil i b k x
let n need int x "invalid_integer" k
some case b n p if > n p n p
```

## Kontrolle mit denselben Operationen wie 0.2

Minifizierte Klammerform des Messwertprogramms.

```lisp
(main((input r))(? i)(fold(lines(read input))(nil i)b k x(let n(need(int x)"invalid_integer" k)(some(case b n p(if(> n p)n p))))))
```
