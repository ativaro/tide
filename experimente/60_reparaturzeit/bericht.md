# Reparaturzeit mit öffentlichem Gegenbeispiel

TIDE reparierte die neuen Mehrdateienfehler im gepaarten Median **2,34-mal so schnell** wie Python-AST. Beide bestanden **84 von 96 Reparaturversuchen (87,5 %)** und verbrauchten **0 Modelltokens**. TIDE benötigte in allen 84 erfolgreichen Paaren weniger Zeit. Die gepaarte Ersparnis lag im Median bei 49,8 ms, mit den mittleren 50 % der Paare zwischen 37,5 und 51,4 ms. [Rohdaten](messung.json)

| Zeit vom Start bis zur Abnahme oder zum Abbruch | TIDE Median / P95 | Python-AST Median / P95 | Versuche je Verfahren |
|---|---:|---:|---:|
| Erfolgreiche Reparaturen insgesamt | 38,1 / 41,4 ms | 88,8 / 94,2 ms | 84 |
| Erfolgreich mit Gegenbeispiel | 39,7 / 42,0 ms | 91,4 / 94,7 ms | 48 |
| Erfolgreich mit sofort eindeutiger Vorprüfung | 26,4 / 28,2 ms | 63,6 / 67,1 ms | 36 |
| Abbruch ohne grünen Kandidaten | 14,8 / 17,2 ms | 27,6 / 29,5 ms | 12 |
| Alle Versuche | 33,1 / 41,4 ms | 77,2 / 94,2 ms | 96 |

## Was beide Verfahren gleich machten

Die acht neuen Projekte bestanden aus je drei Quelldateien. Jede Aufgabe hatte eine bis drei öffentliche Prüfungen und 72 zurückgehaltene Prüfungen. Die erste fehlerhafte Ausgabe war auf beiden Seiten gleich. In den ausgeführten Funktionen prüften beide dieselben ganzzahligen Operatorwechsel und die beiden kleinen Ausdrucksersetzungen aus Versuch 58, mit höchstens 32 Änderungen. Die beobachteten Anzahlen der geprüften und der grünen Kandidaten stimmten pro Paar überein. Keine Suche erreichte ihre Obergrenze. [Quellpaarungen](paarungen.json) · [Versuchsplan](versuchsplan.json)

Für die Gegenbeispielsuche erhielten beide denselben geordneten Pool aus gültigen Eingaben, erzeugt aus den Werten 1 bis 4 für beide Parameter. Beide stoppten beim ersten Eingabepaar, für das die grünen Kandidaten fehlerfrei unterschiedliche Werte lieferten. Eine unabhängige TIDE-Vertragsfunktion bestätigte den Sollwert ohne Zugriff auf Kandidatencode oder verdeckte Prüffälle. Beide ergänzten das so bestätigte öffentliche Beispiel und wiederholten die Vorprüfung. Ein eindeutiger Kandidat wurde im Projekt gespeichert und gegen alle öffentlichen und zurückgehaltenen Fälle abgenommen. [Prüffälle und Vertragsfunktion](vertrag.tide) · [Externer Python-AST-Vergleich](cpython_comparison.py)

| Aufgabe | Grüne Kandidaten zu Beginn | Gemeinsames Gegenbeispiel und Sollwert | TIDE Median | Python-AST Median |
|---|---:|---|---:|---:|
| Kisten | 2 | `(1, 1) → 2`, 1. Probe | 39,1 ms | 89,7 ms |
| Guthaben | 2 | `(1, 1) → 0`, 1. Probe | 39,1 ms | 90,3 ms |
| Ladegrenze | 2 | `(1, 2) → 7`, 2. Probe | 39,9 ms | 91,5 ms |
| Etiketten | 2 | `(1, 2) → 4`, 2. Probe | 40,1 ms | 92,9 ms |
| Förderband | 1 | — | 26,6 ms | 63,9 ms |
| Trommeln | 1 | — | 26,1 ms | 63,4 ms |
| Farbrollen | 1 | — | 26,8 ms | 63,5 ms |
| Doppelzähler | 0 | — | 14,8 ms | 27,6 ms |

Alle zwölf Läufe je Verfahren beim Doppelzähler gingen als Fehlschläge ein. Die Einzeländerungssuche prüfte 16 Kandidaten und fand keinen, der alle öffentlichen Tests bestand. Die getrennte Kontrolle mit beiden Korrekturen in `route.tide` und `rulebook.tide` bestand 75 von 75 Tests.

## Zeitgrenzen

Die monotone Wanduhr startete vor der Erzeugung des Eingabepools. Die Messung enthält Diagnose, Vorprüfung, Gegenbeispielsuche, Bestätigung, ergänztes öffentliches Beispiel, erneute Vorprüfung, Patch mit öffentlicher Prüfung und unabhängige Abnahme. Build, Installation, vorbereitete Ausgangskopien und Erzeugung der ursprünglichen Prüffälle lagen vor dem Start. Die verdeckten Fälle standen dem Reparaturablauf erst nach dem Schreiben des Patches zur Verfügung.

| Phase mit Gegenbeispiel | TIDE Median | Python-AST Median |
|---|---:|---:|
| Gemeinsamen Eingabepool erzeugen | 8,7 ms | 8,8 ms |
| Erster Fehler, Vorprüfung und Gegenbeispielsuche | 5,7 ms | 18,6 ms |
| Sollwert bestätigen und öffentliches Beispiel ergänzen | 7,7 ms | 8,0 ms |
| Öffentliche Vorprüfung wiederholen | 5,6 ms | 18,5 ms |
| Patch prüfen und schreiben | 5,4 ms | 19,1 ms |
| Unabhängige Abnahme | 6,3 ms | 17,8 ms |

Die Suche ist Teil desselben Aufrufs wie die erste Vorprüfung. Die Phasenmediane werden einzeln berechnet. Pro Aufgabe folgten auf einen verworfenen Probelauf zwölf gemessene Paare in wechselnder Startreihenfolge. Jeder Lauf verwendete eine frische Projektkopie und beide Verfahren starteten pro Phase einen frischen Kommandozeilenprozess. CPython nutzte `-I -B -S`, kompilierte Kandidaten im Speicher und startete während der Vorprüfung keinen Prozess pro Kandidat. Gemessen wurde sequenziell auf CPU 24 eines Ryzen 9 9950X3D mit warmen Systemcaches, TIDE 0.6.1 aus einem installierten Paket und CPython 3.14.10. Die Netzwerkschnittstellen des Hosts waren für die Läufe unzugänglich. Es gab keine Modellanfrage.

Der Zeitfaktor gilt für diesen Kommandozeilenablauf auf acht kleinen Projekten mit ausführbarem Vertrag. Die Wiederholungen messen Zeitstreuung, während die Erfolgsquote sieben von acht unterschiedlichen Fehlern entspricht. Ein dauerhaft laufender Prozess und die Dauer einer menschlichen Bestätigung waren ausserhalb des Versuchs.
