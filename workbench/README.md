# Change a TIDE function body

To find the function in your editor, run `tide context FILE --function NAME --call-sites` in the entry file's directory. Open `declaration.file` at the reported line and column. The `call_sites` array gives the same coordinates for each direct caller. [Worked example](../GETTING_STARTED.md#navigate-a-multi-file-failure)

`function_body.tide` prepares an order for exactly one function of the entry file. The model receives the order, signature, and current body. It responds with a TIDE expression on a single line. The caller can provide examples, an observed error message, or required signatures in field `task`. For a new function, the desired signature and a body like `fail "offen"` suffice as a starting point.

The following recipes also document the earlier total scope of the toolbench. For natively supported projects, `forms`, `check`, `context`, `hole`, `edit --edits`, and `edit --source` are available. Complete candidate files can be directly checked and adopted. Detection of function heads runs natively with `./tide run workbench/source_layout.tide --call function_header --inputs '{"line":"  balance opening:i > i","name":"balance"}'`. This call yields `true`. For the complete toolbench recipes, file read permissions and record parameters are still missing. [Executable example with balance](../README.md#check-and-accept-a-change)

## Repair a node

`./tide test FILE --diff --explain=nodes` reports the deviation and the executed path on the first failed example. `repair.nodes` contains up to 32 operator locations and replaceable expressions in the entered functions. Each entry lists node ID, expression, type, and operator alternatives. The optional field `replacements` contains single-line expression replacements. For incomplete execution traces, TIDE uses statically reachable definitions. The finding marks this case in `repair.execution`.

Take the revision from `repair.revision` and the node ID from the finding. A switch has the form `[{"node":"hilfsmodul.tide:2:1","op":"<"}]`. For a whole expression at the same node, use `replace` with a single-line TIDE expression.

```sh
./tide edit "$project" --base "$revision" --edits "$patch"
```

TIDE checks revision, source file, types, and examples. Add `--write` to accept a successful change. On failure, the source remains unchanged. The diagnosis can serve as feedback for the next proposal. [Local comparison](../experimente/55_knotenreparatur/report.md)

`./tide test FILE --diff --explain=candidates` tries up to 32 changes in memory. First, it checks form-compatible operator switches. Then, it tries expression replacements `a*(b+c)` and `(a+c)*b` at `a*b+c` or `c+a*b`. All three operands must be simple integer literals or bindings. The replacement is fully type-checked.

If no single change remains, TIDE uses the remaining budget for three further corrections. In calls to custom functions, it can swap two arguments of the same type, even across an intermediate argument. From `text_len s`, `byte_len (utf8_bytes s)` can become. From `text_find s trenner 0`, a search with `text_rfind` to the end of the text can become. For computed text, the replacement evaluates the expression only once. With `--pairs`, these corrections can also belong to cross-file pairs. An argument swap in the caller can compensate for the error in the called function. An example of a direct call to this function distinguishes both repair locations. [Measurement with direct module check](../experimente/70_strukturelle_reparatur/report.md)

`repair.candidates` contains exclusively changes that pass all existing examples. The entries contain `op` or `replace` and are already in the format for `edit --edits`. `repair.candidate_checks` states the number of considered changes and marks a limited search. The source files remain unchanged during the search.

For agent handover, contract, observed deviation, and `repair.candidates` suffice. With a single candidate, the caller can submit it directly for independent acceptance. An empty list means that the limited search found no successful change. Via `--explain=nodes`, a custom expression replacement can be prepared. [Comparison with same precheck for Python-AST](../experimente/58_ausdrucksvorpruefung/report.md)

### Check the repair location with a module example]

Give the intermediate function its own public contract. In the interface list, `main` forwards the arguments unchanged to `samples`. Both functions must provide exactly four sampling points for one step at rate 4. Therefore, besides the introductory example in `panel.tide`, a direct example appears in `route.tide`.

```tide
example one_step samples
{"inputs":{"begin":3,"finish":4,"rate":4},"expect":4}
```

For the usual call `./tide test panel.tide --diff --explain=candidates --pairs`, the example applies to each individual edit and each cross-file pair. A swap only in `main` yields `samples` here as still −4 and fails before selection. If the entry forwards values converted, use own inputs and target values from the intermediate module's contract at the intermediate module. [Repaired interface list](../experimente/71_modulvorpruefung/repariert/cut/route.tide) · [Comparison with Python-AST](../experimente/71_modulvorpruefung/report.md)

For multiple green candidates, `--probes` accepts an input pool. Provide per line a JSON object with the arguments of the failed example. Select inputs from the technically valid range. The search supports functions without read access. It checks at most 32 inputs and 128 candidate evaluations.

```sh
pool=$(printf '%s\n' '{"a":0,"b":1}' '{"a":1,"b":1}')
./tide test "$project" --diff --explain=candidates --probes "$pool"
```

`repair.counterexample` contains the first input where all candidates provide a value and these values differ from each other. `outcomes` links each value with its edit. The search sets no target value and writes no files. Confirm the result via the contract, an independent oracle, or a technical decision. Subsequently, add a new public example for `repair.target` in a project copy and repeat the precheck. The candidates of the new finding belong to its new revision. [Comparison with confirmed counterexample](../experimente/59_oeffentliches_gegenbeispiel/report.md)

### Check two files together

`--pairs` complements `test --explain=candidates`. If the complete single check finds no green candidate, TIDE checks up to 64 pairs from two different files. `repair.pair_checks` states the number of checked pairs and reports with `truncated` a truncated search. Each element of `repair.pair_candidates` is an array of the two jointly successful edits. With `--probes`, TIDE can also compare green pairs. Then `outcomes[].edit` contains both edits in each case.

```sh
./tide test "$project" --diff --explain=candidates --pairs 2> "$diagnose" || test "$?" = 1
revision=$(jq -er .repair.revision "$diagnose")
patch=$(jq -ec '.repair | select(.pair_checks.truncated == false and (.pair_candidates | length) == 1) | .pair_candidates[0]' "$diagnose")
./tide edit "$project" --base "$revision" --edits "$patch"
```

The editor checks the edits jointly against the same project revision and all examples. The preview provides the checked texts as `files` with each `file` and `source`. Repeat the command with the same base and `--write` to commit the checked files together. If the base is stale, obtain a fresh revision and inspect its node locations before retrying. [Measurement at the double counter](../experimente/61_dateiuebergreifende_paare/report.md)

### Generate inputs for green pairs

TIDE derives the spans and parameter relationships for green pairs from `requires` in the target's example contract. Here, the inclusive interval 1 to 3 applies to both parameters, plus additionally `a <= b`.

```tide
example square main
{"inputs":{"a":2,"b":2},"expect":8,"requires":{"a":{"gt":0,"le":"b"},"b":{"ge":1,"le":3}}}
```

```sh
./tide test "$project" --diff --explain=candidates --pairs --probes "$pool"
```

The fixed pool is optional. TIDE skips inputs outside the contract. If the pool search does not separate pairs, TIDE tries midpoints, boundary values, neighbors of the failed example, and mixed corner points. For connected parameters, it can jointly adjust multiple values of a search point until all conditions are met. Both the fixed and generated searches have a budget of 32 inputs and 128 candidate evaluations. Generation skips public examples of the target and already checked inputs. `repair.probe_range` shows the derived bounds per parameter. `repair.generated_probes_checked` counts the generated and checked inputs, and `repair.counterexample_source` reports `"fixed"`, `"generated"`, or `null`.

`--probe-range '{"a":[1,3],"b":[1,3]}'` provides spans for projects without `requires` or restricts generation to the intersection with the contract. Confirm the counterexample's target value independently and repeat the precheck. [Comparison with Python-AST](../experimente/65_parameterbeziehungen/report.md)

### Prepare order

In the project directory with Bash and `jq`:

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

The copy lies next to the entry file so that TIDE finds the same imports and the same lock file. The revision belongs to this copy. The model's answer comes as a pure expression in `$work/antwort.txt`. For local testing, you can specify it as:

```sh
printf '%s\n' 'fold entries opening total row entry + total entry' > "$work/antwort.txt"
```

### Check and accept answer

```sh
./tide run workbench/function_body.tide --call candidate \
  --read "source=$base" --read "answer=$work/antwort.txt" \
  --inputs '{"name":"balance"}' | jq -ejr . > "$work/kandidat.tide"
./tide edit "$file" --base "$rev" --source "$work/kandidat.tide" --write
```

`candidate` replaces only the old function body. Signature, neighbor declarations, examples, and surrounding line endings come from the stored version. `jq -j` outputs the text with its original file ending. The function selection supports LF and CRLF. The tool checks the name and returns multiline answers. Type checking, all project examples, and the base revision check run before atomic writing by `tide edit`. In case of an error, the target file remains intact. For another model answer, the diagnosis and the same order are available.

`./tide test workbench/function_body.tide` runs the tool examples. The [Balance test](../experimente/12_funktionsrumpf/report.md) contains two answers actually provided by the model with the results of the acceptance test.

## Find errors across multiple files

The native package provides `tide test FILE --explain` with the repair context for the first failed example. The field `repair` contains entry file, revision, target, input, and reachable definitions. A node identifier like `adjustment.tide:2:1` can be used for `edit --edits` in the next call. For a rule, the original declaration text, the file, and the first line number are available. [Measurement on faulty import](../experimente/38_fehlerkontext/report.md)

`project_context.tide` accepts the call relationships from `tide check`, the source files of the same project copy, the public entry point, and an observed deviation. From this entry point, it follows all direct and indirect calls, including rules in `scan`. It delivers every reachable function body once with its original filename. Records and variants remain visible. Examples and unreachable function bodies are omitted. The selection is static and also considers branches that the individual error case does not traverse.

In the following Bash example, `jq` passes the input data to TIDE. The function selection occurs in TIDE. Execute from the project directory and adapt `entry`, `root`, and `observation` to your own case. `root` denotes the entry point called from outside, such as `main` for a data program or `step` for a keyboard input.

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

Source files and compiler findings must originate from the same unchanged state. Missing or duplicate reachable definitions lead to an error. For a type or syntax error that causes `tide check` to abort early, its compiler diagnosis is directly available. For projects above the JSON or work budget limit, the CLI reports the reached limit. The generated view is a read result. Repairs across multiple files can be applied jointly in a working copy and verified there against the original acceptance test.

## Repair grouped function bodies

The grouped view shows each call with its arguments in parentheses. The native parser reconstructs them from the previously checked source code and its declarations. For example, one can read at `(fold xs 0 s row x (+ s (fee x)))` that `fee` runs for each element. The model may change all visible ordinary functions via their project-wide unique name. Each change cites only `name` and the complete single-line `body`. Rules remain visible as context.

The following commands bind the working copy to the checked revision. From the plan, `tide forms` reads all reachable sources in a single process and delivers per ordinary function name, tabulator, and fully parenthesized function body. The file assignment and order come from the same plan. The native parser processes checked UTF-8 source snapshots up to 128 KiB with LF or CRLF. It counts Unicode code points and obtains the spelling of text literals. If parser limits are exceeded (e.g., lines with more than 4,096 code points) or an inconsistent assignment occurs, the workflow uses the previous compiler query per function. Type checking continues to be handled by `tide check`.

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

`compiler_view` imports the function bodies provided by the compiler per file in a single pass. The previous call `repair_view` can be further utilized by existing tools.

The model response arrives as an object `{"edits":[{"name":"…","body":"…"}]}` after `$work/antwort.json`. The function `candidate_files` assembles it into the complete original texts. It rejects, among other things, duplicate goals, unknown names, multi-line answers, and ambiguous file assignments. Only when all replacements are possible does it deliver the array of file candidates.

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

At `E_SYNTAX` with `Missing operand` immediately after the last token of a submitted body, `closing_retry` can suggest exactly one `)` in the diagnosis column. Filename, function header, body text, and position belong to the same candidate copy. The column counts Unicode code points starting from one. The normal success path proceeds without this call. The local attempt runs once. A genuinely missing argument remains a compiler error. [Measurement on journal run](../experimente/18_lokale_syntaxreparatur/report.md)

For an external acceptance suite, the caller must additionally execute this suite over the candidate copy. The tool's return confirms the text changes. Type correctness and domain behavior are checked by the caller with the compiler and its tests. The example writes exclusively to the new working directory.

### Replace an excerpt in the function body

For a small correction, the model can name a unique text excerpt from the grouped view. In this operating mode, it receives the same sources and the instruction to return `name`, `before`, and `after` per changed function. If the printed body of `sheets` is approximately `(div (+ n capacity) capacity)`, this answer suffices:

```json
{"edits":[{"name":"sheets","before":"(+ n capacity)","after":"(+ n (- capacity 1))"}]}
```

The search scope is exactly the printed body of the named function. A missing or multiple-occurring excerpt yields a diagnosis. An empty `before` replaces the entire body. A sentence can change functions from multiple files. All excerpts refer to the same inspected source copy.

If directory, reachable sources, and failed test for this source copy have already been checked, `fragment_view` generates the appropriate model instruction. It names the already completed check steps and allows further inspections in case of a specific information gap. `view` is the input composed above from package and compiler responses.

```sh
./tide run workbench/grouped_view.tide --call fragment_view --inputs "$view" |
  jq -r '.instruction,.observation,(.files[] | "\n--- "+.file+" ---\n"+.source)'
```

```sh
payload=$(jq -nc --argjson input "$args" --slurpfile forms "$work/forms.json" \
  --slurpfile reply "$work/antwort.json" '{files:$input.units,forms:$forms[0],edits:$reply[0].edits}')
./tide run workbench/function_fragment.tide --call fragment_files --inputs "$payload" > "$work/files.json"
```

The file candidates are written to a working copy as above and checked with the compiler and acceptance tests. A single replacement may also affect multiple characters within a token.

### Show further available functions

A repair can initially call an already included library function. The optional call `unused_signatures` supplements the signatures of the ordinary functions missing in the view from the selected entry point. The list comes from the same checked project version. It also includes available functions from the entry module.

```sh
jq -r '.unused[]' "$work/plan.json"
```

### Edit excerpts with the author's brackets

`source_repair` uses the verified project copy and the list of reachable functions from `prepare_grouping`. The view retains all original brackets. In ordinary function hulls, it replaces each line break with a space. Indentation and spaces in text literals are retained. Rules and type declarations remain visible as context.

After generating `$work/plan.json`, these commands suffice for view and edit forms. They replace the individual `tide context` calls of the grouped workflow.

```sh
payload=$(jq -c '.packet+{queries}' "$work/plan.json")
./tide run workbench/source_repair.tide --call source_repair --inputs "$payload" > "$work/source-repair.json"
jq '.forms' "$work/source-repair.json" > "$work/forms.json"
jq -r '.view | .instruction,.observation,(.files[] | "\n--- "+.file+" ---\n"+.source)' "$work/source-repair.json"
```

The response is applied with `fragment_files`, the returned forms, and the complete source files of the same revision. Type checking and examples run on the candidate copy. The comparison with the fully parenthesized view is in the [blind test with jury and delivery invoice](../experimente/25_blinde_quellreparatur/report.md)].
