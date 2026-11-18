# Reparatursuche über drei Dateien

**Beide Werkzeuge lösen mit den neuen Suchregeln neun von zehn Aufgaben am Programmeinstieg. Mit der bisherigen Suche war es auf denselben Aufgaben jeweils eine.** TIDE erreicht bei den erfolgreichen Reparaturen die unabhängige Abnahme in 16,6 ms, Python-AST in 32,0 ms (Median). In drei Fällen tauschen beide Werkzeuge die Argumente im Aufrufer. Bei zusätzlicher direkter Prüfung des Zwischenmoduls bestehen deshalb sechs von zehn Aufgaben. [Auswertung](auswertung.json) · [Direkte Modulabnahme](modulabnahme.json)

| Messgrösse | TIDE bisher | Python-AST bisher | TIDE erweitert | Python-AST erweitert |
|---|---:|---:|---:|---:|
| Bestandene Aufgaben am Einstieg | 1/10 | 1/10 | 9/10 | 9/10 |
| Protokolltokens für alle zehn Versuche | 2.909 | 3.172 | 3.474 | 3.769 |
| Davon auf bestandene Aufgaben entfallen | 340 | 382 | 3.189 | 3.459 |
| Alle Protokolltokens geteilt durch bestandene Aufgaben | 2.909 | 3.172 | 386 | 418,8 |
| Median bis zur erfolgreichen Abnahme | 15,9 ms | 31,7 ms | 16,6 ms | 32,0 ms |
| 95. Perzentil bis zur erfolgreichen Abnahme | 17,1 ms | 33,1 ms | 22,4 ms | 35,0 ms |
| Median bis zur Meldung ohne Kandidat | 6,5 ms | 18,0 ms | 6,5 ms | 18,5 ms |

TIDE war in allen 108 erfolgreichen Messpaaren der erweiterten Suche schneller. Das mediane Verhältnis Python-Zeit/TIDE-Zeit betrug **1,94**, die mittleren 50 % lagen zwischen **1,73 und 1,99**. Bei der einzigen bereits vorher lösbaren Aufgabe `thermal` änderte sich die TIDE-Zeit von 15,90 auf 16,03 ms, die CPython-Zeit von 31,70 auf 31,70 ms. Der Vergleich der beiden Erfolgsmediane vor und nach der Erweiterung umfasst unterschiedlich viele Aufgaben. [Einzelzeiten mit Blockreihenfolge](messung.json)

Über alle Versuche benötigte das erweiterte TIDE-Protokoll **295 Tokens weniger (7,8 %)**. Davon entfallen 257 Tokens auf die erste Nachricht mit Auftrag, drei Quelldateien und öffentlichen Beispielen. Die Eingabe- und Ausgabesummen betragen 3.167 und 307 bei TIDE sowie 3.450 und 319 bei Python. Jedes deterministische Protokoll zählt pro Aufgabe und Verfahren einmal. Die Zeitwiederholungen erzeugten identische Nachrichten. Der lokale Llama-BPE-Tokenizer zählte die kompakten JSON-Nachrichten ohne Spezialtokens. Es gab null Modellaufrufe. Tatsächliche Tokens und Denkzeit eines programmierenden Modells lassen sich daraus nicht bestimmen. [Protokolle](protokolle.json) · [Offline-Auswertung](auswerten.mjs)

## Aufgaben und ausgewählte Reparaturen

Jede Aufgabe besteht aus dem Einstieg `panel`, dem Zwischenmodul `route` und der Bibliothek `rulebook`. Die Tabelle zeigt die erweiterte Suche. An jeder Zeile haben beide Werkzeuge dieselbe Zahl von Einzeländerungen und Paaren geprüft und fachlich dieselben grünen Optionen angeboten. Die Zeiten sind Mediane pro Aufgabe in Millisekunden. Bei `flag` endet die Uhr mit der Meldung, dass kein Kandidat bestanden hat.

| Aufgabe | Ausgewählte Änderung | Geprüft einzeln / paarweise | Grüne Optionen | Tokens TIDE / Python | Zeit TIDE / Python |
|---|---|---:|---:|---:|---:|
| `cut` · Abtastpunkte | Anfang und Ende im Aufrufer tauschen | 12 / 0 | 2 | 349 / 406 | 17,1 / 32,1 |
| `tape` · Bandadresse | Erstes und drittes Argument im Aufrufer tauschen | 24 / 0 | 2 | 370 / 438 | 18,8 / 33,0 |
| `page` · Seitenbelegung | UTF-8-Bytezahl vor dem Runden bestimmen | 9 / 0 | 1 | 291 / 316 | 16,0 / 31,6 |
| `ticket` · Druckauftrag | Bytezahl des zusammengesetzten Texts messen | 5 / 0 | 1 | 343 / 373 | 16,0 / 31,7 |
| `namespace` · Doppelkolon | Letztes `::` finden, auch bei überlappenden Treffern | 5 / 0 | 1 | 303 / 307 | 15,9 / 31,7 |
| `annotation` · Logtext | Letzte Raute in einem berechneten Text finden | 1 / 0 | 1 | 327 / 313 | 15,6 / 31,6 |
| `telemetry` · Zählerdifferenz | Zähler im Aufrufer tauschen und UTF-8-Bytezahl bilden | 11 / 35 | 2 | 468 / 536 | 22,4 / 32,7 |
| `trailer` · Schlussfeld | Letzte Feldgrenze finden und Bytezahl des Teilstrings messen | 7 / 6 | 1 | 398 / 388 | 18,9 / 32,0 |
| `thermal` · Einheiten | Bestehenden arithmetischen Operator ändern | 8 / 0 | 1 | 340 / 382 | 16,0 / 31,7 |
| `flag` · Paketfilter | Kein Kandidat für ASCII-Gross-/Kleinschreibung | 0 / 0 | 0 | 285 / 310 | 6,5 / 18,5 |

Bei `cut`, `tape` und `telemetry` stehen je zwei öffentlich grüne Optionen zur Wahl. Die vorab festgelegte Sortierung wählt jeweils den Tausch in `panel`. Damit stimmen alle 72 Ergebnisse am Einstieg. Ein direkter Aufruf von `samples(begin=3, finish=4, rate=4)` liefert jedoch weiterhin −4, der Vertrag für den Ausschnitt ergibt 4. Bei der zusätzlichen Prüfung wurden die tatsächlich gewählten Patches erneut angewendet und alle 72 Fälle je Aufgabe direkt gegen `route` ausgeführt. Beide Sprachen liefern dort für jede Eingabe identische Resultate. Bei den drei betroffenen Aufgaben bestehen nur 3, 5 bzw. 3 von 72 direkten Aufrufen. Diese nachträgliche Prüfung war von Auswahl und Zeitmessung getrennt. [Modulprüfung](modulpruefung.mjs) · [Erste Gegenbeispiele](modulabnahme.json)

## Versuchsaufbau

- Die zehn Dreidateienprojekte wurden für diesen Versuch geschrieben. Sechs Aufgaben prüfen gezielt die drei Erweiterungen, zwei kombinieren Änderungen in unterschiedlichen Dateien. Eine arithmetische Kontrolle und eine Aufgabe ausserhalb der Suchregeln zählen mit. Die Ergebnisse beschreiben diese gezielt zusammengestellte Stichprobe. [Aufgaben und Quellen beider Sprachen](aufgaben.json)
- Aufgaben, Regeln, Referenz und Zeitplan wurden vor dem Ziehen des lokalen Zufallsseeds gehasht. Das unabhängige TIDE-Orakel erzeugte pro Aufgabe acht öffentliche und 64 verdeckte, innerhalb der Aufgabe verschiedene Eingaben. Die unveränderten TIDE- und Python-Programme lieferten auf allen 720 Eingaben paarweise dieselben Ausgaben. Die Vorabprüfung entdeckte vor der ersten Aufwärmrunde eine Namenskollision im Messhelfer. Nur dessen Parameter wurde umbenannt. Der Seed und die Eingaben blieben erhalten. [Versuchsplan](versuchsplan.json) · [Hashes und Korrektur](fixierung.json) · [Orakel](abnahme.tide) · [Alle Fälle](prueffaelle.json)
- Beide Suchen erhielten dieselben öffentlichen Beispiele und das erste scheiternde Beispiel. Pro Aufgabe standen höchstens 32 Einzelprüfungen und 64 Paarprüfungen über zwei Dateien zur Verfügung. Bestehende Regeln kamen zuerst. Bei mehreren grünen Optionen entschied die Reihenfolge aus Datei, Position und Ersetzung. Verdeckte Beispiele wurden dem reparierten Programm erst zur Abnahme übergeben. Bei keiner Aufgabe wurde die Suche abgeschnitten. [TIDE-Änderung](suche.patch) · [CPython-AST-Vergleich](cpython_suche.py)
- Jeder der vier Arme lief einmal je Aufgabe zum Aufwärmen und zwölfmal unter der Uhr. Jeder Arm belegte jede der vier Positionen dreimal. Pro Versuch wurden frische Dateien und Prozesse verwendet, der Dateisystemcache war warm. Die Uhr umfasst Diagnose, Kandidatensuche, Auswahl, Übernahme und unabhängige Abnahme. Einrichten der Arbeitskopien sowie Tokenzählung lagen ausserhalb. TIDE verwendete die installierten Befehle `test`, `edit`, `test`. CPython suchte und schrieb in einem Prozess und las die gespeicherten Module zur Abnahme in einem frischen Interpreter. AMD Ryzen 9 9950X3D, CPU 24, TIDE 0.6.5, CPython 3.14.10, Netzwerk-Namensraum nur mit Loopback. Die Ergebnisdatei hält beide Inspector-Binärhashes fest. [Messprogramm](messen.mjs) · [480 Einzelmessungen](messung.json)

Die native Regression `make test` bestand. Die drei zuvor offenen Projekte `wire`, `mosaic` und `suffix` aus Versuch 69 bestanden mit dem neuen Inspector nach Diagnose und Übernahme jeweils ihre bisherigen 72 Einstiegsfälle. Für diese Zusatzkontrolle lief die installierte TIDE-Werkzeugkette in einem isolierten Dateisystem ohne Python. [Vorheriger Versuch](../69_neue_mehrdateienaufgaben/bericht.md)

## Lokal wiederholen

Vom Projektverzeichnis aus erzeugen die folgenden Befehle zwei getrennte Installationen. Die Rückwärtspatch-Datei stellt die bisherige Suche in einer temporären Quellkopie wieder her. Die Messbefehle schreiben die Ergebnisdateien im Versuchsverzeichnis neu.

```sh
d="$PWD/experimente/70_strukturelle_reparatur"
stage=$(mktemp -d)
mkdir "$stage/alt"
cp -a Makefile tide tide.lock native "$stage/alt/"
(cd "$stage/alt" && patch -R -p1 < "$d/suche.patch" && make -s -j4 install DESTDIR="$stage/vorher")
make -s -j4 install DESTDIR="$stage/nachher"
export TIDE_BEFORE="$stage/vorher/usr/local/bin/tide" TIDE_BIN="$stage/nachher/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev node "$d/modulpruefung.mjs"
```

Für die Offline-Zählung müssen `TOKENIZER_JSON` auf das in der Fixierung des Versuchsplans bezeichnete lokale Vokabular und `TOKENIZER_PYTHON` auf einen lokalen Interpreter mit `tokenizers` zeigen. Verwendete Version war 0.23.3. Dann prüft der folgende Befehl Hashes, Fallzahlen, Paarungen, Kandidaten und Budgets und schreibt die Auswertung.

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/auswerten.mjs"
```
