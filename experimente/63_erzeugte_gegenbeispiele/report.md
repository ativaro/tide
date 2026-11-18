# Generate counterexamples after exhausting the fixed pool

Passed with fixed pool TIDE and Python-AST each **12/60 Repairs ()20 %)**. Both of them were produced **60/60 (100 %)**. The 48 previously open runs per procedure concerned four tasks with intentionally poorly dividing pools. TIDE needed less with generation in the paired median 47.3 ms and was faster in all 60 pairs. The median of the paired time factors is **2.33×**. No variant called a model. [Individual times and raw data](messung.json)

| Result per procedure | Runs | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Fixed pool, repairs passed | 12 | 33.2 / 37.3 ms | 81.9 / 87.9 ms |
| Fixed pool, without counterexample finished | 48 | 12.0 / 13.8 ms | 23.5 / 25.9 ms |
| With generation, all repairs | 60 | 36.2 / 48.3 ms | 82.0 / 107.4 ms |
| Solved only by generation | 48 | 36.6 / 49.0 ms | 83.4 / 108.1 ms |

## Which inputs separated the pairs

The five programs and their public and held-out test cases originate from experiment 62. For shipping labels and net weight, the fixed pool contains only inputs with `a = b`. For the clock window, its inputs lie above the window. For the remainder load, quotient and remainder are identical across the entire fixed pool. For the paint requirement, the fixed pool already separates the pairs. The pilot runs confirmed the baseline on both sides. [Fixed pools in TIDE](pool.tide) · [Sources and contract](../62_mehrdeutige_paare/report.md)

| Task | Fixed inputs checked until first generated input | Counterexample `(a, b) → Sollwert` | Green pairs per round | TIDE Median with generation | Python-AST Median with generation |
|---|---:|---|---:|---:|---:|
| Shipping labels | 16 | `(0, 1) → 0` | 6 → 1 | 37.7 ms | 83.3 ms |
| Net weight | 16 | `(0, 1) → -1` | 6 → 1 | 33.9 ms | 80.1 ms |
| Clock window | 16 | `(48, 48) → -99`, then `(1, 5) → 1` | 6 → 3 → 1 | 46.2 ms | 105.0 ms |
| Remainder load | 32 | `(48, 48) → 0` | 2 → 1 | 34.4 ms | 81.5 ms |
| Paint requirement | — | `(1, 1) → 1` from the fixed pool | 2 → 1 | 32.4 ms | 80.2 ms |

Both methods found the same separating inputs and the same candidate outputs. The common, independent TIDE contract confirmed the target value. Each confirmed input lay outside the 72 held-out cases of its task. After importing the two jointly tested files, all successful repairs passed the public and the 72 unchanged held-out cases. [Raw data with search rounds and candidates](messung.json)

## Workflow and measurement conditions

`--probe-range '{"a":[0,96],"b":[1,96]}'` specifies the valid search range at TIDE. After the fixed pool, both methods try the same sequence of midpoints, boundary values, neighbors of the failed example, and mixed corner points. Generation skips public examples and already tested inputs. Per search level, 32 inputs and 128 candidate evaluations apply. The search space of changes includes up to 32 single edits and 64 pairs per round. [Test plan](versuchsplan.json) · [Python-AST comparison](cpython_probes.py) · [Invocation in the workshop](../../workbench/README.md#generate-inputs-for-green-pairs)

Measurement was taken from the start of pool creation until independent acceptance or termination. Time includes generation, search, confirmation, further prechecks, patch, and acceptance. Per task and mode, twelve measurement pairs ran with varying order and fresh processes. TIDE 0.6.1 and CPython 3.14.10 used the same logical core on a Ryzen 9 9950X3D with warm file caches. Measurement ran locally without network. Both methods consumed 0 model tokens in both modes.

`make test` succeeded. The installed TIDE package generated the counterexample even in a filesystem without Python. Generation is a limited search within specified integer ranges. Its result contains observed candidate outputs. For selection, an independently confirmed target value remains required. The success increase refers to the five tasks and the specifically poorly separating pools of this experiment.
