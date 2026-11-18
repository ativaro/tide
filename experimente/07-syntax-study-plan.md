# Which notation helps me when programming?

**Stand 16. November 2026.** The exploratory run with twelve tasks and 36 first submissions has been evaluated. All submissions were created in the same session. The following text fixes the pre-planned conditions. [Report and raw data](07_dreiwege/report.md)

## What exactly varies

All three representations generate the same typed program tree. Example for the saturation of the heat counter:

| Surface | Expression |
|---|---|
| A · TIDE-prefix | `if < streak 3 + streak 1 3` |
| B · fully parenthesized prefix | `(if (< streak 3) (+ streak 1) 3)` |
| C · Python-like expressions and function calls | `streak + 1 if streak < 3 else 3` |

In all arms, the same TIDE types, evaluation orders, overflow rules, error codes, rights, and budgets apply. C uses a limited subset of familiar Python syntax. Evaluation proceeds via the shared TIDE semantics. CPython with its libraries is suitable later as an independent practice comparison.

Before measurement for each used construct, verify that a reference tree is identical after output and re-reading in all three forms. Likewise, check limits, the unevaluated branch of a `if`, and a denied read access. An error in this precheck is an error of the experimental setup.

## Tasks and Flow

Twelve new tasks form a first paired experiment. Each task runs once per surface, totaling 36 first submissions. The six possible arrangements of A, B, and C are each used twice. Each submission requires a fresh context with the same model version and the same available tools. The work questions, starter programs, allowed operations, visible examples, and held-out target values are content-identical. Reference cards differ only where the notation requires it. The known examples for Pump, Light, and Alarm serve the precheck.

| Share | Examples for task selection | Success |
|---|---|---|
| 4 write | Two pure data transformations, a nested control flow, and a flow with explicit state. | The program fulfills the task on the pre-defined held-out inputs. |
| 4 change | A change with two callers, a changed initial value, error handling, and a sequence rule. | The new requirement and all still-valid examples are fulfilled. |
| 4 repair | A missing operand, a changed radix of a helper function, a type error, and a type-correct behavioral deviation. | The deliberately introduced defect is fixed and the remaining requirements remain fulfilled. |

Orders and oracles are frozen ahead-of-time. Tasks and domain target values should ideally originate from a different person than the solver. The first response is saved before tool feedback. Subsequently, a maximum of two repair attempts are permitted. The reviewer provides the same semantic information; the position of a syntax error actually derivable from the respective interface remains measurable. Log isolated cases without separate context as exploratory pilots.

## Measurement and Decision

Functionally correct first submissions per task and interface count primarily. For each task type, the individual paired results show: For which tasks did I solve the solution only in one form? Additionally, separate syntax and type errors, record repair attempts, as well as input and output tokens including reference, diagnoses, and tool context. Costs of unsuccessful attempts contribute to total tokens per solved task. Record separately for the missing operand where the parser could **recognize** the defect and whether I correctly localized the **cause**.

The twelve tasks are a pilot. A cheaper syntax becomes the preferred candidate only when an advantage repeats on new tasks and no additional group of domain regressions occurs. In case of a tie, the choice remains open. Optional parentheses as an explicit boundary for individual sub-expressions constitute a separate follow-up attempt; in the first pass, A and B are clearly separated.
