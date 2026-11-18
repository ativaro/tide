# Einen TIDE-Funktionsrumpf ändern

`function_body.tide` bereitet einen Auftrag für genau eine Funktion der Einstiegsdatei auf. Das Modell bekommt Auftrag, Signatur und bisherigen Rumpf. Es antwortet mit einem TIDE-Ausdruck auf einer Zeile. Der Aufrufer kann Beispiele, eine beobachtete Fehlermeldung oder benötigte Signaturen im Feld `task` mitgeben. Für eine neue Funktion genügen als Ausgangspunkt die gewünschte Signatur und ein Rumpf wie `fail "offen"`.

Die folgenden Rezepte dokumentieren auch den früheren Gesamtumfang der Werkbank. Für nativ unterstützte Projekte sind `forms`, `check`, `context`, `hole`, `edit --edits` und `edit --source` verfügbar. Vollständige Kandidatendateien lassen sich direkt prüfen und übernehmen. Die Erkennung von Funktionsköpfen läuft nativ mit `./tide run workbench/source_layout.tide --call function_header --inputs '{"line":"  balance opening:i > i","name":"balance"}'`. Dieser Aufruf ergibt `true`. Für die vollständigen Werkbankrezepte fehlen noch Dateileserechte und Record-Parameter. [Ausführbares Beispiel mit Saldo](../README.md#eine-änderung-prüfen-und-übernehmen)

## Einen Knoten reparieren

`./tide test DATEI --diff --explain=nodes` meldet beim ersten fehlgeschlagenen Beispiel die Abweichung und den ausgeführten Pfad. `repair.nodes` enthält bis zu 32 Operatorstellen und ersetzbare Ausdrücke in den betretenen Funktionen. Jeder Eintrag nennt Knotenkennung, Ausdruck, Typ und Operatoralternativen. Das optionale Feld `replacements` enthält einzeilige Ausdrucksersetzungen. Bei unvollständiger Ausführungsspur verwendet TIDE die statisch erreichbaren Definitionen. Der Befund kennzeichnet diesen Fall in `repair.execution`.

Übernimm die Revision aus `repair.revision` und die Knotenkennung aus dem Befund. Ein Wechsel hat die Form `[{"node":"hilfsmodul.tide:2:1","op":"<"}]`. Für einen ganzen Ausdruck am selben Knoten verwende `replace` mit einem einzeiligen TIDE-Ausdruck.

```sh
./tide edit "$project" --base "$revision" --edits "$patch"
```

TIDE prüft Revision, Quelldatei, Typen und Beispiele. Ergänze `--write`, um eine bestandene Änderung zu übernehmen. Bei einem Fehlschlag bleibt die Quelle unverändert. Die Diagnose kann als Rückmeldung für den nächsten Vorschlag dienen. [Lokaler Vergleich](../experimente/55_knotenreparatur/bericht.md)

`./tide test DATEI --diff --explain=candidates` probiert bis zu 32 Änderungen im Speicher. Zuerst prüft es formverträgliche Operatorwechsel. Danach probiert es bei `a*b+c` oder `c+a*b` die Ausdrucksersetzungen `a*(b+c)` und `(a+c)*b`. Alle drei Operanden müssen einfache Ganzzahlliterale oder Bindungen sein. Die Ersetzung wird vollständig typgeprüft.

Besteht noch keine Einzeländerung, verwendet TIDE das verbleibende Budget für drei weitere Korrekturen. In Aufrufen benutzerdefinierter Funktionen kann es zwei gleich typisierte Argumente tauschen, auch über ein dazwischenliegendes Argument hinweg. Aus `text_len s` kann `byte_len (utf8_bytes s)` werden. Aus `text_find s trenner 0` kann eine Suche mit `text_rfind` bis zum Ende des Texts werden. Bei berechnetem Text wertet der Ersatz den Ausdruck nur einmal aus. Mit `--pairs` können diese Korrekturen auch zu dateiübergreifenden Paaren gehören. Ein Argumenttausch im Aufrufer kann den Fehler in der aufgerufenen Funktion ausgleichen. Ein Beispiel für einen direkten Aufruf dieser Funktion unterscheidet beide Reparaturorte. [Messung mit direkter Modulprüfung](../experimente/70_strukturelle_reparatur/bericht.md)

`repair.candidates` enthält ausschliesslich Änderungen, die alle vorhandenen Beispiele bestehen. Die Einträge enthalten `op` oder `replace` und sind bereits im Format für `edit --edits`. `repair.candidate_checks` nennt die Zahl berücksichtigter Änderungen und kennzeichnet eine begrenzte Suche. Die Quelldateien bleiben während der Suche unverändert.

Für die Agentenübergabe genügen Vertrag, beobachtete Abweichung und `repair.candidates`. Bei einem einzigen Kandidaten kann der Aufrufer ihn direkt für die unabhängige Abnahme vorlegen. Eine leere Liste bedeutet, dass die begrenzte Suche keine bestandene Änderung gefunden hat. Über `--explain=nodes` lässt sich ein eigener Ausdrucksersatz vorbereiten. [Vergleich mit gleicher Vorprüfung für Python-AST](../experimente/58_ausdrucksvorpruefung/bericht.md)

### Den Reparaturort mit einem Modulbeispiel prüfen

Gib der Zwischenfunktion einen eigenen öffentlichen Vertrag. In der Schnittliste leitet `main` die Argumente unverändert an `samples` weiter. Beide Funktionen müssen für einen Schritt bei Rate 4 genau vier Abtastpunkte liefern. Neben dem Einstiegsbeispiel in `panel.tide` steht deshalb in `route.tide` ein direktes Beispiel.

```tide
example one_step samples
{"inputs":{"begin":3,"finish":4,"rate":4},"expect":4}
```

Beim gewohnten Aufruf `./tide test panel.tide --diff --explain=candidates --pairs` gilt das Beispiel für jede Einzeländerung und jedes dateiübergreifende Paar. Ein Tausch nur in `main` lässt `samples` hier weiterhin −4 liefern und fällt vor der Auswahl aus. Leitet der Einstieg Werte umgerechnet weiter, verwende am Zwischenmodul eigene Eingaben und Sollwerte aus dessen Vertrag. [Reparierte Schnittliste](../experimente/71_modulvorpruefung/repariert/cut/route.tide) · [Vergleich mit Python-AST](../experimente/71_modulvorpruefung/bericht.md)

Bei mehreren grünen Kandidaten nimmt `--probes` einen Eingabepool entgegen. Gib pro Zeile ein JSON-Objekt mit den Argumenten des fehlgeschlagenen Beispiels an. Wähle die Eingaben aus dem fachlich gültigen Bereich. Die Suche unterstützt Funktionen ohne Leserechte. Sie prüft höchstens 32 Eingaben und 128 Kandidatenauswertungen.

```sh
pool=$(printf '%s\n' '{"a":0,"b":1}' '{"a":1,"b":1}')
./tide test "$project" --diff --explain=candidates --probes "$pool"
```

`repair.counterexample` enthält die erste Eingabe, bei der alle Kandidaten einen Wert liefern und diese Werte voneinander abweichen. `outcomes` verknüpft jeden Wert mit seinem Edit. Die Suche setzt keinen Sollwert und schreibt keine Dateien. Bestätige das Ergebnis durch den Vertrag, ein unabhängiges Orakel oder eine fachliche Entscheidung. Ergänze danach in einer Projektkopie ein neues öffentliches Beispiel für `repair.target` und wiederhole die Vorprüfung. Die Kandidaten des neuen Befunds gehören zu seiner neuen Revision. [Vergleich mit bestätigtem Gegenbeispiel](../experimente/59_oeffentliches_gegenbeispiel/bericht.md)

### Zwei Dateien gemeinsam prüfen

`--pairs` ergänzt `test --explain=candidates`. Wenn die vollständige Einzelprüfung keinen grünen Kandidaten findet, prüft TIDE bis zu 64 Paare aus zwei verschiedenen Dateien. `repair.pair_checks` nennt die Zahl geprüfter Paare und meldet mit `truncated` eine abgeschnittene Suche. Jedes Element von `repair.pair_candidates` ist ein Array der beiden zusammen bestandenen Änderungen. Mit `--probes` kann TIDE auch grüne Paare vergleichen. Dann enthält `outcomes[].edit` jeweils beide Änderungen.

```sh
./tide test "$project" --diff --explain=candidates --pairs 2> "$diagnose" || test "$?" = 1
revision=$(jq -er .repair.revision "$diagnose")
patch=$(jq -ec '.repair | select(.pair_checks.truncated == false and (.pair_candidates | length) == 1) | .pair_candidates[0]' "$diagnose")
./tide edit "$project" --base "$revision" --edits "$patch"
```

Der Editor prüft die Änderungen zusammen gegen dieselbe Projekt-Revision und alle Beispiele. Die Vorschau liefert die geprüften Texte als `files` mit je `file` und `source`. Übernimm alle ausgegebenen Dateien in dieselbe Arbeitskopie und führe dort die Abnahme aus. `--write` unterstützt den atomaren Austausch einer einzelnen Datei. [Messung am Doppelzähler](../experimente/61_dateiuebergreifende_paare/bericht.md)

### Eingaben für grüne Paare erzeugen

TIDE leitet die Spannen und Parameterbeziehungen für grüne Paare aus `requires` im Beispielvertrag des Ziels ab. Hier gilt für beide Parameter das inklusive Intervall 1 bis 3 und zusätzlich `a <= b`.

```tide
example square main
{"inputs":{"a":2,"b":2},"expect":8,"requires":{"a":{"gt":0,"le":"b"},"b":{"ge":1,"le":3}}}
```

```sh
./tide test "$project" --diff --explain=candidates --pairs --probes "$pool"
```

Der feste Pool ist optional. TIDE überspringt daraus Eingaben ausserhalb des Vertrags. Wenn die Suche im Pool keine Paare trennt, probiert TIDE Mittelpunkte, Randwerte, Nachbarn des fehlgeschlagenen Beispiels und gemischte Eckpunkte. Für zusammenhängende Parameter kann es mehrere Werte eines Suchpunkts gemeinsam anpassen, bis alle Bedingungen erfüllt sind. Die feste und die erzeugte Suche haben jeweils ein Budget von 32 Eingaben und 128 Kandidatenauswertungen. Die Erzeugung überspringt öffentliche Beispiele des Ziels und bereits geprüfte Eingaben. `repair.probe_range` zeigt die abgeleiteten Grenzen je Parameter. `repair.generated_probes_checked` zählt die erzeugten und geprüften Eingaben, und `repair.counterexample_source` meldet `"fixed"`, `"generated"` oder `null`.

`--probe-range '{"a":[1,3],"b":[1,3]}'` liefert die Spannen für Projekte ohne `requires` oder grenzt die Erzeugung auf den Schnitt mit dem Vertrag ein. Bestätige den Sollwert des Gegenbeispiels unabhängig und wiederhole die Vorprüfung. [Vergleich mit Python-AST](../experimente/65_parameterbeziehungen/bericht.md)

### Auftrag vorbereiten

Im Projektverzeichnis mit Bash und `jq`:

```sh
set -euo pipefail
file=apps/balance.tide
work=$(mktemp -d)
base=$(mktemp "$(dirname "$file")/.tide-basis.XXXXXXXX")
trap 'rm -f -- "$base"' EXIT
cp -- "$file" "$base"
rev=$(./tide check "$base" | jq -er .revision)
./tide run workbench/function_body.tide --read "source=$base" \
  --inputs '{"name":"balance","task":"Addiere die Buchungen ab opening in Reihenfolge mit geprüfter i64-Addition. Bei leerer Liste bleibt opening erhalten."}' \
  | jq -er . > "$work/auftrag.txt"
cat "$work/auftrag.txt"
```

Die Kopie liegt neben der Einstiegsdatei, damit TIDE dieselben Importe und dieselbe Lockdatei findet. Die Revision gehört zu dieser Kopie. Die Antwort des Modells kommt als reiner Ausdruck in `$work/antwort.txt`. Zum lokalen Ausprobieren kann man sie vorgeben:

```sh
printf '%s\n' 'fold entries opening total row entry + total entry' > "$work/antwort.txt"
```

### Antwort prüfen und übernehmen

```sh
./tide run workbench/function_body.tide --call candidate \
  --read "source=$base" --read "answer=$work/antwort.txt" \
  --inputs '{"name":"balance"}' | jq -ejr . > "$work/kandidat.tide"
./tide edit "$file" --base "$rev" --source "$work/kandidat.tide" --write
```

`candidate` ersetzt ausschließlich den alten Rumpf. Signatur, Nachbardeklarationen, Beispiele und umgebende Zeilenenden stammen aus der gespeicherten Fassung. `jq -j` gibt den Text mit seinem ursprünglichen Dateiende aus. Die Funktionsauswahl unterstützt LF und CRLF. Das Werkzeug prüft den Namen und weist mehrzeilige Antworten zurück. Die Typprüfung, alle Projektbeispiele und die Prüfung der Basisrevision laufen vor dem atomaren Schreiben durch `tide edit`. Bei einem Fehler bleibt die Zieldatei erhalten. Für eine weitere Modellantwort stehen die Diagnose und derselbe Auftrag zur Verfügung.

`./tide test workbench/function_body.tide` führt die Werkzeugbeispiele aus. Der [Saldoversuch](../experimente/12_funktionsrumpf/bericht.md) enthält zwei tatsächlich vom Modell gelieferte Antworten mit den Ergebnissen der Abnahme.

## Fehler über mehrere Dateien finden

Im nativen Paket liefert `tide test DATEI --explain` den Reparaturkontext zum ersten fehlgeschlagenen Beispiel. Das Feld `repair` enthält Einstiegsdatei, Revision, Ziel, Eingabe und erreichbare Definitionen. Eine Knotenkennung wie `adjustment.tide:2:1` lässt sich im nächsten Aufruf für `edit --edits` verwenden. Für eine Regel stehen der originale Deklarationstext, die Datei und die erste Zeilennummer zur Verfügung. [Messung am fehlerhaften Import](../experimente/38_fehlerkontext/bericht.md)

`project_context.tide` nimmt die Aufrufbeziehungen aus `tide check`, die Quelldateien derselben Projektkopie, den öffentlichen Einstieg und eine beobachtete Abweichung entgegen. Ab diesem Einstieg folgt es allen direkten und indirekten Aufrufen, einschließlich Regeln in `scan`. Es liefert jeden erreichbaren Rumpf einmal mit seinem ursprünglichen Dateinamen. Records und Varianten bleiben sichtbar. Beispiele und unerreichbare Funktionsrümpfe entfallen. Die Auswahl ist statisch und berücksichtigt auch Zweige, die der einzelne Fehlerfall nicht durchläuft.

Im folgenden Bash-Beispiel liefert `jq` die Eingabedaten an TIDE. Die Funktionsauswahl geschieht in TIDE. Vom Projektverzeichnis aus ausführen und `entry`, `root` und `observation` an den eigenen Fall anpassen. `root` bezeichnet den von außen aufgerufenen Einstieg, etwa `main` für ein Datenprogramm oder `step` für eine Tastatureingabe.

```sh
set -euo pipefail
entry=apps/report.tide
root=main
observation='Kundenmeldung oder Ergebnis des fehlgeschlagenen Tests hier einsetzen'
checked=$(./tide check "$entry")
dir=$(dirname -- "$entry")
args=$(
  { basename -- "$entry"; jq -r '.modules[]' <<< "$checked"; } |
    while IFS= read -r file; do
      jq -n --arg file "$file" --rawfile source "$dir/$file" '{file:$file,source:$source}'
    done |
    jq -cs --arg root "$root" --arg observation "$observation" --argjson checked "$checked" \
      '{$root,$observation,graph:($checked.definitions|to_entries|map({name:.key,calls:.value.calls})),units:.}'
)
./tide run workbench/project_context.tide --inputs "$args" |
  jq -r '.observation, (.files[] | "\n--- "+.file+" ---\n"+.source)'
```

Quelldateien und Compilerbefund sollen aus demselben unveränderten Stand stammen. Fehlende oder doppelte erreichbare Definitionen führen zu einem Fehler. Für einen Typ- oder Syntaxfehler, der schon `tide check` abbricht, steht dessen Compilerdiagnose direkt zur Verfügung. Bei Projekten oberhalb des JSON- oder Arbeitsbudgets meldet die CLI das erreichte Limit. Die erzeugte Ansicht ist ein Leseergebnis. Reparaturen über mehrere Dateien lassen sich in einer Arbeitskopie gemeinsam anwenden und dort mit der ursprünglichen Abnahme prüfen.

## Gruppierte Funktionsrümpfe reparieren

Die gruppierte Ansicht zeigt jeden Aufruf mit seinen Argumenten in Klammern. Der native Parser rekonstruiert sie aus dem zuvor geprüften Quelltext und dessen Deklarationen. Beispielsweise lässt sich an `(fold xs 0 s row x (+ s (fee x)))` ablesen, dass `fee` für jedes Element läuft. Das Modell darf alle sichtbaren gewöhnlichen Funktionen über ihren projektweit eindeutigen Namen ändern. Jede Änderung nennt nur `name` und den vollständigen einzeiligen `body`. Regeln bleiben als Kontext sichtbar.

Die folgenden Befehle binden die Arbeitskopie an die geprüfte Revision. Aus dem Plan liest `tide forms` alle erreichbaren Quellen in einem Prozess und liefert pro gewöhnlicher Funktion Name, Tabulator und vollständig geklammerten Rumpf. Die Dateizuordnung und Reihenfolge kommen aus demselben Plan. Der native Parser verarbeitet geprüfte UTF-8-Quellschnappschüsse bis 128 KiB mit LF oder CRLF. Er zählt Unicode-Codepunkte und erhält die Schreibweise von Textliteralen. Bei überschrittenen Parsergrenzen (etwa Zeilen mit mehr als 4.096 Codepunkten) oder einer inkonsistenten Zuordnung verwendet der Ablauf die bisherige Compilerabfrage pro Funktion. Die Typprüfung übernimmt weiterhin `tide check`.

```sh
set -euo pipefail
work=$(mktemp -d)
rev=$(jq -er .revision <<< "$checked")
mkdir "$work/source"
jq -c .version <<< "$checked" > "$work/source/tide.lock"
while IFS= read -r file; do
  jq -ejr --arg file "$file" '.units[]|select(.file==$file)|.source' <<< "$args" > "$work/source/$file"
done < <(jq -r '.units[].file' <<< "$args")
base=$(basename -- "$entry")
snapshot="$work/source/$base"
./tide check "$snapshot" | jq -e --arg rev "$rev" '.revision==$rev' >/dev/null
payload=$(jq -nc --argjson input "$args" --argjson checked "$checked" '$input+{signatures:($checked.definitions|to_entries|map({name:.key,kind:.value.kind,signature:([.key]+[.value.params|to_entries[]|.key+":"+.value]+[">",.value.returns]|join(" "))}))}')
./tide run "workbench/grouping.tide" --call prepare_grouping --inputs "$payload" > "$work/plan.json"
jq -c .packet "$work/plan.json" > "$work/packet"
batch_forms() {
  jq -jr '[.packet.files[].source] | join("\n\n")' "$work/plan.json" |
    ./tide forms > "$work/forms.tsv" &&
  jq -ce --rawfile table "$work/forms.tsv" '
    ($table | split("\n") | map(select(length > 0) | split("\t"))) as $rows |
    INDEX($rows[]; .[0]) as $by_name |
    if ($rows|all(length == 2)) and ($rows|length) == ($by_name|length)
       and (.queries|length) == ($rows|length) and (.queries|map(.name)|unique|length) == ($rows|length)
    then [.queries[] | . as $q | ($by_name[$q.name][1] // error("missing grouped function")) as $body |
          {name:$q.name,file:$q.file,$body}]
    else error("inconsistent grouped functions") end' "$work/plan.json" > "$work/forms.json"
}
if ! batch_forms; then
  jq -r --arg base "$base" '.queries[] | [.name,(if .file==$base then "." else .file end),.line,.column] | @tsv' "$work/plan.json" |
  while IFS=$'\t' read -r name file line column; do
    if [[ $file == "." ]]; then file=$base; fi
    if [[ $column == 0 ]]; then
      node=$(./tide context "$snapshot" --function "$name" |
        jq -er --arg rev "$rev" 'if .revision==$rev then .nodes[0].node else error("project revision changed") end')
    else
      node="$line:$column"
      if [[ $file != "$base" ]]; then node="$file:$node"; fi
    fi
    ./tide context "$snapshot" --function "$name" --node "$node" |
      jq -ce --arg rev "$rev" --arg file "$file" 'if .revision==$rev then {name:.definition,$file,body:.selection.expanded} else error("project revision changed") end'
  done | jq -sc . > "$work/forms.json"
fi
view=$(jq -c --slurpfile forms "$work/forms.json" '.+{forms:$forms[0]}' "$work/packet")
./tide run "workbench/grouped_view.tide" --call compiler_view --inputs "$view" > "$work/grouped.json"
jq -r '.instruction,.observation,(.files[] | "\n--- "+.file+" ---\n"+.source)' "$work/grouped.json"
```

`compiler_view` trägt die vom Compiler gelieferten Rümpfe pro Datei in einem Durchgang ein. Den bisherigen Aufruf `repair_view` können bestehende Werkzeuge weiter nutzen.

Die Modellantwort kommt als Objekt `{"edits":[{"name":"…","body":"…"}]}` nach `$work/antwort.json`. Die Funktion `candidate_files` setzt sie auf den vollständigen Originaltexten zusammen. Sie verweigert unter anderem doppelte Ziele, unbekannte Namen, mehrzeilige Antworten und mehrdeutige Dateizuordnungen. Erst wenn alle Ersetzungen möglich sind, liefert sie das Array der Dateikandidaten.

```sh
set -euo pipefail
cli=$PWD/tide
mkdir "$work/candidate"
./tide lock > "$work/candidate/tide.lock"
write_candidate() {
  local payload file
  payload=$(jq -nc --argjson input "$args" --slurpfile forms "$work/forms.json" \
    --slurpfile reply "$1" '{files:$input.units,forms:$forms[0],edits:$reply[0].edits}')
  ./tide run workbench/function_body.tide --call candidate_files --inputs "$payload" > "$work/files.json"
  while IFS= read -r file; do
    jq -ejr --arg file "$file" '.[]|select(.file==$file)|.source' "$work/files.json" > "$work/candidate/$file"
  done < <(jq -r '.units[].file' <<< "$args")
}
check_candidate() { (cd "$work/candidate" && "$cli" test "$(basename -- "$entry")"); }
write_candidate "$work/antwort.json"
if ! check_candidate 2>"$work/diagnose.json"; then
  retry=$(jq -nc --slurpfile files "$work/files.json" --slurpfile reply "$work/antwort.json" \
    --slurpfile d "$work/diagnose.json" '{files:$files[0],edits:$reply[0].edits,
      diagnostic:($d[0]|{file:(.file//""),code:(.code//""),message:(.message//""),line:(.line//0),column:(.column//0)})}')
  ./tide run workbench/function_body.tide --call closing_retry --inputs "$retry" > "$work/vorschlag.json"
  if jq -e 'has("some")' "$work/vorschlag.json" >/dev/null; then
    jq '{edits:.some}' "$work/vorschlag.json" > "$work/lokal.json"
    write_candidate "$work/lokal.json"
    check_candidate
  else
    cat "$work/diagnose.json" >&2
    exit 1
  fi
fi
```

Bei `E_SYNTAX` mit `Missing operand` unmittelbar nach dem letzten Token eines eingereichten Rumpfs kann `closing_retry` genau ein `)` an der Diagnosespalte vorschlagen. Dateiname, Funktionskopf, Rumpftext und Position gehören zur selben Kandidatenkopie. Die Spalte zählt Unicode-Codepunkte ab eins. Der normale Erfolgsweg kommt ohne diesen Aufruf aus. Der lokale Versuch läuft einmal. Ein tatsächlich fehlendes Argument bleibt ein Compilerfehler. [Messung am Journallauf](../experimente/18_lokale_syntaxreparatur/bericht.md)

Für eine externe Abnahmesuite muss der Aufrufer zusätzlich diese Suite über der Kandidatenkopie ausführen. Die Rückgabe des Werkzeugs bestätigt die Textänderungen. Typkorrektheit und fachliches Verhalten prüft der Aufrufer mit dem Compiler und seinen Tests. Das Beispiel schreibt ausschließlich in das neue Arbeitsverzeichnis.

### Einen Ausschnitt im Funktionsrumpf ersetzen

Bei einer kleinen Korrektur kann das Modell einen eindeutigen Textausschnitt aus der gruppierten Ansicht nennen. In dieser Betriebsart bekommt es dieselben Quellen und den Auftrag, pro geänderter Funktion `name`, `before` und `after` zurückzugeben. Lautet der gedruckte Rumpf von `sheets` etwa `(div (+ n capacity) capacity)`, genügt diese Antwort:

```json
{"edits":[{"name":"sheets","before":"(+ n capacity)","after":"(+ n (- capacity 1))"}]}
```

Der Suchbereich ist genau der gedruckte Rumpf der benannten Funktion. Ein fehlender oder mehrfach vorkommender Ausschnitt ergibt eine Diagnose. Ein leeres `before` ersetzt den ganzen Rumpf. Ein Satz kann Funktionen aus mehreren Dateien ändern. Alle Ausschnitte beziehen sich auf dieselbe geprüfte Quellkopie.

Wenn Verzeichnis, erreichbare Quellen und fehlgeschlagener Test für diese Quellkopie bereits geprüft wurden, erzeugt `fragment_view` die passende Modellanweisung. Sie nennt die schon erledigten Prüfschritte und lässt weitere Inspektionen bei einer konkreten Informationslücke zu. `view` ist die oben aus Paket und Compilerantworten zusammengesetzte Eingabe.

```sh
./tide run workbench/grouped_view.tide --call fragment_view --inputs "$view" |
  jq -r '.instruction,.observation,(.files[] | "\n--- "+.file+" ---\n"+.source)'
```

```sh
payload=$(jq -nc --argjson input "$args" --slurpfile forms "$work/forms.json" \
  --slurpfile reply "$work/antwort.json" '{files:$input.units,forms:$forms[0],edits:$reply[0].edits}')
./tide run workbench/function_fragment.tide --call fragment_files --inputs "$payload" > "$work/files.json"
```

Die Dateikandidaten werden wie oben in eine Arbeitskopie geschrieben und mit Compiler und Abnahmetests geprüft. Eine einzelne Ersetzung darf auch mehrere Zeichen innerhalb eines Tokens betreffen.

### Weitere verfügbare Funktionen anzeigen

Eine Reparatur kann erstmals eine bereits eingebundene Bibliotheksfunktion aufrufen. Der optionale Aufruf `unused_signatures` ergänzt die Signaturen der gewöhnlichen Funktionen, die in der Ansicht ab dem gewählten Einstieg fehlen. Die Liste stammt aus derselben geprüften Projektfassung. Sie enthält auch verfügbare Funktionen aus dem Einstiegsmodul.

```sh
jq -r '.unused[]' "$work/plan.json"
```

### Ausschnitte mit den Klammern des Autors bearbeiten

`source_repair` verwendet die geprüfte Projektkopie und die Liste der erreichbaren Funktionen aus `prepare_grouping`. Die Ansicht behält alle ursprünglichen Klammern. In gewöhnlichen Funktionsrümpfen ersetzt sie jeden Zeilenumbruch durch ein Leerzeichen. Einrückung und Leerzeichen in Textliteralen bleiben erhalten. Regeln und Typdeklarationen bleiben als Kontext sichtbar.

Nach dem Erzeugen von `$work/plan.json` genügen diese Befehle für Ansicht und Bearbeitungsformen. Sie ersetzen die einzelnen `tide context`-Aufrufe des gruppierten Ablaufs.

```sh
payload=$(jq -c '.packet+{queries}' "$work/plan.json")
./tide run workbench/source_repair.tide --call source_repair --inputs "$payload" > "$work/source-repair.json"
jq '.forms' "$work/source-repair.json" > "$work/forms.json"
jq -r '.view | .instruction,.observation,(.files[] | "\n--- "+.file+" ---\n"+.source)' "$work/source-repair.json"
```

Die Antwort wird mit `fragment_files`, den zurückgegebenen Formen und den vollständigen Quelldateien derselben Revision angewandt. Typprüfung und Beispiele laufen auf der Kandidatenkopie. Der Vergleich mit der vollständig geklammerten Ansicht steht im [Blindversuch mit Jury und Lieferabrechnung](../experimente/25_blinde_quellreparatur/bericht.md).
