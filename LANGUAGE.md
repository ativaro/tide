# TIDE 0.6 · Sprachreferenz

Die Referenz beschreibt die Sprachregeln von TIDE 0.6. Den ausführbaren Umfang und die noch offenen Befehle des nativen Pakets führt der [Entwicklungsstand](tasks/todo.md) auf.

## Datei und Modul

UTF-8, eine Leerzeile zwischen Deklarationen. Zeilenumbrüche im Funktionsrumpf trennen Operanden ebenso wie Leerzeichen. Ein ausführbares Programm hat eine Funktion `main`. Bibliotheken dürfen ausschließlich Deklarationen und Beispiele enthalten. Die rechte Seite einer Funktion ist genau ein Ausdruck. Jeder Aufruf kann optional geklammert werden. Namen beginnen mit einem ASCII-Buchstaben, gefolgt von Buchstaben, Ziffern oder Unterstrichen. Bindungen sind unveränderlich. Namenskonflikte und rekursive Aufrufketten ergeben Prüffehler.

```tide
twice value:i > i
+ value value

main > i
twice 7
```

`use readings` lädt die reguläre Datei `readings.tide` aus demselben Verzeichnis. Nachbardateien teilen den Namensraum ihres Projekts oder Pakets. Namen aus transitiven Nachbarimporten stehen darin zur Verfügung. Doppelte Importpfade laden dasselbe Modul einmal, zyklische Importe scheitern. Module werden beim Prüfen aufgelöst. Die Revision umfasst den Quelltext des Einstiegsprogramms sowie Pfade und Inhalte aller importierten Module und Pakete.

`tide modules DATEI [--json]` liefert den Modulgraphen als JSON. `modules` führt die Dateien in der Reihenfolge des ersten Besuchs bei der Tiefensuche auf. `imports` nennt für jede Importstelle die Quelldatei, das Ziel und die einbasierte Zeile und Spalte von `use`. Wiederholte Importe haben eigene Fundstellen. Der Hash verarbeitet die Module nach Dateinamen sortiert und entspricht bei einem gültigen Projekt der Revision von `tide check`. Der Befehl löst die Importe vor der Typprüfung auf und ist so auch bei einem unvollständigen Rumpf nutzbar.

### Versionierte Pakete

`use rowtext@2.0.0` lädt `vendor/rowtext/2.0.0/package.tide` relativ zum Verzeichnis des Projekteinstiegs. Das Paket beginnt mit `package rowtext 2.0.0`. Name und Version müssen zum Import passen. Die drei Dezimalteile der Version sind exakt gepinnt. Jeder Paketname hat pro Projekt eine Version. Widersprüchliche Pins ergeben `E_PACKAGE`. Auch versionierte Abhängigkeiten eines Pakets verwenden das `vendor`-Verzeichnis des Projekteinstiegs.

`export parse` macht eine Funktion als `rowtext.parse` für den direkt importierenden Namensraum aufrufbar. `export` kann auch Regeln, Records und Varianten freigeben. Typen werden zum Beispiel als `{rowtext.Result}` referenziert. Innerhalb des Pakets bleiben Funktions- und Typnamen kurz. Die Nachbardateien eines Pakets gehören zum selben Namensraum, und eine Exportdeklaration kann Namen aus ihnen freigeben. Mehrere Exportnamen stehen durch Leerzeichen getrennt auf derselben Zeile.

Pakete und ihre exakten Versionen erscheinen in `tide modules --json`. `tide check`, `run`, `test` und `build --aot` verwenden dieselbe Paketauflösung. Die Inspektion und Editier-Vorschau arbeiten auch auf Paketquellen. Direktes Schreiben an einer eingebundenen Paketdatei erfolgt aus deren eigenem Projekt.

### Schlüssel mit unterschiedlicher Priorität vergleichen

Das Bibliotheksmodul [ordering.tide](lib/ordering.tide) lässt sich neben die eigenen Module kopieren und mit `use ordering` einbinden. `prefer_min candidate current on_equal` entscheidet zugunsten des kleineren i64-Werts. `prefer_max` entscheidet zugunsten des größeren. Bei Gleichheit geben beide `on_equal` zurück. Damit lassen sich aufsteigende und absteigende Kriterien über den gesamten i64-Bereich kombinieren.

```tide
use ordering

better delay:i old_delay:i capacity:i old_capacity:i > b
prefer_min delay old_delay (prefer_max capacity old_capacity false)
```

Hier gewinnt die geringere Verzögerung, bei gleicher Verzögerung die höhere Kapazität. Bei vollständigem Gleichstand bleibt mit `false` der bisherige Kandidat erhalten. Alle Funktionsargumente werden vor dem Aufruf ausgewertet. Falls ein nachgeordnetes Kriterium nur bei Gleichheit gelesen oder berechnet werden darf, gehört es in den entsprechenden Zweig eines `if`. [Ausführbare Grenz- und Auswertungsprüfungen](lib/ordering_checks.tide)

## Typen und JSON

| Typ | Werte |
|---|---|
| `i`, `b`, `t` | Vorzeichenbehaftete 64-Bit-Ganzzahl, Wahrheitswert, Unicode-Text. Textliterale verwenden JSON-Anführungszeichen und Escapes. |
| `q`, `z` | Exakte Dezimalzahl mit sechs Nachkommastellen bzw. Zeitstempel mit UTC-Offset. |
| `n`, `w`, `p` | Vom Aufrufer gebundene Rechte für einen HTTPS-Ursprung, einen Dateiersatz oder eine PostgreSQL-Verbindung. |
| `d` | Datenbankrecht als Funktionsparameter. Der Aufrufer bindet es mit `--db name=pfad` an eine SQLite-Datenbank. |
| `y` | Bytefolge bis 128 KiB. JSON-Hexstring mit zwei Ziffern pro Oktett. |
| `%A` | Wörterbuch mit Textschlüsseln und einheitlichem, nicht optionalem Werttyp `A`. JSON-Objekt. |
| `?A` | Option. Leer als `{"none":true}`, belegt als `{"some":wert}`. |
| `*A` | Liste gleichartiger Werte als JSON-Array. |
| `&AB` | Paar mit zwei festgelegten Typen als JSON-Array aus zwei Werten. `&i?i` enthält eine Zahl und eine optionale Zahl. |
| `{Name}` | Benannter Typ. Ein Record ist ein JSON-Objekt mit genau den deklarierten Feldern. Eine Variante ist ein JSON-String mit einem der deklarierten Fallnamen. |
| `r` | Vom Host gebundenes Leserecht in einem Funktionsparameter. Rechte können an Hilfsfunktionen weitergegeben werden. Rückgaben, Recordfelder, Optionen, Listen und Paare sind auf Datentypen beschränkt. |

Bei typisierten JSON-Eingaben sind zusätzliche Schlüssel, fehlende Parameter, doppelte Objektschlüssel und eine Verwechslung von Zahlen und Wahrheitswerten Fehler.

Im nativen Projektauswerter verbindet `pair` zwei Datenwerte. Die Komponenten dürfen unterschiedliche Typen haben, etwa `&{Buffer}{Effect}` für den Zustand nach einem Tastendruck und die angeforderte Aktion. Auch Grundwerte, Listen, Optionen und weitere Paare können Komponenten sein. `pair` wertet beide Argumente von links nach rechts aus. `first` und `second` behalten den jeweiligen Typ bei. Listen und Optionen können ihrerseits Paare aufnehmen. Geschachtelte Listen wie `**i` können als Parameter und Rückgaben verwendet werden. [Ausführbare Listen- und Schleifenbeispiele](native/bootstrap/fixtures/functions/iteration.tide) [Ausführbare Typbeispiele](native/bootstrap/fixtures/functions/composite_pairs.tide)

```tide
record Point
x:i y:i

shift point:{Point} > {Point}
with x point + get x point 1

main > {Point}
shift make Point x 2 y 5
```

Ergebnis: `{"x":3,"y":5}`. `make` prüft die Feldnamen in Deklarationsreihenfolge. `get` liest ein Feld, `with` liefert einen aktualisierten Wert. Recordtypen können andere Datenstrukturen enthalten. Zyklische Recorddefinitionen werden zurückgewiesen.

Der native Projektauswerter unterstützt Records als Funktionsparameter, Rückgabe und Akkumulator. Ein Feld kann einen Grundwert, einen benannten Record oder eine Variante enthalten, ebenso eine Liste oder Option dieser Typen. Ein Feld darf auch ein Paar, eine Liste von Paaren oder eine Option mit Paarinhalt sein. An der JSON-Grenze dürfen Recordfelder in beliebiger Reihenfolge stehen. Das gilt auch für Records innerhalb von Listen. Ihr Typ und ihre Namen müssen zur Deklaration passen. Bei einer falschen Feldbezeichnung im Programm meldet TIDE `E_FIELD` mit der Quellposition des Namens. Ein falsch typisierter Feldwert bei `make` oder `with` ergibt `E_TYPE` mit Feld, Solltyp und Isttyp. [Feldbeispiele](native/bootstrap/fixtures/functions/record_values.tide) · [Verschachtelte Werte](native/bootstrap/fixtures/functions/collections.tide)

### Varianten

```tide
variant Signal
red green

speed light:{Signal} > i
match light
red   0
green 50
end

main > i
speed (tag Signal green)
```

`variant` deklariert eine geschlossene Menge benannter Fälle ohne Nutzdaten. `tag Signal green` erzeugt einen Wert vom Typ `{Signal}`. Jeder Variantentyp hat eine eigene Identität, auch wenn zwei Typen dieselben Fallnamen verwenden. An einer JSON-Grenze prüft TIDE den Namen anhand des erwarteten Typs. Das gilt auch für Varianten in Records, Listen, Optionen und Paaren. Die Wörter `variant`, `tag`, `match` und `end` sind ab Version 0.4 reserviert.

`match` wertet den Eingang einmal aus. Jeder Fall braucht genau einen Zweig. Die Reihenfolge ist frei. Alle Zweige müssen denselben Ergebnistyp liefern oder einen Fehler auslösen. Nur der gewählte Zweig wird ausgeführt. `end` schließt den Ausdruck auch dann eindeutig ab, wenn ein Zweig fehlt.

Bei sonst gültigen Typen und Ausdrücken enthält die Diagnose `E_MATCH` unter `diagnostics` alle unvollständigen `match`-Stellen im geladenen Projekt mit Funktion oder Regel, Position, Variantentyp und fehlenden Fällen. Eine ergänzte Variante erzeugt keine Verpflichtung, sie tatsächlich zurückzugeben. Den Unterschied zeigt der [Versuch mit den Spielphasen](experimente/10_varianten.md).

Der native Projektauswerter verarbeitet Varianten als Funktionsargument, Ergebnis, lokale Bindung, Recordfeld, Paarkomponente sowie als Element einer Liste oder Option. In `test --explain=executed` steht der besuchte Fall unter seinem Namen. [Variantenbeispiele](native/bootstrap/fixtures/functions/variants.tide) · [Listen und Optionen](native/bootstrap/fixtures/functions/collections.tide)

## Bytes, Wörterbücher und typisierter JSON-Import

`read_bytes input` liest die Oktette eines Leserechts direkt. `read` und `read_bytes` teilen sich denselben Snapshot und dasselbe Eingabebudget. `utf8_bytes` kodiert Text als UTF-8. `byte_len` zählt Oktette. `byte_at` liefert eine optionale Zahl von 0 bis 255. Bei negativen Indizes und ab der Länge ist die Option leer. Die Hex-Darstellung akzeptiert Gross- und Kleinbuchstaben und verwendet bei der Ausgabe Kleinbuchstaben.

`dict i` erzeugt ein leeres Wörterbuch vom Typ `%i`. `dict_put werte schlüssel wert` liefert ein neues Wörterbuch und ersetzt einen vorhandenen Eintrag. `dict_get werte schlüssel` liefert eine Option. Ein Wörterbuch fasst bis zu 4096 Schlüssel mit je bis zu 4096 Unicode-Codepunkten. Die Ausgabe sortiert Schlüssel nach Codepunkten. Auch der leere String ist ein gültiger Schlüssel.

`json_decode {Document} payload` liest ein vollständiges UTF-8-Dokument aus `payload:y`. Der Compiler prüft den Zieltyp. Der Decoder ordnet Recordfelder nach Namen zu. Fehlende optionale Felder und `null` ergeben `none`. Andere Werte müssen zum inneren Typ passen. Unbekannte Recordfelder dürfen gültige JSON-Werte enthalten. In Wörterbüchern prüft der Decoder jeden Wert. Doppelte Schlüssel und ungültiges JSON ergeben `E_DATA`, ungültige UTF-8-Bytes ergeben `E_UTF8`.

Die Diagnose enthält die Quellposition von `json_decode` und den JSON Pointer `issue.path`. Die Wurzel hat den Pfad `""`, Arrayindizes beginnen bei null. In Schlüsseln wird `~` zu `~0` und `/` zu `~1`. Ein Beispiel mit `"expect_error":{"code":"E_DATA","path":"/readings/1/note"}` prüft den genauen Pfad. Funktionsargumente und Ergebnisse verwenden für Optionen weiterhin `{"some":…}` oder `{"none":true}`. [Messbericht als JSON-Importer](apps/report_packages/json_report.tide)

## Auswertung

Ausdrücke werden von links nach rechts ausgewertet. `if`, `and`, `or`, `case`, `match`, `need` und `catch` werten nur die jeweils benötigten Operanden aus. `let` bindet einen lokalen Wert. `fold` bindet pro Element den Akkumulator, die Position ab **1** und das Element. Der Listenindex bei `at` beginnt bei **0** und ergibt außerhalb der Liste eine leere Option. Geprüfte Arithmetik liefert bei Überlauf `E_OVERFLOW`. `div` rundet gegen null. Division oder Restbildung durch null lösen `E_DATA` mit Grund `division_by_zero` aus.

`< a b`, `> a b`, `<= a b`, `>= a b` und `eq a b` vergleichen zwei Werte vom Typ `i` und ergeben `b`. `<=` und `>=` schließen Gleichheit ein. Ein Vergleich deckt den vollen vorzeichenbehafteten 64-Bit-Bereich ohne Überlauf ab.

`map B liste element rumpf` wertet die Liste einmal aus. Für jedes Element wertet TIDE den Rumpf einmal in Eingabereihenfolge aus. Der Name gilt nur im Rumpf. Jeder Ergebniswert muss den angegebenen Typ `B` haben. Eine leere Eingabe ergibt die leere Liste vom Typ `*B`. Beispielsweise ergibt `map i (list i 2 4 7) x (+ x 1)` den Wert `[5,8]`. Bei einem Fehler bricht die Abbildung am ersten betroffenen Element ab. Die Diagnose behält die Quellstelle und enthält in `map_index` den nullbasierten Index der innersten betroffenen Abbildung. Das Gastbudget zählt den Listenkopf einmal und jeden Ergebniswert beim Einfügen. Operationen im Rumpf verbrauchen ihr gewöhnliches Budget. [Beispiele für Records, Paare, Fehler und verschachtelte Abbildungen](native/bootstrap/fixtures/functions/maps.tide)

`while start zustand bedingung schritt` prüft die Bedingung vor jedem Schritt und gibt den letzten Zustand zurück. `recur` ruft die umgebende Funktion mit neuen Argumenten auf. Es gelten das Arbeitsbudget und höchstens 48 aktive rekursive Aufrufe. Der AOT-Compiler übersetzt geschachtelte Listen, diese beiden Kontrollformen und Zustandsregeln, die eine Funktion mit `scan` aufruft. [Lichtregel](apps/light.tide)

`nil T` und `some wert` erzeugen Optionen. `case option leer name voll` unterscheidet beide Fälle. `need option grund zeile` liefert den Inhalt oder einen Datenfehler mit Grund und Eingabezeile. `int` akzeptiert genau eine dezimale i64-Zahl mit optionalem Minus. `lines` trennt an LF und CRLF, erhält eingebettete Leerzeilen und fügt nach einem abschließenden Trenner keine Zeile hinzu.

`rule` beschreibt einen Übergang je Eingabeereignis. Startwerte, erster passender `when`-Zweig und ein abschließender `else`-Zweig legen das Verhalten fest. Jeder Zweig weist jedem Zustandsfeld genau eine Aktion zu. `keep`, `set` und `reset` lesen den alten Zustand. `out` liest den neuen Zustand. Ein Fehler bricht den Übergang vor der Veröffentlichung seiner Ausgabe ab. `scan` beginnt bei jedem Aufruf neu. Zustandsfelder unterstützen `i` und `b`; Ereignisse und Ausgaben dürfen auch zusammengesetzt sein. Regeln arbeiten ohne Dateizugriffe, einschließlich aller Hilfsfunktionen.

`text_len` zählt Unicode-Codepunkte. `text_slice text start stop` liefert den Abschnitt von `start` einschließlich bis `stop` ausschließlich. `text_find text muster start` sucht vorwärts ab `start`. `text_rfind text muster stop` sucht den letzten Treffer, der vollständig vor der Grenze `stop` liegt. Beide liefern den absoluten Anfang des Treffers als `?i`. Alle Indizes beginnen bei null. Die Operationen begrenzen Indizes auf den Bereich von null bis zur Textlänge.

Die ausführbare Referenz für alle **73 Operationen** ist mit `tide describe` abrufbar. Jeder Katalogeintrag hat eine Signatur und einen Beispielausdruck.

## Fehler, Rechte und Budgets

`catch CODE ausdruck name ersatz` behandelt genau einen abfangbaren Fehler. Im Ersatz bindet `name` die ursprüngliche Diagnose. `_` verwirft sie. `input_line name`, `has_reason name text` und `raise name` lesen oder propagieren diese Diagnose. Abfangbar sind `E_DATA`, `E_OVERFLOW`, `E_UTF8` und `E_IO` während der Ausführung. Fehler beim Binden von Eingaben sowie `E_CAPABILITY`, `E_TRANSACTION` und `E_LIMIT` brechen den Lauf ab.

Dateiinhalte kommen über `tide run DATEI --read parameter=pfad` ins Programm. Der Host prüft das ganze Projekt und die Eingabesignatur, bevor er die angegebenen Datendateien öffnet. `read` legt beim ersten Aufruf einen begrenzten Snapshot an. Weitere `read`-Aufrufe mit demselben Grant verwenden diesen Snapshot. Beispiele binden UTF-8-Inhalte im Speicher. Ein Pfad in `--inputs` kann kein Leserecht erzeugen. Zum Schreiben bindet der Aufrufer ein eigenes Datei- oder Datenbankrecht.

### Externe APIs und Dienste

`https_get {Antwort} api pfad header timeout_ms bytes` und `https_post {Antwort} api pfad header timeout_ms bytes rumpf` liefern einen Record mit `status:i headers:%t body:y`. Der Aufrufer bindet `api:n` über `--https api=https://host:port`. Der Pfad beginnt mit einem einzelnen Schrägstrich. Anfragen bleiben beim gebundenen Ursprung. Der Client prüft Zertifikat und Hostnamen. Für eine private CA kann der Aufrufer `TIDE_HTTPS_CA_FILE` setzen. HTTP-Fehlerstatus gelangen an das Programm. Für Transportfehler gilt `E_IO`. Pro Anfrage gelten 1 bis 30.000 ms und bis zu 131.072 Antwortbytes. Ein Beispiel kann das Recht mit einer Tabelle aus Pfad und Paar `[status,text]` binden. [Zweiseitiger Messbericht mit Fehlerbeispielen](apps/report_packages/api_report.tide)

`json_encode wert` erzeugt öffentliche UTF-8-JSON-Bytes. Eine leere Option erscheint als `null`, eine belegte als ihr Inhalt. `utf8_text bytes` prüft UTF-8. `q` speichert vorzeichenbehaftete i64-Millionstel. `q_units` und `q_from_units` erlauben geprüfte Ganzzahlarithmetik auf dieser Skala. Bei der Dekodierung müssen Wert und Präzision exakt darstellbar sein. `z` akzeptiert RFC-3339-Datumszeiten einschließlich Sekunden, optionaler Sekundenbruchteile bis neun Stellen und `Z` oder numerischem Offset. `unix_seconds` liefert die abgerundete Sekunde seit der Unix-Epoche. [Dezimal-, Zeit- und JSON-Beispiele](native/bootstrap/fixtures/functions/api_values.tide)

`write_bytes ziel daten` ersetzt die mit `--write ziel=pfad` gebundene Datei atomar und liefert die Bytezahl. Die Laufzeit synchronisiert die temporäre Datei vor dem Umbenennen und danach das Verzeichnis. Ein Fehler beim letzten Schritt kann auftreten, nachdem der neue Inhalt sichtbar wurde. Beispiele binden das Schreibrecht mit `":memory:"`.

`pg_exec pg sql parameter` und `pg_query {Zeile} pg sql parameter` erhalten die Verbindungsangaben über `--pg pg=DSN`. PostgreSQL bindet Platzhalter `$1`, `$2` aus einer Liste `*?t` als Text oder SQL-NULL. Die Abfrage ordnet Spalten über ihre Namen zu. Unterstützt sind unter anderem `numeric` für `q` und `timestamptz` für `z`. Letztere werden in UTC gelesen. Die Laufzeit setzt fünf Sekunden für Verbindungsaufbau und Anweisung sowie eine Obergrenze von 4.096 Ergebniszeilen pro Abfrage. Für eine entfernte Datenbank kann der Aufrufer die TLS-Prüfung mit `sslmode=verify-full` im DSN festlegen. [Ausführbares PostgreSQL-Beispiel](native/bootstrap/fixtures/functions/postgres_report.tide)

`tide build --service DATEI AUSGABE HANDLER` übersetzt einen HTTP-Dienst. Sein Handler nimmt `method:t path:t headers:%t body:y` und danach die deklarierten Rechte entgegen. Die Antwort hat die Felder `status:i headers:%t body:y`. Der Start erfordert `--listen IPv4:Port`. Port 0 lässt das Betriebssystem einen freien Port wählen. `--workers` begrenzt die Parallelität auf 1 bis 32, die Vorgabe ist 4. SIGTERM und SIGINT beenden den Dienst. Aktive Gastberechnungen, HTTPS-Übertragungen und laufende PostgreSQL-Abfragen prüfen das Abbruchsignal. Der Listener spricht HTTP. Für HTTPS vor einem Dienst kann ein TLS-Endpunkt vorgeschaltet werden. [Messdienst und zugehöriger HTTPS-Client](apps/report_packages/measurement_service.tide)

### SQLite

Ein Parameter `db:d` erhält mit `--db db=messungen.db` eine Verbindung zum Lesen und Schreiben. SQLite kann die Datei anlegen und daneben Journaldateien verwenden. `--db db=:memory:` öffnet eine frische Datenbank für einen Lauf. Ein ausführbares TIDE-Beispiel bindet `"db":":memory:"` in seinen Eingaben. Jedes Beispiel beginnt mit einer eigenen leeren Datenbank.

```tide
record Anzahl
n:i

anzahl db:d sensor:t > *{Anzahl}
sql_query {Anzahl} db "SELECT count(*) AS n FROM measurements WHERE sensor=:sensor" (dict_put (dict t) "sensor" sensor)
```

`sql_exec db sql parameter` führt eine Anweisung ohne Ergebnisspalten aus und liefert die Anzahl der geänderten Zeilen. `sql_query {Row} db sql parameter` führt eine lesende Anweisung aus. Jede Ergebnisspalte muss genau einem Recordfeld entsprechen. Die Reihenfolge darf abweichen. Beide Operationen binden benannte Platzhalter wie `:sensor` aus einem Record oder Wörterbuch. Die Menge der Feldnamen muss genau passen. Für eine Anweisung ohne Platzhalter genügt `(dict i)`.

| TIDE-Typ | SQLite-Wert |
|---|---|
| `i`, `b` | INTEGER im i64-Bereich, bei `b` nur 0 und 1 |
| `t`, `y` | UTF-8-TEXT bzw. BLOB |
| `q`, `z` | INTEGER in Millionsteln bzw. TEXT mit UTC-Offset |
| Optionaler Grundtyp | Wert des Grundtyps oder NULL |

Eine unpassende Spalte meldet `E_DATA` mit `reason="sqlite_column"` und einem Pfad wie `/0/n`. Für `sql_query` gelten höchstens 4.096 Ergebniszeilen und das verbleibende Gastallokationsbudget. Lange SQL-Anweisungen können am SQLite-Arbeitsbudget mit `E_LIMIT` scheitern.

`transaction db ausdruck` beginnt mit `BEGIN IMMEDIATE` und liefert nach erfolgreichem Commit den Wert des Ausdrucks. Verlässt ein Fehler den Rumpf, setzt TIDE dessen Änderungen vor einem äusseren `catch` zurück. Ein im Rumpf behandelter Fehler erlaubt die Fortsetzung, solange die Transaktion aktiv bleibt. Ein von SQLite selbst ausgelöster Transaktionsabbruch führt zu `E_TRANSACTION`. Verschachtelung auf derselben Verbindung meldet `sqlite_nested`. Transaktionssteuerung, `ATTACH` und `PRAGMA` über Gast-SQL sind gesperrt. [Messbericht mit Transaktion](apps/report_packages/sqlite_report.tide) · [Ausführbare SQL-Beispiele](native/bootstrap/fixtures/functions/sqlite.tide)

Mit `fold_rows {Zeile} db sql parameter start akk index zeile rumpf` liest TIDE jeweils eine typisierte SQLite-Zeile und gibt am Ende den Akkumulator zurück. Der Rumpf erhält die Position ab 1. Bei leerer Ergebnismenge bleibt der Startwert erhalten. Arbeit und Gastallokationen bleiben begrenzt. [Export von 5.000 Zeilen](native/bootstrap/fixtures/functions/exports.tide)

### Zeilenweise lesen

`fold_lines input bytes start akk zeile text rumpf` liest aus einem Grant vom Dateianfang und liefert den letzten Akkumulator. `bytes` ist eine Ganzzahl zwischen 0 und 134.217.728. Die erste Zeile hat die Nummer 1. Der Rumpf erhält den bisherigen Akkumulator, die Zeilennummer und den dekodierten Text. Er liefert einen Wert vom Typ des Startwerts. Eine leere Datei liefert den Startwert. Jeder Aufruf hat eine eigene Leseposition und liest die Datei blockweise. Für reproduzierbare Ergebnisse über mehrere Durchläufe muss ihr Inhalt währenddessen stabil bleiben.

LF und CRLF schliessen eine Zeile ab. Ein einzelnes CR am Dateiende gehört zum Text. Ein abschliessendes LF erzeugt keine zusätzliche Leerzeile. Das Bytebudget zählt die ursprünglichen UTF-8-Bytes inklusive Zeilenenden. Exakt ausgeschöpftes Budget ist am Dateiende gültig. Eine weitere Zeile oder ein weiteres Byte innerhalb der aktuellen Zeile führt zu `E_LIMIT`. Pro Zeile sind höchstens 128 KiB einschliesslich Zeilenende erlaubt. Alle Streams eines Laufs teilen sich zusätzlich 128 MiB tatsächlicher Eingabebytes. Erneutes Lesen zählt erneut.

Vor der Auswertung jeder vollständigen Zeile prüft der Leser ihr UTF-8. Lese-, Dekodier- und Budgetfehler tragen `input_line`. Fehler im Rumpf behalten ihre Quelldiagnose. Bei einer gültigen Zeile stehen dem Lauf pro gelesenem Byte bis zu 32 zusätzliche Arbeitsschritte und 128 logische Allokationsbytes zur Verfügung. Das verbleibende Guthaben ist jeweils auf die unten genannte Anfangsgrenze gedeckelt. Der Zeilentext kostet 8 plus 4 Allokationsbytes pro Unicode-Codepunkt. Ein Rumpf mit konstant grossem Akkumulator kann dadurch lange Dateien mit begrenztem Speicher verarbeiten. [Ausführbarer Messbericht](apps/report_packages/stream_report.tide)

| Ressource | Lokale Standardeinstellung |
|---|---:|
| Projektquelltext einschließlich importierter Module, CLI-JSON-Eingabe, Snapshot-Bytes durch `read` pro Lauf | jeweils 128 KiB |
| Elemente je Liste | 4.096 |
| Ausdrucksverschachtelung und Aufruftiefe | jeweils 48 |
| Zusätzliche Module / Importtiefe | 64 / 32 Ebenen einschließlich Einstieg |
| Anfängliches Arbeitsbudget je Lauf oder Beispiel | 100.000 Schritte |
| Anfängliches Budget für bewertete Gastallokationen je Lauf oder Beispiel | 4 MiB |

Das Gastbudget bewertet logische Werte, einschließlich mehrfach enthaltener Teilwerte. Es ist eine deterministische Sprachgrenze. Der Prozess benötigt zusätzlichen Speicher für Quelltext und interne Datenstrukturen. Die Laufzeit arbeitet lokal auf endlichen Daten und Ereignisfolgen. Die Sicherheit eines isolierten Dienstes für fremde Programme und eine Echtzeitgarantie wurden nicht qualifiziert.

## Werkzeuge für Änderungen

Bei einem Typfehler in einer gebundenen JSON-Eingabe kann `E_INPUT` unter `issue` die betroffene Stelle angeben. `path` ist ein JSON Pointer ab der Wurzel von `--inputs` oder des Beispielvertrags. Listenindizes beginnen bei null. `expected` nennt den TIDE-Typ oder die verletzte Bedingung, `actual` die vorgefundene Wertart oder Struktur. Ein fehlendes Feld hat `actual: "missing"`. Bei einem falsch typisierten Sollwert trägt `E_EXAMPLE` den Pfad ab `/expect`. Bei mehreren Fehlern kann eine weitere Stelle nach der ersten Korrektur sichtbar werden. Für einen überlangen unbekannten Feldnamen verweist die Diagnose auf das umgebende Objekt. [Beispiele und Werkzeugmessung](experimente/48_eingabediagnosen/bericht.md)

`test --diff` meldet die erste Abweichung innerhalb eines Ergebnisses. Für ein ungleiches Recordfeld liefert TIDE beispielsweise `"difference":{"path":"/rows/383/balance","expected":27,"actual":26}`. Der Pfad ist ein JSON Pointer relativ zum Ergebnis. Recordfelder folgen ihrer Deklarationsreihenfolge, Listen und Paare verwenden Indizes ab null. Bei Listen prüft TIDE zuerst die Länge (`aspect: "length"`), bei Optionen zuerst `some` oder `none` (`aspect: "option"`). Bei gleicher Form folgt der Vergleich den enthaltenen Werten. Überschreitet einer von zwei ungleichen Texten 64 Codepunkte, liefert `aspect: "codepoint"` den ersten unterschiedlichen Codepunkt mit `offset` ab null. `null` bezeichnet hier das Textende. Auch an der Wurzel kann eine Abweichung auftreten. Ihr Pfad ist der leere String.

Für einfache Skalare an der Wurzel liefert `--diff` die üblichen Felder `expected` und `actual`. Ein Regelbeispiel nennt das erste abweichende Ereignis ab eins. Bei erwarteten oder unerwarteten Laufzeitfehlern gilt das übliche Diagnoseformat. Die Option lässt sich mit beiden Erklärungsansichten kombinieren. `test` ohne `--diff` liefert beide vollständigen Ausgabewerte. [Ausführbares Mehrdateienbeispiel](experimente/46_ergebnisvergleich/ledger/panel.tide)

`test --explain` ergänzt die erste Abweichung eines ausgeführten Beispiels auf stderr um `repair`. Dieser JSON-Eintrag enthält `revision`, `entry`, `target`, die typisierten `inputs` oder `events` und `definitions`. Die Definitionen folgen den statischen Aufrufen ab dem Beispielziel, einschließlich beider Zweige einer Bedingung und der Regeln eines `scan`. Jede erreichbare Definition erscheint einmal. Funktionen enthalten `signature`, den vollständig gruppierten `body` und die Knotenkennung `node` für den gesamten Rumpf. Regeln enthalten `file`, `line` und den Originaltext in `source`. Bei bestandener Suite ist die Ausgabe `{"passed":N}`. Fehler beim Laden oder Typprüfen liefern die reguläre Diagnose.

Verwendet eine der ausgewählten Definitionen einen Record, liefert `repair.records` seine Feldnamen und Typen. Das gilt für beide Erklärungsmodi. Die Beispielprüfung und der Vertragsfingerabdruck berücksichtigen auch Optionswerte innerhalb eines Recordfelds.

`test --explain=executed` führt das erste abweichende Beispiel zur Beobachtung erneut aus. Bei gleichem Ergebnis oder identischer Fehlerdiagnose meldet `repair.execution.complete` den Wert `true`. Dann stehen unter `definitions` die tatsächlich betretenen Definitionen in der Reihenfolge ihres ersten Eintritts. `execution.branches` ordnet einer Knotenkennung die beobachteten Entscheidungen von `if`, `case`, `match`, `and`, `or`, `need` oder `catch` zu. Für Regeln steht unter dem Regelnamen die gewählte Zweignummer ab eins. Jede Entscheidung erscheint je Stelle einmal. Bei mehr als 64 verschiedenen Kombinationen aus Stelle und Entscheidung meldet `branches_truncated: true` die Kürzung der Zweigliste. Die Erfassung betretener Definitionen läuft weiter.

Erreicht der Beobachtungslauf seine Schrittgrenze oder weicht sein Ergebnis ab, liefert TIDE die statisch erreichbaren Definitionen und `complete: false` mit `reason` gleich `step_limit` oder `replay_mismatch`. Im zweiten Fall verwirft TIDE auch die beobachteten Zweige. Überschreitet das serialisierte Eingabefeld einschließlich Feldnamen 1.024 Unicode-Codepunkte, nennt der Befund unter `input_example` den Beispielnamen. `tide context DATEI --function ZIEL --example NAME` liefert die Eingabe. Die Revision beider Antworten muss übereinstimmen.

Alle CLI-Ergebnisse außer interaktiver Terminalansicht, formatiertem Quelltext, Hilfe und Versionsanzeige werden als JSON ausgegeben. Bei einem Programmfehler bleibt stdout leer. Die Diagnose auf stderr enthält einen stabilen Code und bei einem Quellbefund die Position ab 1. `may_fail` ist eine konservative Menge abfangbarer Fehler; die Analyse berücksichtigt Handler und transitiv aufgerufene Funktionen.

`tide lock` gibt Sprachversion, Werkzeugversion und SHA-256 des Operationskatalogs aus. Mit `tide lock > tide.lock` pinnt man sie im Projekt. Die nächste Lockdatei im Verzeichnis der Einstiegsdatei oder einem Vorfahren gilt für den Aufruf. `describe --project DATEI` verwendet dieselbe Bindung.

Seit 0.6 ist `map` reserviert. Für den Umstieg von 0.5 zuerst eigene Definitionen oder Bindungen dieses Namens umbenennen. Ein Projekt mit altem Pin erhält `E_VERSION`. Den neuen Pin und die Projektbeispiele kannst du zuerst in einer Kopie prüfen. Mit `tide lock --json > tide.lock.new && mv -- tide.lock.new tide.lock` übernimmst du ihn im gewünschten Projekt.

`context` liefert revisionsgebundene Knotenkennungen. Im Einstieg haben sie die Form `Zeile:Spalte`, in Modulen `Datei:Zeile:Spalte`. Eine Auswahl zeigt kompakte und vollständig geklammerte Form. `hole` erzeugt an einem ausgewählten Knoten einen virtuellen Änderungsentwurf. `__hole__` wird als unaufgelöster Name abgewiesen, bis ein gültiger Ausdruck eingesetzt ist.

Normalerweise enthält `context` alle Beispiele, deren Ziel die gewählte Definition direkt oder mittelbar verwendet. Mit `--example-index` enthält jeder Beispieleintrag nur `name`, `target` und `contract_sha256`. Mit `--example NAME` enthält die Antwort den vollständigen Eintrag für diesen Namen. Ein fehlender oder für die Definition unzutreffender Name ergibt `E_EXAMPLE`. Die Optionen schließen einander aus und lassen sich jeweils mit `--node ID` verbinden. Das zusätzliche Feld `examples_view` lautet beim Index `index` und bei der Einzelauswahl `selected`. Bei derselben Projekt-Revision stimmen die Fingerabdrücke in allen Ansichten überein.

Ein Beispielvertrag kann mit `requires` den Eingabebereich seines Ziels für die Reparatursuche festlegen. Zulässig sind ein bis acht Ganzzahlparameter und je Parameter ein Objekt mit den Bedingungen `gt`, `ge`, `lt`, `le` oder `eq`. Rechts steht eine i64-Konstante oder der Name eines Ganzzahlparameters als JSON-String. So drückt `"a":{"le":"b"}` die Bedingung `a <= b` aus. Alle Bedingungen gelten gleichzeitig. Fehlende Grenzen entsprechen der jeweiligen i64-Grenze. Pro Ziel gibt es höchstens eine solche Deklaration. Unbekannte Parameter und widersprüchliche Bedingungen ergeben `E_INPUT`. Der Aufruf der Funktion und die Ausführung vorhandener Beispiele behalten ihre Eingaberegeln. `--pairs` verwendet den deklarierten Bereich bei der Gegenbeispielsuche. [Aufruf und Beispiel](workbench/README.md#eingaben-für-grüne-paare-erzeugen)

Ein `edit` fasst Änderungen **einer** Quelldatei atomar zusammen. Für nativ unterstützte Projekte prüft `--source PFAD` eine vollständige neue Fassung der Einstiegsdatei. Ihre Importe werden neben der ursprünglichen Einstiegsdatei aufgelöst. Geänderte und gelöschte Beispielverträge erfordern `--change-examples`. Bei bestandener Prüfung liefert die Vorschau Basis- und Kandidatenrevision, Ziel, Zahl der bestandenen Beispiele, Vertragsänderungen und Kandidatentext. `--write` übernimmt die geprüften Bytes und liefert `written: true`.

`--edits` erwartet ein JSON-Array mit 1 bis 256 Änderungen derselben Projekt-Revision. Pro Eintrag stehen genau `node` und entweder `op` oder `replace`. Mit `op` ersetzt TIDE das Wort eines Aufrufs, mit `replace` den gesamten Ausdruck einschließlich seiner äußeren Gruppierung. Der Ersatz ist ein einzeiliger TIDE-Ausdruck im lokalen Gültigkeitsbereich des Knotens. Gruppierte und mehrzeilige Originalausdrücke sind zulässig. Alle Stellen beziehen sich auf den ursprünglichen Stand. TIDE prüft zuerst die Ersetzungen in ihrem jeweiligen Kontext und anschließend das gesamte geänderte Projekt mit seinen Beispielen. Überschneidungen innerhalb einer Datei ergeben `E_EDIT`.

Bei Knotenänderungen an mehreren Dateien liefert die Vorschau `files` mit je `file` und `source`. Die Änderungen müssen die Importe erhalten. Der Aufruf mit `--write` ergibt für ein Mehrdateienpaket `E_EDIT`. Die vollständigen geprüften Quellen lassen sich gemeinsam in eine Projektkopie übernehmen.

TIDE-Schreibvorgänge verwenden eine gemeinsame Verzeichnissperre und atomaren Dateiersatz. Direkt vor der Übernahme prüft der Editor die Quellen der Basis und des Kandidaten erneut, einschließlich neu hinzugekommener Importe. Externe Editoren können zwischen dieser Prüfung und dem Dateiersatz selbst schreiben. Schlägt die abschließende Verzeichnissynchronisierung nach dem Dateiersatz fehl, meldet TIDE einen Ein-/Ausgabefehler. Vor einem erneuten Versuch lässt sich die bereits sichtbare Revision mit `check` feststellen. `fmt` gibt eine normalisierte Fassung der Einstiegsdatei nach stdout aus und prüft sie vor der Ausgabe erneut.

## Interaktive Terminalprogramme

`tide play DATEI` verbindet ein TIDE-Programm mit einem interaktiven POSIX-Terminal. Der Host beginnt mit `main > T`; `size > &ii` liefert Breite und Höhe in Zeichenzellen. Bei passender Fenstergröße ruft er zwölfmal je Sekunde `tick world:T keys:{Keys} > T` und danach `draw world:T > *{Glyph}` auf. Jeder Aufruf erhält ein frisches Arbeitsbudget. Die vier Funktionen und ihre Aufrufe müssen frei von Außenwirkungen sein.

`Keys` enthält die fünf booleschen Felder `left`, `right`, `fire`, `start` und `pause`. Sie zeigen Tastendrücke seit dem letzten Takt an. `Glyph` hat die Felder `x:i y:i text:t ink:t`. Der Host zeichnet druckbares ASCII in Listenreihenfolge ab der linken oberen Ecke (0,0). Farbnamen sind `dim`, `cyan`, `green`, `pink`, `gold` und `white`. Darstellung, Spielregeln und Zustandswechsel sind im [spielbaren Beispiel](apps/space_invaders.tide) nachzulesen.

### Ereignisse und eine geöffnete Datei

`tide play PROGRAMM --document PFAD` öffnet ein interaktives Textdokument. Der Host liest UTF-8 aus der benannten regulären Datei oder startet bei einem neuen Pfad mit leerem Text. Die Obergrenze beträgt 128 KiB. Der Dateiname für die Anzeige ist der letzte Pfadbestandteil.

| Reine TIDE-Funktion | Aufruf durch den Host |
|---|---|
| `main body:t > T` | Liefert den Anfangszustand aus dem Dateiinhalt. |
| `step world:T key:{Input} value:t > &T{Effect}` | Verarbeitet ein einzelnes Ereignis und liefert Folgezustand und gewünschten Effekt. |
| `view world:T name:t > {View}` | Liefert die Felder `body:t caret:i title:t status:t help:t`. Der Cursor ist ein Codepunkt-Offset von null bis einschließlich Textlänge. |

`Input` enthält `character`, `control`, `left`, `right`, `up`, `down`, `home_key`, `end_key`, `backspace`, `delete_key`, `enter_key`, `escape`, `stored` und `io_error`. Bei `character` enthält `value` das Zeichen, bei `control` den Kleinbuchstaben der Tastenkombination, bei `io_error` die Fehlermeldung. Der Host stellt Tab als Zeichen zu und hält beim Zeichnen den Cursor im sichtbaren Ausschnitt.

`Effect` umfasst `idle`, `store` und `finish`. Bei `store` schreibt der Host den Text aus `View.body` in den beim Start gewählten Pfad. Anschließend erhält das Programm `stored` oder `io_error` und kann im Puffer weiterarbeiten oder die Sitzung beenden. Der Host prüft die Dateiversion vor dem atomaren Austausch. Einen inzwischen belegten neuen Pfad überschreibt er nicht. Die Umsetzung von Textbearbeitung und Rückfragen steht im [Nano-Beispiel](apps/nano.tide).
