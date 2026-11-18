# Native Sammlungen am vollständigen Spiel

Der öffentliche Projekteinstieg des bisherigen Pakets meldete für das unveränderte Space Invaders `E_BACKEND`. Jetzt besteht `tide test apps/space_invaders.tide` alle zehn Beispiele. Mit `apps/invaders_checks.tide` als Einstieg kommt eine elfte Probe für Bewegung, Schuss, Pause und Fortsetzung hinzu. `run` kann den vollständigen Zustand mit 21 Gegnern und drei Schilden ausgeben, per `tick` weiterschalten und per `draw` in eine Liste von Bildschirmzeichen umwandeln. Die native Terminalanbindung für `play` ist offen. [Spiel](../../apps/space_invaders.tide) · [Prüfprogramm](../../apps/invaders_checks.tide)

## Laufzeit der CLI

| Vollständiger Aufruf | Vor der Erweiterung | Erster lauffähiger Prototyp | Optimierte Fassung |
|---|---:|---:|---:|
| Zehn Spielbeispiele prüfen | E_BACKEND | 21,25 ms | 20,51 ms |
| Startbild aus übergebener Spielwelt erzeugen | – | 21,02 ms | 20,01 ms |
| Liste mit 512 Records einlesen und zählen | – | 29,49 ms | 10,28 ms |
| Liste mit 4.096 Records einlesen und zählen | – | 227,94 ms | 42,25 ms |
| Letzten von 4.096 Records aus einem Recordfeld lesen | – | 234,09 ms | 45,16 ms |
| Saldo über 4.096 Buchungen | 7,85 ms | 7,75 ms | 7,84 ms |
| Zwei Felder eines flachen Records über 4.096 Durchläufe lesen | 19,32 ms | 20,42 ms | 20,17 ms |

Strukturierte JSON-Arrays werden beim Validieren indiziert. Der typisierte Leser verwendet die vorhandenen Einträge. Kurze Zahlen werden beim ersten Trennzeichen abgeschlossen. Bei der großen Liste sank die Zeit gegenüber dem ersten lauffähigen Prototyp um den Faktor 5,39. Bei Projektion aus dem flachen Record kostete der aktuelle Aufruf gegenüber dem Paket vor der Erweiterung 0,86 ms mehr. Die Zeiten enthalten Prozessstart, Projektprüfung, JSON-Verarbeitung, Berechnung und Ausgabe. Jede Zelle ist der Median von 21 seriellen Aufrufen nach drei Aufwärmrunden auf Kern 2 eines Ryzen 9 9950X3D. Die Startreihenfolge wechselte. [Einzelmessungen, Eingaben und Binärprüfsummen](messung.json)

## Kosten des Reparaturkontexts

Beim Fehler im importierten Spielmodul setzte `battle` nach einem überlebten Treffer die Phase auf `paused`. Das Beispiel `surviving_hit` erwartete `respawn`. Alle übrigen Felder der resultierenden Welt stimmten überein. Beide Ansichten lieferten die vier benötigten Recorddeklarationen einschließlich der Elementtypen für Gegner und Schilde. Mit der Knotenkennung aus `context` ließ sich der falsche `tag` über den Projekteinstieg gezielt ersetzen. Nach der Änderung entsprach das Spielmodul byteweise dem Original und die zehn Beispiele bestanden.

| Fehler | Statisch erreichbarer Kontext | Ausgeführter Kontext | Vorbereiteter Python-Kontext |
|---|---:|---:|---:|
| Gleichstand | 277 Tokens · 5,94 ms | 272 Tokens · 5,95 ms | 310 Tokens · 16,69 ms |
| Rundung | 293 Tokens · 6,11 ms | 315 Tokens · 6,19 ms | 315 Tokens · 16,24 ms |
| Falscher Spielzustand | 2.695 Tokens · 22,21 ms | 2.616 Tokens · 23,36 ms | – |

Beim Spiel schrumpft die Zahl der Funktionsrümpfe von 26 auf 18. Die zusätzlichen Zweigangaben lassen eine Ersparnis von 79 Tokens. Bei Rundung liefert die statische TIDE-Ansicht den kürzesten Befund. Die statischen CPython-Antworten für Gleichstand und Rundung wurden mit denselben zwei Projekten, Eingaben und dem externen Kontextwerkzeug wie im vorherigen Variantenversuch erneut erhoben. Die fachlichen Ergebnisse und Eingaben wurden in jedem Durchgang geprüft. Die Spielmessung vergleicht die beiden TIDE-Ansichten. Gezählt wurde die vollständige Werkzeugantwort einschließlich Zeilenende mit `o200k_base`. Gesamttokens und Zeit bis zur Reparatur durch ein Modell würden eigene Blindläufe erfordern. [Vergleichsquellen](../44_native_varianten/messung.json) · [Aktuelle Befunde und Einzelzeiten](messung.json)

## Grenzen und Beispielverträge

- Ein separater Lauf über die installierte CLI prüfte alle sechs Spielphasen, die passenden Banner, die Rückkehr nach einem Treffer sowie den Neustart nach Sieg und Niederlage.
- Listen mit 4.096 Records lassen sich einlesen und indizieren. 4.097 Eingabeelemente ergeben `E_INPUT`. Ein `append` an eine volle Liste ergibt `E_LIMIT`. Ein TIDE-Test belastet den Gast mit 4.096 Änderungen eines je 1.024 Byte großen verschachtelten Records. Genau 4 MiB sind zulässig. Eine weitere Änderung wird abgelehnt. [Grenztest](../../native/bootstrap/checks.tide)
- Ein bestätigtes Beispiel behält seinen Vertragsfingerabdruck, wenn sich in einem Array nur die Reihenfolge der Recordfelder oder die JSON-Schreibweise eines Unicode-Zeichens ändert. Das Umordnen der Listenelemente oder ein anderer Feldwert ändern den Fingerabdruck. Der native Editor verlangt dafür die ausdrückliche Vertragsänderung. [Regressionstest](../../native/bootstrap/inspection_checks.tide)
- `make test` und der vollständige Linux-x86-64-Neuaufbau mit `make check-no-python` bestanden. Das installierte Paket prüft die Spielbeispiele und zeichnet das Startbild im separaten Laufzeitabbild ohne Python. Python wurde ausschließlich im externen Vergleich für Gleichstand und Rundung aufgerufen. [Containerprüfung](../../native/bootstrap/no-python.Dockerfile)
