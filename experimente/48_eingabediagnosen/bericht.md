# Welche Eingabe muss der Aufrufer korrigieren?

Das Journal erwartet unter `opening.rows` Buchungen mit den beiden Ganzzahlfeldern `sequence` und `balance`. Bisher meldete `tide run` für eine falsch typisierte Buchung den Parameter `opening` und den Typ `{Ledger}`. Jetzt liefert derselbe Aufruf bei einem Text im Saldo der letzten von 4.096 Buchungen zusätzlich diese Angabe.

```json
{"issue":{"path":"/opening/rows/4095/balance","expected":"i","actual":"string"}}
```

Der Pfad beginnt an der übergebenen JSON-Wurzel und zählt Listenpositionen ab null. Er lässt sich direkt auf die ursprüngliche Eingabe anwenden. Der Befund gibt die Wertart an. Der Inhalt des fehlerhaften Textes bleibt beim Aufrufer. Unter `test` beginnt der entsprechende Beispielpfad bei `/inputs`. Fehlerhafte Ereignisse und typwidrige Sollwerte verweisen auf `/events` und `/expect`. [Projekteinstieg](panel.tide) · [Typen](types.tide) · [Sprachreferenz](../../LANGUAGE.md)

Ein kurzes Beispiel für den zweiten Listeneintrag lässt sich im Checkout ausführen. Der Befehl endet mit Status 1 und nennt `/opening/rows/1/balance`. Mit der Ganzzahl `26` als Saldo liefert er die Listenlänge `2`.

```sh
./tide run experimente/48_eingabediagnosen/panel.tide \
  --inputs '{"opening":{"rows":[{"sequence":1,"balance":21},{"sequence":2,"balance":"26"}]}}'
```

## Zeit bis zur Antwort

| Eingabe | TIDE bisher | Erster Entwurf mit Pfad | TIDE jetzt | Vorbereitete CPython-Prüfung |
|---|---:|---:|---:|---:|
| 384 Einträge, letzter Saldo als Text | 9,41 ms | 12,16 ms | 9,42 ms | 11,06 ms |
| 4.096 Einträge, erster Saldo als Text | 32,71 ms | 52,97 ms | 32,48 ms | 12,71 ms |
| 4.096 Einträge, letzter Saldo als Text | 42,89 ms | 72,45 ms | 42,37 ms | 13,29 ms |
| 4.096 Einträge, letzter Saldo fehlt | 32,63 ms | 63,49 ms | 33,05 ms | 13,28 ms |
| 4.096 gültige Einträge | 47,96 ms | 46,92 ms | 47,24 ms | 13,38 ms |

Der erste Entwurf rekonstruierte den fehlerhaften Parameter und durchlief ihn für die Diagnose erneut. In der gemessenen Endfassung gibt der Record-Decoder die bereits erreichte Zeile weiter. Der Diagnoseleser setzt dort im vorhandenen JSON-Index auf. Bei abweichender Zeilenbreite prüft TIDE zunächst die Objektgrenzen und sucht anschließend das betroffene Feld innerhalb der Zeile. Enthält eine Eingabe mehrere Fehler, bezeichnet der Pfad eine zu korrigierende Stelle. [Record-Decoder](../../native/bootstrap/compound_json.tide) · [Pfad und Wertart](../../native/bootstrap/input_issue.tide)

CPython erhielt eine externe Prüfung, die eigens für die zwei Journaltypen geschrieben wurde. Sie parst dieselben JSON-Argumente, kontrolliert die Zeilen und i64-Felder in den gemessenen Fällen und führt bei Erfolg die Längenabfrage aus. TIDE lädt die deklarierten Typen des Projekts und erzeugt bei Erfolg typisierte Werte. Bei 4.096 Einträgen blieb die spezialisierte CPython-Prüfung deutlich schneller. Die CPython-Antwort nennt denselben Pfad und dieselben Typangaben. Sie enthält keine TIDE-Quellposition. Die Vergleichsquellen sind als Messdaten hinterlegt. [Vergleichsquellen und Einzelzeiten](messung.json)

## Tokens und Korrektur

Bei 4.096 Buchungen wuchs die vollständige TIDE-Diagnose für den letzten fehlerhaften Saldo von 32 auf 55 Ausgabetokens. Der Pfad, der erwartete Typ und die gelesene Wertart kosteten in beiden Sprachen als separat kodiertes `issue`-Objekt 21 Tokens. Bei 384 Buchungen umfasste die TIDE-Antwort 54 Tokens. Aus diesen Messungen lässt sich keine Einsparung bei den Gesamttokens eines Modells ableiten.

Bei drei weiteren Eingaben mit 1, 384 und 4.096 Records war jeweils ein bekannter ganzzahliger Saldo bei der Übergabe zu Dezimaltext geworden. Der Korrekturschritt folgte dem gelieferten Pfad, prüfte den erwarteten Typ und konvertierte genau diesen Wert. Danach entsprach die gesamte Eingabe wieder der unabhängig gespeicherten Referenz. Der zweite Aufruf bestand in allen drei Fällen. Bei einem fehlenden Saldo müsste der Aufrufer den fachlich richtigen Wert anderweitig beziehen. [Korrekturen und Ergebnisse](messung.json)

## Abdeckung und Messverfahren

Die öffentlichen Werkzeuge wurden mit 132 Kombinationen aus Listenlänge, Fehlerposition und fehlerhafter Zeilenform geprüft. Weitere 49 Prüfungen deckten unter anderem fehlende und zusätzliche Parameter, geschachtelte Optionen, Paare, Varianten, ungültige Sollwerte, Syntaxfehler sowie die Zurückweisung eines ungültigen Schreibkandidaten ab. In den überprüften Fehlerfällen blieb der bisherige Befund nach Entfernen des neuen Felds erhalten. Der abgelehnte Schreibversuch ließ die Quelldatei intakt. Im Bootstrap stehen zusätzlich 19 dauerhafte TIDE-Testfälle für die Typdiagnose. [TIDE-Tests](../../native/bootstrap/checks.tide) · [Eingabebindung](../../native/bootstrap/samples.tide)

Jede CLI-Zeit ist der Median aus 21 Einzelaufrufen nach drei Aufwärmrunden. Alle Prozesse liefen seriell und auf demselben CPU-Kern, mit wechselnder Reihenfolge von Aufgabe und Werkzeug. Gemessen wurde vom Prozessstart bis zum Ende einschließlich der Ausgabe. Die Tokenzählung verwendet `o200k_base` einschließlich abschließendem Zeilenumbruch für die vollständige Antwort. Es gab keine isolierten Modellläufe. Die native Testsuite und der Neubau samt Paketprüfung ohne Python bestanden. [Rohdaten, Ausgaben, Quartile und Prüfsummen](messung.json) · [Isolierter Build](../../native/bootstrap/no-python.Dockerfile)
