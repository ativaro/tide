# Genügt eine Klammer um die bearbeitete Stelle?

Bei sechs neuen Aufgaben habe ich jede Erstabgabe in jeder Schreibweise korrekt gelöst. Eine einzige Klammerung half dem Prüfer in fünf zusätzlichen Fehlerfällen. In allen fünf gehörte der gelöschte Wert unmittelbar zur markierten Operation.

## Mein Selbstversuch

Ich schrieb die vollständigen Rümpfe selbst. Alle drei Ansichten zeigten denselben Auftrag, dasselbe sichtbare Beispiel und dieselbe Angabe, welcher Operand im Editor ausgewählt war. In **P** blieb das Präfix klammerfrei. In **L** umschloss genau ein Klammerpaar die ausgewählte Operation. In **V** war jeder Aufruf geklammert. Die Auswahl stand vorab fest und blieb während einer Aufgabe am selben Strukturpfad. Bei K6 lag sie bewusst auf der anderen Seite des Defekts.

| Aufgabe | Reihenfolge | Klammerfrei | Eine Markierung | Vollständig geklammert | Geprüfte Eingaben je Form |
|---|---|---|---|---|---:|
| K1 · Nahversand bei Menge null ändern | PLV | ✓ | ✓ | ✓ | 1.251 |
| K2 · Preiskorrektur außerhalb des Überlaufhandlers ergänzen | LVP | ✓ | ✓ | ✓ | 3.126 |
| K3 · Archiv bei Punktgleichstand nach Kennung entscheiden lassen | VPL | ✓ | ✓ | ✓ | 1.251 |
| K4 · Fehlenden Summanden in der ausgewählten Addition reparieren | PVL | ✓ | ✓ | ✓ | 251 |
| K5 · Fehlenden Summanden innerhalb eines ausgewählten Zweigs reparieren | VLP | ✓ | ✓ | ✓ | 1.251 |
| K6 · Fehlenden Summanden unmittelbar vor der Auswahl reparieren | LPV | ✓ | ✓ | ✓ | 1.251 |

Jeder Haken steht für eine erfolgreiche Erstabgabe. Alle sechs Reihenfolgen kamen einmal vor. Ich sicherte die 18 Antworten vor dem ersten Prüferfeedback. Pro Form wurden insgesamt 8.381 Eingaben geprüft, einschließlich des sichtbaren Beispiels pro Aufgabe. Das übrige Raster umfasst auch die beiden i64-Grenzen. Der Prüfstand verwendet für alle Ansichten denselben Parser und aus dem vorigen Versuch denselben Typprüfer und Auswerter. Auch die fertigen Programmbäume stimmten bei jeder Aufgabe über alle drei Formen überein.

**Beim Ändern des Preises** trennte die Klammer um das linke Ergebnis dieses gut vom unveränderten rechten Ergebnis. Sobald ich die Korrektur ergänzte, stand in meiner lokalen Fassung aber `(+ catch E_OVERFLOW + l reserve _ ersatz k)`. Um zu entscheiden, ob der Handler einen Überlauf der Korrektur abfängt, musste ich die Argumente wieder zuordnen. Erst `(+ (catch E_OVERFLOW (+ l reserve) _ ersatz) k)` zeigte die für diesen Auftrag entscheidende Grenze vor `k`.

## Wie genau konnte der Parser den Defekt lokalisieren?

Für die separate Diagnosemessung habe ich in den sechs intakten Ausgangsprogrammen an jeder möglichen Stelle genau einen Wertoperanden gelöscht. Fehlercode und Bindungszeichen des Handlers blieben fest. Jede der 37 Löschungen wurde in allen drei Ansichten wiederholt. Alle 111 beschädigten Programme wurden zurückgewiesen.

Als Treffer zählt, wenn die erste Diagnose **genau das ursprüngliche Vorkommen der Operation** nennt, deren direkter Operand gelöscht wurde. Zwei verschiedene Additionen sind dabei verschiedene Stellen. Die Positionen des Originals waren nur der Auswertung bekannt. Der Parser erhielt den beschädigten Text.

| Ort der Löschung | Klammerfrei | Eine Markierung | Vollständig geklammert |
|---|---:|---:|---:|
| Direkter Operand der markierten Operation | 3/8 | **8/8** | 8/8 |
| Tiefer innerhalb der Markierung | 4/16 | 4/16 | **16/16** |
| Außerhalb der Markierung | 9/13 | 9/13 | **13/13** |
| **Gesamt** | **16/37** | **21/37** | **37/37** |

Bei K5 sollte die gültige Probe `roh + offset` liefern, sonst den letzten Wert. Nach dem Löschen von `offset` ergaben sich diese Diagnosen:

| Ansicht | Beschädigter Rumpf | Erste Diagnose |
|---|---|---|
| Klammerfrei | `pair if gueltig + roh letzte + zaehler 1` | Am Ende fehlt Argument 2 von `pair`. |
| Um die erste Komponente | `pair (if gueltig + roh letzte) + zaehler 1` | An der Klammer fehlt Argument 3 von `if`. |
| Vollständig | `(pair (if gueltig (+ roh) letzte) (+ zaehler 1))` | An der inneren Klammer fehlt Argument 2 von `+`. |

In der mittleren Zeile liest der Parser `letzte` als zweiten Summanden. Die äußere Klammer begrenzt hier die Fehlersuche auf die erste Komponente, obwohl sie den betroffenen Aufruf verfehlt. Bei K6 lag die Markierung um die gesunde rechte Komponente. Dort meldeten klammerfreie und lokale Ansicht erst am Ende das unvollständige äußere Paar.

**Nachprobe mit verschobener Auswahl.** Nach der Hauptwertung habe ich bei K5 dieselbe einzelne Klammer auf die Addition gesetzt. In `pair if gueltig (+ roh) letzte + zaehler 1` benannte der Parser die Addition direkt. Bei K6 führte `pair (+ grund) if aktiv + neu bonus neu` zum selben Ergebnis. In beiden Nachproben kannte ich die Fehlerstelle bereits. Ein Verfahren, das die richtige Operation selbst auswählt, wurde hier nicht getestet.

Auch eine genaue Operationsdiagnose lässt die fehlende Information offen. Sowohl aus `(< limit x)` als auch aus `(< x limit)` wird nach dem Entfernen von `limit` der Text `(< x)`. Für die fachlich richtige Reparatur macht die ursprüngliche Operandenseite einen Unterschied.

## Länge und Entwurfsentscheidung

| Tokenizer | Texte, jeweils sechs Rümpfe | Klammerfrei | Eine Markierung | Vollständig geklammert |
|---|---|---:|---:|---:|
| o200k_base | Ausgangstexte | 75 | 86 | 100 |
| o200k_base | Meine Erstabgaben | 99 | 109 | 132 |
| cl100k_base | Ausgangstexte | 77 | 88 | 102 |
| cl100k_base | Meine Erstabgaben | 101 | 111 | 134 |

Eine lokale Markierung kostete über meine sechs fertigen Rümpfe zehn zusätzliche Tokens. Für TIDE würde ich eine verstellbare Auswahl als Editoransicht erproben. Beim Bearbeiten des Handlers will ich seine Grenze sehen können, selbst wenn der zuletzt ausgewählte Bereich die ganze Preiskomponente war. Für eine ungeklärte Syntaxdiagnose hat die vollständig geklammerte Darstellung im Versuch jedes betroffene Aufrufvorkommen identifiziert. Eine intakte Revision könnte beim Anzeigen der vorgesehenen Struktur helfen. Wie der Editor bei unbekannten Defekten die passende Stelle findet, bleibt offen.

Ich habe Aufgaben und Sollverhalten selbst entworfen und alle Runden in derselben Sitzung bearbeitet. Weder unabhängige Erstkontakte noch Suchzeit wurden gemessen. Die 37 Löschungen stammen aus sechs kurzen Bäumen und betreffen ausschließlich fehlende Wertoperanden. Die Tokenzahlen beziehen sich auf die Programmtexte.

[Aufträge und fachliches Soll](aufgaben.py) · [Alle Erstabgaben](erstabgaben.jsonl) · [Notizen vor dem Feedback](notizen.md) · [Auswertung](versuch.py)

Zum Nachrechnen im Versuchsverzeichnis:

```sh
sha256sum -c versuchsstand.sha256
sha256sum -c erststand.sha256
python3 versuch.py werten
python3 versuch.py tokens
```

Für die funktionale Prüfung genügt die Python-Standardbibliothek. Die Tokenzählung verwendet zusätzlich tiktoken.
