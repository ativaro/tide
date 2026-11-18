# Reparatur mit zwei dateiübergreifenden Knotenänderungen

Beide Verfahren reparierten mit der Paarsuche **96 von 96 Läufen bei 0 Modelltokens**. Die zwölf Doppelzähler-Läufe je Verfahren, die im Einzeländerungsversuch offen blieben, bestanden nun die Abnahme. TIDE benötigte in allen 96 Paaren weniger Zeit. Im gepaarten Median war TIDE 2,36-mal so schnell. Die gepaarte Zeitersparnis lag bei 49,7 ms im Median und zwischen 41,1 und 56,7 ms für die mittleren 50 % der Paare. [Vorheriger Versuch](../60_reparaturzeit/bericht.md) · [Einzelzeiten und Rohdaten](messung.json)

| Reparaturzeit bis zur Abnahme | Paare | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Alle Aufgaben | 96 | 36,4 / 45,6 ms | 85,5 / 104,0 ms |
| Doppelzähler mit zwei Änderungen | 12 | 30,7 / 32,6 ms | 71,3 / 74,1 ms |
| Vier Aufgaben mit öffentlichem Gegenbeispiel | 48 | 43,5 / 46,7 ms | 100,3 / 104,3 ms |

## Doppelzähler

Die identische Vorprüfung fand nach 16 Einzeländerungen keinen grünen Kandidaten. Beide Verfahren prüften alle 64 zulässigen Paare zwischen `route` und `rulebook`. Genau ein Paar bestand alle drei öffentlichen Tests. Es ersetzte in beiden Dateien die Addition von 1 durch die Subtraktion von 1. Nach der gemeinsamen Vorschau und Übernahme in die Arbeitskopie bestand der Patch in jedem Lauf auch alle 72 verdeckten Fälle. Die erste Diagnose einschliesslich der Einzel- und Paarsuche dauerte im Median 7,6 ms bei TIDE und 20,7 ms bei Python-AST. Die restliche Zeit entfiel auf die Pool-Erzeugung, Vorschau und Übernahme sowie die abschliessende Abnahme.

In einer separaten Funktionsprüfung mit nur dem ursprünglichen Beispiel `(6, 5) → 54` blieben zunächst drei Paare grün. Bei `(1, 1)` lieferten sie `0`, `8` und `8` in beiden Verfahren. Der Vertrag bestätigte `0`. Nach Ergänzung dieses öffentlichen Beispiels blieb auf beiden Seiten das gleiche Paar übrig wie in der Hauptmessung. Dieser Funktionslauf geht nicht in die Zeit- oder Erfolgskennzahlen ein.

## Vergleichsbedingungen

Die acht Projekte, ihre ursprünglichen öffentlichen Beispiele und die 72 verdeckten Fälle pro Projekt stammen aus Versuch 60. Beide Verfahren starteten mit derselben budgetierten Einzelprüfung. Paare wurden nur geprüft, wenn die Einzelprüfung vollständig war und kein Kandidat durchkam. Pro Paar stammen die Änderungen aus zwei verschiedenen Dateien und aus denselben Operator- und Ausdrucksregeln. Die vier bisherigen Gegenbeispiele und die angezeigten Kandidatenzahlen stimmten in beiden Verfahren überein. [Versuchsplan](versuchsplan.json) · [Quellpaarungen](../60_reparaturzeit/paarungen.json) · [Externer CPython-AST-Vergleich](cpython_pairs.py)

Der Timer startete vor der Pool-Erzeugung und endete nach der unabhängigen Abnahme. Er enthält die Kommandozeilenstarts, Tests, gegebenenfalls die Gegenbeispielsuche und ihre Bestätigung sowie Vorschau und Übernahme des Patches. Für Paare lieferte auf beiden Seiten ein Aufruf die beiden gemeinsam geprüften Texte. Der Messtreiber schrieb sie in die isolierte Arbeitskopie und startete danach den Abnahmelauf. Der Vergleich verwendete TIDE 0.6.1 und CPython 3.14.10 auf derselben logischen CPU mit warmen Systemcaches, frischen Prozessen und wechselnder Startreihenfolge. Beide Verfahren hatten je zwölf Messläufe pro Aufgabe. Die Läufe hatten keinen Netzwerkzugriff und machten keine Modellanfragen.

`make test` bestand. Das installierte Paket bestand die CLI-Prüfung in einem Dateisystem ohne Python und ohne Netzwerk. Dabei stimmte nach Übernahme beider Dateien die Projekt-Revision mit der Vorschau überein. Der alte Revisionswert ergab `E_REVISION`. [Aufruf der Paarsuche und Vorschau](../../workbench/README.md#zwei-dateien-gemeinsam-prüfen)

Die Zeitmessung enthält einen Fehler, der ein Paar erfordert, und sieben Kontrollaufgaben. Die Suche ist auf zwei Dateien pro Paar und 64 Paare begrenzt. Mehrdateien-Patches werden als Vorschau für eine Arbeitskopie ausgegeben. Der atomare Austausch per `--write` gilt für eine einzelne Datei.
