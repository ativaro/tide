# Native TIDE compiler

The compiler reads TIDE source code and generates an executable ELF file for Linux on x86-64. The balance program outputs `97`. The heating degree hour program compares each temperature with 18, adds the difference for colder hours, and outputs `39`. [Balance](../apps/balance.tide) · [Heating degree days](../apps/heating.tide)

## Building without Python

```sh
./tide build apps/pump.tide /tmp/tide-pumpe simulate
/tmp/tide-pumpe 19 20 80 81
# [true,true,true,false]
make check-native
```

The first call builds the compiler under `build/native` from the TIDE sources. Subsequent calls use the same compiler. The optional last parameter selects the entry function; the default is `main`. The output file is atomically replaced upon successful translation. The native backend build expects a program from the already checked section described below. It performs no general project type checking and no embedded examples. For type declarations across multiple files, `tide check` and `tide test` check natively. `tide modules DATEI` outputs import locations and revision for all project types. [Module check](../experimente/28_native_module/report.md)

The native function checker supports i64, boolean values, text, and lists and options of these three types, arithmetic, comparisons, short-circuit logic, `if`, `let`, and functions called within the same or an imported module. `tide run` binds named JSON inputs. `tide test` runs the examples with the same evaluator. With `list`, `length`, `append`, and `fold`, among others, the unchanged programs for balance, heating degree hours, and carton balance are executable. A fold can use a list as an accumulator and call further folds. [Lists and resource limits](../experimente/30_native_listen/report.md)

With `map B liste element rumpf`, the project evaluator produces exactly one result value of type `B` per input element. An error in the function body includes the source location and the zero-based element index. The position query and Space Invaders use the operation for numbers and records. [Tool measurement and acceptance test](../experimente/51_listenabbildung/report.md)

For Unicode text, `concat`, `text_eq`, `text_len`, `text_slice`, `text_find`, `text_rfind`, `lines`, and `int` run via the public project entry point. `some`, `nil`, `case`, `need`, and `at` allow explicit handling of missing hits or invalid numbers. Nano's cursor functions and the detection of function heads in the repair workshop use these operations. [Measurements and scope](../experimente/36_native_texte/report.md)

Functions can also connect records, variants, and further pairs with `pair`. `first` and `second` provide the statically typed components. The example `peak_lines` uses `?&ii` for a maximum value along with the line number. Nano returns `&{Buffer}{Effect}` on every key press. A sequence of keys and storage feedback can be executed with `tide run apps/nano_checks.tide --call replay` and the named inputs `body` and `events`. [Base types](../experimente/39_native_paare/report.md) · [Nano and composite pairs](../experimente/49_zusammengesetzte_paare/report.md) · [Input throughput and error paths for long pair lists](../experimente/50_eingabedurchsatz/report.md)

Function signatures can use named records as well as lists and options of named records and variants. Record fields can also contain these types. `make` constructs a record, `get` reads a field, and `with` creates an updated value. The guest budget counts the total logical size of the result, even if the values internally share memory pages. The Space Invaders game world runs so, including enemies, shields, and optional bullets, via `tide run`. [Field operations](../experimente/43_native_records/report.md) · [Nested values and measurement](../experimente/45_native_sammlungen/report.md)

A variant type can be used as a parameter, result, and direct record field. `tag` creates the value, and `match` executes the selected branch. In an extended game phase, `tide check` lists the pending decisions in `draw` and `tick` together. [Tool measurement and game test](../experimente/44_native_varianten/report.md)

For rules with integer or boolean events and results, TIDE checks the initializations, all branches, and the output expression. `scan` also works for function calls and imported rules. Branch field actions read the state before the event. The output expression sees the already updated fields. `tide trace` shows this transition for a single example event and can limit the output to specified fields. [Precheck, State Limits, and Times](../experimente/31_native_regeln_und_spuren/report.md)

For the supported projects, `context` and `hole` also provide callers, example contracts, and local bindings from the native type checker. The previous executable comparison baseline is preserved in the [Experiment Archive](../experimente/referenzsystem/README.md). [Bootstrap, System Tools, and Python-less Precheck](bootstrap/README.md)

`catch` processes errors even from imported functions and rules. `fail` generates a technical reason, `input_line` reads the optional input line, `has_reason` checks the reason, and `raise` retrieves the diagnosis. An error in the replacement propagates to the next outer matching handler. Work and guest allocations are continued in the same budget. Boundary violations and errors when binding call arguments terminate the run. [Regression Cases](bootstrap/fixtures/functions/handlers.tide) · [Rule with Handler](bootstrap/fixtures/rules/handler.tide)

`run --read NAME=PFAD` checks the project and inputs before opening the regular file. `read` holds a snapshot per bound handle. The snapshots share a limit of 128 KiB. A read error after opening and invalid UTF-8 are catchable in the program. [Read Examples](bootstrap/fixtures/functions/read_grants.tide)

## Translate a program

`tide build --aot QUELLE AUSGABE [EINSTIEG]` translates the checked measurement report along with calls across module boundaries. The Linux-x86-64 build requires a C++20 compiler with static system libraries. The output file is statically linked and reads neither project sources nor tool files at startup. It uses `--read NAME=PFAD` and `--inputs JSON`. A new source state is adopted via a new build.

The AOT path currently covers the types and operations of the measurement report, including text folds, integer operations, optional integers, records with base fields, and named read permissions. AOT also translates SQLite cursors, write permissions, HTTPS calls, PostgreSQL queries, conditional loops, `map`, limited self-recursion, and state rules called via `scan`. `build --service` generates a HTTP listener for a typed handler. For language constructs outside the AOT coverage, the compiler reports `E_BACKEND`. The JSON importer compiles the target type and field accesses at build time. `run`, `test`, and the generated program use the same TIDE implementation for decoding, byte sequences, and dictionaries. [JSON-Measurement Report](../apps/report_packages/json_report.tide)

Execution computes executed nodes, data input, and guest memory like the project evaluator. Errors refer to the source files and nodes of the build. [Acceptance Test and Comparison against CPython](../experimente/53_vorabuebersetzung/report.md)

`tide build` without `--aot` uses the direct ELF exporter for the section described below.

```sh
set -euo pipefail
build=$(mktemp -d)
./tide check apps/heating.tide >/dev/null
./tide test apps/heating.tide
./tide build apps/heating.tide "$build/program"
readelf -lW "$build/program"
"$build/program"
```

The finished program has an executable, read-only load area and a stack marked as non-executable. Linux starts it directly.

## Varying inputs

A program entry with two parameters `i`, `*i` and result `i` receives the start value as the first argument. The further arguments form the list in input order. During the build, a named function can be selected as the entry point.

```sh
./tide build apps/heating.tide "$build/heating" degree_hours
"$build/heating" 3 20 18 12 17     # 10
"$build/heating" -7                # -7
```

Up to 4,096 list values are allowed. Each value is a ASCII-decimal number in the i64 range with an optional minus sign. Leading zeros are allowed. The binding first checks the number of arguments and then each value from left to right before folding begins. For `"$build/heating" 0 18 warm`, the standard output remains empty. On stderr, `{"code":"E_INPUT","reason":"expected_i64","argument":3}` appears, and the exit status is 1. The number counts the start value as position one. A missing start value results in `missing_seed`, and more than 4,096 list values result in `list_too_long`. The operating system limits for argument passing apply even before the program starts. [Binding in the native compiler](argv_i64.tide)

## Supported excerpt

### Execute state rules

Existing applications for heat alarm, pump, and light can be translated directly. The normal build produces a file that executes its `main` at startup with the embedded events. For varying values, the build selects the entry `simulate`. Each positional argument is an event, and the output is a JSON list in event order.

```sh
set -euo pipefail
build=$(mktemp -d)
./tide check apps/light.tide >/dev/null
./tide build apps/light.tide "$build/light" simulate
"$build/light" true false false true     # [true,true,false,true]
"$build/light"                          # []
```

The selected entry can `scan` directly or pass the event list once to a local function with `scan`. The rule is in the same source file. Events, state fields, and output can be `i` or `b`. Start values are literals. For conditions, `set`, and `out`, the same scalar operators as for folds are available. Up to 4,096 events are bound before execution. For `b`, the notations `true` and `false` apply.

The first matching branch wins. All actions read the old field values. Only after the subsequent state is fully computed does `out` read the new values. For multiple erroneous actions, the declaration order of the fields counts. A computation or budget error yields status 1 and the event number starting from one on stderr. The standard output remains empty even for a late rule error. [Transition compiler](rule_scan.tide) · [Native input and output](scan_image.tide) · [Differential tests and runtime comparison](../experimente/24_native_regeln/report.md)

### Execute integer folds

A prerequisite is a program checked with `tide check`. For embedded data, a parameterless `main > i` calls the preceding fold function with a start literal and a list of i64 literals. A parameterized entry folds itself or passes its two parameters in the same order to a fold function in the same file. The fold uses the list parameter and the start value parameter. The step can use start value, accumulator, position from one, current element, as well as integer and boolean literals. Supported are `+`, `-`, `*`, `div`, `mod`, `<`, `>`, `<=`, `>=`, `eq`, `if`, `not`, `and`, and `or` in nested expressions. At `if`, only the selected branch runs. `and` and `or` evaluate the second operand only if it can influence the result.

`div` rounds toward zero. The rest of `mod` has the sign of the dividend for a result different from zero. A divisor of zero results in `E_DATA` with reason `division_by_zero` for both operations. The smallest i64 divided by −1 yields `E_OVERFLOW`, its remainder at −1 yields zero. The carton balance uses both operations to round bookings and cancellations per order to whole cartons. [TIDE application](../apps/cartons.tide) · [Native checks and runtimes](../experimente/23_native_division/report.md)

Expressions can be distributed over multiple lines and bracketed according to the TIDE grammar. The native tokenizer supports up to 512 code points per expression line, spaces and tabs, and LF or CRLF. Execution is subject to TIDE's resource limits. For embedded data, the compiler checks an upper bound for evaluation steps. At a too high bound, it reports `native_work_bound`. For positional arguments, it checks the bound for the maximum allowed list length. If it can 100,000 exceed, the program counts the actually visited expression nodes at runtime. The first step above the boundary yields `E_LIMIT`. Appended examples are checked by `tide test`.

Source translation reads declarations and literals. The expression module translates prefix expressions with a typed stack and generates relative-addressed jumps for branches and loops. Every actually executed addition, subtraction, and multiplication checks for signed overflow. At an overflow, stdout remains empty, code goes to stderr `E_OVERFLOW`, and the process ends with status 1. The native error path currently contains no source position. The previous three direct accumulator operations continue to use their compact encoding. [Source translation](fold_i64.tide) · [Expression translation](scalar.tide) · [ELF output](elf64.tide)

## Verification

In the balance example, standard output and exit status matched the reference. The native file was 411 bytes in size. Ten additional executions compared empty list, subtraction, negative product, zero, both i64 limits, overflow of each of the three operations, and an early overflow before a compensating addition. The success cases matched byte-for-byte. All four overflow cases produced `E_OVERFLOW`, empty standard output, and status 1.

In the branched arithmetic core, 29 programs were compared against the reference interpreter. For heating degree hours, there are separate measurements for build, single call, and repeated execution. [Runtime measurement and individual results](../experimente/20_native_ausdruecke/report.md)

The test with varying arguments uses the same native file for differently long measurement series. It compares the input binding, error positions, and both sides of the working budget limit with the TIDE reference. [Runtime arguments and individual results](../experimente/21_native_eingaben/report.md)
