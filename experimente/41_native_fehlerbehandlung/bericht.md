# Fehler aus einem importierten Modul behandeln

Der installierte Starter lieferte vor dieser Änderung bei einem gültigen Programm mit `catch` den Fehler `E_BACKEND`. Jetzt kann der native Projektauswerter einen Fehler im Aufrufer abfangen, seinen Grund und seine Datenzeile auslesen sowie die Originaldiagnose mit `raise` weitergeben. `check` berechnet die nach außen möglichen Fehler auch dann, wenn dieselbe Funktion an mehreren Stellen innerhalb und außerhalb eines Handlers aufgerufen wird. `hole` zeigt den lokalen Diagnosenamen und an einem abbrechenden Ausdruck den erwarteten Ersatztyp. [Auswerter](../../native/bootstrap/function_run.tide) · [Typ- und Fehlerprüfung](../../native/bootstrap/functions.tide)

Im Anwendungsbeispiel prüft `first_invalid` eine Liste von Messzeilen mit dem importierten Parser `reading`. Bekannte Konvertierungsfehler liefern die erste fehlerhafte Zeilennummer. Andere Gründe werden weitergegeben. Die Kontrollfassung prüft mit `int` und zwei Optionsverzweigungen und merkt sich den ersten Treffer im Faltungsakkumulator. Beide liefern die gleiche JSON-Antwort für die gemessenen Eingaben. [Anwendung](../../apps/reading_check.tide) · [Parser](../../apps/readings.tide)

## Laufzeit bis zum Ergebnis

| Zeilen | Erste ungültige Zeile | TIDE vorher, Option | TIDE jetzt, Option | TIDE jetzt, Handler | CPython |
|---:|---:|---:|---:|---:|---:|
| 16 | keine | 5,31 ms | 5,22 ms | 5,90 ms | 9,08 ms |
| 4.096 | 1 | 15,71 ms | 15,36 ms | 10,57 ms | 9,36 ms |
| 4.096 | 2.048 | 20,49 ms | 20,40 ms | 20,81 ms | 9,50 ms |
| 4.096 | 4.096 | 25,39 ms | 25,46 ms | 31,02 ms | 9,64 ms |
| 4.096 | keine | 25,47 ms | 25,45 ms | 31,07 ms | 9,67 ms |

Bei einem Fehler in der ersten Zeile beendet der Handler die Faltung sofort. Bei gültigen Zeilen ruft er für jede Zeile den importierten Parser auf. Die Optionsfassung prüft direkt im Schleifenrumpf. Die Differenz zwischen diesen Anwendungen umfasst beide Unterschiede. Zum Vergleich mit dem ersten Einbau wurden dasselbe Handlerprogramm und dieselbe Optionsfassung zusätzlich mit einer Zwischenversion ausgeführt. Bei 4.096 gültigen Zeilen brauchte sie 33,38 ms für den Handler und 27,49 ms für die Option. Die Endfassung markiert Diagnoseoperationen beim Parsen. Beim Lesen bereits gebundener Operanden kann sie direkt auf die vorhandene Umgebung zugreifen. Das spart für den Handler im gepaarten Median 2,33 ms gegenüber dem ersten Einbau. Für Saldo mit 4.096 Buchungen lagen die Mediane des Ausgangs- und des Endstands bei 7,060 und 7,062 ms.

Alle Werte sind Mediane von 21 neuen Prozessen nach drei Aufwärmrunden auf demselben CPU-Kern. Die Startreihenfolge der Bedingungen wechselte. Die Uhr lief vom Prozessstart bis zum Ende, jede Ausgabe wurde geprüft. TIDE lief über den installierten Einstieg einschließlich Quell- und Eingabeprüfung. Das externe CPython lief mit `-I -S`, prüfte Eingabeform, Listengrenze, Dezimalzeichen und i64-Bereich auf denselben Messdaten. Die Messung erfasst weder Modelltokens noch die Zeit eines Agenten bei der Reparatur. [Einzelmessungen, Quellen und Prüfsummen](messung.json)

## Korrektheit

34 zusätzliche Aufrufszenarien liefen mit dem installierten TIDE-Paket in einem eigenen Namensraum ohne Python. Sie umfassten unter anderem ungeeignete Handlercodes, die Sichtbarkeit der Diagnose, Fehler im Ersatz, verschachteltes Weiterwerfen und die Ereignisnummer eines Regelfehlers. Ein direkter Fehler im importierten Parser und derselbe Fehler nach dem Weiterwerfen lieferten bytegleiches stderr. Ein falsch typisiertes Aufrufargument wurde vor dem Handler als `E_INPUT` abgewiesen. Ein separater Reparaturdurchlauf lieferte über `test --explain` beide beteiligten Funktionen. Eine revisionsgebundene Änderung am Fehlergrund im importierten Modul ließ das Beispiel wieder bestehen. [Diagnosen und Reparatur](messung.json)

Die dauerhafte Testsuite prüft die Erschöpfung des Arbeitsbudgets genau beim nächsten Knoten im Ersatz. Sie verbraucht außerdem in 4.096 verworfenen Ausdrücken insgesamt 4.194.304 Byte Gastbudget und verlangt für die nächste Allokation `E_LIMIT`. Der saubere Debian-Build ohne Python mit kompletter Testsuite, Paketwechsel und separatem Laufzeitabbild bestand. Die ausführbare Zeilenprüfung verwendet `tide run`. Der direkte ELF-Compiler deckt diesen Programmeinstieg noch nicht ab. Für `E_IO` und `E_UTF8` sind der Handler und die statische Fehleranalyse vorhanden. Fehler beim Lesen freigegebener Dateien werden erst mit einer nativen Implementierung dieser Dateioperation prüfbar. [Budgettests](../../native/bootstrap/checks.tide) · [Paketprüfung](../../native/bootstrap/no-python.Dockerfile)
