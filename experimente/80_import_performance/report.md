# Stage 11 · Order import performance

On the 1,000-event order import, the native TIDE executable improved from **42.56 to 39.09 ms**. It finished sooner in all 12 paired blocks. CPython took **19.93 ms**. At eight events the optimized native process took **5.19 ms** against CPython's **16.79 ms**. The eight-event result comes from native startup and shows no consistent gain from the decoder change. [Raw CLI observations](compare.json)

## File imports

Fresh processes, on-disk SQLite. Times are median milliseconds. The first row measures a minimal native entry point and a CPython process that imports the reference's standard-library modules. The empty-import row uses the real application and commits the schema.

| Workload | TIDE before | TIDE after | CPython | Peak MiB before / after / CPython |
|---|---:|---:|---:|---:|
| Startup probe | 0.44 | 0.45 | 11.86 | 1.83 / 1.84 / 12.14 |
| Empty import | 4.96 | 5.40 | 16.70 | 3.73 / 3.72 / 13.14 |
| 8 mixed events, 754 B | 5.26 | 5.19 | 16.79 | 3.73 / 3.72 / 13.16 |
| 1,000 mixed events, 90,530 B | 42.56 | 39.09 | 19.93 | 12.59 / 12.88 / 13.84 |
| 1,000 mixed events with Unicode SKUs, 93,030 B | 42.28 | 39.09 | 20.58 | 12.61 / 12.89 / 14.05 |
| Rejection and rollback at event index 999 | 38.20 | 34.64 | 15.86 | 12.88 / 12.88 / 13.85 |

On the large ASCII input, throughput rose from **23,499 to 25,582 events/s**. CPython reached **50,174 events/s**. The paired TIDE speedup was 1.08×. The middle half of the paired time savings was 2.87–3.83 ms. Peak memory rose by 296 KiB. The Unicode workload improved in 11 of 12 blocks. At eight events throughput was 1,520 / 1,540 / 476 events/s respectively, but the optimized build beat the old build in only three blocks. Comparing TIDE after the change with CPython gave a paired 3.12× advantage at eight events and a 1.98× disadvantage at 1,000. [Times, memory and fixture hashes](compare.json)

| Estimated phase, ms | 8 before | 8 after | 1,000 before | 1,000 after |
|---|---:|---:|---:|---:|
| Startup | 0.41 | 0.40 | 0.45 | 0.45 |
| Read input bytes | 0.04 | 0.04 | 0.41 | 0.41 |
| UTF-8 conversion | <0.01 | <0.01 | 0.27 | 0.29 |
| Typed JSON above the UTF-8 probe | 0.24 | 0.28 | **20.52** | **16.82** |
| Validate text and quantities, construct ledger entries | 0.08 | 0.08 | 5.16 | 5.32 |
| Apply events in SQLite and commit | 4.41 | 4.55 | 16.27 | 16.35 |

On the large input the decoder phase took **18% less time**. Its remaining cost is close to the cost of applying the batch in SQLite. The final measurements were taken after compilation and regression checks finished, using the same executables as the clean-baseline build. The machine was a Ryzen 9 9950X3D running Linux x86-64 on Btrfs. Both implementations used SQLite 3.54.1, with CPython 3.14.10. Building the importer once with the installed toolchain took 26.13 s before and 26.42 s after. Precompiling the CPython reference took 0.021 s. [Build times](build-seconds.tsv) · [Machine and binary identities](compare.json)

## Source execution and warm services

| Entry point and events | TIDE before, ms | TIDE after, ms | CPython, ms |
|---|---:|---:|---:|
| Source CLI, 8 | 16.90 | 17.66 | 17.08 |
| Source CLI, 1,000 | 554.99 | 548.33 | 20.79 |
| Warm HTTP worker, 8 | 5.43 | 5.21 | 5.28 |
| Warm HTTP worker, 256 | 16.86 | 15.76 | 6.09 |
| Warm HTTP worker, 1,000 | HTTP 500 | HTTP 500 | 10.05 |

The source comparison uses installed `tide run` and the CPython reference source. It includes normal project loading and checking. The pronounced small-import startup advantage belongs to the precompiled TIDE executable. [Source CLI samples and peak memory](source.json)

The warm comparison keeps one process per arm alive and sends the same bytes over a fresh loopback HTTP connection. Each request opens a new SQLite database and uses the original import transaction. The TIDE handler invokes the shared package decoder and `import_document`. The CPython HTTP baseline calls the same decoder and importer as its CLI, with the file reader split at the byte boundary. [TIDE handler](service.tide) · [CPython HTTP baseline](warm_reference.py) · [Warm timings, peak memory and rejections](warm.json)

At 1,000 events both native HTTP builds exhausted the 100,000-unit guest work budget at `model.tide:20:38` and rolled back. Both returned HTTP 500 in every measured block, leaving the database empty. The file importer receives additional work credit from its explicitly bounded `read_batch`. The HTTP body does not receive that credit. The successful CPython result therefore has no paired TIDE throughput at this size. [Observed native diagnostics](warm-limit.json) · [Budget implementation](../../native/bootstrap/run_inputs.tide)

## Correctness

Both TIDE builds rejected the late cancellation at `model.tide:24:1`. CPython and TIDE agreed on `E_DATA`, reason `over_cancel`, input index 999 and path `/events/999/qty`. All 24 ordered restart, redelivery and rollback steps passed in each of the four acceptance arms. Eleven decoder cases preserved the complete values and diagnostics across both revisions, named tests and AOT, including duplicate escaped keys, malformed numbers, control characters and unknown nested fields. [Restart checks](acceptance.json) · [Decoder cases](scalar_records.tide) · [Exact decoder observations](edges.jsonl)

The full native regression and PostgreSQL integration checks passed. The Stage 10 matrix reproduced all 78 receipts byte-for-byte with the optimized installation. The installed checker also passed the 11 decoder examples in a filesystem without Python or a C++ compiler. All measurements used this one workstation. [Stage 10 reference receipts](../79_execution_parity/results.jsonl)

## What changed

The discovery run attributed 20.61 ms of the 1,000-event import to typed JSON decoding, 17.38 ms to applying events and committing, and 4.64 ms to business validation and entry construction. At eight events the database phase dominated at 4.78 ms. The optimization targets the large import. [Discovery measurements](discovery.json) · [TIDE profiling entry points](phases.tide)

The public JSON decoder now consumes consecutive scalar fields of a named record in one pass through the existing tokenizer. It carries the current record through that loop and attaches it to the enclosing value once. The tokenizer still enforces JSON syntax and duplicate keys. A nested value or a rejected scalar returns to the general decoder at the original object position, so it can issue the same precise diagnostic. Short JSON strings, numbers and whitespace also scan by advancing a code-point index. This removes the temporary lists of indices previously constructed for these scans. The application, schema, transaction logic and language budgets are identical in both builds. [Typed record decoding](../../native/bootstrap/public_data.tide) · [JSON number scanner](../../native/bootstrap/json_stream.tide) · [String reader](../../native/bootstrap/json_text.tide)

## Measurement protocol

The baseline is Stage 10 commit `ba43358`. Both native executables and the CPython reference bytecode were built before measuring imports. Each CLI invocation starts a new process with warm filesystem caches. The timer includes process startup, file reading, schema validation, SQL, durable commit or rollback, result emission and process exit. Startup is reported both as a lower-bound probe and as an empty import through the complete application. Input generation, database reset and inspection are outside the timer. [Driver](measure.mjs) · [Unchanged CPython reference](../73_bestellimport/cpython_import.py)

Each group of four events contains an order, its redelivery, a cancellation and its redelivery. The ASCII files and the late-error file match the Stage 4 input hashes. A second large input uses `Pièce猫` as the SKU. Each arm receives identical bytes and a new on-disk SQLite database with the same default durability settings. The driver checks the receipt and every persisted business and ledger field via a separate SQLite process. For a rejected fresh import it verifies that the transaction also rolled back schema creation. Both implementations use parameterized SQL and one `BEGIN IMMEDIATE` transaction. Their statements and runtime libraries can differ. [Order contract](../72_bestellimport_basis/order-import.md) · [Storage implementation](../../apps/orders/store.tide)

Each workload has one discarded warm-up per arm and 12 measured blocks on one CPU. Starting positions rotate and the sequence reverses on alternating cycles. Tables report medians. Throughput divides the event count by median elapsed time. Paired speedups divide elapsed times within each block before taking the median. The CLI memory figure is the kernel's peak resident set for the child, collected by zsh. The warm-service memory figure is the server process's cumulative high-water mark.

The phase probes add a bounded raw read, UTF-8 conversion, typed decoding, text and quantity validation with entry construction, and finally the real SQLite importer. The table uses median within-block differences between adjacent probes. The SQL increment also includes database open, event dispatch, receipt creation and commit. The UTF-8 probe uses the same bytes as the typed decoder. These are estimates from separate processes, so tiny differences can be negative and the increments need not sum to the end-to-end median. [Baseline phase samples](pre.json) · [Optimized phase samples](post.json)

## Reproduction

From the repository root, run `bash experimente/80_import_performance/reproduce.sh`. It builds the pinned baseline from local Git objects, builds the current checkout, regenerates workloads and writes the raw outputs to `build/stage11-results`. Set `TIDE_CPU` to an available logical CPU for another machine. The run requires the native TIDE toolchain, PostgreSQL and HTTPS build dependencies, CPython with sqlite3, the SQLite CLI, Node.js, jq, zsh and Bubblewrap. Benchmark traffic stays inside a private loopback network. All fixtures are public. No model calls enter the experiment.
