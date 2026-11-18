# Mehrdateien-Reparatur mit vorbereitetem Projektkontext

TIDE brauchte für denselben neuen Fehler mit vorbereitetem Kontext 19.833 statt 79.628 Gesamttokens und 6,96 statt 21,37 Sekunden bis zur bestandenen Abnahme. Python mit ebenfalls vorbereitetem Kontext brauchte 19.861 Tokens und 10,18 Sekunden. Alle vier Reparaturen bestanden beim ersten Versuch 25 von 25 Fällen.

| Arbeitsweise | Gesamttokens | Davon Eingabe aus Cache | Tokens nach Abzug der Cache-Treffer | Werkzeugaufrufe des Modells | Sekunden bis zur Abnahme |
|---|---:|---:|---:|---:|---:|
| TIDE, selbst suchen | 79.628 | 76.032 | 3.596 | 6 | 21,374 |
| TIDE, Fehlerbild und erreichbarer Code vorab | 19.833 | 17.920 | 1.913 | 0 | 6,958 |
| Python, selbst suchen | 81.700 | 59.520 | 22.180 | 4 | 28,744 |
| Python, Fehlerbild und ganzer Quelltext vorab | 19.861 | 17.920 | 1.941 | 0 | 10,184 |

### Fehler und Abnahme

Die Paketannahme empfängt Meldungen mit Auftragsnummer und Stückzahl. Die erste Meldung je Auftrag bucht die Stückzahl. Wiederholungen dürfen die Buchung auch dann nicht verändern, wenn zwischenzeitlich ein anderer Auftrag eingetroffen ist. Eine separate Kennzahl zählt aufeinanderfolgende Gruppen gleicher Nummern. Für die Meldungen `(41,4), (52,7), (41,99)` waren drei Gruppen, zwei Aufträge und elf gebuchte Stücke richtig. Beide Ausgangsprogramme lieferten drei Gruppen, drei Aufträge und 110 Stücke.

Der öffentliche Auftrag nannte nur Vertrag und Kundenbeispiel. Er enthielt keine Datei, Funktion oder Zahl betroffener Stellen. Beide Projekte umfassten vier Module. Das Register unterschied bereits „erster Auftragseingang“ und „Beginn einer Gruppe“. Die Auswertungen für Auftragsanzahl und Stückzahl verwendeten beide das zweite Merkmal. Für die Gruppenstatistik musste dieses Merkmal erhalten bleiben.

Eingaben und Sollwerte standen vor den Modellläufen fest. Die Ausgangsprogramme lieferten in allen Fällen paarweise dieselben Ausgaben und bestanden 17/25. Die isolierte Korrektur der Auftragsanzahl ergab 19/25, die der Stückzahl 17/25. Alle vier Modellantworten korrigierten beide Verbraucher. Eine Wiederholung der Abnahme auf vier frischen Kopien mit den gespeicherten Änderungen bestätigte die Ergebnisse. [Aufträge, Quelltexte, Fälle und Messbefehle](aufgabe.json)

### Was die Vorbereitung verändert

Bei TIDE baut das Werkzeug aus den geprüften Aufrufbeziehungen einen Ausschnitt ab dem öffentlichen Einstieg `main`. Alle vier Dateien waren erreichbar. Drei unbenutzte Hilfsfunktionen entfielen. Von 1.966 Quelltextbytes gelangten 1.556 in den Auftrag, jeweils mit sichtbarem Dateinamen. Das Werkzeug ordnet keinem Modul eine Fehlerwahrscheinlichkeit zu. Der Python-Kontrolllauf erhielt dieselbe Testbeobachtung und die vollständigen vier Python-Dateien. In beiden vorbereiteten Läufen durfte das Modell weitere Dateien lesen oder den Prüfer erneut starten. Beide gaben die Reparatur direkt zurück. [TIDE-Werkzeug und Bedienung](../../workbench/README.md#fehler-über-mehrere-dateien-finden)

### Messung und Grenzen

Am 16. November 2026 liefen vier getrennte, frische Codex-Sitzungen nacheinander im Nur-Lese-Modus mit `gpt-6-astra`, Reasoning-Stufe `xhigh`, angeforderter Serviceklasse `priority` und CLI 0.157.1. Die ausgeloste Reihenfolge war Python selbstständig, TIDE vorbereitet, Python vorbereitet, TIDE selbstständig. Modell, Kundentext, Antwortformat, Änderungsrechte und Abnahmefälle waren gleich. In den vorbereiteten Läufen kam der automatisch erzeugte Kontext hinzu. Das System wendete die eingereichten Änderungen gemeinsam auf die jeweilige Versuchskopie an.

Die Uhr lief vor der Kontextvorbereitung bis zum ersten erfolgreichen externen Testlauf. Den Fehlversuch und den Kontext für TIDE vorzubereiten kostete zusammen 0,131 Sekunden, für Python 0,035 Sekunden. Diese Zeiten sind in der Tabelle enthalten. Die Gesamttokens zählen alle Eingabe- und Ausgabetokens des Turns. Cache-Treffer und Denktokens sind darin bereits enthalten. Der selbstständig suchende Python-Lauf prüfte seine vorgeschlagenen Änderungen zusätzlich an sieben eigenen Fällen. Beim selbstständig suchenden TIDE-Lauf entfielen mehrere Werkzeugaufrufe auf die Verzeichnissuche. [Zeitstempel, Nutzungszähler, Prompts, Werkzeugaufrufe und Reparaturen](messung.json)

Gegenüber seinem eigenen Suchlauf sparte TIDE 75,1 % Gesamttokens und 67,4 % Zeit. Nach Abzug der Cache-Treffer betrug die Tokenersparnis 46,8 %. Auch Python konnte mit vorbereitetem Kontext auf alle modellgesteuerten Werkzeugaufrufe verzichten. Zwischen den vorbereiteten Läufen lagen 28 Gesamttokens und 3,23 Sekunden. Mit einem Lauf je Bedingung sind das Einzelbeobachtungen. Der Versuch trennt die Wirkung der TIDE-Quellauswahl nicht von der Wirkung des vorab mitgelieferten Fehlerbilds und Quelltexts.
