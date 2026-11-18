# Acht neue Mehrdateienreparaturen mit TIDE und CPython

Beide Werkzeuge reparierten **5 von 8 Aufgaben (62,5 %)**. Bei denselben fünf Aufgaben erreichte TIDE die unabhängige Abnahme früher. Gegen die kompaktere der beiden geprüften CPython-Varianten betrug der gepaarte Zeitfaktor **1,94×**. Jede erfolgreiche Lösung bestand acht öffentliche und 64 zuvor verdeckte Fälle. Die lokalen Läufe riefen keine Modelle auf. [Einzelmessungen](messung.json) · [Kontrollmessung](kontrollmessung.json)

| Messgrösse | TIDE 0.6.5 | CPython 3.14.10 mit AST |
|---|---:|---:|
| Gelöste unterschiedliche Aufgaben | 5/8 | 5/8 |
| Erfolgreiche Messläufe im vorab festgelegten Vergleich | 60/96 | 60/96 |
| Zeit bis zur erfolgreichen Abnahme, Median / P95 | 18,34 / 24,76 ms | 56,66 / 62,95 ms |
| Zeit bis zum Abbruch ohne Kandidaten, Median / P95 | 7,25 / 8,35 ms | 19,12 / 21,42 ms |
| Zeit bis zur erfolgreichen Abnahme im Kontrollversuch, Median | 14,74 ms | 29,15 ms |
| Tatsächliche Modell-Eingabe- und Ausgabetokens der Reparaturläufe | 0 | 0 |
| Offline gezählte Protokolltokens der fünf gelösten Aufgaben zusammen | 2.057 | 2.286 |
| Offline gezählte Protokolltokens aller acht Aufgaben, je ein Versuch | 2.943 | 3.248 |
| Protokolltokens aller Versuche geteilt durch fünf Erfolge | 588,6 | 649,6 |

### Aufgaben und Fehler

Die acht Projekte wurden für diesen Versuch neu geschrieben. Jedes hat drei Quelldateien je Sprache. In drei der fünf gelungenen Reparaturen musste das Werkzeug zwei Dateien gemeinsam ändern. Bei Spiegelpuffer und Spektralbreite blieben jeweils zwei öffentlich grüne Änderungen übrig. Die vorab festgelegte Sortierung entschied den Gleichstand. Beim Vergleich gleicher Zahlen beeinflusst die Wahl zwischen strengem und inklusivem Vergleich dort das Ergebnis nicht. [Quellen beider Sprachen und Aufträge](aufgaben.json)

| Aufgabe | Ergebnis beider Werkzeuge | Median TIDE / Python, ursprünglicher Ablauf | Protokolltokens TIDE / Python |
|---|---|---:|---:|
| Bildnummer aus Zeitcode | Minuten mit 60 multiplizieren | 16,44 / 56,57 ms | 340 / 383 |
| Archivgruppe | Datensatz ab eins zählen und Gruppenkennung zum Startwert addieren | 17,45 / 54,72 ms | 391 / 435 |
| Pegelalarm | Gleichheit mitzählen und Anzahl mit Messperiode multiplizieren | 19,20 / 56,47 ms | 433 / 485 |
| UTF-8-Nachrichtenlänge | Offen. Die Nutzlast erfordert eine Bytezählung. | 7,03 / 18,56 ms bis Abbruch | 286 / 312 |
| Mosaikadresse | Offen. Beim Aufruf sind Zeile und Spalte vertauscht. | 7,36 / 19,71 ms bis Abbruch | 311 / 350 |
| Spiegelpuffer | Den höheren Belegungsstand verwenden | 17,89 / 57,26 ms | 380 / 426 |
| Spektralbreite | Das untere Minimum bestimmen und vom oberen Maximum abziehen | 22,39 / 56,92 ms | 513 / 557 |
| Pfadkomponente | Offen. Gesucht ist der letzte Schrägstrich. | 7,39 / 18,76 ms bis Abbruch | 289 / 300 |

### Wie die verdeckten Fälle getrennt blieben

Aufträge, Ausgangsprogramme, TIDE-Orakel, Suchregeln und Treiber erhielten vor der ersten Reparatur SHA-256-Fingerabdrücke. Erst danach erzeugte das Betriebssystem einen Zufallswert für die Auswahl der verdeckten Eingaben. Pro Aufgabe sind alle 72 Eingaben verschieden. In einer separaten Prüfung lieferten beide fehlerhaften Ausgangsprogramme auf sämtlichen 576 Eingaben jeweils denselben Istwert. Die Studienautoren kannten die Aufgaben. Die bereits vorhandenen Reparaturwerkzeuge erhielten ausschließlich die öffentlichen Beispiele. [Fixierung und Zufallswert](fixierung.json) · [TIDE-Orakel](abnahme.tide) · [Identische Prüfdaten](prueffaelle.json)

Beide Seiten gingen vom ersten fehlgeschlagenen öffentlichen Beispiel aus. Die Grenzen lagen bei 32 Einzeländerungen und bei Bedarf 64 Änderungspaaren in verschiedenen Dateien. Alle Aufgaben blieben innerhalb dieser Grenzen. Der Vergleich prüfte für jede Aufgabe die Übereinstimmung von Fehlerbeispiel, Ist- und Sollwert, Kandidatenzahlen sowie Dateien und Operatoren der grünen Vorschläge. Die Suche erhielt keine zusätzlichen Sollwerte. Erst nach Auswahl, öffentlicher Nachprüfung und Übernahme der Änderung in die Arbeitskopie bekam ein frischer Prozess die verdeckten Fälle. Ein Fehlschlag war endgültig. [Vorab festgelegter Versuchsplan](versuchsplan.json) · [Reparaturprotokolle](protokolle.json)

### Was die Zeitmessung erfasst

Die monotone Uhr lief vom Start der Diagnose bis zum Abschluss der unabhängigen Abnahme oder zum Abbruch. Sie umfasste Prozessstarts, Kandidatensuche, Auswahl, Übernahme und Tests. Vorbereiten der Arbeitskopien, Erzeugen der Prüfdaten und spätere Tokenzählung lagen ausserhalb des Intervalls. Es gab je Aufgabe ein ungewertetes Aufwärmpaar und zwölf Messpaare mit wechselnder Startreihenfolge, neuen Arbeitskopien und warmem Dateicache. Alle Prozesse liefen nacheinander auf CPU 24 eines Ryzen 9 9950X3D in einem Netzwerk-Namensraum mit ausschließlich Loopback. Die Wiederholungen messen Zeitstreuung auf acht Aufgaben. [Messergebnisse und Laufzeitumgebung](messung.json)

Im vorab festgelegten Ablauf starteten beide Werkzeuge bei erfolgreicher Reparatur drei Prozesse. Der Median der 60 gepaarten Python/TIDE-Zeitverhältnisse betrug 3,07. Die mittleren 50 % lagen zwischen 2,77 und 3,23. Der Median der gepaarten Zeitersparnis betrug 37,45 ms. [Auswertung nach Aufgabe und Phase](auswertung.json)

Nach dieser Messung wurde die Prozessaufteilung in einem zweiten gepaarten Versuch variiert. CPython suchte und übernahm die Änderung in einem Aufruf. Ein schlanker zweiter Interpreter las die gespeicherten Module direkt für die unabhängige Abnahme. TIDE wurde im selben Block mit seinen üblichen CLI-Aufrufen erneut gemessen. Beide Verfahren wählten in allen Aufgaben wieder exakt die gleichen Patches wie in ihrer ersten Messung. TIDE war in allen 60 erfolgreichen Paaren schneller. Der Median der Zeitverhältnisse sank auf **1,94**, die mittleren 50 % lagen zwischen **1,77 und 2,04**. Die Wahl des Python-Werkzeugablaufs hat somit einen erheblichen Einfluss auf den Faktor. [CPython-Kontrollarm](cpython_kompakt.py) · [Gepaarte Einzelzeiten](kontrollmessung.json)

### Was die Tokens aussagen

Es gab **null zusätzliche Modellläufe**. Für die separate Protokollmessung zählte derselbe lokale Llama-BPE-Tokenizer jede kompakt serialisierte Nachricht einzeln, ohne Sondertokens. Er erfasste Aufgabe, vollständige fehlerhafte Quellen, öffentliche Tests, kompakten Diagnosebefund samt grünen Kandidaten, die Entscheidung und den Abnahmestatus. Über alle acht Aufgaben waren das 2.779 Eingabe- plus 164 Ausgabe-Protokolltokens für TIDE und 3.060 plus 188 für Python. Der Umfang lag für TIDE **9,4 % niedriger**. Die Fehlversuche zählen mit. Die zwölf identischen Wiederholungen dienen allein der Zeitmessung. [Nachrichten](protokolle.json) · [Tokenizer-Fingerabdruck und Zählwerte](auswertung.json)

Das Ergebnis trägt eine Aussage über diese lokalen Reparaturwerkzeuge und das festgelegte Nachrichtenformat. Für Aussagen zu den tatsächlichen Gesamttokens eines programmierenden Modells einschliesslich Kontext, Wiederholungen und Denktokens fehlen Modellmessungen. Auch die drei offenen Aufgaben sind relevant für die Machbarkeit. Keine der vorhandenen Änderungsregeln konnte dort einen öffentlich grünen Kandidaten liefern.

### Lokal wiederholen

Die folgenden Befehle laufen vom Projektverzeichnis aus und benötigen die vorhandene Linux-Werkzeugkette, Node.js, CPython, Bubblewrap und taskset. `run` prüft die fixierten Quelldateien und verwendet den aufgezeichneten Zufallswert. Ein neuer Lauf ersetzt die Ergebnisdateien im Versuchsverzeichnis. Für einen unabhängigen Nachlauf kann eine Arbeitskopie verwendet werden.

```sh
d=experimente/69_neue_mehrdateienaufgaben
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/kontrolle.mjs"
```

Für die separate Tokenzählung sind `TOKENIZER_JSON` auf die lokale Vokabulardatei mit dem aufgezeichneten SHA-256-Wert und `TOKENIZER_PYTHON` auf einen Interpreter mit Hugging Face `tokenizers` zu setzen. Die Messung verwendete Version 0.23.3. Es werden ausschließlich Vokabular und Regeln geladen. [Zeitmessung](messen.mjs) · [Offline-Auswertung](auswerten.mjs)

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/auswerten.mjs"
```
