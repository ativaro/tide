# Native Zustandsregeln für Hitze, Pumpe und Licht

Der TIDE-Compiler übersetzt die drei bestehenden Anwendungen in eigenständige Linux-x86-64-Programme. Beim Build führt der bisherige Referenzinterpreter den in TIDE geschriebenen Compiler aus. Die erzeugte Datei verarbeitet boolesche Ereignisse oder vorzeichenbehaftete 64-Bit-Ganzzahlen und schreibt ihre Ergebnisse als JSON-Liste. Der unterstützte Ausschnitt umfasst skalare Zustandsfelder und Ausdrücke, `keep`, `set` und `reset`. Zusammengesetzte Ereignisse, Funktionsaufrufe innerhalb der Regel und Zustandsspuren sind offen. [Build und Aufruf](../../native/README.md)

Je Anwendung stimmten 128 verschiedene deterministische Ereignisfolgen vollständig mit der TIDE-Referenz überein. Dazu kamen die acht ursprünglichen Beispiele, 30 Fälle für Eingabebindung, Übergänge, Ausgabe und Fehler sowie 15 Fälle beiderseits der Grenze von 100.000 Arbeitsschritten. Die Grenzprüfung verglich auch die Ereignisnummer und die Priorität konkurrierender Fehler. Ein Rechenfehler beim 4.096. Ereignis ließ die Standardausgabe leer. Die bisherigen nativen Integerprogramme behielten ihre geprüften Binärhashes.

| Regel | Ereignisse | TIDE, Median | CPython, Median | Median der paarweisen Faktoren |
|---|---:|---:|---:|---:|
| Pumpe | 16 | 0,140 ms | 4,244 ms | 30,10× |
| Pumpe | 4.096 | 0,385 ms | 6,684 ms | 17,34× |
| Licht | 16 | 0,141 ms | 4,233 ms | 30,00× |
| Licht | 4.096 | 0,363 ms | 6,203 ms | 17,12× |

Jede Zelle umfasst 30 Paare nach sechs Aufwärmpaaren. Jeder Aufruf startet einen Prozess einschließlich Eingabebindung und Ausgabe. Rechner war ein Ryzen 9 9950X3D, gebunden an CPU 2, mit CPython 3.14.10. Der Median für den vollständigen Build betrug 89,31 ms bei der Pumpe und 92,38 ms beim Licht.

Eine statische obere Schranke erlaubt dem Compiler bei kurzen Regeln, den Laufzeitzähler wegzulassen. Die Dateigrößen sanken bei Pumpe von 1.552 auf 1.290 Byte, bei Licht von 1.663 auf 1.377 Byte und bei Hitze von 1.641 auf 1.347 Byte. Im direkten Vergleich war die kleinere Fassung für Pumpe und Licht jeweils in 20 von 40 Paaren schneller. Die mediane Zeitersparnis betrug −5,76 µs und +7,39 µs. Daraus ergibt sich kein reproduzierbarer Zeitgewinn. Modellkosten waren hier kein Messgegenstand. [Vorab festgelegter Ablauf](versuchsplan.md) · [Quellen, Messbefehle, Rohzeiten und Prüfergebnisse](messung.json)

## Reproduktion

Aus dem Projektverzeichnis mit Bash, jq, xxd und patch ausführen. Die Timing-Skripte setzen die im Datensatz dokumentierte Linux-Umgebung voraus.

```bash
set -euo pipefail
data=experimente/24_native_regeln/messung.json
build=$(mktemp -d)
for part in checks measure compare; do
  jq -ejr --arg k "$part" '.method[$k]' "$data" > "$build/$part"
done
jq -ejr .method.comparator "$data" > "$build/comparator.py"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
mkdir "$build/metered"
while read -r file; do
  jq -ejr --arg f "$file" '.sources[$f]' "$data" > "$build/metered/$file"
done < <(jq -r '.sources|keys[]' "$data")
for file in rule_scan.tide scan_image.tide; do
  jq -ejr --arg f "$file" '.counted_patches[$f]' "$data" | patch -s "$build/metered/$file"
done
for app in pump light; do
  ./tide run "$build/metered/fold_i64.tide" --call compile_entry --read "source=apps/$app.tide" --inputs '{"entry":"simulate"}' |
    jq -ejr . | xxd -r -p > "$build/metered/$app"
  chmod u+x "$build/metered/$app"
done
python3 "$build/compare" "$build"
```
