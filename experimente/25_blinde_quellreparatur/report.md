# What grouping costs and saves when repairing

In the original tie, TIDE needed 6.92 seconds in the paired median and 354 total tokens more than Python; in rounding, 3.30 seconds and 265 tokens more. Of the total 42,080 additional TIDE tokens of these eight pairs, 40,612 fell to the two pairs with a renewed file list. The thinking token medians were 572 versus 256.5 in the tie and 357.5 versus 138 in rounding. The answers contained repeated field accesses and almost unchanged reproduced folds. How much time a single consideration cost, the counters do not reveal. The earlier switch to an explicitly checked context eliminated repeated inspections. [Original measurement](../15_gepaarte_reparaturen/report.md) · [Controlled repetition](../22_fragmentreparatur/report.md)

The new TIDE repair view leaves the author-written parentheses in the expression. The workbench joins body lines, retains bindings and literals, and uses the same checked call graph and same replacement mechanism as the fully parenthesized view. This eliminates individual compiler processes per function. The accompanying instruction for the already checked copy is shorter. [Implementation and examples](../../workbench/source_repair.tide)

## Two new multi-file errors

In the jury, two independent rankings with equal primary values must select the smallest serial number; one used the term as a secondary key and selected the largest number on tie, while the other rounded half a unit based on the parity of the remainder. A second function calculated the exemption amount over the entire delivery list, although it applies per delivery. Each family comprises four modules. Public and held-out inputs are separated. The two languages produced identical output before the repair, after each individual reference change, and after the complete correction in every case.

| Family | Previously public | Previously held-out | After reference repair |
|---|---:|---:|---:|
| Jury | 22/40 | 19/35 | 40/40 and 35/35 |
| Depot | 18/40 | 3/35 | 40/40 and 35/35 |

Each of the 18 fresh sessions received the technical contract, the same observable error data, and the reachable sources of their language sorted by filename. No prompt named the error location or the number of changes. The three conditions ran serially, three times per family, with balanced starting positions. The model was gpt-6-astra with xhigh and requested service class priority. All sessions produced a first response without shell calls. All 18 candidates passed 40 public and, on a fresh copy, 35 held-out cases. The clock includes precheck, context construction, response, application, and public acceptance. The total count includes input including cache hits and output including thought tokens. [Experiment plan and examples](versuchsplan.json) · [Measurement commands](messverfahren.json)

| Flow, six sessions each | Preparation, median | Until acceptance, median | Total tokens, median | Thought tokens, median |
|---|---:|---:|---:|---:|
| TIDE, fully parenthesized | 0.333 s | 8.61 s | 19,785 | 228.5 |
| TIDE, source parentheses | 0.173 s | 10.45 s | 19,868.5 | 350.5 |
| Python, prepared source | 0.020 s | 8.86 s | 19,713.5 | 264.5 |

| Paired differences, source view minus comparison | Time until acceptance | Total tokens | TIDE-source view faster / more efficient |
|---|---:|---:|---:|
| Both tasks against parenthesized TIDE | +1.81 s | +53.5 | 0/6 and 1/6 |
| Jury against Python | +1.41 s | +57 | 1/3 and 0/3 |
| Depot against Python | +2.68 s | +266 | 0/3 and 0/3 |
| Both tasks against Python | +1.97 s | +152 | 1/6 and 0/6 |

Saving compiler queries accelerated preparation in all six TIDE pairs. Consequently, the total repair time increased across all six, and each response consumed more output tokens. The fully bracketed view remains the default. The experiment measures source view and shorter instruction together. It isolates neither the effect of individual brackets nor model latency. Three repetitions per error allow a decision for these two examples. [Single responses, times, usage counters, and acceptances](messung.json) · [Pair differences, variance, and cache cleanup](auswertung.json)
