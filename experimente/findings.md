# TIDE · Trials on 16 November 2026

## 1 · Read and modify nested expressions

**Question.** Can I, as a programming model, in this chat read and locally modify a compact prefix expression as reliably as a parenthesized expression with the same operations?

**My impression before evaluation.** For P08 and P11, I mentally reconstructed the boundaries between the inner `if`, the addition, and the outer branch. For P09, I could read the boundaries directly. When modifying, the concrete input with the target value was helpful: I could go through the three possible comparisons using the example. For P12, all three reading samples ran through the same branch. Three checked outputs there do not mean three different paths.

**Execution.** I myself solved all 16 tasks in this chat. For each of the two notations, there were four reading tasks with three given inputs each and four modifications. When modifying, exactly one comparison had to be inverted and the complete body returned. The generator selected a target example that uniquely identified the correct one among three possible modifications and the original program. For this, it compared candidates on all 125 inputs from three integers in the range −2 to 2. Reading tasks required three correct outputs for a hit. There was one attempt per task.

The operations were identical in both forms. Size and nesting were balanced, while the concrete texts and inputs differed. The tasks arrived with a fixed seed 161126 in mixed order. When solving, I saw the tasks, and for modifications, the target example. I started the evaluation run only after saving my [First Answers](01_antworten.json).

| Notation | Read | Modify |
|---|---:|---:|
| Prefix | 4/4 | 4/4 |
| Parenthesized | 4/4 | 4/4 |

**Source code costs.** For this count, the same 16 program trees were output in both forms. Together, they yielded 384 tokens in prefix form and 560 with parentheses. Both previously used encodings (`o200k_base`, `cl100k_base`) produced the same numbers. Only the function bodies were counted. Costs for my reasoning, tasks, inputs, and processing time were not measured.

**Classification.** In these tasks, I succeeded with both forms on the first attempt. When reading, the parenthesized view was sometimes more pleasant for me. I designed the generator myself, knew both tree forms, and worked in the same chat. The cases are short, similar, and pairwise not identical tasks. Four hits per subgroup leave open difficulties with larger or foreign programs.

## 2 · Do I find the crucial follow-up question myself?

For the second attempt, I set two business rules. My task is to name a shortest possible input that distinguishes them. Sequences of length 0 to 4 over the values 0, 1, and 2 are allowed. I note the input and expected answers before a search determines the minimum length.

| Question | My example | My expected answers in the given order |
|---|---|---|
| Length of the longest contiguous strictly increasing or non-decreasing sequence | `[1,1]` | 1 and 2 |
| Largest sum of two adjacent or two arbitrary entries | `[2,0,2]` | 2 and 4 |
| Number of changes to the direct predecessor or number of first-occurring values after the first entry | `[0,1,0]` | 2 and 1 |
| Last value greater than the first or more increasing than decreasing steps | `[0,2,1]` | true and false |

**Result of the search.** All four pre-noted examples distinguished the rules as predicted. The minimum lengths were 2, 3, 3, and 3. My examples achieved them in all four cases. The complete search confirmed the minimality. It did not provide a shorter input nor an unknown interpretation of the task in this attempt. I knew both rules beforehand and selected them myself. What helps with a truly ambiguous task must be tested with an independent client.

## 3 · What happens to a clear rule after a short feedback?

The client requested an alarm for "three consecutive values above 80 degrees". My initial interpretation matched the rule: each value above 80 increases the length of the running series by one. At 80 or less, the counter resets to zero. My only clarification question used six high values. With this, I asked for further alarms after the third hit. The response "also counten" I subsequently interpreted as a continuous total count. The client explicitly confirmed the original series rule.

**Observation.** My error arose when revising an already correct interpretation. The word "counten" indicates that counting occurs. By itself, it changes neither the counting criterion nor the reset rule. How high the individual hits are above 80 is irrelevant. For the first alarm, only the sequence of truth values from `Temperatur > 80` matters.

| Measurement Sequence | Expected until first alarm | What the case checks |
|---|---|---|
| `70, 81, 95, 82` | Alarm at the fourth measurement | Differently high values jointly form a series. |
| `81, 70, 95, 82` | No alarm | The same four measurement values in a different order. A total count would falsely trigger here. |
| `81, 80, 95, 82` | No alarm | Even the exact threshold value interrupts the series. |

**Hypothesis for TIDE.** If I incorporate a feedback, a stored counterexample to the previous requirement might show me which already agreed rule changes my new interpretation. On the next independent task, it can be checked whether this hint actually helps me. In this case, the repetition of the alarm within a longer uninterrupted series remains open.

## 4 · Pump with state trace, light without

The two rules came from the client. For the simulation, both devices started off. For the pump, the previous state is retained between the limits including 20 and 80. For the light, every movement interrupts the sequence of messages without movement.

I prepared the test generator myself with three possible individual errors each. Seed 2916324528 produced the concrete source variant, the inputs, and the assignment of the trace. When solving, I saw the faulty code, the inputs, and the desired and actual states at the end. Only for the pump did I also see all actual intermediate states. Before a second input sequence, I recorded the first incorrect output step, the cause, and the source code change for both tasks. Afterwards, I noted the expected states for this new sequence. Only then did I start the evaluation. [My answers](03_antworten.json)

| Task | First faulty step and repair | Check after repair |
|---|---|---|
| Pump, with trace | At `20, 50, 20, 50, 20`, the pump was on starting from step 1. The trace narrowed the error down to the startup at exactly 20. Replace the start comparison `<= 20` with `< 20`. | Prediction for `20, 20, 80, 50, 80, 19` correct: five off, then on. All 3,906 sequences up to length 5 over 19, 20, 50, 80, and 81 passed. |
| Light, without trace | With motion, motion, rest, rest, motion, rest, the first error resulted from the code in step 3. The counter was already 1 after the first rest, so `missed < 1` was wrong. Repair: `missed < 2`. | Prediction for motion and five rest reports correct: on, on, off, off, off, off. All 255 motion sequences up to length 7 passed. |

**What helped me.** The trace immediately showed me that the pump started at the first measurement value. The condition in the code revealed why. For the light, it was sufficient to go through one motion and the first rest report at the beginning. I found both errors on the first attempt. This speaks for an attempt with an on-demand retrievable trace for a specific step. A time saving was not measured. There was only one rule per condition, and I knew the possible errors from the preparation. A repetition with swapped assignment would have to use new errors and sequences.

## 5 · Counter-experiment with swapped trace

Light with trace, pump without. For seed 720416888, per rule, the erroneous code line as well as the diagnostic and prediction sequence differ from the first run. The rules, disabled initial states, error selection, and evaluation stem from the same generator. I saved the diagnosis and edit before displaying the second sequence, and the state prediction before evaluation. [My first answers](04_antworten.json)

| Rule | Observation during diagnosis | Result of the repair |
|---|---|---|
| Light, with trace | The sequence began with rest, motion, rest. The actual states from light and rest counter were `(aus,1) → (an,1) → (aus,2)`. At step 2 the light was still correctly on, but the motion left the rest counter at 1. Only in step 3 did the visible output deviate. Repair: Set the counter to zero on motion. | On the new sequence motion, rest, motion, motion, rest, motion, the light stayed on as predicted six times. All 255 sequences up to length 7 passed. |
| Pump, without trace | Inputs `20, 50, 50, 19, 80`; at the end the pump was off, expected on. For my diagnosis, 19 and then 80 were sufficient: At 19 it starts. Exactly 80 has no switching effect. In step 5 the code fell back to `return False`. Repair: Return the previous state in the hold area. | Prediction for `50, 80, 19, 20, 80, 20` correct: twice off, four times on. All 3,906 sequences up to length 5 over 19, 20, 50, 80, and 81 passed. |

**What helped me this time.** With the light, the internal counter made the cause visible before the visible error. With the pump, I could reconstruct the last set switch state directly from the rule using two values. My working hypothesis for TIDE is now more concrete: If an output depends on a hidden state, I want to see its value before and after the decisive event if needed. The success rate was equal in both runs. I knew the error catalog; I did not measure time.

## 6 · Write state rules yourself

Four new task pairs. Both the four normal TIDE step functions and the four rule tables passed all checked sequences on the first try. For the function bodies, I needed a total of 216 and 334 source code tokens respectively. For a booking, the explicit reset to the start value helped me; for swapping two values, the function was more direct. I did not observe an advantage for the correctness of my first solutions here. [Attempt, Submissions, and Evaluation](05-writing-study.md)

## 7 · Change bonus start value from 1 to 3

In the writing attempt, the number 1 appeared in the normal function when booking. For this maintenance test, I gave both versions the same immutable definition `bonus_start` ahead-of-time, the same field names, and the same event codes. The normal function uses `pair + total bonus bonus_start` when booking. In the rule, the field start is declared as `bonus:i=bonus_start`, while the booking branch contains `bonus=reset`. Both start with account balance 4 and the same named bonus. The limited precheck sets the name to the same value when loading in both versions. A named constant in the state initializer is a test assumption here; Draft 0.3 currently expects a literal at this point. [Both Versions](06_bonusstart.tide) · [Evaluation](06_bonusstart.py)

**Procedure.** First, both prepared versions with start value 1 each passed 19,531 sequences. Before the second evaluation, I fixed on a single edit: replacing 1 in the common definition with 3. For two direct bookings, I predicted `(7,3)` and `(10,3)`. The pre-hash of the test program was `069565cd82d588e8992b1192a88934e06f25e18045cc0b29d1fb6a9425ab2bf8`. Reverting this single edit yields the same hash.

| After the change, starting from account balance 4 and bonus 3 | Expected and observed in both forms |
|---|---|
| Book immediately, book again | First `(7,3)`, then `(10,3)` |
| Book, increase bonus twice by 2, reset account only | `(4,7)` after account reset |
| Then limit bonus to account balance and book | First `(4,4)`, then `(8,3)` |

Both versions passed on the first attempt with a value of 3 for each of 19,531 sequences of five events up to length 6, including the empty sequence and all intermediate states. An intentionally hardcoded 1 in the respective booking branch immediately produced the demonstrable error `(7,1)` instead of `(7,3)` in both forms.

**What helped me when editing.** I had to edit a definition and neither of the two booking branches. `reset` describes the intent concisely. For this change, it neither saved me an edit nor avoided an error I would have made with the named value in the normal function. The single preparation of the two equivalent initial versions counts separately. The comparison measures neither finding the correct location in an external project nor the editing time.

## Traceability

The test runs used Python 3.14.10 and its standard library. They work exclusively with synthetic inputs. The generators provide the tasks and evaluate my separately stored answers.

```sh
python3 experimente/01_schreibweise.py aufgaben
python3 experimente/01_schreibweise.py werten experimente/01_antworten.json
python3 experimente/02_gegenbeispiele.py
python3 experimente/03_zustandsspur.py aufgaben 2916324528
python3 experimente/03_zustandsspur.py vorhersage 2916324528
python3 experimente/03_zustandsspur.py werten 2916324528 experimente/03_antworten.json
python3 experimente/03_zustandsspur.py aufgaben 720416888
python3 experimente/03_zustandsspur.py vorhersage 720416888
python3 experimente/03_zustandsspur.py werten 720416888 experimente/04_antworten.json
python3 experimente/06_bonusstart.py 1 --vorher
python3 experimente/06_bonusstart.py 3
```

**Next open question.** Does a structurally expanded view help me when I need to change an unknown function and recognize the effects at a second caller? For this, new, deeper tasks involving at least two functions come into question. The evaluation should also check previously valid behavior. For the attempt at follow-up questions, a client-defined, hidden expected behavior is more informative than another round with self-selected rule pairs.

## Three notations for twelve new tasks

Four write, change, and repair tasks each reached me in prefix without brackets, fully bracketed prefix, and Python-like expressions on the first attempt. Prefix required the fewest tokens. For the missing summand, only the bracketed diagnosis named the incomplete addition directly. All solutions were created in the same context. [Results per task, diagnoses, and raw data](07_dreiwege/report.md)

## A bracket around the edited operation

For six new change and repair tasks, all 18 first submissions reached me. For 37 systematic single-value deletions, the checker named the affected call without brackets 16 times, with a fixed local marker 21 times, and fully bracketed 37 times. All five additional hits of the local form were immediately adjacent to the marked operation. For a deeper deletion, the marker in the example narrowed the search to a branch. [Test with local bracketing](08_lokale_klammern/report.md)

## When a local change affects a second caller

In the constructed control case, Display and Archive select between two entries. Previously, in case of a tie, the older entry had priority. The new task gives priority exclusively to the newer entry in the Display. The Archive uses the selection indirectly via `archiv_eintrag`. Both entries have the same type.

All three versions passed the type check. Per consumer, the 25 combinations of score values 3 to 7 with two distinguishable identifiers were tested. The change to the shared selection passed all 25 new display requests and failed the archive request in all five ties. If only the already bound arguments of the selection were swapped in the Display, both consumers passed 25/25. The example with two fives and identifiers 11 and 19 distinguishes the domain contracts immediately. [Control case for recalculation](09_aufrufer.py)]

For the planned editor, a testable question arises: Will tracing back call chains plus one existing example per consumer help me choose the correct function before editing? The control case shows which information distinguishes two type-correct solutions. The effect of such a view on my own first submissions is still open.
