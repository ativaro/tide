# Repair with two cross-file node edits

Both methods repaired with the pair search **96 of 96 runs at 0 model tokens**. The twelve double-counter runs per method that remained open in the single-edit experiment now passed acceptance. TIDE required less time in all 96 pairs. In the paired median, TIDE was 2.36 times faster. The paired time saving was 49.7 ms in the median and between 41.1 and 56.7 ms for the middle 50 % of pairs. [Previous Experiment](../60_reparaturzeit/report.md) · [Single Times and Raw Data](messung.json)

| Repair Time Until Acceptance | Pairs | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| All Tasks | 96 | 36.4 / 45.6 ms | 85.5 / 104.0 ms |
| Double-Counter with Two Edits | 12 | 30.7 / 32.6 ms | 71.3 / 74.1 ms |
| Four Tasks with Public Counterexample | 48 | 43.5 / 46.7 ms | 100.3 / 104.3 ms |

## Double-Counter

The identical precheck after 16 single edits found no green candidate. Both methods checked all 64 permissible pairs between `route` and `rulebook`. Exactly one pair passed all three public tests. It replaced the addition of 1 with the subtraction of 1 in both files. After the joint preview and adoption into the working copy, the patch also passed all 72 held-out cases in each run. The first diagnosis, including single and pair search, took a median of 7.6 ms at TIDE and 20.7 ms at Python-AST. The remaining time was spent on pool generation, preview, adoption, and final acceptance.

In a separate function test with only the original example `(6, 5) → 54`, three pairs remained green initially. At `(1, 1)`, they produced `0`, `8`, and `8` in both procedures. The contract confirmed `0`. After adding this public example, the same pair remained on both sides as in the main measurement. This function run does not enter time or success metrics.

## Comparison Conditions

The eight projects, their original public examples, and the 72 held-out cases per project come from trial 60. Both procedures started with the same budgeted individual test. Pairs were only tested if the individual test was complete and no candidate passed. Per pair, the changes come from two different files and from the same operator and expression rules. The four previous counterexamples and the displayed candidate counts matched in both procedures. [Trial Plan](versuchsplan.json) · [Source Pairings](../60_reparaturzeit/paarungen.json) · [External CPython-AST Comparison](cpython_pairs.py)

The timer started before pool creation and ended after independent acceptance. It includes command-line starts, tests, optionally the counterexample search and its confirmation, as well as preview and patch adoption. For pairs, a call on both sides produced the two jointly tested texts. The measurement driver wrote them into the isolated working copy and then started the acceptance run. The comparison used TIDE 0.6.1 and CPython 3.14.10 on the same logical CPU with warm system caches, fresh processes, and varying start order. Both procedures had twelve measurement runs per task. The runs had no network access and made no model queries.

`make test` passed. The installed package passed the CLI test in a filesystem without Python and without network. Upon adoption of both files, the project revision matched the preview. The old revision value yielded `E_REVISION`. [Pair Search and Preview Call](../../workbench/README.md#check-two-files-together)

The time measurement contains an error requiring a pair and seven control tasks. The search is limited to two files per pair and 64 pairs. Multi-file patches are output as a preview for a working copy. Atomic exchange via `--write` applies to a single file.
