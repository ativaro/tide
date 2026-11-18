# Listen im TIDE-Standardpaket

Das installierte Werkzeug führt Saldo, Heizgradstunden und Kartonsaldo über `tide run` aus. Die drei unveränderten Anwendungen ergeben bei Aufruf von `main` die Werte `97`, `39` und `2`. Ihre 14 Beispiele bestehen. Der vorherige native Paketstand meldete für `tide run apps/balance.tide` noch `E_BACKEND`. [Saldo](../../apps/balance.tide) · [Heizgradstunden](../../apps/heating.tide) · [Kartonsaldo](../../apps/cartons.tide)

## Unterstützte Programme

Funktionen können Listen von Ganzzahlen und Wahrheitswerten entgegennehmen und zurückgeben. `list`, `length`, `append` und `fold` sind im Typprüfer und Auswerter implementiert. Die Positionsbindung in einer Faltung beginnt bei eins. Die Faltung einer leeren Liste wertet den Startausdruck aus. Eine Änderung der Liste im Akkumulator erhält die ursprüngliche Eingabe. Die zusätzliche Testsuite kombiniert Funktionsaufrufe über eine Modulgrenze, verschachtelte Faltungen und Listen als Ergebnisse. [Prüfprogramm](../../native/bootstrap/fixtures/functions/lists.tide) · [Importierte Funktion](../../native/bootstrap/fixtures/functions/list_ops.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
"$tool" test apps/heating.tide
"$tool" test native/bootstrap/fixtures/functions/lists.tide
```

## Abnahme

Der Neuaufbau auf Linux x86-64 begann mit einem leeren Buildverzeichnis in einem Mount-Namensraum. Die eingebundenen Buildwerkzeuge umfassten GNU Make und den C++20-Systemcompiler. Der Referenzstarter, Python-Interpreter und Python-Bibliotheken waren ausgeblendet. Die native Testsuite, die Installation und zwölf SHA-256-Vergleiche für neu gebaute Anwendungsprogramme bestanden. Die historische Referenz wurde nur außerhalb dieser Umgebung für die Vergleichsläufe gestartet.

176 Aufrufe für Listen und 466 erneute Vergleiche für bisher unterstützte Funktionen ergaben keine Abweichung. Beim Vergleich zählen der Prozessstatus, die Ausgabekanäle, das vollständige JSON einschließlich i64-Werten und Fehlerpositionen sowie die Textausgabe von `fmt`. Die Grenzfälle umfassen 4.096 und 4.097 JSON-Elemente, Listenliterale mit 4.096 Elementen auf einer und mehreren Zeilen, eine ungültige Bindung, einen Überlauf in einem importierten Funktionsrumpf und eine erst während der Faltung erschöpfte Arbeits- oder Speicherreserve. Für den letzten Fall gibt es dauerhafte TIDE-Prüfungen. Zwei ineinander geschachtelte Faltungen führen genau 100.000 beziehungsweise 100.001 Ausdrucksauswertungen aus. Bei wiederholtem Aufruf einer listenbildenden Funktion besteht der Fall mit 511 Eingabeelementen, der mit 512 meldet `E_LIMIT`. [Native Abnahmetests](../../native/bootstrap/checks.tide) · [Ergebnisse des Differentialvergleichs](pruefung.json)

## Laufzeit

Nach drei Aufwärmpaaren wurden 20 Paare separater CLI-Aufrufe gemessen. Die Tabelle zeigt die Mediane. Die Startreihenfolge wechselte von Paar zu Paar. Beide Werkzeuge lasen dasselbe TIDE-Programm und dieselben JSON-Daten. Die Messung erfasst Prozessstart, Projektprüfung, Auswertung und Ausgabe.

| Aufgabe | Natives TIDE-Werkzeug | TIDE-Referenzinterpreter in Python |
|---|---:|---:|
| Saldo mit leerer Buchungsliste | 6,21 ms | 30,38 ms |
| Saldo mit 16 Buchungen | 6,08 ms | 31,41 ms |
| Saldo mit 4.096 Buchungen | 19,55 ms | 35,20 ms |
| Alle drei Saldobeispiele | 6,06 ms | 30,98 ms |
| Sieben Listenbeispiele | 6,52 ms | 31,24 ms |

Eine idiomatische Python-Anwendung, LLM-Tokens und die Zeit einer Modellreparatur wurden in dieser Messreihe nicht gemessen. [Einzelmessungen](laufzeiten.json)

## Offene Python-Pfade

Der Checkout und die explizite Kompatibilitätsinstallation verwenden weiterhin den historischen Interpreter für weitere Datentypen und Operationen, allgemeine Zustandsregeln, Dateirechte, interaktives `play` und die Bearbeitungsbefehle. Das native Standardpaket meldet dort `E_BACKEND`. Der native JSON-Leser deckt die geprüften Ganzzahl- und Bool-Listen ab. Komplexere JSON-Formen und einzelne Syntaxdiagnosen benötigen weiterhin die Referenz. [Entwicklungsstand](../../tasks/todo.md)
