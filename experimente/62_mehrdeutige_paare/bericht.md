# Mehrdeutige Änderungspaare mit öffentlichen Gegenbeispielen auflösen

Beide Verfahren reparierten alle fünf neuen Projekte mit je drei Quelldateien. Die zwölf Messwiederholungen pro Projekt ergaben **60/60 erfolgreiche Läufe je Verfahren bei 0 Modelltokens**. TIDE war in allen 60 Paaren schneller und benötigte im gepaarten Median 60,5 ms weniger Zeit. Der Median der gepaarten Zeitfaktoren beträgt **2,23×**. Die mittleren 50 % der gepaarten Zeitersparnisse lagen zwischen 52,3 und 63,1 ms. [Rohdaten mit Einzelzeiten](messung.json)

| Zeit vom Start bis zur Abnahme | Paare | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Alle Reparaturen | 60 | 51,8 / 61,0 ms | 115,5 / 123,0 ms |
| Ein bestätigtes Gegenbeispiel | 24 | 38,6 / 40,3 ms | 90,5 / 94,0 ms |
| Zwei bestätigte Gegenbeispiele | 36 | 53,8 / 61,8 ms | 118,1 / 123,5 ms |

## Auflösung der Mehrdeutigkeit

Zu Beginn bestand in keiner Aufgabe eine Einzeländerung sämtliche öffentlichen Tests. Es blieben je zwei oder sechs grüne Änderungspaare in zwei verschiedenen Dateien. In drei Aufgaben blieben nach dem ersten Gegenbeispiel noch drei oder vier Paare grün. Das zweite machte die Reparatur eindeutig. Beide Verfahren fanden in jeder Runde dieselben Paare, dieselbe trennende Eingabe und dieselbe Zuordnung von Ausgaben zu Änderungen. Ein eigenständiger TIDE-Vertrag bestätigte den Sollwert. [Fehlerhafte Quellpaarungen](paarungen.json) · [Vertrag mit Prüffällen](vertrag.tide)

| Aufgabe | Grüne Paare je Runde | Bestätigte Gegenbeispiele `(a, b) → Sollwert` | TIDE Median | Python-AST Median |
|---|---:|---|---:|---:|
| Versandetiketten | 6 → 4 → 1 | `(2, 1) → -99`, `(1, 2) → 4` | 59,1 ms | 120,1 ms |
| Nettogewicht | 6 → 4 → 1 | `(2, 1) → -99`, `(1, 2) → -1` | 52,6 ms | 116,7 ms |
| Taktfenster | 6 → 3 → 1 | `(1, 1) → -99`, `(1, 2) → 1` | 52,9 ms | 116,3 ms |
| Lackbedarf | 2 → 1 | `(1, 1) → 1` | 38,5 ms | 90,5 ms |
| Restladung | 2 → 1 | `(1, 1) → 0` | 39,1 ms | 90,5 ms |

Bei den Versandetiketten prüften beide Werkzeuge pro Runde 14 Einzeländerungen und 40 Paare. In den übrigen Aufgaben waren es je acht Einzeländerungen und 16 Paare. Die endgültige Reparatur der Versandetiketten kombiniert einen Vergleichswechsel mit einer Ausdrucksersetzung. Die anderen Paare bestehen aus zwei Operatorwechseln. In allen Läufen bestanden beide gemeinsam geprüften Dateien sämtliche öffentlichen und die 72 unveränderten verdeckten Fälle.

## Messbedingungen

Beide Werkzeuge starteten mit derselben Vorprüfung mit maximal 32 Einzeländerungen und 64 dateiübergreifenden Paaren je Runde. Der gemeinsame Eingabepool stammte aus dem gültigen Randbereich der Aufgaben. Beide suchten bis zur ersten Eingabe mit unterschiedlichen regulären Ausgaben und prüften dabei höchstens 32 Eingaben und 128 Kandidatenauswertungen pro Runde. Nur der bestätigte Sollwert kam als zusätzlicher öffentlicher Test in die Wiederholung. Der Ablauf erlaubte bis zu drei Bestätigungen. Der Suchlauf und seine Bestätigung erhielten keine verdeckten Sollwerte. [Versuchsplan](versuchsplan.json) · [Unveränderter Python-AST-Vergleich](../61_dateiuebergreifende_paare/cpython_pairs.py)

Die monotone Wanduhr lief ab Beginn der Pool-Erzeugung und schloss Diagnose, alle Such- und Bestätigungsrunden, Vorschau, Übernahme in die Arbeitskopie und unabhängige Abnahme ein. Build und Vorbereitung der Ausgangskopien lagen vor dem Start. Das installierte TIDE 0.6.1 und CPython 3.14.10 liefen sequenziell auf demselben logischen Kern eines Ryzen 9 9950X3D, mit warmen Systemcaches, frischen CLI-Prozessen und wechselnder Startreihenfolge. Die Messung war vom Netzwerk getrennt und rief kein Modell auf.

Der Vergleich gilt für fünf gezielt mehrdeutige Fehler mit ausführbarem Vertrag. Die Wiederholungen messen die Zeitstreuung pro Aufgabe. Die Erfolgsmessung deckt Fälle ab, die sich mit dem festgelegten Eingabepool unterscheiden lassen.
