# TIDE · Development status

## Roadmap in 20 stages

The checkboxes represent the acceptance of the respective roadmap stage. Existing sub-functions and completed individual experiments are documented in the development status below. [Goals and acceptance criteria](plan.md#20-stages-from-feasibility-study-to-leading-language)

- [x] 1. Define the first use case and success metric. [Order import and acceptance](../experimente/72_bestellimport_basis/order-import.md)
- [x] 2. Freeze the comparison tasks and the held-out evaluation. [15 open tasks](../experimente/72_bestellimport_basis/public-tasks.md) · [Proof of 15 sealed tasks](../experimente/72_bestellimport_basis/versiegelung.json)
- [x] 3. Conduct a fair baseline measurement. [TIDE and CPython on the open tasks](../experimente/72_bestellimport_basis/report.md)
- [x] 4. Build the order importer, extend it with cancellations, and measure the largest bottleneck. [Acceptance and paired runtime results](../experimente/73_bestellimport/report.md)
- [ ] 5. Repeat the study independently and decide on a public alpha. The local clean-checkout replication and size sweep are complete. The public alpha is on hold pending the second-machine run. [Stage 5 decision](../experimente/74_alpha_review/report.md)
- [x] 6. Reuse the same typed JSON input package for order and measurement documents. [Application checks and call-site diagnostic](../experimente/75_shared_types/report.md)
- [x] 7. Migrate the public `jsoninput` interface, locate affected callers and verify both pins. [Migration and acceptance](../experimente/76_package_migration/report.md)
- [ ] 8. Consistently adopt multi-file changes
- [ ] 9. Measure incremental feedback against full validation
- [ ] 10. Align the semantics of development, tests, and AOT
- [ ] 11. Improve the largest runtime bottleneck of the applications
- [ ] 12. API-service acceptance for duplicate delivery and restart
- [ ] 13. Prove load limiting and termination
- [ ] 14. Distribute packages independently and reproducibly
- [ ] 15. Test entry and editor with new users
- [ ] 16. Accept the second platform
- [ ] 17. Test operations, upgrades, and recovery
- [ ] 18. Accompany two independent pilot projects
- [ ] 19. Blindly compare real agent costs
- [ ] 20. Independently evaluate leadership claim and choose the next area

## Results of the current study

Stage 1 of the [feasibility study](plan.md#feasibility-study-and-publication-decision) is passed. Measurement file, report, and cross-module repair run without Python. For Stage 2, the measurement report is ahead-of-time compilable and locally compared with CPython. The measured factors are 18.0–31.4× including startup and 6.3–8.4× for the warm compute core. In the local agent comparison, Qwen3 4B solved 0/6 TIDE- and 2/6 Python repairs. A follow-up with TIDE-grammar help solved 0/6. No token advantage per correct solution is evidenced for this workflow. [Runtime measurement](../experimente/53_vorabuebersetzung/report.md) · [Local agent comparison](../experimente/54_lokaler_agentenvergleich/report.md)

The [first self-experiments](../experimente/findings.md) are completed. The [writing test](../experimente/05-writing-study.md) yielded four correct first solutions per form. Open is a comparison during maintenance of external state rules. Afterwards, the view change upon a change across function boundaries can be examined. The [executable version 0.3.0](../README.md) adds modules, records, options, data import with read permissions, and revision-bound editing tools. The ongoing acceptance uses `make test` and the [native checks in TIDE](../native/bootstrap/checks.tide). The table describes the expanded acceptance criteria of the design.

`test --diff --explain=nodes` provides candidates for revision-bound node edits. In the local comparison at four new multi-file errors, 0/12 TIDE-node edits, 0/12 TIDE-function body replacements, and 3/12 Python-AST edits passed. All known corrections passed 75 cases per task. No advantage in success rate or total tokens is evidenced for the TIDE-node surface in this experiment. [Comparison and raw data](../experimente/55_knotenreparatur/report.md)

With `test --diff --explain=candidates`, TIDE checks operator changes locally in advance. Success rates rise to 6/12 for TIDE and 9/12 for Python-AST on the same four tasks, each without a model query. Including an ambiguous fifth task, results were 8/15 at 531 model tokens for TIDE and 11/15 at 555 for Python-AST. The precheck saves model work for both methods. Python-AST remains ahead in tokens per success in this measurement. [Operator changes tested](../experimente/56_gepruefte_operatoren/report.md)

TIDE 0.6.1 complements `<=` and `>=`. With unchanged precheck, TIDE rose to 11/15 at 531 model tokens. The re-measured Python-AST variant stayed at 11/15 and 555 tokens. The three additional TIDE successes come from the capacity task with `<=`. [Repetition measurement](../experimente/57_inklusive_vergleiche/report.md)

The precheck also considers two small expression substitutions for `a*b+c`. For the tax surcharge, this yields a unique candidate without model effort in both languages across all tests. In the same comparison, both methods pass 14/15 runs. TIDE consumed 531 model tokens, Python-AST 555. [Expression precheck](../experimente/58_ausdrucksvorpruefung/report.md)

`test --explain=candidates --probes` finds a valid input where green candidates yield different values. For the remaining task, the independently confirmed public case `a=1, b=1 → 0` separated remainder and quotient. TIDE and Python-AST each achieved 15/15 with zero model tokens. [Counterexample and repetition measurement](../experimente/59_oeffentliches_gegenbeispiel/report.md)

With eight new multi-file errors, both methods passed 84 of 96 runs without model tokens using the same precheck. From start to passed acceptance, TIDE required a median of 38.1 ms, Python-AST 88.8 ms. For the four tasks with counterexamples, including search and confirmation, times were 39.7 ms versus 91.4 ms. The error requiring two changes remained open on both sides. [Paired repair time measurement](../experimente/60_reparaturzeit/report.md)

With `--pairs`, the precheck finds a common correction for the double counter in two modules. Both methods passed all 96 runs without model tokens. Repairing the double counter required a median of 30.7 ms with TIDE and 71.3 ms with Python-AST. For a multi-file patch, the editor checks changes together and outputs the checked texts for a working copy. [Measurement of cross-file pair search](../experimente/61_dateiuebergreifende_paare/report.md)

With five new multi-file errors each having two or six public green pairs, both methods found exactly one correction after one or two confirmed counterexamples. Both passed 60 of 60 runs without model tokens. Total repair time was a median of 51.8 ms with TIDE and 115.5 ms with Python-AST. [Measurement with multiple green pairs](../experimente/62_mehrdeutige_paare/report.md)

`--probe-range` generates further inputs from valid integer ranges when the fixed pool does not separate green pairs. Compared to this, both methods increased success rates from 12 to 60 with 60 trials each and 0 model tokens. With generation, repair took a median of 36.2 ms with TIDE and 82.0 ms with Python-AST. [Measurement with generated counterexamples](../experimente/63_erzeugte_gegenbeispiele/report.md)

A `requires` example contract provides the input ranges for counterexample search. TIDE and Python-AST derived the same bounds and passed 60 out of 60 runs without model tokens. Total repair took a median of 33.9 ms with TIDE and 83.2 ms with Python-AST. [Measurement with derived contract bounds](../experimente/64_vertragsgrenzen/report.md)

`requires` now supports direct comparisons between integer parameters. In six scenarios, both methods found the same admissible counterexamples. 60 out of 72 runs passed, with 0 model tokens. The equivalence check remained ambiguous. Successful repairs took a median of 39.5 ms with TIDE and 95.2 ms with Python-AST. [Measurement with parameter relations](../experimente/65_parameterbeziehungen/report.md)

Versioned local packages have their own namespaces and explicit exports. The measurement report package version uses `rowtext.parse` and `measurements.parse` from two exactly pinned dependencies. The ahead-of-time compiled report achieved, compared to CPython, depending on size, 12.66–17.91× from process start to output. [Package comparison and acceptance test](../experimente/66_native_pakete/report.md)

## Replacement of the Python reference system

The standard build, installation, and native test suite run without Python. For type declarations including transitive imports, `check`, `fmt`, and `test` are native. `modules` provides import locations and revisions also for applications and the repair workbench. Upon project entry, the starter checks ordinary lock files. `make test` additionally executes editor and game states on the original TIDE applications. Pure functions with i64 and boolean parameters, conditions, local bindings, and ordinary calls run including their examples in the standard package. Also lists of these two element types, nested folds, and lists as results run natively. [List acceptance test](../experimente/30_native_listen/report.md)

Rules with integer or boolean events and outputs run including `scan`, rule examples, and event trace natively. [Rules and traces](../experimente/31_native_regeln_und_spuren/report.md)

The Checkout and the Package use exclusively native tools. `context` and `hole` operate on the same verified functions and rules as `check`. Complete candidate files can be checked and written revision-bound with `edit --source`. With `edit --edits`, nodes of the same file can also be changed via the project entry in a module. [Verification of native node edits](../experimente/35_native_knotenaenderungen/report.md) Text, lists, and options of the three basic types as well as search with Unicode indices run via the public evaluator. [Text acceptance at Nano and Workbench](../experimente/36_native_texte/report.md) Open are further composite values as well as terminal operation and writing of documents. [Native source changes](../experimente/34_native_quellaenderungen/report.md) The historical interpreter lies in the [Experiment Archive](../experimente/referenzsystem/README.md). [Acceptance of Checkout, Installation, and Inspection](../experimente/32_native_inspektion/report.md)

The line-by-line measurement report with `fold_lines` processed 100 MiB with 131.0 MiB/s and 1.84 MiB peak-RSS in the median. CPython with streaming achieved 25.6 MiB/s and 11.11 MiB. Both reported an invalid value in the second-to-last line 13.107.199. [Measurement with three input sizes](../experimente/67_zeilenstrom/report.md)

In the streaming measurement report, the time from stored parser correction to seven green tests in the installed TIDE dropped from 5.28 to 1.43 ms (median). CPython was at 6.44 ms in the after-check. [Paired comparison](../experimente/68_aenderung_bis_gruen/report.md)

## Stages and acceptance criteria

The [Measurement Report](../apps/summary.tide) processes measurement lines and returns its Record natively. Space Invaders runs with all six phases over `run` and `test`, including nested records, lists, and options for the game world. Nano's public entry supports the buffer and the requested action as a pair. Interactive terminal connection and access to documents are open. [Nano verification](../experimente/49_zusammengesetzte_paare/report.md) [Measurement Report](../experimente/43_native_records/report.md) · [Variant verification](../experimente/44_native_varianten/report.md) · [Verification at the complete game](../experimente/45_native_sammlungen/report.md)

The [first occurrence](../apps/peak_lines.tide) is natively executable for passed measurement lines via `tide run`. It uses an optional pair of maximum value and line number. The [file entry](../apps/first_peak.tide) calls the same compute core. The public CLI binds read permission with `--read input=PFAD`. [Verification of pairs and folds](../experimente/39_native_paare/report.md)

The order follows later stages in the [Research Plan](plan.md).

| No. | Task | Prerequisites | Finished and verified as soon as … |
|---|---|---|---|
| 1 | Fix prefix grammar, operation signatures, type rules, and output format from the [Language Design](../SPEC.md). | – | Both maximum variants, function call, empty case, type error, and overflow have small source files and expected results. The examples can be parsed unambiguously. Visibility, line boundaries, and error priority are fixed. |
| 2 | Prepare comparison tasks for three surfaces of the same TIDE semantics. | 1 | The held-out test catalog contains twelve orders, permitted repairs, and measurement conditions. The prefix, parenthesized and Python-like, yields the same reference trees. The reference programs pass the result and limit-value tests. |
| 3 | Execute a constant from source code to the CLI. | 1 | `main` with the body `7` yields the number 7 via `tide run`. A syntax error yields via `tide check --json` a machine-readable position. Size and nesting limits apply during parsing. |
| 4 | Add typed functions and integer arithmetic. | 3 | `twice 7` yields 14. `eq 9 9` yields `true`, `eq 9 8` yields `false`. Wrong argument type, recursive call, and value overflow have their own tests, also at both `I64` limits. |
| 5 | Execute options and local decisions. | 4 | A pure maximum program over a list constant processes negative values and an empty list. An incomplete case distinction fails during checking. The test covers `fold`, `let` and both branches of `case`. |
| 5a | Trigger, handle, and propagate catchable errors. | 5 | The sum of 2 and 3 yields `some 5` in the example, the sum of the largest I64 and 1 yields `none`. Handlers handle only their code and execute the replacement only in the error case. Tests for `fail`, `raise`, errors in the replacement, and errors across function boundaries check `may_fail`, the original diagnosis, and CLI output. |
| 6 | Attach read permission and input processing. | 5 | The first file program passes the table in the draft, including CRLF as an additional case. A missing binding, a wrong argument type, invalid UTF-8, and exceeding the byte budget yield defined errors. |
| 7 | Execute a change order with the first occurrence. | 6 | The program returns value and position as a pair. The visible sample with two nines specifically detects the faulty choice of the last position and reports expected and actual. Empty and invalid inputs retain the agreed behavior. |
| 8 | Check execution limits at the normal program entry point. | 5a, 7 | The limits are documented. Tests immediately at the limit and beyond cover source size, work steps, input, and guest memory, as well as an expensive library call. An exhausted budget also terminates a run with a valid handler. `catch E_LIMIT` and `catch E_CAPABILITY` fail during checking. Uncaught errors leave an empty standard output. |
| 9 | Apply changes to a selected program node. | 7 | The comparison in the measurement report can be switched from `>` to `<`. An edit at the wrong state, a wrong digit count, or a type error is rejected without partial change. Related subtree changes are checked together. |
| 9a | Check an open subexpression in the editor. | 9 | The gap at the last `if` of the pair example reports `&ii`, valid local bindings, and available rights. An incomplete draft cannot start a run. After inserting the correct expression, type checking and equivalence testing pass. |
| 9b | Check program examples and, upon positive attempt, state rules. | 8, 9 | `tide test` detects the total count on alarm, incorrect shutdown at 80, and the forgotten reset for the light. `trace` shows the relevant step from the same example. A changed expectation appears separately in the change comparison. |
| 9c | Check version binding, call effects, and diagnostic context. | 4, 8 | An incorrect catalog identifier is visibly rejected. Checker and short reference report the same tool and catalog version. An indirect read access is visible to the caller. Double formatting is byte-identical; the parsed examples remain intact. |
| 10 | Evaluate model experiments and time measurements. | 2, 8, 9a | The report contains raw data for three notations, first hits, total tokens per solved task, and a separate comparison of full regeneration versus targeted change. Runtime is evaluated separately. |

**Checkpoints:** After step 4, the first standalone program must function from the CLI call to output. After step 8, `make test` and the two CLI examples from the draft must be reproducibly executed. Step 10 checks the language's suitability for the measured tasks.
