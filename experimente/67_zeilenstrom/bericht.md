# Messbericht mit zeilenweisem Lesen

Bei **100 MiB** verarbeitet der vorab übersetzte TIDE-Messbericht **131,0 MiB/s**, die Streaming-Referenz unter CPython **25,6 MiB/s**. Das entspricht einem gepaarten Faktor von **5,12×**. Beide lesen 13.107.200 Zeilen, zählen 6.553.600 Werte über 80 und melden als Maximum die grösste vorzeichenbehaftete 64-Bit-Zahl. [TIDE-Programm](../../apps/report_packages/stream_report.tide) · [CPython-Programm](cpython_stream.py)

| Eingabe | Zeit TIDE / CPython | TIDE MiB/s | CPython MiB/s | Faktor, gepaart | Spitzen-RSS TIDE / CPython |
|---:|---:|---:|---:|---:|---:|
| 1 MiB | 8 / 50 ms | 125,0 | 20,0 | 6,25× | 1,84 / 11,14 MiB |
| 10 MiB | 77 / 404 ms | 129,9 | 24,8 | 5,23× | 1,84 / 11,11 MiB |
| 100 MiB | 763,5 / 3.908 ms | 131,0 | 25,6 | 5,12× | 1,84 / 11,11 MiB |

Jede Tabellenzelle zeigt den Median aus acht Läufen je Grösse und Sprache. Für den Faktor wurde zuerst das Zeitverhältnis jedes Messpaars gebildet. Die Zeit bei 100 MiB lag für TIDE zwischen 761 und 771 ms und für Python zwischen 3.884 und 3.988 ms. Alle acht TIDE-Prozesse je Grösse meldeten 1.888 KiB Spitzen-RSS über den Linux-Prozesszähler der aufrufenden Shell. Bei CPython lag das höchste Einzelergebnis über alle Grössen bei 11.440 KiB. In einer getrennten Kontrolle mit drei weiteren Prozessen je Grösse und Sprache wurde der residente Speicher direkt nach Programmstart bis zum Ende abgetastet. Bei 100 MiB lagen die Mediane der höchsten beobachteten Werte aus `smaps_rollup` bei 1.184 und 11.628 KiB. Der Shell-Zähler gilt für den gestarteten Prozess. Die separaten Stichproben beginnen nach dem Laden des Zielprogramms. [Einzelmessungen einschliesslich Speicherkontrolle](messung.json)

## Gleiche Eingaben und Abnahme

Die Eingaben wiederholen denselben 64-Byte-Block mit acht Zeilen. Er enthält kurze Zahlen, negative Werte, beide i64-Grenzen, LF und CRLF. Jede Variante bekommt Leserecht auf dieselbe reguläre Datei und exakt deren Grösse als Bytebudget. Beide verarbeiten eine Zeile nach der anderen, überprüfen UTF-8 und die Ganzzahlgrammatik, begrenzen die rohe Zeilenlänge und geben denselben JSON-Record aus. [Datensatz und unabhängige Erwartungswerte in TIDE](messdaten.tide)

| Eingabe | Ungültige Zeile, von beiden gemeldet |
|---:|---:|
| 1 MiB | 131.071 |
| 10 MiB | 1.310.719 |
| 100 MiB | 13.107.199 |

Für den späten Fehler wurde in der vorletzten Zeile die Ziffer `0` durch `x` ersetzt. Grösse und Zeilenenden blieben identisch. Beide Programme brachen mit Status 1, leerem stdout und `E_DATA / invalid_integer` ab. TIDE meldete zusätzlich die Quellposition in `measurements.decode_measurement` auf Zeile 9, Spalte 1 der Paketdatei. Die fehlerhaften Läufe sind separat von den Durchsatzzeiten erfasst. [Diagnosen und SHA-256 der sechs Dateien](messung.json)

18 kleinere Fälle liefen durch CLI, TIDE-AOT und CPython. Sie prüften unter anderem Nullbudget, ein fehlendes Byte, einen früheren Datenfehler vor einer späteren Budgetgrenze, fehlende Rechte, Überlauf, ungültiges UTF-8 und CRLF bzw. ein mehrbyteiges Zeichen über die 64-KiB-Puffergrenze. Eine Zeile mit exakt 128 KiB gelang, ein zusätzliches Byte führte zu `E_LIMIT`. Weitere TIDE-Beispiele prüfen verschachtelte Leser, eigene Dateipositionen und das Zusammenspiel mit dem Snapshot-Leser. Zweimal 64 MiB aus demselben Grant gelangen. Bei zweimal 65 MiB stoppte der zweite Durchlauf auf Zeile 8.257.537 am gemeinsamen Budget von 128 MiB. [Generische Beispiele](../../native/bootstrap/fixtures/functions/stream_lines.tide) · [Sprachregeln](../../LANGUAGE.md#zeilenweise-lesen)

## Messverfahren

TIDE 0.6.2, GCC 16.2.1 und CPython 3.14.10 liefen lokal auf logischem Kern 24 eines Ryzen 9 9950X3D unter Linux. Die Eingaben lagen im warmen tmpfs. Für jede Grösse lief jede Variante einmal zum Aufwärmen, danach achtmal in wechselnder Reihenfolge. Jeder Messwert umfasst den neuen Prozess vom Start bis zur JSON-Ausgabe. zsh 5.9.2 lieferte mit `%*E` die reale Zeit auf Millisekunden und mit `%M` den maximalen residenten Prozessspeicher in KiB. Der kleinste TIDE-Zeitwert hat entsprechend grobe Auflösung. Vorabübersetzung und Dateierzeugung lagen ausserhalb der Zeitmessung. Der Vergleich lief in einem Netzwerk-Namensraum ohne Netzzugang und verwendete keine Modelle. Die Zahlen gelten für diesen numerischen Bericht mit kurzen Zeilen und warmen Daten. [Versuchsplan](versuchsplan.json)

Zum Wiederholen im Projektverzeichnis mit zsh auf Kern 24 und einem lokalen tmpfs unter `/tmp`:

```zsh
d=$(mktemp -d /tmp/tide-stream.XXXXXXXX)
./tide build --aot apps/report_packages/stream_report.tide "$d/report"
TIMEFMT='%*E s  %M KiB'
for mib in 1 10 100; do
  bytes=$((mib * 1048576))
  ./tide run experimente/67_zeilenstrom/messdaten.tide --inputs "{\"bytes\":$bytes}" |
    jq -jr .block | MIB=$mib perl -0777 -ne 'my $chunk = $_ x 16384; print $chunk for 1..$ENV{MIB}' > "$d/data"
  args=(--inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/data")
  for pair in {0..8}; do
    order=(python tide)
    if (( pair % 2 )); then order=(tide python); fi
    for arm in $order; do
      if [[ $arm = tide ]]; then
        time "$d/report" $args
      else
        time python3 -E -S experimente/67_zeilenstrom/cpython_stream.py $args
      fi
    done
  done
  cp "$d/data" "$d/bad"
  print -rn x | dd of="$d/bad" bs=1 seek=$((bytes - 9)) conv=notrunc status=none
  "$d/report" --inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/bad"
  python3 -E -S experimente/67_zeilenstrom/cpython_stream.py --inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/bad"
done
```

Paar 0 dient zum Aufwärmen. `make test` bestand. Die installierte CLI bestand die sieben Paketbeispiele und den Aufruf mit Dateirecht auch in einer Umgebung ohne Python und Compiler. Im selben isolierten Dateisystem lieferte das eigenständige AOT-Programm den korrekten 100-MiB-Bericht und die erwartete späte Fehlerzeile.
