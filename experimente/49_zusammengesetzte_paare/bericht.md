# Welchen Reparaturkontext braucht ein Agent?

Bei zwei neuen Mehrdateifehlern zu Gleichstand und Rundung genügten die drei statisch erreichbaren Funktionen. Die ausgeführte Ansicht zeigte bei beiden dieselben Funktionen und zusätzlich die gewählten Zweige. Beim Nano-Editor trat das Gegenstück auf. Dort ließ der ausgeführte Kontext mehrere unbeteiligte Funktionen weg und halbierte die Ausgabe beinahe. [Einzelmessungen und vollständige Werkzeugantworten](messung.json)

## Zwei neue Fehler mit vorbereitetem Kontext für beide Sprachen

Bei der Angebotswahl verdrängte ein gleich teurer Herausforderer das bestehende Angebot. Beide Werkzeuge fanden am Ergebnispfad `/0/name` den Namen A anstelle von B. Bei der Umrechnung in Zehnereinheiten sollte ein halber Schritt zur geraden Zahl gehen. Für −25 lieferte die fehlerhafte Funktion −3. Beide Werkzeuge meldeten an `/1` den Sollwert −2. Beide begannen am Projekteinstieg mit denselben Beispielen und erhielten die Position des Fehlers erst durch die Auswertung. [Angebotswahl](gleichstand/panel.tide) · [Rundung](rundung/panel.tide)

| Fehler | Ansicht | TIDE-Ausgabetokens | CPython-Ausgabetokens | TIDE bis Befund | CPython bis Befund |
|---|---|---:|---:|---:|---:|
| Gleichstand | statisch | 261 | 288 | 6,40 ms | 16,84 ms |
| Gleichstand | ausgeführt | 281 | 307 | 6,35 ms | 16,92 ms |
| Rundung | statisch | 307 | 319 | 6,70 ms | 17,14 ms |
| Rundung | ausgeführt | 376 | 383 | 6,75 ms | 17,24 ms |

Beide Werkzeuge lieferten Eingabe, Abweichung, Revision, beteiligte Typen sowie Funktionsrümpfe mit Positionen. Die ausgeführten Ansichten enthielten zusätzlich die tatsächlich gewählten Zweige. Beim Gleichstand stieg die TIDE-Ausgabe dadurch um 20 Tokens, bei der Rundung um 69. Die CPython-Vergleichshilfe lädt die Beispielmodule, liest ihren Syntaxbaum und verfolgt im ausgeführten Modus die durchlaufenen Zeilen. Die Zeit umfasst diesen Aufbau bei jedem Prozessstart. In den kompakten Ergebnissen liegen zwischen den Sprachen teils nur sieben Tokens. Funktionsschreibweise, Quellpositionen und der jeweils eigene Revisionshash fließen in diese Zahlen ein. [Vergleichshilfe und Quelltexte](messung.json)

Die bekannten Korrekturen wurden über den TIDE-Knoteneditor in einer Projektkopie und im externen Python-Vergleich angewandt. Anschließend bestanden beide die eingebetteten Beispiele und eine Prüfung gegen unabhängig berechnete Sollwerte für 25 Angebotspaare und alle 83 ganzzahligen Temperaturen von −41 bis 41. Die beiden hier verlinkten Projekte enthalten absichtlich die fehlerhafte Fassung. Ein Beispielaufruf aus dem Projektstamm lautet wie folgt.

```sh
./tide test experimente/49_zusammengesetzte_paare/rundung/panel.tide --diff --explain
```

## Nano über den normalen Projekteinstieg

Ein Tastendruck in Nano liefert ein Paar aus `Buffer` und `Effect`. Im vorherigen nativen Paket endete der öffentliche Nano-Test mit `E_BACKEND`. Jetzt laufen dieselbe Editorlogik und ihre Cursorroutinen über `tide run` und `tide test`. Das Testmodul verarbeitet zusätzlich eine Liste von Tasten und Speicherrückmeldungen. Ein `store` fordert das Speichern an. Der Aufrufer gibt mit `stored` oder `io_error` das Ergebnis zurück. Nach `finish` ignoriert die Wiedergabe weitere Ereignisse. Interaktives Terminal und echte Dokumentzugriffe sind weiter offen. [Nano in TIDE](../../apps/nano.tide) · [Wiedergabe und zehn Beispiele](../../apps/nano_checks.tide)

Zehn Ereignisse umfassten Unicode-Eingabe auf zwei Zeilen, Cursorbewegung, einen fehlgeschlagenen Speicherversuch und das spätere Beenden. Alle Varianten lieferten denselben vollständigen Endpuffer und die Aktion `finish`.

| Aufruf | Prozesse | Zeit bis zum Endzustand | Ausgabetokens |
|---|---:|---:|---:|
| Natives TIDE, Initialisierung und jeder Schritt einzeln | 11 | 111,40 ms | 568 |
| Natives TIDE, dieselben Ereignisse in einem Aufruf | 1 | 12,38 ms | 54 |
| Historischer TIDE-Interpreter, ein Aufruf | 1 | 33,52 ms | 67 |

In der Einzelvariante geben die Werkzeuge nach jedem Ereignis den Puffer aus. Der Sammelaufruf liefert nur das Endergebnis. Wer die erste falsche Zwischenstufe sucht, kann dieselbe Folge schrittweise abspielen. [Ereignisse und Ausgaben](messung.json)

Bei einem dritten, absichtlich eingebauten Fehler sprang Nano beim Beenden mit ungesicherten Änderungen in die falsche Betriebsart. Der Befund nannte `/0/mode`, erwartete `confirm_exit` und fand `writing`. Die reine Abweichung kostete 50 Ausgabetokens. Der statische Kontext mit Typen und Rümpfen kostete 793 Tokens bei 10,87 ms, der ausgeführte Kontext 407 Tokens bei 10,77 ms. Er enthielt die Funktionen `shortcut` und `stay` sowie die Typen `Buffer`, `Mode` und `Effect`. Eine revisionsgebundene Knotenänderung über das importierende Einstiegsmodul stellte die Originaldatei bytegenau wieder her. Danach bestanden alle zehn Nano-Beispiele.

## Kosten zusammengesetzter Paare

Der native Auswerter typisiert beide Komponenten vollständig und verwendet für zusammengesetzte Paare die vorhandene Darstellung verschachtelter Werte. Grundwertpaare behalten ihre kompakte Darstellung. Bei der häufigen Form `&{Cursor}{Outcome}` ermittelt der Auswerter die Grenze der ersten Komponente direkt an der schließenden Klammer des Typnamens. Bei einem Paar als erster Komponente verfolgt er weiterhin die Struktur des Typs. [Typprüfung](../../native/bootstrap/functions.tide) · [Wertdarstellung und Größenberechnung](../../native/bootstrap/value_tree.tide)

Für die folgenden Aufrufe lasen beide Programme eine JSON-Liste von Paaren aus Cursor und Status und gaben alle Cursorpositionen zurück. Das externe CPython-Programm prüfte die Felder, Typen und Variantennamen dieser Eingaben.

| Anzahl der Paare | TIDE vor der direkten Grenzbestimmung | TIDE danach | Direktes CPython |
|---:|---:|---:|---:|
| 1 | 7,22 ms | 7,17 ms | 9,45 ms |
| 64 | 8,65 ms | 8,52 ms | 9,52 ms |
| 256 | 12,91 ms | 12,43 ms | 9,69 ms |

Die Ausgabetokens waren für alle drei Werkzeuge gleich. Beim größten Datensatz war das spezialisierte CPython-Programm schneller. Gemessen wurden gültige Eingaben dieser drei Größen. CPython führt keine TIDE-Projektprüfung oder Gastbudgetierung durch. [TIDE-Programm](../../native/bootstrap/fixtures/functions/composite_pairs.tide) · [Eingabekonstruktion und externe Python-Fassung](messung.json)

## Abnahme und Messverfahren

Die neun öffentlichen Paarbeispiele und die zehn Nano-Beispiele bestanden nativ und im archivierten Referenzinterpreter. 48 weitere Typkombinationen ergaben nach Vertauschen beider Komponenten in beiden Auswertern dieselben Werte. Alle 14 Nano-Eingaben wurden in beiden Betriebsarten mit der Referenz verglichen. Sechs ungültige JSON-Eingaben, fünf Abweichungspfade und fünf Typfehler wurden über den öffentlichen Einstieg geprüft. Ein dauerhafter TIDE-Grenztest konstruiert 4.096 Paare mit je zwei logisch gezählten Kopien desselben Records. Genau 4 MiB Gastallokation bestehen, ein weiteres Paar meldet `E_LIMIT`. Der vollständige Neubau, die Tests und die Paketprüfung einschließlich eines Upgrades bestanden in einem Container ohne Python. [TIDE-Grenztests](../../native/bootstrap/checks.tide) · [Isolierter Build](../../native/bootstrap/no-python.Dockerfile)

Die Tabellen nennen Mediane aus je 21 seriellen Werkzeugaufrufen nach drei Aufwärmrunden auf einem festen CPU-Kern. Die Reihenfolge wechselte pro Runde. Gezählt wurde die gesamte Werkzeugausgabe einschließlich Zeilenende mit `o200k_base`. Der historische TIDE-Interpreter und die eigenständigen CPython-Vergleiche liefen außerhalb der TIDE-Werkzeugkette. Es gab keine isolierten oder blinden Modellsitzungen. Somit bleiben die Gesamttokens eines Agenten und seine Zeit bis zur selbst gefundenen Reparatur in diesem Versuch ungemessen. [Einzelzeiten, Quartile, Softwareversionen und Prüfsummen](messung.json)
