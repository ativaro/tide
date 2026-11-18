# TIDE · Sprachentwurf 0.3

Ein TIDE-Programm soll lokal ohne Sprachmodell laufen. Der Mensch beschreibt das gewünschte Verhalten und legt die Zugriffsrechte fest. Das Modell schreibt und ändert die Funktionen. **Bestätigte Beispiele gehören zur selben Programmversion wie der Code.** So lässt sich bei einer Änderung prüfen, ob eine bereits getroffene fachliche Entscheidung weiterhin gilt.

**Stand vom 16. November 2026.** TIDE steht für **Typed Instructions, Deterministic Execution**. Die [aktuelle ausführbare Fassung](README.md) und die [Sprachreferenz](LANGUAGE.md) dokumentieren den heutigen Implementierungsstand. Dieser Text hält den ursprünglichen Entwurf und seine Begründungen fest. Der Entwurf legt das Format der Programmbeispiele fest. Die neue Regelform für Zustandswechsel und ihre zwei Ansichten sind Vorschläge aus der Forschungsphase. In den bisherigen Versuchen fand ich die Fehler von Pumpe und Licht sowohl mit als auch ohne Zustandsspur. Beim untersuchten Lichtfehler war der falsche Ruhezähler einen Schritt vor der falschen Ausgabe sichtbar. Ob eine Spur meine Trefferquote oder Bearbeitungszeit verbessert, ist eine offene Hypothese. In der [Schreibprobe](experimente/05_schreibprobe.md) waren alle vier normalen Funktionen und alle vier Regeltabellen beim ersten Versuch korrekt. Die Regelrümpfe waren gemessen in Tokens länger. Beim Wechsel eines gemeinsam benannten Bonus-Startwerts von 1 auf 3 genügte in beiden Formen dieselbe Änderung an der Definition. Ob mir die Regelform bei anderen Wartungsaufgaben hilft, ist offen. [Versuchsprotokoll](experimente/erkenntnisse.md)

## Was „dreimal hintereinander“ im Programm bedeutet

Bei drei aufeinanderfolgenden Temperaturen über 80 ist erstmals ein Alarm fällig. Für die Entscheidung genügen vier Zählerstände: 0, 1, 2 und 3 für „mindestens drei“. Ein Wert von 80 oder darunter beendet die Serie. In der vorgeschlagenen Regelform steht der Rücksetzfall dort, wo ich ihn beim Ändern sehen kann.

```tide
rule heat_ready temperature:i > b
state streak:i=0
when > temperature 80 -> streak=set if < streak 3 + streak 1 3
else -> streak=reset
out eq streak 3

example heat_three heat_ready
{"events":[70,81,95,82],"expect":[false,false,false,true]}

example heat_interrupted heat_ready
{"events":[81,70,95,82],"expect":[false,false,false,false]}

example heat_boundary heat_ready
{"events":[81,80,95,82],"expect":[false,false,false,false]}
```

Die ersten beiden Beispiele verwenden dieselben Messwerte. Eine Änderung auf „alle Werte über 80 zählen“ würde im zweiten Beispiel beim vierten Ereignis ein falsches `true` liefern. `heat_ready` gibt pro Messung an, ob die Bedingung gerade erfüllt ist. Wann nach dem ersten Alarm erneut ein Signal gesendet werden soll, ist eine eigene, offene fachliche Entscheidung.

## Ein Ereignis, ein Zustandswechsel

Die Pumpe startet unter 20 und stoppt über 80. Bei genau 20 oder 80 gilt ebenso wie dazwischen der bisherige Zustand. Das Beispiel erreicht 20 einmal bei ausgeschalteter und einmal bei laufender Pumpe.

```tide
rule pump level:i > b
state on:b=false
when < level 20 -> on=set true
when > level 80 -> on=set false
else -> on=keep
out on

example pump_limits pump
{"events":[20,19,20,80,81],"expect":[false,true,true,true,false]}
```

Beim Licht betrifft eine Bewegung zwei Felder gleichzeitig. Sie schaltet das Licht ein und setzt den Ruhezähler zurück. Der Zähler unterscheidet 0, 1 und mindestens 2 aufeinanderfolgende Meldungen ohne Bewegung. Bei der ersten Ruhe bleibt das Licht in seinem bisherigen Zustand.

```tide
rule light motion:b > b
state on:b=false missed:i=0
when motion -> on=set true, missed=reset
when eq missed 0 -> on=keep, missed=set 1
else -> on=set false, missed=set 2
out on

example light_restart light
{"events":[false,true,false,false,true,false],"expect":[false,true,true,false,true,true]}
```

### Wie ein Schritt ausgewertet wird

1. Die Kopfzeile `rule name ereignis:Typ > Ergebnistyp` beschreibt einen Schritt. `state` deklariert benannte Felder mit Typ und Startliteral. Für den Versuch verwenden wir Ganzzahlen und Wahrheitswerte. Jedes Beispiel und jeder neue Lauf starten mit diesen Werten. Pumpe und Licht beginnen ausgeschaltet.
2. Pro Ereignis liest die Laufzeit die `when`-Bedingungen von oben nach unten. Sie wählt die erste wahre Bedingung, sonst den abschließenden `else`-Zweig. Jede Bedingung hat den Typ `b`.
3. In jedem Zweig bekommt jedes deklarierte Feld genau eine Aktion. `keep` übernimmt seinen bisherigen Wert. `reset` stellt sein deklariertes Startliteral wieder her. `set ausdruck` berechnet einen Wert desselben Typs. Fehlende, unbekannte und doppelte Feldnamen sind Prüffehler. Ein Komma trennt die Aktionen außerhalb von Textliteralen.
4. Bedingungen und rechte Seiten lesen denselben Zustand **vor** dem Ereignis. Die Feldberechnungen erfolgen in der Reihenfolge ihrer Deklaration. Bei mehreren möglichen Fehlern wird der zuerst angetroffene gemeldet. `out` liest den berechneten neuen Zustand und das Ereignis. Erst wenn alle Berechnungen einschließlich `out` gelingen, werden Folgezustand und Ausgabe zusammen übernommen. Bei einem Fehler gilt der Stand vor diesem Schritt. Das Vertauschen zweier Feldaktionen ändert das Ergebnis nicht.
5. Die Regel arbeitet auf übergebenen Werten. Rechte, Dateioperationen und Gerätezugriffe sind in Zustandsfeldern und Schrittberechnungen ausgeschlossen, auch über Hilfsfunktionen. Die vorhandenen Typprüfungen, Fehlerregeln und Ressourcenbudgets gelten. Auch über `scan` muss der Aufrufgraph aus Regeln und Funktionen frei von Zyklen bleiben. Pumpe, Licht und Alarm in diesem Entwurf liefern Werte für eine Simulation.

Normale Funktionen können eine Regel mit `scan regelname liste` über eine endliche Ereignisliste laufen lassen. Das Ergebnis enthält genau eine Ausgabe je Eingabe in derselben Reihenfolge. Eine leere Liste liefert eine leere Liste, ein weiterer Aufruf beginnt wieder im Startzustand. Eine ausführbare Datei kann zum Beispiel die Regel `pump` und diese Einstiegsfunktion enthalten:

```tide
main > *b
scan pump list i 5 20 19 20 80 81
```

## Bestätigte Beispiele mit einer Änderung prüfen

Ein `example`-Block steht in derselben TIDE-Datei wie sein Ziel. Der Kopf nennt eine in der Datei eindeutige Beispielkennung und den Namen einer Regel oder Funktion. Die folgende Zeile ist ein JSON-Objekt. Leerzeilen trennen die Blöcke. Beim Vergleich von Beispielen zählt der JSON-Inhalt. Genau eines der Felder `expect` und `expect_error` muss vorhanden sein.

| Ziel | Eingabe | Erwartung |
|---|---|---|
| Regel | `events` enthält die Ereignisse ab dem deklarierten Startzustand. | `expect` enthält die sichtbare Ausgabe nach jedem Ereignis. Die Länge muss mit `events` übereinstimmen, auch bei einer leeren Folge. Der Beispieltreiber meldet die erste Abweichung als `E_EXAMPLE` mit Ereignisnummer ab 1, Soll und Ist. |
| Funktion | `inputs` bindet jeden Parameter nach Namen. Für ein Leserecht erzeugt der Beispieltreiber aus dem angegebenen Text eine lokale Testeingabe. | `expect` vergleicht den typisierten Rückgabewert mit dem JSON-Wert. |
| Erwarteter Fehler bei einem der beiden Ziele | Eingabe wie oben. | Anstelle von `expect` steht `expect_error` mit einem Fehlercode und gegebenenfalls `reason` oder `input_line`. Alle angegebenen Felder müssen übereinstimmen. Ein erfolgreicher Lauf verfehlt diese Erwartung. |

`tide check` soll Bindungen, Typen und Beispielstruktur prüfen. `tide test` führt die Beispiele einzeln mit frischem Zustand und begrenzten Testeingaben aus. Auch eine Datei aus Regeln und Beispielen lässt sich so prüfen. Erst `tide run` verlangt die Einstiegsfunktion `main`. Für den normalen Programmlauf dienen Beispiele als mitgelieferte Spezifikation und verursachen keine zusätzlichen Testläufe.

Bei einer vorgeschlagenen Codeänderung prüft der Editor die Beispiele der bisherigen Version. Ändert sich auch die Anforderung, zeigt er die Änderung am Beispiel mit bisheriger und neuer Erwartung gesondert an. Eine geänderte Programmausgabe überschreibt keine Erwartung. Eine Löschung oder Umbenennung eines Beispiels bleibt im Vergleich der Versionen sichtbar. Verdeckte Aufgaben für die Forschung werden außerhalb dieser sichtbaren Programmbeispiele aufbewahrt.

**Herkunft der Erwartung.** Der Entwurf unterscheidet vorgeschlagene Beispiele von bestätigten Verträgen. Ein Bestätigungsvermerk nennt Urheber, bestätigende Person oder fachliche Quelle, die geprüfte Programmrevision und die genaue Fassung von Ziel, Eingabe und Erwartung. Der Vermerk kann außerhalb des Quelltexts auf diesen Stand verweisen. Ein Modellvorschlag oder ein erfolgreicher Testlauf ergibt für sich keine fachliche Bestätigung. Ein geändertes Soll bleibt ein neuer Vorschlag, bis die Entscheidung belegt ist. Bei einer reinen Codeänderung bleibt das zuvor bestätigte Beispiel als Vergleich erhalten. Die hier abgedruckten Beispiele illustrieren die Regeln; ihre Herkunft darf aus ihrer bloßen Aufnahme in den Entwurf nicht nachträglich abgeleitet werden.

## Kompakt schreiben, gezielt nachsehen

Die Schreibansicht verwendet Präfixausdrücke und aussagekräftige Namen wie `temperature` und `missed`. In unseren beiden Maximumprogrammen kosteten aussagekräftige Namen mit den getesteten Tokenizern gleich viele Tokens wie einzelne Buchstaben. Die Prüfansicht kann genau einen Zweig desselben Syntaxbaums aufklappen: Aus `if < streak 3 + streak 1 3` wird `(if (< streak 3) (+ streak 1) 3)`. Beide Ansichten verweisen auf denselben Ausdruck in derselben Revision. [Tokenmessung](tasks/notation.md)

**Grenze der Diagnose.** Wird in `if < streak 3 + streak 1 3` die `1` ausgelassen, ist `+ streak 3` weiterhin ein vollständiger Teilausdruck. Erst am Ende fehlt der dritte Operand von `if`. Dieselbe beschädigte Folge entsteht auch aus `if < streak 3 + streak 3 0`, wenn die abschließende `0` entfällt. Allein aus der Eingabe lässt sich daher die gelöschte Position nicht eindeutig rekonstruieren. Bei vollständig geklammertem Präfix würde die entsprechende erste Löschung bereits an der schließenden Klammer von `(+ streak)` auffallen. Im Selbstversuch mit einer einzelnen markierten Operation gelangen alle sechs Änderungen und Reparaturen in jeder Darstellung. Bei einer Löschung direkt an der markierten Operation nannte der Prüfer in 8 von 8 Fällen den betroffenen Aufruf, gegenüber 3 von 8 ohne Markierung. Für tiefer liegende Löschungen blieb die Quote mit beiden Ansichten bei 4 von 16. Eine verstellbare Auswahl bleibt ein Vorschlag für den Editor. [Versuch mit lokaler Klammerung](experimente/08_lokale_klammern/bericht.md)

Eine Zustandsspur lässt sich für ein Beispiel und ein Ereignis anfordern. Für die **korrekte** Lichtregel sähe die Anfrage so aus:

```sh
tide trace sensors.tide --example light_restart --step 2 --fields on,missed
```

| Ereignis | Gewählter Zweig | Feld | Vorher | Aktion | Nachher |
|---|---|---|---|---|---|
| 2 · Bewegung | `when motion` | `on` | `false` | `set true` | `true` |
| 2 · Bewegung | `when motion` | `missed` | `1` | `reset` | `0` |

Würde ich `missed=reset` durch `missed=keep` ersetzen, bliebe der Zähler hier auf 1. Das Beispiel meldete seine erste falsche **Ausgabe** erst bei Ereignis 3. Die Spur für Schritt 2 zeigt den tatsächlich gewählten Zweig und seine Werte; eine Sollvorgabe für interne Felder setzt sie nicht voraus. Sie entsteht beim begrenzten Wiederabspielen des Beispiels aus dem Startzustand. Für einen normalen Lauf wird kein vollständiges Zustandsprotokoll benötigt.

## Neun Entwurfsfragen aus der Praxis

Die folgende Tabelle übersetzt die genannten Schwierigkeiten in konkrete Anforderungen an TIDE. Die bisherigen Selbstversuche untersuchten Schreibweisen, Beispiele und Zustandsspuren. Die übrigen Zeilen sind Vorschläge, die wir an neuen Aufgaben prüfen müssen.

| Schwierigkeit | Entscheidung für TIDE 0.3 | Woran wir sie prüfen können |
|---|---|---|
| Nicht-lokale Effekte | Eine Datei enthält benannte Funktionen und Regeln mit statisch auflösbaren Aufrufen. `check` zeigt pro Definition die direkten Aufrufziele und die transitiv möglichen Außenwirkungen, z. B. Lesen über einen übergebenen Parameter. Ein Regelzustand gehört genau einem Lauf. | Ruft eine Hilfsfunktion mittelbar `read` auf, muss dieser Effekt beim Aufrufer erscheinen. Ein Aufruf aus einem Regelzweig wird mit der konkreten Aufrufkette zurückgewiesen. |
| Dynamische Typisierung | Parameter, Ergebnisse und Zustandsfelder haben deklarierte Typen. Lokale Typen werden abgeleitet. Dieselbe strikte Prüfung gilt beim Schreiben im Editor und beim Starten über die CLI. | `eq "9" 9` meldet den falschen Operandentyp. Ein Textwert als Folgezustand eines Ganzzahlfelds scheitert bereits beim Prüfen. |
| API- und Versionsdrift | Das Projekt bindet Sprachversion und exakten Operationskatalog. Editor, Prüfer und Kurzreferenz verwenden dieselbe gebundene Fassung. Eine unbekannte Operation führt zu einem Befund an der Aufrufstelle. | Bei einem abweichenden Katalog meldet das Werkzeug die erwartete und gefundene Kennung vor dem Lauf. Eine mitgelieferte neuere Referenz darf den Befund nicht verändern. |
| Globale Invarianten | Der Prüfer kontrolliert den ganzen Aufrufgraphen auf Zyklen und unerlaubte Wirkungen. Zustandsänderungen sind pro Ereignis atomar. Rechen- und Speicherbudgets gelten über Funktionsgrenzen hinweg. Für fachliche Regeln wie „hintereinander“ liefert der Auftrag die erwarteten Beispiele. | Ein indirekter Zyklus wird beim Prüfen erkannt. Schlägt die zweite Feldberechnung fehl, bleiben auch der erste Feldwert und die Ausgabe auf dem letzten abgeschlossenen Schritt. |
| Syntaktische Fragilität | Stelligkeit, Blockform und JSON-Schema bestimmen die Struktur. Die geplante Formatierung vereinheitlicht Leerraum und Einrückung. Der Parser meldet die Erkennungsposition und, soweit bestimmbar, den offenen Ausdruck samt erwarteter Operandenzahl. Bei einer Auslassung kann die Erkennungsposition erst am Ausdrucksende liegen. | Erneutes Parsen einer formatierten Datei ergibt denselben Baum einschließlich Beispiele. Zweimaliges Formatieren ergibt identische Bytes. |
| Zu viele Schreibweisen | Pro Kernoperation gibt es eine Schreibweise. Kompakt- und Prüfansicht lesen denselben Baum. Bei Zustandsaktionen bleibt die Absicht sichtbar: `reset` folgt auch nach einer Änderung dem deklarierten Startwert. | Eine Formatierung erhält `reset`; sie ersetzt es auch bei Startwert 0 nicht durch `set 0`. Die beiden Ansichten müssen auf denselben Knoten zeigen. |
| Wenig Trainingsmaterial | Jede Operation hat einen knappen, offline abrufbaren Eintrag mit Stelligkeit, Typen, Wirkung, möglichen Fehlern und einem gültigen Beispiel. Bei einer Lücke kann das Modell gezielt die passenden Einträge und sichtbaren Hilfsfunktionen anfordern. | Bei einem mir unbekannten Operator vergleichen wir meinen ersten Versuch mit und ohne den passenden Referenzeintrag. Zusatzkontext und Reparaturen zählen mit. |
| Build und Tooling | Für die ersten Versuche genügt eine gebundene lokale Werkzeugversion. Zur Reproduktion gehören Quellstand, Werkzeug- und Katalogkennung, Budgets, Beispiele und Testeingaben. Eine spätere Bibliotheksauflösung muss ebenfalls exakt festgelegt werden. | Zwei isolierte Läufe derselben Werkzeuge mit demselben Stand und denselben Testdaten liefern dieselben Werte und stabilen Diagnosefelder. |
| Schlechte Fehlermeldungen | Eine Diagnose nennt den frühesten beobachteten Verstoß, Fehlercode und passende Position. Typfehler nennen Soll- und Isttyp. Beispielabweichungen nennen Beispiel, Ereignis, Soll und Ist. Eine angeforderte Spur zeigt die beteiligten Feldänderungen. | Beim Licht meldet der Beispieltest die falsche Ausgabe bei Schritt 3. Die Spur auf Schritt 2 zeigt den unterbliebenen Reset. Die Diagnose trennt diese Beobachtungen von einer vermuteten Ursache. |

**Vorgeschlagener Versionsvertrag.** Ein Projekt hält in einer kleinen Lockdatei die Sprachversion (hier `0.3`), den Inhalts-Hash des Operationskatalogs und die exakte Werkzeugfassung fest. Einzelfallversuche können dieselben Angaben im Versuchsprotokoll erfassen. `tide describe need --json` ist als gezielter Abruf der zur Prüfung verwendeten Operationsbeschreibung vorgesehen. Der geplante Prüfbefund enthält die tatsächlich verwendeten Versionskennungen. Damit lässt sich eine Diagnose auch in einem anderen Arbeitskontext derselben API zuordnen. Die Tests zur Wiederholbarkeit beginnen mit lokalen, festen Eingaben. Dateiinhalte aus einem anderen Lauf wären eine zusätzliche Einflussgröße.

## Funktionen für Datenverarbeitung

Das folgende vollständige Programm liest ganze Zahlen aus einer freigegebenen Datei. Es liefert den höchsten Wert, ein ausdrückliches leeres Ergebnis oder die Zeilennummer des ersten ungültigen Wertes.

```tide
main input:r > ?i
fold lines read input nil i best row line
let value need int line "invalid_integer" row
some case best value previous if > value previous value previous
```

Die erste Zeile ist der Vertrag. `input:r` bezeichnet das vom Aufrufer gebundene Leserecht, `?i` das Ergebnis „Ganzzahl oder leer“. Der Rest ist **ein Ausdruck**. Aus dem Operationsnamen oder der expliziten Listenlänge ergibt sich die Zahl der Operanden. Bei eigenen Funktionen setzt die Zerlegung in Aufrufe voraus, dass ihre Stelligkeit bekannt ist. Die Syntax hängt damit von Informationen außerhalb des Ausdrucks ab. Der Parser kann so beispielsweise `lines read input` eindeutig in „Eingabe lesen, dann in Zeilen aufteilen“ zerlegen. Im Funktionsrumpf dienen Leerzeichen und Zeilenumbrüche gleichermaßen als Trenner.

`fold` verarbeitet die Zeilen in Reihenfolge. Es beginnt mit `nil i`, dem leeren Maximum. In jedem Schritt stehen `best` für das bisherige Ergebnis, `row` für die Position ab 1 und `line` für die aktuelle Textzeile. `need` liefert die gelesene Zahl oder löst einen Datenfehler mit Grund und Eingabezeile aus. Im gezeigten Programm gelangt dieser Fehler bis zum Aufrufer. `case` deckt beide Zustände des bisherigen Maximums ab. Der Wert des letzten Ausdrucks wird zum nächsten Zustand. Der Endzustand ist das Ergebnis der Funktion.

| Dateiinhalt, hier mit sichtbarem Zeilenumbruch `\n` | Ergebnis |
|---|---|
| `-8\n-2\n-5\n` | `{"some":-2}` |
| Datei mit null Bytes | `{"none":true}` |
| `4\nx\n` | `E_DATA`, Grund `invalid_integer`, `input_line` 2 |
| `4\n\n7` | Derselbe Fehler in Zeile 2 |

**Änderungsauftrag:** „Gib zusätzlich die Zeilennummer des ersten Maximums zurück.“ Es ändern sich der Ergebnistyp, der Typ des leeren Zustands und der Ausdruck für den neuen Zustand. Bei einem Gleichstand wird das vorhandene Paar weitergegeben. Für `-8\n-2\n-2` ergibt sich `{"some":[-2,2]}`.

```tide
main input:r > ?&ii
fold lines read input nil &ii best row line
let value need int line "invalid_integer" row
some case best pair value row previous if > value first previous pair value row previous
```

## Wie der Kern ohne Klammern auskommt

| Bestandteil | Festlegung für den Prototyp |
|---|---|
| Funktionsgrenze | In der Kopfzeile stehen Name, null oder mehr Parameter `name:typ`, dann `>` und der Rückgabetyp. Danach folgt genau ein Ausdruck. Eine Leerzeile trennt Definitionen und darf im Rumpf nicht vorkommen. Die reservierten Kopfzeilen `rule` und `example` kennzeichnen Regeln und Beispiele. Funktions- und Regelnamen sind dateiweit eindeutig. Alle Signaturen werden vor dem Auflösen der Aufrufe eingelesen. Eine ausführbare Datei hat genau ein `main`. |
| Typen | `i` ist eine vorzeichenbehaftete 64-Bit-Ganzzahl, `b` ein Wahrheitswert, `t` UTF-8-Text, `r` ein Leserecht. Die Typkonstruktoren `?T`, `*T` und `&AB` bilden Option, Liste und Paar. Jeder Konstruktor hat eine feste Stelligkeit. Damit hat auch `?&ii` genau eine Lesart. |
| Werte und Bindungen | Ein Literal oder eine Variable ist ein vollständiger Ausdruck. Textliterale verwenden JSON-Anführungszeichen und -Escapes. `let name wert rumpf` bindet einen unveränderlichen lokalen Wert. Das Ergebnis ist der Wert des Rumpfs. Funktionsnamen, Operationsnamen und lokale Bindungen müssen in ihrem sichtbaren Bereich eindeutig sein. Typkürzel stehen in eigenen Typfeldern. |
| Aufrufe | `+ a b` addiert zwei Ganzzahlen mit Überlaufprüfung. `> a b`, `< a b`, `>= a b`, `<= a b` und `eq a b` vergleichen zwei Ganzzahlen und ergeben einen Wahrheitswert (`true` oder `false`). `>=` und `<=` sind auch bei Gleichheit wahr. Eigene Funktionen folgen denselben Regeln. `twice x:i > i` mit dem Rumpf `+ x x` wird durch `twice 7` aufgerufen. Direkte oder indirekte Rekursion weist der Prüfer zunächst zurück. |
| Kontrollfluss | `if test ja nein` wertet nur den gewählten Zweig aus. `case option leer name voll` bindet den Inhalt ausschließlich im vollen Zweig. Beide Ergebnisse müssen denselben Typ haben. `nil T` und `some wert` konstruieren Optionen. `need option grund position` entpackt eine Option oder liefert `E_DATA` mit Grund und Position. Grund und Position werden nur im Fehlerfall ausgewertet. |
| Wiederholung | `fold liste start zustand pos element rumpf` wertet Liste und Start einmal aus. Pro Element werden die drei Namen im Rumpf gebunden. Bei einer leeren Liste ist das Ergebnis der Startwert. Start, Rumpfergebnis und Endwert haben denselben Typ. Ein verschachteltes `fold` ermöglicht weitere Schleifen und verbraucht dasselbe Arbeitsbudget. |
| Daten | `pair a b` bildet ein Paar, `first p` und `second p` wählen Komponenten. `list T N` mit anschließend genau N Elementausdrücken konstruiert eine Liste. N ist eine begrenzte, vom Parser geprüfte nichtnegative Längenangabe. `read` nimmt ein Leserecht entgegen, `lines` zerlegt Text an LF oder CRLF. Der abschließende Trenner erzeugt keine zusätzliche Zeile. Eingebettete Leerzeilen bleiben erhalten. |
| Prüfbare Fehler | `int text` akzeptiert ASCII-Dezimalziffern mit optionalem Minus ohne Leerraum. Ungültige oder zu große Zahlen ergeben eine leere Option. Überlauf bei `+` ergibt `E_OVERFLOW`. Unbekannte Namen, fehlende Operanden, ungültige Typen und überzählige Ausdrücke werden vor der Ausführung zurückgewiesen. |

Der Prüfer leitet lokale Typen aus dem Programm ab. Modell und Prüfer teilen eine versionierte Tabelle mit den Signaturen der Operationen. Dadurch kann das Modell abgeleitete Typen, Rückgabeanweisungen, Blockenden und Klammern beim Schreiben einsparen. Ob ein konkretes Modell den kürzeren Text zuverlässiger beherrscht, entscheidet der Modellversuch.

## Fehler behandeln

Ein leeres Maximum ist ein gültiges Ergebnis. Eine defekte Messzeile ist im selben Auftrag ein Fehler. Die Umwandlung in einen Fehler ist im Programm sichtbar: `int` liefert eine Option, `need` verlangt einen Wert und erzeugt im Leerfall `E_DATA`. Für eigene fachliche Regeln gibt es `fail "grund"`. Der Text ist ein stabiler, vom Programm gewählter Grund innerhalb von `E_DATA`. Die Laufzeit ergänzt die Quellposition.

Eine Funktion kann einen bestimmten Fehler gezielt behandeln. Dieses Beispiel liefert bei einer darstellbaren Summe den Wert und bei einem Ganzzahlüberlauf eine leere Option.

```tide
sum_option x:i y:i > ?i
catch E_OVERFLOW some + x y _ nil i
```

`catch CODE ausdruck name ersatz` wertet zuerst den geschützten Ausdruck aus. Bei Erfolg gibt es dessen Wert direkt zurück. Beim angegebenen Fehlercode wird der Ersatz einmal ausgewertet, auch wenn der Fehler aus einer aufgerufenen Funktion stammt. Ausdruck und Ersatz müssen denselben Ergebnistyp haben. Ein abbrechender Ausdruck wie `fail` passt an jede Ergebnisstelle. Andere Fehler gelangen mit ihrer ursprünglichen Diagnose zum nächsten umgebenden Handler. Ein Fehler im Ersatz gelangt ebenfalls nach außen. Es gibt keine automatische Wiederholung.

`_` verwirft die Fehlerdetails. Ein Name an dieser Stelle bindet die Diagnose für den Ersatz. `input_line name` liefert die Eingabezeile als `?i`, `has_reason name "grund"` prüft den fachlichen Grund und `raise name` gibt dieselbe Diagnose einschließlich ihrer Ursprungsposition weiter. Diese Operationen erwarten einen sichtbaren Diagnose-Namen aus einem Handler. So kann ein Programm einen bekannten Datenfehler behandeln und einen unbekannten Grund weitergeben.

| Wann der Fehler entsteht | Verhalten |
|---|---|
| Während der Auswertung einer Operation | Abfangbar sind `E_DATA` für fachliche Eingabefehler, `E_OVERFLOW` für Arithmetik, `E_UTF8` für ungültige Textkodierung und `E_IO` für einen Lesefehler an einem bereits freigegebenen, geöffneten Handle. |
| Beim Prüfen des Programms oder Einrichten der Eingaben | Syntax- und Typfehler sowie Fehler beim Öffnen der angegebenen Datei werden vom Starter gemeldet. Die Auswertung des Programms hat zu diesem Zeitpunkt noch nicht begonnen. |
| Bei einer Rechte- oder Budgetverletzung | `E_CAPABILITY` und `E_LIMIT` beenden den Lauf. Der Prüfer weist diese Codes sowie unbekannte Codes als Ziel eines `catch` zurück. Auch innerhalb eines Handlers verbraucht die Auswertung das ursprüngliche Budget. |

`tide check --json` weist für jede geprüfte Funktion unter `may_fail` die Menge der möglicherweise nach außen gelangenden **abfangbaren** Codes aus. Sie ergibt sich aus den Operationen und aufgerufenen Funktionen. Ein Handler entfernt seinen Code aus dem geschützten Ausdruck und fügt die möglichen Fehler seines Ersatzes hinzu. Bei `scan` zählen auch die abfangbaren Fehler der Bedingungen, Feldaktionen und Ausgabe der Regel. Damit meldet der Prüfer für `sum_option` eine leere Menge. Das Maximumprogramm kann `E_DATA`, `E_IO` und `E_UTF8` weitergeben.

Bei der Datei `4\nx\n` lautet die ungefangene Diagnose des Maximumprogramms:

```json
{"code":"E_DATA","reason":"invalid_integer","file":"maximum.tide","line":3,"column":11,"input_line":2}
```

`line` und `column` verweisen auf das auslösende `need` im TIDE-Quelltext. `input_line` zeigt auf die fehlerhafte Zeile in den Messwerten. Nur ein bis zum Starter gelangter Fehler erzeugt die CLI-Fehlerausgabe. Ein erfolgreich behandelter Fehler liefert ein reguläres Ergebnis.

## Kleine Änderungen ohne vollständige Neuausgabe

Bei „Suche das Minimum“ ändert sich nur der Vergleich `>` im Funktionsrumpf. Der geplante Editor gibt dem Modell für eine ausgewählte Operation eine lokale Knotennummer, Operanden und Typen. Bindet die Sitzung beispielsweise Nummer 7 an den Vergleich, lautet die gesamte fachliche Änderung `op 7 <`. Die Knotennummer gilt für genau den gelesenen Programmstand. Sitzung und Basisrevision gehören zum Aufruf des Editors.

Vor der Übernahme prüft der Editor Ziel und Basisrevision sowie die Typen und Rechte des **gesamten** geänderten Programms. Die bestätigten Beispiele müssen für die übernommene Fassung bestehen. Ein absichtlich geänderter Vertrag wird zusammen mit der Änderung seiner Beispiele sichtbar. Bei mehreren zusammengehörigen Änderungen wie beim Paar-Ergebnis werden alle betroffenen Teile gemeinsam geprüft und übernommen. Bei einem veralteten Stand oder Prüffehler bleibt der gespeicherte Stand erhalten. Im Modellvergleich zählen auch die Tokens für Kontext, Revision, Werkzeugaufruf und eventuelle Reparaturen.

### Was der Editor beim Weiterprogrammieren zeigen soll

**Den fachlichen Grund für eine Entscheidung.** Zur Funktion gehört ein kleines ausführbares Beispiel aus dem Auftrag. Für „erste Fundstelle“ genügt diese sichtbare Probe mit zwei gleich hohen Messwerten. Der Beispieltreiber bindet den Text als lokale Testeingabe an das Leserecht.

```tide
example first_peak main
{"inputs":{"input":"9\n9"},"expect":{"some":[9,1]}}

example invalid_line main
{"inputs":{"input":"4\nx\n"},"expect_error":{"code":"E_DATA","reason":"invalid_integer","input_line":2}}
```

Eine Fassung, die bei Gleichstand das neue Paar übernimmt, liefert `{"some":[9,2]}`. Beide Programme sind typkorrekt. Der Beispieleintrag legt fest, welche Wahl dem Auftrag entspricht. Bei einem Fehlschlag meldet der Treiber Eingabe, Soll und Ist. Die Probe gehört zum Arbeitskontext der Funktion. Die verdeckten Tests des Modellvergleichs bleiben davon getrennt.

**Eine präzise Antwort mitten in einer Änderung.** Ein Modell darf im Editor einen Teilausdruck als Lücke markieren. An der Stelle des letzten `if` im Paar-Beispiel soll der Prüfer den erwarteten Typ `&ii` und die lokalen Bindungen anzeigen, etwa `value:i`, `row:i` und `previous:&ii`. Dazu kommen die an dieser Stelle verfügbaren Rechte. Der Editor hält diesen unfertigen Stand als Entwurf. Ausführbar ist erst die vollständig eingesetzte und geprüfte Fassung. Für diesen Versuch genügt eine Lücke im bereits bekannten Syntaxbaum.

## Grenzen der Ausführung

Der lokale Starter prüft Quelltext, Typen und benötigte Rechte vor dem Öffnen der angeforderten Datendatei. Er bindet eine vom Nutzer gewählte reguläre Datei an den passenden Parameter. Eine Zeichenfolge kann kein Leserecht erzeugen. Rechte lassen sich nur als Argument weitergeben. Auch verschachtelte Rückgabewerte dürfen keine Rechte enthalten. Gelesene Daten dürfen im Ergebnis erscheinen.

Der Sprachkern bindet Dateiersatz, HTTPS-Anfragen, SQLite und PostgreSQL an explizite Rechte. Ein HTTP-Dienst bindet die vom Aufrufer freigegebene Adresse. Shell und beliebige native Fremdaufrufe sind dem Gastprogramm nicht zugänglich. Die Sprachreferenz beschreibt Rechte und Grenzen der einzelnen Operationen. Zur Vertrauensbasis gehören Starter, Parser, Prüfer, Interpreter und ihre Abhängigkeiten. Fehler in diesen Komponenten bleiben ein Risiko. Die erste Zielumgebung ist ein lokaler Prozess.

**Schnittstelle zum Betriebssystem.** Bei `read input` prüft die Laufzeit das gebundene Leserecht und führt die benötigte Betriebssystemoperation aus. Das TIDE-Programm kennt das logische Recht und den Ergebnistyp. Mit `--db name=pfad` bindet der Aufrufer eine SQLite-Verbindung. `sql_exec` und `sql_query` binden Werte an benannte SQL-Parameter. `transaction` setzt die Änderungen auf dieser Verbindung bei einem entweichenden Fehler zurück. [SQLite-Sprachregeln](LANGUAGE.md#sqlite)

**Ereignisse und Unterbrechungen.** Das Messwertprogramm und `scan` verarbeiten abgeschlossene Eingaben. Für eine spätere Anwendung, die etwa auf neue Messwerte wartet, bietet sich ein typisierter Ereigniseingang an. Der Host könnte eine Folge von Messwerten oder ein Stoppsignal liefern. Direkte Hardware-Interrupts wären eine eigene Entwurfsentscheidung für ein Ziel wie Firmware oder Gerätetreiber. Dafür müssten unter anderem zulässige Aktionen im Handler und die maximale Reaktionszeit feststehen.

Der Starter begrenzt Quellgröße, Verschachtelung und Listenlängen beim Parsen. Der Interpreter begrenzt Eingabebytes, Gastspeicher und Arbeitsschritte. Bibliotheksoperationen werden nach verarbeiteter Datenmenge berechnet. Überschreitungen liefern `E_LIMIT`, fehlende Rechte `E_CAPABILITY`. Die kurze Schreibweise und der Editor durchlaufen dieselben Prüfungen wie ein vollständiges Programm.

Geplante Befehle für das Messwertbeispiel:

```sh
tide check maximum.tide --json
tide test maximum.tide
tide run maximum.tide --read input=werte.txt
```

`check` liefert die Signatur mit den benötigten Rechten oder eine Diagnose mit stabilem Fehlercode, Datei, Zeile und Spalte ab 1. Für eine Typabweichung kommen Operation, Argumentposition, erwarteter und gefundener Typ hinzu. Eine fehlerhafte Datenzeile hat das separate Feld `input_line`. `run` schreibt bei Erfolg ein JSON-Ergebnis nach stdout (Exitcode 0), bei Fehler eine JSON-Diagnose nach stderr (Exitcode 1). Dezimale JSON-Ganzzahlen müssen den gesamten I64-Bereich erhalten.

Der [Tokenvergleich](tasks/notation.md) dokumentiert die ersten Messwerte. Der [Entwicklungsplan](tasks/plan.md) beschreibt, wie wir Korrektheit, Modellaufwand und Ausführungszeit getrennt prüfen.
