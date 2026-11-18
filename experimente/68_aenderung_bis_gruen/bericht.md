# Paketänderung bis zum grünen Messbericht

Beim installierten TIDE sank die Zeit vom Speichern der Korrektur in `measurements.parse` bis zum grünen Test von **5,28 auf 1,43 ms**. Die Einsparung betrug im gepaarten Median **3,82 ms** oder den Faktor **3,70**. Gegen CPython stieg der Faktor von **1,21 auf 4,50**. Die Ergebnisse gelten für den Streaming-Messbericht mit sieben Beispielen, einem frisch gestarteten Prozess und warmen Dateicaches. [Einzelzeiten](messung.json) · [Versuchsplan](versuchsplan.json)

| Aufruf | Vorher, Median / P95 | Nachher, Median / P95 |
|---|---:|---:|
| Installiertes `tide test` | 5,28 / 5,49 ms | 1,43 / 1,57 ms |
| CPython mit denselben sieben Fällen | 6,41 / 6,92 ms | 6,44 / 6,74 ms |
| `./tide test` im Quellcheckout, separate Reihe | 8,52 / 9,23 ms | 5,55 / 5,99 ms |

## Änderung und Vergleich

In einer Projektkopie leitete die exportierte Paketfunktion die gelesene Zeilennummer plus eins an die Ganzzahlprüfung weiter. Dadurch meldete der Bericht bei `80\nx\n` die ungültige Zahl auf Zeile 3. Die Änderung stellte in beiden Sprachen die Übergabe der tatsächlichen Zeilennummer wieder her. Die öffentliche Erwartung war Zeile 2. Die Projektquellen und Erwartungen der Anwendung dienten durchgehend als Referenz. [TIDE-Messbericht](../../apps/report_packages/stream_report.tide) · [Paket](../../apps/report_packages/vendor/measurements/1.3.0/package.tide)

Vor **jeder** Zeitmessung wurde die fehlerhafte Paketfassung gespeichert und ihr roter Test bestätigt. Die monotone Uhr lief vom Öffnen der temporären Datei für die Korrektur über Schreiben, Schliessen und atomare Umbenennung bis zum beendeten Testprozess mit verifizierter Ausgabe `{"passed":7}`. Es gab je Sprache sechs fachgleiche Reportfälle mit Eingaben im Speicher und ein direktes Paketbeispiel. Sie prüfen LF/CRLF, leere Eingabe, überschrittenes und negatives Budget, ungültige Zahlen mit Fehlerzeile und eine vorzeichenbehaftete Zahl mit führender Null. Beide Seiten führten die ganze Suite aus. [CPython-Fälle](python/test_report.py) · [Streaming-Referenz](python/report.py)

Nach acht Aufwärmblöcken folgten 64 Messblöcke mit je vier Läufen. Darin wechselten beide TIDE-Installationen und zwei Läufe derselben CPython-Fassung in ausbalancierter Reihenfolge. Damit hat jede TIDE-Fassung eine zeitlich benachbarte Python-Kontrolle. CPython startete mit `-E -S`, direktem Testskript und normalem Bytecode-Cache. Rote und grüne Quelldatei haben verschiedene Längen. Der geänderte Python-Import musste bei jedem Lauf neu übersetzt werden, auch bei gleichem Zeitstempel. Beide TIDE-Fassungen lasen die Paketquellen frisch. Alle Messungen liefen mit TIDE 0.6.2 und CPython 3.14.10 auf Kern 24 eines Ryzen 9 9950X3D unter Linux. Die Arbeitskopien lagen im warmen tmpfs. Korrektursuche, Werkzeugbau und Installation lagen ausserhalb des Intervalls. Die Messung lief ohne Netzwerk und Modellaufrufe. [Exakter Messablauf und Wiederholung](reproduktion.md)

## Engpass und Änderung

Im Ausgangsprofil dauerte der öffentliche Testaufruf **5,03 ms**. Der bereits vorhandene native Prüfer benötigte für das Laden desselben Paketgraphen, die Typprüfung und die sieben Beispiele zusammen **1,22 ms**. Rund drei Viertel der Zeit entfielen damit auf den Start und die Vorbereitung des Prüfers. Die Profilwerte stammen aus separaten Prozessläufen ohne Speichern und sind von den End-to-End-Werten oben zu unterscheiden. [Profilstichproben](messung.json)

Das installierte `tide test DATEI` startet jetzt direkt im nativen Prüfer. Er löst den Projektpfad und das nächste `tide.lock` auf, prüft den Pin gegen den aktuellen Operationskatalog und führt die Tests mit dem vorhandenen Projektlader aus. Die Änderung braucht weder Ergebnis-Cache noch einen dauerhaft laufenden Prozess. Bei unklarem Pfad oder Versionskonflikt übernimmt der bisherige Diagnoseweg. Weitere CLI-Befehle verwenden den vorhandenen Starter. Im Quellcheckout prüft `make` bei jedem Aufruf zusätzlich den Stand des Werkzeugbaus. Im Abschlussprofil dauerte der installierte Aufruf **1,24 ms**, der direkte Prüfer **1,21 ms**. [Native Einstiegspunkte](../../native/bootstrap/seed.tide) · [Pinprüfung](../../native/bootstrap/project.tide)

Die Weiterleitung anderer installierter Befehle hat einen kleinen messbaren Preis. In je 32 ergänzenden Messpaaren lag der Median für `tide --version` bei **1,96 → 2,13 ms**, für einen kurzen `tide run`-Aufruf bei **5,23 → 5,27 ms**. Die Rohdaten enthalten auch die jeweiligen P95-Werte. [Kontrollmessungen](messung.json)

## Abnahme

`make test` bestand. Bei 32 CLI-Kontrollen stimmten Exitstatus, stdout und stderr vor und nach der Änderung bytegenau überein. Geprüft wurden unter anderem falsche oder umsortierte Pins, der Vorrang eines Versionskonflikts vor einem Quellfehler, Unicode und Zeilenumbrüche im Pfad, Symlinks, ungültiges UTF-8, ein nicht beschreibbarer Ausgabekanal sowie erweiterte Testdiagnosen. Die installierte Fassung erkannte den eingebauten Paketfehler und bestand nach der Korrektur alle sieben Beispiele auch in einem isolierten Dateisystem ohne Python, Shell und Compiler. [Prüfergebnisse](messung.json)
