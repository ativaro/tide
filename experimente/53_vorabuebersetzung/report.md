# Ahead-of-time compile measurement report

`tide build --aot` translates the tested measurement report and its imported functions into a standalone Linux-x86-64 file. The build includes all tested source definitions reachable from the chosen entry. The program binds the file and threshold as `tide run`. [Translator in TIDE](../../native/bootstrap/aot.tide) · Runtime in TIDE](../../native/bootstrap/aot_runtime.tide)

```sh
./tide build --aot apps/report.tide /tmp/tide-report
printf '80\r\n81\r\n98\r\n' > /tmp/tide-werte.txt
/tmp/tide-report --read input=/tmp/tide-werte.txt --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

## Acceptance test

13 Cases provided the same status for the project evaluator, the translated program and the external CPython reference as well as byte-equal standard output and error output. Among them are empty files, both i64 limits, invalid lines, invalid UTF-8, missing files and the limit of 128kiB. The case with exact 100,000 work steps exists. The additional step logs in to both TIDE-Pfaden `E_LIMIT` `readings.tide:5:51`. A separate TIDE test case uses exactly 4 MiB guest memory with repeated read accesses. An additional sign exceeds the budget at the relevant `read`.

83 additional local comparisons between the two TIDE paths checked mixed LF and CRLF input, shared paths with unicode and equal signs, data close to the working limit and errors at JSON input and rights binding. The three process channels each matched. `make test` and `make check-no-python` passed. In isolated packet acceptance, the statically linked program runs without project sources or compilers. [Package acceptance](../../native/bootstrap/no-python.Dockerfile)

## Runtime against CPython

Median from program start to complete JSON output in milliseconds. The factor is the median of the paired quotients. CPython 3.14.10 ran with `-S`, i.e., without loading the `site` module.

| Lines | TIDE ahead-of-time compiled | TIDE `run` | CPython | Factor against CPython |
|---:|---:|---:|---:|---:|
| 3 | 0.330 | 4.823 | 10.362 | 31.4× |
| 512 | 0.376 | 13.891 | 10.563 | 28.0× |
| 2,048 | 0.562 | 41.803 | 11.311 | 20.1× |
| 3,400 | 0.669 | 65.781 | 11.926 | 18.0× |

The warm measurement starts at the same already separated text lines. It covers the compute core with work budget, without file access, process start, or JSON output. At 2,048 lines, it was **85.1 µs versus 712.2 µs**. Across all four sizes, TIDE was **6.3–8.4×** ahead of CPython in this measurement.

The measurement series use 31 paired samples each after five warm-up rounds on CPU-core 2. Per warm sample, 96 computations run. The order of tools alternates. All outputs were compared with independently calculated expected values. The delivered build lasted with prepared package and GCC 16.2.1 **16.98 s**. This time is listed separately. [Raw Times and Error Findings](messung.json)

The CPython comparison uses the same rules for numbers, line separators, read budget, and the observable working limit of this program. The guest memory budget is unreachable in the measurement report under input limits and is checked with the separate TIDE fixture. The measurement qualifies the shown application. The 100× runtime goal against CPython was not met here. There were no model runs.

The measurement can be repeated locally with `PYTHONDONTWRITEBYTECODE=1 python3 -S experimente/53_vorabuebersetzung/measure.py`. CPython is used only for this external comparison. [Comparison Program](cpython_report.py) · [Measurement Procedure](measure.py)
