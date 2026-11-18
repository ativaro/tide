# Bestellimport · Ausgangsmessung für Stufen 1 bis 3

**Die lokalen Werkzeuge lösen auf beiden Seiten 9 von 15 offenen Aufgaben.** Das sind je drei Schreib-, zwei Erweiterungs- und vier Reparaturaufgaben. TIDE benötigt im Hauptlauf 3.187, CPython 3.583 offline gezählte Protokolltokens einschliesslich der sechs erfolglosen Versuche. Die tatsächliche Entwicklungsleistung eines Sprachmodells bleibt offen. Es liefen keine zusätzlichen Modelle. [Spezifikation des Bestellimports](bestellimport.md) · [Offene Aufgaben mit Abnahmefällen](aufgaben.json) · [Auswertung je Aufgabe](auswertung.json)

| Messgrösse | TIDE 0.6.5 | CPython 3.14.10 |
|---|---:|---:|
| Erfolg der begrenzten Werkzeuge | 9/15 | 9/15 |
| Korrekte Referenzprogramme | 15/15 | 15/15 |
| Werkzeugzeit vom Start der Suche bis zur korrekten Abnahme, Median | 11,85 ms | 31,08 ms |
| Median über alle Versuche bis Abnahme oder Enthaltung | 10,02 ms | 29,74 ms |
| Offline-Protokolltokens für alle 15 Versuche | 3.187 | 3.583 |
| Davon Eingabe / Ausgabe | 2.920 / 267 | 3.271 / 312 |
| Alle Protokolltokens geteilt durch korrekte Lösungen | 354,1 | 398,1 |
| Referenzprogramm mit Prozessstart, Median | 5 ms | 10 ms |
| Median des Spitzen-RSS je Referenzprozess | 4.166 KiB | 10.600 KiB |

Der Median der gepaarten Zeitverhältnisse CPython/TIDE beträgt 2,49 bei den erfolgreichen Werkzeugläufen. Für die Referenzprogramme beträgt er 2,20. Die Programmlaufzeit umfasst den Start und die JSON-Ein- und -Ausgabe für **einen kleinen Fachfall**. Die Uhr für diese Messung hat Millisekundenauflösung. Diese Stichprobe beschreibt weder den Dauerdurchsatz noch den vollständigen Bestellimport. [Rohmessungen und Umgebung](messung.json)

| Aufgabenfamilie | Erfolg je Sprache | Protokolltokens TIDE / CPython | Zeit bis Erfolg TIDE / CPython |
|---|---:|---:|---:|
| Schreiben | 3/5 | 807 / 855 | 9,03 / 99,23 ms |
| Erweitern | 2/5 | 1.118 / 1.278 | 12,04 / 29,32 ms |
| Reparieren | 4/5 | 1.262 / 1.450 | 12,53 / 30,13 ms |

**Die Schreibzeit hängt stark von der Prozessaufteilung ab.** Im Hauptlauf prüft jede Sprache jeden Entwurf in einem frischen Prozess. In einer anschliessenden Kontrolle kompiliert und prüft CPython alle Vorschläge einer Aufgabe im selben Interpreter und startet zur unabhängigen Abnahme einen zweiten. Auf denselben drei erfolgreichen Aufgaben sinkt die Python-Zeit von 99,23 auf **21,10 ms**. TIDE wurde parallel dazu in wechselnder Reihenfolge erneut gemessen und brauchte **8,96 ms**. Das gepaarte Verhältnis in dieser Kontrolle ist **2,39**. Beide Varianten wählten bytegleich dieselben Lösungen wie im Hauptlauf ihrer Sprache. [Kontrollarm](cpython_entwuerfe.py) · [Kontrollmessung](kontrollmessung.json)

## Die 15 offenen Aufgaben

| Familie | Umfang | Ergebnis |
|---|---|---|
| Schreiben | W01 Positionswert, W02 verfügbare Menge, W03 Versandetikett, W04 Menge aus JSON, W05 Empfangs-IDs in SQLite | Beide lösen W01 bis W03. Die festen Ausdrucksvorlagen können weder JSON dekodieren noch eine Datenbanktransaktion schreiben. |
| Erweitern | E01 inklusive Rabattgrenze, E02 UTF-8-Abrechnung, E03 Überlieferung, E04 Korrekturbuchungen, E05 neuer Frachttarif | Beide lösen E01 und E02. Bei E05 endet die Paarsuche am Budget von 64. |
| Reparieren | R01 Liefersaldo, R02 Kontrollwert über zwei Dateien, R03 Rechnungsgebühr, R04 Kartonrest, R05 Statuskennung | Beide lösen R01 bis R04 und enthalten sich bei R05. |

Für alle 15 Komponenten gibt es korrekte Referenzen in beiden Sprachen. Vor der Zeitmessung bestand jede die drei öffentlichen und vier zusätzlichen Fälle. Bei Aufgaben mit Zwischenmodul wurden beide Schnittstellen aufgerufen. Beim SQLite-Fall wurden ausserdem zwei Prozesse nacheinander auf dieselbe Datei angesetzt und die gespeicherten IDs einschliesslich Apostroph und Unicode über die SQLite-CLI kontrolliert. Die Vorlagen und die Reparatursuche erhalten während ihrer Entscheidung nur die öffentlichen Fälle und die Startquellen. [Ausgangsprogramme](start) · [Referenzquellen](referenzen)

## Welche 15 Aufgaben verdeckt bleiben

Es gibt insgesamt **zehn Aufgaben je Familie**, davon je fünf offen und fünf verdeckt. Die zusätzliche Schlussstichprobe wurde lokal aus Fachaufträgen mit Eingabebereich, Signatur, Startstand für Änderungen oder Reparaturen, öffentlichen Beispielen und gesonderten Abnahmefällen gezogen. Die konkrete Auswahl und die Eingaben wurden vor der Referenzimplementierung versiegelt. Ein Lesevergleich der verschlüsselten und wieder entschlüsselten Daten wurde bei der Erstellung ausgeführt. Der Messprozess sah weder Aufgabenpaket noch Schlüssel. Die 15 Schlussaufgaben wurden nicht ausgeführt. Die zusätzlichen Fälle der **offenen** Aufgaben sind für Nachprüfungen hier einsehbar. [Versiegelungsnachweis](versiegelung.json) · [Vorab fixierte Prüfwerte](vertrag.sha256)

Das Repository enthält je verdeckter Aufgabe nur Familie und gesalzenen SHA-256-Nachweis sowie den Hash des verschlüsselten Gesamtpakets. Das AES-256-GCM-Paket liegt lokal unter `~/.local/share/tide/holdouts/bestellimport-v1/schlussaufgaben.enc`, der separate Schlüssel unter `~/.config/tide/holdout-keys/bestellimport-v1.key`. Beide Dateien haben Modus 0600. Zur späteren Öffnung sind **beide lokalen Dateien** nötig. Das Format lautet acht Bytes ASCII `TIDE72G1`, zwölf Bytes IV, 16 Bytes GCM-Tag und anschliessend Chiffrat. Die Prüfwerte der einzelnen Aufgaben beziehen sich auf die UTF-8-Bytes von `JSON.stringify(task)` einschliesslich der zufälligen Nonce.

## Gleiche Bedingungen

- Aufträge, Eingaben, Erwartungen, Budgets, Suchreihenfolge und Metriken waren vorab festgelegt. Die Hauptmessung führt die Standard-CLI `tide run` und CPython mit isoliertem Modulpfad und ohne Bytecodecache aus. Beide erhalten dieselben Daten und Rechte. Die getesteten Teilaufgaben verwenden den jeweils dokumentierten Eingabebereich. [Messplan](messplan.json) · [Werkzeug- und Quellenprüfsummen](werkzeuge.sha256)
- Schreiben startet mit leerem Quellverzeichnis. Die endliche Vorlagenliste ist für beide Sprachen semantisch und in der Reihenfolge gleich. Erweitern und Reparieren starten mit drei Modulen und öffentlicher Prüfung am Einstieg und an der Zwischenfunktion. Beide Werkzeuge können bis zu 32 Einzeländerungen und 64 Paare prüfen. Ihre sprachspezifischen Knoten unterscheiden sich bei E04 (Python verwendet `sum`) und R05 (Textvergleich). Der erste öffentlich grüne Vorschlag muss in einem frischen Prozess die abschliessende Abnahme bestehen. [Vorlagen](vorlagen.json) · [Vorherige Modulprüfung](../71_modulvorpruefung/bericht.md)
- Die Werkzeugzeit umfasst Suche, öffentliche Prüfung, Übernahme und unabhängige Abnahme. Das Anlegen des anfänglichen Projekts liegt ausserhalb der Uhr. Eine Enthaltung zählt als erfolgloser Versuch. Für die Programmzeit laufen ausschliesslich korrekte Referenzquellen, jeweils auf dem ersten zusätzlichen Abnahmefall. Die Tabelle berichtet den Median der Einzelzeiten. Für den Faktor wird pro Paar dividiert und anschliessend der Median genommen.
- Ein Aufwärmpaar pro Aufgabe, danach vier Such- und acht Laufzeitpaare, balancierte Startreihenfolge und rotierende Aufgabenreihenfolge. Das ergibt 120 gemessene Suchläufe und 240 gemessene Referenzaufrufe auf CPU 24 eines Ryzen 9 9950X3D. Der Linux-Namensraum stellt nur Loopback bereit. Das Home-Verzeichnis ist nicht eingehängt. Die Spitzen-RSS stammt aus dem Prozesszähler von zsh.
- Der lokale Llama-BPE-Tokenizer zählt jeweils ein vollständiges deterministisches Protokoll pro Aufgabe und Sprache. Erfasst werden Auftrag, Signatur, Startquellen, öffentliche Fälle, angebotene Änderungen, Entscheidung und Status. Die gemessenen Zeitwiederholungen hatten identische Protokolle. Die Tokenzählung umfasst keine Modell- oder Denktokens. [Protokolle](protokolle.json) · [Offline-Auswertung](auswerten.mjs)

## Lokal nachmessen

Vom Repository-Verzeichnis aus erzeugen die folgenden Befehle eine lokale Installation und erneuern die beiden Ergebnisdateien des Hauptlaufs. Erforderlich sind Linux, bwrap, taskset, zsh, Node.js, CPython und die SQLite-CLI. `TIDE_CPU` wählt bei Bedarf einen anderen einzelnen verfügbaren Kern. Das versiegelte Aufgabenpaket wird für die Wiederholung nicht benötigt.

```sh
d=experimente/72_bestellimport_basis
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
sh "$d/lokal-messen.sh"
```

Die Kontrollmessung benutzt denselben Netzwerk- und Dateisystemausschluss. Sie benötigt ausschliesslich die offenen Quellen und Protokolle. Vom selben Repository-Verzeichnis aus:

```sh
out=$(mktemp -d)
bwrap --unshare-all --tmpfs / --ro-bind /usr /usr --symlink usr/bin /bin \
  --symlink usr/lib /lib --symlink usr/lib /lib64 --proc /proc --dev /dev --tmpfs /tmp \
  --ro-bind "$PWD/$d" /study --ro-bind "$stage/usr/local" /opt/tide \
  --ro-bind "$(command -v node)" /opt/node --bind "$out" /result --clearenv --setenv PATH /usr/bin \
  --setenv LC_ALL C.UTF-8 --setenv TIDE_BIN /opt/tide/bin/tide --setenv RESULT_DIR /result \
  taskset -c "${TIDE_CPU:-24}" /opt/node /study/kontrolle.mjs
cp "$out/kontrollmessung.json" "$d/"
```

Für die Offline-Auswertung müssen `TOKENIZER_JSON` und `TOKENIZER_PYTHON` auf das Vokabular mit dem Hash aus dem Messplan und einen lokalen Interpreter mit `tokenizers` zeigen (hier 0.23.3). Danach genügt `node "$d/auswerten.mjs"`. Die Abnahmedaten, Messreihen und Prüfsummen bleiben einzeln nachprüfbar. Die Quellen der TIDE- und CPython-Referenzen für E/R ergeben sich aus dem jeweiligen Startverzeichnis und den gleichnamigen Dateien unter `referenzen`, welche die korrigierten Module ersetzen.
