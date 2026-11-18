# Reparatur mit unbekanntem Fehlerort

| Vom Kundenbericht bis zur bestandenen Abnahme | TIDE | Python |
|---|---:|---:|
| Gesamttokens | 58.789 | 58.824 |
| Davon Eingabetokens aus dem Cache | 38.272 | 38.272 |
| Gesamttokens nach Abzug dieser Cache-Treffer | 20.517 | 20.552 |
| Ausgabetokens, im Gesamtwert enthalten | 475 | 386 |
| Zeit einschließlich Suche, Änderung und Prüfung | 13,669 s | 13,539 s |
| Bestandene Fälle mit der ersten eingereichten Reparatur | 20/20 | 20/20 |

### Der Fehler

Die Kundenmeldung beschrieb eine Miete von 08:57 bis 09:00 zu 3 Cent je Minute. Der Zuschlag von 2 Cent je Minute beginnt um 09:00. Beide Programme stellten 14 Cent in Rechnung. Richtig sind 9 Cent für drei belegte Minuten.

Das Modul für Zeiträume lieferte die erste freie Minute als Ende. Sowohl Grundpreis als auch Zuschlag zählten diese Minute als belegt. So entstanden zwei unterschiedliche falsche Positionen auf derselben Rechnung. Ohne Reparatur stimmten die Ausgaben beider Programme in jedem der 20 Fälle überein. Ein Fall bestand. Eine isolierte Korrektur beim Grundpreis brachte beide Projekte auf 6/20, eine isolierte Korrektur beim Zuschlag auf 2/20. Beide Modelle änderten die Längenberechnung in beiden Abrechnungsmodulen. Die ursprünglichen Quelldateien, der wortgleiche Auftrag, der Prüfbefehl und alle vorab festgelegten Fälle sind gespeichert. [Versuchseingaben](aufgabe.json)

### Durchführung am 16. November 2026

Zwei frische Codex-Sitzungen erhielten jeweils ein Arbeitsverzeichnis mit vier Quelldateien und dem Befehl `./verify`. Der Auftrag nannte weder Dateien noch Funktionen oder die Zahl betroffener Stellen. Beide Sitzungen liefen mit `gpt-6-astra`, Reasoning-Stufe `xhigh`, angeforderter Serviceklasse `priority` und Codex CLI 0.157.1. Erinnerungen, Hooks und Plugins waren ausgeschaltet. Die ausgeloste Reihenfolge war TIDE, dann Python. TIDE lief mit der Referenzimplementierung 0.5.0, Python mit CPython 3.14.10.

Beide Modelle suchten selbst nach den Dateien, lasen alle vier und reproduzierten die Kundenmeldung mit `./verify`. Sie lieferten ihre Änderungen jeweils in einer strukturierten Antwort. Ein externer Prozess wandte die Änderungen an und führte denselben Prüfbefehl erneut aus. Beide Projekte nutzten denselben festen Satz erwarteter Rechnungen. Er umfasst unter anderem leere Mieten, beide Fenstergrenzen, Teilüberlappung, einen ganzen Tag und einzeln auf null gesetzte Tarife. Die Fälle und der Prüfer blieben bei der Reparatur unverändert. Ein erneutes Anwenden der gespeicherten Antworten auf frische Kopien ergab wieder je 20/20.

Die Uhr startete unmittelbar vor dem jeweiligen Codex-Prozess und stoppte beim ersten erfolgreichen externen Testlauf. Die Tokenzahlen stammen aus dem abgeschlossenen CLI-Turn und enthalten die Quellsuche, Werkzeugergebnisse und Reparaturantwort. In diesem Aufbau fiel nach dem erfolgreichen Test keine weitere Modellantwort an. [Werkzeugaufrufe, Änderungen, Zeitstempel und Nutzungszähler](messung.json)

TIDE verbrauchte 35 Gesamttokens weniger. Python erreichte die Abnahme 0,130 Sekunden früher. Bei einem Lauf pro Sprache ist daraus kein verlässlicher Sprachvorteil abzuleiten. Im früheren [Saldoversuch](../12_funktionsrumpf/bericht.md) war die Zielfunktion bereits bekannt. Hier gehörte die Suche zur Aufgabe, und zwei Funktionsrümpfe mussten gemeinsam geprüft werden. Die unterschiedlichen Aufgaben erlauben keine gesonderte Schätzung der Suchkosten.
