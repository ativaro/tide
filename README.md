# TIDE 0.6.11

**TIDE (Typed Instructions, Deterministic Execution)** is a standalone, statically typed programming language. A coding agent can query the operation catalog, inspect callers, replace a subexpression and run examples against the [language specification](LANGUAGE.md).

The order-import study compares TIDE and CPython on 15 open programming tasks. Its first full application processes supplier orders, cancellations and redeliveries in SQLite. The importer and the measurement report share a typed JSON input package. Another 15 tasks are sealed for the final evaluation. [Stage 11 import performance](experimente/80_import_performance/report.md) · [Stage 10 execution parity](experimente/79_execution_parity/report.md) · [Stage 9 incremental feedback](experimente/78_incremental_feedback/report.md) · [Stage 8 atomic project edits](experimente/77_atomic_edits/report.md) · [Stage 7 package migration](experimente/76_package_migration/report.md) · [Stage 6 library and tests](experimente/75_shared_types/report.md) · [Stage 5 alpha decision](experimente/74_alpha_review/report.md) · [Stage 4 results](experimente/73_bestellimport/report.md) · [20-stage roadmap](tasks/plan.md#20-stages-from-feasibility-study-to-leading-language) · [Open tasks](experimente/72_bestellimport_basis/public-tasks.md) · [Baseline results](experimente/72_bestellimport_basis/report.md)

The checkout launcher and installed Linux x86-64 package use the same native tools to build, test, install and run TIDE without Python. The TIDE compiler emits standalone ELF programs for examples such as heating degree hours and pump control. The native checker handles modules, records, variants, pairs, lists and options and runs their examples. The CLI also serves help and catalog queries, checks lockfiles, and inspects parenthesized function bodies in batches. [Native compiler and supported features](native/README.md)

```sh
./tide build apps/light.tide /tmp/tide-light simulate
/tmp/tide-light true false false
# [true,true,false]
```

## Import an order

The importer grants access to one JSON file and one SQLite database. Repeating the first command that runs TIDE reports one duplicate and leaves the outstanding value at 375 cents.

```sh
printf '%s\n' '{"supplier":"ACME","events":[{"id":"E1","kind":"order","order":"O7","line":"1","sku":"A","qty":3,"unit_cents":125}]}' > order.json
./tide run apps/orders/import.tide --read input=order.json --db db=orders.db
./tide run apps/orders/import.tide --call position --db db=orders.db --inputs '{"supplier":"ACME","order":"O7","line":"1"}'
```

A cancellation carries its own event ID. A failed event rolls back the entire document, including earlier successful events. [Order-import contract](experimente/72_bestellimport_basis/order-import.md) · [Restart and rollback cases](experimente/73_bestellimport/restart_cases.tide)

The PostgreSQL webhook accepts the same order document at `POST /orders`. A sender can repeat a request after losing its receipt. Reusing the supplier and event ID applies each booking once. Start the service with `--workers 4 --queue 8` to run up to four handlers and hold eight further requests. When all slots are occupied, the webhook responds with HTTP 503 and a retry delay. [Webhook setup and retry tests](experimente/81_order_webhook/report.md) · [Load and cancellation measurements](experimente/82_webhook_load/report.md)

## Other applications

The [JSON Measurement Report](apps/report_packages/json_report.tide) imports measurement values with optional notes and a dictionary for sensor-dependent thresholds. The importer runs with `tide run` and as a standalone AOT program.

The [API Importer](apps/report_packages/api_report.tide) loads two pages via HTTPS and stores them together in SQLite. A repeated measurement value-ID remains uniquely identifiable per source. The [Measurement Service](apps/report_packages/measurement_service.tide) accepts decimal measurement values with timestamps and reads them back from PostgreSQL.

```sh
# The database and the role must already exist.
dsn='dbname=messbericht'
./tide run apps/report_packages/measurement_service.tide --call prepare --pg "pg=$dsn"
./tide build --service apps/report_packages/measurement_service.tide /tmp/messdienst persist
/tmp/messdienst --listen 127.0.0.1:8080 --workers 4 --pg "pg=$dsn"
```

`make test` checks the import against a local TLS server. `make check-postgres` checks the service as a regular user, HTTPS-POST, and the termination of a running database query. The target starts its own PostgreSQL cluster and requires PostgreSQL server tools, curl, OpenSSL, and socat. For the native build, the development headers of libcurl and libpq are required, and additionally libmicrohttpd for the service. [Language Reference](LANGUAGE.md#external-apis-and-services)

The [SQLite Measurement Report](apps/report_packages/sqlite_report.tide) stores each JSON import in a transaction. It calculates the report over all stored measurements. `by_sensor` reads the values of a sensor in insertion order. Both commands work with the same database.

```sh
printf '%s\n' '{"readings":[{"sensor":"A","value":7}],"limits":{}}' > messungen.json
./tide run apps/report_packages/sqlite_report.tide --db db=messungen.db --read input=messungen.json --inputs '{"limit":80}'
./tide run apps/report_packages/sqlite_report.tide --call by_sensor --db db=messungen.db --inputs '{"sensor":"A"}'
```

`make check-sqlite` checks commit and rollback across process boundaries with `run` and independent AOT programs. [SQLite Language Rules](LANGUAGE.md#sqlite)

The [Streaming Measurement Report](apps/report_packages/stream_report.tide) processes UTF-8 files with an explicit byte budget. Thus, the ahead-of-time compiled version processes a measurement file up to 100 MiB.

```sh
./tide build --aot apps/report_packages/stream_report.tide /tmp/tide-stream-report
/tmp/tide-stream-report --read input=messwerte.txt --inputs '{"bytes":104857600,"limit":80}'
```

[Language Rules for the Reader](LANGUAGE.md#read-line-by-line) · [Throughput and Peak Memory Compared with CPython](experimente/67_zeilenstrom/report.md)

## Quick start

With `map` you write the expression for a single element. TIDE builds the result list in input order. This call adds 10 to each number and outputs `[12,9,12]`. [Executable Examples](native/bootstrap/fixtures/functions/maps.tide)

```sh
./tide run native/bootstrap/fixtures/functions/maps.tide --call offset --inputs '{"xs":[2,-1,2],"shift":10}'
```

```sh
demo=$(mktemp -d)
printf 'variant Signal\nrot gruen\n\nrecord Messung\nwert:i farbe:{Signal}\n' > "$demo/messung.tide"
./tide check "$demo/messung.tide" --json
./tide fmt "$demo/messung.tide"
```

The first output contains the types and the revision of the read file. With `./tide modules apps/space_invaders.tide` you get the project version, the imported files, and the position of each `use` line. This also works while you are editing a function body. [Multi-file Example](native/bootstrap/fixtures/modules/report.tide)

With `./tide test native/bootstrap/fixtures/functions/variants.tide` you can check ten variant examples in the native package. They use named cases for tie-breaking and for rounding. If a new case is added to a project, `check` names the affected `match` locations along with file and line. [Tool Measurement](experimente/44_native_varianten/report.md)

You can run the ranking library directly in the standard package. The first command checks eight examples. The second yields `true`, because in case of a tie the specified value `on_equal` decides.

```sh
./tide test lib/ordering.tide
./tide run lib/ordering.tide --call prefer_min --inputs '{"candidate":7,"current":7,"on_equal":true}'
```

The balance program processes a list of transactions in the standard package. The first call yields `97`. The second checks three examples including an overflow.

```sh
./tide run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
./tide test apps/balance.tide
```

The maximum search returns the measurement value and the first associated line number as a pair. For an empty list, it yields `{"none":true}`.

```sh
./tide run apps/peak_lines.tide --call peak_lines --inputs '{"rows":["-8","-2","-2"]}'
# {"some":[-2,2]}
```

The measurement report returns a record with named fields. With a limit of 80, only 81 and 98 count as exceedances. For an empty list, `above` equals `0` and `peak` is the empty option. [Measurement Report](apps/summary.tide)

```sh
./tide run apps/summary.tide --call summarize --inputs '{"rows":["80","81","98"],"limit":80}'
# {"above":2,"peak":{"some":98}}
./tide test apps/summary_checks.tide
```

The rules for light, pump, and heat alarm also run in the standard package. For the light rule, the trace for the second event shows the first absence of movement. `missed` rises from zero to one, the light stays on.

```sh
./tide run apps/light.tide --call simulate --inputs '{"events":[true,false,false]}'
./tide trace apps/light.tide --example restart --step 2 --fields on,missed
```

The first call yields `[true,true,false]`. The trace provides the selected branch, the previous and new value of each selected field, and the output value. [Rule check and measurement](experimente/31_native_regeln_und_spuren/report.md)

The native evaluator also supports `catch`. A caller can handle a known error with `has_reason`, read the erroneous data line with `input_line`, and pass on the original diagnosis with `raise`. `tide check` shows under `may_fail` which errors can emerge from a function after the handler.

```sh
./tide run apps/reading_check.tide --call first_invalid --inputs '{"rows":["12","x","3"]}'
# {"some":2}
```

The line number originates from the imported number parser. For fully valid inputs, the program yields `{"none":true}`. [Line check](apps/reading_check.tide) · [Number parser](apps/readings.tide)

## Nano, Space Invaders, and file inputs

Nano's editor logic can be executed without a terminal. The first command checks ten examples. The second inserts a character and prompts for saving. The return value contains the modified buffer and the action `"store"`. The input `stored` or `io_error` yields the feedback of a save attempt. [Nano checks and tool measurement](experimente/49_zusammengesetzte_paare/report.md)

```sh
./tide test apps/nano_checks.tide
./tide run apps/nano_checks.tide --call replay \
  --inputs '{"body":"","events":[{"key":"character","value":"Ω"},{"key":"control","value":"o"}]}'
```

Nano's cursor module can also be called individually. The example yields `1` because the cat symbol occupies a Unicode code point and immediately afterwards CRLF begins. [Cursor module check without Python](experimente/36_native_texte/report.md)

```sh
./tide run apps/cursor.tide --call line_limit --inputs '{"body":"🐈\r\nΩ","pos":0}'
./tide test apps/cursor.tide
```

Space Invaders can be executed step-by-step in the native package. `main` yields the start world with 21 enemies and three shields. `tick` processes a key sequence, `draw` yields the characters along with screen positions and colors as JSON. The eleven examples check, among others, movement, hits, pause, and continuation. [Game checks and tool measurement](experimente/45_native_sammlungen/report.md)

```sh
./tide test apps/invaders_checks.tide
world=$(./tide run apps/space_invaders.tide)
./tide run apps/space_invaders.tide --call draw --inputs "{\"world\":$world}"
```

For interactive play with `tide play`, native keyboard and screen operations are still missing. Opening and saving real documents in Nano still requires native file access. [Editor checks](apps/nano_checks.tide)

The measurement report can directly read a granted UTF-8 file. `--read` binds the declared read right, `--inputs` contains the threshold value.

```sh
./tide run apps/report.tide --read input=werte.txt --inputs '{"limit":80}'
```

The measurement report can be compiled ahead-of-time as a standalone program. The build checks the imported modules. The executable file needs only the named input file and the threshold value at startup.

```sh
./tide build --aot apps/report.tide /tmp/tide-report
/tmp/tide-report --read input=werte.txt --inputs '{"limit":80}'
```

The measurement report package version uses `rowtext.parse` from `rowtext@2.0.0` and `measurements.parse` from `measurements@1.3.0`. The import graph lists paths and versions of both dependencies.

```sh
./tide modules apps/report_packages/report.tide --json
./tide test apps/report_packages/report.tide
```

[Versioned packages](LANGUAGE.md#versioned-packages) · [Comparison with CPython](experimente/66_native_pakete/report.md)

## Programs

| Application | Input and Behavior |
|---|---|
| [TIDE nano](apps/nano.tide) | Editor logic with cursor, line buffer, save request, and confirmation on exit. |
| [Space Invaders](apps/space_invaders.tide) | Interactive terminal game with formation, shields, and counterfire. |
| [Measurement report](apps/report.tide) | Granted measurement file and threshold value yield the number of exceedances and the optional maximum value. |
| [First occurrence](apps/first_peak.tide) | Highest number and first line number in case of a tie. |
| [Maximum](apps/maximum.tide) | Highest number, even with exclusively negative values. |
| [Light](apps/light.tide) | Motion turns on, two consecutive idle messages turn off. |
| [Pump](apps/pump.tide) | Start under 20, stop over 80, state preserved on equality. |
| [Temperature Alarm](apps/heat.tide) | Reports per event whether the last three temperatures were all above 80. |
| [Booking Balance](apps/balance.tide) | Folds a booking list over an initial balance and detects i64 overflow. |

## Programming with a Model

For an unknown error location, TIDE retrieves reachable function and rule bodies from the public entry point, including their filenames, type declarations, and the observed error. The model may return multiple changes at once. [Repair across module boundaries](workbench/README.md#find-errors-across-multiple-files)

For nested expressions, there is a view showing the compiler-determined bracketing. Changes to multiple functions can be checked as common candidate copies via their names. [Repair grouped function bodies](workbench/README.md#repair-grouped-function-bodies)

For small changes, a model answer per function can specify the affected text excerpt and its replacement. The workbench searches the grouped body and verifies that the location is unique. [Replace excerpt](workbench/README.md#replace-an-excerpt-in-the-function-body)

For rankings over multiple integer keys, the TIDE module `ordering` provides the functions `prefer_min` and `prefer_max`. A prepared repair view can additionally display the signatures of integrated, previously unused functions. [Prioritized comparisons](LANGUAGE.md#comparing-keys-with-different-priorities) · [Available functions in the repair context](workbench/README.md#show-further-available-functions)

For a single function, TIDE can cut out the task from the source file. The model delivers the new function body in a response. TIDE checks it against types, examples, and the stored revision. [Call and example](workbench/README.md)

1. `tide describe` provides type notation, program structure, and available operations. With `tide describe OP`, a single operation can be looked up.
2. `tide check FILE` checks the entire program, including imported modules, and outputs revision, signatures, calls, side effects, and possible catchable errors.
3. `tide context FILE --function NAME` shows direct and indirect callers, affected examples, and the nodes of the function. `--node ID` restricts the view to a location and shows its local bindings and bracketing.
4. `tide hole FILE --function NAME --node ID` provides the required type, available values, and an edit draft for a planned replacement. The model inserts a complete expression.
5. `tide edit FILE --base REV --edits JSON` checks changes to nodes of the entry file and imported modules jointly. With `--source CANDIDATE`, you can provide the complete entry file. Add `--write` to commit all checked files together. TIDE project commands see one revision and recover an interrupted edit on the next open.
6. `tide trace FILE --example NAME --step N` makes the branch and field changes visible for the specified event. `tide fmt FILE` outputs formatted source code.

With `./tide test FILE --explain`, an agent also receives the input and the definitions reachable from its entry point upon the first failed example. For functions, the finding includes the parenthesized function body and its node identifier. This allows the agent to immediately verify a corrected body against the same revision using `edit --edits`. [Example and blind comparison with Python](experimente/38_fehlerkontext/report.md)

For many possible call paths, `./tide test FILE --explain=executed` shows which definitions and branches the faulty example actually executed. In the tariff example, a package of exactly 500 grams reaches the expensive tariff. The finding includes three of the ten reachable functions for this. In contrast, for the rounding task, the entire call path runs, and the additional branch information enlarges the finding. [Inputs and measurements](experimente/42_ausgefuehrte_zweige/report.md)

`./tide test FILE --diff --explain=nodes` augments the finding with editable operator positions, including types and form-compatible alternatives. The node identifiers and revision are passed directly to `tide edit --edits`. [Edit nodes](workbench/README.md#repair-a-node)

### Prepare a change

For long results, `--diff` provides the path and the two differing values. In the subsequent attempt, the last booking from 384 contains the balance 26. The example expects the value 27 at `/rows/383/balance`. The second command additionally provides the executed functions along with their node identifiers. Both calls end with status 1 when encountering the intentionally inserted error. [Measurements and comparison with CPython](experimente/46_ergebnisvergleich/report.md)

```sh
./tide test experimente/46_ergebnisvergleich/ledger/panel.tide --diff
./tide test experimente/46_ergebnisvergleich/ledger/panel.tide --diff --explain=executed
```

With 384 bookings in the journal, the optimized record reader reduced the time to the executed error finding from 22.54 to 17.75 ms. The prepared CPython comparison required 18.66 ms. For two small multi-file errors regarding equality and rounding, the static view already provided all involved functions. [Tool times, tokens, and acceptance cases](experimente/47_record_eingaben/report.md)

In the balance example, this call checks the type and local bindings at the beginning of the function body. The node numbers come from the currently read revision.

```sh
./tide context apps/balance.tide --function balance
./tide hole apps/balance.tide --function balance --node 2:1
```

For large example inputs, the model can first read the names and fingerprints of the affected contracts. Subsequently, it can display a contract with input and expectation. Both calls specify the project revision. An intervening change is thus detectable. [Output size of context views](experimente/33_beispielkontext/report.md) · [Query time for Unicode contracts](experimente/37_vertragsfingerabdruecke/report.md)

```sh
./tide context apps/balance.tide --function balance --example-index
./tide context apps/balance.tide --function balance --example movements --node 2:1
```

### Check and accept a change

The following example operates on a copy. It swaps the operands of the addition and retains the three confirmed balance examples. The first `edit` shows the new revision, the number of passed examples, and the proposed source. The second accepts it with the same base revision.

```sh
demo=$(mktemp -d)
cp apps/balance.tide "$demo/saldo.tide"
base=$(./tide check "$demo/saldo.tide" | jq -er .revision)
patch='[{"node":"2:38","replace":"+ entry total"}]'
./tide edit "$demo/saldo.tide" --base "$base" --edits "$patch"
./tide edit "$demo/saldo.tide" --base "$base" --edits "$patch" --write
```

An outdated revision yields `E_REVISION`. Changes or deletions of existing examples are shown by TIDE with `E_CONTRACT`. If the changed expectation is technically intended, `--change-examples` allows the subsequent check. New examples are immediately checked. A change order can contain up to 256 positions of the same revision. For an operator, for example, `{"node":"2:38","op":"+"}` suffices as an entry. [Cross-file search and preview](workbench/README.md#check-two-files-together)

## Installation and verification

`make native` builds the native compiler. `make test` (also `make check-native`) checks the self-build and runs TIDE-tests for the compiler, the editor logic, and the game. The public starter can be installed under Linux x86-64 with Make.

With `make check-no-python` you can check independence on Linux x86-64 with Docker and BuildKit. The run builds TIDE in Debian without Python from sources, runs the native test suite, and compares an updated old installation with a new installation. It checks the static binding of all six tools and runs the balance program via the checkout and the installed package. The separate runtime image also checks version binding, catalog, modules, formatting, execution, and state trace. An intentionally incorrect minus in the balance program triggers an error finding. After repair by the native editor, the source file must again match the original and all three examples must pass. Build, tests, and execution run after acquiring system packages without network access. [Build recipe](native/bootstrap/no-python.Dockerfile)

```sh
make install PREFIX="$HOME/.local"
```

The installed command `tide build` uses the bundled compiler. On the target system it requires a POSIX-shell, Unix file tools, and `xxd`. Make and the C++20-compiler are used during package build. To create a package, the installation supports `DESTDIR`.

`make install` and `make install-native` deliver exclusively native tools and their data into a fresh prefix. An unported call reports `E_BACKEND` there. When switching from the compatibility installation, the installation target removes the previous starter, the eleven delivered Python modules, and their bytecode from the package directory. Own additional modules remain preserved.

The [checked new setup without Python](experimente/35_native_knotenaenderungen/report.md) includes self-build, tests, package change, and source changes. The [inspection check](experimente/32_native_inspektion/report.md) additionally documents the outputs of `context` and `hole`. The former interpreter, its integration checks, and the then interactive hosts are archived as [historical comparison base](experimente/referenzsystem/README.md).

The [language reference](LANGUAGE.md) describes syntax, types, rights, budgets, and errors. The [design history](SPEC.md) and the [self-experiments](experimente/findings.md) document the previous design decisions. The original checksum-bound write attempts are [archived](experimente/versuche_vor_umbenennung.tar.gz).
