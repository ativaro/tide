# TIDE 0.6 · Listen abbilden und Fehler lokalisieren

Eine Liste aus Paaren enthält je einen Cursor und einen Status. Gesucht sind alle Cursorpositionen in Eingabereihenfolge. Die bisherige Lösung bildet bei jedem `append` einen neuen logischen Listenwert. Bei 723 Positionen passt die Summe dieser Werte noch ins Gastbudget. Bei 724 bricht dieselbe korrekte Rechnung mit `E_LIMIT` ab. In TIDE 0.6 beschreibt `map` die Berechnung für ein Element. Die Ergebnisliste wird dem Budget einmal zugerechnet.

```tide
map i entries item (get pos (first item))
```

Mit `o200k_base` hat dieser Ausdruck **11 Tokens**. Der bisherige Ausdruck `fold entries (list i 0) seen row item (append seen (get pos (first item)))` hat **21 Tokens**. Der deklarierte Rückgabetyp bleibt `*i`. [Beispielprogramm](../../native/bootstrap/fixtures/functions/maps.tide)

## Laufzeit vom Prozessstart bis zum Ergebnis

| Paare | TIDE 0.5 mit `fold` | Erste `map`-Fassung | TIDE 0.6 mit `map` | CPython |
|---:|---:|---:|---:|---:|
| 1 | 6,17 ms | 5,93 ms | 6,03 ms | 9,57 ms |
| 256 | 9,71 ms | 9,38 ms | 8,99 ms | 9,82 ms |
| 640 | 15,32 ms | 14,48 ms | 13,67 ms | 10,08 ms |
| 723 | 16,67 ms | 15,55 ms | 14,46 ms | 10,18 ms |
| 724 | `E_LIMIT` | 15,41 ms | 14,44 ms | 10,22 ms |
| 1.024 | `E_LIMIT` | 19,71 ms | 18,42 ms | 10,65 ms |
| 3.000 | `E_LIMIT` | 47,43 ms | 43,04 ms | 12,98 ms |
| 4.095 | `E_LIMIT` | 58,64 ms | 52,21 ms | 13,49 ms |

Je Zelle wurden nach drei Aufwärmrunden 21 serielle Aufrufe auf demselben CPU-Kern gemessen. Die Reihenfolge wechselte. Die Tabelle gibt die Mediane an. Beide Programme erhielten dieselben JSON-Bytes und lieferten bei Erfolg dieselbe vollständige Ausgabe. Jede Ausgabe wurde mit unabhängig erzeugten Sollwerten verglichen. Der TIDE-Aufruf prüft den Projekt-Pin und lädt die Quelldatei. Das direkte CPython-Programm prüft bei der Eingabe unter anderem Feldnamen, Status und i64-Wertebereich. Erhoben wurde die gesamte CLI-Laufzeit. [Eingabegenerator, CPython-Fassung, Quartile und Rohzeiten](messung.json)

In der ersten Fassung lief jeder Rumpf durch den gewöhnlichen Auswerter. Die zweite kann Ketten aus `get`, `first` und `second` auf zusammengesetzten Elementen in einem Durchgang ausführen, wenn das Ergebnis eine Ganzzahl oder ein Wahrheitswert ist. Bei knappem Budget übernimmt der gewöhnliche Auswerter und bestimmt die genaue Fehlerstelle. Tests vergleichen verbleibende Arbeit, verbleibenden Speicher und Diagnose bei beiden Ausführungswegen. Große Listen bleiben bei diesem End-to-End-Auftrag in CPython deutlich schneller. [Auswerter](../../native/bootstrap/function_run.tide) · [Budgettests](../../native/bootstrap/checks.tide)

Für 4.095 Paare wurden kurze Feldwerte verwendet. Schon 4.096 dieser Paare benötigen im JSON-Aufruf 131.085 Eingabebytes. Deshalb wurde die Sprachgrenze separat geprüft. Ein TIDE-Programm erzeugte aus 4.096 Zahlen die typisierten Paare im Speicher. Die Projektion lieferte alle 4.096 erwarteten Positionen. Bei 4.097 Eingabezahlen meldete der öffentliche Starter `E_INPUT` am Pfad `/xs/4096`. Eine weitere Prüfung bildete jede von 4.096 Zahlen auf denselben Unicode-Text ab. 251 Zeichen pro Ergebnis passten ins Budget, 252 ergaben `E_LIMIT` am letzten Element mit `map_index: 4095`.

## Zwei neue Fehler über je drei Dateien

Die Verträge für Gleichstand und Rundung stammen aus dem früheren Blindvergleich. Für diese Werkzeugmessung wurden die damaligen Fehler zuerst korrigiert. In jeder Sprache bestanden pro Aufgabe sieben öffentliche und 72 weitere Fälle. Anschließend wurde derselbe neue Fehler in die TIDE- und die Python-Fassung eingesetzt. Beim Gleichstand bewertet die Distanzfunktion eine Koordinate links vom Ursprung um eins zu weit entfernt. Bei der Rundung schneidet die Rückumwandlung negativer Ergebnisse den halben Schritt ab. Die vorbereiteten Befunde zeigen für den ersten Fall Sollwert 7 und Istwert 13, für den zweiten Sollwert 90 und Istwert 100. Jeder Befund enthält die drei relevanten Funktionsdefinitionen. [Verträge und ursprünglicher Versuch](../38_fehlerkontext/bericht.md)

| Werkzeug und Ausgabe | Gleichstand, Tokens | Median | Rundung, Tokens | Median |
|---|---:|---:|---:|---:|
| TIDE `test --explain` | 267 | 5,48 ms | 261 | 5,39 ms |
| TIDE `test --explain=executed` | 331 | 5,64 ms | 303 | 5,47 ms |
| CPython mit vorbereitetem statischem Kontext | 298 | 16,96 ms | 288 | 16,88 ms |

Die Tokenzahlen der Tabelle umfassen die tatsächliche Werkzeugausgabe einschließlich Zeilenende. Beide TIDE-Ansichten zeigen beim Gleichstand und der Rundung alle drei Funktionen. Die Ausführungsspur fügt die besuchten Zweige hinzu und kostet 64 beziehungsweise 42 Tokens. Die Python-Vergleichshilfe liest die Quelldateien, analysiert deren Syntaxbäume, führt die Beispiele aus und gibt JSON mit Leerzeichen aus. Nach gleicher kompakter JSON-Serialisierung ohne Zeilenende ergeben sich für die statischen Befunde **267 gegenüber 257 Tokens** beim Gleichstand und **261 gegenüber 245** bei der Rundung. Der scheinbare Tokenvorsprung von TIDE in der Rohantwort hängt hier von der Formatierung ab. Die 21 Wiederholungen je Variante messen die Bereitstellung des Befunds. Modell-Gesamttokens und Zeit bis zur selbst gefundenen Reparatur wurden nicht erhoben. [Beide Quellfassungen, Befunde und Einzelzeiten](messung.json)

## Prüfung im Spiel und im Paket

Space Invaders verwendet `map` jetzt beim Anlegen der Bunker, beim Marsch der Aliens und beim Aktualisieren der getroffenen Bunker. Die elf Spielbeispiele bestanden. Für 128 Spielschritte mit Bewegung, Schüssen, Pause und Fortsetzung waren alle ausgegebenen Spielzustände bytegleich mit der vorherigen Fassung. Sieben gerenderte Szenen und 23 gezielte Aufrufe für Formation und Bunkertreffer stimmten ebenfalls überein. [Spielregeln](../../apps/invaders_game.tide)

Die neue Funktionsfixture besteht mit ihren Imports 20 Beispiele. 68 zusätzliche CLI-Prüfungen deckten unter anderem typisierte Lücken, revisionsgebundene Änderungen, Quellfehler, Fehlerweitergabe, Überlänge und die Reihenfolge der Ergebnisse ab. `make test` und `make check-no-python` bestanden. Das Paket auf Linux x86-64 wurde aus den Quellen ohne Python gebaut und im separaten Laufzeitabbild geprüft. `map` ist im öffentlichen Projektauswerter und im Bootstrap-Compiler verfügbar. Der eigenständige ELF-Exporter `tide build` unterstützt weiterhin seinen dokumentierten Sprachausschnitt. [Nativer Build](../../native/README.md) · [Abnahmeprotokoll](messung.json)
