# Checked operator changes · TIDE and Python-AST

TIDE checks operator changes now locally against all existing examples. `tide test FILE --diff --explain=candidates` provides the finding and the passed candidates. The search works with one change of the checked tree in memory per step. A later `edit --edits` checks the actual source change once more against the same revision. [Workbench](../../workbench/README.md#repair-a-node)

| Interface | Successes / Runs | Success Rate | Model Requests | Total Tokens | Tokens per Success |
|---|---:|---:|---:|---:|---:|
| TIDE with Precheck | 8/15 | 53.3 % | 3 | 531 | 66.4 |
| Python-AST with Precheck | 11/15 | 73.3 % | 3 | 555 | 50.5 |

The three additional Python successes stem from the capacity task. Python-AST can replace `<` with `<=`. In TIDE the same case requires an expression replacement. The calculation surcharge required an expression replacement in both languages and yielded no passed operator change. [Individual Values and Raw Data](messung.json)

## Comparison on the same four tasks

| Interface | Previously without Precheck | Now with Precheck |
|---|---:|---:|
| TIDE-Node | 0/12 at 10,077 Tokens | 6/12 at 0 Tokens |
| Python-AST | 3/12 at 8,440 Tokens | 9/12 at 0 Tokens |

Both interfaces benefit from local search. The advantage in token consumption arises here primarily because unambiguously accepted suggestions go directly to the independent acceptance test. Compared to the equally equipped Python benchmark, TIDE achieves fewer successes overall and requires more tokens per success. [Previous comparison](../55_knotenreparatur/report.md)

## Ambiguity and Acceptance

A fifth task asks for the number of unpacked units. For the three public inputs, the integer quotient and remainder are randomly equal. Both changes therefore pass the prefilter. Qwen3 4B chose the remainder in two out of three runs per language. In all six queries, it chose the second position after the order had switched per seed. The held-out cases returned the wrong quotient in both languages. This task provides no evidence of a difference in selection quality between languages. [Task](rest_aufgabe.json) · [Oracle in TIDE](rest_orakel.tide)

Up to 32 individual operator changes were considered in the functions entered at the first error, per task and language. Both used their respective native operators. The upper limit was not reached for any of the five tasks. The four reused tasks and their oracle cases were compared with earlier raw data before the run. All 34 TIDE decisions matched the true source editor, including rejected changes. For Python, candidates were generated as AST changes and executed in read-only copies without network access. The TIDE acceptance test checked the result vectors against the shared oracle.

A missing candidate counts as a failed attempt without a model query. A single one receives direct acceptance. For multiple ones, the model receives a contract, the first public error, and exclusively accepted candidates. All selections were tested separately against 3 public and 72 held-out cases per task. 15 runs per language mean five tasks with three seeds. Deterministic suggestions repeat. All six counted model queries ran over local Ollama, including input and output tokens. [Experiment plan](versuchsplan.json) · [Model digest](modell.json)

The package check `make check-no-python` succeeded with the candidate finding in the installed package.
