# Was die Gruppierung beim Reparieren kostet und einspart

Beim ursprünglichen Gleichstand brauchte TIDE im gepaarten Median 6,92 Sekunden und 354 Gesamttokens mehr als Python, beim Runden 3,30 Sekunden und 265 Tokens mehr. Von insgesamt 42.080 zusätzlichen TIDE-Tokens dieser acht Paare entfielen 40.612 auf die beiden Paare mit einer erneuten Dateiliste. Die Denktoken-Mediane betrugen 572 gegenüber 256,5 beim Gleichstand und 357,5 gegenüber 138 bei der Rundung. Die Antworten enthielten wiederholte Feldzugriffe und fast unverändert wiedergegebene Faltungen. Wie viel Zeit eine einzelne Überlegung kostete, verraten die Zähler nicht. Der frühere Wechsel zu einem ausdrücklich geprüften Kontext beseitigte die wiederholten Inspektionen. [Ursprüngliche Messung](../15_gepaarte_reparaturen/bericht.md) · [Kontrollierte Wiederholung](../22_fragmentreparatur/bericht.md)

Die neue TIDE-Reparaturansicht belässt die vom Autor geschriebenen Klammern im Ausdruck. Die Werkbank verbindet Rumpfzeilen, behält Bindungen und Literale bei und verwendet denselben geprüften Aufrufgraphen und denselben Ersetzungsmechanismus wie die vollständig geklammerte Ansicht. Dadurch entfallen einzelne Compilerprozesse pro Funktion. Die begleitende Anweisung zur bereits geprüften Kopie ist kürzer. [Implementierung und Beispiele](../../workbench/source_repair.tide)

## Zwei neue Mehrdateienfehler

Bei der Jury müssen zwei unabhängige Ranglisten bei gleichen Hauptwerten die kleinste Ausweisnummer wählen. Eine verwendete den Termin als Nebenschlüssel, die andere wählte bei Gleichheit die größte Nummer. Beim Depot rundete eine Funktion eine halbe Einheit anhand der Parität des Rests. Eine zweite berechnete den Freibetrag über die ganze Lieferungsliste, obwohl er pro Lieferung gilt. Jede Familie umfasst vier Module. Öffentliche und verdeckte Eingaben sind getrennt. Die beiden Sprachen hatten vor der Reparatur, nach jeder einzelnen Referenzänderung und nach der vollständigen Korrektur auf jedem Fall dieselbe Ausgabe.

| Familie | Vorher öffentlich | Vorher verdeckt | Nach Referenzreparatur |
|---|---:|---:|---:|
| Jury | 22/40 | 19/35 | 40/40 und 35/35 |
| Depot | 18/40 | 3/35 | 40/40 und 35/35 |

Jede der 18 frischen Sitzungen erhielt den fachlichen Vertrag, dieselben beobachtbaren Fehlerdaten und die erreichbaren Quellen ihrer Sprache nach Dateinamen geordnet. Kein Prompt nannte den Fehlerort oder die Zahl der Änderungen. Die drei Bedingungen liefen seriell, je dreimal pro Familie, mit ausgeglichener Startposition. Modell war gpt-6-astra mit xhigh und angeforderter Serviceklasse priority. Alle Sitzungen lieferten eine erste Antwort ohne Shellaufruf. Alle 18 Kandidaten bestanden 40 öffentliche und auf einer frischen Kopie 35 verdeckte Fälle. Die Uhr umfasst Fehlprüfung, Kontextaufbau, Antwort, Anwendung und öffentliche Abnahme. Die Gesamtzahl umfasst Eingabe einschließlich Cachetreffern und Ausgabe einschließlich Denktokens. [Versuchsplan und Beispiele](versuchsplan.json) · [Messbefehle](messverfahren.json)

| Ablauf, je sechs Sitzungen | Vorbereitung, Median | Bis zur Abnahme, Median | Gesamttokens, Median | Denktokens, Median |
|---|---:|---:|---:|---:|
| TIDE, vollständig geklammert | 0,333 s | 8,61 s | 19.785 | 228,5 |
| TIDE, Quellklammern | 0,173 s | 10,45 s | 19.868,5 | 350,5 |
| Python, vorbereitete Quelle | 0,020 s | 8,86 s | 19.713,5 | 264,5 |

| Gepaarte Differenzen, Quellansicht minus Vergleich | Zeit bis zur Abnahme | Gesamttokens | TIDE-Quellansicht schneller / sparsamer |
|---|---:|---:|---:|
| Beide Aufgaben gegen geklammertes TIDE | +1,81 s | +53,5 | 0/6 und 1/6 |
| Jury gegen Python | +1,41 s | +57 | 1/3 und 0/3 |
| Depot gegen Python | +2,68 s | +266 | 0/3 und 0/3 |
| Beide Aufgaben gegen Python | +1,97 s | +152 | 1/6 und 0/6 |

Das Einsparen der Compilerabfragen beschleunigte die Vorbereitung in allen sechs TIDE-Paaren. Die gesamte Reparatur dauerte damit in allen sechs länger, und jede Antwort verbrauchte mehr Ausgabetokens. Die vollständig geklammerte Ansicht bleibt der Standard. Der Versuch misst Quellansicht und kürzere Anweisung zusammen. Er isoliert weder die Wirkung einzelner Klammern noch die Modelllatenz. Drei Wiederholungen pro Fehler erlauben eine Entscheidung für diese beiden Beispiele. [Einzelantworten, Zeiten, Nutzungszähler und Abnahmen](messung.json) · [Paardifferenzen, Streuung und Cachebereinigung](auswertung.json)
