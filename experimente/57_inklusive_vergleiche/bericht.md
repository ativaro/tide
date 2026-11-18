# Inklusive Vergleiche · Wiederholungsmessung mit Vorprüfung

TIDE 0.6.1 unterstützt `<= a b` und `>= a b` für vorzeichenbehaftete Ganzzahlen. Beide ergeben einen Wahrheitswert und schliessen Gleichheit ein. Der Prüfer, die Bootstrap-Werkzeuge, beide nativen Compilerpfade und die Operatorvorprüfung verwenden die neue Vergleichsgruppe. Der Projekt-Pin enthält den aktualisierten Operationskatalog. [Sprachreferenz](../../LANGUAGE.md) · [TIDE-Beispiele](../../native/bootstrap/fixtures/functions/inclusive.tide)

| Verfahren mit Vorprüfung | Erfolge / Läufe | Modellanfragen | Gesamttokens | Tokens pro Erfolg |
|---|---:|---:|---:|---:|
| TIDE 0.6.1 | 11/15 (73,3 %) | 3 | 531 | 48,3 |
| Python-AST | 11/15 (73,3 %) | 3 | 555 | 50,5 |

Die Vorprüfung fand beim Kapazitätsfehler genau eine Korrektur für TIDE: den Wechsel von `<` zu `<=`. Sie bestand in allen drei Wiederholungen ohne Modellanfrage. Damit stieg TIDE von **8/15 auf 11/15** und erreichte dieselbe Erfolgsquote wie der erneut ausgeführte Python-Vergleich. Die 24 Tokens Unterschied stammen aus den drei Anfragen zur mehrdeutigen Restaufgabe. Beide Sprachen lieferten dort zwei von drei korrekten Auswahlen. Der Unterschied ist zu klein und die Aufgabe zu eng, um daraus einen allgemeinen Tokenvorteil abzuleiten. [Rohdaten](messung.json) · [Vorheriger Vergleich](../56_gepruefte_operatoren/bericht.md)

Die fünf Fehler, Eingaben, drei Seeds und das Budget von 32 Kandidaten blieben gleich. TIDE und Python-AST prüften jeweils 36 Wechsel. Alle TIDE-Entscheidungen stimmten mit der echten Quellprüfung durch `tide edit` überein. Die Python-Kandidatenliste war mit der vorherigen Messung identisch. Ein einzelner grüner Wechsel ging ohne Modellaufruf in die unabhängige Abnahme mit 72 verdeckten Fällen. Bei zwei grünen Wechseln erhielten beide Sprachen ihre bytegleichen Modellanfragen aus dem vorherigen Versuch erneut. Kein verdeckter Fall erschien im Prompt. Alle sechs gezählten Anfragen liefen auf demselben lokalen Qwen3 4B. [Versuchsplan](versuchsplan.json) · [Modelldigest](modell.json)

Der Rechnungszuschlag benötigt weiterhin einen Ausdrucksersatz. Die Operatorvorprüfung fand dort in beiden Sprachen keinen passenden Wechsel.

`make check-no-python` bestand mit beiden Operatoren im installierten Katalog, im Projektauswerter, im AOT-Programm und in den eigenständigen ELF-Programmen für Faltungen und Regeln.
