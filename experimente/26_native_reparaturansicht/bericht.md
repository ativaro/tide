# Geklammerte Funktionsrümpfe in einem Durchlauf

Bei Space Invaders sank die Vorbereitungszeit für den Reparaturkontext von 1.214 auf 211 ms. Die Stapelabfrage in TIDE erzeugte in allen vier Projekten byteweise dieselbe Ansicht wie der bisherige Ablauf mit einem Referenzprozess je Funktion.

| Projekt | Funktionen | Bisher, ganze Ansicht | Stapelabfrage, ganze Ansicht | Faktor je Messpaar, Median |
|---|---:|---:|---:|---:|
| Jury | 5 | 310 ms | 146 ms | 2,15× |
| Depot | 5 | 310 ms | 144 ms | 2,16× |
| Nano, step | 14 | 665 ms | 167 ms | 3,96× |
| Space Invaders, tick | 26 | 1.214 ms | 211 ms | 5,78× |

Je Projekt gab es zwei Aufwärmpaare und zwölf Messpaare mit wechselnder Reihenfolge. In allen 48 Messpaaren war der neue Ablauf schneller. Allein für die Funktionsabfragen sank der Median bei Jury von 173 auf 8 ms und bei Space Invaders von 1.031 auf 27 ms. Beide Seiten verwenden denselben überarbeiteten Planer. Zuvor überschritt der Plan für Space Invaders das reguläre Arbeitsbudget. Die Laufzeiten in der Tabelle beginnen bei bereits gebautem Werkzeug. Der erste Aufruf mit leerem Buildverzeichnis einschließlich Selbstbau bis zur Ausgabe der Jury-Funktionen dauerte 5,02 s. [Versuchsplan](versuchsplan.md) · [Einzelmessungen, Prüfsummen und Messbefehle](messung.json)

Bei 33 Quellpaketen stimmten alle 661 gerenderten Funktionsrümpfe mit dem Referenzparser überein. Mehrfach importierte Funktionen werden dabei mehrfach gezählt. Ein zusätzlicher Test prüft einen Ausdruck mit geschützten und ideografischen Leerzeichen, Umlaut und Emoji. Bei sieben ungültigen UTF-8-Bytefolgen lieferte der öffentliche Befehl Status 1, die Diagnose E_UTF8 und eine leere Standardausgabe. Die Werkbank verwendete bei einer gültigen, 4.202 Codepunkte langen Quellzeile den bisherigen Rückfallpfad und lieferte denselben Rumpf. [Differentialprüfung und Isolationsprotokoll](pruefung.json)

Der Neuaufbau, fünf Stapelabfragen, der Selbstbautest, alle 14 Hilfeseiten und der Build von zwölf Anwendungsdateien liefen in einem Mount-Namensraum ohne Python und ohne Referenzstarter. Die zwölf ELF-Dateien stimmten mit den früher gespeicherten SHA-256-Werten überein. Das installierte native Paket baute Saldo und Licht auch in einem schreibgeschützten Präfix ohne Make, C++-Compiler und Python. Beim reinen Gruppierungswerkzeug genügten das statische Programm und die Standardeingabe in einem ansonsten leeren Dateisystem. Zusätzlich bestanden im regulären Checkout die 35 historischen Integrationstests.

Der Versuch misst die lokale Vorbereitung. Die gesamte Reparaturzeit eines Modells, die verbrauchten Modell-Tokens und der Vergleich gegen den Python-Entwicklungsablauf wurden in diesem Versuch nicht neu gemessen.
