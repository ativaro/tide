# Bracketed function bodies in a single pass

For Space Invaders, the preparation time for the repair context dropped from 1,214 to 211 ms. The stack query in TIDE generated a byte-identical view in all four projects as the previous workflow with a reference process per function.

| Project | Functions | Previous, full view | Stack query, full view | Factor per measurement pair, median |
|---|---:|---:|---:|---:|
| Jury | 5 | 310 ms | 146 ms | 2.15× |
| Depot | 5 | 310 ms | 144 ms | 2.16× |
| Nano, step | 14 | 665 ms | 167 ms | 3.96× |
| Space Invaders, tick | 26 | 1,214 ms | 211 ms | 5.78× |

Each project had two warm-up pairs and twelve measurement pairs with varying order. In all 48 measurement pairs, the new workflow was faster. For function queries alone, the median dropped from 173 to 8 ms for Jury and from 1,031 to 27 ms for Space Invaders. Both sides use the same revised planner. Previously, the Space Invaders plan exceeded the regular work budget. The runtimes in the table start with already built tooling. The first call with an empty build directory, including self-build up to outputting Jury functions, took 5.02 s. [Experiment plan](experiment-plan.md) · [Individual measurements, checksums, and measurement commands](messung.json)

For 33 source packages, all 661 rendered function bodies matched the reference parser. Functions imported multiple times are counted multiple times. An additional test checks an expression with protected and ideographic spaces, umlaut, and emoji. For seven invalid UTF-8 byte sequences, the public Status command returned 1, the diagnosis E_UTF8, and an empty standard output. The workbench used the previous fallback path for a valid, 4,202 codepoint-long source line and produced the same body. [Differential check and isolation protocol](pruefung.json)

The rebuild, five stack queries, the self-build test, all 14 help pages, and the build of twelve application files ran in a mount namespace without Python and without a reference starter. The twelve ELF files matched the previously saved SHA-256 values. The installed native package built Saldo and Licht also in a read-only prefix without Make, C++ compiler, and Python. For the pure grouping tool, the static program and standard input in an otherwise empty filesystem sufficed. Additionally, the 35 historical integration tests passed in the regular checkout.

The experiment measures local preparation. The total repair time of a model, the consumed model tokens, and the comparison against the Python development workflow were not remeasured in this experiment.
