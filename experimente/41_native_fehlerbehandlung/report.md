# Handling errors from an imported module

The installed starter produced error `E_BACKEND` for a valid program with `catch` before this change. Now, the native project evaluator can catch an error in the caller, read its cause and its data line, and pass on the original diagnosis with `raise`. `check` calculates the externally possible errors even if the same function is called at multiple locations inside and outside a handler. `hole` shows the local diagnosis name and, at a failing expression, the expected replacement type. [Evaluator](../../native/bootstrap/function_run.tide) · [Type and error check](../../native/bootstrap/functions.tide)

In the application example, `first_invalid` checks a list of measurement lines using the imported parser `reading`. Known conversion errors yield the first invalid line number; other reasons are passed through. The control version checks with `int` and two option branches, remembering the first hit in the folding accumulator. Both yield the same JSON answer for the measured inputs. [Application](../../apps/reading_check.tide) · [Parser](../../apps/readings.tide)

## Runtime until result

| Line | First invalid line | TIDE prior, option | TIDE now, option | TIDE now, handler | CPython |
|---:|---:|---:|---:|---:|---:|
| 16 | none | 5.31 ms | 5.22 ms | 5.90 ms | 9.08 ms |
| 4,096 | 1 | 15.71 ms | 15.36 ms | 10.57 ms | 9.36 ms |
| 4,096 | 2,048 | 20.49 ms | 20.40 ms | 20.81 ms | 9.50 ms |
| 4,096 | 4,096 | 25.39 ms | 25.46 ms | 31.02 ms | 9.64 ms |
| 4,096 | none | 25.47 ms | 25.45 ms | 31.07 ms | 9.67 ms |

On an error in the first line, the handler terminates folding immediately. For valid lines, it calls the imported parser for each line. The option version checks directly in the loop body. The difference between these applications encompasses both differences. For comparison with the first installation, the same handler program and the same option version were additionally executed with an intermediate version. For 4,096 valid lines, it required 33.38 ms for the handler and 27.49 ms for the option. The final version marks diagnostic operations during parsing. When reading already bound operands, it can directly access the existing environment. This saves for the handler in the paired median 2.33 ms compared to the first installation. For balance with 4,096 entries, the medians of the initial and final states were 7.060 and 7.062 ms.

All values are medians of 21 new processes after three warm-up rounds on the same CPU core. The start order of the conditions changed. The clock ran from process start to end; each output was checked. TIDE ran via the installed entry including source and input checks. The external CPython ran with `-I -S`, checking input format, list boundary, decimal sign, and i64 range on the same measurement data. The measurement captures neither model tokens nor the time of an agent during repair. [Individual measurements, sources, and checksums](messung.json)

## Correctness

34 additional call scenarios ran with the installed TIDE package in its own namespace without Python. They included unsuitable trader codes, the visibility of the diagnosis, errors in the replacement, nested forward throwing and the event number of a rule error. A direct error in the imported parser and the same error after further throwing delivered byte-like stderr. An incorrectly typed appeal argument was rejected before the trader as `E_INPUT`. A separate repair run delivered via `test --explain` both participating functions. A revision-related change to the reason for the error in the imported module allowed the example to pass again. [Diagnosis and repair](messung.json)

The permanent test suite checks the exhaustion of the work budget precisely at the next node in the substitution. It also consumes a total of 4,194,304 guest budget bytes in 4,096 discarded expressions and requires `E_LIMIT` for the next allocation. The clean Debian build without Python, with a complete test suite, package switch, and separate runtime image, passed. The executable line check uses `tide run`. The direct ELF compiler does not yet cover this program entry point. Handlers and static error analysis are available for `E_IO` and `E_UTF8`. Errors when reading granted files are only checkable with a native implementation of this file operation. [Budget tests](../../native/bootstrap/checks.tide) · [Package check](../../native/bootstrap/no-python.Dockerfile)
