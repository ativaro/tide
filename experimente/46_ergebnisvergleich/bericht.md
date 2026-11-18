# Welche Stelle im Ergebnis ist falsch?

In einem Buchungsjournal mit 384 Einträgen verringerte die importierte Funktion `post` den letzten Saldo um eins. Neben der Beispielposition meldet `tide test panel.tide --diff` die Abweichung im Feld `balance`.

```json
{"difference":{"path":"/rows/383/balance","expected":27,"actual":26}}
```

Im zweiten Projekt speicherte `store` nur die Einerstelle eines Messwerts. Der Befund nennt den letzten Listenindex `/4095`, Sollwert 82 und Istwert 2. Beide Diagnosepfade wurden vor der Reparatur geprüft. Mit den Knotenkennungen aus `context` und der Revision aus dem Befund ließ sich die jeweilige Hilfsfunktion über den Projekteinstieg korrigieren. Beide Reparaturen bestanden das öffentliche Beispiel und anschließend je 24 zusätzliche Eingaben, auch in der externen CPython-Fassung. [Buchungsjournal](ledger/panel.tide) · [Messwerterfassung](tail/panel.tide) · [Prüfungen und Rohdaten](messung.json)

## Der erste Befund ohne Funktionsrümpfe

| Fehler | Bisherige TIDE-Ausgabe | TIDE mit `--diff` | Zeit bisher | Zeit mit `--diff` |
|---|---:|---:|---:|---:|
| Falsche Spielphase | 178 Tokens | 52 Tokens | 19,52 ms | 19,66 ms |
| Letzte Buchung | 6.187 Tokens | 49 Tokens | 22,54 ms | 19,54 ms |
| Letzter Messwert | 16.420 Tokens | 48 Tokens | 10,09 ms | 7,99 ms |

Bei der Spielphase entfallen die übrigen Felder der beiden Spielwelten. Beim Journal entfallen 383 korrekte Einträge sowie die korrekte Sequenznummer der letzten Buchung. Die Ausgabe nennt die erste Abweichung. Weitere Unterschiede können nach der ersten Korrektur sichtbar werden. Der Standardbefehl liefert weiterhin die vollständigen Werte.

## Vorbereiteter Kontext für beide Sprachen

| Fehler und Ansicht | TIDE · Tokens | CPython · Tokens | TIDE · Zeit | CPython · Zeit |
|---|---:|---:|---:|---:|
| Buchung, statisch mit Eingabe und Ergebnispfad | 3.296 | 3.320 | 22,15 ms | 17,35 ms |
| Buchung, ausgeführte Funktionen und Eingabeverweis | 235 | 259 | 21,49 ms | 17,86 ms |
| Messwert, statisch mit Eingabe und Ergebnispfad | 8.365 | 8.377 | 10,49 ms | 14,23 ms |
| Messwert, ausgeführte Funktionen und Eingabeverweis | 185 | 197 | 8,52 ms | 14,53 ms |

Die statischen Antworten enthielten dieselben Eingaben, die beiden fachlich entsprechenden Funktionsrümpfe und die benötigten Typen. Für die ausgeführte Ansicht werteten beide Werkzeuge das Beispiel erneut aus. Python zeichnete die tatsächlich betretenen Projektfunktionen mit `sys.setprofile` auf. Beide importierten Rechenpfade sind verzweigungsfrei. Das externe Vergleichswerkzeug prüft das am Syntaxbaum. Beide Antworten nennen die zwei besuchten Funktionen und verweisen für die große Eingabe auf das revisionsgebundene Beispiel. Wer es nachlädt, muss dessen Tokens und Ladezeit zusätzlich rechnen. [Bibliotheken, externes Vergleichswerkzeug und vollständige kompakte Befunde](messung.json)

Die tatsächliche Ausgabe enthält pro Sprache einen eigenen Revisionshash. Mit identischem Platzhalter für beide Hashes betrug der Abstand bei ausgeführtem Kontext noch 18 Tokens für die Buchung und zehn für den Messwert. Der große Gewinn entsteht in beiden Sprachen durch die Wahl des Ausgabeumfangs. Bei der Buchung blieb CPython schneller.

## Was zur Laufzeit beiträgt

TIDE vergleicht typisierte Ergebniswerte. Listenlängen und Optionsfälle werden vor den enthaltenen Werten geprüft. Bei einer Abweichung setzt der Prüfer den Pfad aus Recordfeldern, Optionsinhalt und Listenindizes zusammen. Für den ausgeführten Kontext überspringt der Auswerter das Ausschreiben einer Eingabe, wenn schon die Zahl der enthaltenen Elemente die Grenze für einen Eingabeverweis garantiert. Der erste Prototyp mit derselben Ausgabe benötigte für die Buchung 23,26 ms und für den Messwert 10,66 ms. [Vergleich in TIDE](../../native/bootstrap/value_diff.tide)

Bei den reparierten Programmen sank die Zeit für den regulären Testlauf beim Journal von 22,18 auf 19,44 ms und beim Messwert von 9,78 auf 7,88 ms. Bei den elf bestandenen Spielbeispielen lagen die Mediane bei 28,61 und 28,90 ms. Wer für das fehlerhafte Journal die vollständige Standardausgabe verlangt, benötigt jetzt 22,99 ms gegenüber 22,54 ms im vorherigen Paket.

Ein Kontrollprogramm mit demselben Buchungstyp gab unabhängig von der Eingabe die Zahl null zurück. Mit leerer Liste brauchte der Aufruf 5,84 ms, mit 383 Eingaberecords 12,09 ms. Ein zweites Programm gab die unveränderte Liste im Record zurück und prüfte sie gegen einen gleich großen Sollwert. Es benötigte 5,85 ms bei leerer Liste und 18,39 ms bei 383 Records. Damit ist ein großer Teil der Zeit bereits ohne Buchungsrechnung reproduzierbar. Die Kontrollen umfassen das Einlesen, Typisieren, Ausführen und Prüfen des jeweiligen Beispielprojekts.

## Messung und Prüfung

Jede Zeit ist ein Median aus 21 vollständigen seriellen CLI-Aufrufen nach drei Aufwärmrunden auf Kern 2 eines Ryzen 9 9950X3D. Die Startreihenfolge wechselte pro Runde. TIDE verwendete die Projekt-Lockdatei und den kurzen Dateinamen im jeweiligen Projektverzeichnis. Längere Pfade im Befund können weitere Tokens kosten. Die externen CPython-Aufrufe lasen die Beispiele über stdin und die beiden Module aus dem Projektverzeichnis. Gezählt wurde die gesamte Werkzeugantwort einschließlich Zeilenende mit `o200k_base`. Es liefen keine isolierten Modellsitzungen. [Einzelzeiten, Versionen, Prüfsummen und Vergleichsprogramme](messung.json)

Für 64 Wertekombinationen wurde die vollständige Fehlerausgabe mit dem vorherigen Paket byteweise verglichen und anschließend das passende Ergebnis akzeptiert. Weitere Prüfungen umfassten ein- und ausgepackte Optionen, Unicode-Textenden, Ereignisfehler mit Zählung ab eins, Rückgabewerte aus einem Teilbaum und Listen bis 4.096 Records. Große Eingaben wurden direkt unter, genau an und über der Verweisgrenze von 1.024 Codepunkten geprüft. `make test` und `make check-no-python` bestanden. Beim Bau der erweiterten Testsuite erreichte der Startcompiler seine bisherige Grenze für das Einlesen der Quelldatei als eine einzige Zeilenliste. Er verarbeitet die Zeilen nun gruppenweise. Mit 4.097 führenden CRLF-Zeilen und einer folgenden Funktion lieferte `tide forms` im bisherigen Paket `line_limit` und im neuen Paket die korrekt gruppierte Funktion. [TIDE-Regressionstests](../../native/bootstrap/inspection_checks.tide) · [Startcompiler](../../native/bootstrap/seed.tide) · [Isolierter Neubau und Paketprüfung](../../native/bootstrap/no-python.Dockerfile)
