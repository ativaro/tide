# How long an agent waits for the example context

A full context retrieval for a large Unicode example contract took 69 ms on 2026 November 17 with the previous TIDE package. With the new version, the same public call took 21 ms. The response bytes, including project revision, contract fingerprint, and node identifiers, were identical. [Individual measurements, checksums, and inputs](pruefung.json)

## Public Tools

The large contract belongs to the identity function `main txt:t > t`. Input and expectation each contain 7,000 repetitions of `🐈a`. The edit preview adds a blank line, checks the examples, and computes the new revision. For the small contract, the context for `balance` is queried in the unchanged balance program.

| Action | TIDE before | TIDE now | Historical TIDE interpreter on CPython |
|---|---:|---:|---:|
| Full context, large contract | 69.05 ms | 21.31 ms | 29.44 ms |
| Contract index only, large contract | 66.31 ms | 18.73 ms | – |
| Type and local bindings with `hole`, large contract | 32.29 ms | 12.76 ms | 29.45 ms |
| Checked edit preview, large contract | 85.55 ms | 25.46 ms | 29.93 ms |
| Full context, balance program | 6.00 ms | 5.81 ms | 29.07 ms |
| All 64 short contracts in the index | 9.13 ms | 7.75 ms | – |
| Full context, 14,000 ASCII-character | 13.54 ms | 8.80 ms | 28.95 ms |
| Full context, 14,000 varying Unicode characters | 70.07 ms | 22.28 ms | 29.61 ms |

Measurements were taken from process start to end on a Ryzen 9950 9X3D under Linux x86-64. The programs ran on the same logical core. After three warm-up rounds, 19 calls per version and task followed with rotating order. For all twelve tasks, the outputs of the old and new native packages were compared byte-by-byte. The historical interpreter lacks the two options for the contract index and the selection of a single contract in the context. Where both tools support the same call, the JSON results were compared structurally.

In three additional checks with 21 measurements each, the balance with 4,096 bookings was 6.49 ms before and 6.54 ms after. A function with 24 text parameters required 5.92 and 5.85 ms. The call with a short text argument in a project containing the large contract dropped from 30.76 to 11.20 ms.

## What Time Cost

1. The SHA-256 rounds determined bitmasks via a table generated in TIDE with 4,096 entries. The start compiler can now directly translate AND, XOR, and the rotation of a 32-bit word. SHA-256, padding, and UTF-8 processing remain in the TIDE module. Merely swapping the mask table reduced the large context to 48.72 ms. The profile of this intermediate state showed, among other things, 29.5 million calls to the arithmetic rotation over 18 context fetches. The final version rotates directly and generates the 48 loop positions for word extension once per hash. [SHA-256 in TIDE](../../native/bootstrap/sha256.tide) · [Start compiler](../../native/bootstrap/seed.tide)
2. The JSON reader had already decoded text values. For type checking, TIDE read the ASCII representation generated for hashing again subsequently. In the large contract, this resulted in 504,000 calls to the reader for hexadecimal escape sequences in 18 passes. Type checking now takes the decoded value via its full field path. The canonical representation remains available for contract comparison. [JSON binding](../../native/bootstrap/scalar_json.tide) · [Typed examples](../../native/bootstrap/samples.tide)
3. When encoding many special characters, the accumulator repeatedly copied the already written text. The encoder now collects output in sections of 64 code points and aggregates them page-wise. This limits copying work even with changing characters. The pre-run with rotation and reused text values was at 30.07 ms for the large context. [Encoder](../../native/bootstrap/json_text.tide)

## SHA-256 versus a standalone Python program

Both programs read 65,000 valid UTF-8 bytes from standard input. In the series with 64 passes, each process remained alive for its 64 hashes. From the second pass onward, the previous hexadecimal digest was prepended to the text. Each table cell is the median of eleven processes after three warm-up rounds. All results were checked against an independently calculated SHA-256. The TIDE measurement core was translated with the internal start compiler. Python 3.14.10 used `hashlib.sha256`. [Both measurement programs and individual times](pruefung.json)

| Work per process | TIDE before | TIDE now | CPython with hashlib |
|---|---:|---:|---:|
| One hash including process start | 12.33 ms | 2.51 ms | 5.49 ms |
| 64 chained hashes including a process start | 746.21 ms | 123.79 ms | 8.70 ms |

For the 64 hashes, TIDE requires 14.2 times as long as CPython with its optimized library. The unchanged response bytes of the context tools yield the same number of response tokens with the same tokenizer. For the total repair time and model consumption, there was no new blind run in this experiment.

## Precheck

- 147 byte sequences were compared directly with an independent SHA-256 implementation. They covered empty inputs, control characters, Unicode, padding boundaries, the switch of the internal group after 256 blocks, and up to 131,072 input bytes. Two known fingerprints at the group boundary and checks for the sign bit and rotation are permanently in the TIDE tests. [Hash checks](../../native/bootstrap/inspection_checks.tide) · [Compiler checks](../../native/bootstrap/compiler_checks.tide)
- 50 project contexts from 25 pairs of equivalent JSON spellings yielded the expected contract fingerprints. Separately checked were the revision of the respective source file and the 50 associated example executions. An edit preview accepted the other spelling of the same contract. A changed expectation yielded `E_CONTRACT`.
- 553 comparisons for text and tools, 77 resource and diagnosis cases, and 1,041 node edits passed again. For nine complete `fold` replacements, the expected source bytes were determined independently because the historical editor aborts there.
- The isolated rebuild from an empty directory succeeded without Python, Python library, and experiment archive. All six installed tools were statically linked and byte-identical with a second build. Twelve ELF checksums and the tests for compiler, editor, Nano, and Space Invaders passed. The Bootstrap uses a C++20 system compiler. The new word operations are internal. Homonymous freely declared functions were checked in the public `run` and `forms` with both package versions.
