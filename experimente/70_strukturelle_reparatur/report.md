# Repair search across three files

**Both tools solve nine out of ten tasks at the program entry with the new search rules. With the previous search, it was one on the same tasks each time.** TIDE achieves independent acceptance in successful repairs in 16.6 ms, Python-AST in 32.0 ms (median). In three cases, both tools swap the arguments in the caller. Therefore, with additional direct inspection of the intermediate module, six out of ten tasks exist. [Evaluation](auswertung.json) · [Direct module acceptance](modulabnahme.json)

| Metric | TIDE previous | Python-AST previous | TIDE extended | Python-AST extended |
|---|---:|---:|---:|---:|
| Tasks passed at entry | 1/10 | 1/10 | 9/10 | 9/10 |
| Log tokens for all ten attempts | 2,909 | 3,172 | 3,474 | 3,769 |
| Of which attributed to passed tasks | 340 | 382 | 3,189 | 3,459 |
| All log tokens divided by passed tasks | 2,909 | 3,172 | 386 | 418.8 |
| Median until successful acceptance | 15.9 ms | 31.7 ms | 16.6 ms | 32.0 ms |
| 95. Percentile until successful acceptance | 17.1 ms | 33.1 ms | 22.4 ms | 35.0 ms |
| Median until report without candidate | 6.5 ms | 18.0 ms | 6.5 ms | 18.5 ms |

TIDE was faster in all 108 successful measurement pairs of the extended search. The median Python time/TIDE time ratio was **1.94**, with the middle 50 % lying between **1.73 and 1.99**. For the single previously solvable task `thermal`, the TIDE time changed from 15.90 to 16.03 ms, and the CPython time from 31.70 to 31.70 ms. The comparison of the two success medians before and after the extension covers a different number of tasks. [Individual times with block order](messung.json)

Across all trials, the extended TIDE protocol required **295 fewer tokens (7.8 %)**. Of these, 257 tokens were attributed to the first message with the order, three source files, and public examples. The input and output sums are 3,167 and 307 at TIDE, and 3,450 and 319 at Python. Each deterministic protocol counts once per task and procedure. The time repetitions generated identical messages. The local Llama-BPE tokenizer counted the compact JSON messages without special tokens. There were zero model calls. Actual tokens and thinking time of a programming model cannot be determined from this. [Protocols](protokolle.json) · [Offline evaluation](auswerten.mjs)

## Tasks and selected repairs

Each task consists of the entry `panel`, the intermediate module `route`, and the library `rulebook`. The table shows the extended search. At each row, both tools checked the same number of individual edits and pairs and offered the same green options technically. The times are medians per task in milliseconds. At `flag` the clock stops with the report that no candidate passed.

| Task | Selected Edit | Checked individually / pairwise | Green Options | Tokens TIDE / Python | Time TIDE / Python |
|---|---|---:|---:|---:|---:|
| `cut` · Sampling points | Swap start and end in the caller | 12 / 0 | 2 | 349 / 406 | 17.1 / 32.1 |
| `tape` · Band address | Swap first and third argument in the caller | 24 / 0 | 2 | 370 / 438 | 18.8 / 33.0 |
| `page` · Page allocation | Determine UTF-8 byte count before rounding | 9 / 0 | 1 | 291 / 316 | 16.0 / 31.6 |
| `ticket` · Print order | Measure byte count of the composed text | 5 / 0 | 1 | 343 / 373 | 16.0 / 31.7 |
| `namespace` · Double colon | Find last `::`, even with overlapping matches | 5 / 0 | 1 | 303 / 307 | 15.9 / 31.7 |
| `annotation` · Log text | Find last diamond in a computed text | 1 / 0 | 1 | 327 / 313 | 15.6 / 31.6 |
| `telemetry` · Counter difference | Swap counter in the caller and form UTF-8 byte count | 11 / 35 | 2 | 468 / 536 | 22.4 / 32.7 |
| `trailer` · End field | Find last field boundary and measure byte count of the substring | 7 / 6 | 1 | 398 / 388 | 18.9 / 32.0 |
| `thermal` · Units | Change existing arithmetic operator | 8 / 0 | 1 | 340 / 382 | 16.0 / 31.7 |
| `flag` · Package filter | No candidate for ASCII case-insensitivity | 0 / 0 | 0 | 285 / 310 | 6.5 / 18.5 |

For `cut`, `tape`, and `telemetry`, two public green options are available. The pre-determined sorting selects the swap in `panel` in each case. Thus, all 72 results match at the entry point. However, a direct call to `samples(begin=3, finish=4, rate=4)` still yields −4, and the contract for the excerpt results in 4. In the additional check, the actually selected patches were reapplied, and all 72 cases per task were executed directly against `route`. Both languages produce identical results for each input there. For the three affected tasks, only 3, 5, and 3 out of 72 direct calls exist. This subsequent check was separated from selection and timing. [Module check](modulpruefung.mjs) · [First counterexamples](modulabnahme.json)

## Test setup

- The ten three-file projects were written for this experiment. Six tasks specifically test the three extensions, two combine changes in different files. An arithmetic check and a task outside the search rules are included. The results describe this specifically compiled sample. [Tasks and sources for both languages](aufgaben.json)
- Tasks, rules, reference, and schedule were hashed before drawing the local random seed. The independent TIDE oracle generated eight public and 64 held-out, task-specific inputs per task. The unchanged TIDE and Python programs produced pairwise identical outputs on all 720 inputs. The precheck discovered a name collision in the measurement helper before the first warm-up round. Only its parameter was renamed. The seed and inputs remained intact. [Experiment plan](versuchsplan.json) · [Hashes and correction](fixierung.json) · [Oracle](abnahme.tide) · [All cases](prueffaelle.json)
- Both searches received the same public examples and the first failing example. Per task, at most 32 single checks and 64 pair checks over two files were available. Existing rules were tried first. When multiple green options existed, the order from file, position, and replacement was decided. Held-out examples were passed to the repaired program only for acceptance. For no task was the search cut off. [TIDE change](suche.patch) · [CPython-AST comparison](cpython_suche.py)
- Each of the four arms ran once per task for warm-up and twelve times under the clock. Each arm occupied each of the four positions three times. Fresh files and processes were used per trial; the filesystem cache was warm. The clock includes diagnosis, candidate search, selection, takeover, and independent acceptance test. Setting up working copies and token counting were outside the clock. TIDE used the installed commands `test`, `edit`, `test`. CPython searched and wrote in one process and read the saved modules for acceptance in a fresh interpreter. AMD Ryzen 9 9950X3D, CPU 24, TIDE 0.6.5, CPython 3.14.10, network namespace with loopback only. The result file holds both Inspector binary hashes. [Measurement program](messen.mjs) · [480 Individual measurements](messung.json)

The native regression `make test` passed. The three previously open projects `wire`, `mosaic`, and `suffix` from trial 69 passed with the new Inspector after diagnosis and takeover their respective previous 72 entry cases. For this additional control, the installed TIDE toolchain ran in an isolated filesystem without Python. [Previous trial](../69_neue_mehrdateienaufgaben/report.md)

## Locally repeat

From the project directory, the following commands generate two separate installations. The reverse patch file restores the previous search in a temporary source copy. The measurement commands rewrite the result files in the trial directory.

```sh
d="$PWD/experimente/70_strukturelle_reparatur"
stage=$(mktemp -d)
mkdir "$stage/alt"
cp -a Makefile tide tide.lock native "$stage/alt/"
(cd "$stage/alt" && patch -R -p1 < "$d/suche.patch" && make -s -j4 install DESTDIR="$stage/vorher")
make -s -j4 install DESTDIR="$stage/nachher"
export TIDE_BEFORE="$stage/vorher/usr/local/bin/tide" TIDE_BIN="$stage/nachher/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev node "$d/modulpruefung.mjs"
```

For the offline count, `TOKENIZER_JSON` must point to the local vocabulary designated in the trial plan fixation and `TOKENIZER_PYTHON` to a local interpreter with `tokenizers`. The used version was 0.23.3. Then the following command checks hashes, case counts, pairings, candidates, and budgets and writes the evaluation.

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/auswerten.mjs"
```
