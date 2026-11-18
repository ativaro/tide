# Gegenbeispiele aus Beziehungen zwischen Parametern

TIDE erzeugt jetzt Gegenbeispiele für Verträge mit Beziehungen wie `a <= b`. Im Vergleich lösten beide Verfahren **60 von 72 Läufen (83,3 %)** bei **0 Modelltokens**. Die zwölf Abbrüche je Verfahren entfielen auf die Gleichwertigkeitskontrolle. Bei erfolgreichen Reparaturen war TIDE im gepaarten Median **2,42-mal so schnell**. Der Median der Zeitersparnis betrug 55,8 ms. Die mittleren 50 % der gepaarten Ersparnisse lagen zwischen 54,1 und 56,4 ms. [Einzelzeiten und Rohdaten](messung.json)

| Ergebnis | Paare | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Reparatur bestanden | 60 | 39,5 / 44,4 ms | 95,2 / 97,8 ms |
| Mehrdeutig geblieben | 12 | 27,6 / 29,8 ms | 55,2 / 58,8 ms |

## Welche Eingaben die Paare trennten

`"a":{"le":"b"}` steht im Beispielvertrag für `a <= b`. TIDE leitet über die Parameterbeziehungen engere Einzelgrenzen ab und prüft weiterhin jede Beziehung am konkreten Eingabepunkt. Bei einem ungültigen Suchpunkt versucht der Generator, die verbundenen Werte anzuheben oder abzusenken. Bei den Versandetiketten wurde so aus `(5, 6, 6)` der gültige Punkt `(5, 6, 5)`, der sowohl `a <= b` als auch `c = a` erfüllt. [Verträge](vertraege.json) · [Versandvariante](versand.json)

| Aufgabe | Bestätigtes Gegenbeispiel → Sollwert | Grüne Paare je Runde | TIDE Median | Python-AST Median |
|---|---|---:|---:|---:|
| Versandetiketten | `(5, 6, 5) → 40` | 6 → 1 | 44,0 ms | 97,1 ms |
| Nettogewicht | `(42, 50) → -8` | 6 → 1 | 39,7 ms | 94,6 ms |
| Taktfenster | `(47, 48) → 47` | 3 → 1 | 39,6 ms | 95,3 ms |
| Lackbedarf | `(100, 100) → 1000000` | 2 → 1 | 37,3 ms | 94,7 ms |
| Restladung | `(48, 48) → 0` | 2 → 1 | 39,2 ms | 94,7 ms |
| Gleichlauf | `(47, 48) → 47` | 6 → 2 | 27,6 ms bis Abbruch | 55,2 ms bis Abbruch |

Beim Gleichlauf unterscheiden sich die zwei verbleibenden Änderungen nur durch `<` und `<=`. Für alle durch `a < b` zugelassenen Eingaben liefern beide dieselbe Ausgabe. Die Variante Taktfenster enthält zusätzlich ein öffentliches Beispiel bei Gleichheit als Prüfung des Verhaltens ausserhalb des Suchbereichs. Es trennt die beiden Operatoren bereits vor der Gegenbeispielsuche.

## Messbedingungen und Prüfungen

Die sechs Szenarien stammen aus fünf vorhandenen Programmen mit je drei Dateien. Sie verwenden relationale Verträge und neue, vertragskonforme verdeckte Eingaben. Beide Werkzeuge erhielten dieselben Verträge, die gleichen festen Pools, dieselbe Reihenfolge erzeugter Punkte und dieselben Prüfbudgets. Eingaben aus dem festen Pool, die den Vertrag verletzten, wurden übersprungen. Die geprüften Kandidatenzahlen, die abgeleiteten Grenzen und die Ausgaben zu den Trennfällen stimmten überein. Ein unabhängiges TIDE-Orakel bestätigte alle vorgeschlagenen Sollwerte. Jeder erfolgreiche Lauf bestand die öffentlichen und alle 72 verdeckten Tests. [Versuchsplan](versuchsplan.json) · [Szenarien und Abnahme in TIDE](szenarien.tide) · [Externer CPython-AST-Vergleich](cpython_relations.py)

Gemessen wurde vom Erstellen des festen Pools bis zur Abnahme oder zum Abbruch, einschliesslich Vertragsprüfung, Gegenbeispielsuche, Bestätigung, Patch und Neustart für den Abnahmetest. TIDE 0.6.1 und CPython 3.14.10 liefen auf demselben logischen Kern eines Ryzen 9 9950X3D mit warmen Dateicaches. Je Szenario gab es zwölf Messpaare mit frischen Prozessen und wechselnder Reihenfolge. Die Läufe waren lokal, vom Netzwerk getrennt und machten keine Modellanfragen.

`make test` bestand. Das installierte Paket erzeugte ein Gegenbeispiel mit Parameterbeziehung auch in einer Umgebung ohne Python. Gezielte Prüfungen deckten unbekannte Parameter, widersprüchliche strikte Zyklen, i64-Grenzen und einen leeren Schnitt nach manueller Einengung ab. Für `tide test szenarien.tide` liegen `szenarien.tide` und der unveränderte `vertrag.tide` aus Versuch 62 als Nachbardateien in einer Arbeitskopie. [Aufruf und Vertragsformat](../../workbench/README.md#eingaben-für-grüne-paare-erzeugen) · [Importierter Vertrag](../62_mehrdeutige_paare/vertrag.tide)

Die Suche unterstützt gleichzeitig geltende direkte Ganzzahlvergleiche. Die Zeitmessung gilt für die fünf reparierten Aufgaben und die Gleichwertigkeitskontrolle mit ausführbarer Sollwertbestätigung.
