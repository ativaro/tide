# Ein Modellaufruf pro Funktionsrumpf

Im [Saldoversuch](../11_saldo/bericht.md) las das Modell die Datei, änderte sie und startete den Prüfer. Jeder Werkzeugschritt ging zurück in den Modellkontext. Diesmal bereitete TIDE den lokalen Auftrag vor und prüfte nach der Antwort den zurückgegebenen Ausdruck. Beide Modelleingaben enthielten denselben fachlichen Vertrag und TIDE-Hinweis wie zuvor. Beim Reparieren war erneut das Symptom „103 statt 97“ gegeben. Der Ausdruck in der Ausgangsdatei enthielt die falsche Subtraktion. Beim Schreiben stand unter der vorgegebenen Signatur ein typgültiger Platzhalter. Im früheren Schreibversuch war die Datei leer und die Signatur im Auftrag vorgegeben.

| Aufgabe | Gesamttokens vorher | Gesamttokens jetzt | Bis zur Abnahme vorher | Bis zur Abnahme jetzt |
|---|---:|---:|---:|---:|
| Saldo schreiben | 78.662 | 19.203 | 13,225 s | 6,817 s |
| Vorzeichenfehler reparieren | 77.955 | 19.117 | 9,278 s | 5,101 s |

Die Gesamttokens sind Eingabe plus Ausgabe des gesamten Codex-Turns einschließlich Cache-Treffern. Nach Abzug der Cache-Treffer sank der Zähler beim Schreiben von 8.390 auf 7.299 und beim Reparieren von 8.195 auf 7.213. Die Ausgabetokens sanken von 403 auf 156 bzw. von 159 auf 56. Die Token-Ersparnis hängt damit wesentlich davon ab, ob erneut gelesener Kontext mitgezählt wird. [Aufträge, Antworten, Nutzungszähler und Abnahmebelege](messung.json)

### Versuchsaufbau

Am 16. November 2026 liefen zwei neue, getrennte `codex exec`-Sitzungen, zuerst Reparatur, dann Schreiben. Modell, Reasoning-Stufe, angeforderte Serviceklasse und CLI-Version entsprachen der früheren Messung (`gpt-6-astra`, `xhigh`, `priority`, 0.157.1). Jede Sitzung lief in einem eigenen leeren Arbeitsverzeichnis mit Lesezugriff, ohne Erinnerungen, Hooks und Plugins. Das Modell bekam den vorbereiteten Auftrag über stdin, rief kein Werkzeug auf und gab einen Ausdruck über `--output-last-message` zurück. Die Uhr lief bereits vor dem Kopieren und Prüfen der Ausgangsdatei und endete nach dem erfolgreichen `tide edit --write`. Das Anlegen der Testaufgabe war in beiden Versuchen außerhalb der Zeitmessung. Alle [zehn unveränderten Fälle](../11_saldo/faelle.txt) bestanden je beim ersten Versuch.

Nach den Modellläufen wurden Namensprüfung und Behandlung ungewöhnlicher Trennzeichen des Werkzeugs ergänzt. Beide aufgezeichneten Antworten wurden mit der endgültigen Fassung erneut geprüft. Die Kandidaten waren bytegleich, die zehn Tests bestanden weiterhin. Negative Proben ergaben `E_EXAMPLE` bei falschem Saldo, `E_TYPE` bei einem Wahrheitswert, `E_DATA` bei einer zusätzlichen Deklaration und `E_REVISION` bei zwischenzeitlicher Änderung. In allen vier Fällen blieb der Inhalt der Zieldatei erhalten.

Zusammen mit dem Programmeinstieg aus `apps/balance.tide` erzeugten beide Antworten dieselbe native Datei wie im Ausgangsversuch (SHA-256 `cdc5a3f33cc9bd46a07d760bc81a42818f209fb5df29f7f801289cb0225e4ef2`). Die Messung betrifft den Entwicklungsaufwand. Pro Aufgabe und Verfahren liegt ein Modelllauf vor, die Sitzungen fanden zu unterschiedlichen Zeiten statt. Die Übertragbarkeit auf größere Funktionen, mehrstufige Reparaturen und andere Cachebedingungen ist offen.
