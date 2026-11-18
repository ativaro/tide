# Vollständige Quelländerungen nativ prüfen und schreiben

`tide edit DATEI --base REV --source KANDIDAT` prüft eine neue Einstiegsdatei im ursprünglichen Projekt. Ein Agent kann den Kandidaten in einem anderen Verzeichnis vorbereiten, zusätzliche Module importieren und die gesamte Änderung vor dem Schreiben testen. `--write` übernimmt den geprüften Text. Der bisherige native Starter meldete für beide Aufrufe `E_BACKEND`. [Ausführbares Saldobeispiel](../../README.md#eine-änderung-prüfen-und-übernehmen)

## Was eine Übernahme voraussetzt

Die Basisrevision umfasst die ursprüngliche Einstiegsdatei und ihre transitiven Importe. TIDE prüft die Revision vor dem Laden des Kandidaten. Es vergleicht die Beispielverträge nach Namen und Inhalt. Umgeordnete JSON-Felder sind gleichwertig. Eine geänderte Erwartung, ein neues Ziel oder die Löschung eines vorhandenen Beispiels erfordert `--change-examples`. Hinzugefügte Beispiele sind sofort zulässig. Auch bei ausdrücklich zugelassenen Vertragsänderungen müssen die Typprüfung und sämtliche Beispiele des Kandidaten bestehen.

Eine Übernahme hält eine Sperre auf dem Projektverzeichnis. Der Compiler stellt der TIDE-Funktion Leserechte für die Projektquellen und den benannten Kandidaten zur Verfügung. Bei `--write` kommt das Recht zum Ersetzen der Zieldatei hinzu. TIDE lässt den Inhalt in einer temporären Datei im Zielverzeichnis bereitstellen, prüft die Quellen beider Projektfassungen erneut und gibt erst dann den Dateiersatz frei. Die temporäre Datei übernimmt die Modusbits des Ziels. Datei und Verzeichnis werden synchronisiert. Die Sperre koordiniert TIDE-Schreiber. Fremde Editoren können zwischen der letzten Prüfung und der Umbenennung schreiben. [Entscheidungen in TIDE](../../native/bootstrap/editor_transaction.tide) · [Vertragsvergleich](../../native/bootstrap/editor.tide) · [Bootstrap und Dateioperationen](../../native/bootstrap/seed.tide)

## Laufzeit bis zur Werkzeugantwort

Gemessen wurde der vollständige CLI-Aufruf auf einem AMD Ryzen 9 9950X3D unter Linux x86-64. Die historische Referenz verarbeitet dieselben TIDE-Dateien mit CPython 3.14.10. Die erste native Fassung in der Tabelle beherrscht bereits den Vergleich großer Vertragsmengen. Sie verwendet noch die bisherige zusammenhängende Listendarstellung und kodiert den Kandidatentext für die Vorschau erneut. Nach drei Aufwärmrunden liefen alle drei Werkzeuge in rotierender Reihenfolge auf demselben logischen Kern. Gezeigt sind Mediane über je 15 Runden, beim großen Katalogtausch über sieben. Schreibmessungen begannen jeweils mit der ursprünglichen Datei. [Einzelzeiten, Hashes und Prüfergebnisse](pruefung.json)

| Aufgabe | Erste native Fassung | Nativ jetzt | Historische TIDE-Referenz |
|---|---:|---:|---:|
| Saldokandidat prüfen | 6,01 ms | 6,00 ms | 29,08 ms |
| Saldokandidat übernehmen | 7,67 ms | 7,70 ms | 30,98 ms |
| Kandidat mit importierter Funktion prüfen | 6,62 ms | 6,58 ms | 29,52 ms |
| Kandidat mit importierter Funktion übernehmen | 8,39 ms | 8,40 ms | 31,47 ms |
| Unbestätigte Vertragsänderung melden | 5,80 ms | 5,77 ms | 29,06 ms |
| Fehlgeschlagenes Beispiel melden | 5,85 ms | 5,86 ms | 29,12 ms |
| Veraltete Revision melden | 5,43 ms | 5,40 ms | 28,46 ms |
| Vertrag mit 4.096 i64-Eingaben prüfen | 48,44 ms | 43,52 ms | 30,99 ms |
| Vertrag mit 4.096 i64-Eingaben übernehmen | 45,81 ms | 46,17 ms | 33,10 ms |
| 2.100 Beispiele durch 2.100 andere ersetzen, Vorschau | 622,33 ms | 171,19 ms | 69,49 ms |

## Was die Messungen verändert haben

Der erste Vergleichsalgorithmus vereinte die Namen aus beiden Fassungen in einer Liste. Damit scheiterte bereits die Vorschau für zwei einzeln gültige Dateien mit zusammen 4.200 verschiedenen Namen. TIDE durchläuft nun beide sortierten Namensfolgen parallel und baut den Bericht abschnittsweise auf. Die 4.200 Einträge stimmten im Einzelvergleich mit der Referenz überein.

Anschließend zeigte das Profil beim Aufbau der Listen für Deklarationen und Beispiele wiederholte Kopien ihrer vorhandenen Elemente. Der Bootstrap speichert Listen mit Texten, Records und anderen Klassenwerten jetzt in gemeinsam genutzten Seiten mit je 16 Elementen. Beim Anhängen an eine geteilte Liste können die vollen Seiten erhalten bleiben. Für Zahlen, Wahrheitswerte und Varianten bleibt die Speicherung zusammenhängend. In der Vorprobe mit einer Seitenstruktur auch für Zahlen verlangsamte sich die direkte Vorschau für die große i64-Liste von 43,74 auf 50,16 ms. Die gewählte Aufteilung brauchte dort 44,45 ms. Der Katalogtausch ist trotz der Verbesserung im endgültigen CLI-Vergleich noch 2,46-mal so langsam wie die historische Referenz. [Bootstrap-Prüfungen für unterschiedliche Listenversionen](../../native/bootstrap/compiler_checks.tide)

Die Vorschau verwendet jetzt die bereits kodierte Quelle aus dem Projektschnappschuss. Beim Saldo sank die Antwort von 262 auf **235 Tokens**, bei der importierten Funktion von 420 auf **367**. Die Referenz lieferte 247 und 379 Tokens. Die große Listenvorschau liefert weiterhin **32.904 Tokens**, da `--source` in der Vorschau den vollständigen vorgeschlagenen Text zurückgibt. Gezählt wurde die gesamte Standardausgabe bzw. bei Fehlern die Diagnose mit `o200k_base`. Gesamttokens eines Modelllaufs und Zeit bis zu einer blinden Reparatur wurden hier nicht gemessen.

## Abnahme am 17. November 2026

- Ein vollständiger Selbstbau mit leerem Buildverzeichnis, Tests und Paketinstallation lief ohne Python und ohne Experimentarchiv. Die sechs installierten nativen Werkzeuge stimmten byteweise mit dem gesonderten lokalen Paketbau überein. Alle zwölf bestehenden ELF-Prüfsummen für die Anwendungsprogramme bestanden. Die isolierte Installation prüfte und schrieb eine Saldoänderung und wies die Wiederholung mit veralteter Revision zurück.
- Bei 44 Ausgangslagen wurden Vorschau und Schreiben jeweils mit und ohne Zustimmung zu Vertragsänderungen verglichen. Alle **176** Versuche stimmten mit der Referenz bei Status, Ausgabekanal, JSON-Inhalt, Zielbytes und Modusbits überein. 78 waren erfolgreiche Aufrufe. Die Fälle umfassten neue, gelöschte und fehlerhafte Importe, geänderte Verträge, eine bereits fehlerhafte Ausgangsfassung, CRLF, Unicode, i64-Grenzen und das Größenlimit.
- Zwölf Gruppen von acht gleichzeitigen TIDE-Schreibern starteten jeweils mit derselben Revision und unterschiedlichen Kandidaten. Jede Gruppe hatte genau eine Übernahme. Alle 84 unterlegenen Aufrufe meldeten `E_REVISION` mit der übernommenen Revision. In zehn weiteren Versuchen änderte ein externer Schreiber ein neu importiertes Modul während der Vorbereitung der Zieldatei. Alle zehn Übernahmen brachen ab und ließen die ursprüngliche Einstiegsdatei intakt.
- Die bisherigen **1.950** Vergleiche für Typprüfung, Auswertung, Regeln, Inspektion, Fingerabdrücke und Diagnosen bestanden erneut. Eine separate Prüfung mit GCC und Clang unter UndefinedBehaviorSanitizer bestätigte bei jeweils 19 Listenlängen bis 4.096 die ursprünglichen Werte nach verzweigtem Anhängen. [Dauerhafte Editorprüfungen in TIDE](../../native/bootstrap/editor_checks.tide)

Der native Editor unterstützt vollständige Kandidaten für Projekte im Umfang des nativen Prüfers. Revisionsgebundene Änderungen einzelner Syntaxknoten mit `--edits`, die allgemeine Ausführung von Text- und Record-Funktionen und die interaktive Terminalanbindung bleiben offen.
