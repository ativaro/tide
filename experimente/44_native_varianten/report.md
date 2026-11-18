# Native variants and the cost of the repair context

In case of a tie, the older identifier shall win. For identifiers 19 and 7, the program returned 19. The second error concerned rounding to whole units. With 25 tenths and the rule "to the even number", the program returned 3. The target value is 2. In both cases, the faulty helper function was in the imported module. For each language, the prepared finding contained input, expectation, result, revision, types, and the reachable function bodies. [Test programs](../../native/bootstrap/fixtures/functions/variants.tide) · [Modules, comparison sources, and complete findings](messung.json)

| Generated Finding | Tie, Tokens | Time | Rounding, Tokens | Time |
|---|---:|---:|---:|---:|
| TIDE, statically reachable | 277 | 5.86 ms | 293 | 6.01 ms |
| TIDE, actually executed | 272 | 5.82 ms | 315 | 6.02 ms |
| CPython, statically reachable | 310 | 16.45 ms | 315 | 15.94 ms |

In case of a tie, the helper function for the newer identifier is omitted in the executed view. The recorded branches for `oldest` and the comparison in `smaller` cost almost as much space as the omitted definition. In rounding, only `upper_units` with its short body is omitted. The finding additionally lists the paths through sign check, remainder comparisons, variant selection, and parity test. This costs 22 tokens compared to the static TIDE view.

Each time is the median of 21 serial process calls after three warm-up rounds on logical core 2 of a Ryzen 9 9950X3D. The start order changed per round. The time includes determining the error and providing the context until process end. The output tokens include the complete JSON response with line endings, counted with `o200k_base`. The external CPython 3.14.10 helper loads both modules, runs the target examples up to the first error, and determines the reachable definitions and types from the syntax tree. The Python finding contains the positions of the function bodies, TIDE additionally the source position of the failed example. For this experiment, no model sessions were started. The sample measures neither a model's thinking and input tokens nor its time until successful repair.

The node identifier from each executed finding was sufficient to apply the known correction with `tide edit` first in preview and then writeably. Subsequently, the two public tie tests and the five rounding tests passed. For both languages, additionally 50 combinations of identifiers and direction and 100 combinations of tenths value and rounding rule were checked against independently calculated target values. Before the change, 20 and 5 of these combinations were incorrect. Afterwards, all passed. The rounding matrix also includes the public values.

## An additional phase in the game

In a copy of the game, only `intermission` was appended to the declaration of `Phase`. The previous package reported `E_BACKEND`. The new `tide check space_invaders.tide` reports two entries under `E_MATCH` in a single call. They point to `draw` in the entry file at line 72 and to `tick` in `invaders_game.tide` at line 140, both at column 1. The full call took a median of 15.45 ms. With `invaders_checks.tide` as the entry point, its own phase decision is added. After adding `tick` and then `draw`, the number of open positions dropped from three to two and one. The unchanged game still requires lists of records for full public execution. The bootstrap tests continue to run game and editor logic.

Variant values and direct variant fields in records run in the public project analyzer. During parsing, it assigns each variant its branch. During execution, `match` reads the matching branch via this index. A test with 64 in reverse-ordered branches selected the correct value for each label. An unknown marker at `edit --write` resulted in `E_TAG` and the source file remained byte-identical. The container check builds and installs tools without Python, runs all ten variant examples, and requires both reports for the additional game phase. [Container check](../../native/bootstrap/no-python.Dockerfile)

| Full call | Prototype with name search | Indexed version |
|---|---:|---:|
| A decision with 64 cases | 5.82 ms | 5.81 ms |
| 4,096 decisions with 64 cases each | 24.90 ms | 23.72 ms |

The balance control with 4,096 transactions required 7.29 ms in the package before the variant extension and in the new version. Besides branch selection, the check of complete branch lists upon reading also changed. Process times include both. [Individual times, checksums, and acceptance test](messung.json)
