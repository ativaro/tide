# Welche Schreibweise hilft mir beim Programmieren?

**Stand 16. November 2026.** Der explorative Durchgang mit zwölf Aufgaben und 36 Erstabgaben ist ausgewertet. Alle Abgaben entstanden in derselben Sitzung. Der folgende Text hält die vorab geplanten Bedingungen fest. [Bericht und Rohdaten](07_dreiwege/bericht.md)

## Was genau variiert

Alle drei Darstellungen erzeugen denselben typisierten Programmbaum. Beispiel für die Sättigung des Hitzezählers:

| Oberfläche | Ausdruck |
|---|---|
| A · TIDE-Präfix | `if < streak 3 + streak 1 3` |
| B · vollständig geklammertes Präfix | `(if (< streak 3) (+ streak 1) 3)` |
| C · Python-ähnliche Ausdrücke und Funktionsaufrufe | `streak + 1 if streak < 3 else 3` |

In allen Armen gelten dieselben TIDE-Typen, Auswertungsreihenfolgen, Überlaufregeln, Fehlercodes, Rechte und Budgets. C verwendet einen begrenzten Ausschnitt vertrauter Python-Syntax. Die Auswertung erfolgt über die gemeinsame TIDE-Semantik. CPython mit seinen Bibliotheken eignet sich später als eigenständiger Praxisvergleich.

Vor der Messung für jede verwendete Konstruktion prüfen, dass ein Referenzbaum nach Ausgabe und erneutem Einlesen in allen drei Formen identisch ist. Ebenso Grenzwerte, den unausgewerteten Zweig eines `if` und einen abgewiesenen Lesezugriff prüfen. Ein Fehler in dieser Vorprüfung ist ein Fehler des Versuchsaufbaus.

## Aufgaben und Ablauf

Zwölf neue Aufgaben bilden einen ersten gepaarten Versuch. Jede Aufgabe läuft einmal je Oberfläche, insgesamt 36 Erstabgaben. Die sechs möglichen Anordnungen von A, B und C werden jeweils zweimal verwendet. Jede Abgabe benötigt einen frischen Kontext mit derselben Modellfassung und denselben verfügbaren Werkzeugen. Die Arbeitsfragen, Startprogramme, erlaubten Operationen, sichtbaren Beispiele und verdeckten Sollwerte sind inhaltlich identisch. Referenzkarten unterscheiden sich nur dort, wo die Schreibweise es erfordert. Die bekannten Beispiele zu Pumpe, Licht und Alarm dienen der Vorprüfung.

| Anteil | Beispiele für die Aufgabenauswahl | Erfolg |
|---|---|---|
| 4 schreiben | Zwei reine Datentransformationen, ein verschachtelter Kontrollfluss und ein Ablauf mit explizitem Zustand. | Das Programm erfüllt den Auftrag auf den vorab festgelegten verdeckten Eingaben. |
| 4 ändern | Eine Änderung mit zwei Aufrufern, ein geänderter Anfangswert, eine Fehlerbehandlung und eine Reihenfolgeregel. | Die neue Anforderung und alle weiterhin gültigen Beispiele sind erfüllt. |
| 4 reparieren | Ein fehlender Operand, eine geänderte Stelligkeit einer Hilfsfunktion, ein Typfehler und eine typkorrekte Verhaltensabweichung. | Der gezielt eingebrachte Defekt ist behoben und die übrigen Anforderungen bleiben erfüllt. |

Aufträge und Orakel werden vorab eingefroren. Möglichst stammen Aufgaben und fachliche Sollwerte von einer anderen Person als derjenigen, die löst. Die erste Antwort wird vor dem Werkzeugfeedback gespeichert. Danach sind maximal zwei Reparaturversuche erlaubt. Der Prüfer liefert dieselben semantischen Informationen; die von der jeweiligen Oberfläche tatsächlich ableitbare Position eines Syntaxfehlers bleibt messbar. Einzelfälle ohne getrennten Kontext als explorativen Pilot protokollieren.

## Messung und Entscheidung

Primär zählen funktional korrekte Erstabgaben pro Aufgabe und Oberfläche. Pro Aufgabenart die einzelnen gepaarten Ergebnisse zeigen: Bei welchen Aufgaben gelang mir die Lösung nur in einer Form? Zusätzlich Syntax- und Typfehler trennen, Reparaturversuche sowie Eingabe- und Ausgabetokens einschließlich Referenz, Diagnosen und Werkzeugkontext erfassen. Kosten erfolgloser Versuche gehen in die Gesamttokens pro gelöster Aufgabe ein. Für den fehlenden Operanden getrennt erfassen, wo der Parser den Defekt **erkennen** konnte und ob ich die **Ursache** richtig lokalisierte.

Die zwölf Aufgaben sind ein Pilot. Eine günstigere Syntax wird erst dann zum bevorzugten Kandidaten, wenn sich ein Vorteil bei neuen Aufgaben wiederholt und keine zusätzliche Gruppe fachlicher Regressionen auftritt. Bei Gleichstand bleibt die Wahl offen. Optionale Klammern als explizite Grenze einzelner Teilausdrücke sind ein eigener Folgeversuch; im ersten Durchgang sind A und B eindeutig getrennt.
