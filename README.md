# TIDE 0.6.5

**Typed Instructions, Deterministic Execution** ist eine eigenständige, statisch typisierte Programmiersprache. Die Sprachreferenz definiert ihre Auswertung und Fehler. Ein Sprachmodell kann den Operationskatalog abfragen, Aufrufer untersuchen, einen Teilausdruck ersetzen und fachliche Beispiele ausführen.

Die ersten drei Stufen der Roadmap sind am Bestellimport dokumentiert. Der lokale Vergleich umfasst 15 offene Aufgaben zum Schreiben, Erweitern und Reparieren. Weitere 15 Aufgaben sind für die unabhängige Schlussmessung versiegelt. [20-Stufen-Plan](tasks/plan.md#20-stufen-von-der-machbarkeitsstudie-zur-führenden-sprache) · [Ausgangsmessung gegen CPython](experimente/72_bestellimport_basis/bericht.md)

Der Starter im Checkout und das installierte Paket für Linux x86-64 verwenden dieselben nativen Werkzeuge. Build, Tests, Installation und Ausführung kommen ohne Python aus. Der in TIDE geschriebene Compiler erzeugt eigenständige ELF-Programme für Saldo, Heizgradstunden, Kartonsaldo, Hitzealarm, Pumpe und Licht. `check`, `fmt` und `test` verarbeiten auch verteilte Typdeklarationen mit Records und Varianten nativ. Funktionen über Ganzzahlen, Wahrheitswerten und Unicode-Texten lassen sich mit benannten JSON-Eingaben aufrufen. Er verarbeitet außerdem Records, Varianten, Paare sowie Listen und Optionen dieser Werte. Der native Prüfer führt auch ihre Beispiele aus. Version, CLI-Hilfe, Katalog, gewöhnliche Projekt-Lockdateien und die Stapelabfrage für geklammerte Funktionsrümpfe laufen ebenfalls nativ. [Nativer Build und unterstützter Sprachumfang](native/README.md)

```sh
./tide build apps/light.tide /tmp/tide-light simulate
/tmp/tide-light true false false
# [true,true,false]
```

Der [JSON-Messbericht](apps/report_packages/json_report.tide) importiert Messwerte mit optionalen Notizen und einem Wörterbuch für sensorabhängige Grenzwerte. Der Importer läuft mit `tide run` und als eigenständiges AOT-Programm.

Der [API-Importer](apps/report_packages/api_report.tide) lädt zwei Seiten über HTTPS und speichert sie gemeinsam in SQLite. Eine wiederholte Messwert-ID bleibt pro Quelle eindeutig. Der [Messdienst](apps/report_packages/measurement_service.tide) nimmt Dezimalmesswerte mit Zeitstempel an und liest sie aus PostgreSQL zurück.

```sh
# Die Datenbank und die Rolle müssen bereits bestehen.
dsn='dbname=messbericht'
./tide run apps/report_packages/measurement_service.tide --call prepare --pg "pg=$dsn"
./tide build --service apps/report_packages/measurement_service.tide /tmp/messdienst persist
/tmp/messdienst --listen 127.0.0.1:8080 --workers 4 --pg "pg=$dsn"
```

`make test` prüft den Import gegen einen lokalen TLS-Server. `make check-postgres` prüft als gewöhnlicher Benutzer den Dienst, HTTPS-POST und den Abbruch einer laufenden Datenbankabfrage. Das Ziel startet seinen eigenen PostgreSQL-Cluster und benötigt PostgreSQL-Serverwerkzeuge, curl, OpenSSL und socat. Beim nativen Build werden die Entwicklungsheader von libcurl und libpq benötigt, für den Dienst zusätzlich libmicrohttpd. [Sprachreferenz](LANGUAGE.md#externe-apis-und-dienste)

Der [SQLite-Messbericht](apps/report_packages/sqlite_report.tide) speichert jeden JSON-Import in einer Transaktion. Er berechnet den Bericht über alle gespeicherten Messwerte. `by_sensor` liest die Werte eines Sensors in Einfügereihenfolge. Beide Befehle arbeiten mit derselben Datenbank.

```sh
printf '%s\n' '{"readings":[{"sensor":"A","value":7}],"limits":{}}' > messungen.json
./tide run apps/report_packages/sqlite_report.tide --db db=messungen.db --read input=messungen.json --inputs '{"limit":80}'
./tide run apps/report_packages/sqlite_report.tide --call by_sensor --db db=messungen.db --inputs '{"sensor":"A"}'
```

`make check-sqlite` prüft Commit und Rollback über Prozessgrenzen mit `run` und eigenständigen AOT-Programmen. [SQLite-Sprachregeln](LANGUAGE.md#sqlite)

Der [Streaming-Messbericht](apps/report_packages/stream_report.tide) verarbeitet UTF-8-Dateien mit explizitem Bytebudget. So verarbeitet die vorab übersetzte Fassung eine Messdatei bis 100 MiB.

```sh
./tide build --aot apps/report_packages/stream_report.tide /tmp/tide-stream-report
/tmp/tide-stream-report --read input=messwerte.txt --inputs '{"bytes":104857600,"limit":80}'
```

[Sprachregeln für den Leser](LANGUAGE.md#zeilenweise-lesen) · [Durchsatz und Spitzenspeicher im Vergleich mit CPython](experimente/67_zeilenstrom/bericht.md)

## In einer Minute ausprobieren

Mit `map` schreibst du den Ausdruck für ein einzelnes Element. TIDE baut die Ergebnisliste in Eingabereihenfolge auf. Dieser Aufruf addiert 10 zu jeder Zahl und gibt `[12,9,12]` aus. [Ausführbare Beispiele](native/bootstrap/fixtures/functions/maps.tide)

```sh
./tide run native/bootstrap/fixtures/functions/maps.tide --call offset --inputs '{"xs":[2,-1,2],"shift":10}'
```

```sh
demo=$(mktemp -d)
printf 'variant Signal\nrot gruen\n\nrecord Messung\nwert:i farbe:{Signal}\n' > "$demo/messung.tide"
./tide check "$demo/messung.tide" --json
./tide fmt "$demo/messung.tide"
```

Die erste Ausgabe enthält die Typen und die Revision der gelesenen Datei. Mit `./tide modules apps/space_invaders.tide` erhältst du die Projektversion, die importierten Dateien und die Position jeder `use`-Zeile. Das funktioniert auch, während du einen Funktionsrumpf bearbeitest. [Mehrdateienbeispiel](native/bootstrap/fixtures/modules/report.tide)

Mit `./tide test native/bootstrap/fixtures/functions/variants.tide` kannst du zehn Variantenbeispiele im nativen Paket prüfen. Sie verwenden benannte Fälle für die Auswahl bei Gleichstand und für die Rundung. Wenn in einem Projekt ein neuer Fall hinzukommt, nennt `check` die betroffenen `match`-Stellen samt Datei und Zeile. [Werkzeugmessung](experimente/44_native_varianten/bericht.md)

Die Bibliothek für Rangfolgen kannst du direkt im Standardpaket ausführen. Der erste Befehl prüft acht Beispiele. Der zweite ergibt `true`, weil bei Gleichstand der vorgegebene Wert `on_equal` entscheidet.

```sh
./tide test lib/ordering.tide
./tide run lib/ordering.tide --call prefer_min --inputs '{"candidate":7,"current":7,"on_equal":true}'
```

Das Saldoprogramm verarbeitet eine Liste von Buchungen im Standardpaket. Der erste Aufruf ergibt `97`. Der zweite prüft drei Beispiele einschließlich eines Überlaufs.

```sh
./tide run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
./tide test apps/balance.tide
```

Die Höchstwertsuche gibt den Messwert und die erste zugehörige Zeilennummer als Paar zurück. Bei einer leeren Liste liefert sie `{"none":true}`.

```sh
./tide run apps/peak_lines.tide --call peak_lines --inputs '{"rows":["-8","-2","-2"]}'
# {"some":[-2,2]}
```

Der Messbericht gibt einen Record mit benannten Feldern zurück. Bei einem Limit von 80 zählen nur 81 und 98 als Überschreitungen. Bei einer leeren Liste ist `above` gleich `0` und `peak` die leere Option. [Messbericht](apps/summary.tide)

```sh
./tide run apps/summary.tide --call summarize --inputs '{"rows":["80","81","98"],"limit":80}'
# {"above":2,"peak":{"some":98}}
./tide test apps/summary_checks.tide
```

Die Regeln für Licht, Pumpe und Hitzealarm laufen ebenfalls im Standardpaket. Bei der Lichtregel zeigt die Spur für das zweite Ereignis das erste Ausbleiben einer Bewegung. `missed` steigt von null auf eins, das Licht bleibt an.

```sh
./tide run apps/light.tide --call simulate --inputs '{"events":[true,false,false]}'
./tide trace apps/light.tide --example restart --step 2 --fields on,missed
```

Der erste Aufruf ergibt `[true,true,false]`. Die Spur gibt den gewählten Zweig, den vorherigen und neuen Wert jedes ausgewählten Feldes sowie den Ausgabewert an. [Regelprüfung und Messung](experimente/31_native_regeln_und_spuren/bericht.md)

Der native Auswerter unterstützt auch `catch`. Ein Aufrufer kann mit `has_reason` einen bekannten Fehler behandeln, mit `input_line` die fehlerhafte Datenzeile lesen und mit `raise` die ursprüngliche Diagnose weitergeben. `tide check` zeigt unter `may_fail`, welche Fehler nach dem Handler aus einer Funktion gelangen können.

```sh
./tide run apps/reading_check.tide --call first_invalid --inputs '{"rows":["12","x","3"]}'
# {"some":2}
```

Die Zeilennummer stammt aus dem importierten Zahlenparser. Bei vollständig gültigen Eingaben liefert das Programm `{"none":true}`. [Zeilenprüfung](apps/reading_check.tide) · [Zahlenparser](apps/readings.tide)

## Nano, Space Invaders und Datei-Eingaben

Nanos Editorlogik lässt sich ohne Terminal ausführen. Der erste Befehl prüft zehn Beispiele. Der zweite fügt ein Zeichen ein und fordert das Speichern an. Die Rückgabe enthält den geänderten Puffer und die Aktion `"store"`. Die Eingabe `stored` oder `io_error` liefert die Rückmeldung eines Speicherversuchs. [Nano-Prüfungen und Werkzeugmessung](experimente/49_zusammengesetzte_paare/bericht.md)

```sh
./tide test apps/nano_checks.tide
./tide run apps/nano_checks.tide --call replay \
  --inputs '{"body":"","events":[{"key":"character","value":"Ω"},{"key":"control","value":"o"}]}'
```

Nanos Cursormodul lässt sich auch einzeln aufrufen. Das Beispiel liefert `1`, weil das Katzenzeichen einen Unicode-Codepunkt belegt und unmittelbar danach CRLF beginnt. [Prüfung des Cursormoduls ohne Python](experimente/36_native_texte/bericht.md)

```sh
./tide run apps/cursor.tide --call line_limit --inputs '{"body":"🐈\r\nΩ","pos":0}'
./tide test apps/cursor.tide
```

Space Invaders lässt sich im nativen Paket taktweise ausführen. `main` liefert die Startwelt mit 21 Gegnern und drei Schilden. `tick` verarbeitet einen Tastensatz, `draw` liefert die Zeichen samt Bildschirmpositionen und Farben als JSON. Die elf Beispiele prüfen unter anderem Bewegung, Treffer, Pause und Fortsetzung. [Spielprüfungen und Werkzeugmessung](experimente/45_native_sammlungen/bericht.md)

```sh
./tide test apps/invaders_checks.tide
world=$(./tide run apps/space_invaders.tide)
./tide run apps/space_invaders.tide --call draw --inputs "{\"world\":$world}"
```

Für interaktives Spielen mit `tide play` fehlen noch die nativen Tastatur- und Bildschirmoperationen. Das Öffnen und Speichern echter Dokumente in Nano benötigt noch den nativen Dateizugriff. [Editorprüfungen](apps/nano_checks.tide)

Der Messbericht kann eine freigegebene UTF-8-Datei direkt lesen. `--read` bindet das deklarierte Leserecht, `--inputs` enthält den Grenzwert.

```sh
./tide run apps/report.tide --read input=werte.txt --inputs '{"limit":80}'
```

Der Messbericht lässt sich vorab als eigenständiges Programm übersetzen. Der Build prüft die importierten Module. Die ausführbare Datei braucht beim Start nur die benannte Eingabedatei und den Grenzwert.

```sh
./tide build --aot apps/report.tide /tmp/tide-report
/tmp/tide-report --read input=werte.txt --inputs '{"limit":80}'
```

Die Paketfassung des Messberichts verwendet `rowtext.parse` aus `rowtext@2.0.0` und `measurements.parse` aus `measurements@1.3.0`. Der Importgraph nennt Pfade und Versionen beider Abhängigkeiten.

```sh
./tide modules apps/report_packages/report.tide --json
./tide test apps/report_packages/report.tide
```

[Versionierte Pakete](LANGUAGE.md#versionierte-pakete) · [Vergleich mit CPython](experimente/66_native_pakete/bericht.md)

## Programme

| Anwendung | Eingabe und Verhalten |
|---|---|
| [TIDE nano](apps/nano.tide) | Editorlogik mit Cursor, Zeilenzwischenablage, Speicheranforderung und Bestätigung beim Beenden. |
| [Space Invaders](apps/space_invaders.tide) | Interaktives Terminalspiel mit Formation, Schilden und Gegenfeuer. |
| [Messbericht](apps/report.tide) | Freigegebene Messdatei und Grenzwert ergeben die Anzahl der Überschreitungen und den optionalen Höchstwert. |
| [Erste Fundstelle](apps/first_peak.tide) | Höchste Zahl und erste Zeilennummer bei Gleichstand. |
| [Maximum](apps/maximum.tide) | Höchste Zahl, auch bei ausschließlich negativen Werten. |
| [Licht](apps/light.tide) | Bewegung schaltet ein, zwei aufeinanderfolgende Ruhemeldungen schalten aus. |
| [Pumpe](apps/pump.tide) | Start unter 20, Stopp über 80, Zustand bei Gleichheit erhalten. |
| [Temperaturalarm](apps/heat.tide) | Meldet pro Ereignis, ob die letzten drei Temperaturen alle über 80 lagen. |
| [Buchungssaldo](apps/balance.tide) | Faltet eine Buchungsliste über einen Anfangssaldo und erkennt i64-Überlauf. |

## Programmieren mit einem Modell

Bei unbekanntem Fehlerort stellt TIDE vom öffentlichen Einstieg aus die erreichbaren Funktions- und Regelrümpfe mit ihren Dateinamen, den Typdeklarationen und dem beobachteten Fehler zusammen. Das Modell kann mehrere Änderungen auf einmal zurückgeben. [Reparatur über Modulgrenzen](workbench/README.md#fehler-über-mehrere-dateien-finden)

Für verschachtelte Ausdrücke gibt es eine Ansicht mit der vom Compiler ermittelten Klammerung. Änderungen an mehreren Funktionen lassen sich über ihre Namen als gemeinsame Kandidatenkopie prüfen. [Gruppierte Funktionsrümpfe reparieren](workbench/README.md#gruppierte-funktionsrümpfe-reparieren)

Für kleine Änderungen kann eine Modellantwort je Funktion den betroffenen Textausschnitt und seinen Ersatz angeben. Die Werkbank sucht im gruppierten Rumpf und prüft, dass die Stelle eindeutig ist. [Ausschnitt ersetzen](workbench/README.md#einen-ausschnitt-im-funktionsrumpf-ersetzen)

Für Rangfolgen über mehrere Ganzzahlschlüssel stellt das TIDE-Modul `ordering` die Funktionen `prefer_min` und `prefer_max` bereit. Eine vorbereitete Reparaturansicht kann zusätzlich die Signaturen eingebundener, bisher unbenutzter Funktionen anzeigen. [Priorisierte Vergleiche](LANGUAGE.md#schlüssel-mit-unterschiedlicher-priorität-vergleichen) · [Verfügbare Funktionen im Reparaturkontext](workbench/README.md#weitere-verfügbare-funktionen-anzeigen)

Für eine einzelne Funktion kann TIDE den Arbeitsauftrag aus der Quelldatei ausschneiden. Das Modell liefert den neuen Funktionsrumpf in einer Antwort. TIDE prüft ihn gegen Typen, Beispiele und die gespeicherte Revision. [Aufruf und Beispiel](workbench/README.md)

1. `tide describe` liefert Typnotation, Programmstruktur und verfügbare Operationen. Mit `tide describe OP` lässt sich eine einzelne Operation nachschlagen.
2. `tide check DATEI` prüft das ganze Programm einschließlich importierter Module und gibt Revision, Signaturen, Aufrufe, Außenwirkungen und mögliche abfangbare Fehler aus.
3. `tide context DATEI --function NAME` zeigt die direkten und mittelbaren Aufrufer, betroffene Beispiele und die Knoten der Funktion. `--node ID` beschränkt die Ansicht auf eine Stelle und zeigt deren lokale Bindungen und Klammerung.
4. `tide hole DATEI --function NAME --node ID` liefert für eine geplante Ersetzung den benötigten Typ, die verfügbaren Werte und einen Editentwurf. Das Modell setzt einen vollständigen Ausdruck ein.
5. `tide edit DATEI --base REV --edits JSON` prüft Änderungen an Knoten der Einstiegsdatei und importierter Module gemeinsam. Mit `--source KANDIDAT` kannst du die vollständige Einstiegsdatei vorlegen. `--write` übernimmt die geprüfte Fassung einer einzelnen Datei atomar.
6. `tide trace DATEI --example NAME --step N` macht den Zweig und die Feldänderungen beim angegebenen Ereignis sichtbar. `tide fmt DATEI` gibt formatierten Quelltext aus.

Mit `./tide test DATEI --explain` erhält ein Agent beim ersten fehlgeschlagenen Beispiel auch dessen Eingabe und die von seinem Einstieg erreichbaren Definitionen. Bei Funktionen enthält der Befund den geklammerten Rumpf und dessen Knotenkennung. Damit kann der Agent einen korrigierten Rumpf unmittelbar mit `edit --edits` gegen dieselbe Revision prüfen. [Beispiel und Blindvergleich mit Python](experimente/38_fehlerkontext/bericht.md)

Bei vielen möglichen Aufrufpfaden zeigt `./tide test DATEI --explain=executed`, welche Definitionen und Zweige das fehlerhafte Beispiel tatsächlich ausgeführt hat. Im Tarifbeispiel erreicht ein Paket von genau 500 Gramm den teuren Tarif. Der Befund enthält dafür drei der zehn erreichbaren Funktionen. Bei der Rundungsaufgabe läuft hingegen der ganze Aufrufpfad, und die zusätzlichen Zweigangaben vergrößern den Befund. [Eingaben und Messwerte](experimente/42_ausgefuehrte_zweige/bericht.md)

`./tide test DATEI --diff --explain=nodes` ergänzt den Befund um bearbeitbare Operatorstellen mit Typen und formverträglichen Alternativen. Die Knotenkennungen und die Revision gehen direkt an `tide edit --edits`. [Knoten reparieren](workbench/README.md#einen-knoten-reparieren)

### Eine Änderung vorbereiten

Bei langen Ergebnissen liefert `--diff` den Pfad und die zwei abweichenden Werte. Im folgenden Versuch enthält die letzte von 384 Buchungen den Saldo 26. Das Beispiel erwartet an `/rows/383/balance` den Wert 27. Der zweite Befehl liefert zusätzlich die ausgeführten Funktionen samt Knotenkennungen. Beide Aufrufe enden beim absichtlich eingebauten Fehler mit Status 1. [Messwerte und Vergleich mit CPython](experimente/46_ergebnisvergleich/bericht.md)

```sh
./tide test experimente/46_ergebnisvergleich/ledger/panel.tide --diff
./tide test experimente/46_ergebnisvergleich/ledger/panel.tide --diff --explain=executed
```

Beim Journal mit 384 Buchungen verkürzte der optimierte Record-Leser die Zeit bis zum ausgeführten Fehlerbefund von 22,54 auf 17,75 ms. Der vorbereitete CPython-Vergleich benötigte 18,66 ms. Bei zwei kleinen Mehrdateifehlern zu Gleichstand und Rundung lieferte bereits die statische Ansicht alle beteiligten Funktionen. [Werkzeugzeiten, Tokens und Abnahmefälle](experimente/47_record_eingaben/bericht.md)

Im Saldo-Beispiel prüft dieser Aufruf den Typ und die lokalen Bindungen am Anfang des Funktionsrumpfs. Die Knotennummern stammen aus der gerade gelesenen Revision.

```sh
./tide context apps/balance.tide --function balance
./tide hole apps/balance.tide --function balance --node 2:1
```

Bei großen Beispieleingaben kann das Modell zuerst die Namen und Fingerabdrücke der betroffenen Verträge lesen. Anschließend lässt es sich einen Vertrag mit Eingabe und Erwartung anzeigen. Beide Aufrufe nennen die Projekt-Revision. Eine zwischenzeitliche Änderung ist damit erkennbar. [Ausgabegröße der Kontextansichten](experimente/33_beispielkontext/bericht.md) · [Abfragezeit bei Unicode-Verträgen](experimente/37_vertragsfingerabdruecke/bericht.md)

```sh
./tide context apps/balance.tide --function balance --example-index
./tide context apps/balance.tide --function balance --example movements --node 2:1
```

### Eine Änderung prüfen und übernehmen

Das folgende Beispiel arbeitet auf einer Kopie. Es vertauscht die Operanden der Addition und behält die drei bestätigten Saldo-Beispiele. Der erste `edit` zeigt die neue Revision, die Zahl bestandener Beispiele und die vorgeschlagene Quelle. Der zweite übernimmt sie mit derselben Basisrevision.

```sh
demo=$(mktemp -d)
cp apps/balance.tide "$demo/saldo.tide"
base=$(./tide check "$demo/saldo.tide" | jq -er .revision)
patch='[{"node":"2:38","replace":"+ entry total"}]'
./tide edit "$demo/saldo.tide" --base "$base" --edits "$patch"
./tide edit "$demo/saldo.tide" --base "$base" --edits "$patch" --write
```

Eine veraltete Revision ergibt `E_REVISION`. Änderungen oder Löschungen existierender Beispiele zeigt TIDE mit `E_CONTRACT` an. Wenn die geänderte Erwartung fachlich gewollt ist, erlaubt `--change-examples` die anschließende Prüfung. Neue Beispiele werden sofort mitgeprüft. Ein Änderungsauftrag kann bis zu 256 Stellen derselben Revision enthalten. Für einen Operator genügt zum Beispiel `{"node":"2:38","op":"+"}` als Eintrag. [Dateiübergreifende Suche und Vorschau](workbench/README.md#zwei-dateien-gemeinsam-prüfen)

## Installation und Prüfung

`make native` baut den nativen Compiler. `make test` (auch `make check-native`) prüft den Selbstbau und führt TIDE-Tests für den Compiler, die Editorlogik und das Spiel aus. Der öffentliche Starter lässt sich unter Linux x86-64 mit Make installieren.

Mit `make check-no-python` kannst du die Unabhängigkeit auf Linux x86-64 mit Docker und BuildKit prüfen. Der Lauf baut TIDE in Debian ohne Python aus den Quellen, führt die native Testsuite aus und vergleicht eine aktualisierte Altinstallation mit einer Neuinstallation. Er prüft die statische Bindung aller sechs Werkzeuge und führt das Saldoprogramm über den Checkout und das installierte Paket aus. Das separate Laufzeitabbild prüft auch Versionsbindung, Katalog, Module, Formatierung, Ausführung und Zustandsspur. Ein absichtlich falsches Minus im Saldoprogramm löst einen Fehlerbefund aus. Nach der Reparatur durch den nativen Editor müssen die Quelldatei wieder dem Original entsprechen und alle drei Beispiele bestehen. Build, Tests und Ausführung laufen nach dem Beschaffen der Systempakete ohne Netzwerkzugriff. [Buildrezept](native/bootstrap/no-python.Dockerfile)

```sh
make install PREFIX="$HOME/.local"
```

Der installierte Befehl `tide build` verwendet den mitgelieferten Compiler. Auf dem Zielsystem benötigt er eine POSIX-Shell, Unix-Dateiwerkzeuge und `xxd`. Make und der C++20-Compiler werden beim Paketbau verwendet. Zum Erstellen eines Pakets unterstützt die Installation `DESTDIR`.

`make install` und `make install-native` liefern in ein frisches Präfix ausschließlich native Werkzeuge und ihre Daten. Ein unportierter Aufruf meldet dort `E_BACKEND`. Beim Wechsel von der Kompatibilitätsinstallation entfernt das Installationsziel den bisherigen Starter, die elf ausgelieferten Python-Module und deren Bytecode aus dem Paketverzeichnis. Eigene zusätzliche Module bleiben erhalten.

Der [geprüfte Neuaufbau ohne Python](experimente/35_native_knotenaenderungen/bericht.md) umfasst Selbstbau, Tests, Paketwechsel und Quelländerungen. Die [Inspektionsprüfung](experimente/32_native_inspektion/bericht.md) dokumentiert zusätzlich die Ausgaben von `context` und `hole`. Der frühere Interpreter, seine Integrationsprüfungen und die damaligen interaktiven Hosts sind als [historische Vergleichsbasis](experimente/referenzsystem/README.md) archiviert.

Die [Sprachreferenz](LANGUAGE.md) beschreibt Syntax, Typen, Rechte, Budgets und Fehler. Die [Entwurfsgeschichte](SPEC.md) und die [Selbstversuche](experimente/erkenntnisse.md) dokumentieren die bisherigen Designentscheidungen. Die ursprünglichen prüfsummengebundenen Schreibversuche sind [archiviert](experimente/versuche_vor_umbenennung.tar.gz).
