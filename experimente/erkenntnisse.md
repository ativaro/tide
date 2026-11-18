# TIDE · Versuche am 16. November 2026

## 1 · Verschachtelte Ausdrücke lesen und ändern

**Frage.** Kann ich als programmierendes Modell in diesem Chat einen kompakten Präfixausdruck ebenso zuverlässig lesen und lokal ändern wie einen geklammerten Ausdruck mit denselben Operationen?

**Mein Eindruck vor der Auswertung.** Bei P08 und P11 habe ich gedanklich die Grenzen zwischen dem inneren `if`, der Addition und dem äußeren Zweig rekonstruiert. Bei P09 konnte ich die Grenzen direkt ablesen. Beim Ändern war die konkrete Eingabe mit dem Sollwert hilfreich: Ich konnte die drei in Frage kommenden Vergleiche am Beispiel durchgehen. Bei P12 liefen alle drei Leseproben durch denselben Zweig. Drei geprüfte Ausgaben bedeuten dort keine drei unterschiedlichen Pfade.

**Durchführung.** Ich selbst habe alle 16 Aufgaben in diesem Chat gelöst. Für jede der beiden Schreibweisen gab es vier Leseaufgaben mit je drei vorgegebenen Eingaben und vier Änderungen. Beim Ändern musste genau ein Vergleich umgedreht und der vollständige Rumpf zurückgegeben werden. Der Generator wählte ein Sollbeispiel, das die richtige unter drei möglichen Änderungen und dem Ausgangsprogramm eindeutig identifizierte. Dafür verglich er die Kandidaten auf allen 125 Eingaben aus drei Ganzzahlen im Bereich −2 bis 2. Die Leseaufgaben erforderten drei korrekte Ausgaben für einen Treffer. Es gab einen Versuch je Aufgabe.

Die Operationen waren in beiden Formen gleich. Größe und Verschachtelung waren ausbalanciert, die konkreten Texte und Eingaben verschieden. Die Aufgaben kamen mit festem Seed 161126 in gemischter Reihenfolge. Ich sah beim Lösen die Aufgaben und bei den Änderungen das Sollbeispiel. Den Bewertungslauf habe ich erst nach dem Speichern meiner [Erstantworten](01_antworten.json) gestartet.

| Schreibweise | Lesen | Ändern |
|---|---:|---:|
| Präfix | 4/4 | 4/4 |
| Geklammert | 4/4 | 4/4 |

**Quelltextkosten.** Für diese Zählung wurden dieselben 16 Programmbäume jeweils in beiden Formen ausgegeben. Zusammen ergaben sich 384 Tokens in Präfixform und 560 mit Klammern. Beide bislang verwendeten Kodierungen (`o200k_base`, `cl100k_base`) lieferten dieselben Zahlen. Gezählt wurden nur die Rümpfe. Kosten für meine Überlegungen, für Aufgaben und Eingaben sowie meine Bearbeitungszeit wurden nicht gemessen.

**Einordnung.** In diesen Aufgaben kam ich mit beiden Formen beim ersten Versuch zum Ziel. Beim Lesen war die geklammerte Ansicht für mich stellenweise angenehmer. Ich habe den Generator selbst entworfen, kannte die beiden Baumformen und arbeitete im selben Chat. Die Fälle sind kurz, gleichartig und paarweise keine identischen Aufgaben. Vier Treffer pro Teilgruppe lassen Schwierigkeiten bei größeren oder fremden Programmen offen.

## 2 · Finde ich selbst die entscheidende Rückfrage?

Für den zweiten Versuch lege ich je zwei Geschäftsregeln fest. Meine Aufgabe ist, eine möglichst kurze Eingabe zu nennen, die sie unterscheidet. Erlaubt sind Folgen der Länge 0 bis 4 über den Werten 0, 1 und 2. Ich notiere Eingabe und erwartete Antworten, bevor eine Suche die Mindestlänge bestimmt.

| Fragestellung | Mein Beispiel | Meine erwarteten Antworten in der genannten Reihenfolge |
|---|---|---|
| Länge der längsten zusammenhängenden streng steigenden bzw. nicht fallenden Folge | `[1,1]` | 1 und 2 |
| Größte Summe zweier benachbarter bzw. zweier beliebiger Einträge | `[2,0,2]` | 2 und 4 |
| Anzahl der Änderungen zum direkten Vorgänger bzw. Anzahl erstmals auftretender Werte nach dem ersten Eintrag | `[0,1,0]` | 2 und 1 |
| Letzter Wert größer als erster bzw. mehr steigende als fallende Schritte | `[0,2,1]` | wahr und falsch |

**Ergebnis der Suche.** Alle vier vorab notierten Beispiele unterschieden die Regeln wie vorhergesagt. Die Mindestlängen waren 2, 3, 3 und 3. Meine Beispiele erreichten sie in allen vier Fällen. Die vollständige Suche hat mir die Minimalität bestätigt. Sie hat mir in diesem Versuch weder eine kürzere Eingabe geliefert noch eine unbekannte Deutung des Auftrags erschlossen. Ich kannte beide Regeln vorab und habe sie selbst ausgewählt. Was bei einem wirklich mehrdeutigen Auftrag hilft, muss ich an einem unabhängigen Auftraggeber prüfen.

## 3 · Was passiert mit einer klaren Regel nach einer kurzen Rückmeldung?

Der Auftraggeber verlangte einen Alarm bei „dreimal hintereinander über 80 Grad“. Meine erste Auslegung traf die Regel: Jeder Wert über 80 erhöht die Länge der laufenden Serie um eins. Bei 80 oder weniger beginnt die Zählung wieder bei null. Meine einzige Rückfrage nutzte sechs hohe Werte. Damit fragte ich nach weiteren Alarmen nach dem dritten Treffer. Die Antwort „also counten“ deutete ich anschließend als fortlaufende Gesamtzählung. Der Auftraggeber bestätigte ausdrücklich die ursprüngliche Serienregel.

**Beobachtung.** Mein Fehler entstand bei der Überarbeitung einer bereits richtigen Interpretation. Das Wort „counten“ sagt, dass gezählt wird. Es ändert für sich genommen weder das Zählkriterium noch die Rücksetzregel. Wie hoch die einzelnen Treffer über 80 liegen, ist unerheblich. Für den ersten Alarm zählt allein die Folge der Wahrheitswerte von `Temperatur > 80`.

| Messfolge | Erwartung bis zum ersten Alarm | Was der Fall prüft |
|---|---|---|
| `70, 81, 95, 82` | Alarm bei der vierten Messung | Unterschiedlich hohe Werte bilden gemeinsam eine Serie. |
| `81, 70, 95, 82` | Kein Alarm | Dieselben vier Messwerte in anderer Reihenfolge. Eine Gesamtzählung würde hier fälschlich auslösen. |
| `81, 80, 95, 82` | Kein Alarm | Auch der exakte Grenzwert unterbricht die Serie. |

**Hypothese für TIDE.** Wenn ich eine Rückmeldung einarbeite, könnte mir ein gespeichertes Gegenbeispiel zur bisherigen Anforderung zeigen, welche bereits vereinbarte Regel meine neue Deutung verändert. Beim nächsten unabhängigen Auftrag lässt sich prüfen, ob mir dieser Hinweis tatsächlich hilft. Die Wiederholung des Alarms innerhalb einer längeren ununterbrochenen Serie bleibt in diesem Fall offen.

## 4 · Pumpe mit Zustandsspur, Licht ohne

Die beiden Regeln kamen vom Auftraggeber. Für die Simulation starteten beide Geräte ausgeschaltet. Bei der Pumpe bleibt zwischen den Grenzen einschließlich 20 und 80 der vorige Zustand erhalten. Beim Licht unterbricht jede Bewegung die Folge der Meldungen ohne Bewegung.

Ich habe den Versuchsgenerator mit je drei möglichen Einzelfehlern selbst vorbereitet. Seed 2916324528 loste die konkrete Quellvariante, die Eingaben und die Zuordnung der Spur aus. Beim Lösen sah ich jeweils den fehlerhaften Code, die Eingaben sowie Soll- und Istzustand am Ende. Nur für die Pumpe sah ich auch alle tatsächlichen Zwischenzustände. Vor einer zweiten Eingabefolge hielt ich für beide Aufgaben den ersten falschen Ausgabeschritt, die Ursache und die Quelltextänderung fest. Danach notierte ich für diese neue Folge die erwarteten Zustände. Erst dann startete die Auswertung. [Meine Antworten](03_antworten.json)

| Aufgabe | Erster fehlerhafter Schritt und Reparatur | Kontrolle nach der Reparatur |
|---|---|---|
| Pumpe, mit Spur | Bei `20, 50, 20, 50, 20` war die Pumpe ab Schritt 1 an. Die Spur grenzte den Fehler auf das Anlaufen bei genau 20 ein. Im Startvergleich `<= 20` durch `< 20` ersetzen. | Vorhersage für `20, 20, 80, 50, 80, 19` richtig: fünfmal aus, dann an. Alle 3.906 Folgen bis Länge 5 über 19, 20, 50, 80 und 81 bestanden. |
| Licht, ohne Spur | Bei Bewegung, Bewegung, Ruhe, Ruhe, Bewegung, Ruhe ergab sich der erste Fehler aus dem Code in Schritt 3. Der Zähler war nach der ersten Ruhe schon 1, also war `missed < 1` falsch. Reparatur: `missed < 2`. | Vorhersage für Bewegung und fünf Ruhemeldungen richtig: an, an, aus, aus, aus, aus. Alle 255 Bewegungsfolgen bis Länge 7 bestanden. |

**Was mir geholfen hat.** Die Spur zeigte mir sofort, dass die Pumpe schon beim ersten Messwert ansprang. Aus der Bedingung im Code ging hervor, warum. Beim Licht reichte es, eine Bewegung und die erste Ruhemeldung im Kopf durchzugehen. Ich fand beide Fehler im ersten Versuch. Das spricht für einen Versuch mit einer bei Bedarf abrufbaren Spur für einen bestimmten Schritt. Eine Zeitersparnis wurde nicht gemessen. Pro Bedingung gab es nur eine Regel, und die möglichen Fehler kannte ich aus der Vorbereitung. Eine Wiederholung mit vertauschter Zuordnung müsste neue Fehler und Folgen verwenden.

## 5 · Gegenversuch mit vertauschter Spur

Licht mit Spur, Pumpe ohne. Für Seed 720416888 unterscheiden sich pro Regel die fehlerhafte Codezeile sowie Diagnose- und Vorhersagefolge vom ersten Durchgang. Die Regeln, ausgeschalteten Anfangszustände, Fehlerauswahl und Bewertung stammen aus demselben Generator. Diagnose und Änderung habe ich vor der Anzeige der zweiten Folge gespeichert, die Zustandsvorhersage vor der Auswertung. [Meine Erstantworten](04_antworten.json)

| Regel | Beobachtung beim Diagnostizieren | Ergebnis der Reparatur |
|---|---|---|
| Licht, mit Spur | Die Folge begann mit Ruhe, Bewegung, Ruhe. Die tatsächlichen Zustände aus Licht und Ruhezähler waren `(aus,1) → (an,1) → (aus,2)`. An Schritt 2 war das Licht noch korrekt an, aber die Bewegung hatte den Ruhezähler bei 1 belassen. Erst in Schritt 3 wich die sichtbare Ausgabe ab. Reparatur: Bei Bewegung den Zähler auf null setzen. | Auf der neuen Folge Bewegung, Ruhe, Bewegung, Bewegung, Ruhe, Bewegung blieb das Licht wie vorhergesagt sechsmal an. Alle 255 Folgen bis Länge 7 bestanden. |
| Pumpe, ohne Spur | Eingaben `20, 50, 50, 19, 80`; am Ende war die Pumpe aus, erwartet war an. Für meine Diagnose genügten 19 und anschließend 80: Bei 19 startet sie. Genau 80 hat keine Schaltwirkung. In Schritt 5 fiel der Code auf `return False` zurück. Reparatur: Im Haltebereich den vorherigen Zustand zurückgeben. | Vorhersage für `50, 80, 19, 20, 80, 20` richtig: zweimal aus, viermal an. Alle 3.906 Folgen bis Länge 5 über 19, 20, 50, 80 und 81 bestanden. |

**Was mir diesmal geholfen hat.** Beim Licht machte der interne Zähler die Ursache eine Meldung vor dem sichtbaren Fehler erkennbar. Bei der Pumpe konnte ich den zuletzt gesetzten Schaltzustand über zwei Werte direkt aus der Regel rekonstruieren. Meine Arbeitshypothese für TIDE ist jetzt konkreter: Wenn eine Ausgabe von einem verborgenen Zustand abhängt, möchte ich bei Bedarf dessen Wert vor und nach dem entscheidenden Ereignis sehen. Die Trefferquote war in beiden Durchgängen gleich. Ich kannte den Fehlerkatalog, Zeit habe ich nicht gemessen.

## 6 · Zustandsregeln selbst schreiben

Vier neue Aufgabenpaare. Sowohl die vier normalen TIDE-Schrittfunktionen als auch die vier Regeltabellen bestanden im ersten Versuch sämtliche geprüften Folgen. Für die Rümpfe brauchte ich insgesamt 216 bzw. 334 Quelltext-Tokens. Bei einer Buchung half mir der explizite Reset auf den Startwert, beim Tausch zweier Werte war die Funktion direkter. Einen Vorteil für die Korrektheit meiner Erstlösungen habe ich hier nicht beobachtet. [Versuch, Abgaben und Auswertung](05_schreibprobe.md)

## 7 · Bonus-Startwert von 1 auf 3 ändern

Im Schreibversuch stand in der normalen Funktion beim Buchen die Zahl 1. Für diese Wartungsprobe gab ich beiden Fassungen vorab die gleiche unveränderliche Definition `bonus_start`, dieselben Feldnamen und dieselben Ereigniscodes. Die normale Funktion verwendet beim Buchen `pair + total bonus bonus_start`. In der Regel ist der Feldanfang `bonus:i=bonus_start` deklariert, der Buchungszweig enthält `bonus=reset`. Beide starten mit Kontostand 4 und demselben benannten Bonus. Der begrenzte Probeprüfer setzt den Namen beim Laden in beiden Fassungen durch denselben Wert ein. Eine benannte Konstante im Zustandsinitialisierer ist hier eine Versuchsannahme; Entwurf 0.3 sieht an dieser Stelle bisher ein Literal vor. [Beide Fassungen](06_bonusstart.tide) · [Auswertung](06_bonusstart.py)

**Ablauf.** Zuerst bestanden beide vorbereiteten Fassungen mit Startwert 1 je 19.531 Folgen. Vor der zweiten Auswertung legte ich mich auf einen einzigen Edit fest: die 1 in der gemeinsamen Definition durch 3 ersetzen. Für zwei direkte Buchungen sagte ich `(7,3)` und `(10,3)` voraus. Der Vorher-Hash des Versuchsprogramms war `069565cd82d588e8992b1192a88934e06f25e18045cc0b29d1fb6a9425ab2bf8`. Die Rücknahme dieses einen Edits ergibt denselben Hash.

| Nach der Änderung, jeweils ab Kontostand 4 und Bonus 3 | Erwartet und in beiden Formen beobachtet |
|---|---|
| Sofort buchen, nochmals buchen | Erst `(7,3)`, dann `(10,3)` |
| Buchen, zweimal Bonus um 2 erhöhen, nur Konto zurücksetzen | `(4,7)` nach dem Kontoreset |
| Anschließend Bonus auf Kontostand begrenzen und buchen | Erst `(4,4)`, dann `(8,3)` |

Beide Fassungen bestanden im ersten Versuch mit Wert 3 je 19.531 Folgen aus fünf Ereignissen bis Länge 6, einschließlich der leeren Folge und aller Zwischenzustände. Eine absichtlich festgeschriebene 1 im jeweiligen Buchungszweig erzeugte in beiden Formen sofort den nachweisbaren Fehler `(7,1)` statt `(7,3)`.

**Was mir beim Ändern geholfen hat.** Ich musste eine Definition bearbeiten und keinen der beiden Buchungszweige. `reset` beschreibt die Absicht knapp. Für diese Änderung hat es mir weder einen Edit erspart noch einen Fehler vermieden, den ich mit dem benannten Wert in der normalen Funktion gemacht hätte. Die einmalige Vorbereitung der beiden gleichwertigen Ausgangsfassungen zählt separat. Der Vergleich misst weder das Auffinden der richtigen Stelle in einem fremden Projekt noch die Bearbeitungszeit.

## Nachvollziehen

Die Prüfläufe verwendeten Python 3.14.10 und dessen Standardbibliothek. Sie arbeiten ausschließlich mit synthetischen Eingaben. Die Generatoren geben die Aufgaben aus und bewerten meine separat gespeicherten Antworten.

```sh
python3 experimente/01_schreibweise.py aufgaben
python3 experimente/01_schreibweise.py werten experimente/01_antworten.json
python3 experimente/02_gegenbeispiele.py
python3 experimente/03_zustandsspur.py aufgaben 2916324528
python3 experimente/03_zustandsspur.py vorhersage 2916324528
python3 experimente/03_zustandsspur.py werten 2916324528 experimente/03_antworten.json
python3 experimente/03_zustandsspur.py aufgaben 720416888
python3 experimente/03_zustandsspur.py vorhersage 720416888
python3 experimente/03_zustandsspur.py werten 720416888 experimente/04_antworten.json
python3 experimente/06_bonusstart.py 1 --vorher
python3 experimente/06_bonusstart.py 3
```

**Nächste offene Frage.** Hilft mir eine strukturell aufgeklappte Ansicht, wenn ich eine unbekannte Funktion ändern und an einem zweiten Aufrufer die Auswirkungen erkennen muss? Dafür kommen neue, tiefere Aufgaben mit mindestens zwei Funktionen infrage. Die Bewertung sollte auch bisher gültiges Verhalten prüfen. Für den Versuch zu Rückfragen ist ein vom Auftraggeber vorab festgelegtes, mir verborgenes Sollverhalten aussagekräftiger als eine weitere Runde mit selbst gewählten Regelpaaren.

## Drei Schreibweisen bei zwölf neuen Aufgaben

Je vier Schreib-, Änderungs- und Reparaturaufgaben gelangen mir in klammerfreiem Präfix, vollständig geklammertem Präfix und Python-ähnlichen Ausdrücken beim ersten Versuch. Präfix benötigte die wenigsten Tokens. Beim fehlenden Summanden benannte nur die geklammerte Diagnose unmittelbar die unvollständige Addition. Alle Lösungen entstanden im selben Kontext. [Ergebnisse je Aufgabe, Diagnosen und Rohdaten](07_dreiwege/bericht.md)

## Eine Klammer um die bearbeitete Operation

Bei sechs neuen Änderungs- und Reparaturaufgaben gelangen mir alle 18 Erstabgaben. Bei 37 systematischen Einzelwertlöschungen benannte der Prüfer den betroffenen Aufruf klammerfrei 16-mal, mit einer festen lokalen Markierung 21-mal und vollständig geklammert 37-mal. Alle fünf zusätzlichen Treffer der lokalen Form lagen unmittelbar an der markierten Operation. Bei einer tieferen Löschung grenzte die Markierung im Beispiel die Suche auf einen Zweig ein. [Versuch mit lokaler Klammerung](08_lokale_klammern/bericht.md)

## Wenn eine lokale Änderung einen zweiten Aufrufer trifft

Im konstruierten Kontrollfall wählen Anzeige und Archiv zwischen zwei Einträgen. Bisher hatte bei Punktgleichstand der ältere Vorrang. Der neue Auftrag gibt dem neueren Eintrag ausschließlich in der Anzeige Vorrang. Das Archiv verwendet die Auswahl mittelbar über `archiv_eintrag`. Beide Einträge haben denselben Typ.

Alle drei Fassungen bestanden die Typprüfung. Je Verbraucher wurden die 25 Kombinationen der Punktzahlen 3 bis 7 mit zwei unterscheidbaren Kennungen geprüft. Die Änderung an der gemeinsamen Auswahl bestand alle 25 neuen Anzeigeanforderungen und verfehlte die Archivanforderung in allen fünf Gleichständen. Wurden nur in der Anzeige die bereits gebundenen Argumente der Auswahl getauscht, bestanden beide Verbraucher 25/25. Das Beispiel mit zwei Fünfen und den Kennungen 11 und 19 unterscheidet die fachlichen Verträge unmittelbar. [Kontrollfall zum Nachrechnen](09_aufrufer.py)

Für den geplanten Editor ergibt sich eine prüfbare Frage: Helfen mir vor dem Edit die rückwärts verfolgten Aufrufketten plus je ein bestehendes Beispiel, die richtige Funktion zu wählen? Der Kontrollfall zeigt, welche Information zwei typkorrekte Lösungen auseinanderhält. Die Wirkung einer solchen Ansicht auf meine eigenen Erstabgaben ist noch offen.
