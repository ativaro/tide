# Geprüfte Operatorwechsel · TIDE und Python-AST

TIDE prüft Operatorwechsel jetzt lokal gegen alle vorhandenen Beispiele. `tide test DATEI --diff --explain=candidates` liefert den Befund und die bestandenen Kandidaten. Die Suche arbeitet mit je einer Änderung des geprüften Baums im Speicher. Ein späteres `edit --edits` prüft die echte Quelländerung nochmals gegen dieselbe Revision. [Werkbank](../../workbench/README.md#einen-knoten-reparieren)

| Schnittstelle | Erfolge / Läufe | Erfolgsquote | Modellanfragen | Gesamttokens | Tokens pro Erfolg |
|---|---:|---:|---:|---:|---:|
| TIDE mit Vorprüfung | 8/15 | 53,3 % | 3 | 531 | 66,4 |
| Python-AST mit Vorprüfung | 11/15 | 73,3 % | 3 | 555 | 50,5 |

Die drei zusätzlichen Python-Erfolge stammen aus der Kapazitätsaufgabe. Python-AST kann `<` durch `<=` ersetzen. In TIDE braucht derselbe Fall einen Ausdrucksersatz. Der Rechnungszuschlag brauchte in beiden Sprachen einen Ausdrucksersatz und ergab keine bestandene Operatoränderung. [Einzelwerte und Rohdaten](messung.json)

## Vergleich auf denselben vier Aufgaben

| Schnittstelle | Vorher ohne Vorprüfung | Jetzt mit Vorprüfung |
|---|---:|---:|
| TIDE-Knoten | 0/12 bei 10.077 Tokens | 6/12 bei 0 Tokens |
| Python-AST | 3/12 bei 8.440 Tokens | 9/12 bei 0 Tokens |

Beide Schnittstellen profitieren von der lokalen Suche. Der Vorteil beim Tokenverbrauch entsteht hier zum grössten Teil dadurch, dass eindeutig bestandene Vorschläge direkt in die unabhängige Abnahme gehen. Gegen den gleich ausgestatteten Python-Vergleich erreicht TIDE im Gesamtlauf weniger Erfolge und braucht mehr Tokens pro Erfolg. [Vorheriger Vergleich](../55_knotenreparatur/bericht.md)

## Mehrdeutigkeit und Abnahme

Eine fünfte Aufgabe fragt nach der Anzahl ungepackter Einheiten. Bei den drei öffentlichen Eingaben sind ganzzahliger Quotient und Rest zufällig gleich. Beide Änderungen passieren deshalb den Vorfilter. Qwen3 4B wählte je Sprache in zwei von drei Läufen den Rest. In allen sechs Anfragen wählte es die zweite Position, nachdem die Reihenfolge je Seed gewechselt hatte. Die verdeckten Fälle wiesen den falschen Quotienten in beiden Sprachen zurück. Diese Aufgabe belegt keinen Unterschied bei der Auswahlqualität zwischen den Sprachen. [Aufgabe](rest_aufgabe.json) · [Orakel in TIDE](rest_orakel.tide)

Je Aufgabe und Sprache wurden bis zu 32 einzelne Operatorwechsel in den beim ersten Fehler betretenen Funktionen berücksichtigt. Beide benutzten die jeweiligen nativen Operatoren. Die Obergrenze wurde bei keiner der fünf Aufgaben erreicht. Die vier wiederverwendeten Aufgaben und ihre Orakelfälle wurden vor dem Lauf mit den früheren Rohdaten verglichen. Alle 34 TIDE-Entscheidungen stimmten mit dem echten Quelleditor überein, einschliesslich verworfener Wechsel. Bei Python wurden die Kandidaten als AST-Änderungen erzeugt und in schreibgeschützten Kopien ohne Netzwerk ausgeführt. Die TIDE-Abnahme prüfte die Ergebnisvektoren gegen das gemeinsame Orakel.

Ein fehlender Kandidat zählt als Fehlversuch ohne Modellanfrage. Ein einzelner erhält direkt die Abnahme. Bei mehreren erhält das Modell Vertrag, den ersten öffentlichen Fehler und ausschliesslich bestandene Kandidaten. Alle Auswahlen wurden getrennt gegen 3 öffentliche und 72 verdeckte Fälle pro Aufgabe geprüft. 15 Läufe pro Sprache bedeuten fünf Aufgaben mit drei Seeds. Deterministische Vorschläge wiederholen sich. Alle sechs gezählten Modellanfragen liefen über das lokale Ollama, inklusive Eingabe- und Ausgabetokens. [Versuchsplan](versuchsplan.json) · [Modelldigest](modell.json)

Die Paketprüfung `make check-no-python` bestand mit dem Kandidatenbefund im installierten Paket.
