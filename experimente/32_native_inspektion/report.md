# TIDE without automatic Python call

The public starter uses the same native tools in the checkout and in the installed package. The installer delivers five statically linked Linux-x86-64 programs. When updating a previous compatibility installation, it removes the bundled Python files and their bytecode. A separate additional file in the old module directory remained in the upgrade test. The previous interpreter, the interactive hosts, and their respective tests are archived together in the [Experiment Archive](../referenzsystem/README.md).

## Context for a repair

`tide context` and `tide hole` use the typed tree of the same project check as `run`. An imported node retains its module name in the ID. In the body of a fold, the selection knows accumulator, position, and element. State initialization begins with an empty environment. The context view lists direct and transitive callers as well as the affected examples with their previous SHA-256 fingerprints. For the project and example revision, all data comes from the read snapshot. [Inspection](../../native/bootstrap/inspection.tide) · [Permanent Checks](../../native/bootstrap/inspection_checks.tide)

```sh
./tide context native/bootstrap/fixtures/functions/lists.tide --function weighted
./tide hole native/bootstrap/fixtures/functions/lists.tide --function weighted --node list_ops.tide:2:28
```

## Acceptance on 17 November 2026

- In a new build directory, `make -j2 CXX=g++ check-native install` ran in a Linux mount namespace. Visible were build programs, system libraries, and TIDE sources. Python programs, standard library, libpython, and the experiment archive were hidden. The self-build comparison, native test suites, editor and game checks, and all twelve stored ELF checksums passed.
- In nine projects, all definitions and their 236 expression nodes were queried. The 595 comparisons included 508 successful answers and 87 expected diagnoses. In eight additional calls, a list literal with 4,096 elements, a 86,094 byte-sized project with example contract, and a 48 deep definition call chain were checked. All 603 results matched the externally started reference regarding exit status, output channel, and JSON content. Integers were compared losslessly.
- A first boundary run failed at the JSON representation of the complete list literal. The shared string encoding now processes long values in segments. The existing 975 comparisons for functions, lists, rules, and traces were repeated with the updated package. There was no deviation.
- An additional run placed executable call guards for `python` and `python3` at the beginning of the search path. For successful commands as well as for unported calls in the checkout and in the updated package, the call log remained empty. The 35 old integration tests passed separately against the archived reference.

## Cost of a tool call

Both columns execute the same TIDE project with identical arguments. For each combination, there were four warm-up pairs followed by 15 measurement pairs with varying start orders. Measurements were taken from process start until full output. The native starter ran from the installed package. The reference used CPython 3.14.10. [Individual measurements, sources, and checksums](pruefung.json)

| Query | Native tool, Median | Historical TIDE reference, Median |
|---|---:|---:|
| Caller and examples for the balance | 7.79 ms | 31.02 ms |
| Selected node of the light rule | 7.27 ms | 31.18 ms |
| Bindings in an imported function | 7.17 ms | 30.52 ms |
| Context with large example contract | 94.00 ms | 32.73 ms |
| Bracketed expression with 4,096 operands | 29.88 ms | 45.12 ms |

The large contract query includes parsing the 4,096 i64 inputs, their canonical encoding, the SHA-256 calculation in TIDE, and outputting the entire example. The measurement captures these costs together. Model tokens and time to repair were not collected in this port.

## Open language scope

The public tool reports `play`, `edit`, general file read permissions, and previously unported expressions `E_BACKEND`. Editor and game states run in the native test. For interactive use, native terminal and document operations are missing. [Development status](../../tasks/todo.md)
