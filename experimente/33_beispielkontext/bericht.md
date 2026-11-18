# Beispielverträge im Reparaturkontext

Ein `tide context` für einen Vertrag mit 4.096 Ganzzahlen dauerte auf derselben Maschine zuerst 92,62 ms und nach der Änderung 28,35 ms. Beim kleinen Saldoprogramm lagen die Mediane bei 6,43 und 6,20 ms. Die vollständigen Antworten der beiden nativen Versionen waren in allen acht Laufzeitvergleichen bytegleich. [Einzelmessungen und Prüfsummen](pruefung.json)

## Wo die Zeit anfiel

Eine separate TIDE-Messfunktion las das 86.094 Byte große Projekt von stdin und beendete sich nach der jeweils ausgewählten Phase. Die Zeiten schließen den Prozessstart ein und sind kumulativ. Vor der Änderung dauerte die Projektprüfung 14,94 ms, mit kanonischem Vertrag 15,21 ms und mit dessen SHA-256 86,21 ms. Ein instrumentierter Lauf zählte 946.880 Aufrufe der aus TIDE-Arithmetik aufgebauten UND-Operation. Nach der Änderung lagen die drei Mediane bei 5,32, 5,54 und 22,76 ms.

Der JSON-Leser verarbeitet die Elemente flacher Listen in Gruppen. Der SHA-256-Kern hält seine acht Arbeitswörter in benannten Feldern und verwendet dieselbe Tabelle für die bitweise Verknüpfung bei allen Verträgen einer Abfrage. In der Vorprobe mit 4-, 6- und 8-Bit-Tabellen lief die 6-Bit-Variante beim großen Vertrag am schnellsten (27,15 ms am direkten Werkzeugeinstieg). Die kleine Saldoabfrage brauchte mit 4 Bit 0,93 ms und mit 6 Bit 1,10 ms. Im Bootstrap stehen die seltenen Diagnosepfade für Arithmetik und indizierten Zugriff getrennt von der erfolgreichen Berechnung. [JSON-Leser](../../native/bootstrap/scalar_json.tide) · [SHA-256 in TIDE](../../native/bootstrap/sha256.tide) · [Bootstrap](../../native/bootstrap/seed.tide)

## Kosten der vollständigen Abfrage

Jeder Aufruf startete einen neuen Prozess. Auf einem AMD Ryzen 9 9950X3D unter Linux waren Messprozess und Kinder auf einen logischen Kern gebunden. Nach drei Aufwärmrunden folgten 15 Runden mit rotierender Reihenfolge. Die Referenz führte dasselbe TIDE-Programm mit dem archivierten Interpreter unter CPython 3.14.10 aus.

| Aufgabe | Nativ vorher | Nativ jetzt | Historische TIDE-Referenz |
|---|---:|---:|---:|
| Saldo, Kontext | 6,43 ms | 6,20 ms | 29,15 ms |
| Licht, ein Knoten | 6,50 ms | 6,29 ms | 29,24 ms |
| Bindungen in importierter Funktion | 6,25 ms | 6,22 ms | 29,46 ms |
| Großer Beispielvertrag | 92,62 ms | 28,35 ms | 30,14 ms |
| Großer und kurzer Beispielvertrag | 92,75 ms | 28,90 ms | 30,24 ms |
| Ausdruck mit 4.096 Operanden | 29,14 ms | 28,64 ms | 43,38 ms |
| Aufrufkette mit 48 Definitionen | 6,75 ms | 6,74 ms | 29,84 ms |
| Großen Vertrag als Test ausführen | 19,88 ms | 10,03 ms | 29,72 ms |

## Wie viel Kontext beim Modell ankommt

`--example-index` liefert Namen, Ziel und SHA-256 der betroffenen Beispiele. Mit `--example NAME` kann das Modell eine Eingabe samt Erwartung lesen. Der Prüfer lädt dabei die gesamte Projektfassung. Bei einer Einzelauswahl berechnet er den Fingerabdruck nur für das ausgewählte Beispiel. Für mehrere Abfragen lässt sich die Projekt-Revision vergleichen. [Benutzung und Saldo-Beispiel](../../README.md#eine-änderung-vorbereiten)

Gezählt wurde die vollständige UTF-8-Standardausgabe einschließlich Zeilenende mit `o200k_base`. Bei den Zeiten handelt es sich um Einzelaufrufe mit je 15 Messwerten. In Klammern stehen die Mediane.

| Projekt | Vollständig | Index | Ein benanntes Beispiel |
|---|---:|---:|---:|
| Großer und kurzer Vertrag | 33.090 Tokens (28,81 ms) | 304 (27,50 ms) | 266 (10,04 ms, `short`) |
| Saldo | 487 (6,20 ms) | 428 (6,21 ms) | 344 (6,13 ms, `movements`) |
| Importierte Funktion | 543 (6,47 ms) | 451 (6,44 ms) | 318 (6,32 ms, `update`) |
| Licht | 533 (6,30 ms) | 493 (6,30 ms) | 403 (6,22 ms, `restart`) |

Wer im großen Projekt erst den Index und dann den kurzen Vertrag abruft, erhält insgesamt 570 Tokens. Die Summe der beiden Einzelmediane beträgt 37,54 ms, eine vollständige Abfrage dauert 28,81 ms. Beim Saldo kosten dieselben zwei Schritte 772 Tokens gegenüber 487 für die vollständige Ausgabe. Die Entscheidung hängt davon ab, ob der Name schon bekannt ist und welche Eingaben das Modell tatsächlich braucht. Gesamttokens eines Modelllaufs und Zeit bis zur erfolgreichen Reparatur wurden in dieser Messung nicht erhoben.

## Abnahme ohne Python

In einem leeren Buildverzeichnis liefen Selbstbau, Tests und Installation ohne Python, Experimentarchiv oder Netzwerk. Fünf native Werkzeuge wurden neu gebaut. Die zwölf Anwendungsdateien für sechs Programme stimmten mit den gespeicherten ELF-Prüfsummen überein. Der Starter im Paket lieferte sowohl Index als auch Einzelauswahl. Nano und Space Invaders bestanden ihre Zustandsprüfungen. Der interaktive Terminalbetrieb und das revisionsgebundene Schreiben mit `edit` sind weiterhin offen.

Die Vergleichsprüfung umfasste 595 bisherige Inspektionsabfragen, acht Grenzabfragen, 975 Funktions-, Listen-, Regel- und Spurprüfungen, 218 neue Ansichten, 45 Diagnosen, 26 unabhängig berechnete Vertragsfingerabdrücke und 83 JSON-Listeneingaben. Alle 1.950 Ergebnisse erfüllten ihre jeweilige Erwartung. Bei vollständigen Standardansichten diente die historische TIDE-Ausgabe als Vergleich. Für die 83 Listeneingaben wurden Status, stdout und stderr byteweise mit dem nativen Vorgänger verglichen. Weitere 15 Arithmetik- und Indexfälle bestanden mit GCC und Clang, jeweils mit aktiviertem UndefinedBehaviorSanitizer. [Dauerhafte TIDE-Prüfungen](../../native/bootstrap/inspection_checks.tide) · [JSON-Grenzfälle in TIDE](../../native/bootstrap/checks.tide)
