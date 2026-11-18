# Benannte Felder im nativen Auswerter

Der Messbericht verarbeitet jetzt eine übergebene Liste von Messzeilen und liefert einen Record vom Typ `{Summary}`. Für 80, 81 und 98 beim Grenzwert 80 lautet das Ergebnis `{"above":2,"peak":{"some":98}}`. Die Projektfassung vor diesem Zyklus meldete beim Punktbeispiel aus der Sprachreferenz `E_BACKEND`. Vier fachliche Beispiele prüfen den neuen Rechenkern einschließlich negativem Höchstwert, leerer Liste und ungültiger Zahlenzeile. Der Dateieinstieg delegiert an denselben Kern. Sein Leserecht ist im nativen Paket weiterhin offen. [Messbericht](../../apps/summary.tide) · [Beispiele](../../apps/summary_checks.tide)

## Reparatur über Modulgrenzen

In einer Projektkopie wurde im Messbericht der Vergleich `>` durch `<` ersetzt. Am öffentlichen Testeinstieg stand im Ergebnisfeld `above` nun 0 statt 2. `test --explain=executed` lieferte das Schema von `Summary`, den gewählten Zweig und den gruppierten Rumpf aus dem importierten Modul. `hole` zeigte für den Vergleich den Typ `b` und für den Akkumulator `{Summary}`. Über die ausgegebene Revision korrigierte `edit` den Operator. Anschließend bestanden alle vier Beispiele. Der gruppierte Rumpf ließ sich auch vollständig, mitsamt den Feldnamen, als geprüfter Ersatz zurückschreiben. Die Reparatur war ein Funktionstest durch den Versuchsleiter. [Befund und Prüfergebnis](messung.json)

Bei einem falsch benannten Konstruktorfeld nennt `E_FIELD` den erwarteten und den gelieferten Namen sowie die Position des Namens. Bei einem falschen Feldwert nennt `E_TYPE` die Position des Ausdrucks, Feld, Solltyp und Isttyp. Zwei Records mit gleichen Feldern und unterschiedlichen Typnamen werden an einer typisierten Übergabe unterschieden. Der Feldname ist bei `get` und `with` auch in der Knotenliste von `context` ablesbar. [Feldtypen und Quellfehler](messung.json)

## Vertragsänderung innerhalb eines Felds

Im ersten Record-Prototyp ergab der Wechsel von `{"some":1}` auf `{"some":2}` im Record einer Beispieleingabe denselben Vertragsfingerabdruck. Die getestete Funktion las nur ein anderes Feld, sodass das Beispiel grün blieb. Der Editor schrieb die Änderung mit leerer Liste von Vertragsänderungen. Der bisherige Fingerabdruck baute Objekte nur bis zu einer festen Tiefe wieder auf.

Die neue Fassung besucht jeden Objektschlüssel und sortiert die Schlüssel auf jeder Ebene. Für die beiden Werte entstehen unterschiedliche Fingerabdrücke. Der Editor weist dieselbe Änderung mit `E_CONTRACT` zurück. Mit `--change-examples` akzeptiert er sie und zeigt beide Werte im Änderungsprotokoll. Eine bloße Umordnung der Objektschlüssel behält den Fingerabdruck. Der bereits bestehende Prüffall für den Fingerabdruck eines einfachen Beispiels bleibt bytegleich. [Prüfwerte](messung.json) · [Dauerhafte Prüfung](../../native/bootstrap/inspection_checks.tide)

## Laufzeit

| Öffentlicher Aufruf | Vor Record-Unterstützung | Erster Record-Prototyp | Optimierter Auswerter |
|---|---:|---:|---:|
| Zwei Feldzugriffe je Schritt, 4.096 Schritte | | 26,06 ms | 17,29 ms |
| 1.400 Updates, unverändertes Feld mit 128 Texten | | 8,67 ms | 8,46 ms |
| Messbericht mit 512 Zeilen | | 16,99 ms | 15,79 ms |
| Saldo mit 4.096 Buchungen | 6,67 ms | 6,73 ms | 6,66 ms |
| Saldo mit vier Buchungen | 5,27 ms | 5,24 ms | 5,20 ms |

Jede Zelle ist der Median von 21 Läufen nach drei Aufwärmrunden auf dem logischen Kern 2 eines Ryzen 9 9950X3D. Gemessen wurde vom Start des installierten CLI-Prozesses bis zu seinem Ende, einschließlich Einlesen, Typprüfung und JSON-Ausgabe. Innerhalb jeder Aufgabe wechselte die Reihenfolge der Fassungen. Jedes Ergebnis wurde mit dem vorab berechneten Wert verglichen. Für Records beginnen die Zeitvergleiche mit dem ersten Prototyp, der dieselben Ergebnisse liefert. [Einzelzeiten und Binärprüfsummen](messung.json)

Bei `get` auf einer lokalen Variable kann der Auswerter das typgeprüfte Feld direkt an die umgebende Operation liefern. Das Arbeitsbudget zählt weiterhin den Feldzugriff und das Lesen der Variable. Bei `with` wird die logische Größe übernommener Felder wiederverwendet. Der neue Gesamtwert wird bei jedem Update vollständig auf das Allokationsbudget angerechnet.

Die [Feldzugriffsmessung](project.tide) faltet 4.096 Nullen und addiert jeweils die Koordinaten 2 und 5. Das Ergebnis ist 28.672. Bei der [Update-Messung](update.tide) enthält `labels` 128-mal den Text Ω, `tick` startet bei 0. Die Zeilen enthalten 0 bis 1.399. Der Messbericht erhält die Zahlen −250 bis 261 als Texte mit Limit 80. Die Saldo-Kontrolle startet jeweils bei 100 und bucht 4.096-mal −1 oder die vier Werte −20, 15, −8 und 10.

## Abnahme und Grenzen

117 native Beispielausführungen prüften Konstruieren, Lesen und Aktualisieren mit allen 27 unterstützten Feldtypen und mit leeren sowie belegten Optionen. Fünf zusätzliche ungültige Recordeingaben ergaben `E_INPUT`. Die dauerhafte Budgetprüfung konstruiert einen Record von 1.024 logischen Bytes und aktualisiert ihn 4.095-mal. Genau 4 MiB sind zulässig. Ein weiteres Update ergibt `E_LIMIT`. Die normale Testsuite und der saubere Build ohne Python führen die Prüfungen aus. Das installierte Paket führt den Messbericht im Laufzeitabbild aus. [Budgetprüfung](../../native/bootstrap/checks.tide) · [Containerprüfung](../../native/bootstrap/no-python.Dockerfile)

Die Messung erfasst die Laufzeit des nativen Projektauswerters. Der eigenständige ELF-Compiler unterstützt bisher andere Programmausschnitte. Verschachtelte Records, Records als Listen- oder Optionsinhalt und Variantenwerte sind im Projektauswerter offen. Für diese Erweiterung wurden keine neuen blinden Modellläufe durchgeführt.
