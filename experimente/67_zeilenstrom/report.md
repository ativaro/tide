# Measurement report with line-by-line reading

At **100 MiB**, the ahead-of-time compiled TIDE measurement report processes at **131.0 MiB/s**, while the streaming reference under CPython achieves **25.6 MiB/s**. This corresponds to a paired factor of **5.12×**. Both read 13,107,200 lines, count 6,553,600 values over 80, and report as maximum the largest signed 64-bit number. [TIDE-program](../../apps/report_packages/stream_report.tide) · [CPython program](cpython_stream.py)

| Input | Time TIDE / CPython | TIDE MiB/s | CPython MiB/s | Factor, paired | Peak-RSS TIDE / CPython |
|---:|---:|---:|---:|---:|---:|
| 1 MiB | 8 / 50 ms | 125.0 | 20.0 | 6.25× | 1.84 / 11.14 MiB |
| 10 MiB | 77 / 404 ms | 129.9 | 24.8 | 5.23× | 1.84 / 11.11 MiB |
| 100 MiB | 763.5 / 3,908 ms | 131.0 | 25.6 | 5.12× | 1.84 / 11.11 MiB |

Each table cell shows the median of eight runs per size and language. For the factor, the time ratio of each measurement pair was first formed. The time at 100 MiB for TIDE was between 761 and 771 ms and for Python between 3,884 and 3.988ms. All eight TIDE processes per size reported 1,888 KiB peak-RSS via the calling shell's Linux process counter. For CPython, the highest single result across all sizes was 11,440 KiB. In a separate control with three further processes per size and language, the resident memory was scanned directly after program start to the end. At 100 MiB, the medians of the highest observed values were `smaps_rollup` at 1,184 and 11,628 KiB. The shell counter applies to the started process. The separate samples begin after loading the target program. [Individual measurements including memory control](messung.json)

## Same inputs and acceptance test

The inputs repeat the same 64-byte block with eight lines. It contains short numbers, negative values, both i64 limits, LF, and CRLF. Each variant gets read access to the same regular file and exactly its size as byte budget. Both process one line at a time, check UTF-8 and integer grammar, limit the raw line length, and output the same JSON record. [Dataset and independent expected values in TIDE](messdaten.tide)

| Input | Invalid line, reported by both |
|---:|---:|
| 1 MiB | 131,071 |
| 10 MiB | 1,310,719 |
| 100 MiB | 13,107,199 |

For the late error, the digit `0` was replaced by `x` in the second-to-last line. Size and line endings remained identical. Both programs crashed with status 1, empty stdout, and `E_DATA / invalid_integer`. TIDE additionally reported the source position in `measurements.decode_measurement` at line 9, column 1 of the package file. The failed runs are recorded separately from throughput times. [Diagnoses and SHA-256 of the six files](messung.json)

18 smaller cases ran through CLI, TIDE-AOT, and CPython. They checked, among others, zero budget, a missing byte, an earlier data error before a later budget limit, missing rights, overflow, invalid UTF-8, and CRLF, or a multi-byte character exceeding the 64-KiB buffer limit. A line with exactly 128 KiB succeeded; an additional byte led to `E_LIMIT`. Further TIDE examples check nested readers, own file positions, and interaction with the snapshot reader. Twice 64 MiB from the same grant succeeded. At twice 65 MiB, the second run stopped at line 8,257,537 at the shared budget of 128 MiB. [Generic examples](../../native/bootstrap/fixtures/functions/stream_lines.tide) · [Language rules](../../LANGUAGE.md#read-line-by-line)

## Measurement procedure

TIDE 0.6.2, GCC 16.2.1 and CPython 3.14.10 ran locally on logical core 24 of a Ryzen 9 9950X3D on Linux. The inputs were in the warm tmpfs. For each size, each variant ran once for warming up, then eight times in alternating order. Each measured value includes the new process from start to JSON output. zsh 5.9.2 provided the real time in milliseconds with `%*E` and the maximum resident process memory in KiB with `%M`. The smallest TIDE time value has correspondingly rough resolution. Pre-translation and file generation were outside of timekeeping. The comparison ran in a network namespace without network access and did not use models. The numbers apply to this numerical report with short lines and warm data. [Test plan](versuchsplan.json)

To repeat in the project directory with zsh on core 24 and a local tmpfs under `/tmp`:

```zsh
d=$(mktemp -d /tmp/tide-stream.XXXXXXXX)
./tide build --aot apps/report_packages/stream_report.tide "$d/report"
TIMEFMT='%*E s  %M KiB'
for mib in 1 10 100; do
  bytes=$((mib * 1048576))
  ./tide run experimente/67_zeilenstrom/messdaten.tide --inputs "{\"bytes\":$bytes}" |
    jq -jr .block | MIB=$mib perl -0777 -ne 'my $chunk = $_ x 16384; print $chunk for 1..$ENV{MIB}' > "$d/data"
  args=(--inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/data")
  for pair in {0..8}; do
    order=(python tide)
    if (( pair % 2 )); then order=(tide python); fi
    for arm in $order; do
      if [[ $arm = tide ]]; then
        time "$d/report" $args
      else
        time python3 -E -S experimente/67_zeilenstrom/cpython_stream.py $args
      fi
    done
  done
  cp "$d/data" "$d/bad"
  print -rn x | dd of="$d/bad" bs=1 seek=$((bytes - 9)) conv=notrunc status=none
  "$d/report" --inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/bad"
  python3 -E -S experimente/67_zeilenstrom/cpython_stream.py --inputs "{\"bytes\":$bytes,\"limit\":80}" --read "input=$d/bad"
done
```

Pair 0 serves for warming up. `make test` passed. The installed CLI passed the seven package examples and the call with file permissions also in an environment without Python and compiler. In the same isolated filesystem, the standalone AOT program produced the correct 100 MiB report and the expected late error line.
