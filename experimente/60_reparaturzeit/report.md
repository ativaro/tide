# Repair time with public counterexample

TIDE Fixed the new multi-file errors in the paired median **2,34It's so fast** Like python,AST. Both existed **84 from 96 Repair attempts ()87.5 %)** and consumed **0 Model tokens**. TIDE took less time in all 84 successful couples. The median paired savings were 49,8ms, with the median 50 % of the pairs between 37.5 and 51,4ms. [Raw data](messung.json)

| Time from start to acceptance or abort | TIDE Median / P95 | Python-AST Median / P95 | Attempts per procedure |
|---|---:|---:|---:|
| Total successful repairs | 38.1 / 41.4 ms | 88.8 / 94.2 ms | 84 |
| Successful with counterexample | 39.7 / 42.0 ms | 91.4 / 94.7 ms | 48 |
| Successful with immediate precheck | 26.4 / 28.2 ms | 63.6 / 67.1 ms | 36 |
| Abort without green candidate | 14.8 / 17.2 ms | 27.6 / 29.5 ms | 12 |
| All attempts | 33.1 / 41.4 ms | 77.2 / 94.2 ms | 96 |

## What both procedures did equally

The eight new projects consisted of three source files each. Each task had one to three public tests and 72 held-out tests. The first erroneous output was identical on both sides. In the executed functions, both checked the same integer operator swaps and the two small expression substitutions from trial 58, with at most 32 edits. The observed counts of tested and green candidates matched per pair. No search reached its upper limit. [Source Pairs](paarungen.json) · [Experiment Plan](versuchsplan.json)

For the counterexample search, both received the same ordered pool of valid inputs, generated from the values 1 to 4 for both parameters. Both stopped at the first input pair for which the green candidates produced error-free distinct values. An independent TIDE contract function confirmed the expected value without accessing candidate code or held-out test cases. Both supplemented the thus-confirmed public example and repeated the precheck. A unique candidate was saved in the project and accepted against all public and held-out cases. [Test cases and contract function](vertrag.tide) · [External Python-AST comparison](cpython_comparison.py)

| Task | Green candidates at start | Common counterexample and expected value | TIDE Median | Python-AST Median |
|---|---:|---|---:|---:|
| Boxes | 2 | `(1, 1) → 2`, 1. Sample | 39.1 ms | 89.7 ms |
| Balance | 2 | `(1, 1) → 0`, 1. Sample | 39.1 ms | 90.3 ms |
| Load limit | 2 | `(1, 2) → 7`, 2. Sample | 39.9 ms | 91.5 ms |
| Labels | 2 | `(1, 2) → 4`, 2. Sample | 40.1 ms | 92.9 ms |
| Conveyor belt | 1 | — | 26.6 ms | 63.9 ms |
| Drums | 1 | — | 26.1 ms | 63.4 ms |
| Color rollers | 1 | — | 26.8 ms | 63.5 ms |
| Dual counter | 0 | — | 14.8 ms | 27.6 ms |

All twelve runs per procedure for the dual counter failed. The single-edit search checked 16 candidates and found none that passed all public tests. The separate control with both corrections in `route.tide` and `rulebook.tide` passed 75 of 75 tests.

## Time limits

The monotonic wall clock started before generating the input pool. The measurement includes diagnosis, precheck, counterexample search, confirmation, supplemented public example, repeated precheck, patch with public test, and independent acceptance. Build, installation, prepared source copies, and generation of the original test cases were completed before start. The held-out cases were available to the repair process only after writing the patch.

| Phase with counterexample | TIDE Median | Python-AST Median |
|---|---:|---:|
| Generate common input pool | 8.7 ms | 8.8 ms |
| First error, precheck, and counterexample search | 5.7 ms | 18.6 ms |
| Confirm expected value and supplement public example | 7.7 ms | 8.0 ms |
| Repeat public precheck | 5.6 ms | 18.5 ms |
| Check and write patch | 5.4 ms | 19.1 ms |
| Independent acceptance | 6.3 ms | 17.8 ms |

The search is part of the same call as the first precheck. Phase medians are calculated individually. For each task, twelve measured pairs in varying start order followed a discarded trial run. Each run used a fresh project copy, and both methods started a fresh command-line process per phase. CPython used `-I -B -S`, compiled candidates in memory, and did not start a process per candidate during the precheck. Measurements were taken sequentially on CPU 24 of a Ryzen 9 9950X3D with warm system caches, TIDE 0.6.1 from an installed package, and CPython 3.14.10. The host's network interfaces were inaccessible for the runs. There was no model request.

The time factor applies to this command-line run on eight small projects with executable contracts. Repetitions measure time spread, while the success rate corresponds to seven out of eight different errors. A continuously running process and the duration of human acceptance were outside the experiment.
