# Machbarkeitsstudie · Nativer Messbericht mit Dateizugriff

Die erste Etappe ist bestanden. Das installierte Paket liest eine freigegebene Datei, berechnet den Messbericht und repariert in einer Projektkopie einen Fehler über Modulgrenzen. Das Paket wurde auf Linux x86-64 ohne Python gebaut und ausgeführt. [Abnahme im Laufzeitabbild](../../native/bootstrap/no-python.Dockerfile)

```sh
printf '%s\r\n' 80 81 98 > werte.txt
./tide run apps/report.tide --read input=werte.txt --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

Der Reparaturversuch ersetzt im importierten Modul `summary.tide` den Vergleich `>` durch `<`. Die Diagnose am Projekteinstieg meldet `/above`, Soll 2, Ist 0. `edit --edits` übernimmt die Korrektur am Knoten `summary.tide:10:12` mit der Revision aus dem Befund. Danach stimmt die Datei bytegenau mit dem Original überein. Alle drei Beispiele und der Aufruf mit echter Datei bestehen.

Die Abnahme deckt CRLF, fehlende Freigaben und abfangbares ungültiges UTF-8 ab. Lokal wurde zusätzlich geprüft, dass dieselbe Freigabe mit exakt 131.072 Bytes zweimal gelesen werden kann, zwei Freigaben mit zusammen 131.073 Bytes `E_LIMIT` liefern und eine benannte Pipe mit `E_CAPABILITY` zurückgewiesen wird.

## Wo die Zeit anfällt

Median pro Prozess in Millisekunden. Gemessen wurde auf Kern 2, jeweils 21 gültige Läufe nach drei Aufwärmläufen. Jede Datei enthielt die angegebene Anzahl von Zeilen mit `81` und LF. Der Grenzwert war 80. Alle Ergebnisse wurden gegen die erwartete Ausgabe geprüft.

| Zeilen | Installierte CLI | Checker direkt | Nur Lesen und Textlänge | Checker ohne Lesen | Vorab übersetzter Versuch |
|---:|---:|---:|---:|---:|---:|
| 3 | 4,58 | 1,29 | 1,06 | 1,06 | 0,44 |
| 512 | 13,60 | 10,33 | 1,12 | 1,09 | 0,44 |
| 2.048 | 41,07 | 37,34 | 1,15 | 1,08 | 0,48 |
| 4.096 | `E_LIMIT` | `E_LIMIT` | – | – | 0,54 |

Für die ersten vier Spalten wurde dieselbe Projektkopie verwendet. Zwei zusätzliche Einstiege messen `text_len (read input)` und die unmittelbare Rückgabe des Grenzwerts. Die Kontrollwerte enthalten Projektprüfung, Bindung und Prozessstart. Bei 2.048 Zeilen liegen die Kosten im Ausführen der Faltung samt Aufrufen, Records und Optionen. Bei kleinen Dateien dominiert der CLI-Start.

Für den letzten Versuch übersetzte der vorhandene Bootstrap-Compiler `readings.tide` und `summary.tide` zusammen mit einem TIDE-Einstieg `summarize (lines (read input)) 80` und einer JSON-Ausgabe. Das statisch gelinkte Programm wurde mit `-O1` gebaut. Der Messwert enthält Start, Einlesen und Ausgabe. Die Übersetzungszeit wurde nicht gemessen. Der Versuch prüft nur die gezeigten gültigen Eingaben. Er verwendet die internen Bootstrap-Grenzen und hat weder die öffentlichen Gastbudgets noch deren Diagnosen. Die 0,48 ms sind ein Hinweis auf das Potenzial direkter Übersetzung. Sie sind kein Nachweis eines gleichwertigen CLI-Ersatzes oder eines Vorteils gegenüber CPython.

Der nächste Performanceversuch sollte den geprüften TIDE-Baum vorab in Operationen mit festen Typen und direkten lokalen Slots übersetzen. Für den Messbericht sind direkte Schleifen und Updates des Akkumulators besonders interessant. Der Vergleich braucht dieselbe Ausgabe, dieselben Fehlerorte und dieselbe Budgetabrechnung. Aufbaukosten und wiederholte Laufzeit werden getrennt ausgewiesen.
