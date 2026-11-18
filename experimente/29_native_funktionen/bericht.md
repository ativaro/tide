# TIDE-Funktionen ohne Python prüfen und ausführen

Die unveränderte Bibliothek `lib/ordering.tide` besteht ihre acht Beispiele im nativen Standardpaket. Ein Aufruf von `prefer_min` mit zwei gleichen Werten und `on_equal=true` liefert `true`. Der bisherige native Stand meldete für diese Bibliothek `E_BACKEND`. [Bibliothek](../../lib/ordering.tide) · [Versuchsplan](versuchsplan.md)

## Was ausführbar ist

Funktionsparameter und Ergebnisse können i64 oder boolesch sein. Der Prüfer kennt Literale, Variablen, lokale Bindungen, Bedingungen, Vergleiche, geprüfte Arithmetik und Aufrufe anderer Funktionen. Aufrufziele können weiter unten oder in einem importierten Modul stehen. Rekursion, falsche Argumenttypen und zu tief geschachtelte Ausdrücke liefern lokalisierte Diagnosen. `check` nennt die direkt aufgerufenen Funktionen und die transitiv möglichen Fehler. `run` und `test` verwenden denselben geprüften Ausdrucksbaum. Ein unzulässiger Operand in einem nicht gewählten Zweig fällt bereits bei der Typprüfung auf. Eine gültige Division durch null in einem nicht gewählten Zweig wird beim Aufruf übersprungen. [Funktionsprüfung](../../native/bootstrap/functions.tide) · [Auswertung](../../native/bootstrap/function_run.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" check lib/ordering.tide
"$tool" test lib/ordering.tide
"$tool" run lib/ordering.tide --call prefer_min --inputs '{"candidate":7,"current":7,"on_equal":true}'
"$tool" run native/bootstrap/fixtures/functions/report.tide
```

Die letzten drei Ausgaben sind `{"passed":8}`, `true` und `3`. Das letzte Programm ruft eine Funktion aus einem zweiten Modul auf. Seine sechs Beispiele prüfen unter anderem den ausgelassenen Überlauf in einem inaktiven Zweig und die erwartete Diagnose einer Division durch null. [Beispielprojekt](../../native/bootstrap/fixtures/functions/report.tide)

## Korrektheit

533 Vergleiche auf 316 verschiedenen Einstiegspfaden stimmten mit dem direkten Referenzstarter überein. Darunter waren 334 Aufrufe von `run`, 67 von `check` und je 66 von `test` und `fmt`. Beide Seiten erhielten dieselben Quelldateien und Argumente. Verglichen wurden Exitstatus, Ausgabekanal und vollständiges JSON. Ganzzahlen wurden in voller Präzision verglichen. Für `fmt` zählten die tatsächlichen Bytes. Die native Installation lief für die Vergleiche in einem eigenen Mount-Namensraum ohne Python. [Prüfprotokoll](pruefung.json)

- Der TIDE-Generator erzeugt unter anderem alle 245 Kombinationen aus fünf Rechenoperationen und zwei Operanden mit je sieben Werten, darunter beide i64-Grenzen. Weitere Fälle erfassen Kurzschluss, Reihenfolge der Argumentauswertung, Geltungsbereich von `let`, Aufrufzyklen, doppelte JSON-Schlüssel, ungültige Beispielwerte und Fehler in einer importierten Datei. [Fallgenerator](../../native/bootstrap/function_cases.tide)
- Vier erzeugte Programme benötigen rechnerisch 99.999, 100.000, 100.001 bzw. 100.002 besuchte Ausdrücke. Die ersten beiden liefern `0`. Die anderen liefern an derselben Stelle wie die Referenz `E_LIMIT`, im ersten Fall an Zeile 2, Spalte 43, im zweiten an Zeile 5, Spalte 1. Die Fälle mit 100.000 und 100.001 Schritten laufen auch bei jedem `make test`.
- Der bisherige Typkorpus bestand nochmals alle 510 Vergleiche und 96 Formatierungswiederholungen. Bei 73 weiteren Projekten stimmten 216 Aufrufe unmittelbar mit der Referenz überein. Drei Aufrufe eines Projekts mit noch unportierter Record-Operation meldeten erwartungsgemäß `E_BACKEND`. Bei 48 Projekteinstiegen stimmten Importstellen und Revisionen, bei 1.741 Funktionsrümpfen über 42 Eingaben stimmte die gruppierte Darstellung.
- Der Neuaufbau im leeren Verzeichnis ohne Python erzeugte fünf bytegleiche Werkzeugdateien gegenüber dem regulären Build sowie zwölf Anwendungs-ELFs mit den bisherigen Prüfsummen. Die native Testsuite und separat alle 35 historischen Integrationstests bestanden. UBSan führte den Prüfer einschließlich der 100.000-Schritte-Probe mit seinen normalen Prozessgrenzen aus. Für den zusätzlich mit ASan instrumentierten Bootstrap-Test wurde ausschließlich im Diagnoseabbild die Adressraumgrenze aufgehoben. ASan benötigt einen größeren virtuellen Adressraum.

## Laufzeit des vollständigen Befehls

Drei Aufwärmpaare je Aufgabe, danach wechselnde Startreihenfolge. Die ersten vier Aufgaben und der Kompatibilitätsaufruf erhielten je 20 Messpaare, die drei nachträglich ergänzten Lastfälle je neun. Zeiten sind Mediane. Der Faktor ist der Median der Referenzzeit geteilt durch die native Zeit je Paar. Beide Starter prüfen und bearbeiten TIDE-Quelltext. Der Versuch misst Werkzeugzeit, einschließlich Prozessstart. [Einzelwerte und Prüfsummen](messung.json)

| Aufgabe | TIDE | Python-Referenzstarter | Faktor |
|---|---:|---:|---:|
| Rangfolgebibliothek prüfen | 7,03 ms | 31,21 ms | 4,57× |
| Acht Bibliotheksbeispiele ausführen | 6,19 ms | 31,40 ms | 5,04× |
| Einzelnen Gleichstand mit benannten Eingaben auswerten | 6,07 ms | 31,14 ms | 5,16× |
| Sechs Beispiele über zwei Module | 6,30 ms | 31,23 ms | 4,99× |
| Wiederholte parameterlose Aufrufe bis zur Arbeitsgrenze | 5,36 ms | 79,03 ms | 14,76× |
| Teilweise wiederkehrende Argumente | 8,39 ms | 66,76 ms | 7,99× |
| Ausschließlich neue Argumente | 114,25 ms | 66,68 ms | 0,59× |
| Saldo über das Kompatibilitätspaket | 37,66 ms | 30,74 ms | 0,82× |

Vor den Optimierungen brauchten die drei Lastfälle mit denselben Quellen 292,74 ms (parameterlos), 762,96 ms (teilweise wiederkehrende Argumente) und 735,87 ms (ausschließlich neue Argumente). Die erste Ausführung speicherte Zwischenstände für jeden einzelnen Operanden. Jetzt kann sie Literale und lokale Variablen direkt am Aufrufort auswerten. Der Startcompiler teilt unveränderte Listenpuffer und kopiert sie beim Ändern. Ein geprüfter Zugriff auf eine bestehende Liste kann ein Element direkt lesen. Der Auswerter merkt sich Ergebnisse reiner Funktionen für denselben Argumentsatz. Er belastet das Arbeitsbudget bei einem Treffer mit der tatsächlich beobachteten Knotenzahl. Reicht das Restbudget dafür nicht aus, führt er den Aufruf aus und findet den genauen Fehlerort.

Die erste Cache-Fassung brauchte im Versuch mit ausschließlich neuen Argumenten mehr als zwei Sekunden. Die jetzige Fassung begrenzt die Zwischenspeicherung nach wiederholten Fehlversuchen und benötigt für denselben Lastfall rund 114 ms. Die Python-Referenz bleibt hier schneller. Der zusätzliche Start der Referenz bei noch unportierten Befehlen ist ebenfalls messbar. Tokenverbrauch und Reparaturzeit eines programmierenden Modells wurden in dieser Messung nicht erhoben.

## Grenzen

Der native Funktionspfad liest JSON-Objekte mit einfachen unmaskierten Bezeichnerschlüsseln. Beispielbeschreibungen mit komplexeren Zeichenketten oder JSON-Formen können den Kompatibilitätspfad benötigen. Der JSON-Scanner verarbeitet derzeit bis zu 4.096 Codepunkte pro Eingabe. Ausführung mit Listen, Optionen, Text, Records, Varianten, Zustandsregeln oder Dateirechten, revisionsgebundene Bearbeitung sowie der interaktive Betrieb von Nano und Space Invaders benötigen weiterhin die Referenz. Der ELF-Compiler für ausgewählte Listenfaltungen und Zustandsregeln steht über `tide build` zur Verfügung. [Stand der Ablösung](../../tasks/todo.md)
