# Resolve Ambiguous Change Pairs with Public Counterexamples

Both procedures repaired all five new projects with three source files each. The twelve repetitions per project yielded **60/60 successful runs per procedure at 0 model tokens**. TIDE was faster in all 60 pairs and required 60.5 ms less time in the paired median. The median of paired time factors is **2.23×**. The middle 50 % of paired time savings ranged between 52.3 and 63.1 ms. [Raw Data with Individual Times](messung.json)

| Time from start to acceptance | Pairs | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| All repairs | 60 | 51.8 / 61.0 ms | 115.5 / 123.0 ms |
| One confirmed counterexample | 24 | 38.6 / 40.3 ms | 90.5 / 94.0 ms |
| Two confirmed counterexamples | 36 | 53.8 / 61.8 ms | 118.1 / 123.5 ms |

## Resolution of Ambiguity

At the beginning, no task had a single edit passing all public tests. There remained either two or six green edit pairs in two different files. In three tasks, after the first counterexample, three or four pairs remained green. The second made the repair unambiguous. Both methods found the same pairs in each round, the same separating input, and the same mapping of outputs to edits. An independent TIDE contract confirmed the target value. [Faulty Source Pairs](paarungen.json) · [Contract with Test Cases](vertrag.tide)

| Task | Green Pairs per Round | Confirmed Counterexamples `(a, b) → Sollwert` | TIDE Median | Python-AST Median |
|---|---:|---|---:|---:|
| Shipping Labels | 6 → 4 → 1 | `(2, 1) → -99`, `(1, 2) → 4` | 59.1 ms | 120.1 ms |
| Net Weight | 6 → 4 → 1 | `(2, 1) → -99`, `(1, 2) → -1` | 52.6 ms | 116.7 ms |
| Time Window | 6 → 3 → 1 | `(1, 1) → -99`, `(1, 2) → 1` | 52.9 ms | 116.3 ms |
| Paint Requirement | 2 → 1 | `(1, 1) → 1` | 38.5 ms | 90.5 ms |
| Residual Load | 2 → 1 | `(1, 1) → 0` | 39.1 ms | 90.5 ms |

For shipping labels, both tools checked 14 single edits and 40 pairs per round. In the other tasks, there were eight single edits and 16 pairs each. The final repair of shipping labels combines a comparison swap with an expression replacement. The other pairs consist of two operator swaps. In all runs, both jointly checked files passed all public and the 72 unchanged held-out cases.

## Measurement Conditions

Both tools started with the same precheck with at most 32 single edits and 64 cross-file pairs per round. The common input pool came from the valid boundary of the tasks. Both searched until the first input with different regular outputs and checked at most 32 inputs and 128 candidate evaluations per round. Only the confirmed target value came as an additional public test in the repetition. The process allowed up to three confirmations. The search run and its confirmation received no held-out target values. [Experiment Plan](versuchsplan.json) · [Unchanged Python-AST Comparison](../61_dateiuebergreifende_paare/cpython_pairs.py)

The monotonic wall clock started at the beginning of pool generation and included diagnostics, all search and confirmation rounds, preview, takeover into the working copy, and independent acceptance test. Build and preparation of the source copies occurred before the start. The installed TIDE 0.6.1 and CPython 3.14.10 ran sequentially on the same logical core of a Ryzen 9 9950X3D, with warm system caches, fresh CLI processes, and varying start order. The measurement was network-isolated and did not invoke a model.

The comparison applies to five deliberately ambiguous errors with executable contracts. The repetitions measure time spread per task. The success measurement covers cases that can be distinguished from the defined input pool.
