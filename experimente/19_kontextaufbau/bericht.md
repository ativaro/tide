# Gleicher Reparaturkontext mit weniger Compileraufrufen

In allen 24 Messpaaren stand die gruppierte TIDE-Ansicht früher bereit. Die geordneten Funktionsrümpfe, die Zusatzsignaturen und der Inhalt der Ansicht stimmten in jedem Paar überein. Beim Journal und bei der Einsatzvergabe waren die vollständigen Prompts auch bytegleich mit denen der früheren Blindstudien. [Versuchsplan](versuchsplan.md) · [Zeitstempel, Quellstände, Befehle und Inhaltshashes](messung.json)

| Projekt, je acht Paare | Funktionen | Kontext bisher, Median | Kontext jetzt, Median | Ersparnis im einzelnen Paar, Median |
|---|---:|---:|---:|---:|
| Journal | 4 | 495 ms | 323 ms | 171 ms |
| Einsatzvergabe mit Bibliothek | 5 | 585 ms | 366 ms | 216 ms |
| Messbericht aus `apps/report.tide` | 3 | 424 ms | 281 ms | 144 ms |

Gemessen wurde ab der ersten Projektprüfung bis zur fertig gruppierten Ansicht einschließlich zusätzlicher Signaturen. Für jedes Verfahren gab es ein neues Ausgabeverzeichnis. Je Projekt begann jedes Verfahren viermal. Die relative Zeitersparnis lag im Median der 24 Paare bei 35,5 %. Die lokalen Messungen erfassen keine Modelllatenz. Bei bytegleichen Prompts ist auch der Eingabetext für die Tokenisierung gleich. Für diese Auswertung wurde kein neuer Modelllauf gestartet.

## Was Zeit kostete

In der ersten Journalmessung entfielen 369 von 550 ms auf die Beschaffung der vier Funktionsrümpfe. Zuvor startete die Werkbank pro Funktion den Compiler zweimal. Der erste Aufruf lieferte die Knotenliste einschließlich der Position des Wurzelausdrucks. Der zweite Aufruf lieferte genau diesen Ausdruck mit der Gruppierung aus dem Typprüfer.

Jetzt ermittelt ein TIDE-Programm die Position im Originaltext zusammen mit der Liste erreichbarer Definitionen. Der Compiler liefert die Gruppierung mit einer Abfrage pro gewöhnlicher Funktion, sofern ihr Operator in den ersten 32 Codepunkten der ersten Rumpfzeile steht. Andernfalls wird die Position beim Compiler abgefragt. Für eine Zustandsregel ist keine Ausdrucksabfrage nötig. Eine private Quellkopie und die Projektrevision binden alle Antworten an denselben geprüften Stand. Im dokumentierten Ablauf führte eine nachträglich veränderte importierte Datei zum Abbruch vor der Prompt-Ausgabe. [Positionsbestimmung in TIDE](../../workbench/grouping.tide) · [Ausführbarer Ablauf](../../workbench/README.md#gruppierte-funktionsrümpfe-reparieren)

## Eine größere Anwendung

Für Nano `step` lieferte der Compiler bereits vorher alle 14 Funktionsrümpfe. Das anschließende Ersetzen durchsuchte dieselbe Datei pro Rumpf erneut und verbrauchte das Arbeitsbudget. Der neue TIDE-Aufruf setzt die geprüften Rümpfe in einem Durchgang pro Datei ein. Nano lässt sich jetzt mit dem bisherigen Ressourcenlimit vollständig anzeigen. Ein unabhängiger Durchlauf der früheren Einzelersetzungen über dieselben Compilerantworten ergab denselben Text. Die vollständige neu zusammengestellte Projektkopie bestand ihre drei TIDE-Beispiele. [Zusammensetzen der Ansicht](../../workbench/grouped_view.tide)

Bei Space Invaders `draw` stimmte die Ansicht aller 13 Funktionen mit der bisherigen Ausgabe überein. Die vollständige Projektkopie bestand zehn Beispiele. Beim Einstieg über die Temperaturregel blieb der Regeltext sichtbar. Die vollständige Kopie bestand ihre drei Beispiele. Ein weiteres Projekt prüfte tiefe Einrückung und eine öffnende Klammer auf eigener Zeile. Beide Funktionen wurden über die genaue Positionsabfrage gefunden. Der Aufruf mit Eingabe 4 lieferte vor und nach dem Zusammensetzen 9.

## Abstand zu Python

Eine zweite Messung schloss die anfängliche fehlgeschlagene Fachprüfung und das Schreiben der vollständigen Promptdatei ein. Je Projekt liefen sechs Paare mit wechselnder Reihenfolge. Die Endprodukte stimmten mit den archivierten Prompts ihrer jeweiligen Sprache überein. [Plan der Zusatzmessung](pythonvergleich.md)

| Vom ersten Test bis zum fertigen Prompt | TIDE jetzt, Median | Python, Median | Gepaarter Mehraufwand für TIDE, Median |
|---|---:|---:|---:|
| Journal | 372 ms | 33 ms | 340 ms |
| Einsatzvergabe | 409 ms | 29 ms | 379 ms |

Python las die vollständigen Modultexte ein. TIDE prüfte die Revision, verfolgte die erreichbaren Definitionen und beschaffte typgeprüfte Ausdrucksbäume. Python war bei der Vorbereitung in allen zwölf Paaren schneller. Auch im verbesserten TIDE-Ablauf startet die Referenz-CLI einen eigenen Compilerprozess pro abgefragter Funktion. Die Laufzeit der fertigen Anwendungen und die Tokens bis zu einer neuen Reparatur waren keine Messgrößen dieses Versuchs.
