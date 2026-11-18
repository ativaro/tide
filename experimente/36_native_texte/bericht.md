# TIDE ohne Python an Nano und der Reparaturwerkbank

Am 17. November 2026 lieferte die bisherige native Installation für Nanos Zeilensuche noch `E_BACKEND`. Jetzt laufen alle vier Cursorfunktionen als eigenes TIDE-Modul im öffentlichen Projektauswerter. Nano importiert dieselben Funktionen. Die Werkbank kann ebenfalls über `tide run` erkennen, ob eine Quellzeile die gesuchte Funktion deklariert. [Cursormodul](../../apps/cursor.tide) · [Quelltextfunktionen der Werkbank](../../workbench/source_layout.tide)

```sh
./tide run apps/cursor.tide --call line_limit --inputs '{"body":"🐈\r\nΩ","pos":0}'
./tide test apps/cursor.tide
./tide test native/bootstrap/fixtures/functions/text.tide
./tide test workbench/source_layout.tide
```

Der erste Aufruf ergibt `1`. Die drei Tests melden fünf, zehn und zwei bestandene Beispiele. Der Prüfer kennt Texte sowie Listen und Optionen über ganzen Zahlen, Wahrheitswerten und Texten. Die Zeichensuche zählt Unicode-Codepunkte. Eine Suche ohne Treffer liefert eine leere Option. `need` kann daraus einen Datenfehler mit Grund und Eingabezeile machen. Nanos Cursor behandelt CRLF als einen Zeilenwechsel. [Textbeispiele](../../native/bootstrap/fixtures/functions/text.tide) · [Typprüfung](../../native/bootstrap/functions.tide) · [Auswertung](../../native/bootstrap/function_run.tide)

## Neuaufbau ohne Python

Der Linux-x86-64-Build startete in einem leeren Verzeichnis. Ein eigener Mount-Namensraum enthielt die produktiven TIDE-Quellen, Make, die Systemwerkzeuge und GCC 16.2.1. Interpreter, Python-Standardbibliothek, nutzbare gemeinsame Python-Laufzeit und Experimentarchiv waren ausgeblendet. Darin liefen `make check-native` und eine Installation in ein temporäres Präfix. Der Bootstrap benötigt einen C++20-Compiler.

Alle sechs installierten Werkzeuge waren statisch gelinkt und bytegleich mit einem unabhängig gebauten zweiten Paket. Für sechs Anwendungen stimmten alle zwölf hinterlegten ELF-Prüfsummen. Checkout und installiertes Werkzeug berechneten beim Saldo `97`. Beim Upgrade verschwanden elf alte Python-Module mit ihren elf Bytecode-Dateien und die beiden früheren Starter. Eine fremde Datei im alten Paketverzeichnis blieb erhalten. Die archivierte Referenz wird ausschließlich für externe Vergleiche verwendet. [Buildregeln](../../Makefile) · [Einzelwerte und SHA-256-Prüfsummen](pruefung.json)

## Laufzeit

Gemessen wurde die Zeit vom Start des Prozesses bis zu seinem Ende auf einem AMD Ryzen 9 9950X3D, gebunden an den logischen Kern 2. In der ersten Serie liefen das installierte `tide run` und ein eigenständiges Programm unter CPython 3.14.10 mit `-I -S`. Beide lasen dieselben JSON-Argumente und lieferten in jedem Durchgang dasselbe Ergebnis. Pro Aufgabe wechselte die Reihenfolge. Die Tabelle zeigt den Median aus 21 Durchgängen nach drei Aufwärmrunden. Beim Saldo prüfte auch Python jede Addition auf i64-Überlauf. TIDE lud und prüfte bei jedem Start die Programmquelle. Gemessen wurden gültige Eingaben.

| Aufgabe | Eingabe und Ergebnis | TIDE | CPython | Zeit CPython / TIDE |
|---|---|---:|---:|---:|
| Zeilenende im Nano-Dokument | `🐈\r\nΩ`, ab Position 0 → 1 | 5,50 ms | 9,06 ms | 1,65× |
| Letzte Fundstelle | `a猫` 10.000-mal, danach `Z` → Position 20.000 | 7,69 ms | 9,23 ms | 1,20× |
| Saldo | Anfang 0 und 4.096 Buchungen zu je 1 → 4.096 | 6,42 ms | 9,29 ms | 1,45× |

Die zweite Serie verglich verschiedene Stände des TIDE-Werkzeugs. Je Stand und Aufgabe gab es neun gemessene Aufrufe nach zwei Aufwärmrunden in wechselnder Reihenfolge. Die historische Referenz ist der frühere TIDE-Interpreter auf CPython. Ihr Start und ihre Projektprüfung gehören hier zur gemessenen Arbeit.

| Aufgabe | Erster Stand mit Textwerten | Optimierter Stand | Historische TIDE-Referenz |
|---|---:|---:|---:|
| Letzte Fundstelle unter 20.001 Zeichen | 18,11 ms | 7,69 ms | 29,25 ms |
| 100 Zeichen aus einer Eingabe mit 60.000 Zeichen | 12,10 ms | 8,31 ms | 29,23 ms |
| Saldo mit 4.096 Buchungen | 14,05 ms | 6,47 ms | 33,35 ms |
| Kontext mit großem Unicode-Beispiel | 72,34 ms | 68,89 ms | 29,18 ms |

Die JSON-Bindung übernimmt zusammenhängende Textabschnitte gemeinsam. Für einfache Zahlenoperationen in einer Faltung liest der Auswerter die typisierten Operanden direkt. Damit sank der große Saldo auch gegenüber dem nativen Stand vor der Texterweiterung von 11,55 auf 6,47 ms. Als Gegenprobe blieben die Diagnosen und die Arbeitsgrenze von 100.000 Schritten Teil der Tests.

Beim großen Beispielvertrag enthielten Eingabe und Erwartungswert jeweils 7.000 Wiederholungen von `🐈a`. Für diese Kontextabfrage brauchte das native Werkzeug 2,36-mal so lange wie die historische TIDE-Referenz. In zwölf separat profilierten Aufrufen entfielen 55 % der 0,29 Sekunden erfasster CPU-Zeit auf `sha_mask12` in der SHA-256-Verarbeitung. Die einzelnen Laufzeiten und der vollständige Text der eigenständigen CPython-Vergleichsfassung stehen in den [Messdaten](pruefung.json).

## Funktionsprüfung und Grenzen

- 553 Vergleiche prüften Werte, Fehler, Typen, Knotenpositionen, lokale Bindungen und Beispielverträge. Weitere 77 Fälle prüften unter anderem Faltungen, Ressourcenlimits, fehlerhafte Eingaben und Escape-Sequenzen. Beide Serien stimmten mit der historischen Sprachreferenz überein. Dauerhafte TIDE-Tests prüfen auch 4.096 und 4.097 Textzeilen sowie beide Seiten der Speichergrenze bei Verkettungen. [Prüfungen in TIDE](../../native/bootstrap/checks.tide)
- Von 1.041 Knotenänderungen stimmten 1.032 mit dem historischen Editor überein. Bei neun vollständigen Faltungen bricht dieser mit einem internen Fehler ab. Für diese neun wurde separat geprüft, dass die nativen Kandidatenbytes genau den erwarteten Quellbereich ersetzen. Hinzu kamen 176 Vergleiche für Änderungen ganzer Dateien.
- Die 1.950 Fälle der bisherigen Funktions-, Listen-, Regel- und Inspektionsserien wurden erneut ausgeführt. Bei einem fehlerhaften JSON-Argument meldete das frühere native Paket pauschal `E_BACKEND`. Das neue Paket meldete wie die historische Sprachreferenz `E_JSON` an Zeichenposition 4106. Die übrigen 82 Fälle dieser Gruppe für Array-Argumente behielten das bisherige Verhalten.

Der interaktive Start von Nano und Space Invaders benötigt native Tastatur-, Bildschirm- und Dokumentoperationen. Der installierte Befehl `tide play` meldete dafür `E_BACKEND`. Weitere offene Teile des öffentlichen Auswerters sind verschachtelte Datenformen, Records und Varianten als Laufzeitwerte sowie Dateileserechte. Die Textmessungen betreffen den Projektaufruf `tide run`. Die Reparaturzeit eines Agenten und sein Tokenverbrauch wurden in diesem Versuch nicht erhoben.
