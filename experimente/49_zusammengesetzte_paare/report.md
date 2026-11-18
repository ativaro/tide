# What repair context does an agent need?

For two new multi-file errors regarding equality and rounding, the three statically reachable functions sufficed. The executed view showed the same functions for both, plus the selected branches. The Nano editor exhibited the counterpart there. There, the executed context omitted several unrelated functions and nearly halved the output. [Individual measurements and complete tool responses](messung.json)

## Two new errors with prepared context for both languages

In the offer selection, an equally priced challenger displaced the existing offer. Both tools found the name A instead of B at the result path `/0/name`. In the conversion to tenths, a half-step should go to the even number. For −25, the faulty function yielded −3. Both tools reported the target value −2 at `/1`. Both started at the project entry with the same examples and received the error position only through evaluation. [Offer selection](gleichstand/panel.tide) · [Rounding](rundung/panel.tide)

| Error | View | TIDE output tokens | CPython output tokens | TIDE to finding | CPython to finding |
|---|---|---:|---:|---:|---:|
| Equality | static | 261 | 288 | 6.40 ms | 16.84 ms |
| Equality | executed | 281 | 307 | 6.35 ms | 16.92 ms |
| Rounding | static | 307 | 319 | 6.70 ms | 17.14 ms |
| Rounding | executed | 376 | 383 | 6.75 ms | 17.24 ms |

Both tools provided input, deviation, revision, involved types, and function bodies with positions. The executed views additionally contained the actually selected branches. In case of a tie, the TIDE output increased by 20 tokens due to rounding by 69. The CPython comparison aid loads the example modules, reads their syntax tree, and traces the executed lines in execution mode. This time includes this setup on every process start. In the compact results, there are sometimes only seven tokens between the languages. Function notation, source positions, and the respective own revision hash are factored into these numbers. [Comparison aid and source code](messung.json)

The known corrections were applied via the TIDE node editor in a project copy and in the external Python comparison. Subsequently, both passed the embedded examples and a check against independently calculated target values for 25 offer pairs and all 83 integer temperatures from −41 to 41. The two projects linked here intentionally contain the faulty version. An example call from the project root reads as follows.

```sh
./tide test experimente/49_zusammengesetzte_paare/rundung/panel.tide --diff --explain
```

## Nano via the normal project entry

A key press in Nano yields a pair of `Buffer` and `Effect`. In the previous native package, the public Nano test ended with `E_BACKEND`. Now, the same editor logic and its cursor routines run via `tide run` and `tide test`. The test module additionally processes a list of keys and save feedback. A `store` requests saving. The caller returns the result with `stored` or `io_error`. After `finish`, playback ignores further events. Interactive terminal and real document accesses remain open. [Nano in TIDE](../../apps/nano.tide) · [Playback and ten examples](../../apps/nano_checks.tide)

Ten events comprised Unicode input on two lines, cursor movement, a failed save attempt, and the subsequent termination. All variants delivered the same complete end buffer and the action `finish`.

| Call | Processes | Time to end state | Output tokens |
|---|---:|---:|---:|
| Native TIDE, initialization and each step individually | 11 | 111.40 ms | 568 |
| Native TIDE, same events in a single call | 1 | 12.38 ms | 54 |
| Historical TIDE interpreter, a single call | 1 | 33.52 ms | 67 |

In the single variant, the tools output the buffer after each event. The batched call delivers only the final result. Whoever seeks the first incorrect intermediate stage can play the same sequence step by step. [Events and outputs](messung.json)

On a third, intentionally introduced error, Nano switched to the wrong mode upon termination with unsaved changes. The finding named `/0/mode`, expected `confirm_exit`, and found `writing`. The pure deviation cost 50 output tokens. The static context with types and function bodies cost 793 tokens at 10.87 ms, the executed context 407 tokens at 10.77 ms. It contained the functions `shortcut` and `stay` as well as the types `Buffer`, `Mode`, and `Effect`. A revision-bound node edit via the importing entry module restored the original file byte-for-byte. Subsequently, all ten Nano examples passed.

## Costs of composite pairs

The native evaluator fully types both components and uses the existing representation of nested values for composite pairs. Primitive value pairs retain their compact representation. For the frequent form `&{Cursor}{Outcome}`, the evaluator determines the boundary of the first component directly at the closing parenthesis of the type name. For a pair as the first component, it continues to follow the structure of the type. [Type checking](../../native/bootstrap/functions.tide) · [Value representation and size calculation](../../native/bootstrap/value_tree.tide)

For the following calls, both programs read a JSON-list of pairs from cursor and status and returned all cursor positions. The external CPython program checked the fields, types, and variant names of these inputs.

| Number of pairs | TIDE before direct boundary determination | TIDE afterwards | Direct CPython |
|---:|---:|---:|---:|
| 1 | 7.22 ms | 7.17 ms | 9.45 ms |
| 64 | 8.65 ms | 8.52 ms | 9.52 ms |
| 256 | 12.91 ms | 12.43 ms | 9.69 ms |

The output tokens were identical for all three tools. For the largest dataset, the specialized CPython program was faster. Valid inputs of these three sizes were measured. CPython does not perform TIDE project prechecks or guest budgeting. [TIDE-program](../../native/bootstrap/fixtures/functions/composite_pairs.tide) · [Input construction and external Python version](messung.json)

## Acceptance and measurement procedures

The nine public pair examples and the ten Nano examples passed natively and in the archived reference interpreter. 48 additional type combinations yielded the same values in both evaluators after swapping both components. All 14 Nano inputs were compared with the reference in both modes. Six invalid JSON inputs, five deviation paths, and five type errors were checked via the public entry point. A persistent TIDE boundary test constructs 4,096 pairs with two logically counted copies of the same record each. Exactly 4 MiB of guest allocation exists; another pair reports `E_LIMIT`. The complete rebuild, tests, and package check including an upgrade passed in a container without Python. [TIDE-boundary tests](../../native/bootstrap/checks.tide) · [Isolated build](../../native/bootstrap/no-python.Dockerfile)

The tables list medians from 21 sequential tool calls after three warm-up rounds on a fixed CPU-core. The order changed per round. The total tool output, including line endings, was counted with `o200k_base`. The historical TIDE interpreter and the standalone CPython comparisons ran outside the TIDE tool chain. There were no isolated or blind model sessions. Thus, the total tokens of an agent and its time until self-found repair remain unmeasured in this trial. [Individual times, quartiles, software versions, and checksums](messung.json)
