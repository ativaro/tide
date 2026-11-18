# Native Funktionsprüfung und Ausführung

Abnahme am unveränderten Bibliotheksmodul `lib/ordering.tide` mit seinen acht Beispielen, an zusätzlichen Modulen und an neu erzeugten Programmen. Der Vergleich verwendet dieselben Dateien, Argumente und Sollwerte. Er vergleicht bei `check`, `run` und `test` JSON einschließlich Fehlerort und Exitstatus, bei `fmt` die Ausgabe byteweise. Eigene TIDE-Prüffälle erfassen Gleichstände, Kurzschluss, fehlerhafte Operandentypen und die Standortangabe eines Fehlers im Import. Die bisherige Standardinstallation meldet am Bibliotheksmodul E_BACKEND.

Zeitmessung nach dem Build. Pro Aufgabe drei Aufwärmpaare, anschließend 20 Messpaare in wechselnder Startreihenfolge. Aufgaben sind Prüfung der Bibliothek, Ausführung der Beispielsuite und ein parametrisierter Gleichstandsaufruf. Die Python-Referenz läuft außerhalb des Python-freien Abnahmeprozesses. Modellzeit und Tokens gehören zu einem separaten Reparaturversuch.
