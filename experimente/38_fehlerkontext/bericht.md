# Vom fehlgeschlagenen Beispiel zur Änderung im importierten Modul

`tide test --explain` erstellt beim ersten abweichenden Beispiel einen Reparaturkontext. Beim vorbereiteten Vergleich sank die Anzahl der TIDE-Aufrufe von sieben auf einen. In zwölf blinden Modellläufen waren alle ersten Reparaturvorschläge korrekt. Gegen Python mit ebenfalls vorbereitetem Kontext war TIDE in vier von sechs Paaren schneller und benötigte in zwei Paaren weniger Gesamttokens. [Einzelantworten, Nutzungszähler und Zeitmessungen](messung.json)

## Den Befund selbst erzeugen

Im Berichtsbeispiel ruft `after` die Funktion `adjust` im Nachbarmodul auf. Diese Kopie zieht die Änderung fälschlich vom Betrag ab. Die Befehle werden im Projektstamm ausgeführt.

```sh
work=$(mktemp -d)
cp native/bootstrap/fixtures/functions/report.tide "$work/report.tide"
printf 'adjust amount:i change:i > i\n- amount change\n\nratio amount:i count:i > i\ndiv amount count\n' > "$work/adjustment.tide"
./tide test "$work/report.tide" --explain 2>"$work/befund.json"
cat "$work/befund.json"
```

Das Beispiel `update` meldet wie bisher Status 1, Erwartung 3 und Ergebnis 7. Hinzu kommen die Eingaben, die Projekt-Revision, der gruppierte Rumpf von `after` und der von `adjust`. Letzterer ist `(- amount change)`. Die Knotenkennung lautet `adjustment.tide:2:1`. Mit der ausgegebenen Revision kann ein Agent diese Änderung direkt prüfen und übernehmen.

```sh
revision=$(jq -er .repair.revision "$work/befund.json")
./tide edit "$work/report.tide" --base "$revision" \
  --edits '[{"node":"adjustment.tide:2:1","op":"+"}]' --write
./tide test "$work/report.tide" --explain
# {"passed":6}
```

Das Feld `repair.definitions` folgt dem statischen Aufrufgraphen des Beispielziels. Es enthält auch Aufrufe aus inaktiven Zweigen und jede erreichbare Funktion einmal. So kann ein Agent auch eine fehlerhafte Zweigauswahl im Aufrufer untersuchen. Bei Regeln enthält der Befund den Originaltext mit Datei und Zeilennummer. Typ-, Syntax- und Ladefehler behalten ihre bisherige Diagnose. [Implementierung](../../native/bootstrap/explain.tide) · [CLI-Vertrag](../../LANGUAGE.md#werkzeuge-für-änderungen)

## Aufwand bis zum gleichen vorbereiteten Kontext

In den ursprünglichen acht Paaren für Gleichstand und Rundung entfielen 40.612 der 42.080 zusätzlichen TIDE-Tokens auf zwei Sitzungen, die trotz vorbereitetem Kontext noch einmal die Dateien auflisteten. Beim Gleichstand gaben die Antworten wiederholte Feldzugriffe aus, bei der Rundung fast identische Faltungen. Die frühere Messung protokollierte Zeit und Denktokens je Sitzung. Einzelnen Ausdrücken lässt sich daraus keine Denkzeit zuordnen. Der neue Befehl liefert Beispiel und erreichbare Definitionen gemeinsam. Der neue Modellversuch misst Reparaturen mit vorgelegtem Kontext ohne Shellzugang. Ob ein Agent mit freier Werkzeugwahl weiterhin Dateien auflisten würde, bleibt offen. [Ursprüngliche Läufe](../15_gepaarte_reparaturen/bericht.md) · [Auswertung der Antworten](../25_blinde_quellreparatur/bericht.md)

Für die alte Fassung lief zunächst `test`. Aus der gemeldeten Beispielzeile wurde das Ziel gelesen. Zwei `context`-Abfragen je erreichbarer Funktion lieferten Aufrufe, Wurzelkennung, Signatur und gruppierten Rumpf. Der neue Aufruf liefert dieselben strukturierten Informationen samt zugrunde liegender Revision. Beide während des Versuchs aufbereiteten JSON-Pakete waren für jede Aufgabe inhaltlich gleich und kompakt serialisiert jeweils 869 Byte lang.

| Projekt | Sieben Aufrufe, bisher | Ein Aufruf mit `--explain` | Werkzeugausgabe bisher / jetzt |
|---|---:|---:|---:|
| Koordinatenauswahl | 42,38 ms | 5,96 ms | 10.832 / 870 Byte |
| Rasteranzeige | 42,31 ms | 5,85 ms | 10.878 / 870 Byte |

Gemessen wurden die installierten Pakete auf demselben logischen Prozessorkern mit wechselnder Reihenfolge. Jede Zeit ist der Median von 19 Durchgängen nach drei Aufwärmrunden. Die bisherige Abfolge ist ein reproduzierbarer Weg zu derselben Information. Bei bereits bestandenem Saldo brauchte das aktuelle `test` 5,74 ms, mit `--explain` ebenfalls 5,74 ms. Bei einem großen Unicode-Vertrag waren es 12,41 und 13,31 ms. [Rohmessungen](messung.json)

## Blindversuch mit vorbereitetem Kontext für beide Sprachen

- **Koordinatenauswahl.** Aus einer Liste soll die dem Ursprung nächstgelegene Koordinate gewählt werden. Bei gleicher Entfernung gewinnt die kleinere Koordinate. Die fehlerhafte Fassung wählte die größere. Vor der Reparatur bestanden in beiden Sprachen 4 von 6 öffentlichen und 36 von 72 verdeckten Fällen.
- **Rasteranzeige.** Eine Messung soll auf den nächsten Rasterpunkt relativ zu einer Referenz gerundet werden. Exakte Mittelpunkte werden von der Referenz weg gerundet. Die fehlerhafte Fassung halbierte eine ungerade Rasterweite mit Ganzzahldivision, bevor sie den Rest verglich. Vor der Reparatur bestanden 3 von 6 öffentlichen und 63 von 72 verdeckten Fällen.

Jede Aufgabe umfasste drei Module. Die erste Abweichung erschien am öffentlichen Einstieg, der fehlerhafte Ausdruck lag in einem importierten Modul. Beide Sprachen lieferten vor der Reparatur auf allen 78 Fällen jeder Familie dieselben Ergebnisse. Die validierten Referenzreparaturen bestanden alle Fälle. Eingaben, Reihenfolge und Abnahmeregeln standen vor dem ersten Modelllauf fest. [Versuchsplan mit beiden Fassungen](versuchsplan.json)

Drei frische Codex-Sitzungen je Aufgabe und Sprache erhielten den fachlichen Auftrag, die erste beobachtete Abweichung und die erreichbaren Definitionen. Kein Auftrag nannte den Fehlerort. Für TIDE kam das Paket aus `test --explain`, für Python aus einem Testlauf und dem Python-Syntaxbaum. Modell war `gpt-6-astra` mit `xhigh` und angeforderter Serviceklasse `priority`. Die zwölf Sitzungen hatten einen leeren Arbeitsordner, deaktivierte Erinnerungen und keine Shell. Jede lieferte benannte Funktionsrümpfe ohne Werkzeugaufruf. Der TIDE-Editor prüfte die jeweils gemeldete Knotenkennung und Revision. Die öffentlichen Beispiele und danach 72 verdeckte Fälle wurden für jeden Vorschlag erneut ausgeführt. Bei TIDE lag die verdeckte Abnahme in einer frischen Projektkopie. Die Python-Fassung lief mit schreibgeschützten Quellen in einem separaten Mount-Namensraum.

| Drei Paare je Aufgabe | TIDE, Median bis Abnahme | Python, Median bis Abnahme | TIDE, Median Gesamttokens | Python, Median Gesamttokens |
|---|---:|---:|---:|---:|
| Koordinatenauswahl | 5,29 s | 6,59 s | 18.809 | 18.834 |
| Rasteranzeige | 6,94 s | 6,38 s | 18.881 | 18.823 |

Für den direkten Vergleich zählt die Differenz innerhalb derselben Wiederholung. Beim Gleichstand war TIDE in allen drei Paaren schneller, im gepaarten Median um 0,51 s, und brauchte im gepaarten Median zwei Tokens mehr. Bei der Rundung war TIDE in einem Paar schneller, im gepaarten Median um 0,90 s langsamer und um 77 Tokens teurer. Über alle sechs Paare lauten die Mediane **0,29 s weniger Zeit und 6,5 Gesamttokens mehr für TIDE**. Die Uhr lief von der Kontextvorbereitung bis zum Ende der unabhängigen Abnahme. Gesamttokens umfassen Eingabe einschließlich Cachetreffern und Ausgabe einschließlich Denktokens. Unterschiede im Cache und in der Dienstlatenz sind in den Einzelwerten sichtbar. [Paarwerte und Anbieterzähler](messung.json)

Ein zusätzlicher Pilotlauf brach im Messadapter vor dem Speichern der Nutzungszähler ab. Der Adapter hatte einen zusätzlichen CLI-Eintrag als Werkzeugaufruf gewertet. Die zwölf ausgewerteten Sitzungen wurden anschließend vollständig neu gestartet. Der korrigierte Adapter unterscheidet CLI-Hinweise und Modellwerkzeuge. Zwei kleine Aufgaben mit je einer nötigen Quelländerung erlauben keine allgemeine Rangfolge. Der Vergleich zwischen alter und neuer TIDE-Fassung misst die Werkzeugvorbereitung. Die Modellmessung vergleicht die neue Fassung mit Python.

## Abnahme der Werkzeugänderung

26 Prüfungen am öffentlichen Befehl deckten unter anderem Typ- und Laufzeitfehler, mehrere abweichende Beispiele, Options- und Textwerte, importierte Regeln mit CRLF, unbenutzte Zweige, einen geteilten Unteraufruf, die Aufruftiefe 48 und einen Rumpf über mehrere Knotenseiten ab. Eine veraltete Revision wurde nach einer Moduländerung abgewiesen. Mit dem neuen Befund ließ sich das Modul korrigieren. Die dauerhafte Testsuite enthält den Aufrufgraphen mit geteiltem Unteraufruf und eine Korrektur über die aus dem Fehlerbefund gelesene Revision. [TIDE-Prüfung](../../native/bootstrap/inspection_checks.tide) · [Integrationstest](../../Makefile)

Der Neuaufbau aus einem leeren Buildverzeichnis bestand ohne Python oder Experimentarchiv. Alle sechs installierten Werkzeuge waren statisch gelinkt und bytegleich mit einem zweiten Build. Zwölf ELF-Prüfsummen, 553 Vergleiche für Textverarbeitung und Werkzeuge, 77 Ressourcen- und Diagnosefälle sowie 1.041 Knotenänderungen bestanden. Bei neun vollständigen Faltungen wurden die erwarteten Quellbytes unabhängig bestimmt, weil die historische Referenz dort abbricht. [Prüfnachweise](messung.json)
