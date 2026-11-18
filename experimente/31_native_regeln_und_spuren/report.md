# State rules and event traces without Python

The installed TIDE tool checks the unchanged rules for light, pump, and heat alarm and executes them via the normal project entry. All eight application examples pass. The previous native package status reported `E_BACKEND` for the trace call at the light. [Light rule](../../apps/light.tide) · [Rule checker](../../native/bootstrap/rules.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" test apps/light.tide
"$tool" run apps/light.tide --call simulate --inputs '{"events":[true,false,false]}'
"$tool" trace apps/light.tide --example restart --step 2 --fields missed,on
```

The second event of example `restart` is the first message without movement after switching on. The trace shows branch 2, for `missed` the action `set` with the transition from 0 to 1 and for `on` the action `keep` with the light on. The output remains `true`. The trace call evaluates only up to and including the requested event. Thus, even the last successful transition of a later failing example can be checked.

## Evaluation and acceptance

All actions of a selected branch read the state before the event. The output expression reads the updated fields. `reset` uses the start value evaluated once per rule run. `scan` can be called in further expressions and across module boundaries. Nested scans and other function calls share the working and memory reserve of the caller. In case of an error, the diagnosis carries the original source position and the event number of the innermost affected rule. [Evaluator](../../native/bootstrap/function_run.tide) · [Test program with imported start value and booking function](../../native/bootstrap/fixtures/rules/control.tide)

333 new CLI comparisons check among others 192 deterministically generated event sequences, 15 cases at the working limit, invalid rules, simultaneous changes of two fields, errors in nested scans, and field selection in trace queries. In addition, 176 list comparisons and 466 comparisons for the previously supported functions are included. Exit status, output channel, complete JSON values and diagnosis positions as well as the exact text of `fmt` were compared. For the 975 calls, there was no deviation between the isolated native package and the externally started reference. [Test results](pruefung.json)

On the new build under Linux x86-64, interpreters, Python libraries, and reference starters were hidden. The bootstrap self-comparison, the two native test suites, editor and game tests, and twelve comparisons of newly generated application ELF files with their stored SHA-256 values passed. The shared syntax functions of the start compiler and the project checker now reside in a separate module. Both tools remain under the source code limit of 128 KiB. [Build rules](../../Makefile) · [Shared syntax](../../native/bootstrap/syntax.tide) · [Permanent boundary tests](../../native/bootstrap/checks.tide)

## Measurement

All columns execute the same TIDE source code with the same input. Measured was the time from process start to complete output, including project checking and JSON processing. After two warm-up rounds, 15 measurement rounds followed on CPU 2 with rotating order of the three tools. The table shows medians in milliseconds. In the boolean measurement series, every third event starting from the second was true. In the integer measurement series, every eleventh value starting from the first was 18, all other values were 81.

| Call | First native version | Optimized native version | TIDE reference interpreter in Python |
|---|---:|---:|---:|
| Light trail for an event | 5.34 | 5.25 | 28.84 |
| Light, 4,096 events | 60.80 | 26.03 | 38.23 |
| Pump, 4,096 events | 42.56 | 25.67 | 40.33 |
| Heat alarm, 4,096 events | 49.49 | 34.21 | 44.55 |
| Return 4,096 boolean values unchanged | 36.16 | 10.43 | 30.41 |

The last case requires no state transitions. Its first measurement already showed how much time input and output of large lists can cost. The JSON reader now assembles normalized text in sections, and output writes groups of 128 values. For short rule expressions, the evaluator can compute the result directly from operands without setting up an additional evaluation frame. The work budget check applies there too. The measurement series captures the combined effect of these changes. [Individual measurements](laufzeiten.json)

Model tokens, time until error repair, and a standalone idiomatic CPython application were not measured in this series. Rules with additional input or output types, operations outside the native evaluator, general file permissions, and interactive hosts still require the reference.
