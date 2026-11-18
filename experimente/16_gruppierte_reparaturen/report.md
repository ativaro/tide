# Function grouping and named repairs

The new TIDE workflow saved compared to the previous one at two new errors in the median of the eight paired comparisons 3.08 seconds and 190.5 total tokens. Against Python with also named repairs, it required in the median 0.97 seconds and 110 total tokens more. All 32 answers passed with the first submission the respective 40 acceptance test cases and 30 additional held-out cases.

## What the earlier tie and rounding runs cost

In the eight examined TIDE sessions, 199,259 total tokens and 125.22 seconds were incurred in total. The eight corresponding Python sessions required 157,179 tokens and 75.97 seconds. In each of one TIDE run per error, the already submitted file directory was requested again with `rg --files`. In these two pairs, 40,612 of a total of 42,080 additional TIDE tokens were involved. The 40,612 are the total pair differences and not separately measured costs of the command.

| Earlier task | Time TIDE / Python, median in s | Thought tokens TIDE / Python, median | Remaining output tokens TIDE / Python, median |
|---|---:|---:|---:|
| Tie | 17.20 / 10.44 | 572 / 256.5 | 187.5 / 174 |
| Rounding | 11.39 / 8.49 | 357.5 / 138 | 124.5 / 103 |

The old TIDE-answers repeatedly solved the tie using nested comparisons and multiple field accesses. For rounding, they returned the old folding function body and the new expression with rounding outside of `fold`. 3,760 of the total 5,077 output TIDE-tokens were designated as thought tokens, with Python 1,560 of 2.707. The logs measure the entire turn. They do not allow splitting the thinking time into syntax, domain reasoning, or model latency. [Previous Orders and Answers](../15_gepaarte_reparaturen/messung.json)

## Modified Tool

`repair_view` shows the function bodies fully parenthesized by the existing compiler. The order specifies coverage from the public entry point as well as the argument order of `if` and `fold`. The model may continue to read files. Its answer can name multiple ordinary functions, each with a name and a complete new function body. `candidate_files` generates a common file candidate from the same stored source version. The checker types and tests this in a separate copy. Both new tool entries are implemented in TIDE. The previous text editing remains available. [Usage and Example](../../workbench/README.md#repair-grouped-function-bodies)

The original errors could be correctly repaired offline with the new procedure, with 38/38 and 31/31 passing acceptance tests and an additional 30/30 cases each. For Report, Temperature Control, Nano, and Space Invaders, the existing examples also passed after rewriting the compiler-grouped reachable functions. The tool examples check, among other things, two files in an answer, line endings, duplicate and unknown targets, and an invalid second edit.

## Blind Comparison

In **Route Selection**, a profile had to minimize latency first and then power consumption, while a second profile had the reverse priority. The previous code could accept a worse primary value if the secondary value improved. Complete ties should retain the first route. For **Print Orders**, print runs within an order were allowed to split pages, but separate orders and print types were not. One calculation rounded across order boundaries, while the other rounded for each individual print run.

Both errors were each embedded in two of four modules. The precheck compared all output costs of the language pairs. In route selection, there were initially 21/40 cases, and after just one canonical partial correction, each had 28/40. In printing, there were 14/40 and individually 18/40 and respectively 28/40. All held-out target values were fixed before the model runs. Each model received a customer case and contract, the same first test failure, and the prepared reachable sources in alphabetical file order. The prompt contained neither the error location nor the number of required changes. Functions for source inspection and `./verify` were accessible in all groups.

Per error, there were four blocks with four fresh, serially started sessions each. TIDE and Python were each measured with Textedit and with named function repair. For Python, the latter accepts an ordinary multi-line function body. The order was balanced per error such that each run occurred once at each block position and each direct transition occurred once. Model, reasoning level, and service class were `gpt-6-astra`, `xhigh`, and `priority`. The monotonic clock ran before the failure check and context preparation until the first successful external test run. The re-check on fresh copies and the held-out cases lay outside the measurement time. [Fixed tasks and order](versuchsplan.json) · [Measurement commands and Python comparison adapter](messverfahren.json)

| Run | Median in s | Median Total Tokens | Median Thought Tokens | Sum Total Tokens | Sum after subtracting cache hits |
|---|---:|---:|---:|---:|---:|
| TIDE · Textedit | 13.95 | 19,978.5 | 392.0 | 200,502 | 16,310 |
| TIDE · Function name | 9.62 | 19,791.5 | 238.0 | 158,479 | 49,679 |
| Python · Textedit | 9.61 | 19,748.5 | 215.5 | 158,081 | 30,081 |
| Python · Function name | 7.68 | 19,676.0 | 200.5 | 157,483 | 101,163 |

Each difference below is a new TIDE run minus the comparison run within the same error and repetition block. Positive values indicate additional effort for TIDE.

| Task | Comparison | Median Difference in s | Median Difference Total Tokens | TIDE faster | TIDE with fewer tokens |
|---|---|---:|---:|---:|---:|
| Both errors | TIDE with Textedit | −3.08 | −190.5 | 7/8 | 8/8 |
| Both errors | Python with function name | +0.97 | +110.0 | 2/8 | 1/8 |
| Route selection | TIDE with Textedit | −4.50 | −197.0 | 4/4 | 4/4 |
| Route selection | Python with function name | +3.65 | +199.0 | 1/4 | 0/4 |
| Print jobs | TIDE with Textedit | −2.37 | −190.5 | 3/4 | 4/4 |
| Print jobs | Python with function name | +0.79 | +32.5 | 1/4 | 1/4 |

The new TIDE workflow saved a median of 145.5 Den tokens and 68.5 other output tokens per pair compared to the Textedit. Both metrics decreased across all eight pairs. There were two additional tool calls in a single session with the old TIDE Textedit, whereas none occurred during the named TIDE repairs. The compiler view also incurs time costs. Its full preparation, including the initial precheck, took a median of 0.64 seconds with the current TIDE approach, 0.14 seconds with the previous method, and 0.03 seconds with Python and named repairs.

With Python, the named format saved a median of 1.53 seconds and 37.5 total tokens compared to its Textedit. The new TIDE workflow and the previous Python Textedit showed a median difference of −0.12 seconds and +31.5 tokens. The stronger Python comparison is the also-named workflow. After subtracting cache hits, the median pair difference against this is +37 tokens for TIDE, with four of eight pairs favoring TIDE. The sums of cache hits varied considerably. [Prompts, timestamps, responses, usage counters, and acceptances](messung.json)

**Boundary of the finding.** Grouped presentation, explicit context coverage, and named changes were jointly tested with TIDE. Their respective contributions cannot be determined from this experiment. Route selection remains the larger gap: The TIDE responses continue to dictate the priority order. Four repetitions per error demonstrate this behavior for these two tasks with this model. The measurement concerns the repair workflow, not the execution speed of the finished applications.
