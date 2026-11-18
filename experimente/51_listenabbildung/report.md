# TIDE 0.6 · Mapping lists and locating errors

A list of pairs contains one cursor and one status each. All cursor positions in input order are sought. The previous solution forms a new logical list value at each `append`. At 723 positions, the sum of these values still fits into the guest budget. At 724, the same correct calculation breaks with `E_LIMIT`. In TIDE 0.6, `map` describes the calculation for an element. The result list is charged to the budget once.

```tide
map i entries item (get pos (first item))
```

With `o200k_base`, this expression has **11 tokens**. The previous expression `fold entries (list i 0) seen row item (append seen (get pos (first item)))` has **21 tokens**. The declared return type remains `*i`. [Example program](../../native/bootstrap/fixtures/functions/maps.tide)

## Runtime from process start to result

| Pairs | TIDE 0.5 with `fold` | First `map` version | TIDE 0.6 with `map` | CPython |
|---:|---:|---:|---:|---:|
| 1 | 6.17 ms | 5.93 ms | 6.03 ms | 9.57 ms |
| 256 | 9.71 ms | 9.38 ms | 8.99 ms | 9.82 ms |
| 640 | 15.32 ms | 14.48 ms | 13.67 ms | 10.08 ms |
| 723 | 16.67 ms | 15.55 ms | 14.46 ms | 10.18 ms |
| 724 | `E_LIMIT` | 15.41 ms | 14.44 ms | 10.22 ms |
| 1,024 | `E_LIMIT` | 19.71 ms | 18.42 ms | 10.65 ms |
| 3,000 | `E_LIMIT` | 47.43 ms | 43.04 ms | 12.98 ms |
| 4,095 | `E_LIMIT` | 58.64 ms | 52.21 ms | 13.49 ms |

Per cell, after three warm-up rounds, 21 serial calls were measured on the same CPU core. The order changed. The table indicates the medians. Both programs received the same JSON bytes and delivered the same full edition if successful. Each output was compared with independently generated setpoints. The TIDE call checks the project pin and loads the source file. The direct CPython program checks field names, status and i64 value range when entering. The entire CLI term was collected. [Input generator, CPython version, quartiles and raw times](messung.json)

In the first version, each hull ran through the ordinary evaluator. The second can run chains of `get`, `first` and `second` on composite elements in a run if the result is an integer or a truth value. With a tight budget, the usual evaluator takes over and determines the exact point of failure. Tests compare remaining work, remaining memory, and diagnosis on both execution pathways. Large lists remain significantly faster on this end-to-end job in CPython. [Evaluators](../../native/bootstrap/function_run.tide) · [Budget tests](../../native/bootstrap/checks.tide)

Short field values were used for 4,095 pairs. Already 4,096 of these couples need in the JSON call 131,085 input bytes. Therefore, the language border was checked separately. An TIDE program generated the typed pairs in memory from 4,096 numbers. The projection provided all the 4,096 expected positions. At 4.097, the public starter reported `E_INPUT` on the path `/xs/4096`. Another check mapped each of 4,096 numbers to the same unicode text. 251 characters per result fit into the budget, 252 yielded `E_LIMIT` on the last item with `map_index: 4095`.

## Two new errors for each of three files

The contracts for tie and rounding originate from the earlier blind comparison. For this tool measurement, the errors at that time were corrected first. In each language, there were seven public cases per task and 72 more. Subsequently, the same new error was inserted in the TIDE and Python versions. In the case of tie, the distance function evaluates a coordinate to the left of the origin by one too far away. In rounding, the reverse conversion of negative results cuts off half the step. The prepared results show for the first case nominal value 7 and actual value 13, for the second nominal value 90 and actual value 100. Each finding contains the three relevant functional definitions. [Contracts and Initial Attempt](../38_fehlerkontext/report.md)

| Tool and output | Same, tokens | Median | Rounding, tokens | Median |
|---|---:|---:|---:|---:|
| TIDE `test --explain` | 267 | 5,48ms | 261 | 5,39ms |
| TIDE `test --explain=executed` | 331 | 5,64ms | 303 | 5,47ms |
| CPython with prepared static context | 298 | 16,96ms | 288 | 16,88ms |

The token counts in the table include the actual tool output including line endings. Both TIDE views show all three functions at tie and rounding. The execution trace adds the visited branches and costs 64 or 42 tokens. The Python comparison aid reads the source files, analyzes their ASTs, runs the examples, and outputs JSON with spaces. After identical compact JSON serialization without line endings, static findings yield **267 versus 257 tokens** at tie and **261 versus 245** at rounding. The apparent token lead of TIDE in the raw answer here depends on formatting. The 21 repetitions per variant measure the provision of the finding. Model total tokens and time to self-found repair were not collected. [Both source versions, findings, and individual times](messung.json)

## Test in game and in package

Space Invaders now uses `map` when creating bunkers, when marching aliens, and when updating hit bunkers. The eleven game examples passed. For 128 game steps with movement, shooting, pause, and resume, all emitted game states were byte-identical to the previous version. Seven rendered scenes and 23 targeted calls for formation and bunker hits also matched. [Game rules](../../apps/invaders_game.tide)

The new function fixture consists with its imports 20 examples. 68 additional CLI prechecks covered among others typed gaps, revision-bound changes, source errors, error propagation, length, and the order of results. `make test` and `make check-no-python` passed. The package on Linux x86-64 was built from sources without Python and tested in the separate runtime image. `map` is available in the public project analyzer and in the bootstrap compiler. The standalone ELF exporter `tide build` continues to support its documented language subset. [Native build](../../native/README.md) · [Acceptance protocol](messung.json)
