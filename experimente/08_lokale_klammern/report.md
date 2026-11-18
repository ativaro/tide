# Is one parenthesis around the edited location sufficient?

For six new tasks, I solved every first submission correctly in every notation. A single parenthesization helped the reviewer in five additional error cases. In all five, the deleted value belonged immediately to the marked operation.

## My Self-Experiment

I wrote the complete function bodies myself. All three views showed the same order, the same visible example, and the same indication of which operand was selected in the editor. In **P**, the prefix remained parenthesis-free. In **L**, exactly one parenthesis pair enclosed the selected operation. In **V**, every call was parenthesized. The selection was fixed ahead-of-time and remained on the same structure path during a task. For K6, it was deliberately placed on the other side of the defect.

| Task | Order | Parenthesis-free | One Mark | Fully Parenthesized | Input Checks per Form |
|---|---|---|---|---|---:|
| K1 · Change near-shipping for zero quantity | PLV | ✓ | ✓ | ✓ | 1,251 |
| K2 · Add price correction outside overflow handler | LVP | ✓ | ✓ | ✓ | 3,126 |
| K3 · Decide archive at tie after identifier | VPL | ✓ | ✓ | ✓ | 1,251 |
| K4 · Repair missing summand in selected addition | PVL | ✓ | ✓ | ✓ | 251 |
| K5 · Repair missing terms within a selected branch | VLP | ✓ | ✓ | ✓ | 1,251 |
| K6 · Repair missing terms immediately before selection | LPV | ✓ | ✓ | ✓ | 1,251 |

Each checkmark represents a successful first submission. All six orderings occurred once. I secured the 18 answers before the first reviewer feedback. Per form, a total of 8,381 submissions were checked, including the visible example per task. The remaining grid also covers the two i64 limits. The test bench uses the same parser for all views and the same type checker and evaluator from the previous attempt. Also, the finished program trees matched across all three forms for every task.

**When changing the price**, the bracket around the left result separated this well from the unchanged right result. Once I added the correction, my local version showed `(+ catch E_OVERFLOW + l reserve _ ersatz k)` instead. To decide whether the handler catches an overflow of the correction, I had to reassign the arguments again. Only `(+ (catch E_OVERFLOW (+ l reserve) _ ersatz) k)` revealed the critical limit for this task before `k`.

## How precisely could the parser locate the defect?

For the separate diagnostic measurement, I deleted exactly one value operand at every possible location in the six intact source programs. The error code and binding symbol of the handler remained fixed. Each of the 37 deletions was repeated in all three views. All 111 damaged programs were rejected.

A hit counts if the first diagnosis names **exactly the original occurrence of the operation** whose direct operand was deleted. Two different additions are thus different locations. The positions of the original were only known to the evaluator. The parser received the damaged text.

| Location of deletion | Unbracketed | With a marker | Fully bracketed |
|---|---:|---:|---:|
| Direct operand of the marked operation | 3/8 | **8/8** | 8/8 |
| Deeper within the marker | 4/16 | 4/16 | **16/16** |
| Outside the marker | 9/13 | 9/13 | **13/13** |
| **Total** | **16/37** | **21/37** | **37/37** |

For K5, the valid probe should yield `roh + offset`, otherwise the last value. After deleting `offset`, these diagnoses resulted:

| View | Damaged body | First diagnosis |
|---|---|---|
| Unbracketed | `pair if gueltig + roh letzte + zaehler 1` | Argument 2 of `pair` is missing at the end. |
| Around the first component | `pair (if gueltig + roh letzte) + zaehler 1` | Argument 3 of `if` is missing at the bracket. |
| Fully bracketed | `(pair (if gueltig (+ roh) letzte) (+ zaehler 1))` | Argument 2 of `+` is missing at the inner bracket. |

In the middle line, the parser reads `letzte` as the second addend. The outer bracket here limits the search to the first component, although it misses the affected call. At K6, the marking was around the healthy right component. There, bracket-free and local views only reported the incomplete outer pair at the end.

**Post-check with shifted selection.** After the main evaluation, I set the same single bracket to the addition at K5. In `pair if gueltig (+ roh) letzte + zaehler 1`, the parser named the addition directly. At K6, `pair (+ grund) if aktiv + neu bonus neu` led to the same result. In both post-checks, I already knew the error location. A procedure that selects the correct operation itself was not tested here.

Even a precise operation diagnosis leaves the missing information open. Both from `(< limit x)` and from `(< x limit)`, after removing `limit`, the text `(< x)` results. For the technically correct repair, the original operand side makes a difference.

## Length and Design Decision

| Tokenizer | Texts, each six function bodies | Bracket-free | One marking | Fully bracketed |
|---|---|---:|---:|---:|
| o200k_base | Original texts | 75 | 86 | 100 |
| o200k_base | My first submissions | 99 | 109 | 132 |
| cl100k_base | Original texts | 77 | 88 | 102 |
| cl100k_base | My first submissions | 101 | 111 | 134 |

A local marking cost ten additional tokens over my six finished function bodies. For TIDE, I would test an adjustable selection as an editor view. When editing the handler, I want to be able to see its boundary, even if the last selected area was the entire price component. For an unresolved syntax diagnosis, the fully bracketed representation in the trial identified every affected call occurrence. An intact revision could help when displaying the intended structure. How the editor finds the appropriate place for unknown defects remains open.

I designed the tasks and expected behavior myself and processed all rounds in the same session. Neither independent first contacts nor search time were measured. The 37 deletions stem from six short trees and concern exclusively missing value operands. The token counts refer to the program texts.

[Tasks and Expected Behavior](aufgaben.py) · [All First Submissions](erstabgaben.jsonl) · [Notes Before Feedback](notes.md) · [Evaluation](versuch.py)

For recalculating in the trial directory:

```sh
sha256sum -c versuchsstand.sha256
sha256sum -c erststand.sha256
python3 versuch.py werten
python3 versuch.py tokens
```

For the functional check, the Python standard library suffices. The token counting additionally uses tiktoken.
