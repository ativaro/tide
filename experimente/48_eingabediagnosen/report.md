# What input must the caller correct?

The journal expects under `opening.rows` bookings with the two integer fields `sequence` and `balance`. Previously, `tide run` reported parameter `opening` and type `{Ledger}` for a wrongly typed booking. Now, the same call additionally provides this information when there is text in the balance of the last of 4,096 bookings.

```json
{"issue":{"path":"/opening/rows/4095/balance","expected":"i","actual":"string"}}
```

The path starts at the passed JSON root and counts list positions starting from zero. It can be applied directly to the original input. The finding indicates the value type. The content of the erroneous text remains with the caller. Under `test`, the corresponding example path starts at `/inputs`. Erroneous events and type-inappropriate target values refer to `/events` and `/expect`. [Project entry](panel.tide) · [Types](types.tide) · [Language reference](../../LANGUAGE.md)

A short example for the second list entry can be executed in the checkout. The command ends with status 1 and mentions `/opening/rows/1/balance`. With the integer `26` as balance, it yields the list length `2`.

```sh
./tide run experimente/48_eingabediagnosen/panel.tide \
  --inputs '{"opening":{"rows":[{"sequence":1,"balance":21},{"sequence":2,"balance":"26"}]}}'
```

## Time until response

| Input | TIDE previously | First draft with path | TIDE now | Prepared CPython check |
|---|---:|---:|---:|---:|
| 384 entries, last balance as text | 9.41 ms | 12.16 ms | 9.42 ms | 11.06 ms |
| 4,096 entries, first balance as text | 32.71 ms | 52.97 ms | 32.48 ms | 12.71 ms |
| 4,096 entries, last balance as text | 42.89 ms | 72.45 ms | 42.37 ms | 13.29 ms |
| 4,096 entries, last balance missing | 32.63 ms | 63.49 ms | 33.05 ms | 13.28 ms |
| 4,096 valid entries | 47.96 ms | 46.92 ms | 47.24 ms | 13.38 ms |

The first draft reconstructed the erroneous parameter and reprocessed it for diagnosis. In the measured final version, the Record-Decoder passes the already reached line forward. The diagnostic reader sets the existing JSON-index there. In case of differing line width, TIDE first checks the object boundaries and then searches for the affected field within the line. If an input contains multiple errors, the path denotes a place to be corrected. [Record-Decoder](../../native/bootstrap/compound_json.tide) · [Path and Value Type](../../native/bootstrap/input_issue.tide)

CPython received an external check written specifically for the two journal types. It parses the same JSON-arguments, checks the lines and i64 fields in the measured cases, and performs the length query upon success. TIDE loads the declared types of the project and generates typed values upon success. With 4,096 entries, the specialized CPython check was significantly faster. The CPython response cites the same path and the same type annotations. It contains no TIDE-source position. The comparison sources are stored as measurement data. [Comparison Sources and Individual Times](messung.json)

## Tokens and Correction

With 4,096 bookings, the complete TIDE-diagnosis for the last erroneous balance grew from 32 to 55 output tokens. The path, the expected type, and the read value type cost 21 tokens as a separately coded `issue`-object in both languages. With 384 bookings, the TIDE-response comprised 54 tokens. No savings in the total tokens of a model can be derived from these measurements.

With three further inputs containing 1, 384, and 4,096 records, a known integer balance became decimal text upon transfer in each case. The correction step followed the provided path, checked the expected type, and converted exactly that value. Thereafter, the entire input again matched the independently stored reference. The second call occurred in all three cases. In case of a missing balance, the caller would have to obtain the technically correct value elsewhere. [Corrections and Results](messung.json)

## Coverage and Measurement Method

The public tools were tested with 132 combinations of list length, error position, and erroneous line shape. Further 49 tests covered, among others, missing and extra parameters, nested options, pairs, variants, invalid target values, syntax errors, and the rejection of an invalid write candidate. In the tested error cases, the previous finding remained after removing the new field. The rejected write attempt left the source file intact. In the bootstrap, there are additionally 19 permanent TIDE test cases for type diagnosis. [TIDE tests](../../native/bootstrap/checks.tide) · [Input binding](../../native/bootstrap/samples.tide)

Each CLI time is the median of 21 individual calls after three warm-up rounds. All processes ran serially on the same CPU core, with varying order of task and tool. Measurement was from process start to end including output. Token counting uses `o200k_base` including the final newline for the complete response. There were no isolated model runs. The native test suite and the new build with package check without Python passed. [Raw data, outputs, quartiles, and checksums](messung.json) · [Isolated build](../../native/bootstrap/no-python.Dockerfile)
