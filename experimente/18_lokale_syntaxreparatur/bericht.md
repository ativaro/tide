# Eine fehlende Klammer im Reparaturablauf

Im dritten Journallauf mit Vergleichsbibliothek änderte die zweite Modellantwort genau ein Zeichen. Die neue TIDE-Werkbank konnte dieselbe Korrektur aus der ersten Antwort und der Compilerdiagnose ableiten. Für diesen beobachteten Fall entfiel ein Modellaufruf mit 20.708 Gesamttokens. Im anschließenden Blindvergleich an einer neuen Doppelregression lösten alle acht Antworten den Fehler auf Anhieb. Dort kam die lokale Korrektur nie zum Einsatz. [Historische Antworten](../17_prioritaeten/messung.json) · [Neue Blindläufe](blindmessung.json)

## Der beobachtete Ausfall

Die erste Antwort hatte zwei Funktionen in verschiedenen Dateien ersetzt. Der Compiler meldete `E_SYNTAX` und `Missing operand` in der geänderten Funktion `earlier`, unmittelbar hinter dem letzten Token. Der TIDE-Aufruf `closing_retry` gleicht Datei, Funktionskopf, eingereichten Rumpf, Zeile und Spalte mit der Kandidatenkopie ab. Er fügt an dieser Stelle einmal ein `)` ein und reicht den zweiten Edit unverändert weiter. Der Aufrufer erzeugt aus der ursprünglichen Quellfassung einen neuen Kandidaten und führt die reguläre Prüfung aus. Der Beispielablauf wurde auch für bereits korrekten Code und eine typfalsche Antwort überprüft. [Werkzeug und TIDE-Beispiele](../../workbench/function_body.tide) · [Ausführbarer Ablauf](../../workbench/README.md#gruppierte-funktionsrümpfe-reparieren)

| Messgröße | Ursprünglicher Journallauf | Erste Antwort mit lokaler Korrektur |
|---|---:|---:|
| Tatsächliche Gesamttokens der benötigten Modellantworten | 40.948 | 20.240 |
| Modellantworten | 2 | 1 |
| Zeit bis zur ersten Antwort im ursprünglichen Lauf | 13,46 s | 13,46 s |
| Gesamtzeit bis zur öffentlichen Abnahme | 31,09 s gemessen | 13,70 s rekonstruiert |
| Öffentliche und verdeckte Fälle auf frischer Kopie | 40 + 40 bestanden | 40 + 40 bestanden |

Für die Rekonstruktion wurde die Zeit nach Vorliegen der ersten Antwort zwölfmal neu gemessen. Sie umfasst das Anwenden der ersten Antwort, den fehlgeschlagenen Prüflauf, die lokale Ergänzung, das erneute Anwenden und die erfolgreiche öffentliche Abnahme. Ihr Median betrug 0,243 s bei einer Spanne von 0,238 bis 0,252 s. Die erste Modellantwort und ihre Latenz stammen aus dem ursprünglichen Protokoll. Für den lokalen Schritt liefen keine Modellaufrufe. [Messplan](versuchsplan.md) · [Messwerte und Eingabepaket](replay.json)

Im Projektverzeichnis lässt sich die genaue Korrektur anhand der archivierten Daten nachvollziehen.

```sh
set -euo pipefail
data=experimente/18_lokale_syntaxreparatur/replay.json
./tide run workbench/function_body.tide --call closing_retry \
  --inputs "$(jq -c .natural_input "$data")" |
  jq -e --slurpfile saved "$data" '.some == $saved[0].expected_corrected_edits'
```

## Welche Fehler der Ablauf abdeckt

Alle 24 bereits korrekten TIDE-Einreichungen bestanden auf einer neuen Kopie mit ihrem ursprünglichen Text. Anschließend wurde bei jedem ihrer zwei Funktionsrümpfe einzeln die letzte Klammer entfernt. In allen 48 Fällen rekonstruierte die Werkbank das vollständige korrekte Edit-Set. Jede Lösung bestand alle 40 öffentlichen und 40 verdeckten Fälle ihrer Aufgabe. Viele Antworten waren identisch. Die 48 Varianten enthielten sechs verschiedene fehlerhafte Edit-Sets. [Protokolle mit Inhaltshashes](replay.json)

| Gegenprobe | Ergebnis nach höchstens einem lokalen Versuch |
|---|---|
| Ein tatsächlicher Operand fehlt | Der Compiler verwirft die vorgeschlagene Ergänzung. |
| Zwei schließende Klammern fehlen | Auch nach dem ersten Vorschlag meldet der Compiler einen Syntaxfehler. |
| Eine schließende Klammer ist zu viel | Die Werkbank liefert keinen Vorschlag. |
| Die Funktion liefert einen Integer statt eines Wahrheitswerts | Der Typfehler bleibt sichtbar. |
| Die Klammer fehlt und die Vergleichsregel ist fachlich falsch | Der ergänzte Ausdruck besteht die Typprüfung, 33 von 40 öffentlichen Fällen schlagen fehl. |

Der Mechanismus hängt an der Diagnoseform des aktuellen Compilers. Die fachliche Prüfung durch den Aufrufer ist erforderlich, auch wenn die lokale Ergänzung einen kompilierbaren Ausdruck ergibt.

## Neuer Blindvergleich

Im bestehenden Journalprogramm steckte eine neue Doppelregression. Identische Ereignisse wurden als Umkehr gewertet. Außerdem wurde die Länge des letzten Intervalls als längstes Intervall ausgegeben. Die Fehler lagen in verschiedenen Modulen. Beide Sprachfassungen lieferten vor der Reparatur auf allen 84 Eingaben übereinstimmende Ergebnisse. Öffentlich bestanden zunächst 18/42 Fälle. Die beiden isolierten Referenzänderungen brachten das Ergebnis einzeln auf 22/42 und 37/42. Mit beiden Änderungen bestanden alle 42 öffentlichen und 42 verdeckten Prüfungen. [Vorab festgelegte Änderungen, Fälle, Reihenfolge und Befehle](blindplan.json)

Vier zeitlich gepaarte Wiederholungen liefen mit vorbereiteten Quellen und dem ersten öffentlichen Fehlschlag für beide Sprachen. Der Auftrag benannte keine Datei oder fehlerhafte Funktion. Beide Verfahren verwendeten benannte Funktionsersetzungen. Jede Sprache begann zweimal. Die acht ephemeren Sitzungen nutzten `gpt-6-astra` mit `xhigh` und angeforderter Serviceklasse `priority`. Alle acht Antworten bestanden im ersten Versuch und erneut auf frischen Kopien einschließlich der verdeckten Fälle. Es gab keine zusätzlichen Werkzeugaufrufe des Modells. [Prompts, Antworten, Tokenzähler und Zeiten](blindmessung.json)

| Je vier Läufe | TIDE | Python |
|---|---:|---:|
| Zeit bis zur bestandenen Abnahme, Median | 10,54 s | 7,77 s |
| Gesamttokens, Median | 19.929,5 | 19.728,5 |
| Kontextvorbereitung einschließlich anfänglicher Fehlprüfung, Median | 0,58 s | 0,04 s |
| Gesamttokens, Summe | 79.693 | 78.900 |
| Gesamttokens abzüglich Cachetreffern, Summe | 6.605 | 7.220 |

Die mediane Differenz **innerhalb der Paare** betrug +2,63 s und +195,5 Gesamttokens für TIDE. TIDE war in einem von vier Paaren schneller und in keinem bei den Gesamttokens sparsamer. Die Werkbank behebt den belegten Wiederholungsgrund. Der größere Aufwand bei regulären Erstlösungen bleibt eine eigene Messfrage. Die Vorbereitung vor der Modellübergabe dauerte bei TIDE in jedem Paar länger, mit Differenzen zwischen 0,54 und 0,70 s.
