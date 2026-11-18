# Ideen für TIDE aus Forschung und Sprachprojekten

Recherche vom 16. November 2026. Die Leitfrage ist, was mir beim Schreiben, Verstehen und Ändern eines unbekannten Programms hilft. Die folgenden Ideen lassen sich mit vorbereiteten Aufgaben untersuchen, bevor wir einen Sprachkern bauen.

## Eine Regel als Folge von Zuständen lesen

In Lustre hat jede Variable einen Wert pro Takt. Eine Gleichung kann mit `pre` auf den vorherigen Wert Bezug nehmen. Für unseren Temperaturalarm entspricht ein Takt einer Messung, unabhängig davon, wie viele Sekunden zwischen zwei Messungen liegen. Als Versuchsform bietet sich die Gleichung „bei Temperatur über 80 ist die neue Serienlänge die vorherige plus eins, sonst null“ mit Startwert null an. Damit lässt sich für jede Messung zeigen, wo eine Serie endet. Lustre stammt aus der Entwicklung reaktiver Systeme. Der Nutzen dieser Darstellung für mich ist eine eigene Hypothese. [Verimag über Lustre](https://verimag.fr/The-Lustre-Programming-Language-and.html)

## Bei einem Fehler nach dem entscheidenden Ereignis fragen

Whyline beantwortet Fragen nach eingetretenen und ausgebliebenen Ausgaben anhand von Code und tatsächlich ausgeführten Schritten. Die ursprünglichen Untersuchungen betrafen menschliche Programmierer. Als einfaches Gegenstück könnte ich bei einer unbekannten Reparatur eine aus dem tatsächlichen Programmlauf erzeugte Zustandsspur bekommen. Wenn die Endausgabe falsch ist, wäre die relevante Beobachtung etwa der erste Schritt, an dem der Zähler seinen alten Wert behält, obwohl die Regel ein Zurücksetzen verlangt. [Ko und Myers, Whyline](https://doi.org/10.1145/1368088.1368130)

## Beim Schreiben und beim Prüfen die Ansicht wechseln

Tacit beschreibt eine kompakte Schreibansicht und eine aufgegliederte Inspektionsansicht desselben Programmbaums. X07 dokumentiert eine verwandte Konstruktion mit kanonischem JSON und einer verlustfrei rückübersetzbaren Textansicht. Für einen Versuch reichen zwei Darstellungen desselben Beispiels. Ich könnte eine kompakte Änderung abgeben und zum Prüfen gezielt den betroffenen Zweig und seinen Aufrufer aufklappen. Zu messen wären Fehler bei unverändertem Verhalten, benötigte Kontexttokens und zusätzliche Lesevorgänge. [Tacit-Projekt](https://github.com/weetster/tacit) · [X07-Dokumentation](https://x07lang.org/docs/0.2.17/faq/)

## Die passende Funktion am anderen Ende des Projekts finden

Die Hazel-Arbeit zu typisierten Lücken lässt den Sprachserver den erwarteten Typ, die sichtbaren Bindungen und relevante Definitionen aus der übrigen Codebasis bereitstellen. Damit gibt es für unsere bisherige Lückenidee eine zusätzliche Versuchsbedingung: Zeigt mir die Umgebung nur lokale Variablen oder auch bereits vorhandene Hilfsfunktionen, deren Typen zur Aufgabe passen? Prüfkriterium wäre, ob ich die richtige Hilfsfunktion benutze und ihr vorhandenes Verhalten erhalte. [Blinn et al., Statically Contextualizing Large Language Models with Typed Holes](https://arxiv.org/abs/2409.00921)

## Was vorhandene Modellmessungen tatsächlich zeigen

Anka stellt Datenverarbeitung als explizit geordnete Schritte dar. Für die Kategorie mit zehn mehrstufigen Aufgaben berichtet der Preprint bei Claude 3.5 Haiku 100 % Aufgabenerfolg in Anka und 60 % in Python. Als gelöst gilt eine Aufgabe, wenn mindestens die Hälfte der Versuche das korrekte Ergebnis liefert. In der Kategorie mit komplexen Randfällen lag Python vorn. Die Zahlen motivieren einen Test mit ähnlich langen Abläufen. Welcher Anteil auf die Schreibweise, die Operationen oder die Anleitung zurückgeht, bleibt dabei offen. [Anka, Abschnitte 4 und 5](https://arxiv.org/html/2512.23214v1)

Das Projekt toke berichtet eine Korrektur seiner früheren Tokenvergleiche. Mit demselben Tokenizer auf beiden Seiten beanspruchten die toke-Programme im 60-Aufgaben-Vergleich insgesamt das 1,34-Fache der Python-Tokens. Für TIDE sollten Ausdruckslänge, mitgelieferter Kontext, Reparaturen und funktionale Treffer getrennt ausgewiesen werden. Die Zahlen sind Eigenmessungen des Projekts. [toke, Messung und Vergleichsbedingungen](https://tokelang.dev/)

## Vorschlag für meinen nächsten Versuch

Zwei Gruppen bislang ungesehener Aufgaben mit gleich schwierigen Zustandsregeln vorbereiten. In beiden sehe ich den Auftrag, den fehlerhaften Code, eine Eingabefolge sowie Soll- und Istausgabe. Nur in einer Gruppe sehe ich zusätzlich die tatsächlichen Zustandswechsel. Vor der Auswertung benenne ich den fehlerhaften Übergang, schlage eine Änderung vor und sage voraus, was bei einer zweiten Folge geschieht. Gewertet werden korrekte Diagnose, korrekte Reparatur auf verdeckten Folgen und zusätzlicher Kontext. Die bekannte Temperaturaufgabe dient ausschließlich zur Erklärung des Ablaufs.
