# Was Gleichstände und Rundung bei der Reparatur kosten

Der ausdrückliche Hinweis auf erledigte Prüfungen sparte TIDE im gepaarten Median 6,82 Sekunden und 40.073 Gesamttokens. Gegen Python mit demselben Hinweis brauchte TIDE im Median 1,61 Sekunden und 86,5 Gesamttokens mehr. Alle 36 Erstvorschläge bestanden die öffentliche und die verdeckte Abnahme auf einer frischen Kopie.

In Versuch 15 lagen 40.612 der 42.080 zusätzlichen TIDE-Gesamttokens in den zwei Vergleichspaaren, in denen die TIDE-Sitzung mit `rg --files` das schon gelieferte Verzeichnis erneut abfragte. Das ist die gesamte Differenz dieser Paare. Der Anteil des einzelnen Befehls lässt sich daraus nicht exakt bestimmen. Bei Gleichstand lag der Median der ausgewiesenen Denktokens bei 572 für TIDE und 256,5 für Python, bei der Rundung bei 357,5 und 138. Die Antworten zeigen wiederholte Feldzugriffe in verschachtelten Vergleichen und die erneute Ausgabe einer fast unveränderten Faltung. Die Uhr erfasst die gesamte Reparatur. Sie misst keine separate Denkzeit pro Ausdruck. [Ursprüngliche Prompts, Antworten und Zähler](../15_gepaarte_reparaturen/messung.json)

## Zwei Änderungen an der TIDE-Werkbank

Der frühere Versuch mit gruppierter Compileransicht und benannten Funktionsrümpfen sparte gegenüber TIDE-Textedits im gepaarten Median 3,08 Sekunden und 190,5 Gesamttokens. Bei derselben Bearbeitungsform lag Python noch 0,97 Sekunden und 110 Tokens vorn. Eine zusätzliche Bibliothek für Rangfolgen wurde später in einer von zwölf möglichen Reparaturen verwendet. Deshalb untersucht dieser Versuch zwei Schritte des tatsächlichen Reparaturablaufs. [Vergleich der Bearbeitungsformen](../16_gruppierte_reparaturen/bericht.md) · [Versuch mit Vergleichsfunktionen](../17_prioritaeten/bericht.md)

Eine Modellantwort kann einen eindeutigen Ausschnitt im vom Compiler gruppierten Funktionsrumpf ersetzen. Sie nennt Funktion, alten Ausschnitt und Ersatz. Das reduziert die Menge an unverändertem Code, die das Modell abschreiben muss. Bei einem mehrfachen Treffer verlangt die Werkbank einen längeren Ausschnitt. Mehrere Änderungen werden auf derselben Quellfassung zusammengesetzt, typgeprüft und fachlich getestet. [Implementierung in TIDE und ausführbare Beispiele](../../workbench/function_fragment.tide)

Eine zweite Änderung betrifft den Auftrag an das Modell. Die Werkbank kann im vorbereiteten Kontext ausdrücklich bestätigen, dass Verzeichnis, erreichbare Quellen und erster fehlgeschlagener Test aus derselben geprüften Arbeitskopie vorliegen. Die Sitzung soll daraus ihren ersten Vorschlag ableiten und bei einer konkreten Informationslücke weiter nachsehen. Im Vergleich bekam Python denselben Hinweis und dieselbe Ersetzungsoption. [Modellanweisung und Verwendung](../../workbench/README.md#einen-ausschnitt-im-funktionsrumpf-ersetzen)

Die neutrale Kontrollanweisung in diesem Versuch bezeichnete die Quellen als vollständig und erlaubte weitere Inspektionen. Schon in Versuch 16 hatte der äußere Auftrag zusätzlich auf den erfolgten Prüflauf hingewiesen. Hier liefert die Werkbank diesen Hinweis für Ausschnittreparaturen selbst. Der direkte Vergleich misst seinen Zusatznutzen gegenüber der neutralen Kontrollanweisung auf derselben aktuellen Grundlage.

## Neue Fehler und Abnahme

Die Grundlage waren die korrekt reparierten Projekte aus Versuch 16. Bei der Routenwahl verglich ein Profil im Gleichstandsfall den Stromverbrauch der neuen Route mit der Latenz der bisherigen. Das andere Profil verdrängte bei vollständig gleichen Werten die erste Route. Bei den Druckaufträgen zählte die gemeinsame Rundungsfunktion bei exakten Vielfachen einschließlich null einen zusätzlichen Bogen. Ein zweites Modul rechnete für Monochromdruck mit vier statt drei Seiten pro Bogen. Je Aufgabe lagen die beiden Regressionen in verschiedenen Dateien. [Ausgangsprogramme, Änderungen und Versuchsanordnung](versuchsplan.json)

| Fall | Öffentlich vor Reparatur | Verdeckt vor Reparatur | Nach den Referenzkorrekturen |
|---|---:|---:|---:|
| Routenwahl | 29/41 | 25/32 | 41/41 und 32/32 |
| Druckaufträge | 3/41 | 2/32 | 41/41 und 32/32 |

Die Ausgaben beider Sprachen stimmten vor der Reparatur, nach jeder isolierten Teilkorrektur und nach beiden Korrekturen für jede Eingabe überein. Jeder verbliebene Einzelfehler ließ mindestens einen öffentlichen und einen verdeckten Test scheitern. Öffentliche und verdeckte Eingaben waren disjunkt. Die Sitzungen bekamen den Vertrag, die vier erreichbaren Quelldateien in alphabetischer Reihenfolge und den ersten öffentlichen Fehlschlag. Die fehlerhaften Dateien und die Zahl der nötigen Änderungen kannte nur die Versuchsleitung.

## Messung

Jede Wiederholung nutzte eine frische Projektkopie und eine neue ephemere Codex-Sitzung mit `gpt-6-astra`, Denkaufwand `xhigh` und angeforderter Serviceklasse `priority`. Die monotone Uhr lief vom Start der ersten Fehlprüfung über die Kontextaufbereitung und Modellantwort bis zum bestandenen öffentlichen Test. Auf einer weiteren frischen Kopie wurden öffentliche und verdeckte Tests außerhalb der Messzeit wiederholt. Gesamttokens sind Eingabe plus Ausgabe aus der CLI. Eingabe-Cachetreffer sind eingeschlossen. Ausgewiesene Denktokens sind Teil der Ausgabe.

Die erste Serie verglich vollständige TIDE-Rümpfe, TIDE-Ausschnitte und Python-Ausschnitte. Nachdem die ersten TIDE-Sitzungen den fertigen Kontext erneut angefordert hatten, wurde ein eigener Zusatzversuch festgelegt. Er verglich TIDE-Ausschnitte mit der bisherigen und der ausdrücklichen Anweisung sowie Python mit der ausdrücklichen Anweisung. Pro Serie und Fehler gab es drei zeitlich benachbarte Dreierblöcke. Jede Bedingung stand je Fehler einmal an jeder Position. Alle Sitzungen liefen nacheinander. [Befehle der ersten Serie](messverfahren.json) · [Vorab festgelegter Zusatzversuch](zusatzplan.json) · [Änderungen am Messablauf](zusatzverfahren.json)

## Was die kürzere Antwort brachte

Bei der Routenwahl sank die Länge der kompakten JSON-Antwort in allen drei TIDE-Vergleichen von 497 auf 249 UTF-8-Byte. Beim Druck waren die beiden vollständigen Funktionsrümpfe bereits kurz. Hier wuchs die Antwort von 177 auf 197 bis 227 Byte, weil sie die alte und die neue Textstelle benannte. Die Bytezahlen beschreiben nur die abgegebene Reparatur.

Über alle sechs Blöcke brauchte TIDE mit Ausschnitten gegenüber TIDE mit vollständigen Rümpfen im gepaarten Median 20.210,5 Gesamttokens weniger und 1,03 Sekunden mehr. Beide TIDE-Bedingungen inspizierten in jedem Lauf die Arbeitskopie, mit insgesamt 21 beziehungsweise 26 Shellbefehlen. Python kam in allen sechs Läufen ohne Shellbefehl aus. Die Tokenersparnis umfasst auch weitere Modellübergaben nach Werkzeugaufrufen. Die reine Menge des abgeschriebenen Codes erklärt sie nicht. [Prompts, Antworten, Befehle und CLI-Zähler der ersten Serie](messung.json)

## Was der geprüfte Kontext brachte

| Zusatzversuch, jeweils sechs Läufe | Zeit bis zur Abnahme, Median | Gesamttokens, Median | Tokens nach Abzug der Cachetreffer, Median | Shellbefehle insgesamt |
|---|---:|---:|---:|---:|
| TIDE mit neutraler Anweisung | 16,06 s | 59.896 | 3.511,5 | 24 |
| TIDE mit ausdrücklichem Hinweis | 9,64 s | 19.812 | 1.870,5 | 0 |
| Python mit ausdrücklichem Hinweis | 7,96 s | 19.745,5 | 1.825,5 | 0 |

Mit dem Hinweis brauchte TIDE in allen sechs Paaren weniger Zeit und weniger Gesamttokens als TIDE mit der neutralen Anweisung. Die gepaarte Ersparnis nach Abzug der Cachetreffer lag im Median bei 1.623 Tokens. Vorher fragte jede der sechs Sitzungen erneut Informationen aus der Arbeitskopie ab. Eine versuchte sogar, die Antwort über die Standardeingabe an `./verify` zu geben. Der Prüfer testet die Dateien auf der Platte. Mit dem Hinweis erstellten alle sechs Sitzungen direkt eine bestandene Antwort. Die sichtbaren Quellpakete waren gleich. [Prompts, Modellantworten, Modellnutzung und Prüfergebnisse](zusatzmessung.json)

| TIDE mit Hinweis minus Python mit Hinweis | Zeitdifferenz, gepaarter Median | Gesamttokendifferenz, gepaarter Median | TIDE schneller | TIDE sparsamer |
|---|---:|---:|---:|---:|
| Routenwahl mit Gleichstand | −0,60 s | +15 | 2/3 | 0/3 |
| Druck mit Rundung | +3,14 s | +105 | 0/3 | 0/3 |
| Beide Aufgaben | +1,61 s | +86,5 | 2/6 | 0/6 |

Die Differenzen wurden innerhalb jedes Aufgaben- und Wiederholungsblocks gebildet. Die Kontextvorbereitung einschließlich der ersten Fehlprüfung beanspruchte bei TIDE 0,42 Sekunden und bei Python 0,02 Sekunden im Median. Der zusätzliche Aufwand bei der Rundung blieb auch nach Wegfall der überflüssigen Inspektionen sichtbar. Drei Wiederholungen je Fehler auf zwei bekannten Projekten erfassen weder andere Aufgaben noch andere Modelle. Angeforderte Serviceklasse, Antwortlatenz und Cachetreffer können auch zwischen frischen Sitzungen schwanken. [Auswertung aller Bedingungen](auswertung.json)
