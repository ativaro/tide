# Faltungen im nativen Auswerter

Ein Kontrollprogramm hat dieselben Eingaben und Funktionsdefinitionen wie die beiden Schleifen und gibt über zwei zusätzliche Einstiege die Länge der jeweiligen Liste zurück. Bei 4.096 Zahlen brauchte der Längenaufruf 6,44 ms und die Vorzeichenzählung 37,38 ms. Für 4.096 Textzeilen waren es 9,87 ms für die Länge und 59,10 ms für die erste Fundstelle des Maximums. Die vier Werte sind Mediane aus 17 Durchgängen. Die Differenz umfasst die Auswertung des jeweiligen Funktionsrumpfs einschließlich der Erzeugung des Ergebnisses.

Der Auswerter greift jetzt direkt auf den aktiven Rahmen zu. Beim Entfernen dieses Rahmens übernimmt er die vorherigen Rahmen aus dem vorhandenen Stapel. Früher erzeugte er zuerst eine separate Liste von Positionsmarken, um dieselben Rahmen zu kopieren. Die Änderung gilt für den allgemeinen Auswerter. [Auswertungsstapel](../../native/bootstrap/function_run.tide)

| Aufgabe | Werte | TIDE vorher | TIDE jetzt | Externes CPython |
|---|---:|---:|---:|---:|
| Vorzeichen zählen | 16 | 5,42 ms | 5,38 ms | 9,07 ms |
| Vorzeichen zählen | 4.096 | 36,72 ms | 27,64 ms | 9,37 ms |
| Erste Fundstelle des Maximums | 16 | 6,15 ms | 6,08 ms | 9,10 ms |
| Erste Fundstelle des Maximums | 4.096 | 60,35 ms | 45,68 ms | 9,77 ms |

Jede Tabellenzelle ist der Median von 21 Prozessstarts nach drei Aufwärmrunden auf demselben CPU-Kern. Die Startreihenfolge wechselte, jede Ausgabe wurde geprüft. Gemessen wurde der öffentliche Aufruf bis zum Prozessende, einschließlich Quellprüfung bei TIDE und Import der JSON-Bibliothek bei CPython. Bei beiden großen Eingaben war die neue TIDE-Fassung in allen 21 Paaren schneller als die alte. CPython hatte bei diesen Eingaben weiterhin die kürzere Laufzeit. Die Reparaturzeit und der Tokenverbrauch eines Modells wurden in diesem Lauf nicht gemessen. [Messwerte, Quellen und Eingabefolgen](messung.json)

Die Gegenmessung mit CPython lief außerhalb der TIDE-Abnahme. Separat baute `make check-no-python` die Werkzeuge in einem Debian-Abbild ohne Python, führte die native Testsuite aus und prüfte die Installation sowie eine Saldo-Reparatur im Laufzeitabbild. [Build- und Paketprüfung](../../native/bootstrap/no-python.Dockerfile)
