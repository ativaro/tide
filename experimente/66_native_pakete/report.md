# The measurement report with two versioned packages

The package version of the measurement report calls `rowtext.parse` from `rowtext@2.0.0` and `measurements.parse` from `measurements@1.3.0`. The first package splits UTF-8 text into lines; the second checks and reads an i64 measurement value. Both declare `export parse`. The helper function `measurements.decode_measurement` remains package-internal. The revision records the resolved package paths and their contents. [Measurement Report](../../apps/report_packages/report.tide) · [Module Rules](../../LANGUAGE.md#versioned-packages)

| Lines | TIDE ahead-of-time compiled Median / P95 | TIDE Source Mode Median / P95 | CPython Median / P95 | AOT Factor, paired Median |
|---:|---:|---:|---:|---:|
| 4 | 0.585 / 0.668 ms | 5.637 / 6.011 ms | 10.517 / 10.876 ms | 17.91× |
| 512 | 0.636 / 0.833 ms | 14.608 / 15.088 ms | 10.859 / 11.368 ms | 16.63× |
| 2,048 | 0.847 / 0.994 ms | 41.740 / 42.113 ms | 11.498 / 12.048 ms | 13.39× |
| 3,072 | 0.929 / 1.053 ms | 59.695 / 60.386 ms | 11.817 / 12.175 ms | 12.66× |

The AOT build took separately 18.06 s. The source mode includes resolution, source checking, and execution per call. From 512 lines onward, CPython was faster than this mode. [Individual Times and Raw Data](messung.json)

## Acceptance and Comparison Conditions

The three variants passed the same 13 acceptance test cases. The successful results match byte-for-byte. For errors, return status, error code, and, where applicable, domain-specific error reason and input line match. These include empty files, LF, and CRLF, both i64 limits, invalid numbers, and UTF-8, missing read permissions, as well as file and line limits. The TIDE source positions are included in the raw data. TIDE retains its own working and memory budgets. [Raw data with diagnoses](messung.json)

Measured was the time from starting a fresh process to complete JSON output. Inputs and the limit value were identical. The Python version also uses two local packages, checks their expected versions at startup, and ran with `-E -S` and prepared bytecode. The measurement series uses 31 runs per size and variant after five warm-up rounds, a varying order, and warm file caches. Measurements were taken on CPU 24 of a Ryzen 9 9950X3D with TIDE 0.6.1, CPython 3.14.10, and GCC 16.2.1. Processes ran locally without network and without model calls. [Test plan](versuchsplan.json) · [TIDE-measurement dataset](messdaten.tide) · [External Python comparison](python/report.py)

`make test` passed. The CLI prechecks covered private calls, unknown exports, version conflicts, incorrect package headers, transitive visibility, import cycles, and a symlink in the dependency path. An additional native test used two same-named exported record types and internal neighbor files. The two record types were also translated and executed together in a AOT precheck. An exported rule name was called with `scan`. The edit preview of a package file retained the project contract and passed all examples. A write attempt via the importing project and a AOT target path on a package source were rejected. The installed package version and the standalone AOT program passed the measurement report check in an environment without Python.

The package model uses local sources and an exact version per package name. The speed figures apply to the four file sizes and the measured start-to-output flow.
