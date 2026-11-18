# Check green repair candidates at the intermediate module

**Direct module inspection increases the success rate for TIDE and Python-AST from 6/10 to 9/10.** For the cut list, band address, and telemetry, exactly one public green repair remains in each case. It corrects the argument swap where the intermediate function calls its library. The entry code remains identical in all three projects. The ten tasks and their inputs come from trial 70. [Evaluation](auswertung.json) · [Source projects](../70_strukturelle_reparatur/aufgaben.json)

| Metric | TIDE, precheck only at entry | Python-AST, only at entry | TIDE, with module precheck | Python-AST, with module precheck |
|---|---:|---:|---:|---:|
| Success at entry **and** at intermediate module | 6/10 | 6/10 | **9/10** | **9/10** |
| Protocol tokens for all ten tasks | 3,589 | 3,884 | **3,555** | **3,808** |
| Of those, on passed tasks | 2,070 | 2,147 | 3,256 | 3,484 |
| All protocol tokens per passed task | 598.2 | 647.3 | 395 | 423.1 |
| Time to successful acceptance, median | 15.12 ms | 29.35 ms | **16.61 ms** | **29.55 ms** |
| Time to successful acceptance, 95th percentile | 18.83 ms | 30.56 ms | 26.24 ms | 31.21 ms |

With module precheck, TIDE was ahead in all 108 successful measurement pairs. The median of the paired Python time/TIDE time ratios was **1.78**, with the 25th and 75th percentiles at **1.52 and 1.86**. To estimate the additional overhead of the precheck, the six already successful tasks can be compared directly. On these 72 pairs, the precheck increased time by a median of 0.97 ms in the pair differences, with TIDE and 0.08 ms for Python. The time for the unsolved task without a candidate was 5.57 and 17.90 ms with module precheck. [Individual times and block order](messung.json)

Across all ten tasks, TIDE with module precheck required **253 protocol tokens fewer than Python-AST (6.6 %)**. The sum consists of 3,237 input and 318 output tokens for TIDE, and 3,492 and 316 for Python. In both languages, the total protocol shrank compared to the precheck only at the entry point, because the diagnosis filtered out three unsuitable alternatives. Each task counts once, including the unsolved one. The numbers correspond to messages counted locally with Llama-BPE. There were zero additional model runs. [Full protocols](protokolle.json)

## The three corrected argument swap errors

| Project | Directly checked call | Previous selection | New selection | Checked individual edits / pairs in both variants |
|---|---|---:|---:|---:|
| [Interface list](repariert/cut/route.tide) | `samples(begin=3, finish=4, rate=4)` | −4 | **4** | 12 / 0 |
| [Band address](repariert/tape/route.tide) | `address(bank=0, track=0, sector=1)` | 100 | **1** | 24 / 0 |
| [Telemetry](repariert/telemetry/route.tide) | `adjust(label="A1", inbound=1, outbound=0)` | 1 | **3** | 11 / 35 |

The interface list now calls `span begin finish`, and the band address `decimal_address bank track sector`. In telemetry, the counters are passed correctly at `difference inbound outbound` and the identifier in the library is counted as UTF-8 bytes. The individual selection and the telemetry pair consisting of two files were saved as executable TIDE projects. Each project contains eight public entry points and eight public module examples. The three projects also passed with the installed TIDE-CLI in an isolated filesystem without Python. [Telemetry library](repariert/telemetry/rulebook.tide) · [Previous direct counterexamples](../70_strukturelle_reparatur/modulabnahme.json)

For the six already correct tasks, the selected patch remained the same. With the package filter `flag`, none of the tools found a change for comparison independent of ASCII case sensitivity. Across all ten tasks, the candidate budgets and the number of checked individual edits and pairs remained unchanged. [Results per task](auswertung.json)

## What both procedures see

For these ten projects, the test plan explicitly defines the intermediate function. The original entry passes its named arguments unchanged, and both interfaces must deliver the same domain result. Therefore, the same public inputs and target values can be used at both interfaces. In a project with its own units, parameters, or a transformation, the intermediate module requires domain-appropriate examples. [Goal Assignment and Test Plan](versuchsplan.json)

TIDE uses regular `example` declarations in `route.tide`. The native candidate search and the editor check these examples together with the entry examples for every other successful single edit and every pair. In the CPython reference, the same AST search from test 70 receives a second test goal. It calls the function from the respective candidate's intermediate module directly. Both sides first see the eight public entry cases and then the same eight at the intermediate module. Only prechecked candidates are offered. The selection rule and the limits of 32 single checks and 64 cross-file pairs remain the same. [CPython Check](cpython_modul.py) · [Native Regression](../../native/bootstrap/inspection_checks.tide)

The final acceptance test is **identical in all four arms**. After takeover, a fresh process reads the saved modules and checks at both targets eight public and 64 held-out cases. That is 144 calls per successful repair. The repair search receives only the public examples. On errors, the acceptance test ends at the first deviation. The three earlier caller patches pass the 72 entry cases and fail at the intermediate module. The test deliberately repeats the known sample. [Test Cases](prueffaelle.json) · [Hash Fixation](fixierung.json)

Per task and arm, there was one warm-up run and twelve measured passes with fresh processes and working copies. Each arm occupied each of the four positions in the block three times. The clock ran from diagnosis to acceptance or to a no-candidate report, including search and takeover. Preparation of the public test projects and subsequent token counting were outside. TIDE uses `test/edit/test`, CPython one process for search and takeover and a second for acceptance. The measurement ran on CPU 24 of a Ryzen 9 9950X3D with TIDE 0.6.5, CPython 3.14.10 and exclusively loopback in the network namespace. [Measurement Program](messen.mjs)

The token comparison covers order, complete source files, public cases, test goals, first error, candidate offer, selection, and final report. Since both goals use the same cases, their data is transferred once in both language protocols with the associated target names. Tokenization counts compact JSON messages without chat wrappers or special tokens. Actual model consumption and success rate on new tasks remain open. [Joint evaluation of both trials](../70_strukturelle_reparatur/auswerten.mjs)

## Locally precheck

The stored projects can be tested directly from the repository.

```sh
d="$PWD/experimente/71_modulvorpruefung"
for fall in cut tape telemetry; do ./tide test "$d/repariert/$fall/panel.tide"; done
```

For complete timing, the following commands generate a local installation. The run validates the fixed files and replaces the result files in the trial directory. CPU 24 must be available on the executing machine; alternatively, another single available core can be selected.

```sh
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev node "$d/messen.mjs" archive
```

For offline evaluation, `TOKENIZER_PYTHON` and `TOKENIZER_JSON` point to a local interpreter with `tokenizers` (here 0.23.3) and the vocabulary designated in the trial plan via SHA-256.

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/../70_strukturelle_reparatur/auswerten.mjs" "$d"
```
