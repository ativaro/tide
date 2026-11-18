# Vorzeichenbehaftete Division und Rest in nativen TIDE-Programmen

Der native Compiler übersetzt `div` und `mod` für i64-Operanden. Damit lässt sich ein Kartonsaldo direkt als TIDE-Programm ausführen. Jede Buchung von bis zu sechs Stück je Karton zählt ihre angebrochenen Kartons in Bewegungsrichtung. Zwei einzelne Lieferungen zu je einem Stück benötigen zwei Kartons. Ein entsprechendes Storno zählt negativ. Für die Berechnung braucht die TIDE-Anwendung weder eine Gleitkommazahl noch den Betrag des kleinsten i64. [Anwendung und Beispiele](../../apps/cartons.tide) · [Versuchsplan](versuchsplan.md)

| Buchungen pro Aufruf | Native Datei, Median | CPython 3.14.10, Median | Gepaarter Faktor, Median |
|---:|---:|---:|---:|
| 0 | 0,135 ms | 4,142 ms | 30,6× |
| 16 | 0,135 ms | 4,164 ms | 30,9× |
| 4.096 | 0,373 ms | 6,723 ms | 18,0× |

Je Größe liefen sechs Aufwärmpaare und 30 Messpaare mit wechselnder Reihenfolge auf derselben logischen CPU. Die Zeit enthält Prozessstart, Übergabe und Prüfung der Dezimalargumente, Rundung, geprüfte Saldoaddition, Ausgabe und Prozessende. Der TIDE-Interpreter bestimmte das Ergebnis außerhalb der Messung. Die CPython-Fassung verwendet die ganzzahlige Aufrundung von `abs(count)` und setzt das Vorzeichen anschließend wieder ein. Beide Sprachen prüfen den laufenden Saldo nach jeder Buchung. Der native Build dauerte im Median 83,88 ms, die Datei mit dynamischen Eingaben ist 1.264 Byte groß. Die Differenzen zu anderen Anwendungen und Messsitzungen lassen keine Aussage über die Kosten einer einzelnen Division zu. [Einzelzeiten, Vergleichsprogramm, Build und Umgebung](messung.json)

## Rechenregeln und Fehlerreihenfolge

Der Codegenerator wertet beide Operanden von links nach rechts aus. Für den normalen Fall verwendet er die vorzeichenbehaftete x86-64-Division. Bei null als Divisor meldet er `E_DATA` mit dem Grund `division_by_zero`. Für den Divisor −1 erzeugt er eine geprüfte Negation für den Quotienten und null für den Rest. Das erhält auch für den kleinsten i64 die TIDE-Regeln. [Codegenerator](../../native/scalar.tide) · [AMD64 Architecture Programmer’s Manual, General-Purpose Programming](https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24592.pdf)

Für jede Operation wurden alle 169 Kombinationen aus 13 Grenz- und Vorzeichenwerten sowie 128 zusätzliche deterministische Paare geprüft. In allen **594 Einzelvergleichen** stimmten die native Datei, die TIDE-Referenz und eine separat mit unbeschränkter Ganzzahlarithmetik berechnete Erwartung überein. Weitere 16 Programme prüften unter anderem verschachtelte Operanden, übersprungene Fehlerzweige, die laufende Position und konkurrierende Fehler in linkem und rechtem Operanden. Alle 16 liefen sowohl mit eingebetteten als auch mit dynamischen Werten. Ein Fehler musste mit Status 1, leerem stdout und der passenden strukturierten Diagnose enden. Alle sechs Anwendungsbeispiele bestanden auch in der CPython-Vergleichsfassung. Die frühere Verifikation aus Versuch 21 wurde mit dem erweiterten Compiler wiederholt. Ihre Ergebnisse und Binärhashes blieben gleich. [Verschachtelte Fälle](faelle.tide) · [Frühere Eingabeprüfung](../21_native_eingaben/bericht.md)

## Ein durch den Grenztest gefundener Compilerfehler

Für den zusätzlichen Budgettest liegt die letzte Division genau auf dem 100.000. Schritt oder unmittelbar darüber. Schon bei der Übersetzung brachen Quotient und Rest zunächst mit `E_LIMIT` ab. Die erste Compilerfassung fügte ein Fragment in den internen Stapel ein und fügte es nach dem Ergänzen des Schrittzählers erneut in eine Kopie desselben Ausgangsstapels ein. Beide Operationen belasteten das logische Allokationsbudget des in TIDE ausgeführten Compilers.

Der Compiler erstellt jetzt erst das fertige Fragment und erweitert den Stapel einmal. Mit demselben Limit von 4.194.304 logischen Bytes benötigt die Übersetzung des Quotiententests 3.480.748 und die des Resttests 3.456.424 Bytes. Das sind kumulierte Belastungen nach TIDE-Semantik, keine Messungen des Prozessspeichers. Die zuvor übersetzbaren Vergleichsdateien dieses Versuchs blieben bytegleich.

Alle acht Kombinationen aus Operator, Fehleroperand und Budgetgrenze liefen anschließend nativ. Bei genau 100.000 Schritten war der letzte Ausdruck maßgeblich, einschließlich des gültigen Rests null. Beim 100.001. Schritt meldeten beide Programme wie die Referenz zuerst `E_LIMIT`. [TIDE-Grenzfall](budget.tide) · [Compilerstände, Budgetzähler und Einzelergebnisse](messung.json)

## Nachrechnen

Im Projektverzeichnis unter Linux x86-64:

```sh
set -euo pipefail
build=$(mktemp -d)
data=experimente/23_native_division/messung.json
jq -jr .method.cpython "$data" > "$build/comparator.py"
jq -jr .method.cross_check "$data" > "$build/checks"
jq -jr .method.measure "$data" > "$build/measure"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
```

Für den zusätzlichen Vergleich des Compilerbudgets braucht die Messung den damaligen Modulstand. Die gespeicherten Quellen entsprechen den Compilerhashes der Messung. Der Patch rekonstruiert daraus die Fassung mit dem doppelten Stapelaufbau. [Compilerstand](compilerstand.json)

```sh
mkdir -p "$build/revision/native"
for file in elf64.tide scalar.tide argv_i64.tide fold_i64.tide; do
  jq -ejr --arg file "$file" '.[$file]' experimente/23_native_division/compilerstand.json > "$build/revision/native/$file"
done
for dir in apps experimente tide_lang; do ln -s "$PWD/$dir" "$build/revision/$dir"; done
jq -jr .previous_compiler.after_to_before_patch "$data" |
  patch -s -o "$build/scalar-before.tide" "$build/revision/native/scalar.tide"
jq -jr .method.allocation "$data" > "$build/allocation"
(cd "$build/revision" && python3 "$build/allocation" "$build")
```
