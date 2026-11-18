# Modulauflösung ohne Python

Ein TIDE-Projekt mit verteilten Record- und Variantendeklarationen lässt sich mit dem Standardpaket prüfen, formatieren und testen. `tide modules` liefert auch für eine Anwendung mit unvollständigem Funktionsrumpf die Importstellen und die Projektversion. So kann ein Agent während einer Reparatur die betroffenen Dateien finden. [Prüfer](../../native/bootstrap/project.tide) · [Versuchsplan](versuchsplan.md)

## Abnahme

73 Projekte durchliefen jeweils `check`, `fmt` und `test` im installierten Paket ohne Python. In 213 Aufrufen stimmten die Ergebnisse mit der Referenz überein. Geprüft wurden Status, Ausgabekanal, vollständiges JSON einschließlich Position und Revision sowie der bytegenaue formatierte Text. Die übrigen sechs Aufrufe betrafen zwei Programme mit Funktionsrümpfen. Das Standardpaket meldete für ihre vollständige Prüfung jeweils `E_BACKEND`. Der Modulgraph war in beiden Fällen abrufbar. [Prüfprotokoll](pruefung.json)

- Bei neun Projekten wurden Importstellen, Lesereihenfolge und Revision zusätzlich unabhängig berechnet. Bei 42 echten Projekteinstiegen aus Anwendungen, Bibliotheken, Compiler und Werkbank stimmten die Modulnamen und Revisionen mit der Referenz überein. Die Importpositionen wurden am jeweiligen Quelltext nachgezählt.
- Getestet wurden unter anderem Import- und Typzyklen, ungültiges UTF-8, FIFO, Verzeichnis, symbolischer Link beim Import, Grenzfälle für Tiefe, Modulzahl und Quellbytes sowie Fehler in importierten Dateien. Eine Datei mit 5.000 Leerzeilen und getrennt gespeicherte Teile eines CRLF-Zeilenendes behielten ihre korrekten Quellpositionen.
- Zwei Module importierten dieselbe Blattdatei. Während 64 Prüfungen wurde diese Datei 456-mal atomar zwischen zwei verschiedenen Typdeklarationen ausgetauscht. Die vollständigen Ergebnisse entsprachen in 31 bzw. 33 Fällen den vorab geprüften Ständen. Jede Datei wird einmal gelesen. Über unabhängig geänderte Dateien hinweg gibt es keine gemeinsame Dateisystemtransaktion.
- Die drei Befehle bestanden die zusätzlichen 510 Vergleiche am bisherigen 170-Dateien-Korpus. 96 gültige Dateien ergaben bei wiederholter Formatierung identische Bytes. Die gruppierte Darstellung stimmte bei 1.097 Funktionsrümpfen über 38 Eingaben mit der Referenz überein, einschließlich mehrfach erreichbarer Funktionen in verschiedenen Eingaben.
- Der Neuaufbau im leeren Verzeichnis mit ausgeblendetem Python erzeugte zwölf Anwendungs-ELFs mit den bisherigen SHA-256-Werten. Der Selbstbau, die Anwendungsprüfungen und die Prüfroutine unter UndefinedBehaviorSanitizer mit aktivierten Bibliotheksassertionen bestanden. Separat bestanden 35 historische Integrationstests im Checkout mit Referenzsystem.

Beim Wechsel von der Kompatibilitätsinstallation zur Standardinstallation verschwanden der Interpreterstarter, sämtliche elf Paketmodule und ihr Bytecode. Ein fremdes Modul und sein Cache blieben erhalten. Ein Durchlauf mit symbolisch verknüpftem Modul- bzw. Cacheverzeichnis bestätigte, dass die Bereinigung keine fremden Zielinhalte löscht. Der Test verwendete ein temporäres Installationspräfix.

## Laufzeit

Drei Aufwärmpaare, danach je 20 Messpaare in wechselnder Reihenfolge. Die vollständige CLI bearbeitete jeweils denselben Pfad auf demselben Rechner. Der Vergleichsprozess war der direkte Start des historischen TIDE-Prüfers unter CPython. Der Faktor ist der Median der paarweisen Verhältnisse. [Einzelmessungen und Quellprüfsummen](messung.json)

| Aufgabe für `check` | Native CLI | Referenz | Faktor |
|---|---:|---:|---:|
| Kleine Typdatei | 7,28 ms | 30,53 ms | 4,40× |
| Vier Dateien mit gemeinsamem Blatt | 6,90 ms | 31,02 ms | 4,45× |
| Unbekannter Typ in importierter Datei | 6,47 ms | 30,33 ms | 4,83× |
| 64 zusätzliche Module | 10,23 ms | 31,77 ms | 3,13× |
| 31 zusätzliche Module in einer Kette | 7,51 ms | 31,02 ms | 4,11× |
| Projekt mit Funktionsrumpf, Kompatibilitätspaket | 36,97 ms | 31,15 ms | 0,84× |

Die ersten fünf Gruppen gewannen alle 100 Zeitvergleiche. In der letzten Gruppe kosteten die native Vorprüfung und der anschließende Referenzstart zusammen rund sechs zusätzliche Millisekunden.

Die Messung des Prüfprozesses allein zeigte bei 64 zusätzlichen Modulen zunächst 5,63 ms. Der Startcompiler erzeugt jetzt i64-Literale unmittelbar, bindet unveränderliche Zwischenwerte per Referenz und verwendet bei direktem Anhängen im `fold` den privaten Akkumulator weiter. Die Typprüfung sortiert Namensindizes stabil und bestimmt doppelte Variantennamen in Quellreihenfolge. Der fertige Prüfprozess brauchte für das Projekt 2,76 ms. Bei einer Variante mit 4.096 Namen in absteigender Reihenfolge sank die Zeit des vollständigen Befehls im zusätzlichen Dreiervergleich von 430,46 auf 72,91 ms. Die Referenz war bei dieser großen Einzeldatei mit 35,50 ms schneller. Diese Messungen erfassen Werkzeugzeit. Tokens und Zeit bis zur erfolgreichen Modellreparatur wurden in diesem Versuch nicht erhoben.

## Nachvollziehen

```sh
make test
stage=$(mktemp -d)
make install DESTDIR="$stage" PREFIX=/opt/tide
tool="$stage/opt/tide/bin/tide"
entry=native/bootstrap/fixtures/modules/report.tide
"$tool" modules "$entry"
"$tool" check "$entry" --json
"$tool" fmt "$entry"
"$tool" test "$entry"
"$tool" modules apps/space_invaders.tide
```

Im ersten Projekt verweist sowohl `opening.tide` als auch `closing.tide` auf `reading.tide`. Die Ausgabe enthält vier Importstellen und drei Moduldateien. Die Prüfung umfasst die vier Recordtypen. Für das Spiel erscheint `invaders_game.tide` an Zeile 1, Spalte 1.

## Verbleibende Abhängigkeiten

Der Checkout und die optionale Kompatibilitätsinstallation verwenden die Python-Referenz weiterhin für die allgemeine semantische Prüfung und Ausführung von Funktionen, Regeln und Beispielen, für die revisionsgebundene Bearbeitung sowie die interaktiven Terminal- und Dokumentdienste. Auch komplexere Lockdateien, einzelne interne Größenlimits und Betriebssystemfehler beim Öffnen eines Pfads mit Nicht-ASCII-Zeichen können bei den drei bisherigen Prüfbefehlen noch zur Referenz führen. In einer reinen Standardinstallation melden solche nicht unterstützten Prüfpfade `E_BACKEND`. [Stand der Ablösung](../../tasks/todo.md)
