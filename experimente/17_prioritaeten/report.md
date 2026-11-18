# Prioritized keys in the blind multi-file test

Two new error families, six repetitions per family, and three conditions yielded 36 repair orders. Each session received the contract, a faulty result, and the sources of its language. The error locations and the number of required changes remained hidden.

The library was used in 1/12 TIDE repairs with an available module. Against TIDE without the library, the median paired difference was +2.98 s and +144 total tokens. Against Python, it was +3.97 s and +359 total tokens. The differences represent the costs of the first-named TIDE condition minus the comparison condition.

## What was already shown with the tie and rounding

At the tie, the think tokens increased in median from 256.5 at Python to 572 at TIDE, at the rounding from 138 to 357,5. In each session, the model was able to show the existing file names again. The complete differences between these two pairs added up to 40,612 of 42,080 additional total tokens in the eight pairs. The answers wrote out tie-ups with repeated field accesses and, when moving the rounding from the summation, repeated the old hull for the text edit. What proportion of the thinking time is attributable to a concrete expression was not measured. [Previous individual protocols](../15_gepaarte_reparaturen/messung.json)

The grouped compiler view with explicit context coverage and replacement by function name has already been tested with new route and print errors against text edit. She saved compared to the old TIDE procedure in the median 3,08s and 190.5 total tokens. In the new rounding error in printing, the corresponding advantage was 2,37s and 190.5 tokens. Against Python with the same form of editing, TIDE needed more when printing in the median 0,79s and 32.5 Tokens. [Experiment with both forms of machining](../16_gruppierte_reparaturen/report.md)

## Change and tasks

Two ordinary TIDE functions compare an i64 key pair ascending or descending and take another decision for the tie. The repair view can provide signatures of previously unused functions from the tested version. Both TIDE conditions use the same contextual preparation. In the library condition, the import and the two available signatures are added. All professional TIDE source files are otherwise byte-like. Python gets all four modules and also the ability to replace functions in a response by name. [Module](../../lib/ordering.tide) · [Contextual tool](../../workbench/project_context.tide)

When assigning a stake, two profiles determine the winner via three differently prioritized criteria. For identical criteria, the earlier entry wins. In the event journal, a transition must be evaluated by minute, descending priority and serial number. A reversal begins a new segment with the incoming event. For both tasks, canonical correction concerned two modules. Of each 40 acceptance cases existed before the correction 25 at the award and 13 at the journal. With only one of the two reference changes, it was 30 or 31 and 22 or 23. With both changes passed 40.

## Repairs until acceptance

The absolute values are medians of the six individual measurements per row of the table. Total tokens include input including cache hits plus output including think tokens. Accesses count shell commands launched by the model.

| Task | Procedures | Time (s) | Total tokens | Issued tokens | Thinktokens | Preparation (s) | Accesses |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Deployment | TIDE without library | 13.92 | 20,108 | 644 | 429 | 0.65 | 0 |
| Deployment | TIDE with library | 14.93 | 20,249.5 | 757.5 | 542.5 | 0.68 | 0 |
| Deployment | CPython | 10.09 | 19,878 | 457 | 280.5 | 0.03 | 0 |
| Event log | TIDE without library | 12.78 | 20,114 | 580 | 396 | 0.58 | 0 |
| Event log | TIDE with library | 14.87 | 20,257 | 695 | 511 | 0.59 | 0 |
| Event log | CPython | 10.20 | 19,932.5 | 462.5 | 294.5 | 0.04 | 2 |

For each row of the following table, differences within the same repetition block were calculated and then their median was computed. Smaller values favor TIDE with library. Time and tokens can win in different blocks.

| Task | TIDE with library minus … | Δ Time (s) | Δ Total tokens | Δ Tokens after cache deduction | Faster | Fewer tokens |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Deployment | TIDE without library | +2.98 | +142 | +112.5 | 2/6 | 1/6 |
| Deployment | CPython | +3.97 | +337 | +334 | 1/6 | 0/6 |
| Event log | TIDE without library | +2.58 | +183.5 | +942 | 1/6 | 0/6 |
| Event log | CPython | +4.48 | +374.5 | +353.5 | 1/6 | 1/6 |
| Both | TIDE without library | +2.98 | +144 | +142 | 3/12 | 1/12 |
| Both | CPython | +3.97 | +359 | +334 | 2/12 | 1/12 |

Against Python, individual differences ranged from -9.82 to +22.24 s and from -41,028 to +21,058 total tokens. In 1/12 blocks, the library condition was faster and token-efficient simultaneously. For deployment, 1/6 answers used the provided functions; for the log, 0/6. The experiment measures the benefit of the voluntarily available offer. An evaluation only of the answers that chose it would be biased by self-selection.

| Procedure, per 12 runs | Total tokens, sum | Minus cache hits | Output tokens | Attempts | Acceptances passed |
| --- | ---: | ---: | ---: | ---: | ---: |
| TIDE without library | 241,270 | 19,190 | 7,282 | 12 | 12 |
| TIDE with library | 263,502 | 41,422 | 9,376 | 13 | 12 |
| CPython | 279,991 | 19,383 | 6,168 | 12 | 12 |

All 36 repairs also passed the control check. 35 succeeded with the first answer. In the third journal run with TIDE-library, a closing bracket was missing at the end of the nested comparison. The compiler reported `E_SYNTAX` in `sequence.tide`. The second answer added exactly this character. Until acceptance, this task consumed 40,948 total tokens in 31.09 s. In the fourth Python journal run, the model checked the file list and then nine own examples in memory. This run consumed 61,284 total tokens in 25.09 s. Thus, Python could require fewer total tokens in eleven of twelve pairs and yet consume more in sum. Both outliers are fully included. [Individual answers, diagnoses, and tool calls](messung.json)

For the normal repair workflow, we retain the grouped function bodies and changes by function name. The comparison functions remain optional. Their mere signature in the context led to usage only once and yielded no typical repair advantage for these tasks. The numbers for voluntary usage do not allow a statement about how quickly an explicitly requested library solution would be written.

## Runtime of finished programs

The following numbers are milliseconds for all 40 public inputs of a task. The canonical solutions were measured in the warm TIDE-reference interpreter and in CPython. The library solution uses the comparison functions explicitly. Both TIDE measurements include the setup of the evaluation budget per call. Data, imports, and compilation were preloaded. After three warm-up calls per procedure, 18 rounds of eight calls per procedure followed, with rotating order and fixed CPU. All measured variants delivered the same expected results. [Measurement code, individual times, and evaluation steps](laufzeit.json)

| Task | TIDE without library (ms) | TIDE with library (ms) | CPython (ms) | TIDE evaluation steps without / with |
| --- | ---: | ---: | ---: | ---: |
| Assignment distribution | 3.851 | 5.604 | 0.058 | 9,043 / 13,531 |
| Event journal | 4.951 | 5.989 | 0.043 | 10,948 / 13,659 |

TIDE evaluates function arguments before the call. Thus, the library solution can also evaluate subordinate keys, even though a higher key already decides. An error in such a follow-up expression remains observable. A targeted example checks this difference from the conditional expression. The native compiler does not yet cover these record and list programs. [Library tests](../../lib/ordering_checks.tide) · [Native compiler](../../native/README.md)

## Reproduction and limits

Each of the six orders of the three conditions occurred once per family. Each model run was its own ephemeral, serial session with gpt-6-astra, Denkaufwand xhigh, requested service class priority, and codex-cli 0.157.1. The monotone time starts before the first failed test run and context preparation and ends with the first successful external test. Input and output come from the CLI usage report. After completion, all accepted answers were reapplied on new base copies and checked against 40 acceptance cases and 40 further pre-defined cases of their family. Public and additional inputs are disjoint per family. The evaluation covers 37 different session identifiers. Prepared prompts were byte-identical per family and condition over the six repetitions.

An earlier run of the same series was interrupted, and its temporary individual logs were lost. All evaluated repair data originate from a complete restart with the same previously defined plan. The repetitions capture the variance on two specifically selected tasks. Cache occupancy and response latency may fluctuate between sessions. [Test plan, source states, and cases](versuchsplan.json) · [Commands for the measurement run](messverfahren.json) · [Prompts, answers, times, tokens, and control checks](messung.json)
