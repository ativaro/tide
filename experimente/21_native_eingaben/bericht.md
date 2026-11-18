# Dieselbe native TIDE-Datei mit wechselnden Messreihen

Die 957 Byte große Heizgradstunden-Datei verarbeitet einen Startwert und bis zu 4.096 Temperaturen pro Aufruf. Auf dem gemessenen Linux-x86-64-Rechner war sie einschließlich Start, Eingabebindung, Ausgabe und Prozessende je nach Listengröße im gepaarten Median 16,5× bis 23,9× schneller als CPython. Die Buildzeit lag bei 125,74 ms im Median von zehn Builds nach zwei Aufwärmbuilds. [Aufruf und Eingabeformat](../../native/README.md#wechselnde-eingaben) · [Festgelegter Versuchsplan](versuchsplan.md)

| Anzahl Temperaturen | Native Datei, Median | CPython 3.14.10, Median | Gepaarter Faktor, Median |
|---:|---:|---:|---:|
| 0 | 0,296 ms | 6,963 ms | 23,9× |
| 16 | 0,277 ms | 6,674 ms | 23,7× |
| 4.096 | 0,678 ms | 11,234 ms | 16,5× |

Für jede Größe liefen sechs Aufwärmpaare und 30 Messpaare mit wechselnder Startreihenfolge auf CPU 2 eines AMD Ryzen 9 9950X3D. Pro Paar bekamen beide Programme dieselben Dezimalargumente. Startwert und Messreihe wurden vorab deterministisch erzeugt und zwischen Paaren variiert. Der TIDE-Referenzinterpreter lieferte den Sollwert außerhalb der Zeitmessung. Die monotone Uhr lief im Elternprozess um den vollständigen Kindprozessaufruf. Die Zeiten enthalten damit auch die Übergabe der Argumente durch das Messprogramm. CPython lief mit `-BS` ohne Site-Initialisierung. Beide Programme validieren auch Texteingaben, Bereich, Listenlänge und arithmetische Überläufe. Die Messung erfasst keinen warmen Rechenkern und keine Modellkosten. [Vergleichsquelle, Eingabeerzeugung, Einzelzeiten, Build- und Binärhashes](messung.json)

## Was geprüft wurde

- Alle 29 Faltungsprogramme aus Versuch 20 lieferten beim Aufruf ihrer parametrisierten Funktion den erwarteten Wert oder Überlaufcode. Die geschlossenen Heizgradstunden- und Saldodateien sowie die beiden historischen Saldo-Stapeldateien behielten ihre archivierten Binärhashes.
- 27 festgelegte Bindungs- und Rechenfälle sowie 128 weitere, mit festem Seed erzeugte unterschiedliche Eingaben liefen über dieselbe Heizgradstunden-Datei. Unter den 128 Fällen waren 76 Ergebnisse, 26 Eingabefehler und 26 arithmetische Überläufe. Die TIDE-Funktion `int` prüfte die Textbindung. Gültig gebundene Werte wurden durch die TIDE-Referenz ausgewertet. Die CPython-Vergleichsfassung wurde ebenfalls gegen alle Fälle geprüft. [Festgelegte Fälle](faelle.json) · [Bindungsreferenz in TIDE](bindung.tide)
- Sechs zusätzliche Fälle prüften die maximale Listenlänge, einen fehlerhaften letzten Wert, zu viele Werte, die Prüfung der Länge vor dem Parsen und lange Zahlen mit oder ohne führende Nullen. Bei ungültigem Wert meldete die native Datei die erste betroffene Argumentnummer, bei Überschreitung der Listengrenze das Limit. Kein Fehlerfall schrieb ein Ergebnis auf stdout.
- Je acht Prüfungen über einen direkten und einen weiterleitenden Einstieg deckten kurze und lange Rechenzweige, 99.999, 100.000 und 100.001 Auswertungsschritte sowie die Fehlerreihenfolge ab. Beim direkten Einstieg kosteten 3.701 lange und zehn kurze Zweige zusammen mit dem Einstieg genau 100.000 Schritte. Der Wert war 3.701. Beim weiterleitenden Einstieg erreichten 3.697 lange und 25 kurze Zweige dieselbe Grenze. Beide Einstiege meldeten beim ersten zusätzlichen Schritt `E_LIMIT`. Ein früher arithmetischer Überlauf blieb sichtbar, ein fehlerhaftes spätes Argument wurde beim Binden vor der Rechnung erkannt. [Budgetprogramm](budget.tide)

Die ausführbare Datei hat ein schreibgeschütztes ausführbares Ladesegment und einen als nicht ausführbar markierten Stack. Die Prüfung gilt für den dokumentierten i64-Faltungsausschnitt und die vorab typgeprüfte Quelle. Der Laufzeitvergleich betrifft eine Anwendung auf einer Maschine. In keinem der 90 Messpaare wurde das 100×-Ziel erreicht.

## Nachrechnen

Im Projektverzeichnis lassen sich die unter `method` gespeicherten Messprogramme ausführen. Die native Datei entsteht aus der aktuellen TIDE-Quelle in einem temporären Verzeichnis. Für den Zeitvergleich muss logische CPU 2 verfügbar sein.

```sh
set -euo pipefail
build=$(mktemp -d)
data=experimente/21_native_eingaben/messung.json
jq -jr .method.cpython "$data" > "$build/comparator.py"
jq -jr .method.cross_check "$data" > "$build/checks"
jq -jr .method.measure "$data" > "$build/measure"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
```
