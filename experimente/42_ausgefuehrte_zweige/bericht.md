# Welche Zweige hat das fehlerhafte Beispiel gewählt?

Beim Paket mit genau 500 Gramm erwartet der Vertrag den Preis 6. Das Programm berechnet 8. Vom Einstieg aus sind zehn Funktionen erreichbar. Der Beobachtungslauf betritt zunächst `charge`, dann `packet` und schließlich `large`. Der Befund zeigt den genommenen `else`-Zweig und die Bedingung `(< grams 500)` in `tariffs.tide`. Damit lässt sich die falsche Grenzentscheidung im Aufrufer erkennen. [Tarifbeispiel](tarif/checkout.tide) · [Vollständiger Befund](messung.json)

Im Verzeichnis `experimente/42_ausgefuehrte_zweige/tarif` lassen sich beide Ansichten mit dem installierten Paket abrufen. Status 1 ist bei dieser absichtlich fehlerhaften Eingabe das erwartete Ergebnis.

```sh
tide test checkout.tide --explain
tide test checkout.tide --explain=executed
```

## Größe und Bereitstellungszeit

| Beispiel | Tokens statisch | Tokens beobachtet | Statisch, ms | Beobachtet, ms |
|---|---:|---:|---:|---:|
| Paketpreis, drei Dateien | 452 | 255 | 5,91 | 5,87 |
| Gleichstand bei Koordinaten | 265 | 327 | 6,13 | 6,31 |
| Rundung auf Rasterpunkte | 264 | 306 | 6,04 | 6,10 |
| Summe der Abbuchungen, 32 Werte | 208 | 226 | 5,66 | 5,84 |
| Summe der Abbuchungen, 4.096 Werte | 8.341 | 166 | 19,85 | 32,59 |
| Saldo, alle drei Beispiele korrekt | 5 | 5 | 5,98 | 5,99 |

Die erste Messgröße zählt die gesamte CLI-Antwort einschließlich Zeilenende mit `o200k_base` (gpt-tokenizer 3.4.0). Die Zeit läuft vom Start des installierten CLI-Prozesses bis zum Exit. Je Zelle wurden nach drei Aufwärmrunden 21 Durchgänge in wechselnder Reihenfolge auf Kern 2 eines Ryzen 9 9950X3D gemessen. Die statischen Antworten vor und nach der Änderung waren in allen sechs Fällen bytegleich. Einzelzeiten, Binär- und Quellprüfsummen sind aufgezeichnet. [Rohdaten](messung.json)

Bei Gleichstand und Rundung wurden alle drei erreichbaren Funktionen betreten. Die Zweigangaben kosten hier 62 und 42 zusätzliche Tokens. Das spricht für die statische Standardansicht bei kurzen, vollständig durchlaufenen Aufrufketten. Der Paketpreis zeigt, wann sich die andere Ansicht lohnt. Bei 4.096 Werten stammt der größte Platzgewinn aus dem Verweis auf die Beispieleingabe. Der zusätzliche Lauf kostet im Median 12,74 ms. Wer die Liste nachlädt, muss ihre Übertragung zum eigenen Tokenverbrauch hinzurechnen.

Beide Faltungen haben denselben Rumpf und verwenden der Reihe nach −1, 0 und 1. Die erste Liste enthält 32 Einträge und erwartet 11, die zweite 4.096 und erwartet 1.366. Der fehlerhafte Rumpf summiert negative Werte mit ihrem Vorzeichen. Das Beispiel verlangt ihre Beträge. [Faltung mit 32 Einträgen](faltung.tide) · [Originalprojekte für Gleichstand und Rundung mit Eingaben und Erwartungen](../38_fehlerkontext/versuchsplan.json)

## Prüfung der Befunde

Eine Korrektur der Tarifgrenze über den öffentlichen Editor bestand 14 Beispiele. Der reparierte Abbuchungssaldo bestand sieben, darunter die leere Liste, gemischte Vorzeichen und der größte darstellbare Betrag. Bei der langen Faltung beobachtete TIDE beide Zweige. Der vollständige Vertrag ließ sich über den angegebenen Beispielnamen an derselben Revision wieder abrufen. Weitere Fälle prüften die Eingabegrößen genau an und über der Ausgabegrenze, Unicode in einem importierten Beispiel, eine Regel mit 1.200 Ereignissen, Kurzschlussauswertung und eine Bedingung, deren Berechnung vor der Zweigwahl fehlschlägt. Der dauerhafte TIDE-Test prüft zusätzlich die Begrenzung auf 64 verschiedene Zweigentscheidungen. [TIDE-Prüfungen](../../native/bootstrap/inspection_checks.tide)

Die sechs TIDE-Reparaturvorschläge aus dem früheren Blindversuch wurden jeweils an einer frischen Projektkopie über die Knotenkennungen des neuen Befunds angewandt. Jede Fassung bestand ihre sechs öffentlichen und 72 verdeckten Fälle. Diese Wiederholung prüft, ob die damals benötigten Änderungsstellen im Befund verfügbar sind. Modell-Gesamttokens und Zeit bis zur erfolgreichen Reparatur für die neue Ansicht wurden in diesem Versuch nicht erhoben. Die damaligen Messungen für TIDE und Python mit vorbereitetem Kontext stehen im [Blindvergleich](../38_fehlerkontext/bericht.md).
