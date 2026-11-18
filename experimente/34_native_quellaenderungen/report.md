# Fully check and write native source changes

`tide edit DATEI --base REV --source KANDIDAT` checks a new entry file in the original project. An agent can prepare the candidate in a different directory, import additional modules, and test the entire change before writing. `--write` takes over the checked text. The previous native starter reported `E_BACKEND` for both calls. [Executable balance example](../../README.md#check-and-accept-a-change)

## What an adoption requires

The base revision includes the original entry file and its transitive imports. TIDE checks the revision before loading the candidate. It compares example contracts by name and content. Reordered JSON fields are equivalent. A changed expectation, a new target, or the deletion of an existing example requires `--change-examples`. Added examples are immediately allowed. Even with explicitly allowed contract changes, the type check and all examples of the candidate must pass.

A takeover holds a lock on the project directory. The compiler grants read permissions for the project sources and the named candidate to the TIDE function. With `--write`, the right to replace the target file is added. TIDE makes the content available in a temporary file in the target directory, rechecks the sources of both project versions, and only then grants the file replacement. The temporary file inherits the mode bits of the target. File and directory are synchronized. The lock coordinates TIDE writers. Foreign editors can write between the last check and the rename. [Decisions in TIDE](../../native/bootstrap/editor_transaction.tide) · [Contract comparison](../../native/bootstrap/editor.tide) · [Bootstrap and file operations](../../native/bootstrap/seed.tide)

## Runtime until tool response

The complete CLI call was measured on a AMD Ryzen 9 9950X3D under Linux x86-64. The historical reference processes the same TIDE files with CPython 3.14.10. The first native version in the table already handles the comparison of large contract volumes. It still uses the previous contiguous list representation and re-encodes the candidate text for the preview. After three warm-up rounds, all three tools ran in rotating order on the same logical core. Medians over 15 rounds each are shown, seven for the large catalog swap. Write measurements each started with the original file. [Individual times, hashes, and check results](pruefung.json)

| Task | First native version | Native now | Historical TIDE reference |
|---|---:|---:|---:|
| Check balance candidate | 6.01 ms | 6.00 ms | 29.08 ms |
| Take over balance candidate | 7.67 ms | 7.70 ms | 30.98 ms |
| Check candidate with imported function | 6.62 ms | 6.58 ms | 29.52 ms |
| Take over candidate with imported function | 8.39 ms | 8.40 ms | 31.47 ms |
| Report unconfirmed contract change | 5.80 ms | 5.77 ms | 29.06 ms |
| Report failed example | 5.85 ms | 5.86 ms | 29.12 ms |
| Report outdated revision | 5.43 ms | 5.40 ms | 28.46 ms |
| Check contract with 4,096 i64 inputs | 48.44 ms | 43.52 ms | 30.99 ms |
| Take over contract with 4,096 i64 inputs | 45.81 ms | 46.17 ms | 33.10 ms |
| Replace 2,100 examples with 2,100 others, preview | 622.33 ms | 171.19 ms | 69.49 ms |

## What the measurements changed

The first comparison algorithm merged the names from both versions into a list. Thus, the preview already failed for two individually valid files with a combined 4,200 different names. TIDE now traverses both sorted name sequences in parallel and builds the report in sections. The 4,200 entries matched the reference in the individual comparison.

Subsequently, the profile showed repeated copies of existing elements when building lists for declarations and examples. The Bootstrap now stores lists of texts, records, and other class values in shared pages with 16 elements each. When appending to a shared list, the full pages can be retained. For numbers, booleans, and variants, storage remains contiguous. In the precheck with a page structure also for numbers, direct preview for the large i64 list slowed from 43.74 to 50.16 ms. The chosen partitioning took 44.45 ms there. Despite the improvement, the catalog swap is still 2.46 times slower than the historical reference in the final CLI comparison. [Bootstrap checks for different list versions](../../native/bootstrap/compiler_checks.tide)]

Preview now uses the already encoded source from the project snapshot. For the balance, the response dropped from 262 to **235 tokens**, for the imported function from 420 to **367**. The reference yielded 247 and 379 tokens. The large list preview continues to yield **32,904 tokens**, as `--source` returns the full suggested text in preview. The total standard output was counted, or in case of errors, the diagnosis with `o200k_base`. Total tokens of a model run and time until a blind repair were not measured here.

## Acceptance on 17 November 2026

- A full self-build with an empty build directory, tests, and package installation ran without Python and without an experiment archive. The six installed native tools matched byte-for-byte with the separate local package build. All twelve existing ELF checksums for the applications passed. The isolated installation checked and wrote a balance change and rejected the repetition with the outdated revision.
- At 44 starting conditions, preview and writing were compared with and without consent to contract changes. All **176** attempts matched the reference in status, output channel, JSON content, target bytes, and mode bits. 78 were successful calls. The cases included new, deleted, and faulty imports, changed contracts, an already faulty initial version, CRLF, Unicode, i64 limits, and the size limit.
- Twelve groups of eight simultaneous TIDE writers each started with the same revision and different candidates. Each group had exactly one takeover. All 84 subordinate calls reported `E_REVISION` with the taken-over revision. In ten further attempts, an external writer changed a newly imported module during the preparation of the target file. All ten takeovers aborted and left the original entry file intact.
- The previous **1,950** comparisons for type checking, evaluation, rules, inspection, fingerprints, and diagnoses passed again. A separate test with GCC and Clang under UndefinedBehaviorSanitizer confirmed the original values after branched appending for each of 19 list lengths up to 4.096. [Permanent editor checks in TIDE](../../native/bootstrap/editor_checks.tide)

The native editor supports full candidates for projects within the scope of the native checker. Revision-bound changes to individual syntax nodes with `--edits`, the general execution of text and record functions, and interactive terminal integration remain open.
