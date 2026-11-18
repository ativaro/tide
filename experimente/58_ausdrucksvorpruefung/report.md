# Small expression replacements in the precheck

TIDE and the external Python-AST comparison check the same two transformations of `a*b+c` alongside operator switches: `a*(b+c)` and `(a+c)*b`. The search also recognizes `c+a*b`. Each operand must be an integer literal or a binding. In TIDE, every replacement is type-checked in a source copy in memory and executed against the same public examples as the original version. [Workbench](../../workbench/README.md#repair-a-node)

At the calculation surcharge, TIDE yielded exactly the candidate `(* units (+ rate 2))`. Python-AST found `units * (rate + 2)`. Both succeeded in all three repetitions. The unique selection proceeded to the independent acceptance test without a model call.

| Method with identical precheck | Successes / Runs | Model requests | Total tokens | Tokens per success |
|---|---:|---:|---:|---:|
| TIDE | 14/15 (93.3 %) | 3 | 531 | 37.9 |
| Python-AST | 14/15 (93.3 %) | 3 | 555 | 39.6 |

Both methods improved from 11/15 to 14/15. The gain stems entirely from the accounting surcharge. Token counts remained unchanged. All six model queries were repetitions for the remaining task with two publicly green variants. In both languages, the selection failed once due to the held-out oracle. The 24 token difference refers to this single ambiguous task. [Raw data](messung.json) · [Previous measurement](../57_inklusive_vergleiche/report.md)

The measurement used unchanged five programs in three files each, three seeds, and three public and 72 hidden cases per task. A total of 40 candidates were checked per language, including two expression substitutions for the surcharge and budget deduction respectively. The limit of 32 per task was never reached. All reported TIDE candidates were rechecked with `tide edit`. Python programs ran as external references in read-only copies without network access. Target values were outside these copies. Only publicly passed candidates proceeded to selection. All model queries ran locally via Ollama with the same Qwen3-4B model. [Experiment plan](versuchsplan.json) · [Model digest](modell.json)

`make check-no-python` passed. The installed package provided exactly the expected expression substitution for the faulty accounting surcharge.
