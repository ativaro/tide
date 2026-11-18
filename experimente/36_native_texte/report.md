# TIDE without Python at Nano and the repair workbench

On 17 November 2026, the previous native installation for Nano's line search still delivered `E_BACKEND`. Now, all four cursor functions run as a separate TIDE module in the public project analyzer. Nano imports the same functions. The workbench can also detect via `tide run` whether a source line declares the sought function. [Cursor module](../../apps/cursor.tide) · [Workbench source text functions](../../workbench/source_layout.tide)

```sh
./tide run apps/cursor.tide --call line_limit --inputs '{"body":"🐈\r\nΩ","pos":0}'
./tide test apps/cursor.tide
./tide test native/bootstrap/fixtures/functions/text.tide
./tide test workbench/source_layout.tide
```

The first call yields `1`. The three tests report five, ten, and two passed examples. The checker knows texts as well as lists and options over integers, truth values, and texts. The character search counts Unicode code points. A search without hits yields an empty option. `need` can turn this into a data error with reason and input line. Nano's cursor treats CRLF as a line break. [Text examples](../../native/bootstrap/fixtures/functions/text.tide) · [Type checking](../../native/bootstrap/functions.tide) · [Evaluation](../../native/bootstrap/function_run.tide)

## Rebuild without Python

The Linux-x86-64 build started in an empty directory. A dedicated mount namespace contained the production TIDE sources, Make, system tools, and GCC 16.2.1. Interpreter, Python standard library, usable shared Python runtime, and experiment archive were hidden. Inside ran `make check-native` and an installation into a temporary prefix. The bootstrap requires a C++20 compiler.

All six installed tools were statically linked and byte-identical with an independently built second package. For six applications, all twelve stored ELF checksums matched. Checkout and installed tool calculated the balance `97`. During the upgrade, eleven old Python modules with their eleven bytecode files and the two previous starters disappeared. A foreign file in the old package directory remained. The archived reference is used exclusively for external comparisons. [Build rules](../../Makefile) · [Individual values and SHA-256 checksums](pruefung.json)

## Runtime

The time measured was from process start to its end on a AMD Ryzen 9 9950X3D, bound to the logical core 2. In the first series, the installed `tide run` and a standalone program ran under CPython 3.14.10 with `-I -S`. Both read the same JSON arguments and delivered the same result in each run. The order changed per task. The table shows the median from 21 runs after three warm-up rounds. For the balance, Python also checked every addition for i64 overflow. TIDE loaded and checked the program source at every start. Valid inputs were measured.

| Task | Input and Result | TIDE | CPython | Time CPython / TIDE |
|---|---|---:|---:|---:|
| End of line in Nano document | `🐈\r\nΩ`, from position 0 → 1 | 5.50 ms | 9.06 ms | 1.65× |
| Last occurrence | `a猫` 10,000 times, then `Z` → position 20,000 | 7.69 ms | 9.23 ms | 1.20× |
| Balance | Initial 0 and 4,096 bookings each of 1 → 4,096 | 6.42 ms | 9.29 ms | 1.45× |

The second series compared different states of the TIDE tool. For each state and task, there were nine measured calls after two warm-up rounds in varying order. The historical reference is the former TIDE interpreter on CPython. Its start and project precheck belong to the measured work here.

| Task | First state with text values | Optimized state | Historical TIDE reference |
|---|---:|---:|---:|
| Last occurrence under 20,001 characters | 18.11 ms | 7.69 ms | 29.25 ms |
| 100 characters from an input with 60,000 characters | 12.10 ms | 8.31 ms | 29.23 ms |
| Balance with 4,096 bookings | 14.05 ms | 6.47 ms | 33.35 ms |
| Context with large Unicode example | 72.34 ms | 68.89 ms | 29.18 ms |

The JSON binding handles contiguous text sections together. For simple numeric operations in a fold, the evaluator reads the typed operands directly. Thus, the large balance also decreased compared to the native state before text extension, from 11.55 to 6.47 ms. As a counter-check, the diagnoses and the work limit of 100,000 steps remained part of the tests.

In the large example contract, input and expected value each contained 7,000 repetitions of `🐈a`. For this context query, the native tool took 2.36 times as long as the historical TIDE reference. In twelve separately profiled calls, 55 % of the 0.29 seconds of measured CPU time were attributed to `sha_mask12` in SHA-256 processing. The individual runtimes and the full text of the standalone CPython comparison version are in the [measurement data](pruefung.json).

## Function check and limits

- 553 comparisons checked values, errors, types, node positions, local bindings, and example contracts. Further 77 cases checked, among others, folds, resource limits, erroneous inputs, and escape sequences. Both series matched the historical language reference. Persistent TIDE tests also check 4,096 and 4,097 text lines as well as both sides of the memory limit in concatenations. [Tests in TIDE](../../native/bootstrap/checks.tide)
- Of 1,041 node edits, 1,032 matched the historical editor. For nine complete folds, this fails with an internal error. For these nine, it was separately checked that the native candidate bytes exactly replace the expected source region. Additionally, there were 176 comparisons for changes of entire files.
- The 1,950 cases of the previous function, list, rule, and inspection series were re-executed. For a faulty JSON argument, the former native package reported a generic `E_BACKEND`. The new package reported `E_JSON` at character position 4106, as the historical language reference did. The remaining 82 cases in this group for array arguments retained the previous behavior.

Interactive startup of Nano and Space Invaders requires native keyboard, screen, and document operations. The installed command `tide play` reported `E_BACKEND` for this. Further open parts of the public evaluator are nested data forms, records, and variants as runtime values, as well as file read permissions. The text measurements concern the project call `tide run`. The repair time of an agent and its token consumption were not collected in this trial.
