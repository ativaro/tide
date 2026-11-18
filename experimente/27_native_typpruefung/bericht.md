# Typdateien ohne Python prüfen

Der installierte TIDE-Befehl prüfte eine kleine gültige Typdatei im Median in 7,4 ms, der Referenzstarter in 31,3 ms. Bei allen 170 Quelldateien stimmten die Ergebnisse von `check` überein. Der Vergleich umfasst die vollständigen JSON-Felder, die Quellposition beim Fehler, die Revision beim Erfolg, den Exitstatus und den jeweils leeren zweiten Ausgabekanal. [Messwerte je Aufruf](messung.json) · [Prüfprotokoll](pruefung.json)

| `tide check`, 20 Messpaare je Datei | Referenz | Öffentlicher TIDE-Befehl | Faktor je Paar, Median |
|---|---:|---:|---:|
| Drei Typdeklarationen mit Vorwärtsverweisen | 31,3 ms | 7,4 ms | 4,21× |
| Unbekannter Feldtyp | 31,2 ms | 6,2 ms | 4,94× |
| 100 Records mit gemeinsamer Variante | 31,6 ms | 10,7 ms | 2,93× |
| Eine Variante mit 120 Tags | 30,5 ms | 13,2 ms | 2,32× |
| Saldoprogramm mit Faltung und Beispielen, Kompatibilitätsinstallation | 31,6 ms | 35,6 ms | 0,87× |

Der direkte Referenzstarter und die fertig installierte CLI bearbeiteten denselben absoluten Dateipfad mit derselben Projektbindung. Nach drei Aufwärmpaaren wechselte die Startreihenfolge. In den ersten vier Gruppen war der native Aufruf in allen 80 Paaren schneller. Beim Saldoprogramm kamen durch den Versuch der nativen Prüfung und den anschließenden Start der Referenz im Median der beiden Laufzeitreihen rund 4 ms hinzu. Im Standardpaket meldet dieser Aufruf `E_BACKEND`. Die Modellzeit und der Tokenverbrauch wurden hier nicht erhoben. [Versuchsplan](versuchsplan.md)

Der erste native Entwurf durchlief für jede Record-Wurzel erneut ein Arbeitsbudget. Die jetzige Traversierung teilt die bekannten Typentiefen über alle Wurzeln und besucht die Kanten mit einem gemeinsamen Cursor. Der Startcompiler übergibt unveränderliche zusammengesetzte Parameter per Referenz. In einem zusätzlichen Vergleich am 100-Record-Fall sank die ganze CLI-Zeit von 231,1 auf 10,3 ms. Dieser Vorher-nachher-Vergleich umfasst beide Änderungen und die zwischenzeitlichen Änderungen am Starter.

## Abnahme

Der in TIDE geschriebene Generator lieferte 167 Quellen. Hinzu kamen die Typdeklarationen aus Nano, Space Invaders und dessen Spielmodul. Es gab 96 gültige Quellen und 74 Ablehnungen, davon 39 Typfehler, 29 Namensfehler und sechs Syntaxfehler. Der Test erfasste unter anderem Zyklen, geteilte Teilgraphen, Tiefe 16 und 17, Unicode-Leerraum und Fehlerpositionen nach Zeilenwechseln. Die Feldtypen dürfen Paare, Listen, Optionen, Records und Varianten kombinieren. Leserechte sind als Datenfelder unzulässig. [Generator](../../native/bootstrap/schema_cases.tide) · [Prüfer](../../native/bootstrap/schema.tide)

Auf denselben 170 Quellen wurden `fmt` und `test` separat mit der Referenz verglichen. In allen 96 Erfolgsfällen war der formatierte Text bytegleich und eine zweite Formatierung ebenfalls identisch. Eine gültige Datei mit ausschließlich Typdeklarationen meldete null Beispiele. Jede der 74 ungültigen Dateien lieferte bei beiden Befehlen die erwartete Diagnose. Die 510 Vergleiche betreffen drei Befehle auf demselben Korpus.

Der Neuaufbau in einem frischen Linux-Mount-Namensraum verwendete ausschließlich die benötigten Systemprogramme. Python, Projektmodule und Referenzstarter waren für den Build und die nativen Testprozesse unerreichbar. Der Prüfer bestand zusätzlich Fälle mit abweichender Versionsbindung, ungültigem UTF-8, einer 131.073 Byte großen Datei, einem FIFO und ungewöhnlichen Dateinamen. Die zwölf Anwendungs-ELFs stimmten mit den früheren Prüfsummen überein. Eine frische Standardinstallation enthielt keine Python-Datei und keinen Referenzstarter. Beim Wechsel von der Kompatibilitätsinstallation zur Standardinstallation endete die Weiterleitung an eine noch vorhandene Referenzdatei.

Die TIDE-Anwendungsprüfungen laufen mit `make test`. Nano verarbeitet Cursorbewegung über CRLF, Unicode-Eingabe, Speichern und die Rückmeldung des Speicherns. Der Spieltest prüft Start, Schiffsbewegung, Schuss, Pausenanzeige und Fortsetzung. Beide führen die regulären TIDE-Funktionen aus. Die Eingabeereignisse liefert der Test. Der Selbstbau vergleicht zwei aufeinanderfolgende Compilergenerationen byteweise. In der Umgebung mit Referenzsystem bestanden zusätzlich alle 35 historischen Integrationstests. [Nano-Prüfung](../../apps/nano_checks.tide) · [Space-Invaders-Prüfung](../../apps/invaders_checks.tide)

## Nachvollziehen

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
printf 'record Sensor\nphase:{Phase}\n\nvariant Phase\nstop start\n' > "$stage/gut.tide"
"$tool" check "$stage/gut.tide" --json
"$tool" fmt "$stage/gut.tide"
"$tool" test "$stage/gut.tide"
printf 'record Knoten\nkind:?{Knoten}\n' > "$stage/zyklus.tide"
"$tool" check "$stage/zyklus.tide" --json
```

Der letzte Aufruf liefert `E_TYPE` an Zeile 1, Spalte 1 und Exitstatus 1. Für einen eigenen Differentiallauf lässt sich der Korpus direkt mit dem Startcompiler erzeugen.

```sh
{ cat native/bootstrap/syntax.tide; echo; cat native/bootstrap/schema.tide; echo; cat native/bootstrap/schema_cases.tide; } > "$stage/korpus.tide"
build/native/seed generate_cases < "$stage/korpus.tide" > "$stage/korpus.cpp"
c++ -std=c++20 -O1 "$stage/korpus.cpp" -o "$stage/korpus"
"$stage/korpus" > "$stage/faelle.jsonl"
```

Der vollständige Modulprüfer, die allgemeine Ausführung und Beispielsuite, die revisionsgebundenen Bearbeitungswerkzeuge und die interaktiven Terminal- und Dokumentdienste verwenden weiterhin Python. Umfangreichere Typdateien können ebenfalls die internen Grenzen des nativen Werkzeugs erreichen. Im Checkout und nach `make install-compat` steht für diese Aufrufe die Referenz zur Verfügung. Ein frisches Standardpaket führt ausschließlich die portierten Aufrufe aus.
