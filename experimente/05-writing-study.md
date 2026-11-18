# Writing test · Trial conditions before evaluation

I write eight new state programs from four pairwise similar task families. Each twin has its own field names and a different assignment of the four command numbers. Event 0 leaves the old state intact. The reported output is, in both forms, the pair of both fields after each event. The first four tasks alternate between rule and function. In the second half, the assignment per family is reversed. Both versions use the same TIDE expressions.

For each task, I see the order of fields, the initial state, and an example step. I submit exactly one complete TIDE rule or a normal TIDE step function (two old field values and event as parameters, new state as a pair). The test driver provides the function with its initial state. The tasks and the Python reference are fixed before submission. Before submission, I see no evaluation of my programs. I know and design the task families myself.

Evaluation is first per program: complete and correct on all event sequences of lengths 0 to 6 on the first attempt. Within a sequence, every intermediate output counts. For errors, we consider the first deviating transition and the affected field. We also record the tokens of the written programs. Time, internal thought tokens, and general model performance are not measurement metrics.

## My immediate impression after writing

With `spiel`, I could write "book and reset bonus to the initial value" directly with `bonus=reset`. With `konto`, I had to insert the matching initial number 1 in the second position of the return pair. The field name in the table helps me when cross-checking. For the swap in `karte`, I found `pair saved position` easier to overview than two named assignments. With `etappe`, splitting into multiple conditions cost me attention; I had to think about the state logic in both forms. These observations were saved before the first test run.

## Result after the first test run

| Metric | Normal TIDE step functions | Rules with `keep`, `set`, `reset` |
|---|---:|---:|
| Fully correct first solutions | 4 of 4 | 4 of 4 |
| Passed event sequences, all intermediate steps compared | 78,124 of 78,124 | 78,124 of 78,124 |
| Complete submissions, `o200k_base` | 261 tokens | 427 tokens |
| Complete submissions, `cl100k_base` | 264 tokens | 427 tokens |
| Only bodies, both encodings | 216 tokens | 334 tokens |

Each form contained a task for position markers, reservations, bonus bookings, and a pausable step counter. Per task, all 19,531 sequences from five events up to length 6 were checked. No correction or second submission was needed. The sequences are systematic test cases for eight programs, not independent writing attempts.

**What the evaluator could detect.** After evaluation, I intentionally altered copies of the solutions. A mistakenly reset memory value was detected in both position tasks after two events. A bonus left standing after booking was also detected in both booking tasks after two events. Omitting the action for a field was already recognized during the table structure check.

**What I infer from this.** The observed advantage of `reset` was local to me: When writing the booking, I did not have to re-enter the bonus start value. The normal function was also correct with a fixed start value. When swapping the two old values, I found the return pair easier to overview. The explicit fields and `keep` made the completeness of a line visible, but extended the function bodies in my submissions by about 55 %. For new rules of this size, I manage just as well with normal functions. The result does not justify a mandate for rule tables.

**Limits.** The rule contains a start declaration and output projection; the function receives its start state from the test driver. Therefore, additionally, the function bodies without header lines and for rules without declaration and `out` are listed. The overall forms, including named actions and case structure, were compared. Whether a single keyword causally helps was not isolated. I designed the task families and references myself and wrote both forms in the same chat. Order and numbering change, but related solutions could still have helped me with the second task. The question remains open for later changes to start values or when getting familiar with foreign code.

The [first solutions](05-initial-solutions.md) in the [archived original version](versuche_vor_umbenennung.tar.gz) were held out under SHA-256 `ca0188807cd4e1c4cf17d40c24225d663b8b5572e02853e4f5d58a3ea71b8c96`. The [task generator with reference](05_aufgaben.py) and the [checker](05_werten.py) work locally. The checker evaluates only the expressions required for this trial.

```sh
python3 experimente/05_aufgaben.py
python3 experimente/05_werten.py
```

For the optional counting of source code tokens, additionally `tiktoken` is required:

```sh
python3 experimente/05_werten.py tokens
```
