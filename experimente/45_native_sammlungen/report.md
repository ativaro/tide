# Native collections in the full game

The public project entry of the previous package reported `E_BACKEND` for the unchanged Space Invaders. Now `tide test apps/space_invaders.tide` runs all ten examples. With `apps/invaders_checks.tide` as the entry point, an eleventh test for movement, shooting, pause, and continuation is added. `run` can output the full state with 21 enemies and three shields, advance via `tick`, and convert to a list of screen characters via `draw`. Native terminal support for `play` is open. [Game](../../apps/space_invaders.tide) · [Test program](../../apps/invaders_checks.tide)

## Runtime of CLI

| Full call | Before extension | First runnable prototype | Optimized version |
|---|---:|---:|---:|
| Check ten game examples | E_BACKEND | 21.25 ms | 20.51 ms |
| Generate start screen from passed game world | – | 21.02 ms | 20.01 ms |
| Read and count list with 512 records | – | 29.49 ms | 10.28 ms |
| Read and count list with 4,096 records | – | 227.94 ms | 42.25 ms |
| Read last of 4,096 records from a record field | – | 234.09 ms | 45.16 ms |
| Balance over 4,096 transactions | 7.85 ms | 7.75 ms | 7.84 ms |
| Read two fields of a flat record over 4,096 iterations | 19.32 ms | 20.42 ms | 20.17 ms |

Structured JSON-arrays are indexed during validation. The typed reader uses the existing entries. Short numbers are terminated at the first delimiter. For the large list, time decreased by a factor of 5.39 compared to the first working prototype. For projection from the flat record, the current call cost 0.86 ms more than the package before the extension. Times include process start, project precheck, JSON processing, calculation, and output. Each cell is the median of 21 serial calls after three warm-up rounds on core 2 of a Ryzen 9 9950X3D. Start order varied. [Individual measurements, inputs, and binary checksums](messung.json)

## Costs of the repair context

On error in the imported game module, `battle` set the phase to `paused` after a survived hit. Example `surviving_hit` expected `respawn`. All other fields of the resulting world matched. Both views delivered the four required record declarations including element types for enemies and shields. Using the node identifier from `context`, the incorrect `tag` could be specifically replaced via the project entry. After the change, the game module matched the original byte-for-byte and all ten tests passed.

| Error | Statically reachable context | Executed context | Prepared Python context |
|---|---:|---:|---:|
| Tie | 277 tokens · 5.94 ms | 272 tokens · 5.95 ms | 310 tokens · 16.69 ms |
| Rounding | 293 tokens · 6.11 ms | 315 tokens · 6.19 ms | 315 tokens · 16.24 ms |
| Wrong game state | 2,695 tokens · 22.21 ms | 2,616 tokens · 23.36 ms | – |

During the game, the number of function bodies shrinks from 26 to 18. The additional branch information allows a saving of 79 tokens. For rounding, the static TIDE view yields the shortest result. The static CPython answers for tie and rounding were re-collected using the same two projects, inputs, and external context tool as in the previous variant experiment. Domain results and inputs were checked in each run. The game measurement compares the two TIDE views. Counted was the complete tool response including line endings with `o200k_base`. Total tokens and time until repair by a model would require separate blind runs. [Comparison sources](../44_native_varianten/messung.json) · [Current findings and individual times](messung.json)

## Limits and example contracts

- A separate run over the installed CLI checked all six game phases, the matching banners, the return after a hit, and the restart after victory and defeat.
- Lists with 4,096 Records can be read and indexed. 4,097 Input elements yield `E_INPUT`. A `append` on a full list yields `E_LIMIT`. A TIDE-test stresses the guest with 4,096 changes of nested records each 1,024 bytes in size. Exactly 4 MiB are allowed. Another change is rejected. [Boundary test](../../native/bootstrap/checks.tide)
- A confirmed example retains its contract fingerprint if only the order of record fields or the JSON-writing of a Unicode character changes in an array. Reordering list elements or another field value changes the fingerprint. The native editor requires an explicit contract change for this. [Regression test](../../native/bootstrap/inspection_checks.tide)
- `make test` and the complete Linux-x86-64 rebuild with `make check-no-python` passed. The installed package checks the game examples and draws the start screen in a separate runtime image without Python. Python was called exclusively in the external comparison for equality and rounding. [Container check](../../native/bootstrap/no-python.Dockerfile)
