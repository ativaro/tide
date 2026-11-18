# Derive input ranges from the contract

TIDE and Python-AST derived the same inclusive intervals from the same `requires` conditions. Both passed **60 of 60 repair runs at 0 model tokens**. TIDE was faster in all 60 pairs and in the paired median **2.42 times faster**. The paired time saving was 49.5 ms in the median and for the middle 50 % of pairs between 47.5 and 51.1 ms. [Individual times and raw data](messung.json)

| Repair time until acceptance | Pairs | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| All five tasks | 60 | 33.9 / 46.1 ms | 83.2 / 107.2 ms |
| Four tasks with generated counterexample | 48 | 36.2 / 47.0 ms | 83.7 / 108.8 ms |
| Control task with counterexample from the fixed pool | 12 | 31.9 / 33.3 ms | 82.3 / 84.8 ms |

## Derivation and counterexamples

TIDE reads `requires` from the public sample contract of the repaired target. It intersects the conditions per integer parameter and converts strict boundaries into inclusive boundaries. For net weight, for example, `gt: -5` together with `ge: -9` and `le: 88` gives the interval `[-4,88]`. `--pairs` uses this interval automatically. In the diagnosis, the area used is at `repair.probe_range`. [Contracts of the five measurement tasks](vertraege.json) · [Workbench](../../workbench/README.md#generate-inputs-for-green-pairs)

| Task | Derived range for `a` and `b` | Confuted counterexamples `(a, b) → Sollwert` | TIDE Median | Python-AST Median |
|---|---|---|---:|---:|
| Shipping labels | `[1,96]`, `[1,96]` | `(5, 6) → 40` | 38.4 ms | 84.6 ms |
| Net weight | `[-4,88]`, `[1,100]` | `(42, 50) → -8` | 33.7 ms | 81.8 ms |
| Clock window | `[0,96]`, `[1,96]` | `(48, 48) → -99`, then `(1, 5) → 1` | 46.0 ms | 106.3 ms |
| Paint requirement | `[1,50]`, `[1,80]` | `(1, 1) → 1` from the fixed pool | 31.9 ms | 82.3 ms |
| Residual charge | `[0,96]`, `[1,96]` | `(48, 48) → 0` | 32.6 ms | 82.2 ms |

For shipping labels, the example contract excludes the previously generated counterexample `(0, 1)`. Both tools instead found `(5, 6)`. Per round, the normalized ranges, the checked candidate counts, the found inputs, and the outputs of the associated edits matched. The independent TIDE contract confirmed every target value. All repairs passed the public and each 72 unchanged held-out tests, whose inputs differed from the confirmed counterexamples.

## Comparison and Verification

The five faulty programs, each with three files, and the test cases originate from experiment 62, while the fixed pools come from experiment 63. Both sides received the same `requires` conditions together with the public tests. Derivation occurred within the measured calls. Both sides used the same search bounds and the same order for fixed and generated inputs. Both checked and adopted the same two files into a working copy and reopened them for acceptance. [Experiment plan](versuchsplan.json) · [External CPython-AST comparison](cpython_contract.py)

Measurement spanned from creating the fixed pool to acceptance. Included are derivation, precheck, all counterexample rounds, confirmation, patch, and acceptance test. TIDE 0.6.1 and CPython 3.14.10 ran sequentially on the same logical core of a Ryzen 9 9950X3D with warm file caches. Per task, there were twelve measurement pairs with fresh processes and varying order. The runs were local and network-isolated.

`make test` and the call in the installed package without Python passed. Further CLI checks covered overflowing strict bounds, contradictory and multiple declarations, the exact i64 lower bound, and protection of existing example contracts during editing. An explicit span further restricts the contract range for generation. An empty cut yields `E_INPUT`.

The derivation supports independent integer constraints against constants. The measured time advantage applies to these five tasks with executable target confirmation and fresh command-line processes.
