# Package change until the green measurement report

With the installed TIDE, time dropped from saving the correction in `measurements.parse` to the green test from **5.28 to 1.43 ms**. The saving amounted to the paired median **3.82 ms** or the factor **3.70**. Against CPython, the factor rose from **1.21 to 4.50**. The results apply to the streaming measurement report with seven examples, a freshly started process, and warm file caches. [Individual times](messung.json) · [Test plan](versuchsplan.json)

| Call | Before, Median / P95 | After, Median / P95 |
|---|---:|---:|
| Installed `tide test` | 5.28 / 5.49 ms | 1.43 / 1.57 ms |
| CPython with the same seven cases | 6.41 / 6.92 ms | 6.44 / 6.74 ms |
| `./tide test` in source checkout, separate row | 8.52 / 9.23 ms | 5.55 / 5.99 ms |

## Change and comparison

In a project copy, the exported package function forwarded the read line number plus one to the integer check. Consequently, the report reported the invalid number on line `80\nx\n` for 3. The change restored passing the actual line number in both languages. The public expectation was line 2. Project sources and application expectations served as reference throughout. [TIDE measurement report](../../apps/report_packages/stream_report.tide) · [Package](../../apps/report_packages/vendor/measurements/1.3.0/package.tide)

Before **each** timing measurement, the faulty package build was saved and its red test confirmed. The monotonic clock ran from opening the temporary file for correction through writing, closing, and atomic renaming until the completed test process with verified output `{"passed":7}`. There were six identical report cases per language with inputs in memory and a direct package example. They check LF/CRLF, empty input, exceeded and negative budget, invalid numbers with error line, and a signed number with a leading zero. Both sides ran the full suite. [CPython cases](python/test_report.py) · [Streaming reference](python/report.py)

After eight warmup blocks, 64 measurement blocks followed, each with four runs. Within them, both TIDE installations alternated with two runs of the same CPython build in a balanced order. Thus, each TIDE build has a temporally adjacent Python control. CPython started with `-E -S`, direct test script, and normal bytecode cache. Red and green source files have different lengths. The changed Python import had to be retranslated for every run, even with the same timestamp. Both TIDE builds read the package sources freshly. All measurements ran with TIDE 0.6.2 and CPython 3.14.10 on core 24 of a Ryzen 9 9950X3D under Linux. Working copies were in warm tmpfs. Correction search, tooling, and installation lay outside the interval. The measurement ran without network and model calls. [Exact measurement procedure and repetition](reproduction.md)

## Bottleneck and change

In the baseline profile, the public test call took **5.03 ms**. The already existing native checker required **1.22 ms** for loading the same package graph, type checking, and the seven examples combined. Roughly three quarters of the time thus fell to startup and checker preparation. The profile values come from separate process runs without saving and must be distinguished from the end-to-end values above. [Profile samples](messung.json)

The installed `tide test FILE` now starts directly in the native checker. It resolves the project path and the next `tide.lock`, checks the pin against the current operations catalog, and runs the tests with the existing project loader. The change requires neither result cache nor a permanently running process. In case of unclear path or version conflict, the previous diagnostic path takes over. Further CLI commands use the existing starter. In the source checkout, `make` additionally checks the tooling status on every call. In the final profile, the installed call took **1.24 ms**, the direct checker **1.21 ms**. [Native entry points](../../native/bootstrap/seed.tide) · [Pin check](../../native/bootstrap/project.tide)

Forwarding other installed commands incurs a small measurable cost. In each of 32 supplementary measurement pairs, the median for `tide --version` was **1.96 → 2.13 ms**, and for a short `tide run` call, **5.23 → 5.27 ms**. The raw data also includes the respective P95 values. [Precheck](messung.json)

## Acceptance test

`make test` passed. For 32 CLI prechecks, exit status, stdout, and stderr matched byte-for-byte before and after the edit. Checks included incorrect or reordered pins, priority of a version conflict over a source error, Unicode and line breaks in the path, symlinks, invalid UTF-8, an unwritable output channel, and extended test diagnostics. The installed version detected the built-in package error and passed all seven examples after correction, even in an isolated filesystem without Python, Shell, or compiler. [Verifier results](messung.json)
