# Local Agent Comparison · Two Repairs Across Module Boundaries

Qwen3 4B dissolved under the same conditions **0 from 6 TIDErepairs and 2 from 6 Python repairs**. A subsequently tested grammar help brought TIDE also to 0 from 6. Thus, no token advantage per correct repair is used for this local process.

| Condition | Successful Repairs | Total Tokens of All Attempts | Tokens per Successful Repair |
|---|---:|---:|---:|
| TIDE with prepared context | 0/6 | 3,224 | – |
| Python with prepared context | 2/6 | 3,135 | 1,567.5 |
| TIDE with additional grammar assistant | 0/6 | 3,846 | – |

The cost column counts input and output according to Ollama's usage counters. Failed attempts also count toward the cost per success. With zero successes, the quotient is undefined. No pair existed where both languages succeeded. A time comparison up to a successful repair is therefore not possible with these pairs. [Raw Data](messung.json) · [Retest](messung_grammatikhilfe.json)

## What Failed

In case of a tie, Qwen chose the entry point three times in TIDE and rewrote the function body. The answers included, among other things, unsupported bindings and `lambda`. With grammar assistance, these forms disappeared from the answers. However, Qwen continued to omit the required binder for the existing value in the `case`. In Python, both alternatives in the entry point succeeded in all cases. For the rounding error, Qwen failed to solve the task in neither language. The TIDE suggestions repeated the unchanged function body of the entry point, although the incorrect rounding lay in an imported helper.

The previous attempt with GPT-6-Astra solved all twelve of these repairs. There too, no overall token advantage for TIDE emerged in the paired median. The present experiment concerns a different model and the tested workflow with prepared findings and a single edit suggestion. It does not compare freely operating agents. [Previous Blind Test](../38_fehlerkontext/report.md#blind-experiment-with-prepared-context-for-both-languages)

## Procedure

The two tasks, sources, findings, and expectations stem from the existing blind test. Both languages received the same technical assignment, the first failing example, and the statically reachable functions. Each run was a fresh request with an edit suggestion as JSON. The three seeds were paired and the order alternated. The retest added the grammar assistant exclusively to the TIDE system prompt. This arose after reviewing the first results. [Test Plan](versuchsplan.json) · [Grammar Assistant](grammatikhilfe.json)

Before the model runs, all four known reference repairs passed six public and 72 held-out cases each. The TIDE proposals were checked via revision-bound changes in project copies. CPython served as an external comparison in a read-only environment without network access. Both Python successes were confirmed again, with target values lying outside the project copy visible to the program. TIDE compared the complete result vectors. [Acceptance in TIDE](abnahme.tide)

All 18 measured queries ran on the local Ollama 0.40.16 via Loopback. They used the existing Qwen3-4B model in mode without additional thinking phase. Cloud quota was not used for these queries. [Model digest](modell.json)
