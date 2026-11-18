# One model call per function body

In the [Balance test](../11_saldo/report.md), the model read the file, changed it and started the reviewer. Each tool step went back to the model context. This time TIDE prepared the local order and checked the returned printout after replying. Both model inputs contained the same professional contract and TIDE note as before. When repairing, the symptom “103 instead of 97” was given again. The expression in the source file contained the wrong subtraction. During writing, a type-valid placeholder was placed under the predefined signature. In the previous write attempt, the file was empty and the signature was specified in the order.

| Task | Total tokens before | Total tokens now | Until acceptance before | Until the decrease now |
|---|---:|---:|---:|---:|
| Write balance | 78,662 | 19,203 | 13,225ss | 6,817ss |
| Repair of sign errors | 77,955 | 19,117 | 9,278ss | 5,101ss |

The total tokens are input plus output of the entire Codex turn including cache hits. After deducting the cache hits, the counter dropped when writing 8,390 to 7,299 and when fixing 8,195 to 7.213. The output tokens dropped from 403 to 156 and from 159 to 56. The token savings thus depend essentially on whether re-read context is counted. [Orders, replies, usage counters and receipts](messung.json)

### Test set-up

Am 16. November 2026 ran two new, separate `codex exec` sessions, first repair, then writing. Model, reasoning level, requested service class and CLI version corresponded to the previous measurement (`gpt-6-astra`, `xhigh`, `priority`, 0.157.1). Each session ran in its own blank working directory with read access, without reminders, hooks, and plugins. The model got the prepared order via stdin, did not call a tool and returned a printout via `--output-last-message`. The clock ran before the copying and checking of the source file and ended after the successful `tide edit --write`. The creation of the test task was outside of timekeeping in both trials. All [10 unchanged cases](../11_saldo/faelle.txt) passed on the first attempt.

After the model runs, name validation and handling of unusual separators by the tool were added. Both recorded responses were rechecked against the final version. The candidates were byte-identical, and the ten tests continued to pass. Negative samples yielded `E_EXAMPLE` for incorrect balance, `E_TYPE` for a truth value, `E_DATA` for an additional declaration, and `E_REVISION` for an intervening change. In all four cases, the content of the target file was preserved.

Together with the program entry from `apps/balance.tide`, both responses generated the same native file as in the baseline trial (SHA-256 `cdc5a3f33cc9bd46a07d760bc81a42818f209fb5df29f7f801289cb0225e4ef2`). The measurement concerns development effort. One model run is available per task and procedure; the sessions took place at different times. Generalizability to larger functions, multi-stage repairs, and other cache conditions remains open.
