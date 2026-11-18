# Feasibility study · Native measurement report with file access

The first stage is passed. The installed package reads a granted file, computes the measurement report, and repairs in a project copy an error across module boundaries. The package was built and run on Linux x86-64 without Python. [Acceptance in runtime image](../../native/bootstrap/no-python.Dockerfile)

```sh
printf '%s\r\n' 80 81 98 > werte.txt
./tide run apps/report.tide --read input=werte.txt --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

The repair attempt replaces in the imported module `summary.tide` the comparison `>` with `<`. The diagnosis at the project entry reports `/above`, should 2, is 0. `edit --edits` takes over the correction at node `summary.tide:10:12` with the revision from the finding. Afterwards the file matches the original byte-exactly. All three examples and the call with real file pass.

Acceptance testing covers CRLF, missing grants, and interceptable invalid UTF-8. Locally, it was additionally verified that the same grant can be read twice with exactly 131,072 bytes, two grants totaling 131,073 bytes `E_LIMIT`, and a named pipe with `E_CAPABILITY` is rejected.

## Where time is incurred

Median per process in milliseconds. Measurements were taken on core 2, each with 21 valid runs after three warm-up runs. Each file contained the specified number of lines with `81` and LF. The threshold was 80. All results were verified against the expected output.

| Lines | Installed CLI | Checker directly | Read-only and text length | Checker without reading | Ahead-of-time compiled attempt |
|---:|---:|---:|---:|---:|---:|
| 3 | 4.58 | 1.29 | 1.06 | 1.06 | 0.44 |
| 512 | 13.60 | 10.33 | 1.12 | 1.09 | 0.44 |
| 2,048 | 41.07 | 37.34 | 1.15 | 1.08 | 0.48 |
| 4,096 | `E_LIMIT` | `E_LIMIT` | – | – | 0.54 |

For the first four columns, the same project copy was used. Two additional entries measure `text_len (read input)` and the immediate return of the threshold. Control values include project validation, binding, and process startup. At 2,048 lines, costs are incurred in executing the fold along with calls, records, and options. For small files, the CLI startup dominates.

For the final attempt, the existing bootstrap compiler translated `readings.tide` and `summary.tide` together with a TIDE entry `summarize (lines (read input)) 80` and a JSON output. The statically linked program was built with `-O1`. The measurement includes startup, reading, and output. Translation time was not measured. The attempt only checks the shown valid inputs. It uses internal bootstrap limits and neither public guest budgets nor their diagnostics. The 0.48 ms indicate the potential of direct translation. They are not proof of an equivalent CLI replacement or an advantage over CPython.

The next performance attempt should translate the tested TIDE tree ahead-of-time into operations with fixed types and direct local slots. For the measurement report, direct loops and accumulator updates are particularly interesting. The comparison requires the same output, the same error locations, and the same budget accounting. Setup costs and repeated runtime are reported separately.
