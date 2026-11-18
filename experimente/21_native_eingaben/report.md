# The same native TIDE file with varying measurement series

The 957 byte-sized heating degree hour file processes a start value and up to 4,096 temperatures per call. On the measured Linux-x86-64 machine, it was in the paired median 16.5× to 23.9× faster than CPython, including start, input binding, output, and process end depending on list size. The build time was 125.74 ms in the median of ten builds after two warm-up builds. [Call and input format](../../native/README.md#varying-inputs) · [Fixed test plan](experiment-plan.md)

| Number of temperatures | Native file, median | CPython 3.14.10, median | Paired factor, median |
|---:|---:|---:|---:|
| 0 | 0.296 ms | 6.963 ms | 23.9× |
| 16 | 0.277 ms | 6.674 ms | 23.7× |
| 4,096 | 0.678 ms | 11.234 ms | 16.5× |

For each size, six warm-up pairs and 30 measurement pairs with varying start ordering ran on CPU 2 of a AMD Ryzen 9 9950X3D. Both programs received the same decimal arguments per pair. Start value and measurement series were deterministically generated ahead-of-time and varied between pairs. The TIDE reference interpreter provided the target value outside the time measurement. The monotonic clock ran in the parent process around the complete child process call. The times thus also include the transfer of arguments by the measurement program. CPython ran with `-BS` without site initialization. Both programs also validate text input, range, list length, and arithmetic overflows. The measurement does not capture a warm compute core or model costs. [Comparison source, input generation, individual times, build and binary hashes](messung.json)

## What was checked

- All 29 convolution programs from test 20 delivered the expected value or overflow code upon calling their parametrized function. The closed heating degree hour and balance files, as well as the two historical balance stack files, retained their archived binary hashes.
- 27 specified binding and calculation cases as well as 128 further different inputs generated with fixed seed ran over the same heating degree hours file. Among the 128 cases were 76 results, 26 input errors and 26 arithmetic overflows. The TIDE function `int` checked the text binding. Validly bound values were evaluated by the TIDE reference. The CPython comparative version was also tested against all cases. [Determined cases](faelle.json) · [Binding reference in TIDE](bindung.tide)
- Six additional cases checked the maximum list length, an erroneous last value, too many values, length checking before parsing, and long numbers with or without leading zeros. For an invalid value, the native file reported the first affected argument number; for exceeding the list limit, it reported the limit. No error case wrote a result to stdout.
- Eight tests each via a direct and an indirect entry covered short and long computation branches, 99.999, 100.000, and 100,001 evaluation steps as well as the error sequence. For the direct entry, 3,701 long and ten short branches together with the entry totaled exactly 100,000 steps. The value was 3.701. For the indirect entry, 3,697 long and 25 short branches reached the same limit. Both entries reported `E_LIMIT` at the first additional step. An early arithmetic overflow remained visible; an erroneous late argument was detected during binding before computation. [Budget program](budget.tide)

The executable file has a read-only executable load segment and a stack marked as non-executable. The check applies to the documented i64 folding excerpt and the ahead-of-time type-checked source. The runtime comparison concerns an application on a machine. In none of the 90 measurement pairs was the 100× goal achieved.

## Recalculation

In the project directory, the measurement programs stored under `method` can be executed. The native file is generated from the current TIDE source in a temporary directory. For the time comparison, logical CPU 2 must be available.

```sh
set -euo pipefail
build=$(mktemp -d)
data=experimente/21_native_eingaben/messung.json
jq -jr .method.cpython "$data" > "$build/comparator.py"
jq -jr .method.cross_check "$data" > "$build/checks"
jq -jr .method.measure "$data" > "$build/measure"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
```
