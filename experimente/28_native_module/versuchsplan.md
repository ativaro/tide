# Native Modulauflösung

Verglichen werden die öffentlichen Befehle check, fmt und test am selben Pfad mit demselben Projekt. Bei check zählen vollständiges JSON, Reihenfolge der Module und Revisionshash. Bei fmt zählt der genaue Text der Einstiegsdatei. Bei Fehlern zählen Exitstatus, Fehlercode, Zusatzfelder und Quellposition. Den installierten nativen Befehl in einem Mount-Namensraum ohne Python und ohne Referenzstarter ausführen.

Prüffälle umfassen Ketten, Diamanten, doppelte Importe, Modul- und Typzyklen, fehlende Module, Dateityp, UTF-8, fehlerhafte use-Zeilen, die Grenzen von Tiefe, Modulzahl und Quellbytes sowie einen Fehler in einer anderen Datei. Eine Änderung nur im Blatt eines Diamanten muss die Revision ändern. Ein unportierter Funktionsrumpf darf keine erfolgreiche Prüfung ergeben.

Für Einzeldatei, Diamant, Fehler in importierter Datei und breiten Verbund nach drei Aufwärmpaaren je 20 gepaarte vollständige check-Aufrufe in wechselnder Reihenfolge messen. Bezug ist der direkte bisherige Referenzstarter mit identischen Eingaben. Keine neuen Modellmessläufe.
