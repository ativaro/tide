# Multi-file repair with prepared project context

TIDE required 19,833 total tokens instead of 79,628 and 6.96 instead of 21.37 seconds until passing acceptance for the same new error with prepared context. Python with also prepared context required 19,861 tokens and 10.18 seconds. All four repairs passed on the first attempt 25 out of 25 cases.

| Approach | Total Tokens | Input from Cache | Tokens after Subtracting Cache Hits | Model Tool Calls | Seconds until Acceptance |
|---|---:|---:|---:|---:|---:|
| TIDE, self-search | 79,628 | 76,032 | 3,596 | 6 | 21.374 |
| TIDE, error image and reachable code ahead-of-time | 19,833 | 17,920 | 1,913 | 0 | 6.958 |
| Python, self-search | 81,700 | 59,520 | 22,180 | 4 | 28.744 |
| Python, error image and full source ahead-of-time | 19,861 | 17,920 | 1,941 | 0 | 10.184 |

### Errors and Acceptance

The package acceptance receives messages with order number and quantity. The first message per order books the quantity. Repeats must not alter the booking even if another order has arrived in the meantime. A separate metric counts consecutive groups of identical numbers. For the messages `(41,4), (52,7), (41,99)`, three groups, two orders, and eleven booked items were correct. Both initial programs delivered three groups, three orders, and 110 items.

The public commission specified only the contract and customer example. It contained no file, function, or number of affected positions. Both projects comprised four modules. The register already distinguished "first order intake" from "start of a group". The evaluations for order count and quantity both used the second feature. This feature had to be retained for the group statistics.

Inputs and target values were fixed before the model runs. The initial programs produced identical outputs in all cases and consisted of 17/25. Isolating the correction for order count yielded 19/25, and for quantity 17/25. All four model answers corrected both consumers. A repetition of the acceptance test on four fresh copies with the saved changes confirmed the results. [Orders, source code, cases, and measurement commands](aufgabe.json)

### What changed in the preparation

With TIDE, the tool constructs a snippet starting from the public entry point `main` based on the verified call relationships. All four files were accessible. Three unused helper functions were eliminated. Of 1,966 source code bytes, 1,556 were included in the order, each with a visible filename. The tool does not assign an error probability to any module. The Python control run received the same test observation and the complete four Python files. In both prepared runs, the model was allowed to read further files or restart the checker. Both returned the repair directly. [TIDE Tool and Operation](../../workbench/README.md#find-errors-across-multiple-files)

### Measurement and Limits

On 16 November 2026, four separate, fresh Codex sessions ran sequentially in Read-Only mode with `gpt-6-astra`, Reasoning level `xhigh`, requested service class `priority`, and CLI 0.157.1. The triggered sequence was Python autonomous, TIDE prepared, Python prepared, TIDE autonomous. Model, customer text, answer format, change rights, and acceptance cases were identical. In the prepared runs, the automatically generated context was added. The system applied the submitted changes jointly to the respective test copy.

The clock ran until the first successful external test run, starting from context preparation. Preparing the failed attempt and the context for TIDE together cost 0.131 seconds, and for Python 0.035 seconds. These times are included in the table. Total tokens count all input and output tokens of the turn. Cache hits and thought tokens are already included. The autonomously searching Python run additionally verified its proposed changes against seven own cases. In the autonomously searching TIDE run, several tool calls for directory search were eliminated. [Timestamps, usage counters, prompts, tool calls, and repairs](messung.json)

Saved from his own search. TIDE 75.1 % total tokens and 67.4 % time. After deducting the cache hits, the token savings were 46.8 %. With a prepared context, Python was also able to do without all model-driven tool calls. Between the prepared runs were 28 total tokens and 3.23 seconds. With one run per condition, these are individual observations. The attempt does not separate the effect of the TIDE source selection from the effect of the previously supplied error image and source code.
