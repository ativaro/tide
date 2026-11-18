# TIDE · Forschungs- und Entwicklungsplan

## Machbarkeitsstudie und Veröffentlichungsentscheidung

TIDE ist eine Machbarkeitsstudie. Wir bündeln die Arbeit in drei Etappen. Jede endet mit einem Ergebnis, das die Entscheidung über die nächste Etappe trägt. Neue Fähigkeiten und Tests entstehen in TIDE. [Projektregel](../AGENTS.md)

| Etappe | Abnahme und Entscheidung |
|---|---|
| 1 · Einen vollständigen Arbeitsablauf belegen | Der bestehende Messbericht liest über die öffentliche CLI eine ausdrücklich freigegebene Datei und liefert den erwarteten Bericht. Ein eingebauter Fehler über Modulgrenzen wird ab dem fehlschlagenden Beispiel diagnostiziert und über die native Werkbank repariert. Geprüft werden auch fehlende Freigabe, ungültige Eingaben und die Abnahme des reparierten Programms. Installiertes Paket und Tests laufen ohne Python. |
| 2 · Nutzen im Vergleich messen | Derselbe Arbeitsablauf läuft mit einer idiomatischen CPython-Referenz durch dieselbe fachliche Abnahme. Lokale Messungen vergleichen Startzeit und Durchsatz bei kleinen und größeren Dateien. Falls der Tokenverbrauch untersucht wird, stehen Aufgaben, Abnahme, Anzahl der Modellläufe und Budget vorab fest. Wiederholungen und Fehlschläge gehen in die Bilanz ein. |
| 3 · Über Veröffentlichung entscheiden | Für eine erfolgreiche Studie genügt ein reproduzierbarer Vorteil in einer von zwei Messgrößen. Entweder läuft ein gleichwertiges TIDE-Programm auf einer repräsentativen Aufgabe schneller als CPython, oder dasselbe Modell braucht für eine korrekt abgeschlossene, gleichwertige Entwicklungsaufgabe mit TIDE weniger Gesamttokens. Der Bericht nennt Faktor, Streuung und Geltungsbereich des nachgewiesenen Vorteils. |

Build, Abnahme und Laufzeitmessungen laufen lokal ohne Modellaufrufe. Für Entwicklungsarbeit im Chat bekommt jede Runde ein klar abgegrenztes Etappenziel. Messreihen mit Modellaufrufen starten erst, wenn dafür ein separates Budget feststeht. Das persönliche Wochenkontingent ist dafür nicht eingeplant.

Nano und das Terminalspiel bleiben Demonstratoren für Editorlogik und Spielzustand. Interaktive Bedienung kommt wieder auf den Plan, sobald sie eine konkrete Frage der Studie beantworten kann.

## 20 Stufen von der Machbarkeitsstudie zur führenden Sprache

**Das erste Wettbewerbsfeld sind Datenwerkzeuge und Backend-Dienste**, die Menschen und Coding-Agenten gemeinsam entwickeln und über mehrere Versionen warten. Für diese Nutzer zählt, ob sie heute eine Anwendung schreiben, sie morgen sicher ändern und sie im Störungsfall wieder in Betrieb nehmen können. Der Vergleich umfasst deshalb Neuentwicklung, Erweiterung und Reparatur.

**Ausgangslage am 18. November 2026.** TIDE 0.6.5 hat typisiertes JSON, versionierte Pakete, HTTPS, SQLite und PostgreSQL. Beim 100-MiB-Streamingversuch erreichte eine frühere TIDE-Fassung den 5,12-fachen CPython-Durchsatz. Im jüngsten Werkzeugversuch lösten beide Sprachen neun von zehn Aufgaben. TIDE brauchte im Median 16,6 ms, Python-AST 29,6 ms. Die 6,6 % kürzeren TIDE-Protokolle wurden offline gezählt. In einem früheren tatsächlichen Modellversuch mit Qwen3 4B gelangen 0/6 TIDE- und 2/6 Python-Reparaturen. Die grösste offene Frage ist damit, wie gut ein Agent **neue** TIDE-Programme schreiben und später ändern kann. [Implementierungsstand](../README.md) · [Streaming](../experimente/67_zeilenstrom/bericht.md) · [Modulvorprüfung](../experimente/71_modulvorpruefung/bericht.md) · [Modellversuch](../experimente/54_lokaler_agentenvergleich/bericht.md)

### I · Entscheiden, ob sich die Sprache in der Praxis lohnt

| Stufe | Arbeit | Woran wir den Abschluss erkennen |
|---:|---|---|
| 1 | **Den ersten Anwender und seinen Auftrag festlegen.** Als ersten unabhängigen Anwendungsfall einen Bestellimport wählen. Er muss Lieferantenzeilen validieren, Bestellungen speichern und zurückweisen können. | Ein einseitiger Auftrag definiert Eingaben, Fehler und beobachtbares Ergebnis. Eine spätere Änderung, etwa Stornierungen nachzuliefern, gehört von Anfang an dazu. |
| 2 | **Einen verdeckten Vergleich aufbauen.** Als Startgrösse 30 Aufgaben aus drei Familien vorsehen, je zehn zum Schreiben, Erweitern und Reparieren. Aufgaben aus mehreren Projekten verwenden. | 15 Entwicklungsaufgaben und 15 bis zum Schluss zurückgehaltene Aufgaben sind nach Familie ausgeglichen. Akzeptanztests und Ressourcenbudgets stehen vor dem ersten Lauf fest. Die bisherigen zehn Reparaturen bleiben Regressionstests. |
| 3 | **Die Ausgangswerte messen.** TIDE und idiomatisches CPython erhalten für die offenen Aufgaben dieselben fachlichen Verträge, Daten und Rechte. | Ein reproduzierbarer Lauf weist Lösungsquote, Zeit bis zur Abnahme, Programmlaufzeit und Spitzenspeicher aus. Offline-Protokolltokens und tatsächlich verbrauchte Modelltokens haben eigene Spalten. Fehlversuche bleiben sichtbar. |
| 4 | **Den Bestellimport von der leeren Datei bis zur ersten Änderung bauen.** Den gesamten Pfad über CLI, Bibliothek und Datenbank gehen. Erst danach den teuersten beobachteten Engpass bearbeiten. | Beide Versionen bestehen dieselbe Abnahme, einschliesslich fehlerhafter Zeile, doppelter Lieferung und Stornierung. Ein Vorher-nachher-Paar zeigt, welchen Aufwand die erste Verbesserung tatsächlich beseitigt hat. |
| 5 | **Über die Veröffentlichung der Studie entscheiden.** Den Versuch aus einer sauberen Installation auf einer zweiten Maschine wiederholen. | Das bestehende Studienkriterium entscheidet über eine öffentliche Alpha. Ein reproduzierbarer Vorteil bei Programmlaufzeit oder tatsächlichen Modelltokens reicht. Bei Erfolg Quellstand, Installationsweg, Rohdaten und bekannte Grenzen zur Veröffentlichung vorbereiten. Bei offenem Ergebnis folgt ein gezielter Gegenversuch. |

### II · Grössere Programme schreiben und sicher ändern

| Stufe | Arbeit | Woran wir den Abschluss erkennen |
|---:|---|---|
| 6 | **Wiederverwendbare Typen an echten Programmen erproben.** Die erste mehrfach geschriebene Bibliotheksfunktion aus Import und Bericht herauslösen. Benutzerdefinierte Generika oder Funktionsparameter dort einführen, wo diese Abstraktion sie braucht. | Zwei Anwendungen nutzen dieselbe Implementierung für verschiedene fachliche Typen. Ein falscher Typ wird am Aufruf mit Quellstelle erkannt. |
| 7 | **Änderungen öffentlicher Paketschnittstellen beherrschbar machen.** Vorhandene Namensräume, Exporte und Versionspins für eine reale Migration nutzen. | Bei einer inkompatiblen Schemaänderung nennt das Werkzeug die betroffenen Verbraucher. Alte Verbraucher bleiben mit dem alten Pin baubar, migrierte bestehen die Abnahme mit dem neuen. |
| 8 | **Eine Änderung über mehrere Dateien als Ganzes übernehmen.** Die vorhandene, revisionsgebundene Edit-Vorschau bis zur sicheren Übernahme für ein ganzes Projekt führen. | Eine Änderung an Bibliothek, Aufrufer und Tests wird gemeinsam sichtbar. Veraltete Revision, Fehler beim Schreiben und Prozessabbruch lassen einen wiederherstellbaren, konsistenten Stand zurück. |
| 9 | **Den Weg von der Änderung zur Rückmeldung verkürzen.** Abhängige Module und Tests gezielt neu prüfen. | Bei Blatt-, Schnittstellen- und Paketänderung stimmt das inkrementelle Ergebnis mit einer sauberen Vollprüfung überein. Median und 95. Perzentil der Zeit bis Grün sind auf einem grösseren Projekt gemessen. |
| 10 | **Verlässliche Semantik über alle Ausführungswege sichern.** Für jede im Wettbewerbsfeld benötigte Sprachfunktion Beispiele gegen Entwicklungsmodus, Tests und vorab übersetztes Programm ausführen. | Eine veröffentlichbare Abdeckungsmatrix zeigt gleiche Werte, Fehlerorte und Budgets. Jede verbleibende Lücke hat ein minimales reproduzierbares Beispiel. |

### III · Datenwerkzeuge und Dienste unter echter Last betreiben

| Stufe | Arbeit | Woran wir den Abschluss erkennen |
|---:|---|---|
| 11 | **Laufzeit dort verbessern, wo reale Programme Zeit verlieren.** Textverarbeitung, typisierte JSON-Dekodierung und Datenbankzugriff im vollständigen Ablauf profilieren. | Für den grössten Anteil liegen Vorher-nachher-Messungen bei kleinen und grossen Datenmengen vor. Durchsatz, Startzeit, Spitzenspeicher und Fehlersemantik werden gemeinsam ausgewiesen. |
| 12 | **Einen ausfallsicheren API-Dienst liefern.** Einen Bestell-Webhook mit PostgreSQL, Transaktionen und wiederholbarer Zustellung bauen. | Doppelte Nachricht, Zeitüberschreitung und Neustart nach erfolgreichem Commit ergeben jeweils genau einen korrekten Geschäftsfall. Die gespeicherten Daten werden unabhängig geprüft. |
| 13 | **Nebenläufigkeit und Abbruch unter Last beherrschen.** Die vorhandenen HTTP-Worker um die vom Dienst benötigte Lastbegrenzung und Abbruchweitergabe ergänzen. | Ein Lasttest dokumentiert Durchsatz und 95. Perzentil der Antwortzeit. Abgebrochene Anfragen geben Verbindungen frei, und die Zahl wartender Arbeiten bleibt im festgelegten Budget. |
| 14 | **Pakete unabhängig verteilen und reproduzierbar bauen.** Auf den bestehenden exakten Pins eine überprüfbare Paketinstallation aufbauen. | Zwei eigenständige Projekte beziehen dieselbe Bibliothek. Eine saubere Maschine baut aus festgeschriebenen Inhalten offline, ein verändertes Paket wird erkannt, ein Upgrade lässt sich zurücknehmen. |
| 15 | **Die Sprache ohne Projektwissen benutzbar machen.** Einsteigerpfad, Bibliotheksreferenz und Editor-Navigation an den häufigsten Fragen aus den ersten Anwendungen ausrichten. | Drei bisher unbeteiligte Entwickler installieren TIDE, fügen ein Feld hinzu und beheben einen Mehrdateienfehler anhand der Anleitung. Zeit, Rückfragen und Abbrüche werden festgehalten. |

### IV · Vertrauen ausserhalb des Projekts gewinnen

| Stufe | Arbeit | Woran wir den Abschluss erkennen |
|---:|---|---|
| 16 | **Eine zweite Plattform tragen.** Als nächste Zielplattform Linux ARM64 neben Linux x86-64 vorschlagen. | Auf beiden Architekturen laufen Installation, Build, Tests und die zwei Referenzanwendungen ohne Python in der TIDE-Werkzeugkette. Plattformabweichungen sind reproduzierbar erfasst. |
| 17 | **Betrieb und Wiederherstellung nachweisen.** Einen Release-Kandidaten mit Diagnosen, Ressourcenmessung, Upgrade und Rückkehr zur Vorversion betreiben. | Der Dienst besteht einen 24-Stunden-Lauf samt unterbrochenem Upgrade und Datenbankneustart. Eine zweite Person kann einen gespeicherten Fehler anhand der Diagnose lokalisieren und den Betrieb wiederherstellen. |
| 18 | **Fremde Projekte über zwei Versionen begleiten.** Zwei unabhängige Teams sollen je eine selbst gewählte Anwendung bauen und später fachlich erweitern. Beiträge und Sprachvorschläge erhalten einen dokumentierten Weg bis zur Entscheidung. | Für beide Anwendungen liegen Erfahrungen mit Installation, fehlenden Bibliotheken, Wartung und Upgrade vor. Erfasst wird, ob die Teams TIDE freiwillig wieder wählen und ob sie eine Verbesserung selbst beitragen konnten. |
| 19 | **Den tatsächlichen Agentenvorteil blind messen.** Aufgaben und Implementierungen einfrieren. Mit eigenem, separat freigegebenem Versuchsbudget dieselben Modelle an unbekannten Aufgaben in beiden Sprachen arbeiten lassen. | Pro Aufgabenfamilie sind Erfolgsquote, alle Eingabe- und Ausgabetokens einschliesslich Fehlversuchen, Reparaturzeit und Streuung veröffentlicht oder zur Veröffentlichung aufbereitet. Ohne eigenes Modellbudget bleibt diese Aussage offen. Die übrige Entwicklung kann weiterlaufen. |
| 20 | **Den Führungsanspruch unabhängig prüfen und den nächsten Einsatzbereich wählen.** Eine externe Gruppe wiederholt die Schlussmessung mit den versiegelten Aufgaben. Für Dienste kommt neben Python ein idiomatischer Go-Vergleich hinzu. | Die Entscheidung benennt Einsatzbereich, Vergleichsversionen, nachgewiesene Vorteile und offene Nachteile. Bei Erfolg denselben Versuch für ein zweites Gebiet aufsetzen, etwa Entwicklerwerkzeuge. Bei gemischtem Ergebnis bestimmt der grösste gemessene Rückstand den nächsten Entwicklungszyklus. |

**Vorgeschlagener Massstab für Stufe 20.** Für den Anspruch „führend bei agentengestützten Datenwerkzeugen und Backend-Diensten“ soll TIDE auf den verdeckten Aufgaben mindestens ebenso viele korrekte Lösungen je Aufgabenfamilie erzielen. Als erste Zielmarke schlage ich einen reproduzierbaren Faktor von mindestens 2 bei tatsächlichen Gesamttokens je korrekter Lösung **oder** Zeit bis zur erfolgreichen Reparatur gegenüber Python vor. Der Vergleich mit Go prüft beim Dienst insbesondere Durchsatz, hohe Antwortlatenzen, Speicher und Betriebsaufwand. Welche Grenzen für den Anwender akzeptabel sind, wird in Stufe 1 vereinbart. Die drei 100×-Forschungsziele bleiben separat sichtbar. Kleine Stichproben und widersprüchliche Wiederholungen werden als offene Befunde ausgewiesen.

**Erster Arbeitsblock abgeschlossen.** Der Auftrag für den Bestellimport umfasst positionsgenaue Stornierung, Wiederholung und Rollback. Von 30 Aufgaben sind je fünf pro Familie offen und fünf lokal versiegelt. Auf den 15 offenen Aufgaben lösten die Werkzeuge jeweils 9/15, alle Referenzprogramme bestanden die Abnahme. Die Protokolle umfassten 3.187 Tokens für TIDE und 3.583 für CPython. Der vollständige Import bis zur ersten fachlichen Änderung ist der nächste Arbeitsblock. [Spezifikation](../experimente/72_bestellimport_basis/bestellimport.md) · [Lokale Ausgangsmessung](../experimente/72_bestellimport_basis/bericht.md) · [Aufgabenstatus](todo.md#roadmap-in-20-stufen)

## Drei 100×-Ziele

Ein Faktor von 100 bedeutet für dieselbe bestandene Aufgabe höchstens ein Hundertstel des jeweiligen Python-Vergleichswerts. Die drei Faktoren bleiben Forschungsziele und werden getrennt ausgewiesen. Für die Veröffentlichungsentscheidung gilt das oben beschriebene Kriterium. Die Reparaturzeit bleibt eine zusätzliche Messgröße.

| Messgröße | Vergleich |
|---|---|
| Laufzeit des fertigen Programms | Native TIDE-Ausführung gegen eine idiomatische bestehende CPython-Referenz bei gleicher Eingabe, Ausgabe und Fehlersemantik auf derselben Maschine. Rechenzeit bei warmem Prozess und Zeit vom Start bis zum Ergebnis getrennt messen. Buildzeit separat ausweisen. |
| Tokens je korrekt abgeschlossener Entwicklungsaufgabe | Dasselbe Modell schreibt, ändert oder repariert funktional gleichwertige Programme. Je Versuch die tatsächlich verbrauchten Eingabe- und Ausgabetokens sämtlicher Modellaufrufe summieren. Dokumentation, Toolantworten, Diagnosen und Wiederholungen zählen mit, soweit sie dem Modell übergeben werden. Cacheanteile und vom Anbieter ausgewiesene Denktokens separat berichten, ohne Doppelzählung. |
| Zeit je erfolgreicher Fehlersuche | Von der Übergabe desselben beobachtbaren Fehlers bis zum ersten bestandenen unabhängigen Abnahmelauf messen. Zeit für Kontextsuche, Diagnose, Bearbeitung und Tests einschließen. Reparaturversuche, Toolaufrufe, Regressionen und ungelöste Aufgaben zusätzlich ausweisen. |

Die Paarungen und Abnahmetests stehen vor dem Versuch fest. Beide Seiten bekommen denselben fachlichen Auftrag, dasselbe Modell mit demselben Budget und einen frischen Kontext. Für Reparaturen liegen bereits fehlerhafte Programme in beiden Sprachen vor. Die Reihenfolge wechselt. Pro Aufgabenfamilie berichten wir Abschlussquote, Gesamtverbrauch einschließlich gescheiterter Versuche, Median und Streuung der gepaarten Messungen. Ein Ergebnis für eine Aufgabenfamilie gilt für genau diese Aufgaben.

Im lokalen Vergleich vom 18. November 2026 lösten TIDE und CPython jeweils fünf von acht neuen Mehrdateienaufgaben. Im gepaarten Kontrollversuch mit zusammengelegter CPython-Suche und Übernahme erreichte TIDE die Abnahme im Median 1,94× schneller. Die offline gezählten Reparaturprotokolle waren über alle acht Versuche 9,4 % kürzer. Die tatsächlichen Gesamttokens eines Modells bleiben für diese Aufgaben offen. [Messbericht mit Abnahme und Rohdaten](../experimente/69_neue_mehrdateienaufgaben/bericht.md)

Auf zehn weiteren Dreidateienaufgaben erhöhte die Suche nach Argumenttausch, UTF-8-Bytelänge und letztem Trennzeichen die Erfolgsquote in beiden Sprachen von 1/10 auf 9/10 am Programmeinstieg. Bei direkter Zusatzprüfung des Zwischenmoduls bestanden jeweils 6/10. Für erfolgreiche Programmeinstiege brauchte TIDE im Median 16,6 ms und Python-AST 32,0 ms. Über alle zehn Versuche waren die TIDE-Protokolle 7,8 % kürzer. Die Messung lief lokal ohne Modellaufrufe. [Gepaarter Vorher-nachher-Vergleich](../experimente/70_strukturelle_reparatur/bericht.md)

Auf denselben zehn Aufgaben hob die direkte öffentliche Prüfung des Zwischenmoduls vor der Kandidatenauswahl die gemeinsame Abnahme von Einstieg und Modul für beide Werkzeuge von 6/10 auf 9/10. In allen drei betroffenen Projekten blieb der Einstiegscode erhalten. Für die erweiterte Prüfung benötigte TIDE im Median 16,6 ms pro erfolgreicher Reparatur, Python-AST 29,6 ms. Die zehn Protokolle umfassten 3.555 bzw. 3.808 offline gezählte Tokens. [Messbericht und reparierte Projekte](../experimente/71_modulvorpruefung/bericht.md)

**Bisheriger Stand.** Beim [Drei-Wege-Versuch](../experimente/07_dreiwege/bericht.md) umfassten Aufgabenpakete und Abgaben zusammen 2.847 Tokens in Präfix- und 2.966 in Python-ähnlicher TIDE-Schreibweise (`o200k_base`). Für das Saldoprogramm mit vier festen Buchungen liegen nun Messungen gegen echtes CPython und vier isolierte Modellläufe vor. Natives TIDE erreichte im warmen Stapel 174× Durchsatz und beim einzelnen Programmaufruf 39×. Der TIDE-Schreiblauf verbrauchte 78.662 Gesamttokens, Python 58.341. Die Reparatur derselben falschen Subtraktion dauerte 9,28 bzw. 7,29 Sekunden. Die Übertragbarkeit auf andere Aufgaben ist offen. [Messbericht mit Rohdaten](../experimente/11_saldo/bericht.md)

Im anschließenden [Versuch mit einem Funktionsrumpf pro Antwort](../experimente/12_funktionsrumpf/bericht.md) sanken die Gesamttokens auf 19.203 beim Schreiben und 19.117 beim Reparieren. Die Zeiten bis zum bestandenen Saldotest betrugen 6,82 bzw. 5,10 Sekunden. Für beide Aufgaben wurde die Prüfung außerhalb des Modellaufrufs erledigt.

Bei der [Reparatur mit unbekanntem Fehlerort](../experimente/13_mehrdateien/bericht.md) mussten zwei von vier Modulen gemeinsam korrigiert werden. TIDE bestand 20/20 Fälle mit 58.789 Tokens in 13,67 Sekunden, Python mit 58.824 Tokens in 13,54 Sekunden. Beide Reparaturen gelangen im ersten Versuch.

Beim nächsten [Mehrdateienfehler in der Paketannahme](../experimente/14_projektkontext/bericht.md) reduzierte vorbereiteter Projektkontext die TIDE-Reparatur von 79.628 auf 19.833 Tokens und von 21,37 auf 6,96 Sekunden. Python mit vorbereiteten Quellen bestand dieselben 25 Fälle mit 19.861 Tokens in 10,18 Sekunden. Je Bedingung gab es einen Modelllauf.

Im [Folgeversuch mit drei neuen Fehlern und vier Paaren je Fehler](../experimente/15_gepaarte_reparaturen/bericht.md) bekamen beide Sprachen vorbereiteten Kontext. TIDE war in 3/12 Paaren schneller und verbrauchte in 3/12 weniger Gesamttokens. Im Median der Paardifferenzen brauchte TIDE 3,07 Sekunden und 186,5 Tokens mehr. Alle 24 Antworten bestanden die Abnahme im ersten Versuch.

Im [Blindversuch mit gruppierten Funktionsrümpfen](../experimente/16_gruppierte_reparaturen/bericht.md) sparte die neue TIDE-Bearbeitung gegenüber dem bisherigen Textedit im Median der acht Vergleichspaare 3,08 Sekunden und 190,5 Gesamttokens. Gegen Python mit ebenfalls benannten Reparaturen brauchte TIDE 0,97 Sekunden und 110 Tokens mehr. Alle 32 Reparaturen bestanden die Abnahme- und Kontrollfälle. Bei priorisierten Vergleichen bleiben wiederholte Feldzugriffe und verschachtelte Bedingungen im Antworttext sichtbar. Ein nächster Kandidat ist eine wiederverwendbare Vergleichsoperation für einen Hauptschlüssel mit nachgeordnetem Entscheidungskriterium.

Beim [Blindversuch mit gemischten Prioritäten](../experimente/17_prioritaeten/bericht.md) verwendete das Modell die neuen TIDE-Vergleichsfunktionen in einer von zwölf Reparaturen mit eingebundener Bibliothek. Gegenüber TIDE ohne Bibliothek kostete das Angebot im Median der gepaarten Vergleiche 2,98 Sekunden und 144 Gesamttokens mehr, gegenüber Python 3,97 Sekunden und 359 Gesamttokens mehr. Alle 36 Reparaturen bestanden je 40 öffentliche und 40 verdeckte Fälle, eine benötigte eine zweite Antwort für eine fehlende schließende Klammer. Die Bibliothek bleibt optional.

Die [lokale Korrektur nach einer Parserdiagnose](../experimente/18_lokale_syntaxreparatur/bericht.md) ersetzte beim Replay des konkreten Klammerfehlers eine zweite Modellantwort mit 20.708 Tokens. Auf einer neuen Journalregression gelangen alle acht Blindläufe im ersten Versuch. Hier kostete TIDE bei vier Paaren im Median 2,63 Sekunden und 195,5 Gesamttokens mehr als Python. Die Vorbereitung des TIDE-Kontexts benötigte im Median 0,58 Sekunden gegenüber 0,04 Sekunden bei Python.

Beim [Aufbau der gruppierten Reparaturansicht](../experimente/19_kontextaufbau/bericht.md) verringerte die Werkbank die Vorbereitungszeit in 24/24 lokalen Messpaaren bei identischen Kontexten. Nano `step` passt nun mit seinen 14 erreichbaren Funktionsrümpfen ins Arbeitsbudget. Vom ersten fehlgeschlagenen Test bis zum vollständigen Prompt brauchte TIDE beim Journal im Median 372 ms, Python 33 ms. Die Referenz-CLI startet weiterhin einen eigenen Prozess für jeden abgefragten Funktionsrumpf.

Der [native Versuch für verzweigte i64-Ausdrücke](../experimente/20_native_ausdruecke/bericht.md) übersetzt eine Integer-Faltung mit Bedingungen und geprüfter Arithmetik. Bei den Heizgradstunden lag der Faktor gegen CPython im warmen Durchsatz bei 33,8×, beim Einzelstart bei 48,1×. Alle 29 Differentialfälle stimmten bei Wert oder Überlaufcode mit der TIDE-Referenz überein.

Bei [wechselnden Positionsargumenten](../experimente/21_native_eingaben/bericht.md) verarbeitete dieselbe native Datei leere Listen, 16 und 4.096 Temperaturen. Die gepaarten Faktoren einschließlich Start und Eingabebindung waren 23,9×, 23,7× und 16,5× gegen CPython. Die Referenzprüfung deckte insbesondere beide i64-Grenzen, Eingabefehler und die exakte Arbeitsgrenze von 100.000 Schritten ab. Native Record-Verarbeitung und Datei-Eingabe bleiben offen.

Im [Blindversuch mit Ausschnittreparaturen](../experimente/22_fragmentreparatur/bericht.md) senkte der ausdrückliche Hinweis auf bereits geprüfte Quellen und den Testlauf gegenüber dem neutralen TIDE-Auftrag die gepaarten Mediane um 6,82 Sekunden und 40.073 Gesamttokens. Gegen Python mit demselben Hinweis lag TIDE um 1,61 Sekunden und 86,5 Tokens zurück.

Der [native Divisionsversuch](../experimente/23_native_division/bericht.md) deckt vorzeichenbehafteten Quotienten und Rest auch an den i64-Grenzen ab. Beim Kartonsaldo mit 4.096 Buchungen lag der gepaarte Faktor für den vollständigen Prozessaufruf bei 18,0× gegen CPython. Ein bei der Grenzprüfung gefundener doppelter Stapelaufbau im Compiler wurde beseitigt. Die beiden zuvor am Compilerbudget gescheiterten Testprogramme lassen sich jetzt unter demselben Limit übersetzen.

Die [nativen Zustandsregeln](../experimente/24_native_regeln/bericht.md) verarbeiten die unveränderten Anwendungen für Hitze, Pumpe und Licht. 384 Ereignisfolgen und 15 Fälle an der Arbeitsgrenze stimmten mit der Referenz überein.

Beim [Blindversuch mit Jury und Depot](../experimente/25_blinde_quellreparatur/bericht.md) sparte eine neue Quellansicht im gepaarten Median 0,16 s für die Vorbereitung. Bis zur Abnahme benötigte sie gegenüber vollständig geklammertem TIDE 1,81 s und 53,5 Gesamttokens mehr, gegenüber Python 1,97 s und 152 Tokens mehr. Alle 18 Erstvorschläge bestanden die öffentliche und verdeckte Abnahme.

Die [native Stapelabfrage für geklammerte Ausdrücke](../experimente/26_native_reparaturansicht/bericht.md) ersetzt bei den vier geprüften Projekten den separaten Referenzprozess pro Funktion. Gemessen wird die Zeit bis zur fertigen Ansicht.

Die [native Typprüfung](../experimente/27_native_typpruefung/bericht.md) vergleicht die öffentlichen Befehle für einzelne Typdateien mit der Referenz und misst die vollständige Prozesslaufzeit von `check`. Native Anwendungsprüfungen führen Nano- und Spielzustände durch die kompilierten TIDE-Quellen.

Die [native Modulprüfung](../experimente/28_native_module/bericht.md) vergleicht transitive Typreferenzen, Dateipositionen, Reihenfolge und Revisionsbindung. Der Modulgraph ist auch während einer Reparatur mit unvollständigem Rumpf abrufbar.

Die [native Funktionsausführung](../experimente/29_native_funktionen/bericht.md) prüft das Rangfolgemodul mit seinen Beispielen, Aufrufe über mehrere Dateien und die exakte Arbeitsgrenze. Der Laufzeitvergleich trennt wiederholte von stets verschiedenen Argumenten.

## Bisheriger Forschungsplan

**Aktuelle Forschungsfrage.** Hilft mir diese Darstellung, wenn ich selbst ein unbekanntes Programm verstehen, ändern oder einen mehrdeutigen Auftrag klären soll? Der [Sprachentwurf](../SPEC.md) liefert Kandidaten für Versuche. Der [lokale Interpreter 0.3.0](../README.md) führt Daten- und Ereignisprogramme aus. Katalog, Quellkontext, typisierte Ersetzung und Zustandsspur stehen für weitere Versuche bereit.

Die [ersten Versuche](../experimente/erkenntnisse.md) sind ausgewertet. In 16 kurzen Aufgaben habe ich mit beiden Schreibweisen alle Erstversuche bestanden. Bei vier bekannten Regelpaaren waren meine selbst gewählten Gegenbeispiele bereits minimal. Beim ersten Auftrag des Nutzers zum Temperaturalarm war meine erste Interpretation richtig. Nach einer kurzen Rückmeldung gab ich eine ausdrückliche Bedingung auf. Für den nächsten Dialogversuch prüfen wir, ob mir ein Gegenbeispiel aus der ursprünglichen Anforderung hilft, eine Erläuterung einzuarbeiten, ohne eine andere Regel unbemerkt zu ändern.

**Schreib- und Wartungsversuch zu Entwurf 0.3.** Ich habe neue Aufgaben zur Positionsmarke, Reservierung, Bonusbuchung und Pause in beiden Formen gelöst. Alle vier Schrittfunktionen und alle vier Regeltabellen waren beim ersten Versuch korrekt. Die Regelrümpfe kosteten in diesen Abgaben rund 55 % mehr Quelltext-Tokens. Beim Wechsel des Bonus-Startwerts von 1 auf 3 genügte für beide Formen eine einzige Änderung an derselben benannten Definition. Einen zusätzlichen Wartungsvorteil von `reset` habe ich hier nicht beobachtet. Die Regeltabelle bleibt ein optionaler Forschungskandidat. [Schreibprobe](../experimente/05_schreibprobe.md) · [Wartungsversuch](../experimente/erkenntnisse.md)

Getrennt davon bleibt die Änderung über zwei Funktionen eine offene Frage. Dort kann ich zwischen kompakter und aufgeklappter Ansicht wechseln. Bei beiden Versuchen zeigt der Beispielvergleich, wenn eine Änderung einen zuvor bestätigten Fall verletzt.

**Prüfungen zu den neun Entwurfsfragen.** Für lokale Fehlerdiagnosen und Aufrufkontext vergleichen wir gleichartige Reparaturen mit und ohne den Eintrag aus dem gebundenen Operationskatalog. Davon getrennt lassen sich technische Zusagen objektiv prüfen: Ein absichtlich vertauschter Katalog muss eine Versionsabweichung melden, ein mittelbarer Dateizugriff im Aufrufgraphen sichtbar sein und die Formatierung denselben Syntaxbaum ergeben. Erstversuchsquote und Tokenaufwand gehören zum Selbstversuch, Reproduzierbarkeit und Typkorrektheit zu den Werkzeugprüfungen. [Sprachentwurf 0.3](../SPEC.md)

## Entwicklungsoptionen nach der Forschungsphase

Die [Quellenrecherche zum Sprachdesign](../experimente/recherche-sprachdesign.md) ergänzt mögliche Versuchsbedingungen für Zustandsregeln, Fehlersuche und unterschiedliche Programmansichten.

Die folgenden Etappen beschreiben den Gesamtentwurf. Der erste ausführbare Kern deckt bereits Funktionen, Zustandsregeln, Beispiele und typisierte JSON-Eingaben ab.

| Etappe | Was wir bauen oder entscheiden | Woran wir das Ergebnis erkennen |
|---|---|---|
| 1 · Sprachkern festlegen | Die kompakte Präfixgrammatik, die Operationstabelle und die Typregeln an den Beispielen festlegen. Gültige und ungültige Programme sowie ihre exakten Ausgaben festhalten. Den LLM-Vergleich vorbereiten. | Das ursprüngliche und das geänderte Messwertprogramm lassen sich mit denselben allgemeinen Regeln beschreiben. Fehlende Operanden und ein unvollständiges `case` haben eindeutige Prüfergebnisse. |
| 2 · Erstes Programm ausführen | Einen lokalen Interpreter mit Parser, Typprüfung und den Befehlen `check` und `run` bauen. Zuerst eine reine Funktion aufrufen. Danach Typfehler und Überlauf durch denselben Ausführungspfad prüfen. | Ein `main`, das `twice 7` zurückgibt, liefert `14`. `twice "7"` wird mit Quellposition zurückgewiesen. Die Ausführung benötigt keinen Modelldienst. |
| 3 · Messreihe verarbeiten | Optionen, Listen, Paare, Schleifen und begrenztes Einlesen ergänzen. Die Dateieingabe an ein vom Starter geöffnetes Handle binden. Die Änderungsaufgabe als zweites Programm ausführen. | Beide Programme bestehen die Beispieltabelle und die Grenzfälle. Fehlende Leserechte und erschöpfte Budgets ergeben die vereinbarten Fehler. |
| 4 · Sprachentwurf bewerten | Programmier-, Änderungs- und Reparaturaufträge mit drei Oberflächen derselben TIDE-Semantik vergleichen. Auf demselben Rechner die Laufzeit korrekter Messwertprogramme vergleichen. | Ein Bericht enthält Rohwerte, Fehlertypen und die Entscheidung, welchen Teil der Sprache wir beibehalten oder überarbeiten. |

Etappe 2 braucht die Kernregeln aus Etappe 1. Die kleinen Testprogramme und die Python-Vergleichsfassung lassen sich bereits in Etappe 1 vorbereiten. Erste Modellversuche sind mit den reinen Funktionen aus Etappe 2 möglich. Der vollständige Vergleich nutzt den eingefrorenen Stand nach Etappe 3. Die [Arbeitsliste](todo.md) enthält die Reihenfolge und die einzelnen Prüfschritte.

Zur Fehlerbehandlung bauen wir zuerst den Weg von einer fehlgeschlagenen Operation bis zur CLI. Dann ergänzen wir selektive Handler und die vom Prüfer ermittelte Fehlermenge pro Funktion. Die Abnahme vergleicht denselben Überlauf einmal ungefangen und einmal mit Ersatzwert. Ein verschachtelter Fall prüft zusätzlich, dass ein Fehler im Ersatz den äußeren Handler erreicht und ein erneutes Auslösen die ursprüngliche Quellposition behält. Am Dateibeispiel prüfen wir die Trennung von Quellposition und Eingabezeile.

## Historischer Vorschlag für einen Rust-Interpreter

Wir schreiben den Referenzinterpreter in Rust und lassen ihn zunächst den typgeprüften Syntaxbaum direkt auswerten. So können wir Syntax oder Diagnosen ändern, während der Sprachkern noch klein ist. Der Interpreter führt nur eigene, fest eingebaute Operationen aus. Für den eigenen Rust-Code schlagen wir `#![forbid(unsafe_code)]` vor. Die Abhängigkeiten bleiben Teil der Vertrauensbasis. [Rust-Dokumentation zum Lint](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code)

Der geplante Aufbau bleibt klein. `src/` enthält CLI, Parser, Typprüfung und Auswertung. `examples/` enthält die beiden Messwertprogramme. `tests/` prüft das Verhalten über dieselben Befehle, die später das Modell benutzt. Ein Bytecode- oder nativer Compiler wird dann eine begründete nächste Investition, wenn Messungen den Interpreter als Engpass zeigen.

## Zwei Versuche mit Entscheidungskriterien

**1. Welchen Unterschied macht die Oberfläche für mich?** Im Drei-Wege-Selbstversuch gelangen alle zwölf Aufgaben in jeder Form beim ersten Versuch. Klammerfreies Präfix hatte die kürzesten Abgaben. Bei einem gelöschten Summanden lokalisierte geklammertes Präfix den unvollständigen Aufruf unmittelbar. Getrennte Kontexte und Aufgaben fremder Herkunft stehen noch aus. [Bericht zum Drei-Wege-Versuch](../experimente/07_dreiwege/bericht.md). Ein späterer Vergleich mit echtem Python untersucht das gesamte Sprach- und Werkzeugpaket. Der Vergleich von Baumersatz und vollständiger Neuausgabe sowie zusätzliche Typinformationen im Editor bleiben getrennte Versuchsbedingungen.

**2. Wie schnell läuft das fertige Programm?** Wir vergleichen das korrekte TIDE-Programm mit einer CPython-Fassung mit denselben Eingabe-, Fehler- und Gleichstandsregeln. Kleine, mittlere und große Dateien enthalten 10, 1.000 und 100.000 Werte. Je Größe messen wir 30 Läufe pro Sprache in wechselnder Reihenfolge. Ein Lauf misst Prozessstart bis Ergebnis, eine zweite Messung die reine Verarbeitung im bereits gestarteten Prozess mit vorab gelesenen Daten. Ergebnisse werden auf Gleichheit geprüft. Berichtete Werte sind Median, 95. Perzentil und maximaler Prozessspeicher, zusammen mit Rechner, Softwareversionen und Budgetwerten.

Der historische Vorschlag für den Referenzinterpreter sah bei 100.000 Werten eine Verarbeitungszeit innerhalb des Zweifachen der Python-Referenz vor. Für die native Sprache gelten die drei oben festgelegten Ziele.

## Entwurfsexperiment · Eine fachliche Frage aus zwei Programmen gewinnen

Bei einem mehrdeutigen Änderungsauftrag könnte das Modell zwei plausible, typkorrekte Programmfassungen vorschlagen. Das Entwicklungswerkzeug verwirft zuerst jede Fassung, die ein vorhandenes, weiterhin gültiges Beispiel verletzt. Für die verbleibenden Fassungen sucht es eine kleine Eingabe, bei der die beobachtbaren Ergebnisse auseinandergehen. Die Person, die den Auftrag kennt, bekommt diese konkrete Entscheidung vorgelegt. Ihre Antwort kann auch ein drittes Ergebnis sein. Die gewählte Erwartung wird als Beispiel für spätere Änderungen gespeichert.

In einem lokalen Python-Versuch haben wir für zwei Aufträge je zwei von Hand formulierte Regeln verglichen. Pro Auftrag wurden alle 121 Folgen der Länge 0 bis 4 über drei möglichen Werten geprüft. Sortiert wurde zuerst nach Eingabelänge, dann nach der unten angegebenen Reihenfolge der Werte.

| Auftrag | Welche Beispiele beide Regeln bereits erfüllen | Welche Frage der Vergleich sichtbar macht |
|---|---|---|
| „Liefere den zweitgrößten Messwert.“ Werte 1, 2, 3. | Eine leere Liste und ein Einzelwert liefern nichts. Für `[1,3,2]` liefern beide Regeln 2. | 60 Folgen unterscheiden „zweiter Platz mit Wiederholung“ von „zweitgrößter verschiedener Wert“. Die kürzeste ist `[1,1]` mit den Ergebnissen 1 und leer. Soll zwischen zwei Zahlen entschieden werden, eignet sich `[1,2,2]`: 2 oder 1? |
| „Baue einen zusätzlichen Import, der fehlerhafte Zeilen überspringt.“ Zeilen `0`, `1`, `x`. | Eine leere Datei liefert leer. Aus den Zeilen `x, 0, 1` gewinnen beide Varianten das Maximum 1. | Vier Folgen unterscheiden sich. Alle enthalten ausschließlich ungültige Zeilen. Schon die Datei `x` trennt die Varianten: leerer Erfolg oder `E_DATA` in Zeile 1? |

Der Versuch findet Unterschiede zwischen vorgegebenen Regeln. Das Erzeugen guter Kandidaten aus einem Auftrag ist ein eigenes, offenes Problem. Für einen Versuch im TIDE-Editor genügen zwei Kandidaten, synthetische Eingaben und ein festes Suchbudget. Findet die Suche keinen Unterschied, zeigt sie den geprüften Eingabebereich an. Erst eine fachlich geklärte Fassung wird als Programm übernommen. Die Auswahl findet während der Entwicklung statt. Ein ausgeliefertes Programm braucht dafür kein Modell.

## Weitere Vorschläge aus dem Review

- **Bereichstypen und Sättigung.** Für einen Zähler könnte der Wertebereich 0 bis 3 zum Typ gehören. Ein eigens benanntes sättigendes Inkrement würde am Maximum bleiben. Gewöhnliche Addition behält ihre Überlaufregeln. Auch der vorhandene I64-Typ ist endlich; der kleine Bereich erleichtert die vollständige Untersuchung. Zuerst an einer weiteren Zähleraufgabe prüfen, ob der neue Typ das Modellieren tatsächlich vereinfacht.
- **Verhaltensunterschiede.** Bei deterministischen Regeln mit endlichem, durchsuchbarem Produktzustand und vollständigen Ereignisklassen kann eine Breitensuche die kürzeste unterscheidende Folge liefern. Für den Hitzezähler reichen die Klassen „über 80“ und „höchstens 80“, weil die genaue Höhe in beiden Varianten keine weitere Wirkung hat. Im Modellversuch trennt `hoch, niedrig, hoch, hoch` die Serienregel von der Gesamtzählung erstmals nach vier Schritten. Alle kürzeren Folgen beider Klassen wurden geprüft. Bei willkürlichen Stichproben oder erschöpftem Suchbudget ist nur der untersuchte Bereich bekannt.
- **Zweigabdeckung und Priorität.** Eine Zählung der tatsächlich gewählten `when`-, `else`- und `case`-Zweige kann fehlende Beispiele zeigen. Für die Lichtregel sind beim Start mit Bewegung sowohl `motion` als auch `eq missed 0` wahr. Der zweite Zweig ist trotzdem bei einer ersten Ruhemeldung erreichbar. Einen beobachteten Überlapp mit Zeugen melden; „ungetestet“, „überlappt“ und „nachweislich unerreichbar“ müssen unterschieden werden. Die priorisierte Semantik bleibt erhalten.
- **Datenformen und Zeit.** Benannte Felder zunächst mit einem Ereignis testen, bei dem zwei gleich typisierte Werte vertauscht werden können. Für Zeitregeln zuerst klären, ob Ereigniszeit, Ankunftszeit oder verstrichene Dauer gemeint ist und was bei Lücken gilt. Das ist eine eigene Aufgabenfamilie.
- **Name.** TIDE steht für Typed Instructions, Deterministic Execution. Quelldateien verwenden die Endung `.tide`.

## Abnahme eines späteren Prototyps

Die funktionale Abnahme verlangt korrekte Ergebnisse und reproduzierbare Diagnosen für beide Messwertprogramme. Falls der Zustandsversuch die Regelform stützt, kommen die Beispiele aus Entwurf 0.3 hinzu: Ein vergessener Reset muss das Lichtbeispiel bei Schritt 3 verletzen, die gezielte Spur für Schritt 2 den alten und neuen Zählerwert zeigen. Die Sicherheitsabnahme verlangt Tests für Typprüfung, Rechte und Ressourcenlimits einschließlich großer und tief geschachtelter Eingaben. Der Vergleichsbericht bewertet die beiden Zwischenziele getrennt. Ein verfehltes Ziel bleibt als offener Befund sichtbar und bestimmt den nächsten Entwicklungsschritt.
