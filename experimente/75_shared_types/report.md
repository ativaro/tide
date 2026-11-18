# Stage 6 — One typed JSON reader for orders and measurements

**Stage 6 passed with TIDE 0.6.7 on one Linux x86-64 workstation.** Both applications import `jsoninput@1.0.0[Document]`. In the order project, `Document` contains a supplier and a list of order events. In the measurement project, `Document` contains a list of readings and a dictionary of sensor limits. Each project keeps its existing public type name. A third test consumer binds a type named `Reading`.

## What the applications share

The package exports `decode` for bytes and `load` for a read grant and an optional byte limit. Both application entry points call the same `load` function. The order importer supplies 4,194,304 bytes and the package uses `read_batch`. The measurement report supplies an empty option and the package uses `read_bytes`. Both branches feed one typed decoder. The SQLite measurement importer uses the same package as the in-memory report.

TIDE resolves the package parameter to the consumer's concrete type before checking function bodies and calls. This edition supports one named record or variant parameter per package and one concrete binding for that package within a project. Dependencies can forward the parameter. The module graph shows which argument each consumer supplied. [Language reference](../../LANGUAGE.md#a-package-with-a-type-parameter)

The order project's package is the maintained source. Each application carries the pinned file in its own vendor directory so either project can run on its own. Both files have SHA-256 `30360ee448023b0ef35cfaba52c7a9d812bc101cbb95fbce78e2a28b10f2e145`. The regression target compares their bytes and fails on drift. [Package source](../../apps/orders/vendor/jsoninput/1.0.0/package.tide) · [Order entry point](../../apps/orders/import.tide) · [Measurement entry point](../../apps/report_packages/json_report.tide)

## Local acceptance

| Check | Observed result |
|---|---|
| Existing application examples | 13/13 order import, 9/9 JSON measurement report and 4/4 SQLite measurement report |
| Order restart scenarios | 24/24 with the source CLI and 24/24 in the AOT arm. Each arm used the original order-only producer for the two upgrade setup steps. The SQLite dump matched its pre-call contents after every rejected operation. |
| Duplicate delivery and cancellations | The same five-event input returned `{"applied":3,"duplicates":2}` in the installed CLI and the AOT executable. |
| Sensor-specific thresholds | Both execution paths returned `{"above":2,"peak":{"some":98}}`. |
| Malformed domain fields | Both paths returned byte-identical diagnostics for each input. The order path was `/events/0/qty` and the reading path was `/readings/1/note`. |
| Resource boundaries | Both paths accepted 1,000 order events, rejected 1,001 at `/events` and returned `E_LIMIT` for a 4,194,305-byte file. The package fixture accepted an 11-byte document at limit 11 and rejected it at limit 10. |
| Package bindings | The forwarded binding produced a pair of concrete records. Missing, malformed, unknown and conflicting arguments were rejected during checking. |

The compile-time test passes the result of `jsoninput.load` to a function expecting `OtherDocument`. That record declares the same fields as the order document. All four commands (`check`, `run`, `test`, and `build --aot`) rejected the call at **wrong_order.tide, line 10, column 15**, with `E_TYPE`, operand 1 of `count_events`, expected `{OtherDocument}`, actual `{Document}`. The build produced no executable. JSON field errors during execution instead point to the decoder and include the path into the input document. [Negative fixture](../../native/bootstrap/fixtures/package_types/wrong_order.tide)

## Reproduction

Run the following commands at the repository root. The focused target checks package identity, type binding and the negative fixture. The full suite also exercises the native bootstrap, SQLite, loopback HTTPS and language I/O. The PostgreSQL target uses a disposable local cluster.

```sh
make -s check-package-types
./tide test apps/orders/checks.tide
./tide test apps/report_packages/json_report.tide
./tide test apps/report_packages/sqlite_report.tide
make -s -j4 test check-postgres
make -s check-no-python
```

The full native suite and the disposable PostgreSQL suite passed. A clean Debian build and its installed-package checks also passed without Python. For the restart and application checks, the installed CLI and standalone executables ran in an isolated local filesystem with networking disabled and no Python interpreter. The restart inputs and expected results come from the existing [24-step TIDE scenario](../73_bestellimport/restart_cases.tide).

This was a language and application acceptance run. It used zero model runs and produced no new CPython timing or agent-token measurements.
