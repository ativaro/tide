# Counterexamples from relationships between parameters

TIDE now generates counterexamples for contracts with relationships like `a <= b`. In comparison, both methods solved **60 of 72 runs (83.3 %)** at **0 model tokens**. The twelve aborts per method were due to equivalence checking. For successful repairs, TIDE was **2.42 times faster in the paired median**. The median time saving was 55.8 ms. The middle 50 % of paired savings ranged between 54.1 and 56.4 ms. [Individual times and raw data](messung.json)

| Result | Pairs | TIDE Median / P95 | Python-AST Median / P95 |
|---|---:|---:|---:|
| Repair passed | 60 | 39.5 / 44.4 ms | 95.2 / 97.8 ms |
| Remained ambiguous | 12 | 27.6 / 29.8 ms | 55.2 / 58.8 ms |

## Inputs that separated the pairs

`"a":{"le":"b"}` stands for `a <= b` in the example contract. TIDE derives tighter individual bounds via parameter relationships and continues to check each relationship at the concrete input point. For an invalid search point, the generator attempts to raise or lower the connected values. For shipping labels, this yielded the valid point `(5, 6, 5)` from `(5, 6, 6)`, satisfying both `a <= b` and `c = a`. [Contracts](vertraege.json) · [Shipping variant](versand.json)

| Task | Confirmed counterexample → target | Green pairs per round | TIDE Median | Python-AST Median |
|---|---|---:|---:|---:|
| Shipping labels | `(5, 6, 5) → 40` | 6 → 1 | 44.0 ms | 97.1 ms |
| Net weight | `(42, 50) → -8` | 6 → 1 | 39.7 ms | 94.6 ms |
| Cycle window | `(47, 48) → 47` | 3 → 1 | 39.6 ms | 95.3 ms |
| Paint requirement | `(100, 100) → 1000000` | 2 → 1 | 37.3 ms | 94.7 ms |
| Residual load | `(48, 48) → 0` | 2 → 1 | 39.2 ms | 94.7 ms |
| Synchronization | `(47, 48) → 47` | 6 → 2 | 27.6 ms until abort | 55.2 ms until abort |

For synchronization, the two remaining changes differ only by `<` and `<=`. For all inputs allowed by `a < b`, both yield the same output. The Cycle window variant additionally includes a public example at equality to check behavior outside the search range. It separates the two operators before counterexample search.

## Measurement conditions and checks

The six scenarios originate from five existing programs, each with three files. They use relational contracts and new, contract-compliant held-out inputs. Both tools received the same contracts, the same fixed pools, the same order of generated points, and the same precheck budgets. Inputs from the fixed pool that violated the contract were skipped. The checked candidate counts, derived bounds, and outputs for the separation cases matched. An independent TIDE oracle confirmed all proposed targets. Every successful run passed the public and all 72 held-out tests. [Experiment Plan](versuchsplan.json) · [Scenarios and Acceptance in TIDE](szenarien.tide) · [External CPython-AST Comparison](cpython_relations.py)

Measurement was taken from creating the fixed pool until acceptance or termination, including contract checking, counterexample search, confirmation, patching, and restart for the acceptance test. TIDE 0.6.1 and CPython 3.14.10 ran on the same logical core of a Ryzen 9 9950X3D with warm file caches. Per scenario, there were twelve measurement pairs with fresh processes and varying order. The runs were local, network-isolated, and made no model queries.

`make test` passed. The installed package generated a counterexample with parameter relationship even in an environment without Python. Targeted checks covered unknown parameters, contradictory strict cycles, i64 bounds, and an empty intersection after manual narrowing. For `tide test szenarien.tide`, `szenarien.tide` and the unchanged `vertrag.tide` from experiment 62 exist as neighbor files in a working copy. [Invocation and Contract Format](../../workbench/README.md#generate-inputs-for-green-pairs) · [Imported Contract](../62_mehrdeutige_paare/vertrag.tide)

The search supports concurrent valid direct integer comparisons. The timing applies to the five repaired tasks and the equivalence control with executable target confirmation.
