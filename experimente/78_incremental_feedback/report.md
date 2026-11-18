# Stage 9 · Time from a saved change to a green test

TIDE 0.6.10 returned the same results as a fresh full test for all 108 measured corrections and the failures that preceded them. In an already running process, selective checking reduced median time to green by **5.51× for a leaf change, 1.43× for an interface change and 5.57× for a package change**. The interface migration reran 11 examples that reach the order importer. [Raw timings, diagnostics and machine details](results.json)

| Change | Bodies checked out of 47 | Examples run out of 33 | Incremental median / P95 (ms) | Full session median / P95 (ms) | Fresh CLI median / P95 (ms) |
|---|---:|---:|---:|---:|---:|
| Cursor leaf implementation | 4 | 5 | 5.11 / 5.62 | 28.17 / 30.09 | 32.42 / 35.34 |
| Order identifier interface and callers | 6 | 11 | 22.29 / 24.39 | 31.94 / 35.37 | 37.07 / 48.33 |
| Versioned measurement parser | 2 | 7 | 5.17 / 6.07 | 28.81 / 34.70 | 33.60 / 42.01 |

## What the session reuses

Start `tide test FILE --incremental`, send a line containing `test` after saving and read the JSON reply. The checker rereads the reachable files under the project snapshot lock. Every request checks declarations, example bindings and the call graph. It reuses typed bodies from unchanged modules when their visible names, types and callee interfaces still match. It reuses a passing example only when its source and resolved target still match and the target cannot reach a rechecked body. Adding a function or changing a record layout forces a complete check. A failed request leaves the last green snapshot available for the next correction. [Session protocol](../../LANGUAGE.md#incremental-test-sessions) · [Implementation](../../native/bootstrap/incremental.tide)

## What was measured

One entry imports the existing order acceptance suite, streaming measurement report, cursor module and Invaders game logic. It reaches 10 source files, 47 functions or rules and 33 examples. The fixture renames the report entry and its `empty` example to avoid collisions with the order suite. The original assertions and inputs are preserved. [Project assembly](prepare.sh)

| Change | Deliberately failing version | What the clean and incremental checkers reported |
|---|---|---|
| Leaf | The cursor moves back one position across CRLF. | `cross_crlf` expected 2 and got 3 at `cursor.tide` line 16, column 1. |
| Interface | The model and importer use different arities for `identifier`. | `E_TYPE` in `import.tide` line 6, column 22 when adding the parameter and column 21 when removing it. |
| Package | The parser increments the input row passed to its decoder. | The example at `stream_report.tide` line 22 expected input row 2 and received 3. Both diagnostics also identified the failing expression in the package at line 9, column 1. |

Each scenario alternated between two distinct passing source versions. Before each correction, the harness verified the red diagnostic against a fresh `tide test`, including all nested fields. Timing started immediately before writing the replacement file or files and ended after reading and verifying the green reply. Every arm saved the same bytes by renaming temporary files and had to report 33 passing examples. The incremental arm had to recheck at least one body and execute at least one example each time.

The full-session control uses the same request protocol and starts each check from scratch. The fresh control starts the installed CLI anew. All six execution orders occurred equally often. Each scenario ran six warm-up blocks followed by 36 measured blocks. Times use a monotonic clock, the median of the middle two observations, and nearest-rank P95. The filesystem cache was warm. Results apply to this combined workload on one Ryzen 9 9950X3D core with tmpfs and networking disabled. The study measured feedback latency. It made no model calls or token estimates.

The full native and PostgreSQL regression suites passed locally. In a separate installation with no Python or compiler, the session and a fresh test also agreed on stale tool pins, missing imports, invalid UTF-8, broken exports and failed examples. [Executable TIDE regressions](../../native/bootstrap/checks.tide)

## Reproduction

From the repository root, install to a local directory and run the measurement harness. Node is used only to time the installed commands. Choose a core in the current process's allowed affinity list.

```sh
make -s -j5 install-native DESTDIR="$PWD/build/stage9/install"
bwrap --unshare-net --bind / / --proc /proc --dev-bind /dev /dev --setenv TMPDIR /tmp -- \
  taskset -c 24 node experimente/78_incremental_feedback/measure.mjs \
  build/stage9/install/usr/local/bin/tide > /tmp/tide-feedback.json
make -s -j5 test check-postgres
```
