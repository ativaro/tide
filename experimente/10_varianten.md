# Was findet TIDE beim Hinzufügen einer Spielphase?

Am 16. November 2026 habe ich die fünf Textwerte von Space Invaders in den Variantentyp `Phase` überführt. Vor dem Versuch habe ich als sechste Phase `respawn` gewählt. Ein überlebter Treffer soll eine kurze Spielunterbrechung auslösen, sofern die Partie weitergeht.

| Änderung am Spiel | Beobachtung im jeweiligen Zwischenstand |
|---|---|
| Die fünf alten Phasen erhalten benannte Fälle. `tick` und `draw` behandeln jeden Fall. | `tide check` erfolgreich, 9 von 9 TIDE-Beispielen erfolgreich. Die Simulationen erreichen Sieg und Niederlage. Der Terminaltest startet, pausiert und beendet das Spiel. |
| Ausschließlich `respawn` an die Deklaration angehängt. | Ein `tide check apps/space_invaders.tide` endet mit Status 1. Unter `E_MATCH` stehen zwei Einträge mit `missing: ["respawn"]`. Sie zeigen auf `draw` in der Einstiegsdatei (Zeile 72, Spalte 1) und `tick` im Modul `invaders_game.tide` (damals Zeile 139, Spalte 1). |
| `tick` und `draw` behandeln den neuen Fall. Die Trefferlogik ist noch die alte. | `check` erfolgreich, alle 9 alten Beispiele erfolgreich. Ein Aufruf von `tick` mit einer ankommenden Bombe und drei Schiffen liefert zwei Schiffe, Schutzzeit 16 und weiterhin `playing`. |
| Derselbe Treffer bekommt im neuen Beispiel `surviving_hit` die Erwartung `respawn`. | `tide test` meldet `E_EXAMPLE`. Im ganzen Ergebnis unterscheidet sich genau das Feld `mode`. |
| `battle` gibt bei einem überlebten Treffer in einer laufenden Partie `respawn` zurück. | Alle 10 Beispiele bestehen. Der Python-Testspieler bricht beim ersten Wiedereinstieg vorzeitig ab. Nach Umstellung seines Abbruchkriteriums auf `won` und `lost` enden seine Durchläufe wieder mit den erwarteten Ergebnissen. |

Für mich lag der Gewinn beim Ändern darin, dass ich die beiden zuständigen Verzweigungen in einem Prüflauf vor mir hatte. Für zwei weitere Entscheidungen brauchte ich die Spielregel. Erstens muss ein Treffer den Wiedereinstieg auslösen. Zweitens hat ein bereits feststehendes Spielende Vorrang. Treffen der letzte eigene Schuss und eine gegnerische Bombe zugleich, zählt bei einem verbliebenen Schiff die Niederlage, bei zwei Schiffen der Sieg. Beides ist jetzt getestet.

Der endgültige Wiedereinstieg friert das Spielfeld acht Takte ein. Auch Start, Pause, Bewegung und Feuer verändern es währenddessen nicht. Danach läuft das Spiel automatisch mit acht Takten Trefferschutz weiter.

## Den damaligen Referenzversuch wiederholen

Die folgenden Befehle gehören zum damaligen [Referenzsystem](referenzsystem/README.md). Im aktuellen Paket prüft `make check-no-python` die zusätzliche Spielphase mit den installierten nativen Werkzeugen. [Natives Ergebnis und Fundstellen](44_native_varianten/bericht.md)

```sh
./tide test apps/space_invaders.tide
python3 -m unittest discover -s tests -p test_invaders.py -v
```

`test_one_more_phase` erweitert die aktuelle Deklaration im Speicher um einen weiteren Fall und erwartet wieder genau die beiden offenen Stellen. `test_respawn` prüft Treffer, Anzeige, Countdown, Eingaben und das Ende des Schutzes. Der Versuch belegt die Abdeckung expliziter Verzweigungen in diesem Spiel. Ob ein Übergang fachlich fehlt, lässt sich aus der Liste zulässiger Phasen allein nicht ableiten.
