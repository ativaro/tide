# Zeit bis zum Fehlerbefund bei Record-Eingaben

Beim Buchungsjournal mit 384 Einträgen sank die Zeit für `tide test panel.tide --diff --explain=executed` von 22,54 auf 17,75 ms (−21,3 %). Der vorbereitete CPython-Vergleich benötigte 18,66 ms. Alle drei meldeten beim letzten Saldo den Sollwert 27 und den Istwert 26. Beide TIDE-Pakete gaben dieselben 235 Tokens aus, CPython 259. [Buchungsbeispiel](../46_ergebnisvergleich/ledger/panel.tide) · [Einzelmessungen und Quartile](messung.json)

## Zwei neue Fehler über je drei Dateien

Bei der Warteschlange gewinnt das Ticket mit der höheren Priorität. Bei Gleichstand gewinnt das früher eingereihte Ticket. Die Ankunftsposition liegt zwischen 0 und 31. Die fehlerhafte Gewichtung bevorzugt bei gleicher Priorität das spätere Ticket. Bei der Zeitabrechnung entsprechen zehn Takte einer Einheit. Eine halbe Einheit wird aufgerundet. Ein Intervall von 18 bis 43 umfasst 25 Takte und sollte drei Einheiten ergeben. Das fehlerhafte Programm liefert zwei. [Warteschlange](warteschlange/panel.tide) · [Zeitabrechnung](zeitabrechnung/panel.tide)

| Fehler und vorbereiteter Kontext | TIDE vorher | TIDE jetzt | CPython | Ausgabetokens TIDE / CPython |
|---|---:|---:|---:|---:|
| Gleichstand, statisch | 6,42 ms | 6,31 ms | 16,96 ms | 235 / 241 |
| Gleichstand, tatsächlich ausgeführt | 6,30 ms | 6,33 ms | 17,07 ms | 246 / 252 |
| Rundung, statisch | 6,25 ms | 6,24 ms | 16,98 ms | 216 / 231 |
| Rundung, tatsächlich ausgeführt | 6,28 ms | 6,30 ms | 17,13 ms | 227 / 242 |

Beide Werkzeuge erhielten den Projekteinstieg und das Beispiel. Ihre Antworten enthielten den abweichenden Wert, die Eingabe, den Recordtyp sowie die drei beteiligten Funktionen mit Quellposition. Beide Programme haben verzweigungsfreie Aufrufpfade. Die ausgeführte Ansicht lieferte in jeder Sprache dieselben Funktionen wie die statische und kostete jeweils elf zusätzliche Tokens. Mit einem identischen Platzhalter für die Revisionskennung betrug der Tokenabstand zwischen TIDE und CPython sieben beim Gleichstand und elf bei der Rundung. Die Optimierung des Einlesens brachte bei diesen kleinen Eingaben keinen erkennbaren Zeitgewinn.

Für die fachliche Gegenprüfung wurden beide Fehler in separaten Kopien korrigiert. Beim Gleichstand bestanden vorher 63 von 81 Kombinationen und nachher 81 von 81. Bei der Rundung bestanden vorher 30 von 42 und nachher 42 von 42. Für jeden einzelnen Fall lieferten beide Sprachen vor und nach dem Eingriff übereinstimmende Ergebnisse. TIDE übernahm die Referenzkorrekturen über den nativen Editor anhand der Revision und Knotenkennung. Die Fehler und Reparaturen waren für diese Werkzeugmessung bekannt. [Abnahmeeingaben, Erwartungen und Referenzänderungen](messung.json)

## Wo die Zeit eingespart wird

Der JSON-Leser hält den aktuellen Container separat und verarbeitet direkt benachbarte Schlüssel, Doppelpunkte, Werte und Kommas mit weniger Zustandswechseln. Für Listen von Records mit ganzzahligen, booleschen oder Textfeldern ordnet der Decoder die geprüften JSON-Ereignisse direkt den deklarierten Feldern zu. Die Zuordnung prüft jeden Namen und Typ. Bei abweichender Reihenfolge sucht sie das Feld innerhalb desselben Records. Verschachtelte Feldtypen verwenden den allgemeinen Decoder. [JSON-Leser](../../native/bootstrap/json_stream.tide) · [Typisierter Decoder](../../native/bootstrap/compound_json.tide)

| Kumulierte Zeit einschließlich Prozessstart | 383 Records vorher / jetzt | 4.096 Records vorher / jetzt |
|---|---:|---:|
| Datei über stdin einlesen und Länge liefern | 0,50 / 0,51 ms | 0,77 / 0,79 ms |
| JSON-Ereignisse indizieren | 3,77 / 2,33 ms | 35,42 / 20,09 ms |
| Indizieren und typisierte Werte erzeugen | 5,78 / 3,35 ms | 56,79 / 30,90 ms |

Der reguläre Test des reparierten Journals sank von 20,55 auf 15,25 ms. Ein Kontrollprogramm, das 383 Records unverändert zurückgibt und sie gegen die Erwartung prüft, sank von 19,63 auf 14,25 ms. Mit leerer Liste stieg sein Median von 6,19 auf 6,30 ms. Die ausgeführte Diagnose einer Liste einfacher Ganzzahlen änderte sich von 9,04 auf 9,00 ms. Ein Test mit 64 Records und je 48 Feldern dauerte in deklarierter Reihenfolge 16,08 ms und bei umgekehrter Reihenfolge 18,97 ms. Vorher waren es 26,64 und 27,85 ms. [Stufenmessung in TIDE](stufen.tide) · [Alle Kontrollfälle](messung.json)

## Messbedingungen und Abdeckung

Für die CLI-Mediane liefen je drei Aufwärmrunden und 21 gemessene Aufrufe, für die Stufenmessung zwei und neun. Jeder Aufruf startete einen neuen Prozess auf demselben CPU-Kern. Die Reihenfolge der Werkzeuge und Aufgaben wechselte. Die CPython-Zeit umfasst den Start, die Prüfung der Projektmodule, die Ausführung des Beispiels und das Erstellen des Kontexts. Die ausgeführte Ansicht zeichnet die tatsächlich betretenen Funktionen auf. Die TIDE- und CPython-Antworten wurden vollständig einschließlich Zeilenende mit `o200k_base` gezählt. Die Messung liefert Werkzeugzeiten und Ausgabegrößen. Zeit und Gesamttokens eines Modells bis zur Reparatur bleiben offen. [Vorheriger Versuch und externer Vergleich](../46_ergebnisvergleich/bericht.md) · [Rohdaten und Vergleichsquellen](messung.json)

Die öffentlichen Befehle wurden zusätzlich in 44 Eingabefällen und 28 Editorfällen vor und nach der Änderung verglichen. Exitstatus, Standardausgabe und Fehlerausgabe stimmten byteweise überein. Alle 26 abgelehnten Schreibversuche ließen die ursprüngliche Datei intakt. Die Prüfungen umfassten unter anderem vertauschte Felder, Unicode-Escapes, doppelte Schlüssel, unvollständiges JSON, Ganzzahlgrenzen und Listen mit 4.095, 4.096 und 4.097 Einträgen. Bei breiten Records wurden auch die Werte sämtlicher Felder in drei Reihenfolgen geprüft. Die native Testsuite, die typisierten Vergleichsfälle aus Versuch 46 und der isolierte Neubau samt Paketprüfung ohne Python bestanden. [Dauerhafter Vergleich der Decoder in TIDE](../../native/bootstrap/checks.tide) · [Prüfung ohne Python](../../native/bootstrap/no-python.Dockerfile)
