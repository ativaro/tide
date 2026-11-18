# Knotenreparatur im lokalen Vergleich

`tide test --diff --explain=nodes` liefert jetzt den ersten Fehlerbefund, die ausgeführten Definitionen und bearbeitbare Operatorstellen mit Typ und Alternativen. `tide edit --edits` prüft den ausgewählten Wechsel oder Ersatz gegen die Revision, die Typen und die öffentlichen Beispiele. Die vier bekannten Reparaturen bestanden in allen drei Schnittstellen. Bei Qwen3 4B verbesserte der zusätzliche Knotenbefund die Erfolgsquote gegenüber TIDE-Funktionsrümpfen in diesem Versuch nicht. [Werkbank](../../workbench/README.md#einen-knoten-reparieren)

| Schnittstelle | Erfolge / Läufe | Modellanfragen | Eingabetokens | Ausgabetokens | Gesamttokens | Tokens pro Erfolg |
|---|---:|---:|---:|---:|---:|---:|
| TIDE-Funktionsrumpf | 0/12 | 24 | 7.272 | 506 | 7.778 | – |
| TIDE-Knotenänderung | 0/12 | 24 | 9.444 | 633 | 10.077 | – |
| Python-AST-Edit | 3/12 | 21 | 7.784 | 656 | 8.440 | 2.813,3 |

Die drei Python-Erfolge entstanden beim selben Gleichheitsfehler in drei Wiederholungen. Dafür genügte `<` → `<=`. TIDE benötigt für diesen Fall einen Ausdrucksersatz, etwa `(not (> load cap))`. Keine Variante löste einen der drei anderen Fehler. Bei TIDE-Knotenänderungen waren 12 von 24 Antworten der Versuch, den bereits vorhandenen Operator zu setzen. Neun weitere Vorschläge erreichten die öffentliche Abnahme und scheiterten dort. Der Knotenbefund erhöhte in diesem Versuch den TIDE-Gesamtverbrauch gegenüber den Rümpfen um 2.299 Tokens. Bei null Erfolgen sind Tokens pro Erfolg undefiniert. [Antworten, Diagnosen und Zähler](messung.json)

## Verfahren

Die vier neuen Projekte haben jeweils drei Quelldateien und einen Fehler in einer aufgerufenen Funktion. Sie behandeln Budgetabzug, inklusive Kapazität, vollständige Zeitfenster und Zuschlag je Einheit. Zwei TIDE-Referenzlösungen wechseln einen Operator, zwei ersetzen einen Ausdruck. Vor der ersten Modellanfrage zeigten TIDE und Python denselben falschen Wert für das erste öffentliche Beispiel. Jede bekannte Korrektur bestand alle drei öffentlichen und 72 verdeckten Fälle je Aufgabe. [Aufgaben und Referenzkorrekturen](aufgaben.json) · [Unabhängiges Orakel in TIDE](orakel.tide)

Für jede Aufgabe liefen drei Seeds gepaart und in wechselnder Reihenfolge durch alle Schnittstellen. Beide TIDE-Arme bekamen dieselben Funktionsdefinitionen und denselben beobachteten Unterschied. Beide Knotenarme erhielten zusätzlich die Operatorstellen der betretenen Funktionen. Der Python-Vergleich lokalisiert Ausdrücke im AST, ersetzt genau den ausgewählten Ausdruck oder Operator und führt die Kandidaten in einer schreibgeschützten Umgebung ohne Netzwerk aus. Die Sollwerte bleiben ausserhalb der sichtbaren Projektkopie. TIDE prüft die Ergebnisvektoren. [Versuchsplan](versuchsplan.json) · [Externer CPython-Vergleich](cpython_ast.py)

Je Lauf war ein zweiter Vorschlag nach einer öffentlichen Fehlermeldung zulässig. Der zweite Versuch sah die eigene vorherige Antwort und den tatsächlichen öffentlichen Befund. Jeder Vorschlag startete vom ursprünglichen Quellstand. Verdeckte Fälle oder deren Ergebnisse wurden dem Modell nie gezeigt. Die Tokenzahlen summieren Ollamas Eingabe- und Ausgabezähler über beide Versuche, einschliesslich Fehlversuchen und übergebener Diagnosen. Alle 69 gemessenen Anfragen liefen auf dem vorhandenen lokalen Qwen3 4B. [Modellkennung](modell.json)

Der Versuch misst einen Reparaturablauf mit vorbereitetem Kontext und höchstens zwei Vorschlägen. Vier kleine Aufgaben und ein Modell reichen für eine Aussage über diesen Ablauf. Ein allgemeiner Vorsprung für Python oder ein Agentenvorteil für TIDE lässt sich daraus nicht ableiten. Der Aufbau und die Übernahme von Knotenänderungen bestanden die native Abnahme und die Paketprüfung ohne Python.
