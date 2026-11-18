# A public counterexample separates green candidates

TIDE can compare publicly passed candidates against each other on the same valid inputs using `test --diff --explain=candidates --probes`. The finding names the first separating input and the observed outputs. An independent proof is required for the target value. [Workbench](../../workbench/README.md#repair-a-node)

For the remaining task, the quotient and remainder match on the three previous public cases. The input pool checks the permissible minimum capacity `b = 1`. At `a = 0`, both candidates still match. At `a = 1`, the quotient yields `1` and the remainder `0`. A separate TIDE oracle confirmed `0` by subtracting units in full boxes from the initial quantity. The confirmed case lay outside the previous public and hidden catalog. [Input pool and oracle](probe.tide)

Both methods added `{"inputs":{"a":1,"b":1},"expect":0}` as a fourth public example in a copy and repeated the same precheck. TIDE retained `mod`, Python-AST `%`. The remaining candidates passed all 72 unchanged hidden cases.

| Method with same precheck | Before | With public counterexample | Total tokens after |
|---|---:|---:|---:|
| TIDE | 14/15 at 531 tokens | 15/15 | 0 |
| Python-AST | 14/15 at 555 tokens | 15/15 | 0 |

The five programs, each with three source files, the original tests, the candidate rules, and the upper limit of 32 edits per project remained unchanged. The initial candidate lists matched the previous measurement. Both sides searched in the same order and required two probe inputs. All 30 acceptances ran from separate copies. The 15 slots per language correspond to five tasks and three repetitions. The choice was deterministic this time. No model query was needed. [Experiment Plan](versuchsplan.json) · [Raw Data](messung.json) · [Previous Comparison](../58_ausdrucksvorpruefung/report.md)

`make check-no-python` checked the new diagnosis in the installed TIDE package without Python.

The result shows the benefit of a domain-validated counterexample for both procedures. Without an independent target value, the observed values remain an open domain decision. The cost of a domain inquiry lies outside this measurement.
