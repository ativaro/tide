# Gegenbeispiele nach erschöpftem festem Pool erzeugen

Mit festem Pool bestanden TIDE und Python-AST je **12/60 Reparaturen (20 %)**. Mit Erzeugung bestanden beide **60/60 (100 %)**. Die 48 zuvor offenen Läufe je Verfahren betrafen vier Aufgaben mit absichtlich schlecht trennenden Pools. TIDE brauchte mit Erzeugung im gepaarten Median 47,3 ms weniger und war in allen 60 Paaren schneller. Der Median der gepaarten Zeitfaktoren beträgt **2,33×**. Keine Variante rief ein Modell auf. [Einzelzeiten und Rohdaten](messung.json)

| Ergebnis je Verfahren | Läufe | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Fester Pool, Reparatur bestanden | 12 | 33,2 / 37,3 ms | 81,9 / 87,9 ms |
| Fester Pool, ohne Gegenbeispiel beendet | 48 | 12,0 / 13,8 ms | 23,5 / 25,9 ms |
| Mit Erzeugung, alle Reparaturen | 60 | 36,2 / 48,3 ms | 82,0 / 107,4 ms |
| Davon erst durch Erzeugung gelöst | 48 | 36,6 / 49,0 ms | 83,4 / 108,1 ms |

## Welche Eingaben die Paare trennten

Die fünf Programme und ihre öffentlichen und verdeckten Prüffälle stammen aus Versuch 62. Für Versandetiketten und Nettogewicht enthält der feste Pool nur Eingaben mit `a = b`. Beim Taktfenster liegen seine Eingaben oberhalb des Fensters. Bei der Restladung sind Quotient und Rest im gesamten festen Pool gleich. Beim Lackbedarf trennt der feste Pool die Paare bereits. Die Pilotläufe bestätigten die Ausgangslage auf beiden Seiten. [Feste Pools in TIDE](pool.tide) · [Quellen und Vertrag](../62_mehrdeutige_paare/bericht.md)

| Aufgabe | Geprüfte feste Eingaben bis zur ersten erzeugten Eingabe | Gegenbeispiel `(a, b) → Sollwert` | Grüne Paare je Runde | TIDE Median mit Erzeugung | Python-AST Median mit Erzeugung |
|---|---:|---|---:|---:|---:|
| Versandetiketten | 16 | `(0, 1) → 0` | 6 → 1 | 37,7 ms | 83,3 ms |
| Nettogewicht | 16 | `(0, 1) → -1` | 6 → 1 | 33,9 ms | 80,1 ms |
| Taktfenster | 16 | `(48, 48) → -99`, dann `(1, 5) → 1` | 6 → 3 → 1 | 46,2 ms | 105,0 ms |
| Restladung | 32 | `(48, 48) → 0` | 2 → 1 | 34,4 ms | 81,5 ms |
| Lackbedarf | — | `(1, 1) → 1` aus dem festen Pool | 2 → 1 | 32,4 ms | 80,2 ms |

Beide Verfahren fanden dieselben trennenden Eingaben und dieselben Kandidatenausgaben. Der gemeinsame, unabhängige TIDE-Vertrag bestätigte den Sollwert. Jede bestätigte Eingabe lag ausserhalb der 72 verdeckten Fälle ihrer Aufgabe. Nach der Übernahme der beiden gemeinsam geprüften Dateien bestanden alle erfolgreichen Reparaturen die öffentlichen und die 72 unveränderten verdeckten Fälle. [Rohdaten mit Suchrunden und Kandidaten](messung.json)

## Ablauf und Messbedingungen

`--probe-range '{"a":[0,96],"b":[1,96]}'` gibt bei TIDE den gültigen Suchbereich an. Nach dem festen Pool probieren beide Verfahren dieselbe Folge von Mittelpunkten, Randwerten, Nachbarn des fehlgeschlagenen Beispiels und gemischten Eckpunkten. Die Erzeugung überspringt die öffentlichen Beispiele und bereits geprüfte Eingaben. Pro Suchstufe gelten 32 Eingaben und 128 Kandidatenauswertungen. Der Suchraum der Änderungen umfasst pro Runde bis zu 32 Einzeländerungen und 64 Paare. [Versuchsplan](versuchsplan.json) · [Python-AST-Vergleich](cpython_probes.py) · [Aufruf in der Werkbank](../../workbench/README.md#eingaben-für-grüne-paare-erzeugen)

Gemessen wurde vom Beginn der Pool-Erstellung bis zur unabhängigen Abnahme oder zum Abbruch. Die Zeit schliesst Erzeugung, Suche, Bestätigung, weitere Vorprüfungen, Patch und Abnahme ein. Je Aufgabe und Modus liefen zwölf Messpaare mit wechselnder Reihenfolge und frischen Prozessen. TIDE 0.6.1 und CPython 3.14.10 nutzten denselben logischen Kern eines Ryzen 9 9950X3D und warme Dateicaches. Die Messung lief lokal ohne Netzwerk. Beide Verfahren verbrauchten in beiden Modi jeweils 0 Modelltokens.

`make test` bestand. Das installierte TIDE-Paket erzeugte das Gegenbeispiel auch in einem Dateisystem ohne Python. Die Erzeugung ist eine begrenzte Suche in angegebenen Ganzzahlspannen. Ihr Ergebnis enthält beobachtete Kandidatenausgaben. Für die Auswahl bleibt ein unabhängig bestätigter Sollwert erforderlich. Die Erfolgssteigerung bezieht sich auf die fünf Aufgaben und die gezielt schlecht trennenden Pools dieses Versuchs.
