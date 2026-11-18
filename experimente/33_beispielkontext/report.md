# Example contracts in the repair context

A `tide context` for a contract with 4,096 integers took 92.62 ms first on the same machine and 28.35 ms after the change. For the small balance program, the medians were 6.43 and 6.20 ms. The full responses of both native versions were byte-identical in all eight runtime comparisons. [Individual measurements and checksums](pruefung.json)

## Where the time was spent

A separate TIDE measurement function read the 86,094 byte project from stdin and terminated after each selected phase. The times include process start and are cumulative. Before the change, project validation took 14.94 ms, with canonical contract 15.21 ms, and with its SHA-256 86.21 ms. An instrumented run counted 946,880 calls of the UND operation built from TIDE arithmetic. After the change, the three medians were 5,32, 5,54, and 22.76 ms.

The JSON-reader processes elements of flat lists in groups. The SHA-256 core holds its eight working words in named fields and uses the same table for bitwise conjunction across all contracts of a query. In the precheck with 4-, 6-, and 8-bit tables, the 6-bit variant ran fastest for the large contract (27.15 ms at direct tool entry). The small balance query required 0.93 ms with 4 bits and 1.10 ms with 6 bits. In the bootstrap, rare diagnostic paths for arithmetic and indexed access are held out separately from successful computation. [JSON-reader](../../native/bootstrap/scalar_json.tide) · [SHA-256 in TIDE](../../native/bootstrap/sha256.tide) · [Bootstrap](../../native/bootstrap/seed.tide)

## Costs of the full query

Each invocation started a new process. On a AMD Ryzen 9 9950X3D under Linux, the measurement process and children were bound to a single logical core. After three warm-up rounds, 15 rounds followed with rotating order. The reference ran the same TIDE program with the archived interpreter under CPython 3.14.10.

| Task | Native before | Native now | Historical TIDE reference |
|---|---:|---:|---:|
| Balance, context | 6.43 ms | 6.20 ms | 29.15 ms |
| Light, a node | 6.50 ms | 6.29 ms | 29.24 ms |
| Bindings in imported function | 6.25 ms | 6.22 ms | 29.46 ms |
| Large example contract | 92.62 ms | 28.35 ms | 30.14 ms |
| Large and short example contract | 92.75 ms | 28.90 ms | 30.24 ms |
| Expression with 4,096 operands | 29.14 ms | 28.64 ms | 43.38 ms |
| Call chain with 48 definitions | 6.75 ms | 6.74 ms | 29.84 ms |
| Run large contract as test | 19.88 ms | 10.03 ms | 29.72 ms |

## How much context arrives at the model

`--example-index` provides names, target, and SHA-256 of the affected examples. With `--example NAME`, the model can read an input along with an expectation. The checker loads the entire project version in this case. For a single selection, it computes the fingerprint only for the selected example. For multiple queries, the project revision can be compared. [Usage and balance example](../../README.md#prepare-a-change)

Counted was the full UTF-8 standard output including line endings with `o200k_base`. The times refer to single invocations with 15 measurement values each. Medians are in parentheses.

| Project | Full | Index | A named example |
|---|---:|---:|---:|
| Large and short contract | 33,090 tokens (28.81 ms) | 304 (27.50 ms) | 266 (10.04 ms, `short`) |
| Balance | 487 (6.20 ms) | 428 (6.21 ms) | 344 (6.13 ms, `movements`) |
| Imported function | 543 (6.47 ms) | 451 (6.44 ms) | 318 (6.32 ms, `update`) |
| Light | 533 (6.30 ms) | 493 (6.30 ms) | 403 (6.22 ms, `restart`) |

In a large project, fetching the index first and then the short contract yields a total of 570 tokens. The sum of the two individual medians is 37.54 ms, while a full query takes 28.81 ms. Under the balance cost, the same two steps consume 772 tokens compared to 487 for the full output. The decision depends on whether the name is already known and what inputs the model actually requires. Total tokens of a model run and time until successful repair were not collected in this measurement.

## Acceptance without Python

In an empty build directory, self-build, tests, and installation ran without Python, experiment archive, or network. Five native tools were rebuilt. The twelve application files for six programs matched the stored ELF checksums. The package starter provided both index and individual selection. Nano and Space Invaders passed their state checks. Interactive terminal operation and revision-bound writing with `edit` remain open.

The comparison check included 595 previous inspection queries, eight boundary queries, 975 function, list, rule, and trace checks, 218 new views, 45 diagnoses, 26 independently computed contract fingerprints, and 83 JSON list inputs. All 1,950 results met their respective expectations. For full standard views, the historical TIDE output served as comparison. For the 83 list inputs, status, stdout, and stderr were compared byte-by-byte with the native predecessor. Additional 15 arithmetic and index cases passed with GCC and Clang, each with UndefinedBehaviorSanitizer enabled. [Permanent TIDE checks](../../native/bootstrap/inspection_checks.tide) · [JSON boundary cases in TIDE](../../native/bootstrap/checks.tide)
