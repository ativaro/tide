# Signed division and remainder in native TIDE programs

The native compiler translates `div` and `mod` for i64 operands. Thus, a carton balance can be executed directly as a TIDE program. Each booking of up to six pieces per carton counts its opened cartons in the direction of movement. Two single deliveries of one piece each require two cartons. A corresponding cancellation counts negatively. For the calculation, the TIDE application needs neither a floating-point number nor the magnitude of the smallest i64. [Application and examples](../../apps/cartons.tide) · [Experimental plan](experiment-plan.md)

| Bookings per call | Native file, median | CPython 3.14.10, median | Paired factor, median |
|---:|---:|---:|---:|
| 0 | 0.135 ms | 4.142 ms | 30.6× |
| 16 | 0.135 ms | 4.164 ms | 30.9× |
| 4,096 | 0.373 ms | 6.723 ms | 18.0× |

For each size, six warm-up pairs and 30 measurement pairs with varying order ran on the same logical CPU. The time includes process start, handover, and verification of decimal arguments, rounding, verified balance addition, output, and process end. The TIDE interpreter determined the result outside the measurement. The CPython version uses the integer rounding of `abs(count)` and restores the sign subsequently. Both languages check the running balance after each booking. The native build took a median of 83.88 ms; the file with dynamic inputs is 1,264 bytes large. Differences to other applications and measurement sessions do not allow a statement about the cost of a single division. [Individual times, comparison program, build and environment](messung.json)

## Arithmetic rules and error order

The code generator evaluates both operands from left to right. For the normal case, it uses the signed x86-64 division. For zero as divisor, it reports `E_DATA` with reason `division_by_zero`. For divisor −1, it generates a verified negation for the quotient and zero for the remainder. This also holds for the smallest i64 regarding the TIDE rules. [Code generator](../../native/scalar.tide) · [AMD64 Architecture Programmer's Manual, General-Purpose Programming](https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24592.pdf)

For each operation, all 169 combinations of 13 boundary and sign values plus 128 additional deterministic pairs were verified. In all **594 individual comparisons**, the native file, the TIDE reference, and an expectation calculated separately with unlimited integer arithmetic matched. Further 16 programs checked, among others, nested operands, skipped error branches, the running position, and competing errors in left and right operands. All 16 ran with both embedded and dynamic values. An error had to end with status 1, empty stdout, and the matching structured diagnosis. All six application examples also passed in the CPython comparison version. The earlier verification from trial 21 was repeated with the extended compiler. Their results and binary hashes remained identical. [Nested cases](faelle.tide) · [Earlier input verification](../21_native_eingaben/report.md)

## A compiler error found by the boundary test

For the additional budget test, the last division lies exactly on the 100,000 step or immediately above. Already during translation, quotient and remainder initially broke off at `E_LIMIT`. The first compiler version inserted a fragment into the internal stack and inserted it again into a copy of the same initial stack after incrementing the step counter. Both operations stressed the logical allocation budget of the compiler executed in TIDE.

The compiler now generates the complete fragment and extends the stack once. With the same limit of 4,194,304 logical bytes, the translation of the quotient test 3,480,748 and the remainder test 3,456,424 requires bytes. These are cumulative loads according to TIDE semantics, not measurements of process memory. The previously translatable comparison files of this experiment remained byte-identical.

All eight combinations of operator, error operand, and budget limit subsequently ran natively. At exactly 100,000 steps, the last expression was decisive, including the valid remainder of zero. At step 100.001, both programs reported `E_LIMIT` first, like the reference. [TIDE edge case ](budget.tide) · [compiler states, budget counters, and individual results ](messung.json)

## Recalculation

In the project directory under Linux x86-64:

```sh
set -euo pipefail
build=$(mktemp -d)
data=experimente/23_native_division/messung.json
jq -jr .method.cpython "$data" > "$build/comparator.py"
jq -jr .method.cross_check "$data" > "$build/checks"
jq -jr .method.measure "$data" > "$build/measure"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
```

For the additional comparison of the compiler budget, the measurement requires the module state at that time. The stored sources correspond to the compiler hashes of the measurement. The patch reconstructs from this the version with the double stack setup. [compiler state ](compilerstand.json)

```sh
mkdir -p "$build/revision/native"
for file in elf64.tide scalar.tide argv_i64.tide fold_i64.tide; do
  jq -ejr --arg file "$file" '.[$file]' experimente/23_native_division/compilerstand.json > "$build/revision/native/$file"
done
for dir in apps experimente tide_lang; do ln -s "$PWD/$dir" "$build/revision/$dir"; done
jq -jr .previous_compiler.after_to_before_patch "$data" |
  patch -s -o "$build/scalar-before.tide" "$build/revision/native/scalar.tide"
jq -jr .method.allocation "$data" > "$build/allocation"
(cd "$build/revision" && python3 "$build/allocation" "$build")
```
