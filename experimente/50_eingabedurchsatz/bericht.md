# Wo kostet das Einlesen einer Liste von Paaren Zeit?

Bei 256 Paaren benötigte derselbe TIDE-Aufruf bisher 13,07 ms und nach der Änderung 9,98 ms. Das direkte CPython-Programm benötigte 10,04 ms. Die mittleren 50 Prozent lagen bei TIDE zwischen 9,72 und 10,27 ms und bei CPython zwischen 9,79 und 10,22 ms. Bei dieser Größe ergibt die Messung einen praktischen Gleichstand. Bei 640 Paaren blieb CPython deutlich schneller. [Rohdaten aller Messreihen](messung.json)

| Paare in der Eingabe | TIDE bisher | TIDE jetzt | CPython | Ausgabetokens pro Werkzeug |
|---:|---:|---:|---:|---:|
| 1 | 7,60 ms | 6,02 ms | 10,09 ms | 3 |
| 64 | 9,11 ms | 7,09 ms | 9,97 ms | 129 |
| 256 | 13,07 ms | 9,98 ms | 10,04 ms | 513 |
| 640 | 20,95 ms | 16,12 ms | 10,41 ms | 1.281 |

Beide Programme erhalten dieselbe JSON-Liste aus Cursor und Status und geben alle Cursorpositionen zurück. TIDE lädt das Projekt samt Typen und Beispielen. Das eigenständige CPython-Programm enthält vorbereitete Prüfungen für die Feldnamen, Grundtypen, Statusnamen und i64-Grenzen dieses Eingabeformats. Die Tabelle zeigt vollständige CLI-Aufrufe einschließlich Prozessstart und Ausgabe. Für die Vergleiche mit CPython wurden gültige Eingaben verwendet. [TIDE-Funktion](../../native/bootstrap/fixtures/functions/composite_pairs.tide) · [CPython-Fassung und Eingabegenerator](messung.json)

## Was die Kontrollprogramme zeigen

Im bisherigen nativen Prüfer dauerte bei 640 Paaren die Funktion `length entries` 11,63 ms. Die Funktion `positions` brauchte auf demselben vorbereiteten Projekt 14,26 ms. Der Aufruf über den vollständigen Paketstarter kostete bei der Längenabfrage 17,19 ms. Damit ließen sich die Kosten der Eingabeverarbeitung und des Starts auch ohne Ausgabe einer langen Liste beobachten.

Eine zweite Kontrolle las bei jedem Prozessstart dieselbe Eingabe über stdin. Für 2.000 Paare dauerte allein das Einlesen mit Rückgabe der Textlänge 1,12 ms, das Auffinden der äußeren JSON-Abschnitte 3,11 ms und die vollständige syntaktische Verarbeitung 19,63 ms. Die typisierte Bindung mit Rückgabe der Listenlänge benötigte insgesamt 33,22 ms. Diese Zahlen sind kumulative Messungen getrennt gestarteter Prozesse. [Kontrollquelltext, Aufrufvarianten und Einzelzeiten](messung.json)

## Was sich geändert hat

Der typisierte Leser bestimmt für Listen von Paaren vor der ersten Zeile, wie er beide Komponenten lesen kann. Grundwerte und Varianten benötigen jeweils ein JSON-Ereignis. Ein Record mit Grundwertfeldern hat ebenfalls eine feste Ereigniszahl. Die Felder dürfen in beliebiger Reihenfolge kommen. Jedes Paar wird auf Form, Feldwerte und Variantennamen geprüft. Für Komponenten mit variabler Struktur bleibt der allgemeine Leser zuständig. Bei einem Fehler kennt TIDE jetzt den Index und die Startposition der betreffenden Zeile und kann dort die genaue Felddiagnose beginnen. [Typisierter Leser](../../native/bootstrap/compound_json.tide) · [Eingabediagnose](../../native/bootstrap/samples.tide)

Ein Profil zeigte zahlreiche Konstruktionen und Kopien von Texten. Der Bootstrap-Compiler erzeugt für ein Textliteral jetzt einen unveränderlichen Wert, den seine Verwendungsstellen gemeinsam lesen. Der Wert entsteht beim ersten Gebrauch. Bei `first` und `second` kann der Compiler die Komponente eines noch lebenden Werts direkt lesen. Temporäre Ergebnisse behalten die bisherige Wertübernahme. Tests prüfen unter anderem verschachtelte Paare, die Lebensdauer eines temporären Ergebnisses, eingebettete NUL-Zeichen und die Unabhängigkeit eines älteren Listenzustands nach `append`. [Compiler](../../native/bootstrap/seed.tide) · [Regressionstests](../../native/bootstrap/compiler_checks.tide)

Bei 2.000 gültigen Paaren ergab eine eigene Messreihe für die Längenabfrage schrittweise 39,35 ms im bisherigen Paket, 35,26 ms mit dem Paarleser, 32,45 ms mit direktem Komponentenzugriff und 29,49 ms mit gemeinsam genutzten Literalen. Die vier Pakete dieser Reihe verwendeten denselben bisherigen Starter. Ein Versuch mit der Compilerstufe `-O2` brachte bei 256 Positionen weitere 0,24 ms. Ein lokaler Bau des Prüfers dauerte damit 20,38 s gegenüber 12,93 s mit `-O1`. Für diesen Zyklus blieb die vorhandene Build-Einstellung erhalten. [Zwischenmessungen und Compilervergleich](messung.json)

Der Paketstarter gibt fertige Ergebnisse von `run`, `test`, `trace`, `fmt` und `edit` unmittelbar auf stdout aus. Der native Prozess prüft das Schreiben einschließlich Flush. Für Metadaten mit Revisionshash verwendet der Starter weiterhin einen Snapshot. Ein Zwischenentwurf sammelte den Ergebnistext in der Shell. Bei 1.792.003 Ausgabebytes benötigte er 155,64 ms, die direkte Ausgabe 134,94 ms und das ursprüngliche Paket 147,08 ms. Eine volle Ausgabedatei ergibt Status 1, ein bereits geschlossener Pipe-Leser wie bisher Status 141. [Paketstarter](../../tide) · [Ausgabetests im isolierten Paket](../../native/bootstrap/no-python.Dockerfile)

## Diagnosen und Abnahme

| Werkzeugauftrag | TIDE bisher | TIDE jetzt | Ausgabetokens vorher und nachher |
|---|---:|---:|---:|
| 2.000 gültige Paare binden und zählen | 40,96 ms | 29,31 ms | 3 |
| Unbekannter Status im letzten von 2.000 Paaren | 44,87 ms | 29,58 ms | 60 |
| Zehn Nano-Beispiele | 13,45 ms | 11,13 ms | 5 |
| Elf Space-Invaders-Beispiele | 29,36 ms | 25,45 ms | 5 |
| Drei Saldobeispiele | 6,63 ms | 5,17 ms | 5 |

Der Fehlerbefund beim letzten Status ist bytegleich und verweist auf `/entries/1999/1`. Über zwölf Paarformen wurden 434 Vergleiche zwischen den Paketen ausgeführt. Darunter waren vertauschte Feldreihenfolgen, Unicode, ungültige Sollwerte, falsche Feldtypen, fehlende Komponenten, Listen an der Grenze von 4.096 Werten und Kombinationen, für die beide Pakete den allgemeinen Leser verwenden. Weitere 55 CLI-Vergleiche betrafen unter anderem Projekt-Lockdateien, Dateifehler, ungewöhnliche Pfadnamen, Kontext, Formatierung und eine revisionsgebundene Änderung. Für Ausgabefehler wurden Rückgabestatus und Fehlerkanal gesondert geprüft. [Dauerhafte TIDE-Lesertests](../../native/bootstrap/checks.tide) · [Protokoll und Prüfsummen](messung.json)

`make test` und `make check-no-python` bestanden mit dem endgültigen Quellstand. Ein gezieltes Compiler-Testprogramm bestand UBSan mit dem regulären Prozesslimit. Für dieselbe einzelne Prüfung mit ASan und UBSan wurde im instrumentierten Testabbild das virtuelle Adressraumlimit angehoben, damit ASan seinen Schattenspeicher reservieren konnte. Die installierten Programme verwenden das reguläre Limit.

Die Tabellen berichten pro Variante den Median aus 21 seriellen Aufrufen nach drei Aufwärmrunden auf Kern 2. Die Reihenfolge der Aufgaben und Werkzeuge wechselte. Die separate Reihe für große Ausgaben umfasst elf Messungen nach zwei Aufwärmrunden. `o200k_base` zählt die vollständige Werkzeugantwort einschließlich Zeilenende. Gesamttokens eines Modells und Zeit bis zu einer selbst gefundenen Reparatur wurden in diesem Zyklus nicht gemessen. [Rechner, Quellen, Quartile und Rohzeiten](messung.json)
