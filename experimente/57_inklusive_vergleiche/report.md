# Including comparisons · Repetition measurement with precheck

TIDE 0.6.1 supports `<= a b` and `>= a b` for signed integers. Both yield a truth value and include equality. The checker, the bootstrap tools, both native compiler paths, and the operator precheck use the new comparison group. The project pin contains the updated operator catalog. [Language reference](../../LANGUAGE.md) · [TIDE examples](../../native/bootstrap/fixtures/functions/inclusive.tide)

| Procedure with precheck | Successes / Runs | Model queries | Total tokens | Tokens per success |
|---|---:|---:|---:|---:|
| TIDE 0.6.1 | 11/15 (73.3 %) | 3 | 531 | 48.3 |
| Python-AST | 11/15 (73.3 %) | 3 | 555 | 50.5 |

The precheck found exactly one correction for TIDE at the capacity error: the switch from `<` to `<=`. It succeeded in all three repetitions without a model request. Consequently, TIDE increased from **8/15 to 11/15** and achieved the same success rate as the re-executed Python comparison. The 24 Tokens difference stems from the three requests for the ambiguous remaining task. Both languages delivered two out of three correct selections there. The difference is too small and the task too narrow to derive a general token advantage from it. [Raw data](messung.json) · [Previous comparison](../56_gepruefte_operatoren/report.md)

The five errors, inputs, three seeds, and the budget of 32 candidates remained unchanged. TIDE and Python-AST each checked 36 switches. All TIDE decisions matched the actual source check by `tide edit`. The Python candidate list was identical to the previous measurement. A single green switch proceeded to the independent acceptance test with 72 held-out cases without a model call. With two green switches, both languages received their byte-identical model requests from the previous trial again. No held-out case appeared in the prompt. All six counted requests ran on the same local Qwen3 4B. [Test plan](versuchsplan.json) · [Model digest](modell.json)

The calculation surcharge still requires an expression replacement. The operator precheck found no matching switch in both languages there.

`make check-no-python` succeeded with both operators in the installed catalog, in the project evaluator, in the AOT program, and in the independent ELF programs for folds and rules.
