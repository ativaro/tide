# Stage 5 — public alpha decision

**Hold the public alpha.** A fresh installation reproduced the native order import's small-batch advantage. In the eight-event case TIDE beat CPython in all 12 pairs, with a median speedup of 3.13×. At 1,000 mixed events, CPython won all 12 pairs. Both implementations passed the same correctness checks. The roadmap accepts a verified advantage on a representative task and calls for an independent repeat on a second machine. This campaign used one physical workstation. The small-batch result supports a narrowly scoped performance claim. Public release awaits the independent hardware result. [Release criterion](../../tasks/plan.md) · [Replication protocol](protocol.md)

## Order import

Times are end-to-end medians in milliseconds for the final implementations. The ratios are medians of paired CPython time divided by TIDE time. Values above 1 favor TIDE. The interquartile range spans the 25th to 75th percentiles and the last column counts pairs won by TIDE.

| Entry points | Events | Stage 4 ratio | TIDE ms | CPython ms | Stage 5 ratio | Ratio IQR | TIDE wins |
|---|---|---:|---:|---:|---:|---:|---:|
| Native / bytecode | 8 mixed | 3.12 | 5.74 | 17.90 | 3.13 | 2.89–3.21 | 12/12 |
| Native / bytecode | 1,000 mixed | 0.46 | 45.33 | 22.42 | 0.49 | 0.48–0.50 | 0/12 |
| Native / bytecode | 1,000 redeliveries | 0.37 | 41.28 | 16.46 | 0.40 | 0.39–0.41 | 0/12 |
| Native / bytecode | Rollback at event 999 | 0.40 | 41.03 | 17.52 | 0.43 | 0.42–0.44 | 0/12 |
| Source CLI | 8 mixed | 1.04 | 18.25 | 18.89 | 1.05 | 1.00–1.07 | 9/12 |
| Source CLI | 1,000 mixed | 0.04 | 596.40 | 24.90 | 0.04 | 0.04–0.04 | 0/12 |
| Source CLI | 1,000 redeliveries | 0.04 | 585.42 | 18.92 | 0.03 | 0.03–0.03 | 0/12 |
| Source CLI | Rollback at event 999 | 0.03 | 601.85 | 19.33 | 0.03 | 0.03–0.03 | 0/12 |

Both compiled entry points were prepared before timing. Each measured import started a fresh process. Both received the same UTF-8 input and initial SQLite state, used one durable transaction per document, and had their full persisted rows and event ledger checked after exit. The source-mode comparison includes source loading and normal TIDE project checking. These results describe warm filesystem caches on Btrfs. [Stage 4 comparison](../73_bestellimport/report.md) · [Compiled observations](raw/orders/compare.json) · [Source observations](raw/orders/source.json)

All 24 ordered acceptance steps passed for interpreted TIDE, pre- and post-optimization native TIDE, and CPython. The two upgrade setup actions share the order-only TIDE producer in every arm. A late over-cancellation preserved the previous balance and discarded all writes from the failing document. All 13 TIDE examples and the clean checkout's full regression suite passed. In the isolated 1,000-event comparison, the original importer took 56.92 ms, the database change alone 50.85 ms, and both changes 46.33 ms. [Acceptance](raw/orders/acceptance.json) · [Profile](raw/orders/profile.json) · [Optimization breakdown](raw/orders/isolate.json)

## Where the small-batch advantage ends

The additional comparison changes the number of events per document. Each group of four contains the same order, cancellation and two redeliveries. Each size uses 12 fresh process pairs with six TIDE-first and six CPython-first pairs. Fixture generation and the inspection of committed data are outside the clock. [Measured pairs](raw/sizes.json) · [Changes to the original driver](size-sweep.patch)

| Events | Native TIDE ms | CPython bytecode ms | Paired ratio | Ratio IQR | TIDE wins |
|---:|---:|---:|---:|---:|---:|
| 8 | 6.56 | 19.31 | 2.86 | 2.56–3.12 | 12/12 |
| 32 | 6.94 | 19.73 | 2.89 | 2.56–3.22 | 12/12 |
| 128 | 11.62 | 20.85 | 1.79 | 1.60–1.98 | 12/12 |
| 256 | 15.80 | 19.03 | 1.22 | 1.13–1.26 | 11/12 |
| 384 | 21.36 | 20.56 | 0.97 | 0.91–0.99 | 2/12 |
| 512 | 26.82 | 21.58 | 0.80 | 0.74–0.84 | 0/12 |
| 1000 | 47.11 | 22.55 | 0.48 | 0.47–0.52 | 0/12 |

The change in the median winner falls between 256 and 384 events for this fixture and host. TIDE won 11 of 12 pairs at 256. At 384, CPython won 10 of 12 pairs and led by about 3% in the median. At 512 and 1,000 it won every pair. An exact break-even point or an event limit for other machines, payloads and storage systems cannot be inferred from these sizes.

## The 15 open programming tasks

Each arm received the same 15 open tasks and three public and four additional acceptance cases per reference solution. The historical replay uses TIDE 0.6.5 and the additional candidate run uses TIDE 0.6.6. Times below are medians for successful tool attempts. The writing control lets CPython evaluate all proposals for a task in one interpreter before independent acceptance.

| Campaign | TIDE solved | CPython solved | Protocol tokens TIDE / CPython | Tool time ms TIDE / CPython | Writing control ms TIDE / CPython |
|---|---:|---:|---:|---:|---:|
| Original Stage 3 | 9/15 | 9/15 | 3187 / 3583 | 11.85 / 31.08 | 8.96 / 21.10 |
| Historical replay | 9/15 | 9/15 | 3187 / 3583 | 13.01 / 34.05 | 9.46 / 23.02 |
| Release candidate | 9/15 | 9/15 | 3187 / 3583 | 13.13 / 33.17 | 9.40 / 23.52 |

Both new campaigns produced byte-identical protocols to the original study. In the candidate run, the median reference program took 5 ms in TIDE and 11 ms in CPython. Peak RSS medians were 4,480 and 10,600 KiB respectively. [Candidate observations](raw/current-tasks/observations.json) · [Candidate evaluation](raw/current-tasks/evaluation.json) · [Candidate writing control](raw/current-tasks/writing-control.json) · [Original protocol](../72_bestellimport_basis/protokolle.json)

The bounded tools solve public tasks deterministically. The offline counts cover the complete protocol for all 15 attempts in each language. Actual agent solve rate, tokens to a correct solution and agent repair time require model trials. The study ran with zero model calls. The 15 final tasks stayed sealed. [Per-task evaluation](raw/tasks/evaluation.json) · [Raw runtime, memory and search observations](raw/tasks/observations.json) · [Writing control](raw/tasks/writing-control.json)

## Reproduce offline

The order-import revision is `33f0972a2e001f3158630446f2e579ab355e0da1` (TIDE 0.6.6). The open-task baseline is `96c0a936b215ca21d3a58222b42ac96872f4d8b8` (TIDE 0.6.5). The campaigns used clean local Git clones without shared build products, an AMD Ryzen 9 9950X3D pinned to logical CPU 24, Linux 7.3.4-1-cachyos, CPython 3.14.10, and SQLite 3.54.1. Timed processes ran without network or home-directory access.

The compiled entry points, source-mode checkers, application sources, inputs and CPython reference matched the Stage 4 hashes. One profiling-only binary differed. The database-only build takes an absolute temporary source path, which the AOT compiler embeds in diagnostics. Generating code twice with different diagnostic paths produced identical output after substituting that path. Both the original and the new binary hashes are retained in the component-isolation records.

Run the commands below from a local clone containing the two pinned commits. Choose an output directory on disk. Set `TOKENIZER_JSON` to the frozen vocabulary and `TOKENIZER_PYTHON` to a local interpreter with `tokenizers` 0.23.3. Choose an available logical CPU with `TIDE_CPU`. The script uses the Linux build prerequisites, Node.js, zsh, CPython, the SQLite CLI, Bubblewrap and standard Unix tools. [Reproduction script](repeat.sh) · [Run receipt](receipt.json)

```sh
out=$(mktemp -d /var/tmp/tide-alpha.XXXXXXXX)
export TIDE_CPU=24
for phase in orders tasks sizes current-tasks; do
    sh experimente/74_alpha_review/repeat.sh "$phase" "$out" || exit 1
done
```
