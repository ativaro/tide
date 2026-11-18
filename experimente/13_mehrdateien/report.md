# Repair with unknown error location

| From customer report to passed acceptance test | TIDE | Python |
|---|---:|---:|
| Total tokens | 58,789 | 58,824 |
| Of which input tokens from cache | 38,272 | 38,272 |
| Total tokens after deduction of these cache hits | 20,517 | 20,552 |
| Output tokens, included in total | 475 | 386 |
| Time including search, edit, and check | 13.669 s | 13.539 s |
| Passed cases with the first submitted repair | 20/20 | 20/20 |

### The Error

The customer message described a rental from 08:57 to 09:00 at 3 cents per minute. The surcharge of 2 cents per minute begins at 09:00. Both programs invoiced 14 cents. The correct amount is 9 cents for three occupied minutes.

The time period module provided the first free minute as the end. Both base price and surcharge counted this minute as occupied. This resulted in two different incorrect line items on the same invoice. Without repair, the outputs of both programs matched in each of the 20 cases. One case existed. An isolated correction for the base price brought both projects to 6/20, an isolated correction for the surcharge to 2/20. Both models changed the length calculation in both billing modules. The original source files, the verbatim order, the check command, and all pre-agreed cases are stored. [Test inputs](aufgabe.json)

### Execution on 16 November 2026

Two fresh Codex sessions each received a working directory with four source files and the command `./verify`. The order did not name files, functions, or the number of affected locations. Both sessions ran with `gpt-6-astra`, reasoning level `xhigh`, requested service class `priority`, and Codex CLI 0.157.1. Reminders, hooks, and plugins were disabled. The triggered order was TIDE, then Python. TIDE ran with the reference implementation 0.5.0, Python with CPython 3.14.10.

Both models searched for the files themselves, read all four, and reproduced the customer complaint with `./verify`. They delivered their changes in a structured response each time. An external process applied the changes and re-executed the same test command. Both projects used the same fixed set of expected invoices. It includes, among others, empty rents, both window boundaries, partial overlap, a full day, and tariffs individually set to zero. The cases and the checker remained unchanged during the repair. Re-applying the stored answers to fresh copies yielded 20/20 again.

The clock started immediately before the respective Codex process and stopped at the first successful external test run. The token counts come from the completed CLI-turn and include the source search, tool results, and repair response. In this setup, no further model response was generated after the successful test. [Tool calls, changes, timestamps, and usage counters](messung.json)

TIDE consumed 35 fewer total tokens. Python achieved acceptance 0.130 seconds earlier. From a run per language, no reliable language advantage can be derived. In the earlier [balance test](../12_funktionsrumpf/report.md), the objective function was already known. Here, the search belonged to the task, and two function bodies had to be checked jointly. The different tasks do not allow a separate estimation of search costs.
