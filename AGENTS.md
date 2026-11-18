# TIDE

TIDE ist eine eigenständige Programmiersprache. Ihre Spezifikation legt Syntax, Typen, Auswertungs- und Fehlerregeln fest. Die native Ausführung soll die Programme direkt nach diesen Regeln ausführen.

Für Anwendungen, Bibliotheken, Spracherweiterungen und neue ausführbare Tests ist TIDE die einzige Implementierungssprache. Fehlt einer Anwendung eine Fähigkeit, bauen wir sie als wiederverwendbaren Teil von TIDE und verwenden sie anschließend in der Anwendung. Ein neuer oder erweiterter Host, Adapter oder Hilfsprozess in Python oder einer anderen Sprache ist kein zulässiger Ersatz.

Python soll aus der gesamten TIDE-Werkzeugkette verschwinden, einschließlich Bootstrap, Build, Ausführung, Tests und interaktiven Hosts. CPython bleibt als externe Vergleichssprache für die ausdrücklich angeforderten Messungen zulässig. Die Ablösung eines bestehenden Befehls wird in einer Umgebung ohne Python mit denselben Eingaben und erwarteten Ergebnissen geprüft.

Für Sprachentscheidungen zählen auch die Kosten des programmierenden Modells. Laufzeit, Tokens bis zur korrekten Lösung und Zeit bis zur erfolgreichen Reparatur haben eigene 100×-Ziele und eigene Vergleichsmessungen. [Messregeln](tasks/plan.md)

## graphify

Bei der Eingabe `/graphify` zuerst den installierten Skill unter `~/.Codex/skills/graphify/SKILL.md` oder seine Anweisungen verwenden.
