# Order import · Initial measurement for stages 1 to 3

**The local tools solve 9 of 15 open tasks.** These are three writing, two extension, and four repair tasks. TIDE requires 3,187 in the main run, CPython 3,583 offline-counted protocol tokens including the six unsuccessful attempts. The actual development performance of a language model remains open. No additional models ran. [Specification of the order import](order-import.md) · [Open cases with acceptance tests](aufgaben.json) · [Evaluation per task](auswertung.json)

| Metric | TIDE 0.6.5 | CPython 3.14.10 |
|---|---:|---:|
| Success of limited tools | 9/15 | 9/15 |
| Correct reference programs | 15/15 | 15/15 |
| Tool time from start of search to correct acceptance, median | 11.85 ms | 31.08 ms |
| Median over all trials until acceptance or abstention | 10.02 ms | 29.74 ms |
| Offline protocol tokens for all 15 trials | 3,187 | 3,583 |
| Of these input / output | 2,920 / 267 | 3,271 / 312 |
| All protocol tokens divided by correct solutions | 354.1 | 398.1 |
| Reference program with process start, median | 5 ms | 10 ms |
| Median of peak RSS per reference process | 4,166 KiB | 10,600 KiB |

The median of the paired time ratios CPython/TIDE is 2.49 for successful tool runs. For the reference programs, it is 2,20. The program runtime includes the start and the JSON input and output for **a small specific case**. The clock for this measurement has millisecond resolution. This sample describes neither the sustained throughput nor the complete order import. [Raw measurements and environment](messung.json)

| Task family | Success per language | Protocol tokens TIDE / CPython | Time to success TIDE / CPython |
|---|---:|---:|---:|
| Write | 3/5 | 807 / 855 | 9.03 / 99.23 ms |
| Expand | 2/5 | 1,118 / 1,278 | 12.04 / 29.32 ms |
| Repair | 4/5 | 1,262 / 1,450 | 12.53 / 30.13 ms |

**Write time depends heavily on process partitioning.** In the main run, each language checks every draft in a fresh process. In a subsequent control, CPython compiles and checks all proposals of a task in the same interpreter and starts a second one for independent acceptance. On the same three successful tasks, Python time drops from 99.23 to **21.10 ms**. TIDE was measured again in varying order in parallel and took **8.96 ms**. The paired ratio in this control is **2.39**. Both variants chose byte-identical solutions as in their language's main run. [Control Arm](cpython_entwuerfe.py) · [Control Measurement](kontrollmessung.json)

## The 15 open tasks

[English task descriptions](public-tasks.md) · [Frozen benchmark inputs](aufgaben.json)

| Family | Scope | Result |
|---|---|---|
| Write | W01 Position value, W02 available quantity, W03 shipping label, W04 quantity from JSON, W05 receipt IDs in SQLite | Both solve W01 to W03. The fixed expression templates cannot decode JSON nor write a database transaction. |
| Expand | E01 including discount limit, E02 UTF-8 billing, E03 delivery, E04 correction entries, E05 new freight tariff | Both solve E01 and E02. For E05, the pair search ends at the budget of 64. |
| Repair | R01 delivery balance, R02 control value over two files, R03 invoice fee, R04 carton remainder, R05 status identifier | Both solve R01 to R04 and refrain from R05. |

For all 15 components, there are correct references in both languages. Before timing, each consisted of three public and four additional cases. For tasks with intermediate modules, both interfaces were called. For the SQLite case, two processes were also sequentially applied to the same file and the stored IDs including apostrophe and Unicode were checked via the SQLite-CLI. The templates and repair search receive only the public cases and start sources during their decision. [Output Programs](start) · [Reference Sources](referenzen)

## Which 15 tasks remain held out

There are a total of **ten tasks per family**, with five open and five held out. The additional final sample was drawn locally from domain tasks with input range, signature, starting state for changes or repairs, public examples, and separate acceptance cases. The specific selection and inputs were sealed before the reference implementation. A read comparison of the encrypted and decrypted data was performed during creation. The measurement process saw neither task package nor key. The 15 final tasks were not executed. The additional cases of the **open** tasks are visible here for rechecks. [Sealing proof](versiegelung.json) · [Pre-fixed check values](vertrag.sha256)

The repository contains, per held-out task, only the family and the salted SHA-256 proof, as well as the hash of the encrypted total package. The AES-256-GCM package lies locally under `~/.local/share/tide/holdouts/bestellimport-v1/schlussaufgaben.enc`, the separate key under `~/.config/tide/holdout-keys/bestellimport-v1.key`. Both files have mode 0600. For later opening, **both local files** are required. The format is eight bytes ASCII `TIDE72G1`, twelve bytes IV, 16 bytes GCM tag, followed by ciphertext. The check values of individual tasks refer to the UTF-8 bytes of `JSON.stringify(task)` including the random nonce.

## Equal conditions

- Tasks, inputs, expectations, budgets, search order, and metrics were fixed ahead of time. The main measurement runs the standard-CLI `tide run` and CPython with isolated module path and without bytecode cache. Both receive the same data and rights. The tested subtasks use the documented input range respectively. [Measurement plan](messplan.json) · [Tool and source checksums](werkzeuge.sha256)
- Writing starts with an empty source directory. The finite template list is semantically and in order identical for both languages. Extending and repairing start with three modules and public check at the entry and at the intermediate function. Both tools can check up to 32 single edits and 64 pairs. Their language-specific nodes differ at E04 (Python uses `sum`) and R05 (text comparison). The first publicly green proposal must pass the final acceptance in a fresh process. [Templates](vorlagen.json) · [Previous module check](../71_modulvorpruefung/report.md)
- Tool time includes search, public check, takeover, and independent acceptance. Creating the initial project lies outside the clock. An abstention counts as an unsuccessful attempt. For programming time, only correct reference sources run, each on the first additional acceptance case. The table reports the median of individual times. For the factor, it is divided per pair and then the median is taken.
- One warm-up pair per task, followed by four search pairs and eight runtime pairs, balanced start order and rotating task order. This results in 120 measured search runs and 240 measured reference calls on CPU 24 of a Ryzen 9 9950X3D. The Linux namespace provides only loopback. The home directory is not mounted. The peak RSS comes from the process counter of zsh.
- The local Llama-BPE tokenizer counts a complete deterministic protocol per task and language. Recorded are task, signature, start sources, public cases, offered changes, decision, and status. The measured time repetitions had identical protocols. Token counting excludes model or thought tokens. [Protocols](protokolle.json) · [Offline evaluation](auswerten.mjs)

## Measure locally

From the repository directory, the following commands generate a local installation and update the two result files of the main run. Required are Linux, bwrap, taskset, zsh, Node.js, CPython, and the SQLite-CLI. `TIDE_CPU` selects another single available core if needed. The sealed task package is not needed for repetition.

```sh
d=experimente/72_bestellimport_basis
stage=$(mktemp -d)
make -s install DESTDIR="$stage"
export TIDE_BIN="$stage/usr/local/bin/tide"
sh "$d/lokal-messen.sh"
```

The control measurement uses the same network and filesystem exclusion. It requires only the open sources and protocols. From the same repository directory:

```sh
out=$(mktemp -d)
bwrap --unshare-all --tmpfs / --ro-bind /usr /usr --symlink usr/bin /bin \
  --symlink usr/lib /lib --symlink usr/lib /lib64 --proc /proc --dev /dev --tmpfs /tmp \
  --ro-bind "$PWD/$d" /study --ro-bind "$stage/usr/local" /opt/tide \
  --ro-bind "$(command -v node)" /opt/node --bind "$out" /result --clearenv --setenv PATH /usr/bin \
  --setenv LC_ALL C.UTF-8 --setenv TIDE_BIN /opt/tide/bin/tide --setenv RESULT_DIR /result \
  taskset -c "${TIDE_CPU:-24}" /opt/node /study/kontrolle.mjs
cp "$out/kontrollmessung.json" "$d/"
```

For offline evaluation, `TOKENIZER_JSON` and `TOKENIZER_PYTHON` must point to the vocabulary with the hash from the measurement plan and a local interpreter with `tokenizers` (here 0.23.3). Then `node "$d/auswerten.mjs"` is sufficient. The acceptance data, measurement series, and checksums remain individually verifiable. The sources of the TIDE and CPython references for E/R result from the respective start directory and the same-named files under `referenzen`, which replace the corrected modules.
