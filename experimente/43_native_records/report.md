# Named fields in the native evaluator

The measurement report now processes a passed list of measurement lines and delivers a record of type `{Summary}`. For 80, 81, and 98 at the limit value 80, the result is `{"above":2,"peak":{"some":98}}`. The project version prior to this cycle reported at the point example from the language reference `E_BACKEND`. Four domain examples check the new calculation core including negative maximum value, empty list, and invalid number line. The file entry delegates to the same core. Its read permission remains open in the native package. [Measurement Report](../../apps/summary.tide) · [Examples](../../apps/summary_checks.tide)

## Repair across module boundaries

In a project copy, the comparison `>` in the measurement report was replaced by `<`. At the public test entry, the result field `above` now showed 0 instead of 2. `test --explain=executed` delivered the schema of `Summary`, the selected branch, and the grouped body from the imported module. `hole` showed the type `b` for the comparison and `{Summary}` for the accumulator. Via the output revision, `edit` corrected the operator. Subsequently, all four examples passed. The grouped body could also be fully rewritten back as a verified replacement, including field names. The repair was a functional test by the test leader. [Finding and Test Result](messung.json)

For a misnamed constructor field, `E_FIELD` names the expected and delivered name as well as the position of the name. For an incorrect field value, `E_TYPE` names the position of the expression, field, expected type, and actual type. Two records with identical fields but different type names are distinguished at a typed handover. The field name is also readable in the node list of `context` for `get` and `with`. [Field Types and Source Errors](messung.json)

## Contract change within a field

In the first record prototype, the switch from `{"some":1}` to `{"some":2}` in a record of an example input yielded the same contract fingerprint. The tested function read only another field, so the example remained green. The editor wrote the change with an empty list of contract changes. The previous fingerprint reconstructed objects only up to a fixed depth.

The new version visits every object key and sorts the keys at each level. For the two values, different fingerprints arise. The editor assigns the same change with `E_CONTRACT`. With `--change-examples`, it accepts it and shows both values in the change log. A mere reordering of object keys preserves the fingerprint. The existing test case for the fingerprint of a simple example remains byte-identical. [Test Values](messung.json) · [Permanent Check](../../native/bootstrap/inspection_checks.tide)

## Runtime

| Public Call | Before Record Support | First Record Prototype | Optimized Evaluator |
|---|---:|---:|---:|
| Two field accesses per step, 4,096 steps | | 26.06 ms | 17.29 ms |
| 1,400 updates, unchanged field with 128 texts | | 8.67 ms | 8.46 ms |
| Measurement report with 512 lines | | 16.99 ms | 15.79 ms |
| Balance with 4,096 entries | 6.67 ms | 6.73 ms | 6.66 ms |
| Balance with four entries | 5.27 ms | 5.24 ms | 5.20 ms |

Each cell is the median of 21 runs after three warmup rounds on the logical core 2 of a Ryzen 9 9950X3D. Measurement was taken from the start of the installed CLI process until its end, including read-in, type checking, and JSON output. Within each task, the order of versions was swapped. Each result was compared with the precomputed value. For records, time comparisons start with the first prototype that yields the same results. [Individual times and binary checksums](messung.json)

With `get` on a local variable, the evaluator can deliver the type-checked field directly to the surrounding operation. The work budget continues to count the field access and reading the variable. With `with`, the logical size of taken fields is reused. The new total value is fully charged to the allocation budget at each update.

The [Field access measurement](project.tide) folds 4,096 zeros and adds the coordinates 2 and 5 respectively. The result is 28.672. In the [Update measurement](update.tide), `labels` contains 128 times the text Ω, `tick` starts at 0. The lines contain 0 to 1.399. The measurement report receives the numbers −250 to −261 as texts with limit 80. The balance control starts at 100 each time and books 4,096 times −1 or the four values −20, 15, −8, and 10.

## Acceptance and Limits

117 native example executions checked Construct, Read, and Update with all 27 supported field types and with empty as well as populated options. Five additional invalid record inputs yielded `E_INPUT`. The persistent budget check constructs a record of 1,024 logical bytes and updates it 4,095 times. Exactly 4 MiB are allowed. Another update yields `E_LIMIT`. The normal test suite and the clean build without Python run the checks. The installed package runs the measurement report in the runtime image. [Budget check](../../native/bootstrap/checks.tide) · [Container check](../../native/bootstrap/no-python.Dockerfile)

The measurement captures the runtime of the native project evaluator. The standalone ELF compiler currently supports other program snippets. Nested records, records as list or option content, and variant values are open in the project evaluator. No new blind model runs were performed for this extension.
