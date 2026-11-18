# Wie lange ein Agent auf den Beispielkontext wartet

Ein vollständiger Kontextabruf für einen großen Unicode-Beispielvertrag brauchte am 17. November 2026 mit dem bisherigen TIDE-Paket rund 69 ms. Mit der neuen Fassung dauerte derselbe öffentliche Aufruf 21 ms. Die Antwortbytes einschließlich Projekt-Revision, Vertragsfingerabdruck und Knotenkennungen waren identisch. [Einzelmessungen, Prüfsummen und Eingaben](pruefung.json)

## Öffentliche Werkzeuge

Der große Vertrag gehört zur Identitätsfunktion `main txt:t > t`. Eingabe und Erwartung enthalten jeweils 7.000 Wiederholungen von `🐈a`. Die Editvorschau fügt eine Leerzeile hinzu, prüft die Beispiele und berechnet die neue Revision. Beim kleinen Vertrag wird der Kontext für `balance` im unveränderten Saldoprogramm abgefragt.

| Aktion | TIDE vorher | TIDE jetzt | Historischer TIDE-Interpreter auf CPython |
|---|---:|---:|---:|
| Vollständiger Kontext, großer Vertrag | 69,05 ms | 21,31 ms | 29,44 ms |
| Nur Vertragsindex, großer Vertrag | 66,31 ms | 18,73 ms | – |
| Typ und lokale Bindungen mit `hole`, großer Vertrag | 32,29 ms | 12,76 ms | 29,45 ms |
| Geprüfte Editvorschau, großer Vertrag | 85,55 ms | 25,46 ms | 29,93 ms |
| Vollständiger Kontext, Saldoprogramm | 6,00 ms | 5,81 ms | 29,07 ms |
| Alle 64 kurzen Verträge im Index | 9,13 ms | 7,75 ms | – |
| Vollständiger Kontext, 14.000 ASCII-Zeichen | 13,54 ms | 8,80 ms | 28,95 ms |
| Vollständiger Kontext, 14.000 wechselnde Unicode-Zeichen | 70,07 ms | 22,28 ms | 29,61 ms |

Gemessen wurde vom Prozessstart bis zum Ende auf einem Ryzen 9 9950X3D unter Linux x86-64. Die Programme liefen auf demselben logischen Kern. Nach drei Aufwärmrunden folgten 19 Aufrufe pro Fassung und Aufgabe mit rotierender Reihenfolge. Für alle zwölf Aufgaben wurden die Ausgaben des alten und des neuen nativen Pakets byteweise verglichen. Beim historischen Interpreter fehlen die beiden Optionen für den Vertragsindex und die Auswahl eines einzelnen Vertrags im Kontext. Wo beide Werkzeuge denselben Aufruf unterstützen, wurden die JSON-Ergebnisse strukturell verglichen.

Bei drei weiteren Kontrollen mit je 21 Messungen lag der Saldo mit 4.096 Buchungen bei 6,49 ms vorher und 6,54 ms nachher. Eine Funktion mit 24 Textparametern brauchte 5,92 und 5,85 ms. Der Aufruf mit einem kurzen Textargument in einem Projekt, das den großen Vertrag enthält, sank von 30,76 auf 11,20 ms.

## Was Zeit gekostet hat

1. Die SHA-256-Runden bestimmten Bitmasken über eine in TIDE erzeugte Tabelle mit 4.096 Einträgen. Der Startcompiler kann für seine Werkzeuge jetzt AND, XOR und die Rotation eines 32-Bit-Worts direkt übersetzen. SHA-256, Padding und UTF-8-Verarbeitung stehen weiter im TIDE-Modul. Allein der Austausch der Maskentabelle brachte den großen Kontext auf 48,72 ms. Das Profil dieses Zwischenstands zeigte unter anderem 29,5 Millionen Aufrufe der arithmetischen Rotation über 18 Kontextabrufe. Die Endfassung rotiert direkt und erzeugt die 48 Schleifenpositionen für die Worterweiterung einmal pro Hash. [SHA-256 in TIDE](../../native/bootstrap/sha256.tide) · [Startcompiler](../../native/bootstrap/seed.tide)
2. Der JSON-Leser hatte Textwerte bereits dekodiert. Für die Typprüfung las TIDE die zum Hashen erzeugte ASCII-Darstellung anschließend erneut. Beim großen Vertrag ergab das 504.000 Aufrufe des Lesers für hexadezimale Escape-Sequenzen in 18 Durchgängen. Die Typprüfung übernimmt den dekodierten Wert jetzt über seinen vollständigen Feldpfad. Die kanonische Darstellung bleibt für den Vertragsvergleich verfügbar. [JSON-Bindung](../../native/bootstrap/scalar_json.tide) · [Typisierte Beispiele](../../native/bootstrap/samples.tide)
3. Beim Kodieren vieler Sonderzeichen kopierte der Akkumulator den bereits geschriebenen Text immer wieder. Der Encoder sammelt die Ausgabe jetzt in Abschnitten von 64 Codepunkten und fasst sie seitenweise zusammen. Das begrenzt die Kopierarbeit auch bei wechselnden Zeichen. Der Vorlauf mit Rotation und wiederverwendeten Textwerten lag bei 30,07 ms für den großen Kontext. [Encoder](../../native/bootstrap/json_text.tide)

## SHA-256 gegen ein eigenständiges Python-Programm

Beide Programme lasen 65.000 Byte gültiges UTF-8 von der Standardeingabe. In der Serie mit 64 Durchgängen blieb jeder Prozess für seine 64 Hashes am Leben. Ab dem zweiten Durchgang wurde der vorherige hexadezimale Digest dem Text vorangestellt. Jede Tabellenzelle ist der Median von elf Prozessen nach drei Aufwärmrunden. Alle Ergebnisse wurden gegen einen unabhängig berechneten SHA-256 geprüft. Der TIDE-Messkern wurde mit dem internen Startcompiler übersetzt. Python 3.14.10 verwendete `hashlib.sha256`. [Beide Messprogramme und Einzelzeiten](pruefung.json)

| Arbeit pro Prozess | TIDE vorher | TIDE jetzt | CPython mit hashlib |
|---|---:|---:|---:|
| Ein Hash einschließlich Prozessstart | 12,33 ms | 2,51 ms | 5,49 ms |
| 64 verkettete Hashes einschließlich eines Prozessstarts | 746,21 ms | 123,79 ms | 8,70 ms |

Für die 64 Hashes benötigt TIDE noch 14,2-mal so lange wie CPython mit seiner optimierten Bibliothek. Die unveränderten Antwortbytes der Kontextwerkzeuge ergeben bei gleichem Tokenizer dieselbe Anzahl an Antworttokens. Für die gesamte Reparaturzeit und den Modellverbrauch gab es in diesem Versuch keinen neuen Blindlauf.

## Prüfung

- 147 Bytefolgen wurden direkt mit einer unabhängigen SHA-256-Implementierung verglichen. Sie deckten leere Eingaben, Steuerzeichen, Unicode, Paddinggrenzen, den Wechsel der internen Gruppe nach 256 Blöcken und bis zu 131.072 Eingabebyte ab. Zwei bekannte Fingerabdrücke an der Gruppengrenze und Prüfungen für Vorzeichenbit und Rotation stehen dauerhaft in den TIDE-Tests. [Hashprüfungen](../../native/bootstrap/inspection_checks.tide) · [Compilerprüfungen](../../native/bootstrap/compiler_checks.tide)
- 50 Projektkontexte aus 25 Paaren gleichwertiger JSON-Schreibweisen lieferten die erwarteten Vertragsfingerabdrücke. Getrennt geprüft wurden die Revision der jeweiligen Quelldatei sowie die 50 zugehörigen Beispielausführungen. Eine Editvorschau akzeptierte die andere Schreibweise desselben Vertrags. Eine geänderte Erwartung lieferte `E_CONTRACT`.
- 553 Vergleiche für Text und Werkzeuge, 77 Ressourcen- und Diagnosefälle sowie 1.041 Knotenänderungen bestanden erneut. Für neun vollständige `fold`-Ersetzungen wurden die erwarteten Quellbytes unabhängig bestimmt, weil der historische Editor dort abbricht.
- Der isolierte Neuaufbau aus einem leeren Verzeichnis bestand ohne Python, Python-Bibliothek und Experimentarchiv. Alle sechs installierten Werkzeuge waren statisch gelinkt und bytegleich mit einem zweiten Build. Zwölf ELF-Prüfsummen und die Tests für Compiler, Editor, Nano und Space Invaders bestanden. Der Bootstrap verwendet einen C++20-Systemcompiler. Die neuen Wortoperationen sind intern. Gleichnamige frei deklarierte Funktionen wurden im öffentlichen `run` und `forms` mit beiden Paketständen geprüft.
