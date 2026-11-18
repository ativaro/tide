# Vorbereiteter Reparaturkontext in TIDE und Python

TIDE war in 3 von 12 Paaren schneller und verbrauchte in 3 von 12 weniger Gesamttokens. Beides traf in zwei Paaren zu. Alle 24 unabhängigen Sitzungen bestanden die Abnahme mit der ersten Reparatur. Der Zeit- und Tokenvorsprung aus dem früheren Einzelversuch wiederholte sich über die drei neuen Fehlerfamilien hinweg nicht. [Früherer Vergleich](../14_projektkontext/bericht.md)

## Zeit und Tokens bis zur bestandenen Abnahme

Die Differenzen sind jeweils TIDE minus Python. Erst wurde die Differenz innerhalb jedes zeitlich benachbarten Paares bestimmt, dann der Median gebildet. Ein positives Vorzeichen bedeutet höheren Aufwand für TIDE.

| Fehlerfamilie | Paare | Zeit TIDE / Python, Median in s | Gepaarte Zeitdifferenz, Median in s | Gepaarte Gesamttokendifferenz, Median | TIDE schneller | TIDE mit weniger Tokens |
|---|---:|---:|---:|---:|---:|---:|
| Gleichstand bei Höchst- und Tiefstwert | 4 | 17,20 / 10,44 | +6,92 | +354 | 0/4 | 0/4 |
| Rundung von Soll und Haben | 4 | 11,39 / 8,49 | +3,30 | +265 | 1/4 | 0/4 |
| Messreihe nach Neustart | 4 | 11,20 / 12,93 | −1,73 | −47 | 2/4 | 3/4 |
| Alle | 12 | 13,27 / 10,65 | +3,07 | +186,5 | 3/12 | 3/12 |

Die Zeitdifferenzen reichten von −4,23 bis +18,64 Sekunden, die Gesamttokendifferenzen von −79 bis +20.589. Bezogen auf den Python-Wert des jeweiligen Paars lag der Median bei +30,9 % Zeit und +0,95 % Gesamttokens für TIDE.

| Zählweise | Alle 12 TIDE-Reparaturen | Alle 12 Python-Reparaturen | Mediane gepaarte Differenz pro Reparatur |
|---|---:|---:|---:|
| Gesamttokens aus CLI-Eingabe und -Ausgabe | 278.839 | 236.901 | +186,5 |
| Gesamttokens abzüglich gemeldeter Eingabe-Cache-Treffer | 74.679 | 37.349 | +46 |
| Ausgabetokens einschließlich ausgewiesener Denktokens | 6.717 | 4.817 | +156,5 |

Cache-Treffer sind Teil der Eingabe und Denktokens Teil der Ausgabe. Ohne Cache-Treffer war TIDE in sechs Paaren sparsamer. Die Cachebelegung schwankte zwischen Sitzungen.

Beim zweiten TIDE-Rundungslauf und dritten TIDE-Gleichstandslauf listete das Modell trotz vorbereitetem Kontext die Dateien noch einmal mit `rg --files` auf. Das führte zu einer weiteren Übergabe des Modellkontexts. Alle übrigen Sitzungen antworteten ohne Werkzeugaufruf. Auf diese zwei Paare entfielen zusammen 40.612 der insgesamt 41.938 zusätzlichen TIDE-Tokens. Beide Paare sind in allen Hauptwerten enthalten. Auch unter den zehn Paaren ohne Werkzeugaufrufe auf beiden Seiten brauchte TIDE in sieben mehr Gesamttokens. Die lokale Kontextvorbereitung dauerte im Median 0,149 Sekunden für TIDE und 0,035 Sekunden für Python. [Nutzungszähler, Werkzeuge, Prompts, Reparaturen und Zeitstempel](messung.json)

## Aufgaben, Kontrolle und Ablauf

Jede Fehlerfamilie bestand aus vier fachlich entsprechenden Dateien pro Sprache. Beim Ranglistenfehler mussten beide Extremwerte dieselbe Gleichstandsregel beachten. Beim Rechnungsfehler mussten beide Seiten erst nach dem Summieren runden. Beim Messreihenfehler gehörte eine Segmentgrenze zur aktuellen Probe, und die Auswertung der Abstiege musste ungültige Übergänge über diese Grenze auslassen. Jede Sprache lieferte vor der Reparatur für jeden Abnahmefall exakt die gleiche fehlerhafte oder richtige Ausgabe wie die andere.

| Familie | Vorher bestanden | Nur erste Referenzänderung | Nur zweite Referenzänderung | Nach beiden Änderungen |
|---|---:|---:|---:|---:|
| Gleichstand | 12/38 | 22/38 | 22/38 | 38/38 |
| Rundung | 20/31 | 22/31 | 21/31 | 31/31 |
| Neustart | 17/36 | 25/36 | 16/36 | 36/36 |

Der Modellauftrag enthielt den öffentlichen Vertrag und einen Kundenfall. Dazu erhielt jede Sitzung das Ergebnis des fehlgeschlagenen Prüflaufs und die vier Quelldateien in gleicher Reihenfolge nach Dateinamen. TIDE nutzte das unveränderte Werkzeug `project_context.tide` ab `main`, Python erhielt den vollständigen Quelltext. Alle Produktionsfunktionen in den Beispielen waren erreichbar. Keine Fehlerstelle oder Zahl erwarteter Änderungen wurde im Auftrag benannt. Pro Sprache und Familie war der Prompt über alle vier Wiederholungen bytegleich. Die Modelle durften Dateien lesen und den Prüfer starten.

Fehler, Abnahmefälle, Reihenfolge, Paarbildung, Wiederholungsgrenze und Hauptkennzahlen standen vor der ersten Sitzung fest. In vier Blöcken kam jede Familie einmal vor, ihre Position wechselte. Innerhalb jedes Paares liefen die Sprachen direkt nacheinander, jede Sprache begann zweimal pro Familie. Jeder Lauf startete mit einer frischen Projektkopie und einer eigenen ephemeren Sitzung von `gpt-6-astra` mit `xhigh`, angeforderter Serviceklasse `priority` und Codex CLI 0.157.1. Verwendet wurden TIDE 0.5.0 und CPython 3.14.10. [Festgelegter Versuchsplan und Ausgangsprogramme](versuchsplan.json) · [Messbefehle](messverfahren.json)

Die monotone Uhr startete vor der ersten Prüfung und dem Aufbau des Kontexts. Sie stoppte nach Anwendung der Antwort auf eine frische Kopie und dem erfolgreichen externen Test. Alle 24 Antworten wurden anschließend noch einmal auf unveränderte Ausgangskopien angewandt. Jede bestand sowohl ihre ursprünglichen Fälle als auch 30 weitere, während der Modellläufe separat festgelegte Fälle ihrer Familie. Diese zusätzliche Kontrolle gehörte nicht zur Zeitmessung. Die Wiederholungen erfassen Schwankungen bei drei Aufgaben am 16. November 2026. Eine allgemeine Rangfolge für andere Fehler, Modelle oder Servicebedingungen lässt sich daraus nicht ableiten.

## Die zwölf Paare

| Fehlerfamilie | Wiederholung | TIDE in s | Python in s | TIDE-Gesamttokens | Python-Gesamttokens |
|---|---:|---:|---:|---:|---:|
| Gleichstand | 1 | 13,73 | 10,69 | 19.900 | 19.781 |
| Gleichstand | 2 | 15,42 | 9,54 | 20.026 | 19.752 |
| Gleichstand | 3 | 28,83 | 10,19 | 40.317 | 19.728 |
| Gleichstand | 4 | 18,98 | 11,03 | 20.169 | 19.735 |
| Rundung | 1 | 10,51 | 10,61 | 19.677 | 19.566 |
| Rundung | 2 | 15,01 | 7,78 | 39.537 | 19.514 |
| Rundung | 3 | 10,45 | 6,92 | 19.778 | 19.502 |
| Rundung | 4 | 12,28 | 9,21 | 19.855 | 19.601 |
| Neustart | 1 | 8,99 | 13,22 | 19.846 | 19.925 |
| Neustart | 2 | 9,59 | 13,18 | 19.899 | 19.918 |
| Neustart | 3 | 15,67 | 12,59 | 19.892 | 19.967 |
| Neustart | 4 | 12,81 | 12,67 | 19.943 | 19.912 |
