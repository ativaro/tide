# Messbericht vorab übersetzen

`tide build --aot` übersetzt den geprüften Messbericht und seine importierten Funktionen in eine eigenständige Linux-x86-64-Datei. Der Build enthält alle geprüften Quelldefinitionen, die vom gewählten Einstieg erreichbar sind. Das Programm bindet die Datei und den Grenzwert wie `tide run`. [Übersetzer in TIDE](../../native/bootstrap/aot.tide) · [Laufzeit in TIDE](../../native/bootstrap/aot_runtime.tide)

```sh
./tide build --aot apps/report.tide /tmp/tide-report
printf '80\r\n81\r\n98\r\n' > /tmp/tide-werte.txt
/tmp/tide-report --read input=/tmp/tide-werte.txt --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

## Abnahme

13 Fälle lieferten beim Projektauswerter, beim übersetzten Programm und bei der externen CPython-Referenz denselben Status sowie bytegleiche Standardausgabe und Fehlerausgabe. Darunter sind leere Dateien, beide i64-Grenzen, ungültige Zeilen, ungültiges UTF-8, fehlende Dateien und die Grenze von 128 KiB. Der Fall mit exakt 100.000 Arbeitsschritten besteht. Der zusätzliche Schritt meldet bei beiden TIDE-Pfaden `E_LIMIT` an `readings.tide:5:51`. Ein separater TIDE-Prüffall schöpft mit wiederholten Lesezugriffen genau 4 MiB Gastspeicher aus. Ein zusätzliches Zeichen überschreitet das Budget am betreffenden `read`.

83 zusätzliche lokale Vergleiche zwischen den beiden TIDE-Pfaden prüften gemischte LF- und CRLF-Eingaben, freigegebene Pfade mit Unicode und Gleichheitszeichen, Daten nahe der Arbeitsgrenze und Fehler bei JSON-Eingabe und Rechtebindung. Die drei Prozesskanäle stimmten jeweils überein. `make test` und `make check-no-python` bestanden. In der isolierten Paketabnahme läuft das statisch gelinkte Programm ohne Projektquellen oder Compiler. [Paketabnahme](../../native/bootstrap/no-python.Dockerfile)

## Laufzeit gegen CPython

Median vom Programmstart bis zur vollständigen JSON-Ausgabe in Millisekunden. Der Faktor ist der Median der gepaarten Quotienten. CPython 3.14.10 lief mit `-S`, also ohne Laden des `site`-Moduls.

| Zeilen | TIDE vorab übersetzt | TIDE `run` | CPython | Faktor gegen CPython |
|---:|---:|---:|---:|---:|
| 3 | 0,330 | 4,823 | 10,362 | 31,4× |
| 512 | 0,376 | 13,891 | 10,563 | 28,0× |
| 2.048 | 0,562 | 41,803 | 11,311 | 20,1× |
| 3.400 | 0,669 | 65,781 | 11,926 | 18,0× |

Die warme Messung beginnt bei denselben bereits getrennten Textzeilen. Sie umfasst den Rechenkern mit Arbeitsbudget, ohne Dateizugriff, Prozessstart oder JSON-Ausgabe. Bei 2.048 Zeilen waren es **85,1 µs gegenüber 712,2 µs**. Über alle vier Grössen lag TIDE in dieser Messung **6,3–8,4×** vor CPython.

Die Messreihen verwenden je 31 gepaarte Stichproben nach fünf Aufwärmrunden auf CPU-Kern 2. Pro warmer Stichprobe laufen 96 Berechnungen. Die Reihenfolge der Werkzeuge wechselt. Alle Ausgaben wurden mit unabhängig berechneten Sollwerten verglichen. Der ausgelieferte Build dauerte mit vorbereitetem Paket und GCC 16.2.1 **16,98 s**. Diese Zeit ist separat ausgewiesen. [Rohzeiten und Fehlerbefunde](messung.json)

Der CPython-Vergleich verwendet dieselben Regeln für Zahlen, Zeilentrenner, Lesebudget und die beobachtbare Arbeitsgrenze dieses Programms. Das Gastspeicherbudget ist beim Messbericht unter den Eingabegrenzen unerreichbar und wird mit der separaten TIDE-Fixture geprüft. Die Messung qualifiziert die gezeigte Anwendung. Das 100×-Laufzeitziel gegen CPython wurde hier nicht erreicht. Es gab keine Modellläufe.

Die Messung lässt sich mit `PYTHONDONTWRITEBYTECODE=1 python3 -S experimente/53_vorabuebersetzung/measure.py` lokal wiederholen. CPython wird dabei nur für diesen externen Vergleich verwendet. [Vergleichsprogramm](cpython_report.py) · [Messablauf](measure.py)
