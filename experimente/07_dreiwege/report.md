# Three notations in the self-experiment

On 16 November 2026, I solved twelve tasks once each in parenthesis-free prefix (A), fully parenthesized prefix (B), and Python-like expressions (C). All 36 of my first submissions passed. The form made a measurable difference for the length of these tasks and for error diagnosis with the deleted operand.

## Results per task

A checkmark means that the unchanged first submission compiled and fulfilled all visible and held-out expectations. The number on the right counts the held-out inputs per form. For event sequences, every intermediate value was checked.

| Task | Order | Prefix | Parenthesized | Python-like | Inputs |
|---|---|---|---|---|---:|
| S1 · Sort two endpoints | ABC | ✓ | ✓ | ✓ | 225 |
| S2 · Shift two coordinates | BCA | ✓ | ✓ | ✓ | 2,025 |
| S3 · Check priority for shipping codes | CAB | ✓ | ✓ | ✓ | 240 |
| S4 · Activate voucher and redeem once | ACB | ✓ | ✓ | ✓ | 1,364 |
| A1 · Change common fee function for two callers | CBA | ✓ | ✓ | ✓ | 238 |
| A2 · Change named start and extension value | BAC | ✓ | ✓ | ✓ | 1,363 |
| A3 · Catch overflow only in the inner call | ABC | ✓ | ✓ | ✓ | 3,148 |
| A4 · Reorder simultaneous deletion and increment | BCA | ✓ | ✓ | ✓ | 59 |
| R1 · Restore deleted operands | CAB | ✓ | ✓ | ✓ | 1,575 |
| R2 · Adjust two calls to the new digit | ACB | ✓ | ✓ | ✓ | 225 |
| R3 · Fix confusion between truth value and measurement value | CBA | ✓ | ✓ | ✓ | 450 |
| R4 · Keep the previous entry on a tie | BAC | ✓ | ✓ | ✓ | 900 |

For each form, 4/4 write, 4/4 edit, and 4/4 repair tasks were completed, including the four tasks where this form was first in line. No first submission had a syntax, type, or domain error. There was no second submission. 16 visible examples and 11,812 additional inputs per form were checked by the programs. The three forms were compared on the same inputs.

## What helped me while working

**Write.** When shipping, I could concatenate the conditions in Prefix in the order of the order. This also worked as a Python-like chain. For the coupon, Prefix fit well because the entire result pair followed each condition. For two independent coordinates, I found `pair(first(p) + dx, second(p) + dy)` easier to read against than `pair + first p dx + second p dy`. In both expressions, I had to make the same domain decision: which shift belongs to which field.

**Edit.** All three initial-value submissions consisted of the body `5`. For the fee, a modified function was also sufficient everywhere. For the error handler, the boundary of the change was decisive. Both sums can overflow, but only the inner one has a fallback value. In B and C, I could see that `post` stands outside the handler. In A, I had to trace how many arguments `subtotal` and `catch` consume.

| Form | My first submission for the handler |
|---|---|
| A | `+ catch E_OVERFLOW subtotal x y bad _ x post` |
| B | `(+ (catch E_OVERFLOW (subtotal x y bad) _ x) post)` |
| C | `catch(E_OVERFLOW, subtotal(x, y, bad), _, x) + post` |

**Repair.** For the deleted operand, I gave the same cause in all forms before the feedback: The addition is missing its second argument `delta`. The order and example named the target. Where the respective parser could first detect a problem differed.

| Form | Damaged body | Actual first diagnosis |
|---|---|---|
| A | `if < used limit + used 0` | Column 25, end of input. Argument 3 of `if` is missing. The `0` was read as the second summand. |
| B | `(if (< used limit) (+ used) 0)` | Column 27, closing bracket of `(+ used)`. The addition has one of two operands. |
| C | `used +  if used < limit else 0` | Column 9, start of `if`. The Python expression parser reports `invalid syntax` here. |

With the new signature of `cap`, B and C reported the wrong argument count at the end of the first call, while A reported it at the input end. For the incorrect pair field, all three issued exactly the same type diagnosis. At the tie, the start text was type-correct everywhere. The example with equal points but different identifiers made the technical deviation visible in every form. The diagnoses stem from the post-hoc review of the start texts. All submissions were already saved at this point.

## Token measurement

First counted per task and form, then summed per column. The **input** is the standardized complete task package consisting of work instruction, reference card, order, visible example, signatures, and start text. The **submission** contains the edited function names and bodies, and for R1, the requested cause statement. **Bodies only** is a subset thereof. For repair feedback, zero additional packages were generated. The three rounds shared the conversation flow and tools of the same session. The actual conversation, tool, thinking, and time totals per notation are not attributable from this. The package sums are a reproducible measurement of the experiment texts.

| Tokenizer | Form | Input | Submission | Bodies only | Input + Submission | Per solved task |
|---|---|---:|---:|---:|---:|---:|
| o200k_base | Prefix | 2,675 | 172 | 136 | 2,847 | 237.25 |
| o200k_base | Bracketed | 2,934 | 238 | 194 | 3,172 | 264.33 |
| o200k_base | Python-like | 2,752 | 214 | 177 | 2,966 | 247.17 |
| cl100k_base | Prefix | 2,985 | 174 | 136 | 3,159 | 263.25 |
| cl100k_base | Bracketed | 3,256 | 240 | 194 | 3,496 | 291.33 |
| cl100k_base | Python-like | 3,050 | 216 | 178 | 3,266 | 272.17 |

## Flow and statement boundary

I defined orders, start texts, sampling keys, and a separate technical oracle before the solutions. The precheck output and read back reference trees in all three forms. The known heat, pump, and light logic, as well as thresholds, branched evaluation, a denied read access, and the step budget were passed. The test bench supports the TIDE excerpt examined here. All frontends use the same type checker and evaluator.

I wrote twelve answers in three rounds. The remaining forms came into play for each task only in later rounds. Each of the six form sequences occurred twice. I wrote the bodies myself, without automatically translating the solutions between forms. My impressions and submissions were recorded before evaluation. The four repair tasks began with a deliberately damaged program. Repair attempts **after** my own faulty submission would have been counted separately.

The planned fresh context per submission remained open. Tasks and expected behavior also come from me, and debugging was constrained by tight deadlines. The technical test cases were only evaluated after securing the answers. With twelve short tasks all hitting first tries, I cannot quantify either reliability on unknown foreign code or time savings. For TIDE, I would retain the compact form for short function bodies and further test visible partial expression limits when editing nested calls. The decision on a single standard syntax remains open.

[Tasks](aufgaben.py) · [First submissions in submission order](erstabgaben.jsonl) · [Notes before evaluation](notes.md) · [Independently coded expected behavior](soll.py) · [Original test plan](../07-syntax-study-plan.md)

### Recalculation

Start the evaluation from the project directory using the Python standard library. The token measurement additionally requires `tiktoken` with the two specified dictionaries.

```sh
python3 experimente/07_dreiwege/versuch.py werten
python3 experimente/07_dreiwege/versuch.py tokens
```
