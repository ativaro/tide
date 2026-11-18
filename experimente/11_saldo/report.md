# Balancing program: TIDE versus CPython

Measured on 16 November 2026 on a AMD Ryzen 9 9950X3D under Linux x86-64. The task was identical in both languages. Starting from 100, the postings −20, +15, −8, and +10 are applied in sequence. The result is 97. Each individual step must fit into a signed 64-bit integer. A temporary overflow is also an error even if a later posting would offset it.

## Runtime

| Measurement | Native TIDE | CPython 3.14.10 | Factor in favor of TIDE |
|---|---:|---:|---:|
| Start program, post four times, output `97`, terminate process | 0.166 ms | 6.737 ms | 39.2× |
| Time per balance in repeated run, four postings | 0.837 ns | 146.94 ns | 174.3× |

The time columns are medians. For the factor, Python was divided by TIDE within each round, and then the median of the quotients was formed. The middle 50 % of factors were between 36.3× and 41.2× for the single call and between 151.7× and 210.2× for repeated calculation. The TIDE reference interpreter needed 32.858 ms for the complete single call in the median. Creating the native file from the source code once took 37.249 ms. [Raw times](laufzeit.csv)

**Single call.** 51 rounds after five warm-up rounds. Each round contained the unchanged native balancing program, the CPython script, and `./tide run apps/balance.tide`. The six possible call sequences were varied. The Bash timing included process start and output after `/dev/null`. Measurement was performed with a warm file cache on the logical CPU 2. The Python function from the write attempt ran under normal CPython startup without additional packages. The small program entry passed the same literals and produced `OverflowError` on the same CLI error message. At all ten acceptance cases, stdout, stderr, and exit status were compared for both executable programs. [Acceptance cases](faelle.txt) · [Python function](schreiben/balance.py)

**Repeated Run.** The native compiler is a prototype for folding over embedded i64 data. For throughput, I added a counted outer loop in a temporary copy of the TIDE emitter. Each iteration resets the starting balance, pointer, and booking counter. The original computation loop including overflow check runs fully. CPython calls the verified function per iteration with the same reused list. Both processes output only the final balance. Per round and language, 1,048,576 and 2,097,152 complete balances were computed. The time per additional balance is the difference of the two process times divided by 1.048.576. 31 rounds after two warm-up rounds, with size and language order swapped. This measures the throughput of a hot loop including repetition costs. For a single balance with new inputs, the nanosecond count is not a latency measurement. [TIDE measurement patch ](stapel.patch)]

The unchanged ELF program is 411 bytes large and has SHA-256 `cdc5a3f33cc9bd46a07d760bc81a42818f209fb5df29f7f801289cb0225e4ef2`. The TIDE function from the isolated write attempt with the repository entry point yielded byte-identical the same ELF. In a technical precheck, the Python-CLI entry point lacked translation of an exception into the agreed JSON error message. After adding this error path, the entire time series was measured again. In the precheck, the paired median factors were 40.4× and 168.1× respectively. [Precheck ](vorlauf.csv)]

## Writing and Repairing

| Order | Source code tokens of the submitted function | CLI input, from cache | CLI output | Total | Start to passed test |
|---|---:|---:|---:|---:|---:|
| Write TIDE | 20 | 78.259, of which 70,272 | 403 | 78,662 | 13.225 s |
| Write Python | 72 | 58.124, of which 50,304 | 217 | 58,341 | 7.376 s |
| Repair Python | 50 | 77.732, of which 69,632 | 146 | 77,878 | 7.294 s |
| Repair TIDE | 19 | 77.796, of which 69,760 | 159 | 77,955 | 9.278 s |

The total is the input plus output of the entire turn reported by Codex-CLI. It includes repeatedly passed context, tool results, and the final message after the test. Cache tokens are already included in the input, indicated thought tokens in the output. Subtracting cache hits leaves 8,390 tokens for TIDE and 8,037 for Python when writing. The separately counted source code tokens use `o200k_base` and include exclusively the submitted function. TIDE checks for overflow already as a language operation. The submitted Python function checks the value range explicitly. [Complete orders, tool events, timestamps, and usage counters ](modell.json)]

Four fresh, sequentially started `codex exec` sessions used `gpt-6-astra`, Reasoning level `xhigh`, and requested service class `priority` in the CLI 0.157.1. Each session saw only its task and its working folder. Hooks, reminders, and plugins were disabled. The order was TIDE write, Python write, Python repair, TIDE repair. During writing, the model received an empty file, the same domain task, and a brief language-specific hint. During repair, each source file contained exactly the same sign error. In the TIDE version, `- total entry` stood, in the Python version `total -= entry`. Both tasks named the symptom "103 instead of 97". The location and cause were not in the task.

Each session read the file, changed it once, and invoked the independent checker once successfully. The ten fixed cases included the visible example balance, empty list, zero, mixed postings, both valid i64 limits, and positive, negative, and transient overflow. TIDE ran the cases as language examples. The Python checker used the same JSON data and treated only `OverflowError` as overflow. The clock ran from the start of the respective Codex process until the first success of the checker. Thus, it includes model response time and tool latency. Search and processing were measured together. The first inner time point at which the model recognized the cause is not observable. [Repaired TIDE](reparatur/balance.tide) · [Repaired Python](reparatur/balance.py)

For the four constant postings, the native throughput exceeded the 100× target. At program start, at model consumption, and at repair time, it was missed in this experiment. One model run per condition and a single easily localizable defect are insufficient to estimate a language-induced advantage or disadvantage in debugging.

## Post-measurement

For single start, use the [native build commands](../../native/README.md). CPython calls in a copy of the submitted function `print(balance(100, [-20, 15, -8, 10]))`. Its CLI entry catches `OverflowError`, writes `{"code":"E_OVERFLOW"}` with newline to stderr, and ends with status 1. The batch version binds the same list once, calls `result = balance(100, entries)` in a loop `for _ in range(N)`, and then outputs `result`.

For the native batch, copy the TIDE compiler files from `native/` into a temporary directory and run `patch -p1 < …/stapel.patch` there. Compile the first version over the existing balance program. For the second, set the constant `batch_repetitions` to 2,097,152 and compile again. Both versions deliver `97`. The SHA-256 values of the measured binary files are `caa8bf028621f185df716fdf66e3083f64e6e18dd232eafa6adf948adaf7047e` and `22a04c2ba53461d7628332419cf4e7878b24d4219178a70f54fe40bb5633ef1a`.

The measurement shell ran under `taskset -c 2` with bash 5.3, `TIMEFORMAT='%6R'`, `LC_ALL=C` and stdin/stdout of the timed programs `/dev/null`. Expenditure was compared outside of timekeeping. The CSV files contain seconds. Negative lap numbers mark warm-up runs, lap numbers from zero mark the evaluated runs.
