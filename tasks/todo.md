# TIDE · Entwicklungsstand

## Roadmap in 20 Stufen

Die Kästchen stehen für die Abnahme der jeweiligen Roadmap-Stufe. Bestehende Teilfunktionen und abgeschlossene Einzelversuche sind im Entwicklungsstand darunter dokumentiert. [Ziele und Abnahmekriterien](plan.md#20-stufen-von-der-machbarkeitsstudie-zur-führenden-sprache)

- [x] 1. Ersten Anwenderfall und Erfolgsmassstab festlegen. [Bestellimport und Abnahme](../experimente/72_bestellimport_basis/bestellimport.md)
- [x] 2. Vergleichsaufgaben und verdeckte Abnahme fixieren. [15 offene Aufgaben](../experimente/72_bestellimport_basis/aufgaben.json) · [Nachweis über 15 versiegelte Aufgaben](../experimente/72_bestellimport_basis/versiegelung.json)
- [x] 3. Faire Ausgangsmessung durchführen. [TIDE und CPython auf den offenen Aufgaben](../experimente/72_bestellimport_basis/bericht.md)
- [ ] 4. Bestellimport bauen, ändern und den grössten Engpass messen
- [ ] 5. Studie unabhängig wiederholen und über die Alpha entscheiden
- [ ] 6. Bibliothek über fachliche Typen wiederverwenden
- [ ] 7. Öffentliche Paketschnittstelle migrieren
- [ ] 8. Mehrdateienänderung konsistent übernehmen
- [ ] 9. Inkrementelle Rückmeldung gegen Vollprüfung messen
- [ ] 10. Semantik von Entwicklung, Tests und AOT abgleichen
- [ ] 11. Grössten Laufzeitengpass der Anwendungen verbessern
- [ ] 12. API-Dienst bei Doppelzustellung und Neustart abnehmen
- [ ] 13. Lastbegrenzung und Abbruch nachweisen
- [ ] 14. Pakete unabhängig und reproduzierbar verteilen
- [ ] 15. Einstieg und Editor mit neuen Nutzern erproben
- [ ] 16. Zweite Plattform abnehmen
- [ ] 17. Betrieb, Upgrade und Wiederherstellung erproben
- [ ] 18. Zwei unabhängige Pilotprojekte begleiten
- [ ] 19. Echte Agentenkosten blind vergleichen
- [ ] 20. Führungsanspruch unabhängig bewerten und nächstes Gebiet wählen

## Ergebnisse der bisherigen Studie

Etappe 1 der [Machbarkeitsstudie](plan.md#machbarkeitsstudie-und-veröffentlichungsentscheidung) ist bestanden. Messdatei, Bericht und modulübergreifende Reparatur laufen ohne Python. Für Etappe 2 ist der Messbericht vorab übersetzbar und lokal mit CPython verglichen. Die gemessenen Faktoren liegen bei 18,0–31,4× einschliesslich Start und 6,3–8,4× für den warmen Rechenkern. Im lokalen Agentenvergleich löste Qwen3 4B 0/6 TIDE- und 2/6 Python-Reparaturen. Ein Nachversuch mit TIDE-Grammatikhilfe löste 0/6. Für diesen Ablauf ist kein Tokenvorteil pro korrekter Lösung belegt. [Laufzeitmessung](../experimente/53_vorabuebersetzung/bericht.md) · [Lokaler Agentenvergleich](../experimente/54_lokaler_agentenvergleich/bericht.md)

Die [ersten Selbstversuche](../experimente/erkenntnisse.md) sind abgeschlossen. Die [Schreibprobe](../experimente/05_schreibprobe.md) ergab vier korrekte Erstlösungen je Form. Offen ist ein Vergleich bei der Wartung fremder Zustandsregeln. Danach lässt sich der Ansichtswechsel bei einer Änderung über Funktionsgrenzen untersuchen. Die [ausführbare Fassung 0.3.0](../README.md) ergänzt Module, Records, Optionen, Datenimport mit Leserechten und revisionsgebundene Bearbeitungswerkzeuge. Die laufende Abnahme verwendet `make test` und die [nativen Prüfungen in TIDE](../native/bootstrap/checks.tide). Die Tabelle beschreibt die weiter gefassten Abnahmekriterien des Entwurfs.

`test --diff --explain=nodes` liefert Kandidaten für revisionsgebundene Knotenänderungen. Beim lokalen Vergleich an vier neuen Mehrdateienfehlern bestanden 0/12 TIDE-Knotenänderungen, 0/12 TIDE-Rumpfersetzungen und 3/12 Python-AST-Edits. Die bekannten Korrekturen bestanden alle 75 Fälle je Aufgabe. Ein Vorteil bei Erfolgsquote oder Gesamttokens ist für die TIDE-Knotenoberfläche in diesem Versuch nicht belegt. [Vergleich und Rohdaten](../experimente/55_knotenreparatur/bericht.md)

Mit `test --diff --explain=candidates` prüft TIDE Operatorwechsel lokal vor. Auf denselben vier Aufgaben steigen die Erfolge auf 6/12 für TIDE und 9/12 für Python-AST, jeweils ohne Modellanfrage. Einschliesslich einer mehrdeutigen fünften Aufgabe waren es 8/15 bei 531 Modell-Tokens für TIDE und 11/15 bei 555 für Python-AST. Die Vorprüfung spart bei beiden Verfahren Modellarbeit. Python-AST bleibt in dieser Messung bei den Tokens je Erfolg vorn. [Geprüfte Operatorwechsel](../experimente/56_gepruefte_operatoren/bericht.md)

TIDE 0.6.1 ergänzt `<=` und `>=`. Mit unveränderter Vorprüfung stieg TIDE auf 11/15 bei 531 Modell-Tokens. Die erneut gemessene Python-AST-Variante blieb bei 11/15 und 555 Tokens. Die drei zusätzlichen TIDE-Erfolge stammen aus der Kapazitätsaufgabe mit `<=`. [Wiederholungsmessung](../experimente/57_inklusive_vergleiche/bericht.md)

Die Vorprüfung berücksichtigt auch zwei kleine Ausdrucksersetzungen für `a*b+c`. Beim Rechnungszuschlag kommt dadurch in beiden Sprachen ein eindeutiger Kandidat ohne Modellaufwand durch alle Tests. Im selben Vergleich bestehen beide Verfahren 14/15 Läufe. TIDE verbrauchte 531 Modell-Tokens, Python-AST 555. [Ausdrucksvorprüfung](../experimente/58_ausdrucksvorpruefung/bericht.md)

`test --explain=candidates --probes` findet eine gültige Eingabe, an der grüne Kandidaten verschiedene Werte liefern. Bei der Restaufgabe trennte der unabhängig bestätigte öffentliche Fall `a=1, b=1 → 0` Restbildung und Quotient. TIDE und Python-AST erreichten damit je 15/15 bei null Modell-Tokens. [Gegenbeispiel und Wiederholungsmessung](../experimente/59_oeffentliches_gegenbeispiel/bericht.md)

Bei acht neuen Mehrdateienfehlern bestanden beide Verfahren mit gleicher Vorprüfung 84 von 96 Läufen ohne Modelltokens. Vom Start bis zur bestandenen Abnahme benötigte TIDE im Median 38,1 ms, Python-AST 88,8 ms. In den vier Aufgaben mit Gegenbeispiel waren es einschliesslich Suche und Bestätigung 39,7 ms gegenüber 91,4 ms. Der Fehler mit zwei nötigen Änderungen blieb auf beiden Seiten offen. [Gepaarte Reparaturzeitmessung](../experimente/60_reparaturzeit/bericht.md)

Mit `--pairs` findet die Vorprüfung beim Doppelzähler eine gemeinsame Korrektur in zwei Modulen. Beide Verfahren bestanden alle 96 Läufe ohne Modelltokens. Die Reparatur des Doppelzählers benötigte im Median 30,7 ms mit TIDE und 71,3 ms mit Python-AST. Für einen Mehrdateien-Patch prüft der Editor die Änderungen zusammen und gibt die geprüften Texte für eine Arbeitskopie aus. [Messung der dateiübergreifenden Paarsuche](../experimente/61_dateiuebergreifende_paare/bericht.md)

Bei fünf neuen Mehrdateienfehlern mit je zwei oder sechs öffentlich grünen Paaren fanden beide Verfahren nach einem oder zwei bestätigten Gegenbeispielen genau eine Korrektur. Beide bestanden 60 von 60 Läufen ohne Modelltokens. Die gesamte Reparatur dauerte im Median 51,8 ms mit TIDE und 115,5 ms mit Python-AST. [Messung mit mehreren grünen Paaren](../experimente/62_mehrdeutige_paare/bericht.md)

`--probe-range` erzeugt weitere Eingaben aus gültigen Ganzzahlspannen, wenn der feste Pool grüne Paare nicht trennt. Im Vergleich stiegen beide Verfahren von 12 auf 60 Erfolge bei je 60 Versuchen und 0 Modelltokens. Mit Erzeugung dauerte die Reparatur im Median 36,2 ms bei TIDE und 82,0 ms bei Python-AST. [Messung mit erzeugten Gegenbeispielen](../experimente/63_erzeugte_gegenbeispiele/bericht.md)

Ein `requires`-Beispielvertrag liefert die Eingabespannen für die Gegenbeispielsuche. TIDE und Python-AST leiteten dieselben Grenzen ab und bestanden je 60 von 60 Läufen ohne Modelltokens. Die gesamte Reparatur dauerte im Median 33,9 ms mit TIDE und 83,2 ms mit Python-AST. [Messung mit abgeleiteten Vertragsgrenzen](../experimente/64_vertragsgrenzen/bericht.md)

`requires` unterstützt jetzt direkte Vergleiche zwischen Ganzzahlparametern. In sechs Szenarien fanden beide Verfahren dieselben zulässigen Gegenbeispiele. Je 60 von 72 Läufen bestanden, bei 0 Modelltokens. Die Gleichwertigkeitskontrolle blieb mehrdeutig. Erfolgreiche Reparaturen dauerten im Median 39,5 ms mit TIDE und 95,2 ms mit Python-AST. [Messung mit Parameterbeziehungen](../experimente/65_parameterbeziehungen/bericht.md)

Versionierte lokale Pakete haben eigene Namensräume und explizite Exporte. Die Paketfassung des Messberichts nutzt `rowtext.parse` und `measurements.parse` aus zwei exakt gepinnten Abhängigkeiten. Der vorab übersetzte Bericht erreichte im Vergleich mit CPython je nach Grösse 12,66–17,91× vom Prozessstart bis zur Ausgabe. [Paketvergleich und Abnahme](../experimente/66_native_pakete/bericht.md)

## Ablösung des Python-Referenzsystems

Der Standardbuild, die Installation und die native Testsuite kommen ohne Python aus. Für Typdeklarationen samt transitiven Importen sind `check`, `fmt` und `test` nativ. `modules` liefert Importstellen und Revision auch für Anwendungen und die Reparaturwerkbank. Beim Einstieg in ein Projekt prüft der Starter gewöhnliche Lockdateien. `make test` führt zusätzlich die Editor- und Spielzustände an den originalen TIDE-Anwendungen aus. Reine Funktionen mit i64- und booleschen Parametern, Bedingungen, lokalen Bindungen und gewöhnlichen Aufrufen laufen einschließlich ihrer Beispiele im Standardpaket. Auch Listen dieser zwei Elementtypen, verschachtelte Faltungen und Listen als Ergebnisse laufen nativ. [Listenabnahme](../experimente/30_native_listen/bericht.md)

Regeln mit ganzzahligen oder booleschen Ereignissen und Ausgaben laufen einschließlich `scan`, Regelbeispielen und Ereignisspur nativ. [Regeln und Spuren](../experimente/31_native_regeln_und_spuren/bericht.md)

Der Checkout und das Paket verwenden ausschließlich native Werkzeuge. `context` und `hole` arbeiten auf denselben geprüften Funktionen und Regeln wie `check`. Vollständige Kandidatendateien lassen sich revisionsgebunden mit `edit --source` prüfen und schreiben. Mit `edit --edits` lassen sich Knoten derselben Datei auch über den Projekteinstieg in einem Modul ändern. [Prüfung der nativen Knotenänderungen](../experimente/35_native_knotenaenderungen/bericht.md) Text, Listen und Optionen der drei Grundtypen sowie die Suche mit Unicode-Indizes laufen über den öffentlichen Auswerter. [Textabnahme an Nano und Werkbank](../experimente/36_native_texte/bericht.md) Offen sind weitere zusammengesetzte Werte sowie Terminalbedienung und Schreiben von Dokumenten. [Native Quelländerungen](../experimente/34_native_quellaenderungen/bericht.md) Der historische Interpreter liegt im [Experimentarchiv](../experimente/referenzsystem/README.md). [Abnahme von Checkout, Installation und Inspektion](../experimente/32_native_inspektion/bericht.md)

Der zeilenweise Messbericht mit `fold_lines` verarbeitete 100 MiB mit 131,0 MiB/s und 1,84 MiB Spitzen-RSS im Median. CPython mit Streaming erreichte 25,6 MiB/s und 11,11 MiB. Beide meldeten einen ungültigen Wert in der vorletzten Zeile 13.107.199. [Messung mit drei Eingabegrössen](../experimente/67_zeilenstrom/bericht.md)

Beim Streaming-Messbericht sank die Zeit von der gespeicherten Parserkorrektur bis zu sieben grünen Tests im installierten TIDE von 5,28 auf 1,43 ms (Median). CPython lag bei 6,44 ms in der Nachher-Kontrolle. [Gepaarter Vergleich](../experimente/68_aenderung_bis_gruen/bericht.md)

## Etappen und Abnahmekriterien

Der [Messbericht](../apps/summary.tide) verarbeitet Messzeilen und gibt seinen Record nativ zurück. Space Invaders läuft mit allen sechs Phasen über `run` und `test`, einschließlich der verschachtelten Records, Listen und Optionen für die Spielwelt. Nanos öffentlicher Einstieg unterstützt den Puffer und die angeforderte Aktion als Paar. Die interaktive Terminalanbindung und der Zugriff auf Dokumente sind offen. [Nano-Prüfung](../experimente/49_zusammengesetzte_paare/bericht.md) [Messbericht](../experimente/43_native_records/bericht.md) · [Variantenprüfung](../experimente/44_native_varianten/bericht.md) · [Prüfung am vollständigen Spiel](../experimente/45_native_sammlungen/bericht.md)

Die [erste Fundstelle](../apps/peak_lines.tide) ist über `tide run` für übergebene Messzeilen nativ ausführbar. Sie verwendet ein optionales Paar aus Höchstwert und Zeilennummer. Der [Dateieinstieg](../apps/first_peak.tide) ruft denselben Rechenkern auf. Die öffentliche CLI bindet das Leserecht mit `--read input=PFAD`. [Prüfung von Paaren und Faltungen](../experimente/39_native_paare/bericht.md)

Die Reihenfolge folgt den späteren Etappen im [Forschungsplan](plan.md).

| Nr. | Aufgabe | Setzt voraus | Fertig und geprüft, sobald … |
|---|---|---|---|
| 1 | Präfixgrammatik, Operationssignaturen, Typregeln und Ausgabeformat aus dem [Sprachentwurf](../SPEC.md) festhalten. | – | Beide Maximum-Varianten, Funktionsaufruf, Leerfall, Typfehler und Überlauf haben kleine Quelldateien und erwartete Ergebnisse. Die Beispiele lassen sich eindeutig parsen. Sichtbarkeit, Zeilengrenzen und Fehlervorrang stehen fest. |
| 2 | Vergleichsaufgaben für drei Oberflächen derselben TIDE-Semantik vorbereiten. | 1 | Verdeckter Testkatalog, zwölf Aufträge, erlaubte Reparaturen und Messbedingungen sind festgehalten. Präfix, geklammert und Python-ähnlich ergeben dieselben Referenzbäume. Die Referenzprogramme bestehen die Ergebnis- und Grenzwerttests. |
| 3 | Eine Konstante vom Quelltext bis zur CLI ausführen. | 1 | `main` mit dem Rumpf `7` liefert per `tide run` die Zahl 7. Ein Syntaxfehler liefert per `tide check --json` eine maschinenlesbare Position. Größen- und Verschachtelungsgrenzen wirken beim Parsen. |
| 4 | Typisierte Funktionen und Ganzzahlarithmetik ergänzen. | 3 | `twice 7` ergibt 14. `eq 9 9` ergibt `true`, `eq 9 8` ergibt `false`. Falscher Argumenttyp, rekursiver Aufruf und Werteüberlauf haben eigene Tests, auch an beiden `I64`-Grenzen. |
| 5 | Optionen und lokale Entscheidungen ausführen. | 4 | Ein reines Maximumprogramm über eine Listen-Konstante verarbeitet negative Werte und eine leere Liste. Eine unvollständige Fallunterscheidung scheitert beim Prüfen. Der Test umfasst `fold`, `let` und beide Zweige von `case`. |
| 5a | Abfangbare Fehler auslösen, behandeln und weitergeben. | 5 | Die Summe aus 2 und 3 ergibt im Beispiel `some 5`, die Summe aus dem größten I64 und 1 ergibt `none`. Handler behandeln nur ihren Code und führen den Ersatz nur im Fehlerfall aus. Tests für `fail`, `raise`, Fehler im Ersatz und Fehler über Funktionsgrenzen prüfen `may_fail`, ursprüngliche Diagnose und CLI-Ausgabe. |
| 6 | Leserecht und Eingabeverarbeitung anschließen. | 5 | Das erste Dateiprogramm besteht die Tabelle im Entwurf, einschließlich CRLF als zusätzlichem Fall. Eine fehlende Bindung, ein falscher Argumenttyp, ungültiges UTF-8 und eine Überschreitung des Bytebudgets ergeben definierte Fehler. |
| 7 | Änderungsauftrag mit der ersten Fundstelle ausführen. | 6 | Das Programm gibt Wert und Position als Paar zurück. Die sichtbare Probe mit zwei Neunen erkennt gezielt die fehlerhafte Wahl der letzten Position und meldet Soll und Ist. Leere und ungültige Eingaben behalten das vereinbarte Verhalten. |
| 8 | Grenzen der Ausführung am normalen Programmeinstieg prüfen. | 5a, 7 | Die Grenzwerte sind dokumentiert. Tests unmittelbar am Limit und darüber decken Quellgröße, Arbeitsschritte, Eingabe und Gastspeicher sowie einen teuren Bibliotheksaufruf ab. Ein erschöpftes Budget beendet auch einen Lauf mit gültigem Handler. `catch E_LIMIT` und `catch E_CAPABILITY` scheitern beim Prüfen. Ungefangene Fehler hinterlassen eine leere Standardausgabe. |
| 9 | Änderungen an einem ausgewählten Programmknoten anwenden. | 7 | Der Vergleich im Messwertprogramm lässt sich von `>` auf `<` umstellen. Ein Edit am falschen Stand, eine falsche Stelligkeit oder ein Typfehler wird ohne Teiländerung verworfen. Zusammengehörige Teilbaumänderungen werden gemeinsam geprüft. |
| 9a | Einen offenen Teilausdruck im Editor prüfen. | 9 | Die Lücke am letzten `if` des Paar-Beispiels meldet `&ii`, gültige lokale Bindungen und verfügbare Rechte. Ein unvollständiger Entwurf kann keinen Lauf starten. Nach dem Einsetzen des korrekten Ausdrucks bestehen Typprüfung und Gleichstandsprobe. |
| 9b | Programmbeispiele und, bei positivem Versuch, Zustandsregeln prüfen. | 8, 9 | `tide test` erkennt die Gesamtzählung beim Alarm, falsches Ausschalten bei 80 und den vergessenen Reset beim Licht. `trace` zeigt den betreffenden Schritt aus demselben Beispiel. Eine geänderte Erwartung erscheint separat im Änderungsvergleich. |
| 9c | Versionsbindung, Aufrufeffekte und Diagnosekontext überprüfen. | 4, 8 | Eine falsche Katalogkennung wird sichtbar zurückgewiesen. Prüfer und Kurzreferenz berichten dieselbe Werkzeug- und Katalogfassung. Ein mittelbarer Lesezugriff ist beim Aufrufer sichtbar. Zweimaliges Formatieren ist bytegleich, die geparsten Beispiele bleiben erhalten. |
| 10 | Modellversuche und Zeitmessungen auswerten. | 2, 8, 9a | Der Bericht enthält Rohdaten für drei Schreibweisen, Ersttreffer, Gesamttokens pro gelöster Aufgabe und einen getrennten Vergleich von vollständiger Neuausgabe und gezielter Änderung. Die Laufzeit wird separat bewertet. |

**Prüfpunkte:** Nach Schritt 4 muss das erste eigenständige Programm vom CLI-Aufruf bis zur Ausgabe funktionieren. Nach Schritt 8 sollen `make test` und die beiden CLI-Beispiele aus dem Entwurf reproduzierbar durchlaufen. Schritt 10 prüft die Eignung der Sprache für die gemessenen Aufgaben.
