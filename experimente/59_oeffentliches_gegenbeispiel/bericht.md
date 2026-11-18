# Ein öffentliches Gegenbeispiel trennt grüne Kandidaten

TIDE kann mit `test --diff --explain=candidates --probes` die öffentlich bestandenen Kandidaten an denselben gültigen Eingaben miteinander vergleichen. Der Befund nennt die erste trennende Eingabe und die beobachteten Ausgaben. Für den Sollwert braucht es einen unabhängigen Nachweis. [Werkbank](../../workbench/README.md#einen-knoten-reparieren)

Bei der Restaufgabe stimmen Quotient und Rest auf den drei bisherigen öffentlichen Fällen überein. Der Eingabepool prüft die zulässige Mindestkapazität `b = 1`. Bei `a = 0` stimmen beide Kandidaten weiterhin überein. Bei `a = 1` liefert der Quotient `1` und der Rest `0`. Ein separates TIDE-Orakel bestätigte `0`, indem es die Einheiten in vollen Kisten von der Ausgangsmenge abzog. Der bestätigte Fall lag ausserhalb des bisherigen öffentlichen und verdeckten Katalogs. [Eingabepool und Orakel](probe.tide)

Beide Verfahren ergänzten `{"inputs":{"a":1,"b":1},"expect":0}` als viertes öffentliches Beispiel in einer Kopie und wiederholten dieselbe Vorprüfung. TIDE behielt `mod`, Python-AST `%`. Die verbleibenden Kandidaten bestanden jeweils alle 72 unveränderten verdeckten Fälle.

| Verfahren mit gleicher Vorprüfung | Zuvor | Mit öffentlichem Gegenbeispiel | Gesamttokens danach |
|---|---:|---:|---:|
| TIDE | 14/15 bei 531 Tokens | 15/15 | 0 |
| Python-AST | 14/15 bei 555 Tokens | 15/15 | 0 |

Die fünf Programme mit je drei Quelldateien, die ursprünglichen Tests, die Kandidatenregeln und die Obergrenze von 32 Änderungen pro Projekt blieben gleich. Die anfänglichen Kandidatenlisten stimmten mit der vorherigen Messung überein. Beide Seiten suchten in derselben Reihenfolge und brauchten zwei Probeeingaben. Alle 30 Abnahmen liefen aus separaten Kopien. Die 15 Plätze pro Sprache entsprechen fünf Aufgaben und drei Wiederholungen. Die Wahl war diesmal deterministisch. Keine Modellanfrage war nötig. [Versuchsplan](versuchsplan.json) · [Rohdaten](messung.json) · [Vorheriger Vergleich](../58_ausdrucksvorpruefung/bericht.md)

`make check-no-python` prüfte die neue Diagnose im installierten TIDE-Paket ohne Python.

Das Ergebnis zeigt den Nutzen eines fachlich bestätigten Gegenbeispiels für beide Verfahren. Ohne unabhängigen Sollwert bleiben die beobachteten Werte eine offene fachliche Entscheidung. Die Kosten einer fachlichen Rückfrage liegen ausserhalb dieser Messung.
