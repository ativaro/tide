# Eight new multi-file repairs with TIDE and CPython

Both tools repaired **5 of 8 tasks (62.5 %)**. For the same five tasks, TIDE achieved independent acceptance earlier. Against the more compact of the two tested CPython variants, the paired time factor was **1.94×**. Each successful solution passed eight public and 64 previously held-out cases. The local runs did not invoke any models. [Individual measurements](messung.json) · [Precheck](kontrollmessung.json)

| Metric | TIDE 0.6.5 | CPython 3.14.10 with AST |
|---|---:|---:|
| Solved distinct tasks | 5/8 | 5/8 |
| Successful measurement runs in the predefined comparison | 60/96 | 60/96 |
| Time to successful acceptance, Median / P95 | 18.34 / 24.76 ms | 56.66 / 62.95 ms |
| Time to abort without candidates, Median / P95 | 7.25 / 8.35 ms | 19.12 / 21.42 ms |
| Time to successful acceptance in the precheck, Median | 14.74 ms | 29.15 ms |
| Actual model input and output tokens of the repair runs | 0 | 0 |
| Offline counted protocol tokens of the five solved tasks combined | 2,057 | 2,286 |
| Offline counted protocol tokens of all eight tasks, one attempt each | 2,943 | 3,248 |
| Protocol tokens of all attempts divided by five successes | 588.6 | 649.6 |

### Tasks and Errors

The eight projects were rewritten for this experiment. Each has three source files per language. In three of the five successful repairs, the tool had to modify two files jointly. For Mirror Buffer and Spectral Width, two public green changes remained in each case. The pre-established sorting decided the tie. When comparing equal numbers, the choice between strict and inclusive comparison does not affect the result there. [Sources of both languages and orders](aufgaben.json)

| Task | Result of both tools | Median TIDE / Python, original flow | Protocol tokens TIDE / Python |
|---|---|---:|---:|
| Image number from timestamp | Multiply minutes by 60 | 16.44 / 56.57 ms | 340 / 383 |
| Archive group | Count records starting from one and add group ID to start value | 17.45 / 54.72 ms | 391 / 435 |
| Level alarm | Count equality and multiply count by measurement period | 19.20 / 56.47 ms | 433 / 485 |
| UTF-8-Message length | Open. The payload requires byte counting. | 7.03 / 18.56 ms until abort | 286 / 312 |
| Mosaic address | Open. Row and column are swapped on call. | 7.36 / 19.71 ms until abort | 311 / 350 |
| Mirror buffer | Use the higher occupancy level | 17.89 / 57.26 ms | 380 / 426 |
| Spectral width | Determine the lower minimum and subtract from the upper maximum | 22.39 / 56.92 ms | 513 / 557 |
| Path component | Open. The last slash is sought. | 7.39 / 18.76 ms until abort | 289 / 300 |

### How the held-out cases remained separated

Orders, source programs, TIDE-oracles, search rules, and drivers received SHA-256 fingerprints before the first repair. Only afterward did the operating system generate a random value for selecting the held-out inputs. For each task, all 72 inputs are distinct. In a separate precheck, both faulty source programs yielded the same actual value on all 576 inputs. The study authors knew the tasks. The existing repair tools received only the public examples. [Fixation and random value](fixierung.json) · [TIDE-oracle](abnahme.tide) · [Identical test data](prueffaelle.json)

Both sides started from the first failed public example. The limits were 32 single edits and, if needed, 64 edit pairs across different files. All tasks remained within these limits. The comparison checked for each task the match of error example, actual and target values, candidate counts, and files and operators of the green suggestions. The search received no additional target values. Only after selection, public precheck, and acceptance of the edit into the working copy did a fresh process uncover the held-out cases. A failure was final. [Predefined test plan](versuchsplan.json) · [Repair logs](protokolle.json)

### What the timing measured

The monotonic clock ran from the start of diagnosis until the completion of the independent acceptance test or until termination. It included process starts, candidate search, selection, acceptance, and tests. Preparation of working copies, generation of test data, and subsequent token counting lay outside the interval. There was one unweighted warm-up pair per task and twelve measurement pairs with varying start order, new working copies, and warm file cache. All processes ran sequentially on CPU 24 of a Ryzen 9 9950X3D in a network namespace with only loopback. The repetitions measure time spread across eight tasks. [Measurement results and runtime environment](messung.json)

In the predefined sequence, both tools started three processes upon successful repair. The median of the 60 paired Python/TIDE time ratios was 3,07. The middle 50 % lay between 2.77 and 3,23. The median of the paired time savings was 37.45 ms. [Evaluation by task and phase](auswertung.json)

After this measurement, the process split was varied in a second paired experiment. CPython searched and accepted the edit in a single call. A lean second interpreter read the saved modules directly for the independent acceptance test. TIDE was measured again in the same block with its usual CLI calls. Both methods selected exactly the same patches for all tasks as in their first measurement. TIDE was faster in all 60 successful pairs. The median of the time ratios dropped to **1.94**, the middle 50 % lay between **1.77 and 2.04**. The choice of the Python tool sequence thus has a significant impact on the factor. [CPython control arm](cpython_kompakt.py) · [Paired single times](kontrollmessung.json)

### What the tokens indicate

There were **zero additional model runs**. For the separate log measurement, the same local Llama-BPE tokenizer counted each compactly serialized message individually, without special tokens. It recorded the task, complete erroneous sources, public tests, compact diagnosis report including green candidates, the decision, and the acceptance status. Across all eight tasks, this amounted to 2,779 input plus 164 output log tokens for TIDE and 3,060 plus 188 for Python. The scope was **9.4 % lower** for TIDE. Failed attempts count. The twelve identical repetitions serve solely for timing. [Messages](protokolle.json) · [Tokenizer fingerprint and counts](auswertung.json)

The result bears a statement about these local repair tools and the specified message format. Statements regarding the actual total tokens of a programming model including context, repetitions, and thought tokens lack model measurements. Also, the three open tasks are relevant for feasibility. None of the existing change rules could deliver a public green candidate there.

### Locally repeat

The following commands run from the project directory and require the existing Linux toolchain, Node.js, CPython, Bubblewrap, and taskset. `run` checks the fixed source files and uses the recorded random value. A new run replaces the result files in the experiment directory. For an independent rerun, a working copy can be used.

```sh
d=experimente/69_neue_mehrdateienaufgaben
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/messen.mjs" run
bwrap --unshare-net --bind / / --dev /dev taskset -c 24 node "$d/kontrolle.mjs"
```

For the separate token count, set `TOKENIZER_JSON` to the local vocabulary file with the recorded SHA-256 value and `TOKENIZER_PYTHON` to an interpreter with Hugging Face `tokenizers`. The measurement used version 0.23.3. Only vocabulary and rules are loaded. [Timing](messen.mjs) · [Offline evaluation](auswerten.mjs)

```sh
bwrap --unshare-net --bind / / --dev /dev node "$d/auswerten.mjs"
```
