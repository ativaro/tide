# Native TIDE-Verzweigungen bei Heizgradstunden

Der in TIDE geschriebene Compiler erzeugt für einen i64-Faltungsschritt jetzt auch verschachtelte Ausdrücke aus Arithmetik, Vergleichen und bedingter Auswertung. Beim Beispiel mit 16 stündlichen Messwerten lieferte die eigenständige Linux-Datei 39 Heizgradstunden. Natives TIDE war beim Einzelstart im Median der gepaarten Quotienten 48,1× schneller als CPython und bei wiederholter Berechnung 33,8×. Das angestrebte 100×-Verhältnis wurde bei dieser Aufgabe in keiner Messrunde erreicht. [TIDE-Programm](../../apps/heating.tide) · [Vorab festgelegtes Messverfahren](versuchsplan.md)

| Messgröße | Natives TIDE | CPython 3.14.10 | Gepaarter Faktor |
|---|---:|---:|---:|
| Start bis Ausgabe und Prozessende | 0,130 ms | 6,108 ms | 48,1× |
| Zeit pro vollständiger Auswertung im wiederholten Lauf | 13,44 ns | 451,41 ns | 33,8× |
| Nativer Build aus der Quelle, Median aus zehn Durchläufen | 84,86 ms | – | – |

Die Einzelmessung lief in 30 Paaren nach sechs Aufwärmpaaren auf demselben logischen Kern eines AMD Ryzen 9 9950X3D. Beide Programme verwendeten feste Eingabedaten, prüften die i64-Arithmetik und gaben `39` aus. Die Zeitspalten sind die jeweiligen Mediane. Der Faktor ist der Median der Quotienten innerhalb der einzelnen Runden. Der Einzelstart enthält die unterschiedlichen Startkosten der Programme.

Für den warmen Durchsatz wurden 32.768 und 131.072 vollständige Auswertungen pro Prozess verglichen. Jede Runde enthielt vier Prozessmessungen. Über 24 Runden kam jede Reihenfolge einmal vor. Die Laufzeitdifferenz pro Sprache wurde durch die 98.304 zusätzlichen Auswertungen geteilt. Jede Differenz war positiv. Die gepaarten Faktoren lagen zwischen 23,0× und 40,5×. Der Durchsatz gilt für die wiederholte Auswertung derselben Messreihe. Andere Datenverteilungen können die Kosten der Sprünge verändern.

Die normale ELF-Datei ist 621 Byte groß. Ihr 184 Byte langer Rechenkern einschließlich Überlaufpfad sowie die 128 Byte Eingabedaten stimmten byteweise mit denen beider Stapeldateien überein. Bei jeder Wiederholung werden Startwert, Zeiger und Zähler neu gesetzt. Die Python-Fassung ruft dieselbe Funktion pro Auswertung mit denselben Eingaben auf. Für die fünf fachlichen TIDE-Beispiele wurden auch CPython und die jeweils neu erzeugte native Datei gegengeprüft. Die native Buildzeit enthält die Prüfung der Quelle, den Compilerlauf im Referenzinterpreter, die Byteübertragung und das Setzen des Ausführungsbits. [Rohzeiten, Maschinenzustand, Quellen des Vergleichs und Binärhashes](messung.json)

## Semantik und Kompatibilität

29 weitere, von einem TIDE-Programm bereitgestellte Programme wurden jeweils mit `tide check` geprüft, nativ übersetzt und gegen ihren Sollwert sowie `tide run` ausgeführt. 24 lieferten denselben Integer einschließlich Zeilenumbruch. Fünf brachen mit `E_OVERFLOW`, leerer Standardausgabe und Status 1 ab. Die Beispiele unterscheiden zwischen übersprungenen und tatsächlich ausgeführten Fehlerzweigen. Sie prüfen auch den unveränderten Startwert neben dem laufenden Akkumulator, die Positionsvariable ab eins, beide i64-Grenzen sowie Verzweigungen über mehr als 127 Byte. Der Referenzinterpreter liefert im Fehlerfall zusätzliche Diagnosedetails. [TIDE-Prüffälle](faelle.tide) · [Übersetzungsbeispiele und Ablehnungen](../../native/scalar.tide)

Für das bestehende Saldoprogramm blieb die erzeugte Datei bytegleich. Der historische Messpatch erzeugte für beide Wiederholungszahlen wieder die archivierten Binärhashes. Der native Compiler deckt bisher geschlossene Programme mit einer Integer-Faltung über eingebettete Literale ab. Records, Datei- und Terminaleingaben sowie Modellkosten beim Entwickeln dieser Programme wurden hier nicht qualifiziert. [Nativer Aufruf und unterstützte Ausdrücke](../../native/README.md) · [Frühere Saldomessung](../11_saldo/bericht.md)

## Nachrechnen

Die JSON-Datei enthält die verwendeten Messbefehle, den Python-Vergleich und alle Einzelzeiten. Im Projektverzeichnis lässt sich die Laufzeitmessung mit Bash, jq und Python auf einer Maschine mit verfügbarer logischer CPU 2 wiederholen.

```sh
set -euo pipefail
work=$(mktemp -d)
data=experimente/20_native_ausdruecke/messung.json
jq -r .method.cpython "$data" > "$work/comparator.py"
jq -r .method.performance "$data" > "$work/measure"
python3 "$work/measure" "$work"
jq -r .method.differential_checks "$data" > "$work/compare-cases"
bash "$work/compare-cases"
```

Für die Bedeutung der x86-64-Vergleichs-, Sprung- und Überlaufoperationen dient die Instruktionsreferenz des Prozessorherstellers als Nachschlagewerk. Die tatsächlich ausgeführten Bytes wurden zusätzlich lokal mit dem Disassembler und anhand der Ergebnisse geprüft. [Intel Software Developer’s Manual, Band 2](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
