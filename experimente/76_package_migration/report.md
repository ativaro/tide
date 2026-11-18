# Stage 7 — Migrating the jsoninput package

Three application calls needed source changes for `jsoninput@2.0.0`. TIDE 0.6.8 identified all three in the working version. Switching just the pins produced three type errors at those locations. With the appropriate calls in place, all 30 application examples passed on the old and migrated pins.

## The interface change

In 1.0.0, `jsoninput.load` took an optional integer. A present value selected a byte-limited batch read. An empty option selected a snapshot read. In 2.0.0, the two operations are explicit in the public interface.

| Intent | Original call | Migrated call |
|---|---|---|
| Read and decode at most 4 MiB | `jsoninput.load input (some 4194304)` | `jsoninput.load input (make jsoninput.ReadBudget max_bytes 4194304)` |
| Decode a snapshot from a read grant | `jsoninput.load input (nil i)` | `jsoninput.snapshot input` |
| Decode bytes already in memory | `jsoninput.decode payload` | `jsoninput.decode payload` |

The bounded implementation passes the byte count to `read_batch`. The snapshot uses `read_bytes`. Both feed the same decoder, bound to each project's document type. A 14-byte JSON document containing `é` passed at limit 14 and failed at limit 13. A negative budget also raised `E_LIMIT`. [Version 1 source](../../apps/orders/vendor/jsoninput/1.0.0/package.tide) · [Version 2 source](../../apps/orders/vendor/jsoninput/2.0.0/package.tide) · [Budget examples](../../native/bootstrap/fixtures/package_types/v2_reader.tide)

## Which callers broke?

The compact `--call-sites` view reports resolved calls in a checked project. The study queried `jsoninput.load` on each original project before switching its pin. A second query on the same revision identified the examples that reach that export. The call column below points to the start of the call. The diagnostic column points to its obsolete second argument.

| Original application source | Caller | Call (line, column) | Pin-only diagnostic (line, column) | Examples reaching the call |
|---|---|---|---|---:|
| `apps/orders/import.tide` | `main` | 18, 21 | 18, 43 | 11 |
| `apps/report_packages/json_report.tide` | `main` | 4, 14 | 4, 36 | 6 |
| `apps/report_packages/sqlite_report.tide` | `main` | 14, 21 | 14, 43 | 4 |

Each diagnostic gave `E_TYPE`, expected `{jsoninput.ReadBudget}`, actual `?i`. The API report also imports the package transitively. The query found zero calls to `load` in that project, and all four of its examples passed immediately after the pin switch. The shared `json_readings.parse` still calls `decode`. Two import declarations select the new version across the application roots. The separate package-binding test consumer continues to exercise its original 1.0.0 pin. [Revision-bound caller lists and diagnostics](results.jsonl)

## Old pin and migrated acceptance

The old arm used the unedited application sources from commit `cb93e76a862da076de5858b458e1b2eabbf481a9`. Both vendored versions were present in both arms. The module graph confirmed the selected pin for every suite. The runner also checked the 1.0.0 package against its original Git contents. Its SHA-256 is `30360ee448023b0ef35cfaba52c7a9d812bc101cbb95fbce78e2a28b10f2e145`.

| Suite | Pinned 1.0.0 | Migrated 2.0.0 |
|---|---:|---:|
| Order import, including redelivery, cancellation and rollback | 13/13 | 13/13 |
| JSON measurement report | 9/9 | 9/9 |
| SQLite measurement report, including rollback | 4/4 | 4/4 |
| API measurement report | 4/4 | 4/4 |

All three affected production entry points built ahead of time in both arms. The six executables each ran a successful case and an invalid-input case drawn from the same TIDE examples. The order receipt contained three applied events and two duplicates. Both measurement reports counted two readings above threshold and returned a peak of 98. The three invalid inputs retained their expected code, reason and JSON field path. A project combining direct and transitive pins for different major versions was rejected with `E_PACKAGE`.

## Reproduction

Run from the repository root. The replay reads the Stage 6 commit from local Git history. It uses the same TIDE tool version in both arms and writes JSON Lines to standard output.

```sh
experimente/76_package_migration/reproduce.sh > /tmp/tide-migration.jsonl
diff -u experimente/76_package_migration/results.jsonl /tmp/tide-migration.jsonl
make -s -j3 test check-postgres
```

To inspect the original callers interactively, run TIDE 0.6.8 against the Stage 6 application sources, as the replay does. On a migrated report, query `jsoninput.snapshot` to find the replacement call.

```sh
./tide context apps/orders/checks.tide --function jsoninput.load --call-sites
./tide context apps/report_packages/json_report.tide --function jsoninput.snapshot --call-sites
```

The replay ran on one Linux x86-64 workstation with networking disabled. The full local native and PostgreSQL regression suites passed. The installed CLI also located calls and ran the order, JSON and SQLite suites for both pins in an isolated filesystem without Python. Model runs and new comparative performance measurements were outside this migration study.
