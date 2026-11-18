# Same repair context with fewer compiler invocations

In all 24 measurement pairs, the grouped TIDE view was available earlier. The ordered function bodies, additional signatures, and the content of the view matched in every pair. For the journal and deployment assignment, the complete prompts were also byte-identical to those of the earlier blind studies. [Experimental plan](experiment-plan.md) · [timestamps, source states, commands, and content hashes](messung.json)

| Project, eight pairs each | Functions | Context before, median | Context now, median | Savings per pair, median |
|---|---:|---:|---:|---:|
| Journal | 4 | 495 ms | 323 ms | 171 ms |
| Deployment with library | 5 | 585 ms | 366 ms | 216 ms |
| Measurement report from `apps/report.tide` | 3 | 424 ms | 281 ms | 144 ms |

Measurement started from the first project check up to the fully grouped view including additional signatures. For each procedure, a new output directory was created. Per project, each procedure ran four times. The relative time savings were at 35.5 % in the median of the 24 pairs. Local measurements do not capture model latency. For byte-identical prompts, the input text for tokenization is also identical. For this evaluation, no new model run was started.

## What time cost

In the first journal measurement, 369 of 550 ms were attributed to acquiring the four function bodies. Previously, the workshop started the compiler twice per function. The first invocation returned the node list including the position of the root expression. The second invocation returned exactly this expression with the grouping from the type checker.

Now a TIDE program determines the position in the original text together with the list of reachable definitions. The compiler provides the grouping with one query per ordinary function, provided its operator is within the first 32 code points of the first body line. Otherwise, the position is queried from the compiler. For a state rule, no expression query is necessary. A private source copy and the project revision bind all answers to the same checked state. In the documented workflow, a subsequently modified imported file led to termination before prompt output. [Position determination in TIDE](../../workbench/grouping.tide) · [Executable workflow](../../workbench/README.md#repair-grouped-function-bodies)

## A larger application

For Nano `step`, the compiler had already delivered all 14 function bodies beforehand. The subsequent replacement searched the same file again per body and consumed the work budget. The new TIDE call inserts the checked bodies in a single pass per file. Nano can now be fully displayed within the previous resource limit. An independent run of the earlier individual replacements over the same compiler responses yielded the same text. The fully newly assembled project copy passed its three TIDE examples. [Assembling the view](../../workbench/grouped_view.tide)

For Space Invaders `draw`, the view of all 13 functions matched the previous output. The full project copy passed ten examples. When entering via temperature control, the rule text remained visible. The full copy passed its three examples. Another project checked deep indentation and an opening bracket on its own line. Both functions were found via the exact position query. The call with input 4 yielded before and after assembling 9.

## Distance to Python

A second measurement included the initial failed precheck and writing the full prompt file. Per project, six pairs ran with varying order. The end products matched the archived prompts of their respective languages. [Plan of the additional measurement](python-comparison.md)

| From first test to finished prompt | TIDE now, Median | Python, Median | Additional paired effort for TIDE, Median |
|---|---:|---:|---:|
| Journal | 372 ms | 33 ms | 340 ms |
| Assignment | 409 ms | 29 ms | 379 ms |

Python read in the full module texts. TIDE checked the revision, traced reachable definitions, and procured type-checked expression trees. Python was faster in preparation for all twelve pairs. Even in the improved TIDE flow, the reference CLI starts its own compiler process per queried function. The runtime of the finished applications and tokens until a new repair were not measurement variables of this experiment.
