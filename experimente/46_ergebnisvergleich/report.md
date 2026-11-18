# Which part of the result is wrong?

In a booking journal with 384 entries, the imported function `post` reduced the last balance by one. Besides the example position, `tide test panel.tide --diff` reports the deviation in field `balance`.

```json
{"difference":{"path":"/rows/383/balance","expected":27,"actual":26}}
```

In the second project, `store` stored only the ones digit of a measurement value. The finding cites the last list index `/4095`, target value 82, and actual value 2. Both diagnostic paths were checked before the repair. Using the node identifiers from `context` and the revision from the finding, the respective helper function could be corrected via the project entry. Both repairs passed the public example and subsequently 24 additional inputs each, also in the external CPython version. [Booking journal](ledger/panel.tide) · [Measurement capture](tail/panel.tide) · [Checks and raw data](messung.json)

## First finding without function bodies

| Error | Previous TIDE output | TIDE with `--diff` | Time previous | Time with `--diff` |
|---|---:|---:|---:|---:|
| Wrong game phase | 178 tokens | 52 tokens | 19.52 ms | 19.66 ms |
| Last booking | 6,187 tokens | 49 tokens | 22.54 ms | 19.54 ms |
| Last measurement | 16,420 tokens | 48 tokens | 10.09 ms | 7.99 ms |

In the game phase, the remaining fields of both game worlds are omitted. In the journal, 383 correct entries and the correct sequence number of the last booking are omitted. The output names the first deviation. Further differences may become visible after the first correction. The standard command continues to provide the full values.

## Prepared context for both languages

| Error and view | TIDE · Tokens | CPython · Tokens | TIDE · Time | CPython · Time |
|---|---:|---:|---:|---:|
| Booking, static with input and result path | 3,296 | 3,320 | 22.15 ms | 17.35 ms |
| Booking, executed functions and input reference | 235 | 259 | 21.49 ms | 17.86 ms |
| Measurement, static with input and result path | 8,365 | 8,377 | 10.49 ms | 14.23 ms |
| Measurement value, executed functions, and input reference | 185 | 197 | 8.52 ms | 14.53 ms |

The static responses contained the same inputs, the two semantically corresponding function bodies, and the required types. For the executed view, both tools re-evaluated the example. Python recorded the actually traversed project functions with `sys.setprofile`. Both imported computation paths are branch-free. The external comparison tool checks this against the syntax tree. Both responses name the two visited functions and reference the revision-bound example for the large input. Whoever reloads it must additionally compute its tokens and load time. [Libraries, external comparison tool, and complete compact findings ](messung.json)

The actual output contains its own revision hash per language. With an identical placeholder for both hashes, the distance in the executed context was still 18 tokens for the booking and ten for the measurement value. The large gain arises in both languages through the choice of output scope. For the booking, CPython remained faster.

## What contributes at runtime

TIDE compares typed result values. List lengths and option cases are checked before the contained values. In case of a deviation, the checker assembles the path from record fields, option content, and list indices. For the executed context, the evaluator skips writing an input if the number of contained elements already guarantees a boundary for an input reference. The first prototype with the same output required 23.26 ms for the booking and 10.66 ms for the measurement value. [Comparison in TIDE](../../native/bootstrap/value_diff.tide)

For the repaired programs, the time for the regular test run dropped in the journal from 22.18 to 19.44 ms and in the measurement value from 9.78 to 7.88 ms. For the eleven passing game examples, the medians were at 28.61 and 28.90 ms. Whoever demands the full standard output for the faulty journal now requires 22.99 ms compared to 22.54 ms in the previous package.

A control program with the same booking type returned the number zero independently of the input. With an empty list, the call took 5.84 ms, with 383 input records 12.09 ms. A second program returned the unchanged list in the record and checked it against an equally sized target value. It required 5.85 ms with an empty list and 18.39 ms with 383 records. Thus, a large part of the time is already reproducible without booking calculation. The controls include reading in, typing, executing, and checking the respective example project.

## Measurement and Verification

Each time is a median of 21 complete serial CLI calls after three warm-up rounds on core 2 of a Ryzen 9 9950X3D. The start order changed per round. TIDE used the project lockfile and the short filename in the respective project directory. Longer paths in the findings may incur additional tokens. The external CPython calls read the examples via stdin and loaded the two modules from the project directory. The total tool response was counted, including the line ending, with `o200k_base`. No isolated model sessions ran. [Individual times, versions, checksums, and comparison programs](messung.json)

For 64 value combinations, the complete error output was compared byte-by-byte with the previous package, and then the appropriate result was accepted. Further checks included unpacked and packed options, Unicode text endings, event errors with counting starting from one, return values from a subtree, and lists up to 4,096 records. Large inputs were tested directly below, exactly at, and above the reference boundary of 1,024 code points. `make test` and `make check-no-python` passed. When building the extended test suite, the initial compiler reached its previous limit for reading the source file as a single list of lines. It now processes lines in groups. With 4,097 leading CRLF lines and a following function, `tide forms` produced the correctly grouped function in the previous package `line_limit` and in the new package. [TIDE regression tests](../../native/bootstrap/inspection_checks.tide) · [Initial compiler](../../native/bootstrap/seed.tide) · [Isolated rebuild and package check](../../native/bootstrap/no-python.Dockerfile)
