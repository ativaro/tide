# Grüne Reparaturkandidaten am Zwischenmodul prüfen

**Die direkte Modulprüfung erhöht die Erfolgsquote bei TIDE und Python-AST von 6/10 auf 9/10.** Bei Schnittliste, Bandadresse und Telemetrie bleibt jeweils genau eine öffentlich grüne Reparatur übrig. Sie korrigiert den Argumenttausch dort, wo die Zwischenfunktion ihre Bibliothek aufruft. Der Einstiegscode bleibt in allen drei Projekten gleich. Die zehn Aufgaben und ihre Eingaben stammen aus Versuch 70. [Auswertung](auswertung.json) · [Ausgangsprojekte](../70_strukturelle_reparatur/aufgaben.json)

| Messgrösse | TIDE, Vorprüfung nur am Einstieg | Python-AST, nur am Einstieg | TIDE, mit Modulvorprüfung | Python-AST, mit Modulvorprüfung |
|---|---:|---:|---:|---:|
| Erfolg am Einstieg **und** am Zwischenmodul | 6/10 | 6/10 | **9/10** | **9/10** |
| Protokolltokens für alle zehn Aufgaben | 3.589 | 3.884 | **3.555** | **3.808** |
| Davon auf bestandene Aufgaben entfallen | 2.070 | 2.147 | 3.256 | 3.484 |
| Alle Protokolltokens je bestandener Aufgabe | 598,2 | 647,3 | 395 | 423,1 |
| Zeit bis zur erfolgreichen Abnahme, Median | 15,12 ms | 29,35 ms | **16,61 ms** | **29,55 ms** |
| Zeit bis zur erfolgreichen Abnahme, 95. Perzentil | 18,83 ms | 30,56 ms | 26,24 ms | 31,21 ms |

Mit Modulvorprüfung lag TIDE in allen 108 erfolgreichen Messpaaren vorne. Der Median der gepaarten Verhältnisse Python-Zeit/TIDE-Zeit betrug **1,78**, das 25. und 75. Perzentil lagen bei **1,52 und 1,86**. Um den Zusatzaufwand der Prüfung zu schätzen, lassen sich die sechs schon vorher erfolgreichen Aufgaben direkt vergleichen. Auf diesen 72 Paaren erhöhte die Vorprüfung die Zeit im Median der Paardifferenzen um 0,97 ms bei TIDE und 0,08 ms bei Python. Die Zeit für die ungelöste Aufgabe ohne Kandidat betrug mit Modulvorprüfung 5,57 bzw. 17,90 ms. [Einzelzeiten und Blockreihenfolge](messung.json)

Über alle zehn Aufgaben benötigte TIDE mit Modulvorprüfung **253 Protokolltokens weniger als Python-AST (6,6 %)**. Die Summe setzt sich aus 3.237 Eingabe- und 318 Ausgabetokens für TIDE sowie 3.492 und 316 für Python zusammen. In beiden Sprachen schrumpfte das Gesamtprotokoll gegenüber der Vorprüfung nur am Einstieg, weil die Diagnose drei unpassende Alternativen aussortierte. Jede Aufgabe zählt einmal, einschliesslich der ungelösten. Die Zahlen entsprechen lokal mit Llama-BPE gezählten Nachrichten. Es gab null zusätzliche Modellläufe. [Vollständige Protokolle](protokolle.json)

## Die drei korrigierten Argumenttauschfehler

| Projekt | Direkt geprüfter Aufruf | Frühere Auswahl | Neue Auswahl | Geprüfte Einzeländerungen / Paare in beiden Varianten |
|---|---|---:|---:|---:|
| [Schnittliste](repariert/cut/route.tide) | `samples(begin=3, finish=4, rate=4)` | −4 | **4** | 12 / 0 |
| [Bandadresse](repariert/tape/route.tide) | `address(bank=0, track=0, sector=1)` | 100 | **1** | 24 / 0 |
| [Telemetrie](repariert/telemetry/route.tide) | `adjust(label="A1", inbound=1, outbound=0)` | 1 | **3** | 11 / 35 |

Die Schnittliste ruft jetzt `span begin finish` auf, die Bandadresse `decimal_address bank track sector`. In der Telemetrie werden die Zähler bei `difference inbound outbound` richtig übergeben und die Kennung in der Bibliothek als UTF-8-Bytes gezählt. Die Einzelauswahl und das aus zwei Dateien bestehende Telemetrie-Paar wurden als ausführbare TIDE-Projekte gespeichert. Jedes Projekt enthält acht öffentliche Einstiegs- und acht öffentliche Modulbeispiele. Die drei Projekte bestanden auch mit der installierten TIDE-CLI in einem isolierten Dateisystem ohne Python. [Telemetrie-Bibliothek](repariert/telemetry/rulebook.tide) · [Frühere direkte Gegenbeispiele](../70_strukturelle_reparatur/modulabnahme.json)

Bei den sechs schon korrekten Aufgaben blieb der gewählte Patch gleich. Beim Paketfilter `flag` fand keines der Werkzeuge eine Änderung für den Vergleich unabhängig von ASCII-Gross-/Kleinschreibung. Über alle zehn Aufgaben blieben die Kandidatenbudgets und die Zahl geprüfter Einzeländerungen und Paare gleich. [Ergebnisse je Aufgabe](auswertung.json)

## Was beide Verfahren sehen

Für diese zehn Projekte legt der Versuchsplan die Zwischenfunktion explizit fest. Der originale Einstieg reicht seine benannten Argumente unverändert weiter, und beide Schnittstellen sollen dasselbe fachliche Ergebnis liefern. Darum lassen sich dieselben öffentlichen Eingaben und Sollwerte an beiden Schnittstellen verwenden. In einem Projekt mit eigenen Einheiten, Parametern oder einer Transformation braucht das Zwischenmodul fachlich passende Beispiele. [Zielzuordnung und Versuchsplan](versuchsplan.json)

TIDE nutzt reguläre `example`-Deklarationen in `route.tide`. Die native Kandidatensuche und der Editor prüfen diese Beispiele zusammen mit den Einstiegsbeispielen für jede sonst bestandene Einzeländerung und jedes Paar. In der CPython-Referenz erhält dieselbe AST-Suche aus Versuch 70 ein zweites Prüfziel. Sie ruft die Funktion aus dem Zwischenmodul des jeweiligen Kandidaten direkt auf. Beide Seiten sehen zuerst die acht öffentlichen Einstiegsfälle und dann dieselben acht am Zwischenmodul. Nur vorgeprüfte Kandidaten werden angeboten. Die Wahlregel und die Grenzen von 32 Einzelprüfungen und 64 dateiübergreifenden Paaren bleiben gleich. [CPython-Prüfung](cpython_modul.py) · [Native Regression](../../native/bootstrap/inspection_checks.tide)

Die Endabnahme ist in **allen vier Armen identisch**. Nach der Übernahme liest ein frischer Prozess die gespeicherten Module und prüft an beiden Zielen je acht öffentliche und 64 zurückgehaltene Fälle. Das sind 144 Aufrufe pro bestandener Reparatur. Die Reparatursuche erhält nur die öffentlichen Beispiele. Bei Fehlern endet die Abnahme mit der ersten Abweichung. Die drei früheren Aufrufer-Patches bestehen die 72 Einstiegsfälle und scheitern am Zwischenmodul. Der Versuch wiederholt gezielt die bekannte Stichprobe. [Prüffälle](prueffaelle.json) · [Hash-Fixierung](fixierung.json)

Pro Aufgabe und Arm gab es einen Aufwärmlauf und zwölf gemessene Durchgänge mit frischen Prozessen und Arbeitskopien. Jeder Arm belegte jede der vier Positionen im Block dreimal. Die Uhr lief von der Diagnose bis zur Abnahme oder zur Meldung ohne Kandidat, einschliesslich Suche und Übernahme. Die Vorbereitung der öffentlichen Testprojekte und die nachträgliche Tokenzählung lagen ausserhalb. TIDE verwendet `test/edit/test`, CPython einen Prozess zur Suche und Übernahme sowie einen zweiten zur Abnahme. Die Messung lief auf CPU 24 eines Ryzen 9 9950X3D mit TIDE 0.6.5, CPython 3.14.10 und ausschliesslich Loopback im Netzwerknamensraum. [Messprogramm](messen.mjs)

Der Tokenvergleich umfasst Auftrag, vollständige Ausgangsquellen, öffentliche Fälle, Prüfziele, ersten Fehler, Kandidatenangebot, Auswahl und Abschlussmeldung. Da beide Ziele dieselben Fälle verwenden, werden deren Daten in beiden Sprachprotokollen einmal mit den zugehörigen Zielnamen übertragen. Die Tokenisierung zählt die kompakten JSON-Nachrichten ohne Chat-Hüllen oder Spezialtokens. Tatsächlicher Modellverbrauch und Erfolgsquote auf neuen Aufgaben bleiben offen. [Gemeinsame Auswertung beider Versuche](../70_strukturelle_reparatur/auswerten.mjs)

## Lokal nachprüfen

Die gespeicherten Projekte lassen sich aus dem Repository direkt testen.

```sh
d="$PWD/experimente/71_modulvorpruefung"
for fall in cut tape telemetry; do ./tide test "$d/repariert/$fall/panel.tide"; done
```

Für die vollständige Zeitmessung erzeugen die folgenden Befehle eine lokale Installation. Der Lauf validiert die fixierten Dateien und ersetzt die Ergebnisdateien im Versuchsverzeichnis. CPU 24 muss auf dem ausführenden Rechner verfügbar sein, alternativ kann ein anderer einzelner verfügbarer Kern gewählt werden.

```sh
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev node "$d/messen.mjs" archive
```

Für die Offline-Auswertung zeigen `TOKENIZER_PYTHON` und `TOKENIZER_JSON` auf einen lokalen Interpreter mit `tokenizers` (hier 0.23.3) und das im Versuchsplan per SHA-256 bezeichnete Vokabular.

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/../70_strukturelle_reparatur/auswerten.mjs" "$d"
```
