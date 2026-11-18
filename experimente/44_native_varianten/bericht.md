# Native Varianten und die Kosten des Reparaturkontexts

Bei Gleichstand soll die ältere Kennung gewinnen. Für die Kennungen 19 und 7 gab das Programm 19 zurück. Der zweite Fehler betraf die Rundung auf ganze Einheiten. Bei 25 Zehnteln und der Regel „zur geraden Zahl“ gab das Programm 3 zurück. Der Sollwert ist 2. In beiden Fällen lag die fehlerhafte Hilfsfunktion im importierten Modul. Für jede Sprache enthielt der vorbereitete Befund Eingabe, Erwartung, Ergebnis, Revision, Typen und die erreichbaren Funktionsrümpfe. [Prüfprogramme](../../native/bootstrap/fixtures/functions/variants.tide) · [Module, Vergleichsquellen und vollständige Befunde](messung.json)

| Erzeugter Befund | Gleichstand, Tokens | Zeit | Rundung, Tokens | Zeit |
|---|---:|---:|---:|---:|
| TIDE, statisch erreichbar | 277 | 5,86 ms | 293 | 6,01 ms |
| TIDE, tatsächlich ausgeführt | 272 | 5,82 ms | 315 | 6,02 ms |
| CPython, statisch erreichbar | 310 | 16,45 ms | 315 | 15,94 ms |

Beim Gleichstand fällt in der ausgeführten Ansicht die Hilfsfunktion für die neuere Kennung weg. Die aufgezeichneten Zweige für `oldest` und den Vergleich in `smaller` kosten fast so viel Platz wie die ausgelassene Definition. Bei der Rundung fällt lediglich `upper_units` mit seinem kurzen Rumpf weg. Der Befund nennt zusätzlich die Pfade durch Vorzeichenprüfung, Restvergleiche, Variantenwahl und Paritätstest. Das kostet gegenüber der statischen TIDE-Ansicht 22 Tokens.

Jede Zeit ist der Median von 21 seriellen Prozessaufrufen nach drei Aufwärmrunden auf logischem Kern 2 eines Ryzen 9 9950X3D. Die Startreihenfolge wechselte pro Runde. Die Zeit umfasst das Ermitteln des Fehlers und das Bereitstellen des Kontexts bis zum Prozessende. Die Ausgabetokens umfassen die vollständige JSON-Antwort mit Zeilenende, gezählt mit `o200k_base`. Der externe CPython-3.14.10-Helfer lädt beide Module, führt die Beispiele des Ziels bis zum ersten Fehler aus und ermittelt die erreichbaren Definitionen und Typen aus dem Syntaxbaum. Der Python-Befund enthält die Positionen der Funktionsrümpfe, TIDE zusätzlich die Quellposition des fehlgeschlagenen Beispiels. Für diesen Versuch wurden keine Modellsitzungen gestartet. Die Stichprobe misst weder Denk- und Eingabetokens eines Modells noch dessen Zeit bis zur erfolgreichen Reparatur.

Die Knotenkennung aus jedem ausgeführten Befund genügte, um die bekannte Korrektur mit `tide edit` erst in der Vorschau und dann schreibend anzuwenden. Anschließend bestanden die zwei öffentlichen Gleichstandsproben und die fünf Rundungsproben. Für beide Sprachen wurden außerdem 50 Kombinationen aus Kennungen und Richtung sowie 100 Kombinationen aus Zehntelwert und Rundungsregel gegen unabhängig berechnete Sollwerte geprüft. Vor der Änderung waren 20 bzw. 5 dieser Kombinationen falsch. Danach bestanden alle. Die Rundungsmatrix umfasst auch die öffentlichen Werte.

## Eine zusätzliche Phase im Spiel

In einer Kopie des Spiels wurde ausschließlich `intermission` an die Deklaration von `Phase` angehängt. Das bisherige Paket meldete `E_BACKEND`. Das neue `tide check space_invaders.tide` meldet in einem Aufruf zwei Einträge unter `E_MATCH`. Sie zeigen auf `draw` in der Einstiegsdatei bei Zeile 72 und auf `tick` in `invaders_game.tide` bei Zeile 140, beide bei Spalte 1. Der vollständige Aufruf dauerte im Median 15,45 ms. Mit `invaders_checks.tide` als Einstieg kommt dessen eigene Phasenentscheidung hinzu. Nach dem Ergänzen von `tick` und danach `draw` sank die Zahl der offenen Stellen von drei auf zwei und eins. Das unveränderte Spiel benötigt für die vollständige öffentliche Ausführung noch Listen von Records. Die Bootstrap-Tests führen Spiel- und Editorlogik weiterhin aus.

Variantenwerte und direkte Variantenfelder in Records laufen im öffentlichen Projektauswerter. Beim Parsen ordnet er jeder Variante ihren Zweig zu. Während der Ausführung liest `match` den passenden Zweig über diesen Index. Ein Test mit 64 in umgekehrter Reihenfolge notierten Zweigen wählte für jedes Label den richtigen Wert. Eine unbekannte Markierung bei `edit --write` ergab `E_TAG` und die Quelldatei blieb bytegleich. Die Containerprüfung baut und installiert die Werkzeuge ohne Python, führt alle zehn Variantenbeispiele aus und verlangt beide Meldungen für die zusätzliche Spielphase. [Containerprüfung](../../native/bootstrap/no-python.Dockerfile)

| Vollständiger Aufruf | Prototyp mit Namenssuche | Indizierte Fassung |
|---|---:|---:|
| Eine Entscheidung mit 64 Fällen | 5,82 ms | 5,81 ms |
| 4.096 Entscheidungen mit je 64 Fällen | 24,90 ms | 23,72 ms |

Die Saldo-Kontrolle mit 4.096 Buchungen benötigte im Paket vor der Variantenerweiterung und in der neuen Fassung jeweils 7,29 ms. Neben der Zweigwahl änderte sich auch die Prüfung vollständiger Zweiglisten beim Einlesen. Die Prozesszeiten umfassen beides. [Einzelzeiten, Prüfsummen und Abnahme](messung.json)
