# Eingabespannen aus dem Vertrag ableiten

TIDE und Python-AST leiteten aus denselben `requires`-Bedingungen dieselben inklusiven Intervalle ab. Beide bestanden **60 von 60 Reparaturläufen bei 0 Modelltokens**. TIDE war in allen 60 Paaren schneller und im gepaarten Median **2,42-mal so schnell**. Die gepaarte Zeitersparnis betrug im Median 49,5 ms und lag für die mittleren 50 % der Paare zwischen 47,5 und 51,1 ms. [Einzelzeiten und Rohdaten](messung.json)

| Reparaturzeit bis zur Abnahme | Paare | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Alle fünf Aufgaben | 60 | 33,9 / 46,1 ms | 83,2 / 107,2 ms |
| Vier Aufgaben mit erzeugtem Gegenbeispiel | 48 | 36,2 / 47,0 ms | 83,7 / 108,8 ms |
| Kontrollaufgabe mit Gegenbeispiel aus dem festen Pool | 12 | 31,9 / 33,3 ms | 82,3 / 84,8 ms |

## Ableitung und Gegenbeispiele

TIDE liest `requires` aus dem öffentlichen Beispielvertrag des reparierten Ziels. Es schneidet die Bedingungen pro Ganzzahlparameter und rechnet strikte Grenzen in inklusive Grenzen um. Beim Nettogewicht ergibt etwa `gt: -5` zusammen mit `ge: -9` und `le: 88` das Intervall `[-4,88]`. `--pairs` nutzt dieses Intervall automatisch. In der Diagnose steht der verwendete Bereich unter `repair.probe_range`. [Verträge der fünf Messaufgaben](vertraege.json) · [Werkbank](../../workbench/README.md#eingaben-für-grüne-paare-erzeugen)

| Aufgabe | Abgeleiteter Bereich für `a` und `b` | Bestätigte Gegenbeispiele `(a, b) → Sollwert` | TIDE Median | Python-AST Median |
|---|---|---|---:|---:|
| Versandetiketten | `[1,96]`, `[1,96]` | `(5, 6) → 40` | 38,4 ms | 84,6 ms |
| Nettogewicht | `[-4,88]`, `[1,100]` | `(42, 50) → -8` | 33,7 ms | 81,8 ms |
| Taktfenster | `[0,96]`, `[1,96]` | `(48, 48) → -99`, dann `(1, 5) → 1` | 46,0 ms | 106,3 ms |
| Lackbedarf | `[1,50]`, `[1,80]` | `(1, 1) → 1` aus dem festen Pool | 31,9 ms | 82,3 ms |
| Restladung | `[0,96]`, `[1,96]` | `(48, 48) → 0` | 32,6 ms | 82,2 ms |

Bei den Versandetiketten schliesst der Beispielvertrag das zuvor erzeugte Gegenbeispiel `(0, 1)` aus. Beide Werkzeuge fanden stattdessen `(5, 6)`. Pro Runde stimmten die normalisierten Bereiche, die geprüften Kandidatenzahlen, die gefundenen Eingaben und die Ausgaben der zugehörigen Änderungen überein. Der unabhängige TIDE-Vertrag bestätigte jeden Sollwert. Sämtliche Reparaturen bestanden die öffentlichen und je 72 unveränderte verdeckte Tests, deren Eingaben von den bestätigten Gegenbeispielen verschieden waren.

## Vergleich und Prüfung

Die fünf fehlerhaften Programme mit je drei Dateien und die Testfälle stammen aus Versuch 62, die festen Pools aus Versuch 63. Beide Seiten erhielten dieselben `requires`-Bedingungen zusammen mit den öffentlichen Tests. Die Ableitung geschah innerhalb der gemessenen Aufrufe. Beide Seiten nutzten dieselben Suchgrenzen und dieselbe Reihenfolge für feste und erzeugte Eingaben. Beide prüften und übernahmen dieselben zwei Dateien in eine Arbeitskopie und öffneten sie erneut für die Abnahme. [Versuchsplan](versuchsplan.json) · [Externer CPython-AST-Vergleich](cpython_contract.py)

Gemessen wurde vom Erstellen des festen Pools bis zur Abnahme. Eingerechnet sind Ableitung, Vorprüfung, alle Gegenbeispielrunden, Bestätigung, Patch und Abnahmetest. TIDE 0.6.1 und CPython 3.14.10 liefen sequenziell auf demselben logischen Kern eines Ryzen 9 9950X3D mit warmen Dateicaches. Je Aufgabe gab es zwölf Messpaare mit frischen Prozessen und wechselnder Reihenfolge. Die Läufe waren lokal und vom Netzwerk getrennt.

`make test` und der Aufruf im installierten Paket ohne Python bestanden. Weitere CLI-Prüfungen deckten überlaufende strikte Grenzen, widersprüchliche und mehrfache Deklarationen, die exakte i64-Untergrenze und den Schutz bestehender Beispielverträge beim Bearbeiten ab. Eine explizite Spanne schränkt den Vertragsbereich für die Erzeugung weiter ein. Ein leerer Schnitt ergibt `E_INPUT`.

Die Ableitung unterstützt unabhängige Ganzzahlbedingungen gegen Konstanten. Der gemessene Zeitvorteil gilt für diese fünf Aufgaben mit ausführbarer Sollwertbestätigung und frischen Kommandozeilenprozessen.
