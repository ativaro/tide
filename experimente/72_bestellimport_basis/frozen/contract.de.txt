# Auftrag des Einkaufs an den Bestellimport

Eine Sachbearbeiterin importiert Bestellungen mehrerer Lieferanten aus einem UTF-8-JSON-Dokument in eine lokale SQLite-Datenbank. Nach einem unterbrochenen Import muss sie die Datei erneut einlesen können. Sie will erkennen, welche Position wie viel kostet, was noch offen ist und warum ein Import scheitert. Das Zielsystem für die erste Anwendung ist Linux. Referenzwährung ist EUR, Preise und Summen sind ganze Cent.

## Schnittstelle und fachliche Regeln

- Ein Dokument hat die Form `{"supplier":"ACME","events":[...]}`. Ein Anlageereignis trägt `id`, `kind:"order"`, `order`, `line`, `sku`, `qty` und `unit_cents`. Eine Position ist durch (Lieferant, Bestellung, Position) bestimmt, ein Ereignis durch (Lieferant, Ereignis-ID). Identifikatoren sind nichtleere Unicode-Texte mit höchstens 64 UTF-8-Bytes. Identität beruht auf dem unveränderten Text.
- `qty` liegt zwischen 1 und 1.000.000, `unit_cents` zwischen 0 und 100.000.000. Pro Dokument sind bis zu 1.000 Ereignisse zulässig. Geld wird ganzzahlig gerechnet. Fehlende Pflichtfelder, falsche Typen, ungültiges UTF-8 und Überlauf liefern einen Fehler. Unbekannte Zusatzfelder werden ignoriert. Für eine leere Liste gilt der Erfolg mit Nullzählung.
- Die erste gültige Anlage erzeugt die Position. Ein bekanntes Ereignis mit denselben fachlichen Feldern zählt als Wiederholung. Dieselbe Ereignis-ID mit anderem Inhalt oder eine zweite Anlage derselben Position unter neuer ID ist ein Konflikt. Die Verarbeitung bindet SQL-Parameter und läuft in Dokumentreihenfolge in **einer** Transaktion. Ein Fehler verwirft alle Änderungen dieses Dokuments. Bereits gespeicherte Dokumente behalten ihre Wirkung.
- Die erste Erweiterung ist `kind:"cancel"` mit eigener Ereignis-ID, Bestellung, Position und positiver Menge. Sie reduziert die offene Menge bis auf null. Unbekannte Position und Überstorno sind Fehler. Der offene Wert ist offene Menge mal ursprünglichem Preis. Gross-/Kleinschreibung von Geschäftsschlüsseln ist signifikant.
- Der Erfolg meldet `applied` und `duplicates`. Eine Abfrage per Positionsschlüssel liefert ursprüngliche Menge, offene Menge und offenen Wert. Diagnosen nennen eine stabile fachliche Ursache und bei einem Ereignis den nullbasierten Index, bei Feldfehlern zusätzlich den JSON-Pointer. Die CLI erhält explizite Eingabe- und Datenbankrechte.

## Abnahme für die spätere Gesamtanwendung

| Ablauf, jeweils bei Lieferant ACME | Erwartung |
|---|---|
| E1 legt O7/1, SKU A, 3 Stück zu 125 Cent an | 1 angewendet, 0 Wiederholungen, offen 3 Stück / 375 Cent |
| Dasselbe Dokument nach Prozessneustart | 0 angewendet, 1 Wiederholung, offen 375 Cent |
| E2 storniert 2 Stück von O7/1 | Offen 1 Stück / 125 Cent, identische Wiederholung ändert nichts |
| Ein Dokument legt O7/2 an und storniert danach 2 weitere Stück von O7/1 | Überstorno bei Index 1, O7/2 fehlt nach erneutem Öffnen der DB, O7/1 bleibt bei 125 Cent |
| E1 erscheint erneut mit anderem Stückpreis | Konflikt bei Index 0, ursprünglicher Stückpreis bleibt erhalten |
| Ein zweiter Lieferant verwendet dieselben IDs | Getrennte Positionen und getrennte Ereignisse |
| Menge ist Text im ersten Ereignis | Feldfehler bei `/events/0/qty`, keine persistierte Position |

## Erfolgsmassstab

Korrektheit an Einstieg und betroffenen Modulen geht vor kürzeren Laufzeiten. Die Studie erfasst Lösequote, Zeit bis zur unabhängigen Abnahme, Programmzeit und Spitzen-RSS getrennt. Die vorgeschlagene erste Wettbewerbsmarke ist gleiche oder höhere Korrektheit und ein Faktor von zwei bei Agentengesamttokens oder Reparaturzeit. Für die drei 100×-Forschungsziele gilt weiterhin der Projektplan. Buchungs-, Wareneingangs- und Versandaufgaben der Ausgangsmessung prüfen einzelne Komponenten auf definierten Eingabebereichen. Der vollständige Import samt Neustartabnahme gehört zu Stufe 4. [Projektplan](../../tasks/plan.md)
