# Schreibprobe · Versuchsbedingungen vor der Auswertung

Ich schreibe acht neue Zustandsprogramme aus vier paarweise gleichartigen Aufgabenfamilien. Jeder Zwilling hat eigene Feldnamen und eine andere Zuordnung der vier Befehlsnummern. Ereignis 0 lässt den alten Zustand bestehen. Die gemeldete Ausgabe ist in beiden Formen nach jedem Ereignis das Paar beider Felder. Die vier ersten Aufgaben wechseln zwischen Regel und Funktion. In der zweiten Hälfte ist die Zuteilung je Familie umgekehrt. Beide Fassungen nutzen dieselben TIDE-Ausdrücke.

Pro Aufgabe sehe ich den Auftrag, die Feldreihenfolge, den Anfangszustand und einen Beispielschritt. Ich gebe genau eine vollständige TIDE-Regel oder eine normale TIDE-Schrittfunktion (zwei alte Feldwerte und Ereignis als Parameter, neuer Zustand als Paar) ab. Der Versuchstreiber stellt der Funktion ihren Startzustand bereit. Die Aufgaben und die Python-Referenz liegen vor der Abgabe fest. Vor der Abgabe sehe ich keine Auswertung meiner Programme. Ich kenne und entwerfe die Aufgabenfamilien selbst.

Gewertet wird zuerst pro Programm: vollständig und beim ersten Versuch auf allen Ereignisfolgen der Längen 0 bis 6 korrekt. Innerhalb einer Folge zählt jede Zwischenausgabe. Bei Fehlern betrachten wir den ersten abweichenden Übergang und das betroffene Feld. Wir erfassen außerdem die Tokens der geschriebenen Programme. Zeit, interne Denktokens und allgemeine Modellleistung sind keine Messgrößen.

## Mein Eindruck unmittelbar nach dem Schreiben

Bei `spiel` konnte ich „buchen und Bonus wieder auf den Anfangswert stellen“ direkt mit `bonus=reset` hinschreiben. Bei `konto` musste ich im zweiten Platz des Rückgabepaars die passende Anfangszahl 1 einsetzen. Der Feldname in der Tabelle hilft mir beim Gegenlesen. Beim Tausch in `karte` fand ich hingegen `pair saved position` einfacher zu überblicken als zwei benannte Zuweisungen. Bei `etappe` kostete mich die Aufteilung in mehrere Bedingungen Aufmerksamkeit; über die Zustandslogik musste ich in beiden Formen nachdenken. Diese Beobachtungen wurden vor dem ersten Prüflauf gespeichert.

## Ergebnis nach dem ersten Prüflauf

| Messgröße | Normale TIDE-Schrittfunktionen | Regeln mit `keep`, `set`, `reset` |
|---|---:|---:|
| Vollständig korrekte Erstlösungen | 4 von 4 | 4 von 4 |
| Bestandene Ereignisfolgen, alle Zwischenschritte verglichen | 78.124 von 78.124 | 78.124 von 78.124 |
| Vollständige Abgaben, `o200k_base` | 261 Tokens | 427 Tokens |
| Vollständige Abgaben, `cl100k_base` | 264 Tokens | 427 Tokens |
| Nur Rümpfe, beide Kodierungen | 216 Tokens | 334 Tokens |

Je Form enthielt der Versuch eine Aufgabe zu Positionsmarken, Reservierungen, Bonusbuchungen und einem pausierbaren Schrittzähler. Je Aufgabe wurden alle 19.531 Folgen aus fünf Ereignissen bis Länge 6 geprüft. Keine Korrektur oder zweite Abgabe war nötig. Die Folgen sind systematische Prüffälle für acht Programme, keine unabhängigen Schreibversuche.

**Was der Prüfer erkennen konnte.** Nach der Bewertung habe ich Kopien der Lösungen absichtlich verändert. Ein irrtümlich mit zurückgesetzter Merkwert fiel bei beiden Positionsaufgaben nach zwei Ereignissen auf. Ein nach der Buchung stehen gelassener Bonus fiel bei beiden Buchungsaufgaben ebenfalls nach zwei Ereignissen auf. Das Weglassen der Aktion für ein Feld wurde schon bei der Strukturprüfung der Tabelle erkannt.

**Was ich daraus ableite.** Der beobachtete Vorteil von `reset` war für mich lokal: Beim Schreiben der Buchung musste ich den Startwert des Bonus nicht erneut einsetzen. Die normale Funktion war bei festem Startwert ebenso korrekt. Beim Tauschen der beiden alten Werte fand ich das Rückgabepaar leichter zu überblicken. Die expliziten Felder und `keep` machten die Vollständigkeit einer Zeile sichtbar, verlängerten die Rümpfe in meinen Abgaben aber um rund 55 %. Für neue Regeln dieser Größe komme ich mit normalen Funktionen genauso gut zurecht. Das Ergebnis begründet keine Pflicht zur Regeltabelle.

**Grenzen.** Die Regel enthält Startdeklaration und Ausgabeprojektion; die Funktion erhält ihren Startzustand vom Versuchstreiber. Deshalb sind zusätzlich die Rümpfe ohne Kopfzeilen und bei Regeln ohne Deklaration und `out` ausgewiesen. Verglichen wurden die Gesamtformen, einschließlich benannter Aktionen und Fallstruktur. Ob ein einzelnes Schlüsselwort ursächlich hilft, wurde nicht isoliert. Ich habe Aufgabenfamilien und Referenz selbst entworfen und beide Formen im selben Chat geschrieben. Reihenfolge und Nummerierung wechseln, verwandte Lösungen können mir trotzdem bei der zweiten Aufgabe geholfen haben. Für spätere Änderungen von Startwerten oder beim Einarbeiten in fremden Code ist die Frage weiter offen.

Die [Erstlösungen](05_erstloesungen.md) in der [archivierten Originalfassung](versuche_vor_umbenennung.tar.gz) waren vor der Bewertung unter SHA-256 `ca0188807cd4e1c4cf17d40c24225d663b8b5572e02853e4f5d58a3ea71b8c96` festgehalten. Der [Aufgabengenerator mit Referenz](05_aufgaben.py) und der [Prüfer](05_werten.py) arbeiten lokal. Der Prüfer wertet nur die für diese Probe benötigten Ausdrücke aus.

```sh
python3 experimente/05_aufgaben.py
python3 experimente/05_werten.py
```

Für die optionale Zählung der Quelltext-Tokens wird zusätzlich `tiktoken` benötigt:

```sh
python3 experimente/05_werten.py tokens
```
