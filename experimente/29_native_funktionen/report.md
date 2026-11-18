# Check and execute TIDE functions without Python

The unchanged library `lib/ordering.tide` passes its eight examples in the native standard package. A call to `prefer_min` with two identical values and `on_equal=true` yields `true`. The previous native baseline reported `E_BACKEND` for this library. [Library](../../lib/ordering.tide) · [Test Plan](experiment-plan.md)

## What is Executable

Function parameters and results can be i64 or boolean. The checker knows literals, variables, local bindings, conditions, comparisons, checked arithmetic, and calls to other functions. Call targets can be further down or in an imported module. Recursion, incorrect argument types, and too deeply nested expressions yield localized diagnoses. `check` names the directly called functions and the transitively possible errors. `run` and `test` use the same checked expression tree. An impermissible operand in a non-selected branch is already detected during type checking. A valid division by zero in a non-selected branch is skipped at call time. [Function Check](../../native/bootstrap/functions.tide) · [Evaluation](../../native/bootstrap/function_run.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" check lib/ordering.tide
"$tool" test lib/ordering.tide
"$tool" run lib/ordering.tide --call prefer_min --inputs '{"candidate":7,"current":7,"on_equal":true}'
"$tool" run native/bootstrap/fixtures/functions/report.tide
```

The last three outputs are `{"passed":8}`, `true`, and `3`. The last program calls a function from a second module. Its six examples check, among other things, the held-out overflow in an inactive branch and the expected diagnosis of a division by zero. [Example Project](../../native/bootstrap/fixtures/functions/report.tide)

## Correctness

533 Comparisons on 316 different entry paths matched the direct reference starter. Among these were 334 calls to `run`, 67 from `check`, and each 66 from `test` and `fmt`. Both sides received the same source files and arguments. Compared were exit status, output channel, and complete JSON. Integers were compared in full precision. For `fmt`, the actual bytes were counted. The native installation ran for the comparisons in its own mount namespace without Python. [Test Protocol](pruefung.json)

- The TIDE generator produces, among other things, all 245 combinations of five arithmetic operations and two operands with seven values each, including both i64 limits. Further cases cover short-circuiting, order of argument evaluation, scope of `let`, call cycles, duplicate JSON keys, invalid example values, and errors in an imported file. [Case Generator](../../native/bootstrap/function_cases.tide)
- Four generated programs require computationally 99.999, 100.000, 100.001, or 100,002 visited expressions. The first two yield `0`. The others yield at the same location as the reference `E_LIMIT`, in the first case at line 2, column 43, in the second at line 5, column 1. The cases with 100,000 and 100,001 steps also run on every `make test`.
- The previous type corpus passed all 510 comparisons and 96 formatting repetitions again. For 73 additional projects, 216 calls matched the reference immediately. Three calls of a project with an unported Record operation reported `E_BACKEND` as expected. For 48 project entries, import sites and revisions matched, and for 1,741 function bodies over 42 inputs, the grouped view matched.
- The rebuild in an empty directory without Python generated five byte-identical tool files compared to the regular build, as well as twelve application ELFs with the previous checksums. The native test suite and separately all 35 historical integration tests passed. UBSan ran the checker including the 100,000-step probe with its normal process limits. For the additionally ASan-instrumented bootstrap test, the address space limit was lifted exclusively in the diagnostic image. ASan requires a larger virtual address space.

## Runtime of the full command

Three warm-up pairs per task, then varying start order. The first four tasks and the compatibility call each received 20 measurement pairs, and the three subsequently added load cases each received nine. Times are medians. The factor is the median of the reference time divided by the native time per pair. Both starters check and process TIDE source text. The experiment measures tool time, including process start. [Individual values and checksums ](messung.json)

| Task | TIDE | Python reference starter | Factor |
|---|---:|---:|---:|
| Check ranking library | 7.03 ms | 31.21 ms | 4.57× |
| Run eight library examples | 6.19 ms | 31.40 ms | 5.04× |
| Evaluate individual equality with named inputs | 6.07 ms | 31.14 ms | 5.16× |
| Six examples over two modules | 6.30 ms | 31.23 ms | 4.99× |
| Repeated parameterless calls up to the work limit | 5.36 ms | 79.03 ms | 14.76× |
| Partially recurring arguments | 8.39 ms | 66.76 ms | 7.99× |
| Exclusively new arguments | 114.25 ms | 66.68 ms | 0.59× |
| Balance over the compatibility package | 37.66 ms | 30.74 ms | 0.82× |

Before the optimizations, the three load cases with the same sources needed 292.74 ms (parameterless), 762.96 ms (partially recurring arguments), and 735.87 ms (exclusively new arguments). The first execution stored intermediate states for each individual operand. Now it can evaluate literals and local variables directly at the call site. The start compiler shares unchanged list buffers and copies them when changing. A checked access to an existing list can read an element directly. The evaluator caches results of pure functions for the same argument set. It loads the work budget with the actually observed node count on a hit. If the remaining budget is not sufficient, it executes the call and finds the exact error location.

The first cache version required more than two seconds in the test with exclusively new arguments. The current version limits caching after repeated failures and requires around 114 ms for the same load case. The Python reference remains faster here. The additional start of the reference for still unported commands is also measurable. Token consumption and repair time of a programming model were not collected in this measurement.

## Limits

The native function path reads JSON objects with simple unmasked identifier keys. Example descriptions with more complex strings or JSON forms may require the compatibility path. The JSON scanner currently processes up to 4,096 code points per input. Execution with lists, options, text, records, variants, state rules, or file permissions, revision-bound editing, as well as the interactive operation of Nano and Space Invaders still require the reference. The ELF compiler for selected list folds and state rules is available via `tide build`. [Status of replacement](../../tasks/todo.md)
