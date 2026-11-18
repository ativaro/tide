# Prepared repair context in TIDE and Python

TIDE was faster in 3 out of 12 pairs and consumed less total tokens in 3 out of 12. Both applied in two pairs. All 24 independent sessions passed acceptance with the first repair. The time and token lead from the earlier individual trial did not repeat across the three new error families. [Earlier comparison](../14_projektkontext/report.md)

## Time and tokens until passed acceptance

The differences are each TIDE minus Python. First, the difference within each temporally adjacent pair was determined, then the median was formed. A positive sign means higher effort for TIDE.

| Error family | Pairs | Time TIDE / Python, median in s | Paired time difference, median in s | Paired total token difference, median | TIDE faster | TIDE with fewer tokens |
|---|---:|---:|---:|---:|---:|---:|
| Tie at max and min value | 4 | 17.20 / 10.44 | +6.92 | +354 | 0/4 | 0/4 |
| Rounding of debit and credit | 4 | 11.39 / 8.49 | +3.30 | +265 | 1/4 | 0/4 |
| Measurement series after restart | 4 | 11.20 / 12.93 | −1.73 | −47 | 2/4 | 3/4 |
| All | 12 | 13.27 / 10.65 | +3.07 | +186.5 | 3/12 | 3/12 |

The time differences ranged from −4.23 to +18.64 seconds, the total token differences from −79 to +20.589. Relative to the Python value of the respective pair, the median was +30.9 % time and +0.95 % total tokens for TIDE.

| Counting method | All 12 TIDE repairs | All 12 Python repairs | Median paired difference per repair |
|---|---:|---:|---:|
| Total tokens from CLI input and output | 278,839 | 236,901 | +186.5 |
| Total tokens minus reported input cache hits | 74,679 | 37,349 | +46 |
| Output tokens including indicated thought tokens | 6,717 | 4,817 | +156.5 |

Cache hits are part of input and thought tokens part of output. Without cache hits, TIDE was more frugal in six pairs. Cache occupancy fluctuated between sessions.

During the second TIDE-rounding run and third TIDE-tie run, the model listed the files again with `rg --files` despite the prepared context. This led to another handover of the model context. All other sessions responded without tool calls. These two pairs accounted for a combined 40,612 of the total 41,938 additional TIDE tokens. Both pairs are included in all main values. Even among the ten pairs without tool calls on both sides, TIDE required more total tokens in seven cases. Local context preparation took a median of 0.149 seconds for TIDE and 0.035 seconds for Python. [Usage counter, tools, prompts, repairs, and timestamps](messung.json)

## Tasks, control, and flow

Each error family consisted of four technically appropriate files per language. For the ranking error, both extreme values had to observe the same tie rule. For the calculation error, both sides had to round only after summing. For the measurement series error, a segment boundary belonged to the current sample, and the evaluation of descents had to omit invalid transitions across this boundary. Each language produced exactly the same faulty or correct output as the other for every acceptance case before the repair.

| Family | Passed before | Only first reference change | Only second reference change | After both changes |
|---|---:|---:|---:|---:|
| Tie | 12/38 | 22/38 | 22/38 | 38/38 |
| Rounding | 20/31 | 22/31 | 21/31 | 31/31 |
| Restart | 17/36 | 25/36 | 16/36 | 36/36 |

The model task contained the public contract and a customer case. Additionally, each session received the result of the failed test run and the four source files in the same order by filename. TIDE used the unchanged tool `project_context.tide` from `main`, while Python received the full source code. All production functions in the examples were reachable. No error location or number of expected changes was named in the task. For each language and family, the prompt was byte-identical across all four repetitions. The models were allowed to read files and start the tester.

Errors, acceptance cases, order, pairing, repetition limit, and key metrics were fixed before the first session. Each family appeared once in four blocks, with their position changing. Within each pair, the languages ran directly one after the other, with each language starting twice per family. Each run started with a fresh project copy and its own ephemeral session of `gpt-6-astra` with `xhigh`, requested service class `priority` and Codex CLI 0.157.1. Used were TIDE 0.5.0 and CPython 3.14.10. [Fixed test plan and initial programs](versuchsplan.json) · [Measurement commands](messverfahren.json)

The monotone clock started before the first precheck and context setup. It stopped after applying the answer to a fresh copy and the successful external test. All 24 answers were then applied again to unchanged original copies. Each passed both its original cases and 30 additional cases defined separately during model runs for its family. This additional control did not belong to the timing. The repetitions capture fluctuations for three tasks on 16 November 2026. A general ranking for other errors, models, or service conditions cannot be derived from this.

## The twelve pairs

| Error family | Repetition | TIDE in s | Python in s | TIDE-total tokens | Python total tokens |
|---|---:|---:|---:|---:|---:|
| Tie | 1 | 13.73 | 10.69 | 19,900 | 19,781 |
| Tie | 2 | 15.42 | 9.54 | 20,026 | 19,752 |
| Tie | 3 | 28.83 | 10.19 | 40,317 | 19,728 |
| Tie | 4 | 18.98 | 11.03 | 20,169 | 19,735 |
| Rounding | 1 | 10.51 | 10.61 | 19,677 | 19,566 |
| Rounding | 2 | 15.01 | 7.78 | 39,537 | 19,514 |
| Rounding | 3 | 10.45 | 6.92 | 19,778 | 19,502 |
| Rounding | 4 | 12.28 | 9.21 | 19,855 | 19,601 |
| Restart | 1 | 8.99 | 13.22 | 19,846 | 19,925 |
| Restart | 2 | 9.59 | 13.18 | 19,899 | 19,918 |
| Restart | 3 | 15.67 | 12.59 | 19,892 | 19,967 |
| Restart | 4 | 12.81 | 12.67 | 19,943 | 19,912 |
