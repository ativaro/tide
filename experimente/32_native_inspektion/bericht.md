# TIDE ohne automatischen Python-Aufruf

Der öffentliche Starter verwendet im Checkout und im installierten Paket dieselben nativen Werkzeuge. Der Installer liefert fünf statisch gelinkte Linux-x86-64-Programme aus. Beim Aktualisieren einer früheren Kompatibilitätsinstallation entfernt er die mitgelieferten Python-Dateien und deren Bytecode. Eine eigene zusätzliche Datei im alten Modulverzeichnis blieb im Upgrade-Test erhalten. Der frühere Interpreter, die interaktiven Hosts und ihre damaligen Tests liegen gemeinsam im [Experimentarchiv](../referenzsystem/README.md).

## Kontext für eine Reparatur

`tide context` und `tide hole` verwenden den typisierten Baum derselben Projektprüfung wie `run`. Ein importierter Knoten behält seinen Modulnamen in der ID. Im Körper einer Faltung kennt die Auswahl Akkumulator, Position und Element. Eine Zustandsinitialisierung beginnt mit leerer Umgebung. Die Kontextansicht führt direkte und transitive Aufrufer sowie die betroffenen Beispiele mit ihren bisherigen SHA-256-Fingerabdrücken auf. Für die Projekt- und die Beispielrevision stammen alle Daten aus dem eingelesenen Schnappschuss. [Inspektion](../../native/bootstrap/inspection.tide) · [Dauerhafte Prüfungen](../../native/bootstrap/inspection_checks.tide)

```sh
./tide context native/bootstrap/fixtures/functions/lists.tide --function weighted
./tide hole native/bootstrap/fixtures/functions/lists.tide --function weighted --node list_ops.tide:2:28
```

## Abnahme am 17. November 2026

- In einem neuen Buildverzeichnis lief `make -j2 CXX=g++ check-native install` in einem Linux-Mount-Namensraum. Sichtbar waren Buildprogramme, Systembibliotheken und TIDE-Quellen. Python-Programme, Standardbibliothek, libpython und das Experimentarchiv waren ausgeblendet. Der Selbstbauvergleich, die nativen Prüfsuiten, Editor- und Spielprüfungen sowie alle zwölf gespeicherten ELF-Prüfsummen bestanden.
- In neun Projekten wurden alle Definitionen und ihre 236 Ausdrucksknoten abgefragt. Die 595 Vergleiche umfassten 508 erfolgreiche Antworten und 87 erwartete Diagnosen. Bei acht zusätzlichen Aufrufen wurden ein Listenliteral mit 4.096 Elementen, ein 86.094 Byte großes Projekt mit Beispielvertrag und eine 48 Definitionen tiefe Aufrufkette geprüft. Alle 603 Ergebnisse stimmten hinsichtlich Exitstatus, Ausgabekanal und JSON-Inhalt mit der extern gestarteten Referenz überein. Ganzzahlen wurden verlustfrei verglichen.
- Ein erster Grenzlauf scheiterte bei der JSON-Darstellung des vollständigen Listenliterals. Die gemeinsame Zeichenkettenkodierung verarbeitet lange Werte jetzt in Abschnitten. Die bestehenden 975 Vergleiche für Funktionen, Listen, Regeln und Spuren wurden mit dem aktualisierten Paket wiederholt. Es gab keine Abweichung.
- Ein zusätzlicher Durchlauf legte ausführbare Aufrufwächter für `python` und `python3` an den Anfang des Suchpfads. Bei erfolgreichen Befehlen sowie bei unportierten Aufrufen im Checkout und im aktualisierten Paket blieb das Aufrufprotokoll leer. Die 35 alten Integrationstests bestanden separat gegen die archivierte Referenz.

## Kosten eines Werkzeugaufrufs

Beide Spalten führen dasselbe TIDE-Projekt mit denselben Argumenten aus. Je Kombination gab es vier Aufwärmpaare und anschließend 15 Messpaare mit wechselnder Startreihenfolge. Gemessen wurde vom Prozessstart bis zur vollständigen Ausgabe. Der native Starter lief aus dem installierten Paket. Die Referenz verwendete CPython 3.14.10. [Einzelmessungen, Quellen und Prüfsummen](pruefung.json)

| Abfrage | Natives Werkzeug, Median | Historische TIDE-Referenz, Median |
|---|---:|---:|
| Aufrufer und Beispiele für den Saldo | 7,79 ms | 31,02 ms |
| Ausgewählter Knoten der Lichtregel | 7,27 ms | 31,18 ms |
| Bindungen in einer importierten Funktion | 7,17 ms | 30,52 ms |
| Kontext mit großem Beispielvertrag | 94,00 ms | 32,73 ms |
| Geklammerter Ausdruck mit 4.096 Operanden | 29,88 ms | 45,12 ms |

Die große Vertragsabfrage beinhaltet das Parsen der 4.096 i64-Eingaben, ihre kanonische Kodierung, die SHA-256-Berechnung in TIDE und die Ausgabe des gesamten Beispiels. Die Messung erfasst diese Kosten gemeinsam. Modell-Tokens und Zeit bis zur Reparatur wurden bei dieser Portierung nicht erhoben.

## Offener Sprachumfang

Das öffentliche Werkzeug meldet bei `play`, `edit`, allgemeinen Dateileserechten und bisher unportierten Ausdrücken `E_BACKEND`. Die Editor- und Spielzustände laufen im nativen Test. Für interaktive Nutzung fehlen die nativen Terminal- und Dokumentoperationen. [Entwicklungsstand](../../tasks/todo.md)
