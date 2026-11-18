# Maximum value and first occurrence as a native pair

In the measurement series `−8, −2, −2`, an agent shall return the maximum value and its first line. Before the edit, the native type check and the example test for this fold ended with `E_BACKEND`. Now, the installed project analyzer `{"some":[-2,2]}` delivers. The file entry and the public call for already read lines use the same TIDE computing core. [Application](../../apps/first_peak.tide) · [Computing core with three examples](../../apps/peak_lines.tide)

```sh
./tide run apps/peak_lines.tide --call peak_lines --inputs '{"rows":["-8","-2","-2"]}'
./tide test apps/peak_lines.tide --explain
```

A regular function can use a pair of two base values. All nine combinations from `i`, `b`, and `t`, as well as options around these pairs, function as parameters, intermediate results, and return values. The checker knows the component type at each `first` and `second`. Thus, the type can be queried at the same node, an expression replaced, and the confirmed examples re-executed. Pairs with composite components, lists of pairs, pair results from rules, and the direct ELF build for these functions are still open. The named read permission of the file entry also requires a native implementation. [Language reference](../../LANGUAGE.md)

## Runtime from call to result

| Task | Count | TIDE with regular evaluation | TIDE with direct pair access | Standalone CPython program |
|---|---:|---:|---:|---:|
| Count negative and remaining numbers | 16 | 5.75 ms | 5.75 ms | 9.38 ms |
| Count negative and remaining numbers | 4,096 | 51.98 ms | 37.06 ms | 9.49 ms |
| Find maximum value and first line | 16 | 6.22 ms | 6.16 ms | 9.24 ms |
| Find maximum value and first line | 4,096 | 69.24 ms | 60.86 ms | 9.93 ms |

If an operand directly reads `first totals` or `second totals`, the analyzer fetches the component from the bound variable. It saves an evaluation frame. Both visited expression nodes still burden the work budget. If exhausted after the first node, the diagnosis points to the variable. For more complex operands, TIDE uses the regular path. [Implementation](../../native/bootstrap/function_run.tide)

With 4,096 inputs, direct access was faster in both tasks in each 21 of 21 pairs. The median saving within the pairs amounted to 14.85 ms for counting and 8.38 ms for the maximum search. The large balance without pairs required 7.08 ms in the original package, and 7.16 ms after the extension. CPython had the shorter runtime with both direct applications for the large inputs.

Each table cell is the median of 21 individual invocations after three warm-up rounds. The three conditions ran on the same logical processor core with varying start positions. Each invocation started a new process and received the same prepared JSON input text. Measurement continued until process termination; each output was verified. TIDE ran via the installed `tide run` including source verification. CPython started with `-I -S`, read the arguments, executed the domain calculation, and output JSON. The CPython and TIDE programs used for measurement, all timings, checksums, and input sequences are in the [Measurement Data](messung.json).

## Correctness and Limits

- 184 comparisons at the public command matched the historical language reference in output and exit status. They covered type combinations, swapped components, options, Unicode, i64 limits, incorrect types, faulty JSON, formatting, and node queries. The native side ran in its own mount namespace without Python. For nine example contracts, the SHA-256 value was calculated independently. An edit in the imported module subsequently passed the tests. A further write attempt with the consumed revision yielded `E_REVISION`.
- For 16 input texts, the original file entry, the refactored file entry in the historical reference, and the native compute core matched. The cases included CRLF, equalities, empty lines, both i64 limits, and invalid numbers. For input errors, code, reason, input line, and source line were compared. The error-triggering number conversion now resides in the imported compute core.
- The permanent test suite constructs 4,096 optional pairs, each with two texts of 58 code points. This consumes exactly 4,194,304 guest budget bytes. The next pair formation yields `E_LIMIT`. A separate test checks the four exhaustion points in the operands of `+ (first v) (second v)`. [Boundary Tests](../../native/bootstrap/checks.tide)
- 553 existing text comparisons, 77 resource cases, and 1,041 node edits passed. For nine node edits, the historical reference produced no comparison output. The expected source bytes were determined independently. The clean rebuild and verification of the installed package passed via `make check-no-python`. [Build Check](../../native/bootstrap/no-python.Dockerfile)

This experiment measures the runtime of finished programs. Token consumption and repair time of a model were not collected in this cycle.
