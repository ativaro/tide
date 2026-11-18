# Kleine Ausdrucksersetzungen in der Vorprüfung

TIDE und der externe Python-AST-Vergleich prüfen neben Operatorwechseln dieselben zwei Umformungen von `a*b+c`: `a*(b+c)` und `(a+c)*b`. Die Suche erkennt auch `c+a*b`. Jeder Operand muss ein Ganzzahlliteral oder eine Bindung sein. In TIDE wird jede Ersetzung in einer Quellkopie im Speicher typgeprüft und gegen dieselben öffentlichen Beispiele ausgeführt wie der ursprüngliche Stand. [Werkbank](../../workbench/README.md#einen-knoten-reparieren)

Beim Rechnungszuschlag lieferte TIDE genau den Kandidaten `(* units (+ rate 2))`. Python-AST fand `units * (rate + 2)`. Beide bestanden in allen drei Wiederholungen. Die eindeutige Wahl ging ohne Modellaufruf in die unabhängige Abnahme.

| Verfahren mit gleicher Vorprüfung | Erfolge / Läufe | Modellanfragen | Gesamttokens | Tokens pro Erfolg |
|---|---:|---:|---:|---:|
| TIDE | 14/15 (93,3 %) | 3 | 531 | 37,9 |
| Python-AST | 14/15 (93,3 %) | 3 | 555 | 39,6 |

Beide Verfahren stiegen von 11/15 auf 14/15. Der Zuwachs stammt vollständig vom Rechnungszuschlag. Die Tokenzahlen blieben unverändert. Alle sechs Modellanfragen waren Wiederholungen für die Restaufgabe mit zwei öffentlich grünen Varianten. In beiden Sprachen scheiterte einmal die Auswahl am verdeckten Orakel. Die 24 Tokens Unterschied beziehen sich auf diese eine mehrdeutige Aufgabe. [Rohdaten](messung.json) · [Vorherige Messung](../57_inklusive_vergleiche/bericht.md)

Die Messung verwendete unverändert fünf Programme in je drei Dateien, drei Seeds sowie drei öffentliche und 72 verdeckte Fälle pro Aufgabe. Pro Sprache wurden insgesamt 40 Kandidaten geprüft, darunter je zwei Ausdrucksersetzungen beim Zuschlag und beim Budgetabzug. Das Limit von 32 pro Aufgabe wurde nie erreicht. Alle gemeldeten TIDE-Kandidaten wurden nochmals mit `tide edit` geprüft. Die Python-Programme liefen als externe Referenz in schreibgeschützten Kopien ohne Netzwerk. Die Sollwerte waren ausserhalb dieser Kopien. Nur öffentlich bestandene Kandidaten gelangten zur Auswahl. Alle Modellanfragen liefen lokal über Ollama mit demselben Qwen3-4B-Modell. [Versuchsplan](versuchsplan.json) · [Modelldigest](modell.json)

`make check-no-python` bestand. Das installierte Paket lieferte beim fehlerhaften Rechnungszuschlag genau die erwartete Ausdrucksersetzung.
