# Lists in the TIDE standard package

The installed tool executes Balance, Heating Degree Hours, and Carton Balance via `tide run`. The three unchanged applications yield the values `97`, `39`, and `2` upon calling `main`. Their 14 examples pass. The previous native package status reported `E_BACKEND` for `tide run apps/balance.tide`. [Balance](../../apps/balance.tide) · [Heating Degree Hours](../../apps/heating.tide) · [Carton Balance](../../apps/cartons.tide)

## Supported Programs

Functions can accept and return lists of integers and booleans. `list`, `length`, `append`, and `fold` are implemented in the type checker and evaluator. Position binding in a fold starts at one. Folding an empty list evaluates the start expression. Changing the list in the accumulator preserves the original input. The additional test suite combines function calls across a module boundary, nested folds, and lists as results. [Test program](../../native/bootstrap/fixtures/functions/lists.tide) · [Imported function](../../native/bootstrap/fixtures/functions/list_ops.tide)

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
"$tool" run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
"$tool" test apps/heating.tide
"$tool" test native/bootstrap/fixtures/functions/lists.tide
```

## Acceptance test

The rebuild on Linux x86-64 began with an empty build directory in a mount namespace. The included build tools comprised GNU Make and the C++20 system compiler. The reference starter, Python interpreter, and Python libraries were hidden. The native test suite, installation, and twelve SHA-256 comparisons for newly built applications passed. The historical reference was started only outside this environment for comparison runs.

176 calls for lists and 466 re-comparisons for previously supported functions yielded no deviation. In the comparison, the process status, output channels, the complete JSON including i64 values and error positions, and the text output of `fmt` are counted. Edge cases include 4,096 and 4,097 JSON-element lists, list literals with 4,096 elements on one or multiple lines, an invalid binding, an overflow in an imported function body, and a work or memory reserve exhausted only during the fold. For the last case, there are permanent TIDE checks. Two nested folds perform exactly 100,000 and 100,001 expression evaluations respectively. In the case of repeated calls to a list-building function with 511 input elements, the one with 512 reports `E_LIMIT`. [Native acceptance tests](../../native/bootstrap/checks.tide) · [Results of the differential comparison](pruefung.json)

## Runtime

After three warm-up pairs, 20 pairs of separate CLI calls were measured. The table shows the medians. The start order alternated from pair to pair. Both tools read the same TIDE program and the same JSON data. The measurement captures process start, project check, evaluation, and output.

| Task | Native TIDE tool | TIDE reference interpreter in Python |
|---|---:|---:|
| Balance with empty booking list | 6.21 ms | 30.38 ms |
| Balance with 16 bookings | 6.08 ms | 31.41 ms |
| Balance with 4,096 bookings | 19.55 ms | 35.20 ms |
| All three balance examples | 6.06 ms | 30.98 ms |
| Seven list examples | 6.52 ms | 31.24 ms |

An idiomatic Python application, LLM tokens, and the time of a model repair were not measured in this series. [Individual measurements](laufzeiten.json)

## Open Python paths

The checkout and explicit compatibility installation continue to use the historical interpreter for additional data types and operations, general state rules, file permissions, interactive `play` and edit commands. The native standard package reports `E_BACKEND` there. The native JSON reader covers the tested integer and boolean lists. More complex JSON forms and individual syntax diagnostics still require the reference. [Development status](../../tasks/todo.md)
