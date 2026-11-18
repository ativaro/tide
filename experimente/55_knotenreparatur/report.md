# Node repair in local comparison

`tide test --diff --explain=nodes` now delivers the first error finding, the executed definitions, and editable operator locations with type and alternatives. `tide edit --edits` checks the selected change or replacement against the revision, the types, and the public examples. The four known repairs passed in all three interfaces. With Qwen3 4B, the additional node finding did not improve the success rate compared to TIDE function bodies in this trial. [Workbench](../../workbench/README.md#repair-a-node)

| Interface | Successes / Runs | Model queries | Input tokens | Output tokens | Total tokens | Tokens per success |
|---|---:|---:|---:|---:|---:|---:|
| TIDE-function body | 0/12 | 24 | 7,272 | 506 | 7,778 | – |
| TIDE-node edit | 0/12 | 24 | 9,444 | 633 | 10,077 | – |
| Python-AST-edit | 3/12 | 21 | 7,784 | 656 | 8,440 | 2,813.3 |

The three Python successes arose from the same equality error in three repetitions. For this, `<` → `<=` sufficed. TIDE requires an expression replacement for this case, e.g., `(not (> load cap))`. No variant solved any of the other three errors. With TIDE-node edits, 12 of 24 answers were an attempt to set the already existing operator. Nine further proposals reached public acceptance and failed there. The node finding increased the TIDE total consumption in this trial compared to bodies by 2,299 tokens. With zero successes, tokens per success is undefined. [Answers, diagnoses, and counters](messung.json)

## Procedure

The four new projects each have three source files and one error in a called function. They handle budget deduction, including capacity, complete time windows, and surcharge per unit. Two TIDE-reference solutions change an operator, two replace an expression. Before the first model query, TIDE and Python showed the same incorrect value for the first public example. Each known correction passed all three public and 72 held-out cases per task. [Tasks and reference corrections](aufgaben.json) · [Independent oracle in TIDE](orakel.tide)

For each task, three seeds ran paired and in alternating order through all interfaces. Both TIDE arms received the same function definitions and the same observed difference. Both node arms additionally received the operator positions of the entered functions. The Python comparison localizes expressions in the AST, replaces exactly the selected expression or operator, and runs the candidates in a read-only environment without network. The target values remain outside the visible project copy. TIDE checks the result vectors. [Test Plan](versuchsplan.json) · [External CPython Comparison](cpython_ast.py)

Per run, a second proposal was allowed after a public error message. The second attempt saw its own previous answer and the actual public finding. Each proposal started from the original source state. Held-out cases or their results were never shown to the model. Token counts sum Ollama's input and output counters over both attempts, including failed attempts and passed diagnostics. All 69 measured requests ran on the existing local Qwen3 4B. [Model Identification](modell.json)

The experiment measures a repair workflow with prepared context and at most two proposals. Four small tasks and one model suffice for a statement about this workflow. A general advantage for Python or an agent advantage for TIDE cannot be derived from this. The setup and the takeover of node edits passed the native acceptance test and the package check without Python.
