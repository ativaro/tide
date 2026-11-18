# Native TIDE branches for heating degree hours

The compiler written in TIDE now also generates nested expressions from arithmetic, comparisons, and conditional evaluation for an i64 folding step. For the example with 16 hourly measurement values, the standalone Linux file 39 produced heating degree hours. Native TIDE was faster than CPython in the median of the paired quotients 48.1× during single execution and in repeated calculation 33.8×. The targeted 100× ratio was not achieved in any measurement round for this task. [TIDE-Program ](../../apps/heating.tide) · [Predefined measurement procedure ](experiment-plan.md)

| Metric | Native TIDE | CPython 3.14.10 | Paired Factor |
|---|---:|---:|---:|
| Start to output and process end | 0.130 ms | 6.108 ms | 48.1× |
| Time per full evaluation in repeated runs | 13.44 ns | 451.41 ns | 33.8× |
| Native build from source, median of ten runs | 84.86 ms | – | – |

The single measurement ran in 30 pairs after six warm-up pairs on the same logical core of a AMD Ryzen 9 9950X3D. Both programs used fixed input data, checked the i64 arithmetic, and output `39`. The time columns are the respective medians. The factor is the median of the quotients within the individual rounds. Single execution includes the different startup costs of the programs.

For warm throughput, 32,768 and 131,072 complete evaluations per process were compared. Each round contained four process measurements. Over 24 rounds, each order occurred once. The runtime difference per language was divided by the 98,304 additional evaluations. Each difference was positive. The paired factors ranged between 23.0× and 40.5×. Throughput applies to repeated evaluation of the same measurement series. Other data distributions can change the costs of jumps.

The normal ELF file is 621 bytes large. Its 184 byte-long computation core including overflow path and the 128 byte input data matched byte-for-byte with those of both batch files. At each repetition, start value, pointer, and counter are reset. The Python version calls the same function per evaluation with the same inputs. For the five domain TIDE examples, CPython and the newly generated native file were also cross-checked. The native build time includes source verification, compiler run in the reference interpreter, byte transfer, and setting the execution bit. [Raw times, machine state, comparison sources, and binary hashes ](messung.json)

## Semantics and Compatibility

29 other programs provided by an TIDE program were checked with `tide check`, translated natively and executed against their target value as well as `tide run`. 24 provided the same integer including line break. Five broke off with `E_OVERFLOW`, empty standard edition and status 1. The examples distinguish between skipped and actually executed error branches. They also check the unchanged starting value next to the running accumulator, the position variable from one, both i64 limits and branches over more than 127byte. The reference interpreter provides additional diagnostic details in the event of a fault. [TIDE test cases](faelle.tide) · [Translation Examples and Rejections](../../native/scalar.tide)

For the existing balance program, the generated file remained byte-identical. The historical measurement patch produced the archived binary hashes for both repetition counts again. The native compiler covers previously closed programs with an integer fold over embedded literals. Records, file and terminal inputs, and model costs during the development of these programs were not qualified here. [Native call and supported expressions](../../native/README.md) · [Earlier balance measurement](../11_saldo/report.md)

## Recalculation

The JSON file contains the used measurement commands, the Python comparison, and all individual timings. The runtime measurement can be repeated on a machine with available logical CPU 2 using Bash, jq, and Python in the project directory.

```sh
set -euo pipefail
work=$(mktemp -d)
data=experimente/20_native_ausdruecke/messung.json
jq -r .method.cpython "$data" > "$work/comparator.py"
jq -r .method.performance "$data" > "$work/measure"
python3 "$work/measure" "$work"
jq -r .method.differential_checks "$data" > "$work/compare-cases"
bash "$work/compare-cases"
```

For the meaning of x86-64 comparison, jump, and overflow operations, the processor manufacturer's instruction reference serves as a manual. The actually executed bytes were additionally verified locally with the disassembler and based on the results. [Intel Software Developer's Manual, Volume 2](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
