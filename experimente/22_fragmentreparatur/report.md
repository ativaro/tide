# What equals and rounding mean for repair costs

The explicit note on completed tests saved TIDE in the paired median 6.82 seconds and 40,073 total tokens. Compared to Python with the same note, it required TIDE in the median 1.61 seconds and 86.5 total tokens more. All 36 initial proposals passed the public and held-out acceptance test on a fresh copy.

In experiment 15, 40,612 of the 42,080 additional TIDE total tokens were in the two comparison pairs where the TIDE session with `rg --files` re-queried the already delivered directory. This is the total difference of these pairs. The share of the individual command cannot be determined exactly from this. In case of a tie, the median of the indicated thought tokens was 572 for TIDE and 256.5 for Python, and 357.5 and 138 for rounding. The answers show repeated field accesses in nested comparisons and the re-output of an almost unchanged fold. The clock records the entire repair. It measures no separate thinking time per expression. [Original prompts, answers, and counters](../15_gepaarte_reparaturen/messung.json)

## Two changes to the TIDE workbench

The previous attempt with grouped compiler view and named function bodies saved TIDE-text edits in paired median 3.08 seconds and 190.5 total tokens. At the same processing form, Python was still ahead by 0.97 seconds and 110 tokens. An additional library for rankings was later used in one of twelve possible repairs. Therefore, this experiment examines two steps of the actual repair process. [Comparison of processing forms](../16_gruppierte_reparaturen/report.md) · [Experiment with comparison functions](../17_prioritaeten/report.md)

A model answer can replace a unique excerpt in the compiler-grouped function body. It names the function, old excerpt, and replacement. This reduces the amount of unchanged code that the model must transcribe. In case of multiple hits, the workbench requires a longer excerpt. Multiple changes are composed on the same source version, type-checked, and tested substantively. [Implementation in TIDE and executable examples](../../workbench/function_fragment.tide)

A second change concerns the instruction to the model. The workbench can explicitly confirm in the prepared context that directory, reachable sources, and first failed test come from the same checked working copy. The session shall derive its first proposal from this and look further in case of a concrete information gap. In comparison, Python received the same hint and the same replacement option. [Model instruction and usage](../../workbench/README.md#replace-an-excerpt-in-the-function-body)

The neutral control instruction in this experiment designated the sources as complete and allowed further inspections. Already in experiment 16, the outer instruction additionally pointed to the performed test run. Here, the workbench provides this hint for excerpt repairs itself. The direct comparison measures its additional benefit over the neutral control instruction on the same current basis.

## New errors and acceptance tests

The basis were the correctly repaired projects from experiment 16. In route selection, a profile compared the power consumption of the new route with the latency of the previous one in case of a tie. The other profile displaced the first route when values were completely equal. In print orders, the common rounding function counted an additional sheet for exact multiples including zero. A second module calculated four instead of three sheets per sheet for monochrome printing. For each task, the two regressions were in different files. [Source programs, changes, and experimental setup](versuchsplan.json)

| Case | Public before repair | Held out before repair | After reference corrections |
|---|---:|---:|---:|
| Route selection | 29/41 | 25/32 | 41/41 and 32/32 |
| Print orders | 3/41 | 2/32 | 41/41 and 32/32 |

The outputs of both languages matched before the repair, after each isolated partial correction, and after both corrections for every input. Each remaining individual error caused at least one public and one held-out test to fail. Public and held-out inputs were disjoint. The sessions received the contract, the four reachable source files in alphabetical order, and the first public failure. The faulty files and the number of required edits were known only to the experiment lead.

## Measurement

Each repetition used a fresh project copy and a new ephemeral Codex session with `gpt-6-astra`, cognitive effort `xhigh`, and requested service class `priority`. The monotonic clock ran from the start of the first precheck through context preparation and model response until the passed public test. On another fresh copy, public and held-out tests were repeated outside the measurement time. Total tokens are input plus output from the CLI. Input cache hits are included. Reported cognitive tokens are part of the output.

The first series compared complete TIDE function bodies, TIDE snippets, and Python snippets. After the first TIDE sessions had requested the finished context again, a separate additional trial was defined. It compared TIDE snippets with the prior and explicit instruction, and Python with the explicit instruction. Per series and error, there were three temporally adjacent triplets. Each condition stood once per error at each position. All sessions ran sequentially. [Commands of the first series](messverfahren.json) · [Predefined additional trial](zusatzplan.json) · [Changes to the measurement procedure](zusatzverfahren.json)

## What the shorter response brought

In the route selection, the length of the compact JSON response decreased in all three TIDE comparisons from 497 to 249 UTF-8 bytes. In printing, the two complete function bodies were already short. Here, the response grew from 177 to 197 up to 227 bytes because it named the old and the new text passage. The byte counts describe only the issued repair.

Across all six blocks, TIDE with snippets versus TIDE with complete function bodies needed 20,210.5 fewer total tokens and 1.03 more seconds in the paired median. Both TIDE conditions inspected the working copy in each run, with a total of 21 and 26 shell commands respectively. Python managed all six runs without a shell command. The token savings also include further model calls after tool invocations. The sheer amount of copied code does not explain it. [Prompts, responses, commands, and CLI counters of the first series](messung.json)

## What the inspected context brought

| Additional trial, six runs each | Time to acceptance, median | Total tokens, median | Tokens after subtracting cache hits, median | Total shell commands |
|---|---:|---:|---:|---:|
| TIDE with neutral instruction | 16.06 s | 59,896 | 3,511.5 | 24 |
| TIDE with explicit note | 9.64 s | 19,812 | 1,870.5 | 0 |
| Python with explicit note | 7.96 s | 19,745.5 | 1,825.5 | 0 |

With the note, TIDE required less time and fewer total tokens than TIDE with the neutral instruction in all six pairs. The paired savings after subtracting cache hits were at a median of 1,623 tokens. Previously, each of the six sessions queried information again from the working copy. One even attempted to provide the answer via standard input to `./verify`. The checker tests the files on disk. With the note, all six sessions created a passing answer directly. The visible source packages were identical. [Prompts, model answers, model usage, and checker results](zusatzmessung.json)

| TIDE with note minus Python with note | Time difference, paired median | Total token difference, paired median | TIDE faster | TIDE more efficient |
|---|---:|---:|---:|---:|
| Route selection with tie | −0.60 s | +15 | 2/3 | 0/3 |
| Printing with rounding | +3.14 s | +105 | 0/3 | 0/3 |
| Both tasks | +1.61 s | +86.5 | 2/6 | 0/6 |

The differences were formed within each task and repetition block. Context preparation including the first precheck required TIDE 0.42 seconds and 0.02 seconds for Python at a median. The additional effort for rounding remained visible even after removing the superfluous inspections. Three repetitions per error on two known projects capture neither other tasks nor other models. Requested service class, response latency, and cache hits can also fluctuate between fresh sessions. [Evaluation of all conditions](auswertung.json)
