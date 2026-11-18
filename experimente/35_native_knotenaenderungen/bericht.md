# Einen TIDE-Ausdruck in einer Projektdatei ändern

Der native Editor übernimmt gezielte Änderungen an einer Einstiegsdatei oder einem ihrer importierten Module. Ein Agent liefert die Projekt-Revision, eine Knotenkennung aus `context` oder `hole` und den neuen Operator oder Ausdruck. Der TIDE-Prüfer kennt an dieser Stelle auch die lokalen Namen einer Faltung, einer Bindung oder einer Regel. Er prüft alle Beispiele des Projekts vor der Übernahme. [Editor](../../native/bootstrap/node_edits.tide) · [Transaktion](../../native/bootstrap/editor_transaction.tide)

## Neuaufbau ohne Python am 17. November 2026

In einem isolierten Linux-x86-64-Dateisystem lagen nur die produktiven Quellen, die Buildregeln, der Starter und die Systemwerkzeuge für den Build. Das Buildverzeichnis war leer. Python-Interpreter, Standardbibliothek, gemeinsame Python-Laufzeit und Experimentarchiv standen dem Build und dem installierten TIDE nicht zur Verfügung. Dort bestanden `make check-native` und `make install`, einschließlich des byteweisen Selbstbauvergleichs und der TIDE-Prüfungen für Compiler, Editor, Nano und Space Invaders. Alle zwölf gespeicherten ELF-Prüfsummen für die sechs Beispielprogramme stimmten. Die sechs installierten Werkzeuge waren bytegleich mit denen eines zweiten lokalen Builds. Sowohl der Checkout als auch der installierte Starter ergaben beim Saldo `97`. Beim Upgrade verschwanden elf nachgebildete alte Python-Module, elf Bytecode-Dateien und die beiden früheren Starter. Eine zusätzlich angelegte fremde Datei blieb erhalten. [Buildregeln](../../Makefile) · [Prüfsummen und Rohdaten](pruefung.json)

`make test` enthält jetzt eine vom Build erzeugte temporäre Saldodatei, die der Editor tatsächlich über einen Knoten ändert und die der Prüfer danach erneut testet. Weitere dauerhafte Tests prüfen die Quellgrenzen gruppierter und mehrzeiliger Ausdrücke einschließlich eines parameterlosen Aufrufs in einem importierten Modul, Unicode, CRLF und mehrere Änderungen mit versetzten Quelllängen. Für `play`, allgemeine Datei-Leserechte und weitere Werttypen fehlen weiterhin öffentliche native Operationen. Beim interaktiven Start meldete die Installation `E_BACKEND`. [Editorprüfungen in TIDE](../../native/bootstrap/editor_checks.tide)

## Was bei einer Reparatur kleiner wird

Vier Projektkopien enthielten jeweils einen absichtlich falschen Ausdruck. Vor der Messung schlugen ihre Beispiele fehl, nach der Übernahme bestanden sie. Für die beiden Methoden im selben Projekt waren Kandidatenbytes und sämtliche Antwortfelder identisch. Die Tokens in der Tabelle zählen den Inhalt, den ein Agent zur Änderung liefern muss. Befehlsoptionen, Kontextabfrage, Modellüberlegungen und mögliche Fehlversuche sind darin nicht enthalten. Jede Zeit ist der Median von 15 Aufrufen des installierten Werkzeugs mit `--write` nach drei Aufwärmrunden. Die Methoden wechselten die Reihenfolge auf demselben CPU-Kern. [Einzelzeiten für Vorschau und Schreiben](pruefung.json)

| Reparatur | Vollständige Datei | Knotenänderung | Zeit mit Datei | Zeit mit Knoten |
|---|---:|---:|---:|---:|
| Saldo, Subtraktion zu Addition | 120 Tokens | 12 Tokens | 7,67 ms | 7,69 ms |
| Rangfolge, bei Gleichstand wieder `on_equal` verwenden | 312 Tokens | 14 Tokens | 8,23 ms | 8,40 ms |
| Bericht mit Import, negative Werte bei null begrenzen | 240 Tokens | 13 Tokens | 8,42 ms | 8,47 ms |
| Vom Bericht aus die Addition im Modul korrigieren | – | 17 Tokens | – | 8,37 ms |

Beim letzten Fall bezeichnet `adjustment.tide:2:1` das Ziel. `--source` ersetzt am selben Projekteinstieg die Einstiegsdatei, deshalb gibt es für diesen Fall keinen gleichwertigen Zeitvergleich. Die drei direkten Vergleiche zeigen deutlich weniger übertragene Tokens und einen kleinen zeitlichen Mehraufwand für die Knotenänderung. Beide Vorschauen enthalten weiterhin die vollständige Kandidatendatei. Eine neue blinde Modellreparatur oder ein Geschwindigkeitsvergleich mit Python war nicht Teil dieser Messung.

## Abnahme von Änderungen und Fehlerfällen

- 236 verschiedene Knoten in neun Projekten erhielten jeweils einen Auftrag für einen Ausdruck und für einen Operator. Weitere Fälle umfassten fehlerhafte JSON-Eingaben, Stelligkeit, Typfehler, Revisionskonflikte, unzulässige Überlappungen, Zugriffe auf lokale Namen und den Schreibzustand beider Dateien bei einer Moduländerung. Ein Auftrag mit 256 verschiedenen Änderungen in umgekehrter Quellreihenfolge bestand.
- Von insgesamt 567 Fällen stimmten 562 mit dem historischen Editor überein. Bei fünf Ersetzungen ganzer `fold`-Ausdrücke bricht dieser mit einem internen Fehler ab. In diesen fünf Fällen wurden die vollständigen erwarteten Quellbytes separat aus dem ursprünglichen Tokenbereich bestimmt und mit der nativen Vorschau verglichen. Alle fünf bestanden. Der Referenzeditor lief ausschließlich außerhalb der isolierten TIDE-Installation.
- In zwölf Gruppen mit jeweils acht gleichzeitigen Schreibern auf dasselbe importierte Modul wurde genau eine Änderung übernommen. Die anderen 84 meldeten `E_REVISION`. Einstiegsdatei, Dateirechte und die nachgelesene Projekt-Revision wurden in jeder Gruppe geprüft.
- Die 176 Vergleiche für vollständige Quelldateien und die 1.950 bisherigen Vergleiche für Funktionen, Regeln, Listen, Inspektion und Diagnosen bestanden erneut. [Fallzahlen, Einzelmessungen und Revisionen](pruefung.json)
