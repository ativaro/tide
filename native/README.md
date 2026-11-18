# Nativer TIDE-Compiler

Der Compiler liest TIDE-Quelltext und erzeugt eine ausführbare ELF-Datei für Linux auf x86-64. Das Saldoprogramm gibt `97` aus. Das Heizgradstundenprogramm vergleicht jede Temperatur mit 18, addiert die Differenz für kältere Stunden und gibt `39` aus. [Saldo](../apps/balance.tide) · [Heizgradstunden](../apps/heating.tide)

## Ohne Python bauen

```sh
./tide build apps/pump.tide /tmp/tide-pumpe simulate
/tmp/tide-pumpe 19 20 80 81
# [true,true,true,false]
make check-native
```

Der erste Aufruf baut den Compiler unter `build/native` aus den TIDE-Quellen. Weitere Aufrufe verwenden denselben Compiler. Der optionale letzte Parameter wählt die Einstiegsfunktion, der Standard ist `main`. Die Ausgabedatei wird nach erfolgreicher Übersetzung atomar ersetzt. Der native Backend-Build erwartet ein Programm aus dem unten beschriebenen, bereits geprüften Ausschnitt. Er führt keine allgemeine Projekt-Typprüfung und keine eingebetteten Beispiele aus. Für Typdeklarationen über mehrere Dateien prüfen `tide check` und `tide test` nativ. `tide modules DATEI` gibt für alle Projektarten Importstellen und Revision aus. [Modulprüfung](../experimente/28_native_module/bericht.md)

Der native Funktionsprüfer unterstützt i64, boolesche Werte, Texte sowie Listen und Optionen dieser drei Typen, Arithmetik, Vergleiche, Kurzschlusslogik, `if`, `let` und aufgerufene Funktionen im selben oder einem importierten Modul. `tide run` bindet benannte JSON-Eingaben. `tide test` führt die Beispiele mit demselben Auswerter aus. Mit `list`, `length`, `append` und `fold` sind unter anderem die unveränderten Programme für Saldo, Heizgradstunden und Kartonsaldo ausführbar. Eine Faltung kann als Akkumulator eine Liste verwenden und weitere Faltungen aufrufen. [Listen und Ressourcengrenzen](../experimente/30_native_listen/bericht.md)

Mit `map B liste element rumpf` erzeugt der Projektauswerter genau einen Ergebniswert vom Typ `B` je Eingabeelement. Ein Fehler im Rumpf enthält die Quellstelle und den nullbasierten Elementindex. Die Positionsabfrage und Space Invaders verwenden die Operation für Zahlen und Records. [Werkzeugmessung und Abnahme](../experimente/51_listenabbildung/bericht.md)

Für Unicode-Text laufen `concat`, `text_eq`, `text_len`, `text_slice`, `text_find`, `text_rfind`, `lines` und `int` über den öffentlichen Projekteinstieg. `some`, `nil`, `case`, `need` und `at` erlauben es, fehlende Treffer oder ungültige Zahlen explizit zu behandeln. Nanos Cursorfunktionen und die Erkennung von Funktionsköpfen in der Reparaturwerkbank nutzen diese Operationen. [Messungen und Umfang](../experimente/36_native_texte/bericht.md)

Funktionen können mit `pair` auch Records, Varianten und weitere Paare verbinden. `first` und `second` liefern die statisch typisierten Komponenten. Das Beispiel `peak_lines` verwendet `?&ii` für einen Höchstwert samt Zeilennummer. Nano gibt bei jedem Tastendruck `&{Buffer}{Effect}` zurück. Eine Folge von Tasten und Speicherrückmeldungen lässt sich mit `tide run apps/nano_checks.tide --call replay` und den benannten Eingaben `body` und `events` ausführen. [Grundtypen](../experimente/39_native_paare/bericht.md) · [Nano und zusammengesetzte Paare](../experimente/49_zusammengesetzte_paare/bericht.md) · [Eingabedurchsatz und Fehlerpfade bei langen Paarlisten](../experimente/50_eingabedurchsatz/bericht.md)

Funktionssignaturen können benannte Records sowie Listen und Optionen benannter Records und Varianten verwenden. Recordfelder können diese Typen ebenfalls enthalten. `make` konstruiert einen Record, `get` liest ein Feld und `with` erzeugt einen aktualisierten Wert. Das Gastbudget zählt die gesamte logische Größe des Ergebnisses, auch wenn sich die Werte intern Speicherseiten teilen. Die Spielwelt von Space Invaders läuft so einschließlich Gegnern, Schilden und optionalen Geschossen über `tide run`. [Feldoperationen](../experimente/43_native_records/bericht.md) · [Verschachtelte Werte und Messung](../experimente/45_native_sammlungen/bericht.md)

Ein Variantentyp lässt sich als Parameter, Ergebnis und direktes Recordfeld verwenden. `tag` erzeugt den Wert, `match` führt den gewählten Zweig aus. Bei einer ergänzten Spielphase nennt `tide check` die ausstehenden Entscheidungen in `draw` und `tick` gemeinsam. [Werkzeugmessung und Spielprüfung](../experimente/44_native_varianten/bericht.md)

Für Regeln mit ganzzahligen oder booleschen Ereignissen und Ergebnissen prüft TIDE die Initialisierungen, alle Zweige und den Ausgabeausdruck. `scan` funktioniert auch bei Funktionsaufrufen und importierten Regeln. Die Feldaktionen eines Zweigs lesen den Zustand vor dem Ereignis. Der Ausgabeausdruck sieht die bereits aktualisierten Felder. `tide trace` zeigt diesen Übergang für ein einzelnes Beispielereignis und kann die Ausgabe auf angegebene Felder begrenzen. [Prüfung, Zustandsgrenzen und Zeiten](../experimente/31_native_regeln_und_spuren/bericht.md)

Für die unterstützten Projekte liefern `context` und `hole` auch Aufrufer, Beispielverträge und lokale Bindungen aus dem nativen Typprüfer. Die frühere ausführbare Vergleichsbasis ist im [Experimentarchiv](../experimente/referenzsystem/README.md) erhalten. [Bootstrap, Systemwerkzeuge und Prüfung ohne Python](bootstrap/README.md)

`catch` verarbeitet Fehler auch aus importierten Funktionen und Regeln. `fail` erzeugt einen fachlichen Grund, `input_line` liest die optionale Eingabezeile, `has_reason` prüft den Grund und `raise` erhält die Diagnose. Ein Fehler im Ersatz gelangt zum nächstäußeren passenden Handler. Arbeit und Gastallokationen werden im selben Budget weitergezählt. Grenzverletzungen und Fehler beim Binden der Aufrufargumente beenden den Lauf. [Regressionsfälle](bootstrap/fixtures/functions/handlers.tide) · [Regel mit Handler](bootstrap/fixtures/rules/handler.tide)

`run --read NAME=PFAD` prüft das Projekt und die Eingaben vor dem Öffnen der regulären Datei. `read` hält pro gebundenem Handle einen Snapshot. Die Snapshots teilen sich ein Limit von 128 KiB. Ein Lesefehler nach dem Öffnen und ungültiges UTF-8 sind im Programm abfangbar. [Lesebeispiele](bootstrap/fixtures/functions/read_grants.tide)

## Ein Programm übersetzen

`tide build --aot QUELLE AUSGABE [EINSTIEG]` übersetzt den geprüften Messbericht samt Aufrufen über Modulgrenzen. Der Linux-x86-64-Build benötigt einen C++20-Compiler mit statischen Systembibliotheken. Die Ausgabedatei ist statisch gelinkt und liest beim Start weder Projektquellen noch Werkzeugdateien. Sie verwendet `--read NAME=PFAD` und `--inputs JSON`. Ein neuer Quellstand wird durch einen neuen Build übernommen.

Der AOT-Pfad deckt derzeit die Typen und Operationen des Messberichts ab, darunter Textfaltungen, Ganzzahloperationen, optionale Ganzzahlen, Records mit Grundwertfeldern und benannte Leserechte. AOT übersetzt auch SQLite-Cursor, Schreibrechte, HTTPS-Aufrufe, PostgreSQL-Abfragen, bedingte Schleifen, `map`, begrenzte Selbstrekursion und mit `scan` aufgerufene Zustandsregeln. `build --service` erzeugt einen HTTP-Listener für einen typisierten Handler. Für Sprachkonstrukte ausserhalb der AOT-Abdeckung meldet der Compiler `E_BACKEND`. Der JSON-Importer kompiliert den Zieltyp und die Feldzugriffe beim Build. `run`, `test` und das erzeugte Programm verwenden dieselbe TIDE-Implementierung für die Dekodierung, Bytefolgen und Wörterbücher. [JSON-Messbericht](../apps/report_packages/json_report.tide)

Die Ausführung rechnet ausgeführte Knoten, Dateneingabe und Gastspeicher wie der Projektauswerter ab. Fehler verweisen auf die Quelldateien und Knoten des Builds. [Abnahme und Vergleich gegen CPython](../experimente/53_vorabuebersetzung/bericht.md)

`tide build` ohne `--aot` verwendet den direkten ELF-Exporter für den unten beschriebenen Ausschnitt.

```sh
set -euo pipefail
build=$(mktemp -d)
./tide check apps/heating.tide >/dev/null
./tide test apps/heating.tide
./tide build apps/heating.tide "$build/program"
readelf -lW "$build/program"
"$build/program"
```

Das fertige Programm hat einen ausführbaren, schreibgeschützten Ladebereich und einen als nicht ausführbar markierten Stack. Linux startet es direkt.

## Wechselnde Eingaben

Ein Programmeinstieg mit zwei Parametern `i`, `*i` und Ergebnis `i` erhält den Startwert als erstes Argument. Die weiteren Argumente bilden die Liste in Eingabereihenfolge. Beim Build kann man eine benannte Funktion als Einstieg auswählen.

```sh
./tide build apps/heating.tide "$build/heating" degree_hours
"$build/heating" 3 20 18 12 17     # 10
"$build/heating" -7                # -7
```

Zulässig sind null bis 4.096 Listenwerte. Jeder Wert ist eine ASCII-Dezimalzahl im i64-Bereich mit optionalem Minus. Führende Nullen sind erlaubt. Die Bindung prüft zuerst die Argumentzahl und danach jeden Wert von links nach rechts, bevor die Faltung beginnt. Bei `"$build/heating" 0 18 warm` bleibt die Standardausgabe leer. Auf stderr steht `{"code":"E_INPUT","reason":"expected_i64","argument":3}`, der Exitstatus ist 1. Die Nummer zählt den Startwert als Position eins. Ein fehlender Startwert ergibt `missing_seed`, mehr als 4.096 Listenwerte ergeben `list_too_long`. Die Betriebssystemgrenzen für die Argumentübergabe gelten bereits vor dem Programmstart. [Bindung im nativen Compiler](argv_i64.tide)

## Unterstützter Ausschnitt

### Zustandsregeln ausführen

Die bestehenden Anwendungen für Hitzealarm, Pumpe und Licht lassen sich direkt übersetzen. Der normale Build erzeugt eine Datei, die beim Start ihr `main` mit den eingebetteten Ereignissen ausführt. Für wechselnde Werte wählt der Build den Einstieg `simulate`. Jedes Positionsargument ist ein Ereignis, die Ausgabe ist eine JSON-Liste in Ereignisreihenfolge.

```sh
set -euo pipefail
build=$(mktemp -d)
./tide check apps/light.tide >/dev/null
./tide build apps/light.tide "$build/light" simulate
"$build/light" true false false true     # [true,true,false,true]
"$build/light"                          # []
```

Der gewählte Einstieg kann `scan` direkt aufrufen oder die Ereignisliste einmal an eine lokale Funktion mit `scan` weitergeben. Die Regel steht in derselben Quelldatei. Ereignisse, Zustandsfelder und Ausgabe können `i` oder `b` sein. Startwerte sind Literale. Für Bedingungen, `set` und `out` stehen dieselben skalaren Operatoren wie bei den Faltungen zur Verfügung. Bis zu 4.096 Ereignisse werden vor der Ausführung gebunden. Für `b` gelten die Schreibweisen `true` und `false`.

Der erste passende Zweig gewinnt. Alle Aktionen lesen die alten Feldwerte. Erst bei vollständig berechnetem Folgezustand liest `out` die neuen Werte. Bei mehreren fehlerhaften Aktionen zählt die Deklarationsreihenfolge der Felder. Ein Rechen- oder Budgetfehler liefert Status 1 und die Ereignisnummer ab eins auf stderr. Die Standardausgabe bleibt auch bei einem späten Regelfehler leer. [Übergangscompiler](rule_scan.tide) · [Native Ein- und Ausgabe](scan_image.tide) · [Differentialtests und Laufzeitvergleich](../experimente/24_native_regeln/bericht.md)

### Integer-Faltungen ausführen

Voraussetzung ist ein mit `tide check` geprüftes Programm. Für eingebettete Daten ruft ein parameterloses `main > i` die vorangehende Faltungsfunktion mit einem Startliteral und einer Liste von i64-Literalen auf. Ein parametrisierter Einstieg faltet selbst oder gibt seine beiden Parameter in derselben Reihenfolge an eine Faltungsfunktion in derselben Datei weiter. Die Faltung verwendet den Listenparameter und den Startwertparameter. Der Schritt kann Startwert, Akkumulator, Position ab eins, aktuelles Element sowie Integer- und Bool-Literale verwenden. Unterstützt sind `+`, `-`, `*`, `div`, `mod`, `<`, `>`, `<=`, `>=`, `eq`, `if`, `not`, `and` und `or` in verschachtelten Ausdrücken. Bei `if` läuft nur der gewählte Zweig. `and` und `or` werten den zweiten Operanden nur dann aus, wenn er das Ergebnis beeinflussen kann.

`div` rundet gegen null. Der Rest von `mod` hat bei einem von null verschiedenen Ergebnis das Vorzeichen des Dividenden. Ein Divisor von null ergibt bei beiden Operationen `E_DATA` mit dem Grund `division_by_zero`. Der kleinste i64 geteilt durch −1 ergibt `E_OVERFLOW`, sein Rest bei −1 ergibt null. Der Kartonsaldo verwendet beide Operationen, um Buchungen und Stornos jeweils pro Auftrag auf ganze Kartons zu runden. [TIDE-Anwendung](../apps/cartons.tide) · [Native Prüfungen und Laufzeiten](../experimente/23_native_division/bericht.md)

Die Ausdrücke können auf mehrere Zeilen verteilt und entsprechend der TIDE-Grammatik geklammert werden. Der native Tokenleser unterstützt bis zu 512 Codepunkte je Ausdruckszeile, Leerzeichen und Tabs sowie LF oder CRLF. Für die Ausführung gelten TIDEs Ressourcengrenzen. Bei eingebetteten Daten prüft der Compiler eine obere Schranke für die Auswertungsschritte. Bei einer zu hohen Schranke meldet er `native_work_bound`. Bei Positionsargumenten prüft er die Schranke für die maximal zulässige Listenlänge. Kann sie 100.000 übersteigen, zählt das Programm zur Laufzeit die tatsächlich besuchten Ausdrucksknoten. Der erste Schritt über der Grenze ergibt `E_LIMIT`. Nachgestellte Beispiele prüft `tide test`.

Die Quellübersetzung liest die Deklarationen und Literale. Das Ausdrucksmodul übersetzt Präfixausdrücke mit einem typisierten Stapel und erzeugt relativ adressierte Sprünge für Verzweigungen und Schleifen. Jede tatsächlich ausgeführte Addition, Subtraktion und Multiplikation prüft den vorzeichenbehafteten Überlauf. Bei einem Überlauf bleibt stdout leer, nach stderr geht der Code `E_OVERFLOW`, der Prozess endet mit Status 1. Der native Fehlerpfad enthält bisher keine Quellposition. Die bisherigen drei direkten Akkumulatoroperationen nutzen weiterhin ihre kompakte Kodierung. [Quellübersetzung](fold_i64.tide) · [Ausdrucksübersetzung](scalar.tide) · [ELF-Ausgabe](elf64.tide)

## Überprüfung

Beim Saldobeispiel stimmten Standardausgabe und Exitstatus mit der Referenz überein. Die native Datei war 411 Byte groß. Zehn weitere Ausführungen verglichen leere Liste, Subtraktion, negatives Produkt, Null, beide i64-Grenzen, Überlauf jeder der drei Operationen und einen frühen Überlauf vor einer kompensierenden Addition. Die Erfolgsfälle stimmten byteweise überein. Alle vier Überlauffälle ergaben `E_OVERFLOW`, leere Standardausgabe und Status 1.

Beim verzweigten Rechenkern wurden 29 Programme mit dem Referenzinterpreter verglichen. Für die Heizgradstunden gibt es getrennte Messungen von Build, Einzelaufruf und wiederholter Ausführung. [Laufzeitmessung und Einzelresultate](../experimente/20_native_ausdruecke/bericht.md)

Die Prüfung mit wechselnden Argumenten verwendet dieselbe native Datei für unterschiedlich lange Messreihen. Sie vergleicht die Eingabebindung, Fehlerpositionen und beide Seiten der Arbeitsbudgetgrenze mit der TIDE-Referenz. [Laufzeitargumente und Einzelresultate](../experimente/21_native_eingaben/bericht.md)
