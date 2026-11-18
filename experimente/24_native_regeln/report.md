# Native state rules for heat, pump, and light

The TIDE compiler translates the three existing applications into standalone Linux-x86-64 programs. During the build, the previous reference interpreter executes the compiler written in TIDE. The generated file processes boolean events or signed 64-bit integers and writes their results as a JSON list. The supported subset includes scalar state fields and expressions, `keep`, `set`, and `reset`. Compound events, function calls within the rule, and state traces are open. [Build and invocation](../../native/README.md)

For each application, 128 different deterministic event sequences fully matched the TIDE reference. Additionally, the eight original examples, 30 cases for input binding, transitions, output, and errors, and 15 cases on both sides of the 100,000 step limit were tested. The boundary check also compared the event number and the priority of competing errors. A computation error at event 4,096 left the standard output empty. The previous native integer programs retained their verified binary hashes.

| Rule | Events | TIDE, Median | CPython, Median | Median of pairwise factors |
|---|---:|---:|---:|---:|
| Pump | 16 | 0.140 ms | 4.244 ms | 30.10× |
| Pump | 4,096 | 0.385 ms | 6.684 ms | 17.34× |
| Light | 16 | 0.141 ms | 4.233 ms | 30.00× |
| Light | 4,096 | 0.363 ms | 6.203 ms | 17.12× |

Each cell comprises 30 pairs after six warm-up pairs. Each invocation starts a process including input binding and output. The computer was a Ryzen 9 9950X3D, bound to CPU 2, with CPython 3.14.10. The median for the full build was 89.31 ms for the pump and 92.38 ms for the light.

A static upper bound allows the compiler to omit the runtime counter for short rules. File sizes decreased for the pump from 1,552 to 1,290 bytes, for the light from 1,663 to 1,377 bytes, and for heat from 1,641 to 1,347 bytes. In direct comparison, the smaller version was faster in 20 of 40 pairs for both pump and light. The median time saving was −5.76 µs and +7.39 µs. This yields no reproducible time gain. Model costs were not a measurement subject here. [Predefined sequence](experiment-plan.md) · [Sources, measurement commands, raw times, and test results](messung.json)

## Reproduction

Execute from the project directory using Bash, jq, xxd, and patch. The timing scripts require the Linux environment documented in the dataset.

```bash
set -euo pipefail
data=experimente/24_native_regeln/messung.json
build=$(mktemp -d)
for part in checks measure compare; do
  jq -ejr --arg k "$part" '.method[$k]' "$data" > "$build/$part"
done
jq -ejr .method.comparator "$data" > "$build/comparator.py"
python3 "$build/checks" "$build"
python3 "$build/measure" "$build"
mkdir "$build/metered"
while read -r file; do
  jq -ejr --arg f "$file" '.sources[$f]' "$data" > "$build/metered/$file"
done < <(jq -r '.sources|keys[]' "$data")
for file in rule_scan.tide scan_image.tide; do
  jq -ejr --arg f "$file" '.counted_patches[$f]' "$data" | patch -s "$build/metered/$file"
done
for app in pump light; do
  ./tide run "$build/metered/fold_i64.tide" --call compile_entry --read "source=apps/$app.tide" --inputs '{"entry":"simulate"}' |
    jq -ejr . | xxd -r -p > "$build/metered/$app"
  chmod u+x "$build/metered/$app"
done
python3 "$build/compare" "$build"
```
