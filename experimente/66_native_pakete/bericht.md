# Der Messbericht mit zwei versionierten Paketen

Die Paketfassung des Messberichts ruft `rowtext.parse` aus `rowtext@2.0.0` und `measurements.parse` aus `measurements@1.3.0` auf. Das erste Paket teilt UTF-8-Text in Zeilen, das zweite prüft und liest eine i64-Messzahl. Beide deklarieren `export parse`. Die Hilfsfunktion `measurements.decode_measurement` bleibt paketintern. Die Revision erfasst die aufgelösten Paketpfade und deren Inhalte. [Messbericht](../../apps/report_packages/report.tide) · [Modulregeln](../../LANGUAGE.md#versionierte-pakete)

| Zeilen | TIDE vorab übersetzt Median / P95 | TIDE Quellmodus Median / P95 | CPython Median / P95 | AOT-Faktor, gepaarter Median |
|---:|---:|---:|---:|---:|
| 4 | 0,585 / 0,668 ms | 5,637 / 6,011 ms | 10,517 / 10,876 ms | 17,91× |
| 512 | 0,636 / 0,833 ms | 14,608 / 15,088 ms | 10,859 / 11,368 ms | 16,63× |
| 2.048 | 0,847 / 0,994 ms | 41,740 / 42,113 ms | 11,498 / 12,048 ms | 13,39× |
| 3.072 | 0,929 / 1,053 ms | 59,695 / 60,386 ms | 11,817 / 12,175 ms | 12,66× |

Der AOT-Build dauerte separat 18,06 s. Der Quellmodus umfasst Auflösung, Quellprüfung und Ausführung pro Aufruf. Ab 512 Zeilen war CPython gegenüber diesem Modus schneller. [Einzelzeiten und Rohdaten](messung.json)

## Abnahme und Vergleichsbedingungen

Die drei Varianten bestanden dieselben 13 Abnahmefälle. Die erfolgreichen Ergebnisse stimmen bytegenau überein. Bei Fehlern stimmen Rückgabestatus, Fehlercode und, soweit vorhanden, fachlicher Fehlergrund und Eingabezeile überein. Darunter sind leere Dateien, LF und CRLF, beide i64-Grenzen, ungültige Zahlen und UTF-8, fehlende Leserechte sowie das Datei- und Zeilenlimit. Die TIDE-Quellpositionen sind in den Rohdaten enthalten. TIDE behält seine eigenen Arbeits- und Speicherbudgets. [Rohdaten mit Diagnosen](messung.json)

Gemessen wurde die Zeit vom Start eines frischen Prozesses bis zur vollständigen JSON-Ausgabe. Die Eingaben und der Grenzwert waren identisch. Die Python-Fassung verwendet ebenfalls zwei lokale Pakete, prüft deren erwartete Versionen beim Start und lief mit `-E -S` und vorbereitetem Bytecode. Die Messreihe verwendet je 31 Läufe pro Grösse und Variante nach fünf Aufwärmrunden, eine wechselnde Reihenfolge und warme Dateicaches. Gemessen wurde auf CPU 24 eines Ryzen 9 9950X3D mit TIDE 0.6.1, CPython 3.14.10 und GCC 16.2.1. Die Prozesse liefen lokal ohne Netzwerk und ohne Modellaufrufe. [Versuchsplan](versuchsplan.json) · [TIDE-Messdatensatz](messdaten.tide) · [Externer Python-Vergleich](python/report.py)

`make test` bestand. Die CLI-Prüfungen deckten private Aufrufe, unbekannte Exporte, Versionskonflikte, falsche Paketköpfe, transitive Sichtbarkeit, Importzyklen und einen Symlink im Abhängigkeitspfad ab. Ein zusätzlicher nativer Test verwendet zwei gleichnamige exportierte Recordtypen und interne Nachbardateien. Die beiden Recordtypen wurden auch in einer AOT-Prüfung gemeinsam übersetzt und ausgeführt. Ein exportierter Regelname wurde mit `scan` aufgerufen. Die Editier-Vorschau einer Paketdatei behielt den Projektvertrag und bestand alle Beispiele. Ein Schreibversuch über das importierende Projekt und ein AOT-Zielpfad auf einer Paketquelle wurden abgewiesen. Die installierte Paketfassung und das eigenständige AOT-Programm bestanden die Messberichtprüfung in einer Umgebung ohne Python.

Das Paketmodell nutzt lokale Quellen und eine exakte Version pro Paketname. Die Geschwindigkeitszahlen gelten für die vier Dateigrössen und den gemessenen Start-bis-Ausgabe-Ablauf.
