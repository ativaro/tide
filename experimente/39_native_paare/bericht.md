# Höchstwert und erste Fundstelle als natives Paar

Bei der Messreihe `−8, −2, −2` soll ein Agent den Höchstwert und seine erste Zeile zurückgeben. Vor der Änderung endeten die native Typprüfung und der Beispieltest für diese Faltung mit `E_BACKEND`. Jetzt liefert der installierte Projektauswerter `{"some":[-2,2]}`. Der Dateieinstieg und der öffentliche Aufruf für bereits gelesene Zeilen verwenden denselben TIDE-Rechenkern. [Anwendung](../../apps/first_peak.tide) · [Rechenkern mit drei Beispielen](../../apps/peak_lines.tide)

```sh
./tide run apps/peak_lines.tide --call peak_lines --inputs '{"rows":["-8","-2","-2"]}'
./tide test apps/peak_lines.tide --explain
```

Eine gewöhnliche Funktion kann ein Paar aus zwei Grundwerten verwenden. Alle neun Kombinationen aus `i`, `b` und `t` sowie Optionen um diese Paare funktionieren als Parameter, Zwischenergebnisse und Rückgabewerte. Der Prüfer kennt an jedem `first` und `second` den Komponententyp. So lassen sich am selben Knoten der Typ abfragen, ein Ausdruck ersetzen und die bestätigten Beispiele erneut ausführen. Paare mit zusammengesetzten Komponenten, Listen von Paaren, Paarergebnisse von Regeln und der direkte ELF-Build für diese Funktionen sind noch offen. Das benannte Leserecht des Dateieinstiegs benötigt ebenfalls eine native Implementierung. [Sprachreferenz](../../LANGUAGE.md)

## Laufzeit vom Aufruf bis zum Ergebnis

| Aufgabe | Anzahl | TIDE mit gewöhnlicher Auswertung | TIDE mit direktem Paarzugriff | Eigenständiges CPython-Programm |
|---|---:|---:|---:|---:|
| Negative und übrige Zahlen zählen | 16 | 5,75 ms | 5,75 ms | 9,38 ms |
| Negative und übrige Zahlen zählen | 4.096 | 51,98 ms | 37,06 ms | 9,49 ms |
| Höchstwert und erste Zeile finden | 16 | 6,22 ms | 6,16 ms | 9,24 ms |
| Höchstwert und erste Zeile finden | 4.096 | 69,24 ms | 60,86 ms | 9,93 ms |

Wenn ein Operand direkt `first totals` oder `second totals` liest, holt der Auswerter die Komponente aus der gebundenen Variablen. Er spart einen Auswertungsrahmen. Beide besuchten Ausdrucksknoten belasten weiterhin das Arbeitsbudget. Ist es nach dem ersten Knoten erschöpft, zeigt die Diagnose auf die Variable. Bei aufwendigeren Operanden verwendet TIDE den gewöhnlichen Weg. [Implementierung](../../native/bootstrap/function_run.tide)

Bei 4.096 Eingaben war der direkte Zugriff in beiden Aufgaben in je 21 von 21 Paaren schneller. Die mediane Ersparnis innerhalb der Paare betrug 14,85 ms beim Zählen und 8,38 ms bei der Höchstwertsuche. Der große Saldo ohne Paare benötigte im ursprünglichen Paket 7,08 ms, nach der Erweiterung 7,16 ms. CPython hatte bei den großen Eingaben mit beiden direkten Anwendungen die kürzere Laufzeit.

Jede Tabellenzelle ist der Median von 21 Einzelaufrufen nach drei Aufwärmrunden. Die drei Bedingungen liefen auf demselben logischen Prozessorkern mit wechselnder Startposition. Jeder Aufruf startete einen neuen Prozess und erhielt denselben vorbereiteten JSON-Eingabetext. Gemessen wurde bis zum Prozessende, jede Ausgabe wurde geprüft. TIDE lief über das installierte `tide run` einschließlich Quellprüfung. CPython startete mit `-I -S`, las die Argumente, führte die fachliche Berechnung aus und gab JSON aus. Die für die Messung verwendeten CPython- und TIDE-Programme, alle Zeiten, Prüfsummen und Eingabefolgen stehen in den [Messdaten](messung.json).

## Korrektheit und Grenzen

- 184 Vergleiche am öffentlichen Befehl stimmten bei Ausgabe und Exitstatus mit der historischen Sprachreferenz überein. Sie umfassten die Typkombinationen, vertauschte Komponenten, Optionen, Unicode, i64-Grenzen, falsche Typen, fehlerhaftes JSON sowie Formatierung und Knotenabfragen. Die native Seite lief in einem eigenen Mount-Namensraum ohne Python. Für neun Beispielverträge wurde der SHA-256-Wert unabhängig berechnet. Ein Edit im importierten Modul bestand anschließend die Tests. Ein erneuter Schreibversuch mit der verbrauchten Revision ergab `E_REVISION`.
- Bei 16 Eingabetexten stimmten der ursprüngliche Dateieinstieg, der umgebaute Dateieinstieg in der historischen Referenz und der native Rechenkern überein. Die Fälle umfassten CRLF, Gleichstände, leere Zeilen, beide i64-Grenzen und ungültige Zahlen. Bei Eingabefehlern wurden Code, Grund, Eingabezeile und Quellzeile verglichen. Die fehlerauslösende Zahlenkonvertierung steht jetzt im importierten Rechenkern.
- Die dauerhafte Testsuite konstruiert 4.096 optionale Paare mit je zwei Texten von 58 Codepunkten. Das verbraucht genau 4.194.304 Byte Gastbudget. Die nächste Paarbildung ergibt `E_LIMIT`. Ein separater Test prüft die vier Erschöpfungsstellen in den Operanden von `+ (first v) (second v)`. [Grenztests](../../native/bootstrap/checks.tide)
- 553 bestehende Textvergleiche, 77 Ressourcenfälle und 1.041 Knotenänderungen bestanden. Bei neun Knotenänderungen lieferte die historische Referenz keine Vergleichsausgabe. Dafür wurden die erwarteten Quellbytes unabhängig bestimmt. Der saubere Neubau und die Prüfung des installierten Pakets bestanden über `make check-no-python`. [Buildprüfung](../../native/bootstrap/no-python.Dockerfile)

Dieser Versuch misst die Laufzeit fertiger Programme. Tokenverbrauch und Reparaturzeit eines Modells wurden in diesem Zyklus nicht erhoben.
