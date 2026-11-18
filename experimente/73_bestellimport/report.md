# Order import, cancellations and redelivery

Stage 4 implements the purchasing contract as a TIDE application backed by SQLite. On the 1,000-event mixed workload, native AOT import fell from **54.11 to 45.65 ms**. CPython took **20.78 ms** in the same comparison. On eight events the final native program was **3.12× faster** than CPython by paired elapsed time. [Purchasing contract](../72_bestellimport_basis/order-import.md) · [Application entry point](../../apps/orders/import.tide)

## What persists

An order creates a line. A cancellation reduces its outstanding quantity at the original unit price. The ledger uses the supplier and event ID as its key and compares the business fields on redelivery. Line and ledger writes share one `BEGIN IMMEDIATE` transaction. An invalid event rolls it back. The public lookup returns original quantity, outstanding quantity and outstanding value in cents. [Storage operations](../../apps/orders/store.tide)

The restart scenario starts with an order-only entry point, then opens the same database with the cancellation-capable importer. Two units cancelled from three at 125 cents leave one unit worth 125 cents. A subsequent document creates a second line and then requests an excessive cancellation. Its second event fails at `/events/1/qty`. A separate process sees the original line at 125 cents and no second line. The complete SQL dump, including the event ledger, matches its pre-failure state. [Order-only entry point](v1.tide) · [Ordered TIDE scenarios](restart_cases.tide)

The 24 restart steps passed for interpreted TIDE, both native builds, and the CPython reference. The two upgrade setup actions use the same TIDE order-only producer in each arm. Acceptance covers redelivery before and after restart, conflicting event contents, position conflicts, independent suppliers, invalid UTF-8, field paths, a valid document above 128 KiB with 1,000 events, 1,001 events, and the explicit 4 MiB byte limit. The 13 native TIDE examples also passed in a namespace without Python. [Acceptance results](acceptance.json) · [Executable examples](../../apps/orders/checks.tide)

## Where the time went

Before optimization, 12 paired blocks attributed **28.34 ms** to validation, applying events and committing, **26.78 ms** to typed JSON decoding, and **1.19 ms** to starting the process and reading the file. These are differences between progressively more complete programs. The database phase also includes business validation. The clean rerun measured 26.98, 26.41 and 1.08 ms respectively. [Initial profile](discovery.json) · [Repeat profile](profile.json)

1. Let SQLite enforce event and line uniqueness on insert. Perform a guarded decrement for cancellations. Read a line separately only when the decrement fails and the error reason must distinguish an unknown line from an excessive cancellation. On redelivery, compare the canonical event fields in SQLite. This removed the routine position lookup and reconstruction of complete duplicate records.
2. Build the JSON Pointer only on a decoding error. Valid fields previously reconstructed and escaped their ancestor path for every token. The diagnostic tests exercise the same field paths after the change.

In the separate 1,000-event run that changes one component at a time, the baseline took **53.83 ms**, the database change alone **48.77 ms**, and both changes **45.24 ms**. [Isolated measurements](isolate.json) · [Patch that reconstructs the pre-optimization source](baseline.patch)

## End-to-end time in milliseconds

Each cell is the median of 12 fresh processes. The unchanged CPython reference ran twice per block. Input generation, compilation and independent database inspection are outside the timed interval. File open, decoding, validation, transaction, output or error, and process exit are inside it.

**TIDE native AOT and CPython bytecode**. Both entry points were compiled before timing. Python still starts its interpreter and imports its standard-library dependencies.

| Workload | TIDE before | CPython control 1 | TIDE after | CPython control 2 |
|---|---:|---:|---:|---:|
| 8 mixed events | 5.26 | 16.30 | 5.26 | 16.69 |
| 1,000 mixed events | 54.11 | 20.46 | 45.65 | 20.78 |
| 1,000 redeliveries | 45.68 | 15.98 | 42.87 | 15.96 |
| Rollback at event 999 | 50.47 | 16.43 | 42.01 | 16.72 |

For 1,000 mixed events, the median paired TIDE speedup was 1.18×. CPython was 2.20× faster than final TIDE. The middle half of the final TIDE observations was 45.30–47.26 ms and the corresponding CPython interval was 20.49–21.17 ms. [All paired AOT measurements](compare.json)

**Source CLI comparison**. TIDE runs `tide run`. CPython runs the reference source in a fresh interpreter. These figures include normal source loading and TIDE project checking.

| Workload | TIDE before | CPython control 1 | TIDE after | CPython control 2 |
|---|---:|---:|---:|---:|
| 8 mixed events | 18.15 | 18.35 | 17.02 | 17.88 |
| 1,000 mixed events | 672.02 | 22.62 | 588.39 | 22.06 |
| 1,000 redeliveries | 652.74 | 22.46 | 585.97 | 22.33 |
| Rollback at event 999 | 654.34 | 17.88 | 571.72 | 17.86 |

The difference between the installed TIDE CLI and the precompiled executable matters on this workload. Only the eight-event AOT comparison supports a pronounced TIDE advantage. [All source CLI measurements](source.json)

## Reproduction

Both implementations receive identical UTF-8 documents, a fresh on-disk database or an identical preseeded database, the same transaction boundary, bound parameters, and SQLite 3.54.1 with its default rollback journal and synchronous settings. A mixed group contains an order, its redelivery, a partial cancellation and its redelivery. Redelivery-only runs start from the committed result. The failing case replaces the last event with an excessive cancellation. The driver checks the receipt or error and every persisted line and ledger entry outside the clock. [Timing driver](measure.mjs) · [CPython reference](cpython_import.py)

The runs used CPU 24 of an AMD Ryzen 9 9950X3D, Linux, Btrfs and CPython 3.14.10. Each workload had one unmeasured warm-up per arm, then balanced rotations of the process order. This is warm filesystem-cache performance with a fresh process per import. Source and binary hashes accompany the raw measurements. The experiment uses synthetic purchasing inputs and local tools. The final 15 tasks, model inference and agent-token measurements are outside this study.

Run from the checkout root on Linux with the native build prerequisites, Node.js, CPython, SQLite CLI, Bubblewrap, taskset and patch installed. Set `TIDE_CPU` to choose an available core.

```sh
sh experimente/73_bestellimport/reproduce.sh
```
