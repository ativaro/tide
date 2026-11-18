# Check type files without Python

The installed TIDE command checked a small valid type file in the median in 7.4 ms, the reference starter in 31.3 ms. For all 170 source files, the results of `check` matched. The comparison includes the complete JSON fields, the source position on error, the revision on success, the exit status, and the respective empty second output channel. [Measurement values per call](messung.json) · [Check protocol](pruefung.json)]

| `tide check`, 20 measurement pairs per file | Reference | Public TIDE command | Factor per pair, Median |
|---|---:|---:|---:|
| Three type declarations with forward references | 31.3 ms | 7.4 ms | 4.21× |
| Unknown field type | 31.2 ms | 6.2 ms | 4.94× |
| 100 records with shared variant | 31.6 ms | 10.7 ms | 2.93× |
| A variant with 120 tags | 30.5 ms | 13.2 ms | 2.32× |
| Balance program with folding and examples, compatibility installation | 31.6 ms | 35.6 ms | 0.87× |

The direct reference starter and the fully installed CLI edited the same absolute file path with the same project binding. After three warm-up pairs, the start order changed. In the first four groups, the native call was faster in all 80 pairs. For the balance program, the attempt at native precheck and the subsequent start of the reference added around 4 ms to the median of the two runtime series. The standard package reports `E_BACKEND` for this call. Model time and token consumption were not collected here. [Test plan](experiment-plan.md)

The first native draft traversed each record root again within a work budget. The current traversal distributes known type depths across all roots and visits edges with a shared cursor. The start compiler passes immutable composite parameters by reference. In an additional comparison at the 100-record case, the entire CLI time dropped from 231.1 to 10.3 ms. This before-after comparison encompasses both changes and the interim changes to the starter.

## Acceptance test

The generator written in TIDE produced 167 sources. In addition came the type declarations from Nano, Space Invaders, and its game module. There were 96 valid sources and 74 rejections, of which 39 were type errors, 29 name errors, and six syntax errors. The test covered, among other things, cycles, shared subgraphs, depth 16 and 17, Unicode whitespace, and error positions after line changes. Field types may combine pairs, lists, options, records, and variants. Read permissions are not allowed as data fields. [Generator](../../native/bootstrap/schema_cases.tide) · [Checker](../../native/bootstrap/schema.tide)

On the same 170 sources, `fmt` and `test` were compared separately with the reference. In all 96 success cases, the formatted text was byte-identical, and a second formatting was also identical. A valid file containing only type declarations reported zero examples. Each of the 74 invalid files produced the expected diagnosis for both commands. The 510 comparisons concern three commands on the same corpus.

The rebuild in a fresh Linux mount namespace used exclusively the required system programs. Python, project modules, and the reference starter were inaccessible for the build and native test processes. The examiner additionally passed cases with divergent version binding, invalid UTF-8, a 131,073 byte file, a FIFO, and unusual filenames. The twelve application ELF files matched the previous checksums. A fresh standard installation contained no Python file and no reference starter. When switching from the compatibility installation to the standard installation, the redirection ended at a still-existing reference file.

The TIDE application tests run with `make test`. Nano processes cursor movement via CRLF, Unicode input, saving, and save feedback. The game test checks start, ship movement, shooting, pause display, and continuation. Both execute the regular TIDE functions. The test provides the input events. The self-build compares two consecutive compiler generations byte-by-byte. In the environment with the reference system, all 35 historical integration tests also passed. [Nano Test](../../apps/nano_checks.tide) · [Space Invaders Test](../../apps/invaders_checks.tide)

## Trace

```sh
make test
stage=$(mktemp -d)
make install PREFIX=/opt/tide DESTDIR="$stage"
tool="$stage/opt/tide/bin/tide"
printf 'record Sensor\nphase:{Phase}\n\nvariant Phase\nstop start\n' > "$stage/gut.tide"
"$tool" check "$stage/gut.tide" --json
"$tool" fmt "$stage/gut.tide"
"$tool" test "$stage/gut.tide"
printf 'record Knoten\nkind:?{Knoten}\n' > "$stage/zyklus.tide"
"$tool" check "$stage/zyklus.tide" --json
```

The last call yields `E_TYPE` at line 1, column 1, and exit status 1. For a personal differential run, the corpus can be generated directly with the starting compiler.

```sh
{ cat native/bootstrap/syntax.tide; echo; cat native/bootstrap/schema.tide; echo; cat native/bootstrap/schema_cases.tide; } > "$stage/korpus.tide"
build/native/seed generate_cases < "$stage/korpus.tide" > "$stage/korpus.cpp"
c++ -std=c++20 -O1 "$stage/korpus.cpp" -o "$stage/korpus"
"$stage/korpus" > "$stage/faelle.jsonl"
```

The full module checker, general execution, and example suite, revision-bound editing tools, and interactive terminal and documentation services continue to use Python. More extensive type files can also reach the internal limits of the native tool. In checkout and after `make install-compat`, the reference is available for these calls. A fresh standard package executes only the ported calls.
