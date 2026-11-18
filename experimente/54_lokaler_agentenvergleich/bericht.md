# Lokaler Agentenvergleich · Zwei Reparaturen über Modulgrenzen

Qwen3 4B löste unter denselben Bedingungen **0 von 6 TIDE-Reparaturen und 2 von 6 Python-Reparaturen**. Eine anschliessend getestete Grammatikhilfe brachte TIDE ebenfalls auf 0 von 6. Damit ist für diesen lokalen Ablauf kein Tokenvorteil pro korrekter Reparatur belegt.

| Bedingung | Bestandene Reparaturen | Gesamttokens aller Versuche | Tokens pro bestandener Reparatur |
|---|---:|---:|---:|
| TIDE mit vorbereitetem Kontext | 0/6 | 3.224 | – |
| Python mit vorbereitetem Kontext | 2/6 | 3.135 | 1.567,5 |
| TIDE mit zusätzlicher Grammatikhilfe | 0/6 | 3.846 | – |

Die Kostenspalte zählt Eingabe und Ausgabe nach Ollamas Nutzungszählern. Für die Kosten pro Erfolg zählen auch die Fehlversuche. Bei null Erfolgen ist der Quotient undefiniert. Es gab kein Paar, in dem beide Sprachen bestanden. Ein Zeitvergleich bis zu einer bestandenen Reparatur ist deshalb mit diesen Paaren nicht möglich. [Rohdaten](messung.json) · [Nachversuch](messung_grammatikhilfe.json)

## Was scheiterte

Beim Gleichstand wählte Qwen in TIDE dreimal den Einstieg und schrieb den Rumpf um. Die Antworten enthielten unter anderem nicht unterstützte Bindungen und `lambda`. Mit Grammatikhilfe verschwanden diese Formen aus den Antworten. Qwen liess aber weiterhin den erforderlichen Binder für den vorhandenen Wert im `case` aus. Bei Python bestanden zwei Alternativen im Einstieg alle Fälle. Beim Rundungsfehler löste Qwen die Aufgabe in keiner Sprache. Die TIDE-Vorschläge wiederholten den unveränderten Rumpf des Einstiegs, obwohl die falsche Rundung in einem importierten Helfer lag.

Der frühere Versuch mit GPT-6-Astra löste alle zwölf dieser Reparaturen. Auch dort ergab sich kein Gesamttokenvorteil für TIDE im gepaarten Median. Der vorliegende Versuch betrifft ein anderes Modell und den getesteten Ablauf mit vorbereiteten Befunden und einem einzigen Änderungsvorschlag. Er vergleicht keine frei arbeitenden Agenten. [Früherer Blindversuch](../38_fehlerkontext/bericht.md#blindversuch-mit-vorbereitetem-kontext-für-beide-sprachen)

## Verfahren

Die zwei Aufgaben, Quellen, Befunde und Erwartungen stammen aus dem bestehenden Blindversuch. Beide Sprachen erhielten denselben fachlichen Auftrag, das erste fehlschlagende Beispiel und die statisch erreichbaren Funktionen. Jeder Lauf war eine frische Anfrage mit einem Änderungsvorschlag als JSON. Die drei Seeds waren gepaart und die Reihenfolge wechselte. Der Nachversuch fügte ausschliesslich dem TIDE-Systemtext die Grammatikhilfe hinzu. Diese entstand nach Sichtung der ersten Ergebnisse. [Versuchsplan](versuchsplan.json) · [Grammatikhilfe](grammatikhilfe.json)

Vor den Modellläufen bestanden alle vier bekannten Referenzreparaturen je sechs öffentliche und 72 verdeckte Fälle. Die TIDE-Vorschläge wurden über revisionsgebundene Änderungen in Projektkopien geprüft. CPython diente als externer Vergleich in einer schreibgeschützten Umgebung ohne Netzwerk. Beide Python-Erfolge wurden erneut bestätigt, wobei die Sollwerte ausserhalb der für das Programm sichtbaren Projektkopie lagen. TIDE verglich die vollständigen Ergebnisvektoren. [Abnahme in TIDE](abnahme.tide)

Alle 18 gemessenen Anfragen liefen auf dem lokalen Ollama 0.40.16 über Loopback. Sie verwendeten das vorhandene Qwen3-4B-Modell im Modus ohne zusätzliche Denkphase. Cloud-Kontingent wurde für diese Anfragen nicht genutzt. [Modelldigest](modell.json)
