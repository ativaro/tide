# Priorisierte Schlüssel im blinden Mehrdateienversuch

Zwei neue Fehlerfamilien, sechs Wiederholungen je Familie und drei Bedingungen ergaben 36 Reparaturaufträge. Jede Sitzung bekam den Vertrag, ein fehlerhaftes Ergebnis und die Quellen ihrer Sprache. Die Fehlerorte und die Zahl nötiger Änderungen blieben offen.

Die Bibliothek wurde in 1/12 TIDE-Reparaturen mit verfügbarem Modul verwendet. Gegen TIDE ohne Bibliothek betrug die mediane gepaarte Differenz +2,98 s und +144 Gesamttokens. Gegen Python waren es +3,97 s und +359 Gesamttokens. Die Differenzen sind Kosten der jeweils zuerst genannten TIDE-Bedingung abzüglich der Vergleichsbedingung.

## Was sich bereits beim Gleichstand und bei der Rundung zeigte

Beim Gleichstand stiegen die Denktokens im Median von 256,5 bei Python auf 572 bei TIDE, bei der Rundung von 138 auf 357,5. In je einer Sitzung ließ sich das Modell die vorhandenen Dateinamen noch einmal zeigen. Die kompletten Differenzen dieser zwei Paare summierten sich auf 40.612 von 42.080 zusätzlichen Gesamttokens in den acht Paaren. Die Antworten schrieben Gleichstände mit wiederholten Feldzugriffen aus und wiederholten beim Verschieben der Rundung aus der Summation den alten Rumpf für den Textedit. Welcher Anteil der Denkzeit auf einen konkreten Ausdruck entfällt, wurde nicht gemessen. [Frühere Einzelprotokolle](../15_gepaarte_reparaturen/messung.json)

Die gruppierte Compileransicht mit expliziter Kontextabdeckung und Ersetzung nach Funktionsnamen wurde bereits mit neuen Routen- und Druckfehlern gegen Textedit geprüft. Sie sparte gegenüber dem alten TIDE-Verfahren im Median 3,08 s und 190,5 Gesamttokens. Beim neuen Rundungsfehler im Druck war der entsprechende Vorteil 2,37 s und 190,5 Tokens. Gegen Python mit derselben Bearbeitungsform benötigte TIDE beim Druck im Median 0,79 s und 32,5 Tokens mehr. [Versuch mit beiden Bearbeitungsformen](../16_gruppierte_reparaturen/bericht.md)

## Veränderung und Aufgaben

Zwei gewöhnliche TIDE-Funktionen vergleichen ein i64-Schlüsselpaar aufsteigend oder absteigend und nehmen eine weitere Entscheidung für den Gleichstand entgegen. Die Reparaturansicht kann Signaturen bislang unbenutzter Funktionen aus der geprüften Fassung mitgeben. Beide TIDE-Bedingungen nutzen dieselbe Kontextvorbereitung. In der Bibliotheksbedingung kommen der Import und die beiden verfügbaren Signaturen hinzu. Alle fachlichen TIDE-Quelldateien sind ansonsten bytegleich. Python erhält alle vier Module und ebenfalls die Möglichkeit, Funktionen in einer Antwort nach Namen zu ersetzen. [Modul](../../lib/ordering.tide) · [Kontextwerkzeug](../../workbench/project_context.tide)

Bei der Einsatzvergabe bestimmen zwei Profile über je drei unterschiedlich priorisierte Kriterien den Gewinner. Bei identischen Kriterien gewinnt der frühere Eintrag. Im Ereignisjournal muss ein Übergang nach Minute, absteigender Priorität und Seriennummer bewertet werden. Eine Umkehr beginnt ein neues Segment mit dem eingehenden Ereignis. Bei beiden Aufgaben betraf die kanonische Korrektur zwei Module. Von je 40 Abnahmefällen bestanden vor der Korrektur 25 bei der Vergabe und 13 beim Journal. Mit jeweils nur einer der zwei Referenzänderungen waren es 30 beziehungsweise 31 und 22 beziehungsweise 23. Mit beiden Änderungen bestanden je 40.

## Reparaturen bis zur bestandenen Abnahme

Die absoluten Werte sind Mediane der sechs Einzelmessungen je Tabellenzeile. Gesamttokens umfassen Eingabe einschließlich Cachetreffern plus Ausgabe einschließlich Denktokens. Zugriffe zählen vom Modell gestartete Shellbefehle.

| Aufgabe | Verfahren | Zeit (s) | Gesamttokens | Ausgabetokens | Denktokens | Vorbereitung (s) | Zugriffe |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Einsatzvergabe | TIDE ohne Bibliothek | 13,92 | 20.108 | 644 | 429 | 0,65 | 0 |
| Einsatzvergabe | TIDE mit Bibliothek | 14,93 | 20.249,5 | 757,5 | 542,5 | 0,68 | 0 |
| Einsatzvergabe | CPython | 10,09 | 19.878 | 457 | 280,5 | 0,03 | 0 |
| Ereignisjournal | TIDE ohne Bibliothek | 12,78 | 20.114 | 580 | 396 | 0,58 | 0 |
| Ereignisjournal | TIDE mit Bibliothek | 14,87 | 20.257 | 695 | 511 | 0,59 | 0 |
| Ereignisjournal | CPython | 10,20 | 19.932,5 | 462,5 | 294,5 | 0,04 | 2 |

Für jede Zeile der folgenden Tabelle wurden die Differenzen innerhalb desselben Wiederholungsblocks berechnet und dann ihr Median gebildet. Kleinere Werte begünstigen TIDE mit Bibliothek. Zeit und Tokens können in unterschiedlichen Blöcken gewinnen.

| Aufgabe | TIDE mit Bibliothek minus … | Δ Zeit (s) | Δ Gesamttokens | Δ Tokens nach Cacheabzug | Schneller | Weniger Tokens |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Einsatzvergabe | TIDE ohne Bibliothek | +2,98 | +142 | +112,5 | 2/6 | 1/6 |
| Einsatzvergabe | CPython | +3,97 | +337 | +334 | 1/6 | 0/6 |
| Ereignisjournal | TIDE ohne Bibliothek | +2,58 | +183,5 | +942 | 1/6 | 0/6 |
| Ereignisjournal | CPython | +4,48 | +374,5 | +353,5 | 1/6 | 1/6 |
| Beide | TIDE ohne Bibliothek | +2,98 | +144 | +142 | 3/12 | 1/12 |
| Beide | CPython | +3,97 | +359 | +334 | 2/12 | 1/12 |

Gegen Python reichten die individuellen Differenzen von -9,82 bis +22,24 s und von -41.028 bis +21.058 Gesamttokens. In 1/12 Blöcken war die Bibliotheksbedingung schneller und tokensparsamer zugleich. Bei der Vergabe benutzten 1/6 Antworten die bereitgestellten Funktionen, beim Journal 0/6. Das Experiment misst den Nutzen des freiwillig verfügbaren Angebots. Eine Auswertung nur der Antworten, die es wählten, wäre durch Selbstselektion verzerrt.

| Verfahren, je 12 Läufe | Gesamttokens, Summe | Abzüglich Cachetreffern | Ausgabetokens | Versuche | Abnahmen bestanden |
| --- | ---: | ---: | ---: | ---: | ---: |
| TIDE ohne Bibliothek | 241.270 | 19.190 | 7.282 | 12 | 12 |
| TIDE mit Bibliothek | 263.502 | 41.422 | 9.376 | 13 | 12 |
| CPython | 279.991 | 19.383 | 6.168 | 12 | 12 |

Alle 36 Reparaturen bestanden auch die Kontrollprüfung. 35 gelangen mit der ersten Antwort. Im dritten Journallauf mit TIDE-Bibliothek fehlte am Ende des verschachtelten Vergleichs eine schließende Klammer. Der Compiler meldete `E_SYNTAX` in `sequence.tide`. Die zweite Antwort ergänzte genau dieses Zeichen. Bis zur Abnahme verbrauchte dieser Auftrag 40.948 Gesamttokens in 31,09 s. Im vierten Python-Journallauf prüfte das Modell die Dateiliste und danach neun eigene Beispiele im Speicher. Dieser Lauf verbrauchte 61.284 Gesamttokens in 25,09 s. So konnte Python bei elf von zwölf Paaren weniger Gesamttokens benötigen und dennoch in der Summe mehr verbrauchen. Beide Ausreißer sind vollständig eingerechnet. [Einzelantworten, Diagnosen und Werkzeugaufrufe](messung.json)

Für den normalen Reparaturablauf behalten wir die gruppierten Rümpfe und Änderungen nach Funktionsnamen bei. Die Vergleichsfunktionen bleiben optional. Ihre bloße Signatur im Kontext führte nur einmal zur Verwendung und brachte bei diesen Aufgaben keinen typischen Reparaturvorteil. Die Zahlen für freiwillige Verwendung erlauben keine Aussage darüber, wie schnell eine ausdrücklich verlangte Bibliothekslösung geschrieben würde.

## Laufzeit der fertigen Programme

Die folgenden Zahlen sind Millisekunden für alle 40 öffentlichen Eingaben einer Aufgabe. Gemessen wurden die kanonischen Lösungen im warmen TIDE-Referenzinterpreter und in CPython. Die Bibliothekslösung verwendet die Vergleichsfunktionen ausdrücklich. Beide TIDE-Messungen schließen die Einrichtung des Auswertungsbudgets pro Aufruf ein. Daten, Imports und Kompilierung waren vorab geladen. Nach drei Aufwärmaufrufen je Verfahren folgten 18 Runden zu acht Aufrufen je Verfahren, bei rotierender Reihenfolge und fester CPU. Alle gemessenen Varianten lieferten dieselben erwarteten Ergebnisse. [Messcode, Einzelzeiten und Auswertungsschritte](laufzeit.json)

| Aufgabe | TIDE ohne Bibliothek (ms) | TIDE mit Bibliothek (ms) | CPython (ms) | TIDE-Auswertungsschritte ohne / mit |
| --- | ---: | ---: | ---: | ---: |
| Einsatzvergabe | 3,851 | 5,604 | 0,058 | 9.043 / 13.531 |
| Ereignisjournal | 4,951 | 5,989 | 0,043 | 10.948 / 13.659 |

TIDE wertet Funktionsargumente vor dem Aufruf aus. Damit kann die Bibliothekslösung auch nachgeordnete Schlüssel auswerten, obwohl ein höherer Schlüssel bereits entscheidet. Ein Fehler in einem solchen Folgeausdruck bleibt beobachtbar. Ein gezieltes Beispiel prüft diesen Unterschied zum bedingten Ausdruck. Der native Compiler deckt diese Record- und Listenprogramme noch nicht ab. [Bibliotheksprüfungen](../../lib/ordering_checks.tide) · [Nativer Compiler](../../native/README.md)

## Reproduktion und Grenzen

Jede der sechs Reihenfolgen der drei Bedingungen kam je Familie einmal vor. Jeder Modelllauf war eine eigene ephemere, serielle Sitzung mit gpt-6-astra, Denkaufwand xhigh, angeforderter Serviceklasse priority und codex-cli 0.157.1. Die monotone Zeit beginnt vor dem ersten fehlgeschlagenen Prüflauf und der Kontextvorbereitung und endet mit dem ersten erfolgreichen externen Test. Eingabe und Ausgabe stammen aus der CLI-Nutzungsmeldung. Nach Abschluss wurden alle akzeptierten Antworten auf neuen Ausgangskopien erneut angewendet und gegen 40 Abnahmefälle sowie 40 weitere vorab festgelegte Fälle ihrer Familie geprüft. Öffentliche und zusätzliche Eingaben sind pro Familie disjunkt. Die Auswertung umfasst 37 verschiedene Sitzungskennungen. Vorbereitete Prompts waren je Familie und Bedingung über die sechs Wiederholungen bytegleich.

Eine frühere Ausführung derselben Serie wurde unterbrochen, ihre temporären Einzelprotokolle gingen verloren. Sämtliche ausgewerteten Reparaturdaten stammen aus dem vollständigen Neustart mit demselben vorher festgelegten Plan. Die Wiederholungen erfassen die Streuung auf zwei gezielt ausgewählten Aufgaben. Cachebelegung und Antwortlatenz können zwischen Sitzungen schwanken. [Versuchsplan, Quellstände und Fälle](versuchsplan.json) · [Befehle für den Messablauf](messverfahren.json) · [Prompts, Antworten, Zeiten, Tokens und Kontrollprüfungen](messung.json)
