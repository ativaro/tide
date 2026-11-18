# How much time does reading a list of pairs cost?

For 256 couples, the same TIDE call required so far 13,07ms and after the change 9,98ms. The direct CPython program required 10,04ms. The median 50 percent was at TIDE between 9.72 and 10,27ms and at CPython between 9.79 and 10,22ms. At this value, the measurement results in a practical tie. For 640 couples, CPython remained much faster. [Raw data of all measurement series](messung.json)

| Pairs in input | TIDE previously | TIDE now | CPython | Output tokens per tool |
|---:|---:|---:|---:|---:|
| 1 | 7.60 ms | 6.02 ms | 10.09 ms | 3 |
| 64 | 9.11 ms | 7.09 ms | 9.97 ms | 129 |
| 256 | 13.07 ms | 9.98 ms | 10.04 ms | 513 |
| 640 | 20.95 ms | 16.12 ms | 10.41 ms | 1,281 |

Both programs receive the same JSON-list from Cursor and status and return all cursor positions. TIDE loads the project including types and examples. The standalone CPython program contains prechecks for field names, base types, status names, and i64 limits of this input format. The table shows complete CLI calls including process start and output. For comparisons with CPython, valid inputs were used. [TIDE function](../../native/bootstrap/fixtures/functions/composite_pairs.tide) · [CPython version and input generator](messung.json)

## What the control programs show

In the previous native checker, for 640 pairs, function `length entries` took 11.63 ms. Function `positions` required 14.26 ms on the same prepared project. The call via the full package starter cost 17.19 ms for the length query. Thus, the costs of input processing and startup could also be observed without outputting a long list.

A second control read the same input via stdin at each process start. For 2,000 pairs, reading alone with return of text length took 1.12 ms, finding the outer JSON sections took 3.11 ms, and full syntactic processing took 19.63 ms. The typed binding with return of list length required a total of 33.22 ms. These numbers are cumulative measurements of separately started processes. [Control source code, call variants, and individual times](messung.json)

## What has changed

The typed reader determines, before the first line, how to read both components of a list of pairs. Base values and variants each require a JSON event. A record with base value fields also has a fixed event count. Fields may appear in any order. Each pair is checked for form, field values, and variant names. For components with variable structure, the general reader remains responsible. In case of an error, TIDE now knows the index and start position of the affected line and can begin the precise field diagnosis there. [Typed Reader](../../native/bootstrap/compound_json.tide) · [Input Diagnosis](../../native/bootstrap/samples.tide)

A profile showed numerous constructions and copies of texts. The Bootstrap compiler now generates an immutable value for a text literal that its usage sites read in common. The value is created at first use. At `first` and `second`, the compiler can directly read a component of a still-live value. Temporary results retain the previous value transfer. Tests check, among other things, nested pairs, the lifetime of a temporary result, embedded NUL characters, and the independence of an older list state after `append`. [Compiler](../../native/bootstrap/seed.tide) · [Regression Tests](../../native/bootstrap/compiler_checks.tide)

For 2,000 valid pairs, a dedicated measurement series for length queries yielded 39.35 ms in the previous package, 35.26 ms with the pair reader, 32.45 ms with direct component access, and 29.49 ms with shared literals. The four packages of this series used the same previous starter. A trial with compiler level `-O2` brought an additional 0.24 ms at 256 positions. A local build of the checker thus took 20.38 s compared to 12.93 s with `-O1`. For this cycle, the existing build setting remained unchanged. [Intermediate Measurements and Compiler Comparison](messung.json)

The package starter outputs finished results from `run`, `test`, `trace`, `fmt`, and `edit` directly to stdout. The native process checks the writing including flush. For metadata with revision hash, the starter continues to use a snapshot. An intermediate draft collected the result text in the shell. At 1,792,003 output bytes, it required 155.64 ms, direct output 134.94 ms, and the original package 147.08 ms. A full output file yields status 1, while an already closed pipe reader yields status 141 as before. [Package Starter](../../tide) · [Output Tests in Isolated Package](../../native/bootstrap/no-python.Dockerfile)

## Diagnoses and Acceptance

| Tool Order | TIDE previously | TIDE now | Output tokens before and after |
|---|---:|---:|---:|
| 2,000 valid pairs bind and count | 40.96 ms | 29.31 ms | 3 |
| Unknown status in the last of 2,000 pairs | 44.87 ms | 29.58 ms | 60 |
| Ten Nano examples | 13.45 ms | 11.13 ms | 5 |
| Eleven Space Invaders examples | 29.36 ms | 25.45 ms | 5 |
| Three Balance examples | 6.63 ms | 5.17 ms | 5 |

The error finding at the last status is byte-identical and refers to `/entries/1999/1`. Over twelve pair forms, 434 comparisons between packages were executed. Among these were swapped field orders, Unicode, invalid target values, incorrect field types, missing components, lists at the boundary of 4,096 values and combinations for which both packages use the general reader. Further 55 CLI comparisons concerned, among other things, project lock files, file errors, unusual path names, context, formatting, and a revision-bound change. For output errors, return status and error channel were checked separately. [Permanent TIDE reader tests](../../native/bootstrap/checks.tide) · [Protocol and checksums](messung.json)

`make test` and `make check-no-python` passed with the final source state. A targeted compiler test program passed UBSan with the regular process limit. For the same single check with ASan and UBSan, the virtual address space limit was raised in the instrumented test image so that ASan could reserve its shadow storage. The installed programs use the regular limit.

The tables report per variant the median from 21 serial calls after three warm-up rounds on core 2. The order of tasks and tools changed. The separate row for large outputs comprises eleven measurements after two warm-up rounds. `o200k_base` counts the complete tool response including line endings. Total tokens of a model and time until a self-found repair were not measured in this cycle. [Computers, sources, quartiles and raw times](messung.json)
