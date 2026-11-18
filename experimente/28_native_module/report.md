# Module resolution without Python

A TIDE project with distributed record and variant declarations can be checked, formatted, and tested with the standard package. `tide modules` also provides import locations and the project version for an application with an incomplete function body. This allows an agent to locate affected files during repair. [Checker](../../native/bootstrap/project.tide) · [Test plan](experiment-plan.md)

## Acceptance test

73 projects each ran through `check`, `fmt`, and `test` in the installed package without Python. In 213 calls, the results matched the reference. Checked were status, output channel, complete JSON including position and revision, and the byte-exact formatted text. The remaining six calls concerned two programs with function bodies. The standard package reported `E_BACKEND` for their complete check in both cases. The module graph was retrievable in both cases. [Test protocol](pruefung.json)

- For nine projects, import locations, read order, and revision were additionally calculated independently. For 42 genuine project entries from applications, libraries, compilers, and the workbench, module names and revisions matched the reference. Import positions were recounted in the respective source code.
- Import and type cycles, invalid UTF-8, FIFO, directory, and symbolic link during import were tested, as well as edge cases for depth, module count, and source bytes, and errors in imported files. A file with 5,000 blank lines and separately stored parts of a CRLF-line end retained their correct source positions.
- Two modules imported the same leaf file. During 64 prechecks, this file was atomically swapped 456 times between two different type declarations. The full results matched the ahead-of-time compiled states in 31 and 33 cases, respectively. Each file is read once. Across independently changed files, there is no common filesystem transaction.
- The three commands passed the additional 510 comparisons on the existing 170-file corpus. 96 valid files yielded identical bytes upon repeated formatting. The grouped representation matched the reference for 1,097 function bodies over 38 inputs, including functions reachable multiple times across different inputs.
- Rebuilding in an empty directory with Python hidden generated twelve application ELF files with the previous SHA-256 values. The self-build, application tests, and the check routine under UndefinedBehaviorSanitizer with enabled library assertions passed. Separately, 35 historical integration tests in the checkout with the reference system passed.

Switching from the compatibility installation to the standard installation removed the interpreter starter, all eleven package modules, and their bytecode. A foreign module and its cache remained intact. A run with a symbolically linked module or cache directory confirmed that the cleanup does not delete foreign target contents. The test used a temporary installation prefix.

## Runtime

Three warmup pairs, then 20 measurement pairs in varying order. The full CLI processed the same path on the same machine. The comparison process was the direct start of the historical TIDE checker under CPython. The factor is the median of pairwise ratios. [Individual measurements and source checksums](messung.json)

| Task for `check` | Native CLI | Reference | Factor |
|---|---:|---:|---:|
| Small type file | 7.28 ms | 30.53 ms | 4.40× |
| Four files with shared leaf | 6.90 ms | 31.02 ms | 4.45× |
| Unknown type in imported file | 6.47 ms | 30.33 ms | 4.83× |
| 64 additional modules | 10.23 ms | 31.77 ms | 3.13× |
| 31 additional modules in a chain | 7.51 ms | 31.02 ms | 4.11× |
| Project with function body, compatibility package | 36.97 ms | 31.15 ms | 0.84× |

The first five groups won all 100 timing comparisons. In the last group, the native precheck and the subsequent reference start together cost around six additional milliseconds.

The measurement of the check process alone showed initially 64 additional modules 5.63 ms. The start compiler now generates i64 literals directly, binds immutable intermediate values by reference, and continues using the private accumulator when directly appending in the `fold`. Type checking sorts name indices stably and determines duplicate variant names in source order. The finished check process required 2.76 ms for the project. For a variant with 4,096 names in descending order, the time of the full command in the additional triple comparison dropped from 430.46 to 72.91 ms. The reference was faster with this large single file at 35.50 ms. These measurements capture tool time. Tokens and time until successful model repair were not collected in this experiment.

## Trace

```sh
make test
stage=$(mktemp -d)
make install DESTDIR="$stage" PREFIX=/opt/tide
tool="$stage/opt/tide/bin/tide"
entry=native/bootstrap/fixtures/modules/report.tide
"$tool" modules "$entry"
"$tool" check "$entry" --json
"$tool" fmt "$entry"
"$tool" test "$entry"
"$tool" modules apps/space_invaders.tide
```

In the first project, both `opening.tide` and `closing.tide` refer to `reading.tide`. The output contains four import locations and three module files. The check covers the four record types. For the game, `invaders_game.tide` appears at line 1, column 1.

## Remaining Dependencies

The checkout and optional compatibility installation continue to use the Python reference for general semantic checking and execution of functions, rules, and examples, for revision-bound editing, as well as interactive terminal and document services. Even more complex lock files, individual internal size limits, and operating system errors when opening a path with non-ASCII characters can still lead to the reference in the three previous check commands. In a pure standard installation, such unsupported check paths report `E_BACKEND`. [Status of replacement](../../tasks/todo.md)
