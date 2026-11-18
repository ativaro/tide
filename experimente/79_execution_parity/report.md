# Stage 10 · Execution parity

TIDE 0.6.11 returned matching results in **78 of 78 cases** on Linux x86-64. The three execution paths agreed on 45 values and 33 expected errors, including their source locations and structured details. The cases cover all 75 operations in the public catalog. This is a result for the listed inputs and boundaries on one machine. [Recorded observations](results.jsonl)

The study checks the same TIDE source through three public entry points. A named example supplies the input and its expected result. `tide test FILE --example NAME` checks that expectation and returns the actual value or complete diagnostic. The driver compares that observation with `tide run` and with a freshly built AOT executable. It checks exit status, stdout and stderr separately. JSON comparison preserves 64-bit integers and ignores object key order. [Driver](reproduce.sh) · [Sources, entry points and grants](targets.tsv)

## Operation coverage

Each row names a case that runs the listed operations. The driver requires the union of the rows to match the installed `tide describe` catalog. An operation can appear in many other cases. [Case-to-operation mapping](witnesses.tsv) · [Results by case](results.jsonl)

| Witness cases | Operations executed |
|---|---|
| `integer_path`, `range_error`, `depth_last` | `*`, `+`, `-`, `<`, `<=`, `>`, `>=`, `and`, `div`, `eq`, `fail`, `if`, `mod`, `not`, `or`, `recur`, `text_eq` |
| `unicode`, `parsed_int`, `missing` | `concat`, `int`, `length`, `let`, `lines`, `need`, `nil`, `text_find`, `text_len`, `text_rfind`, `text_slice` |
| `lists`, `scan_events`, `loop_steps` | `append`, `at`, `case`, `first`, `fold`, `list`, `map`, `pair`, `scan`, `second`, `while` |
| `variant_value` | `get`, `make`, `match`, `tag`, `with` |
| `octets`, `document` | `byte_at`, `byte_len`, `dict`, `dict_get`, `dict_put`, `json_decode`, `json_encode`, `q_from_units`, `q_units`, `unix_seconds`, `utf8_bytes`, `utf8_text` |
| `rethrow` | `catch`, `fail_at`, `has_reason`, `input_line`, `raise`, `some` |
| `line_exact`, `batch_exact`, `shared_snapshot`, `write_file` | `fold_lines`, `read_batch`, `read`, `read_bytes`, `write_bytes` |
| `cursor_rows`, `transaction_rollback`, `bound_parameters` | `fold_rows`, `sql_exec`, `sql_query`, `transaction`, `pg_exec`, `pg_query` |
| `get_at_limit`, `post_at_limit` | `https_get`, `https_post` |

## Boundaries and diagnostics

| Resource | Last successful case | First rejected case | Location of the rejection |
|---|---|---|---|
| Work | 100,000 units | 100,001 units | `work.tide:5:1` |
| Guest allocation | 4,194,304 bytes | 4,194,305 bytes | `allocation.tide:6:31` |
| Recursive calls | 48 | 49 | `limits.tide:17:21` |
| List produced by `lines` | 4,096 entries | 4,097 entries | `limits.tide:14:1` |
| UTF-8 batch read | 2 bytes for `é` | 1 byte granted | `io.tide:7:36` |
| Streaming measurement report | 9 bytes, three input lines | 8 bytes granted | `stream_report.tide:7:1`, input line 3 |
| HTTPS response body | 2 bytes for `{}` | 1 byte granted | `net.tide:6:4` |

The work fixture adds one function call in place of a literal. Both paths return zero when sufficient work is available. The allocation fixture creates 4,095 records of 1,024 logical bytes each. Its final UTF-8 conversion costs eight bytes plus its payload of 1,016 or 1,017 bytes. These figures describe TIDE's guest budget. [Work fixture](../../native/bootstrap/fixtures/parity/work.tide) · [Allocation fixture](../../native/bootstrap/fixtures/parity/allocation.tide)

Application cases cover order redelivery and cancellation, rollback after a rejected import, the signed integer limits in a measurement report, optional and unknown JSON fields, and invalid UTF-8. The receipts retain the defining module, line, column, input line, map index and JSON Pointer whenever the evaluator provides them. The escaped-key case checks the path `/limits/A~0~1B`. [Order contracts](../../apps/orders/checks.tide) · [JSON importer contracts](../../apps/report_packages/json_report.tide)

The AOT generator now emits text slicing and both search directions, pair construction and projection, variant construction and matching, and immutable record updates. Dedicated cases exercise a nested pair containing a record and a variant, an unselected failing match arm, Unicode search bounds, and allocation at the hard limit. [Native code generation](../../native/bootstrap/aot.tide) · [Pair examples](../../native/bootstrap/fixtures/functions/composite_pairs.tide) · [Variant examples](../../native/bootstrap/fixtures/functions/variants.tide)

## Reproduce locally

Run from the checkout on Linux x86-64 as an unprivileged user. The build uses the TIDE native toolchain, a C++20 compiler and static system libraries. The harness uses Bash, jq with decimal-number support, PostgreSQL server tools, OpenSSL and socat. Bubblewrap restricts networking to loopback. The PostgreSQL cluster accepts Unix-socket connections in a private temporary directory.

```sh
make -s -j4 install-native DESTDIR="$PWD/build/stage10/install"
bwrap --unshare-net --bind / / --dev-bind /dev /dev --proc /proc -- \
  env TIDE_CLI="$PWD/build/stage10/install/usr/local/bin/tide" \
  bash experimente/79_execution_parity/reproduce.sh > build/stage10/results.jsonl
diff -u experimente/79_execution_parity/results.jsonl build/stage10/results.jsonl
```

All three modes open real SQLite and PostgreSQL databases. PostgreSQL uses a new session and a temporary table for each invocation. For HTTPS, the named example uses a declared response map. The run and AOT paths use a local TLS connection to the compiled TIDE measurement service. Read and write examples use in-memory grants in test mode. The two process modes use real files, and the driver checks the five UTF-8 bytes written by each. Network transport faults, platform portability and performance require separate measurements.

The same machine passed `make test check-postgres`, including the bootstrap, package checks, atomic edits and the PostgreSQL service checks. The installed CLI also passed all 16 examples in `values.tide` in an isolated filesystem with neither Python nor a C++ compiler. Its help began with `usage: tide test FILE`; a selected success returned 4, a selected failure returned the original division-by-zero diagnostic, and an unknown name returned `E_EXAMPLE`. No model was invoked by the study.
