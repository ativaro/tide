# Zustandsregeln und Ereignisspuren ohne Python

Das installierte TIDE-Werkzeug prüft die unveränderten Regeln für Licht, Pumpe und Hitzealarm und führt sie über den normalen Projekteinstieg aus. Alle acht Anwendungsbeispiele bestehen. Der vorherige native Paketstand meldete für den Spuraufruf beim Licht `E_BACKEND`. [Lichtregel](../../apps/light.tide) · [Regelprüfer](../../native/bootstrap/rules.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" test apps/light.tide
"$tool" run apps/light.tide --call simulate --inputs '{"events":[true,false,false]}'
"$tool" trace apps/light.tide --example restart --step 2 --fields missed,on
```

Das zweite Ereignis des Beispiels `restart` ist die erste Meldung ohne Bewegung nach dem Einschalten. Die Spur zeigt Zweig 2, für `missed` die Aktion `set` mit dem Übergang von 0 auf 1 und für `on` die Aktion `keep` bei eingeschaltetem Licht. Die Ausgabe bleibt `true`. Der Spuraufruf wertet nur bis einschließlich des angefragten Ereignisses aus. So lässt sich auch der letzte erfolgreiche Übergang eines später fehlschlagenden Beispiels prüfen.

## Auswertung und Abnahme

Alle Aktionen eines gewählten Zweigs lesen den Zustand vor dem Ereignis. Der Ausgabeausdruck liest die aktualisierten Felder. `reset` verwendet den einmal pro Regellauf ausgewerteten Startwert. `scan` kann in weiteren Ausdrücken und über Modulgrenzen aufgerufen werden. Verschachtelte Scans und andere Funktionsaufrufe teilen sich die Arbeits- und Speicherreserve des Aufrufs. Bei einem Fehler trägt die Diagnose die ursprüngliche Quellposition und die Ereignisnummer der innersten betroffenen Regel. [Auswerter](../../native/bootstrap/function_run.tide) · [Prüfprogramm mit importiertem Startwert und Buchungsfunktion](../../native/bootstrap/fixtures/rules/control.tide)

333 neue CLI-Vergleiche prüfen unter anderem 192 deterministisch erzeugte Ereignisfolgen, 15 Fälle an der Arbeitsgrenze, ungültige Regeln, gleichzeitige Änderungen zweier Felder, Fehler in verschachtelten Scans und die Feldauswahl bei der Spurabfrage. Dazu kommen 176 Listenvergleiche und 466 Vergleiche für die bisher unterstützten Funktionen. Verglichen wurden Exitstatus, Ausgabekanal, vollständige JSON-Werte und Diagnosepositionen sowie der genaue Text von `fmt`. Bei den 975 Aufrufen gab es keine Abweichung zwischen dem isolierten nativen Paket und der extern gestarteten Referenz. [Prüfergebnisse](pruefung.json)

Beim Neubau unter Linux x86-64 waren Interpreter, Python-Bibliotheken und Referenzstarter ausgeblendet. Der Bootstrap-Selbstvergleich, die beiden nativen Prüfsuiten, Editor- und Spielprüfungen sowie zwölf Vergleiche neu erzeugter Anwendungs-ELFs mit ihren gespeicherten SHA-256-Werten bestanden. Die gemeinsamen Syntaxfunktionen des Startcompilers und des Projektprüfers liegen jetzt in einem eigenen Modul. Beide Werkzeuge bleiben unter der Quelltextgrenze von 128 KiB. [Buildregeln](../../Makefile) · [Gemeinsame Syntax](../../native/bootstrap/syntax.tide) · [Dauerhafte Grenztests](../../native/bootstrap/checks.tide)

## Messung

Alle Spalten führen denselben TIDE-Quelltext mit derselben Eingabe aus. Gemessen wurde die Zeit vom Prozessstart bis zur vollständigen Ausgabe, einschließlich Projektprüfung und JSON-Verarbeitung. Nach zwei Aufwärmrunden folgten 15 Messrunden auf CPU 2 mit rotierender Reihenfolge der drei Werkzeuge. Die Tabelle zeigt die Mediane in Millisekunden. In den booleschen Messreihen war jedes dritte Ereignis ab dem zweiten wahr. Bei den ganzzahligen Messreihen betrug jeder elfte Wert ab dem ersten 18, alle übrigen Werte waren 81.

| Aufruf | Erste native Fassung | Optimierte native Fassung | TIDE-Referenzinterpreter in Python |
|---|---:|---:|---:|
| Lichtspur für ein Ereignis | 5,34 | 5,25 | 28,84 |
| Licht, 4.096 Ereignisse | 60,80 | 26,03 | 38,23 |
| Pumpe, 4.096 Ereignisse | 42,56 | 25,67 | 40,33 |
| Hitzealarm, 4.096 Ereignisse | 49,49 | 34,21 | 44,55 |
| 4.096 Wahrheitswerte unverändert zurückgeben | 36,16 | 10,43 | 30,41 |

Der letzte Fall erfordert keine Zustandsübergänge. Bereits seine erste Messung zeigte, wie viel Zeit die Ein- und Ausgabe großer Listen kosten kann. Der JSON-Leser setzt den normalisierten Text jetzt abschnittsweise zusammen, und die Ausgabe schreibt Gruppen von 128 Werten. Bei kurzen Regelausdrücken kann der Auswerter das Ergebnis direkt aus Operanden berechnen, ohne einen zusätzlichen Auswertungsrahmen anzulegen. Die Prüfung des Arbeitsbudgets gilt auch dort. Die Messreihe erfasst den gemeinsamen Effekt dieser Änderungen. [Einzelmessungen](laufzeiten.json)

Modell-Tokens, Zeit bis zur Fehlerreparatur und eine eigenständige idiomatische CPython-Anwendung wurden in dieser Messreihe nicht gemessen. Regeln mit weiteren Ein- oder Ausgabetypen, Operationen außerhalb des nativen Auswerters, allgemeine Dateirechte und die interaktiven Hosts benötigen noch die Referenz.
