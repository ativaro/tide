# Drei Schreibweisen im Selbstversuch

Am 16. November 2026 habe ich zwölf Aufgaben je einmal in klammerfreiem Präfix (A), vollständig geklammertem Präfix (B) und Python-ähnlichen Ausdrücken (C) gelöst. Alle 36 von mir geschriebenen Erstabgaben bestanden. Die Form machte bei diesen Aufgaben einen messbaren Unterschied für die Länge und beim gelöschten Operanden für die Fehlerdiagnose.

## Ergebnisse je Aufgabe

Ein Haken bedeutet, dass die unveränderte Erstabgabe kompilierte und alle sichtbaren und zurückgehaltenen Erwartungen erfüllte. Die Zahl rechts zählt die zurückgehaltenen Eingaben je Form. Bei Ereignisfolgen wurde jeder Zwischenwert geprüft.

| Aufgabe | Reihenfolge | Präfix | Geklammert | Python-ähnlich | Eingaben |
|---|---|---|---|---|---:|
| S1 · Zwei Endpunkte sortieren | ABC | ✓ | ✓ | ✓ | 225 |
| S2 · Zwei Koordinaten verschieben | BCA | ✓ | ✓ | ✓ | 2.025 |
| S3 · Prüfvorrang bei Versandcodes | CAB | ✓ | ✓ | ✓ | 240 |
| S4 · Gutschein aktivieren und einmal einlösen | ACB | ✓ | ✓ | ✓ | 1.364 |
| A1 · Gemeinsame Gebührenfunktion für zwei Aufrufer ändern | CBA | ✓ | ✓ | ✓ | 238 |
| A2 · Benannten Start- und Verlängerungswert ändern | BAC | ✓ | ✓ | ✓ | 1.363 |
| A3 · Überlauf nur im inneren Aufruf abfangen | ABC | ✓ | ✓ | ✓ | 3.148 |
| A4 · Gleichzeitiges Löschen und Hochzählen neu ordnen | BCA | ✓ | ✓ | ✓ | 59 |
| R1 · Gelöschten Operanden ergänzen | CAB | ✓ | ✓ | ✓ | 1.575 |
| R2 · Zwei Aufrufe auf die neue Stelligkeit umstellen | ACB | ✓ | ✓ | ✓ | 225 |
| R3 · Verwechslung von Wahrheitswert und Messwert reparieren | CBA | ✓ | ✓ | ✓ | 450 |
| R4 · Bei Punktgleichstand den bisherigen Eintrag behalten | BAC | ✓ | ✓ | ✓ | 900 |

Je Form bestanden 4/4 Schreib-, 4/4 Änderungs- und 4/4 Reparaturaufgaben, einschließlich der vier Aufgaben, bei denen diese Form als erste an die Reihe kam. Keine Erstabgabe hatte einen Syntax-, Typ- oder fachlichen Fehler. Es gab keine zweite Abgabe. 16 sichtbare Beispiele und 11.812 weitere Eingaben je Form prüfen die Programme. Die drei Formen wurden auf denselben Eingaben verglichen.

## Was mir beim Arbeiten half

**Schreiben.** Beim Versand konnte ich die Bedingungen in Präfix in der Reihenfolge des Auftrags aneinanderhängen. Das funktionierte auch als Python-ähnliche Kette. Beim Gutschein passte Präfix gut, weil nach jeder Bedingung das ganze Ergebnispaar folgte. Bei zwei unabhängigen Koordinaten fand ich dagegen `pair(first(p) + dx, second(p) + dy)` leichter gegenzulesen als `pair + first p dx + second p dy`. In beiden Ausdrücken musste ich dieselbe fachliche Entscheidung treffen, welche Verschiebung zu welchem Feld gehört.

**Ändern.** Alle drei Startwert-Abgaben bestanden aus dem Rumpf `5`. Für die Gebühr genügte ebenfalls überall eine geänderte Funktion. Beim Fehlerhandler war die Grenze der Änderung entscheidend. Beide Summen können überlaufen, aber nur die innere besitzt einen Ersatzwert. In B und C konnte ich sehen, dass `post` außerhalb des Handlers steht. In A musste ich nachvollziehen, wie viele Argumente `subtotal` und `catch` verbrauchen.

| Form | Meine Erstabgabe für den Handler |
|---|---|
| A | `+ catch E_OVERFLOW subtotal x y bad _ x post` |
| B | `(+ (catch E_OVERFLOW (subtotal x y bad) _ x) post)` |
| C | `catch(E_OVERFLOW, subtotal(x, y, bad), _, x) + post` |

**Reparieren.** Beim gelöschten Operanden habe ich in allen Formen vor dem Feedback dieselbe Ursache angegeben: Der Addition fehlt ihr zweites Argument `delta`. Auftrag und Beispiel nannten das Soll. Wo der jeweilige Parser zum ersten Mal ein Problem erkennen konnte, unterschied sich.

| Form | Beschädigter Rumpf | Tatsächliche erste Diagnose |
|---|---|---|
| A | `if < used limit + used 0` | Spalte 25, Ende der Eingabe. Argument 3 von `if` fehlt. Die `0` wurde als zweiter Summand gelesen. |
| B | `(if (< used limit) (+ used) 0)` | Spalte 27, schließende Klammer von `(+ used)`. Die Addition hat einen von zwei Operanden. |
| C | `used +  if used < limit else 0` | Spalte 9, Beginn von `if`. Der Python-Ausdrucksparser meldet hier `invalid syntax`. |

Bei der neuen Signatur von `cap` meldeten B und C die falsche Argumentzahl am Ende des ersten Aufrufs. A meldete sie am Eingabeende. Beim falschen Paarfeld gaben alle drei exakt dieselbe Typdiagnose aus. Beim Gleichstand war der Starttext überall typkorrekt. Das Beispiel mit gleichen Punkten und verschiedenen Kennungen machte die fachliche Abweichung in jeder Form sichtbar. Die Diagnosen stammen aus der nachträglichen Prüfung der Starttexte. Alle Abgaben waren zu diesem Zeitpunkt bereits gespeichert.

## Tokenmessung

Zuerst je Aufgabe und Form gezählt, dann pro Spalte summiert. Die **Eingabe** ist das standardisierte vollständige Aufgabenpaket aus Arbeitsanweisung, Referenzkarte, Auftrag, sichtbarem Beispiel, Signaturen und Starttext. Die **Abgabe** enthält die bearbeiteten Funktionsnamen und Rümpfe sowie bei R1 die verlangte Ursachenangabe. **Nur Rümpfe** ist eine Teilmenge davon. Für Reparaturfeedback fielen null weitere Pakete an. Die drei Runden teilten sich den Gesprächsverlauf und die Werkzeuge derselben Sitzung. Die tatsächlichen Gesprächs-, Werkzeug-, Denk- und Zeittotale pro Schreibweise sind daraus nicht zurechenbar. Die Paketsummen sind eine reproduzierbare Messung der Versuchstexte.

| Tokenizer | Form | Eingabe | Abgabe | Nur Rümpfe | Eingabe + Abgabe | Je gelöster Aufgabe |
|---|---|---:|---:|---:|---:|---:|
| o200k_base | Präfix | 2.675 | 172 | 136 | 2.847 | 237,25 |
| o200k_base | Geklammert | 2.934 | 238 | 194 | 3.172 | 264,33 |
| o200k_base | Python-ähnlich | 2.752 | 214 | 177 | 2.966 | 247,17 |
| cl100k_base | Präfix | 2.985 | 174 | 136 | 3.159 | 263,25 |
| cl100k_base | Geklammert | 3.256 | 240 | 194 | 3.496 | 291,33 |
| cl100k_base | Python-ähnlich | 3.050 | 216 | 178 | 3.266 | 272,17 |

## Ablauf und Aussagegrenze

Ich habe Aufträge, Ausgangstexte, Stichprobenschlüssel und ein separates fachliches Orakel vor den Lösungen festgelegt. Die Vorprobe hat Referenzbäume in alle drei Formen ausgegeben und zurückgelesen. Die bekannte Hitze-, Pumpen- und Lichtlogik sowie Grenzwerte, verzweigte Auswertung, ein verweigerter Lesezugriff und das Schrittbudget bestanden. Der Prüfstand unterstützt den hier untersuchten TIDE-Ausschnitt. Alle Frontends nutzen denselben Typprüfer und Auswerter.

Ich schrieb in drei Runden jeweils zwölf Antworten. Pro Aufgabe kamen die übrigen Formen erst in den späteren Runden an die Reihe. Jede der sechs Formreihenfolgen kam zweimal vor. Ich schrieb die Rümpfe selbst, ohne die Lösungen zwischen den Formen automatisch zu übersetzen. Meine Eindrücke und die Abgaben wurden vor der Wertung festgehalten. Die vier Reparaturaufgaben begannen mit einem gezielt beschädigten Programm. Reparaturversuche **nach** einer eigenen fehlerhaften Abgabe wären separat gezählt worden.

Der geplante frische Kontext je Abgabe ist hier offen geblieben. Aufgaben und Sollverhalten stammen ebenfalls von mir, und die Fehlersuche war durch knappe Aufträge eingegrenzt. Die fachlichen Prüffälle wurden erst nach dem Sichern der Antworten ausgewertet. Bei zwölf kurzen Aufgaben mit lauter Ersttreffern kann ich weder die Zuverlässigkeit auf unbekanntem Fremdcode noch einen Zeitgewinn beziffern. Für TIDE würde ich die kompakte Form für kurze Rümpfe beibehalten und sichtbare Teilausdrucksgrenzen beim Bearbeiten verschachtelter Aufrufe weiter erproben. Die Entscheidung über eine einzige Standardsyntax bleibt offen.

[Aufträge](aufgaben.py) · [Erstabgaben in Abgabereihenfolge](erstabgaben.jsonl) · [Notizen vor der Auswertung](notizen.md) · [Unabhängig codiertes Sollverhalten](soll.py) · [Ursprünglicher Versuchsplan](../07_oberflaechen_plan.md)

### Nachrechnen

Vom Projektverzeichnis aus die Bewertung mit der Python-Standardbibliothek starten. Die Tokenmessung benötigt zusätzlich `tiktoken` mit den beiden angegebenen Wörterbüchern.

```sh
python3 experimente/07_dreiwege/versuch.py werten
python3 experimente/07_dreiwege/versuch.py tokens
```
