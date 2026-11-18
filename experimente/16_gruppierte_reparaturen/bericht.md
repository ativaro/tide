# Funktionsgruppierung und benannte Reparaturen

Der neue TIDE-Ablauf sparte gegenüber dem bisherigen bei zwei neuen Fehlern im Median der acht gepaarten Vergleiche 3,08 Sekunden und 190,5 Gesamttokens. Gegen Python mit ebenfalls benannten Reparaturen benötigte er im Median 0,97 Sekunden und 110 Gesamttokens mehr. Alle 32 Antworten bestanden mit der ersten Einreichung die jeweils 40 Abnahmefälle und 30 zusätzlichen verdeckten Fälle.

## Was die früheren Gleichstands- und Rundungsläufe kostete

In den acht untersuchten TIDE-Sitzungen kamen 199.259 Gesamttokens und 125,22 Sekunden zusammen. Die acht entsprechenden Python-Sitzungen benötigten 157.179 Tokens und 75,97 Sekunden. In je einem TIDE-Lauf pro Fehler wurde das bereits übergebene Dateiverzeichnis mit `rg --files` erneut angefordert. In diesen beiden Paaren lagen 40.612 von insgesamt 42.080 zusätzlichen TIDE-Tokens. Die 40.612 sind die gesamten Paardifferenzen und keine separat gemessenen Kosten des Befehls.

| Frühere Aufgabe | Zeit TIDE / Python, Median in s | Denktokens TIDE / Python, Median | Übrige Ausgabetokens TIDE / Python, Median |
|---|---:|---:|---:|
| Gleichstand | 17,20 / 10,44 | 572 / 256,5 | 187,5 / 174 |
| Rundung | 11,39 / 8,49 | 357,5 / 138 | 124,5 / 103 |

Die alten TIDE-Antworten lösten den Gleichstand wiederholt mit ineinander geschachtelten Vergleichen und mehrfachen Feldzugriffen. Bei der Rundung gaben sie den alten Faltungsrumpf und den neuen Ausdruck mit der Rundung außerhalb von `fold` zurück. 3.760 der insgesamt 5.077 ausgegebenen TIDE-Tokens waren als Denktokens ausgewiesen, bei Python 1.560 von 2.707. Die Protokolle messen den gesamten Turn. Sie erlauben keine Aufteilung der Denkzeit auf Syntax, fachliche Überlegung oder Modelllatenz. [Frühere Aufträge und Antworten](../15_gepaarte_reparaturen/messung.json)

## Geändertes Werkzeug

`repair_view` zeigt die vom vorhandenen Compiler vollständig geklammerten Funktionsrümpfe. Der Auftrag nennt die Abdeckung ab dem öffentlichen Einstieg sowie die Argumentreihenfolge von `if` und `fold`. Das Modell darf weiterhin Dateien lesen. Seine Antwort kann mehrere gewöhnliche Funktionen mit je einem Namen und einem vollständigen neuen Rumpf benennen. `candidate_files` erzeugt aus derselben gespeicherten Quellfassung einen gemeinsamen Dateikandidaten. Der Prüfer typisiert und testet diesen in einer separaten Kopie. Beide neuen Werkzeugeinträge sind in TIDE implementiert. Die bisherige Textbearbeitung bleibt verfügbar. [Bedienung und Beispiel](../../workbench/README.md#gruppierte-funktionsrümpfe-reparieren)

Die ursprünglichen Fehler ließen sich mit dem neuen Verfahren offline korrekt reparieren, mit 38/38 beziehungsweise 31/31 bestandenen Abnahmefällen und je 30/30 zusätzlichen Fällen. Bei Bericht, Temperaturregel, Nano und Space Invaders bestanden die vorhandenen Beispiele auch nach dem Rückschreiben der vom Compiler gruppierten erreichbaren Funktionen. Die Werkzeugbeispiele prüfen unter anderem zwei Dateien in einer Antwort, Zeilenenden, doppelte und unbekannte Ziele sowie einen ungültigen zweiten Edit.

## Blinder Vergleich

Bei der **Routenwahl** musste ein Profil zuerst Latenz und dann Stromverbrauch minimieren, ein zweites Profil in umgekehrter Priorität. Der bisherige Code konnte einen schlechteren Hauptwert akzeptieren, wenn der Nebenwert besser wurde. Vollständige Gleichstände sollten die erste Route behalten. Bei den **Druckaufträgen** durften Druckläufe innerhalb eines Auftrags Blätter teilen, getrennte Aufträge und Druckarten aber nicht. Eine Berechnung rundete über Auftragsgrenzen hinweg, die andere für jeden einzelnen Drucklauf.

Beide Fehler steckten jeweils in zwei von vier Modulen. Die Vorabprüfung verglich sämtliche Ausgangsausgaben der Sprachpaare. Bei der Routenwahl bestanden anfangs 21/40 Fälle und nach nur einer kanonischen Teilkorrektur jeweils 28/40. Beim Druck waren es 14/40 und einzeln 18/40 beziehungsweise 28/40. Sämtliche verdeckten Sollwerte standen vor den Modellläufen fest. Jedes Modell erhielt Kundenfall und Vertrag, den gleichen ersten Testfehlschlag und die vorbereiteten erreichbaren Quellen in alphabetischer Dateireihenfolge. Im Prompt stand weder der Fehlerort noch die Zahl der erforderlichen Änderungen. Funktionen zur Quellinspektion und `./verify` waren in allen Gruppen zugänglich.

Pro Fehler gab es vier Blöcke mit je vier frischen, seriell gestarteten Sitzungen. TIDE und Python wurden jeweils mit Textedit sowie mit benannter Funktionsreparatur gemessen. Bei Python nimmt letztere einen gewöhnlichen mehrzeiligen Funktionsrumpf entgegen. Die Reihenfolge war je Fehler so ausbalanciert, dass jeder Ablauf einmal an jeder Blockposition und jeder direkte Übergang einmal vorkam. Modell, Reasoning-Stufe und Serviceklasse waren `gpt-6-astra`, `xhigh` und `priority`. Die monotone Uhr lief vor der Fehlprüfung und Kontextvorbereitung bis zum ersten erfolgreichen externen Prüflauf. Die erneute Prüfung auf frischen Kopien und die verdeckten Fälle lagen außerhalb der Messzeit. [Festgelegte Aufgaben und Reihenfolge](versuchsplan.json) · [Messbefehle und Python-Vergleichsadapter](messverfahren.json)

| Ablauf | Median in s | Median Gesamttokens | Median Denktokens | Summe Gesamttokens | Summe nach Abzug der Cache-Treffer |
|---|---:|---:|---:|---:|---:|
| TIDE · Textedit | 13,95 | 19.978,5 | 392,0 | 200.502 | 16.310 |
| TIDE · Funktionsname | 9,62 | 19.791,5 | 238,0 | 158.479 | 49.679 |
| Python · Textedit | 9,61 | 19.748,5 | 215,5 | 158.081 | 30.081 |
| Python · Funktionsname | 7,68 | 19.676,0 | 200,5 | 157.483 | 101.163 |

Jede Differenz unten ist neuer TIDE-Ablauf minus Vergleichslauf innerhalb desselben Fehler- und Wiederholungsblocks. Positive Werte bedeuten Mehraufwand für TIDE.

| Aufgabe | Vergleich | Mediane Differenz in s | Mediane Differenz Gesamttokens | TIDE schneller | TIDE mit weniger Tokens |
|---|---|---:|---:|---:|---:|
| Beide Fehler | TIDE mit Textedit | −3,08 | −190,5 | 7/8 | 8/8 |
| Beide Fehler | Python mit Funktionsname | +0,97 | +110,0 | 2/8 | 1/8 |
| Routenwahl | TIDE mit Textedit | −4,50 | −197,0 | 4/4 | 4/4 |
| Routenwahl | Python mit Funktionsname | +3,65 | +199,0 | 1/4 | 0/4 |
| Druckaufträge | TIDE mit Textedit | −2,37 | −190,5 | 3/4 | 4/4 |
| Druckaufträge | Python mit Funktionsname | +0,79 | +32,5 | 1/4 | 1/4 |

Der neue TIDE-Ablauf sparte gegenüber dem Textedit im Median 145,5 Denktokens und 68,5 übrige Ausgabetokens je Paar. Beide Größen sanken in allen acht Paaren. Zwei zusätzliche Werkzeugaufrufe gab es in einer einzigen Sitzung mit altem TIDE-Textedit, bei den benannten TIDE-Reparaturen gab es keine. Auch die Compileransicht kostet Zeit. Ihre gesamte Vorbereitung einschließlich des anfänglichen Prüflaufs dauerte im Median 0,64 Sekunden, beim bisherigen TIDE-Verfahren 0,14 Sekunden und bei Python mit benannten Reparaturen 0,03 Sekunden.

Bei Python sparte das benannte Format gegenüber seinem Textedit im Median 1,53 Sekunden und 37,5 Gesamttokens. Neuer TIDE-Ablauf und bisheriger Python-Textedit lagen im Median bei −0,12 Sekunden und +31,5 Tokens Unterschied. Der stärkere Python-Vergleich ist der ebenfalls benannte Ablauf. Nach Abzug der Cache-Treffer beträgt die mediane Paardifferenz gegenüber diesem +37 Tokens für TIDE, mit vier von acht Paaren zugunsten von TIDE. Die Summen der Cache-Treffer schwankten erheblich. [Prompts, Zeitstempel, Antworten, Nutzungszähler und Abnahmen](messung.json)

**Grenze des Befunds.** Gruppierte Darstellung, ausdrückliche Kontextabdeckung und benannte Änderungen wurden bei TIDE gemeinsam getestet. Ihr jeweiliger Anteil lässt sich aus diesem Versuch nicht bestimmen. Die Routenwahl bleibt die größere Lücke: Die TIDE-Antworten schreiben die Prioritätsfolge weiterhin aus. Vier Wiederholungen je Fehler belegen das Verhalten bei diesen zwei Aufgaben mit diesem Modell. Die Messung betrifft den Reparaturablauf, nicht die Ausführungsgeschwindigkeit der fertigen Anwendungen.
