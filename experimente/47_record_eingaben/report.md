# Time to error finding with record inputs

With the booking journal containing 384 entries, the time for `tide test panel.tide --diff --explain=executed` dropped from 22.54 to 17.75 ms (−21.3 %). The prepared CPython comparison required 18.66 ms. All three reported the target value 27 and the actual value 26 for the last balance. Both TIDE packages emitted the same 235 tokens, CPython 259. [Booking example](../46_ergebnisvergleich/ledger/panel.tide) · [Individual measurements and quartiles](messung.json)

## Two new errors across three files each

In the queue, the ticket with the higher priority wins. In case of a tie, the ticket submitted earlier wins. The arrival position lies between 0 and 31. The faulty weighting favors the later ticket when priorities are equal. In the time accounting, ten ticks correspond to one unit. A half unit is rounded up. An interval from 18 to 43 encompasses 25 ticks and should yield three units. The faulty program yields two. [Queue](warteschlange/panel.tide) · [Time accounting](zeitabrechnung/panel.tide)

| Errors and prepared context | TIDE before | TIDE now | CPython | Output tokens TIDE / CPython |
|---|---:|---:|---:|---:|
| Tie, statically | 6.42 ms | 6.31 ms | 16.96 ms | 235 / 241 |
| Tie, actually executed | 6.30 ms | 6.33 ms | 17.07 ms | 246 / 252 |
| Rounding, statically | 6.25 ms | 6.24 ms | 16.98 ms | 216 / 231 |
| Rounding, actually executed | 6.28 ms | 6.30 ms | 17.13 ms | 227 / 242 |

Both tools received the project entry and the example. Their answers contained the deviating value, the input, the record type, and the three involved functions with source position. Both programs have branch-free call paths. The executed view delivered the same functions in each language as the static one and cost eleven additional tokens each. With an identical placeholder for the revision identifier, the token distance between TIDE and CPython was seven at parity and eleven at rounding. Optimizing the read-in brought no discernible time gain for these small inputs.

For the technical recheck, both errors were corrected in separate copies. At parity, 63 of 81 combinations passed before and 81 of 81 after. At rounding, 30 of 42 passed before and 42 of 42 after. For each individual case, both languages delivered matching results before and after the intervention. TIDE took over the reference corrections via the native editor using the revision and node identifier. The errors and repairs were known for this tool measurement. [Acceptance inputs, expectations, and reference changes](messung.json)

## Where time is saved

The JSON reader holds the current container separately and processes adjacent keys, colons, values, and commas with fewer state transitions. For lists of records with integer, boolean, or text fields, the decoder assigns the checked JSON events directly to the declared fields. The assignment checks every name and type. For deviating order, it searches for the field within the same record. Nested field types use the general decoder. [JSON reader](../../native/bootstrap/json_stream.tide) · [Typed decoder](../../native/bootstrap/compound_json.tide)

| Cumulative time including process start | 383 records before / now | 4,096 records before / now |
|---|---:|---:|
| Read file via stdin and provide length | 0.50 / 0.51 ms | 0.77 / 0.79 ms |
| Index JSON events | 3.77 / 2.33 ms | 35.42 / 20.09 ms |
| Index and generate typed values | 5.78 / 3.35 ms | 56.79 / 30.90 ms |

The regular test of the repaired journal dropped from 20.55 to 15.25 ms. A control program that returns 383 records unchanged and checks them against the expectation dropped from 19.63 to 14.25 ms. With an empty list, its median rose from 6.19 to 6.30 ms. The executed diagnosis of a list of simple integers changed from 9.04 to 9.00 ms. A test with 64 records and 48 fields each took 16.08 ms in declared order and 18.97 ms in reversed order. Before, it was 26.64 and 27.85 ms. [Step measurement in TIDE](stufen.tide) · [All control cases](messung.json)

## Measurement conditions and coverage

For the CLI-medians, three warm-up runs and 21 measured calls were executed for the step measurement, two and nine respectively. Each call started a new process on the same CPU core. The order of tools and tasks was varied. CPython time includes startup, project module verification, example execution, and context creation. The executed view records the actually traversed functions. TIDE and CPython responses were fully counted, including line endings, with `o200k_base`. The measurement yields tool times and output sizes. Time and total tokens of a model until repair remain open. [Previous attempt and external comparison](../46_ergebnisvergleich/report.md) · [Raw data and comparison sources](messung.json)

Public commands were additionally compared in 44 input cases and 28 editor cases before and after the change. Exit status, standard output, and error output matched byte-for-byte. All 26 rejected write attempts left the original file intact. Tests included, among others, swapped fields, Unicode escapes, duplicate keys, incomplete JSON, integer boundaries, and lists with 4.095, 4.096, and 4,097 entries. For wide records, values of all fields were also checked in three orders. The native test suite, the typed comparison cases from attempt 46, and the isolated rebuild with package verification without Python passed. [Persistent comparison of decoders in TIDE](../../native/bootstrap/checks.tide) · [Verification without Python](../../native/bootstrap/no-python.Dockerfile)
