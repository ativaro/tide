# Saldoprogramm: TIDE gegen CPython

Gemessen am 16. November 2026 auf einem AMD Ryzen 9 9950X3D unter Linux x86-64. Der Auftrag war in beiden Sprachen derselbe. Ausgehend von 100 werden die Buchungen −20, +15, −8 und +10 in Reihenfolge angewandt. Das Ergebnis ist 97. Jeder einzelne Schritt muss in einen vorzeichenbehafteten 64-Bit-Integer passen. Ein vorübergehender Überlauf ist auch dann ein Fehler, wenn ihn eine spätere Buchung ausgleichen würde.

## Laufzeit

| Messung | Natives TIDE | CPython 3.14.10 | Faktor zugunsten von TIDE |
|---|---:|---:|---:|
| Programm starten, viermal buchen, `97` ausgeben, Prozess beenden | 0,166 ms | 6,737 ms | 39,2× |
| Zeit je Saldo im wiederholten Lauf, vier Buchungen | 0,837 ns | 146,94 ns | 174,3× |

Die Zeitspalten sind Mediane. Für den Faktor wurde innerhalb jeder Runde Python durch TIDE geteilt und anschließend der Median der Quotienten gebildet. Die mittleren 50 % der Faktoren lagen beim Einzelaufruf zwischen 36,3× und 41,2× und beim wiederholten Rechnen zwischen 151,7× und 210,2×. Der TIDE-Referenzinterpreter brauchte für den vollständigen Einzelaufruf im Median 32,858 ms. Das einmalige Erzeugen der nativen Datei aus dem Quelltext dauerte 37,249 ms. [Rohzeiten](laufzeit.csv)

**Einzelaufruf.** 51 Runden nach fünf Aufwärmrunden. Jede Runde enthielt das unveränderte native Saldoprogramm, das CPython-Skript und `./tide run apps/balance.tide`. Die sechs möglichen Aufrufreihenfolgen wechselten. Die Bash-Zeitmessung umfasste den Prozessstart und die Ausgabe nach `/dev/null`. Gemessen wurde mit warmem Dateicache auf der logischen CPU 2. Die Python-Funktion aus dem Schreibversuch lief unter dem normalen CPython-Start ohne Zusatzpakete. Der kleine Programmeinstieg übergab dieselben Literale und bildete `OverflowError` auf dieselbe CLI-Fehlermeldung ab. An allen zehn Abnahmefällen wurden für beide ausführbaren Programme stdout, stderr und Exitstatus verglichen. [Abnahmefälle](faelle.txt) · [Python-Funktion](schreiben/balance.py)

**Wiederholter Lauf.** Der native Compiler ist ein Prototyp für eine Faltung über eingebettete i64-Daten. Für den Durchsatz ergänzte ich in einer temporären Kopie des TIDE-Emitters eine gezählte äußere Schleife. Jede Iteration setzt Startsaldo, Zeiger und Buchungszähler zurück. Die ursprüngliche Rechenschleife samt Überlaufprüfung läuft vollständig. CPython ruft pro Iteration die geprüfte Funktion mit derselben wiederverwendeten Liste auf. Beide Prozesse geben erst den letzten Saldo aus. Pro Runde und Sprache wurden 1.048.576 und 2.097.152 vollständige Salden berechnet. Die Zeit je zusätzlichem Saldo ist die Differenz der beiden Prozesszeiten geteilt durch 1.048.576. 31 Runden nach zwei Aufwärmrunden, Größen- und Sprachreihenfolge gewechselt. Das misst den Durchsatz einer heißen Schleife einschließlich der Wiederholungskosten. Für einen einzelnen Saldo mit neuen Eingaben ist die Nanosekundenzahl keine Latenzmessung. [TIDE-Messpatch](stapel.patch)

Das unveränderte ELF-Programm ist 411 Byte groß und hat SHA-256 `cdc5a3f33cc9bd46a07d760bc81a42818f209fb5df29f7f801289cb0225e4ef2`. Die TIDE-Funktion aus dem isolierten Schreibversuch mit dem Programmeinstieg des Repositorys ergab bytegleich dasselbe ELF. In einem technischen Vorlauf fehlte dem Python-CLI-Einstieg die Übersetzung einer Ausnahme in die vereinbarte JSON-Fehlermeldung. Nach Ergänzung dieses Fehlerpfads wurde die ganze Zeitserie erneut gemessen. Im Vorlauf lagen die gepaarten Medianfaktoren bei 40,4× bzw. 168,1×. [Vorlauf](vorlauf.csv)

## Schreiben und Reparieren

| Auftrag | Quelltext-Tokens der abgegebenen Funktion | CLI-Eingabe, davon aus Cache | CLI-Ausgabe | Gesamt | Start bis bestandener Test |
|---|---:|---:|---:|---:|---:|
| TIDE schreiben | 20 | 78.259, davon 70.272 | 403 | 78.662 | 13,225 s |
| Python schreiben | 72 | 58.124, davon 50.304 | 217 | 58.341 | 7,376 s |
| Python reparieren | 50 | 77.732, davon 69.632 | 146 | 77.878 | 7,294 s |
| TIDE reparieren | 19 | 77.796, davon 69.760 | 159 | 77.955 | 9,278 s |

Die Gesamtzahl ist die vom Codex-CLI gemeldete Eingabe plus Ausgabe des ganzen Turns. Sie umfasst wiederholt übergebenen Kontext, Werkzeugergebnisse und die Abschlussmeldung nach dem Test. Cache-Tokens sind bereits in der Eingabe enthalten, ausgewiesene Denktokens in der Ausgabe. Zieht man Cache-Treffer ab, bleiben beim Schreiben 8.390 Tokens für TIDE und 8.037 für Python. Die separat gezählten Quelltext-Tokens verwenden `o200k_base` und umfassen ausschließlich die eingereichte Funktion. TIDE prüft die Addition bereits als Sprachoperation auf Überlauf. Die abgegebene Python-Funktion prüft den Wertebereich explizit. [Vollständige Aufträge, Toolereignisse, Zeitstempel und Nutzungszähler](modell.json)

Vier frische, nacheinander gestartete `codex exec`-Sitzungen verwendeten `gpt-6-astra`, Reasoning-Stufe `xhigh` und angeforderte Serviceklasse `priority` im CLI 0.157.1. Jede Sitzung sah nur ihren Auftrag und ihren Arbeitsordner. Hooks, Erinnerungen und Plugins waren ausgeschaltet. Die Reihenfolge war TIDE schreiben, Python schreiben, Python reparieren, TIDE reparieren. Beim Schreiben bekam das Modell eine leere Datei, denselben fachlichen Auftrag und einen kurzen sprachspezifischen Hinweis. Beim Reparieren enthielt jede Ausgangsdatei genau dieselbe Vorzeichenverwechslung. In der TIDE-Fassung stand `- total entry`, in der Python-Fassung `total -= entry`. Beide Aufträge nannten das Symptom „103 anstelle von 97“. Der Ort und die Ursache standen nicht im Auftrag.

Jede Sitzung las die Datei, änderte sie einmal und rief den unabhängigen Prüfer einmal erfolgreich auf. Die zehn festgelegten Fälle umfassten den sichtbaren Beispielsaldo, leere Liste, Null, gemischte Buchungen, beide gültigen i64-Grenzen sowie positiven, negativen und vorübergehenden Überlauf. TIDE führte die Fälle als Sprachbeispiele aus. Der Python-Prüfer verwendete dieselben JSON-Daten und behandelte ausschließlich `OverflowError` als Überlauf. Die Uhr lief vom Start des jeweiligen Codex-Prozesses bis zum ersten Erfolg des Prüfers. Damit umfasst sie auch Modellantwortzeit und Werkzeuglatenz. Suche und Bearbeitung wurden gemeinsam gemessen. Der erste innere Zeitpunkt, zu dem das Modell die Ursache erkannte, ist nicht beobachtbar. [Repariertes TIDE](reparatur/balance.tide) · [Repariertes Python](reparatur/balance.py)

Für die vier konstanten Buchungen überschritt der native Durchsatz das 100×-Ziel. Beim Programmstart, beim Modellverbrauch und bei der Reparaturzeit wurde es in diesem Versuch verfehlt. Ein Modelllauf pro Bedingung und ein einziger leicht lokalisierbarer Defekt reichen nicht aus, um einen sprachbedingten Vor- oder Nachteil bei der Fehlersuche zu schätzen.

## Nachmessen

Für den Einzelstart gelten die [nativen Buildbefehle](../../native/README.md). CPython ruft in einer Kopie der eingereichten Funktion `print(balance(100, [-20, 15, -8, 10]))` auf. Ihr CLI-Einstieg fängt `OverflowError` ab, schreibt `{"code":"E_OVERFLOW"}` mit Zeilenumbruch nach stderr und endet mit Status 1. Die Stapelfassung bindet dieselbe Liste einmal, ruft `result = balance(100, entries)` in einer Schleife `for _ in range(N)` auf und gibt danach `result` aus.

Für den nativen Stapel die TIDE-Compilerdateien aus `native/` in ein temporäres Verzeichnis kopieren und dort `patch -p1 < …/stapel.patch` ausführen. Die erste Fassung über das bestehende Saldoprogramm kompilieren. Für die zweite die Konstante `batch_repetitions` auf 2.097.152 setzen und erneut kompilieren. Beide Fassungen liefern `97`. Die SHA-256-Werte der gemessenen Binärdateien sind `caa8bf028621f185df716fdf66e3083f64e6e18dd232eafa6adf948adaf7047e` und `22a04c2ba53461d7628332419cf4e7878b24d4219178a70f54fe40bb5633ef1a`.

Die Mess-Shell lief unter `taskset -c 2` mit Bash 5.3, `TIMEFORMAT='%6R'`, `LC_ALL=C` und stdin/stdout der zeitgemessenen Programme auf `/dev/null`. Die Ausgaben wurden außerhalb der Zeitmessung verglichen. Die CSV-Dateien enthalten Sekunden. Negative Rundennummern markieren Aufwärmläufe, Rundennummern ab null die ausgewerteten Läufe.
