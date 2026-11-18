# TIDE · Research and Development Plan

## Feasibility study and publication decision

TIDE is a feasibility study. We bundle the work into three stages. Each ends with a result that determines the decision on the next stage. New capabilities and tests emerge in TIDE. [Project rule](../AGENTS.md)

| Stage | Acceptance and decision |
|---|---|
| 1 · Document a complete workflow | The existing measurement report reads an explicitly granted file via the public CLI and delivers the expected report. A built-in error across module boundaries is diagnosed from the failing example and repaired via the native workbench. Also checked are missing grants, invalid inputs, and acceptance of the repaired program. Installed package and tests run without Python. |
| 2 · Measure utility comparatively | The same workflow runs with an idiomatic CPython reference through the same domain acceptance. Local measurements compare start time and throughput for small and large files. If token consumption is examined, tasks, acceptance, number of model runs, and budget are fixed ahead-of-time. Repetitions and failures go into the balance. |
| 3 · Decide on publication | For a successful study, a reproducible advantage in one of two metrics suffices. Either an equivalent TIDE program runs faster than CPython on a representative task, or the same model requires TIDE fewer total tokens for a correctly completed, equivalent development task. The report names the factor, spread, and scope of the demonstrated advantage. |

Build, acceptance, and runtime measurements run locally without model calls. For development work in the chat, each round gets a clearly bounded stage goal. Measurement series with model calls start only when a separate budget is fixed. The personal weekly quota is not planned for this.

Nano and the terminal game remain demonstrators for editor logic and game state. Interactive operation comes back into play as soon as it can answer a concrete question of the study.

## 20 Stages from feasibility study to leading language

**The first competitive field is data tools and backend services**, which humans and coding agents develop together and maintain across multiple versions. For these users, it counts whether they can write an application today, safely change it tomorrow, and restore it in case of disruption. The comparison therefore includes new development, extension, and repair.

**Situation as of 18 November 2026.** TIDE 0.6.5 supports typed JSON, versioned packages, HTTPS, SQLite, and PostgreSQL. During the 100-MiB streaming attempt, an earlier TIDE version achieved 5.12× CPython throughput. In the latest tooling experiment, both languages solved nine out of ten tasks. TIDE required a median of 16.6 ms, while Python-AST took 29.6 ms. The 6.6 % shorter TIDE protocols were counted offline. In a prior actual model experiment with Qwen3 4B, 0/6 TIDE- and 2/6 Python repairs were achieved. The biggest open question is thus how well an agent can write **new** TIDE programs and later modify them. [Implementation status](../README.md) · [Streaming](../experimente/67_zeilenstrom/report.md) · [Module precheck](../experimente/71_modulvorpruefung/report.md) · [Model experiment](../experimente/54_lokaler_agentenvergleich/report.md)

### I · Decide whether the language is worthwhile in practice

| Stage | Work | How we recognize completion |
|---:|---|---|
| 1 | **Define the first user and their task.** Choose a purchase order import as the first independent use case. It must validate supplier lines, store orders, and allow rejection. | A one-sided task defines inputs, errors, and observable outcomes. A later change, such as submitting cancellations, must be included from the start. |
| 2 | **Set up a held-out comparison.** Plan 30 tasks from three families as the starting size, with ten each for writing, extending, and repairing. Use tasks from multiple projects. | 15 development tasks and 15 held-out tasks are balanced by family. Acceptance tests and resource budgets are fixed before the first run. The previous ten repairs remain regression tests. |
| 3 | **Measure baseline values.** TIDE and idiomatic CPython receive the same domain contracts, data, and rights for the open tasks. | A reproducible run reports solve rate, time to acceptance, program runtime, and peak memory. Offline protocol tokens and actually consumed model tokens have their own columns. Failed attempts remain visible. |
| 4 | **Build the purchase order import from empty file to first change.** Traverse the entire path via CLI, library, and database. Only then address the most expensive observed bottleneck. | Both versions pass the same acceptance, including erroneous line, duplicate delivery, and cancellation. A before-after pair shows how much effort the first improvement actually eliminated. |
| 5 | **Decide on the publication of the study.** Repeat the experiment from a clean installation on a second machine. | The existing study criterion decides on a public alpha. A reproducible advantage in program runtime or actual model tokens suffices. On success, prepare the source state, installation path, raw data, and known limitations for publication. On an open result, follow with a targeted counter-experiment. |

### II · Develop and safely modify larger programs

| Stage | Work | How we recognize completion |
|---:|---|---|
| 6 | **Test reusable types on real programs.** Extract the first library function written multiple times from import and report. Introduce custom generics or function parameters where this abstraction is needed. | Two applications use the same implementation for different domain types. An incorrect type is detected at the call site with source location. |
| 7 | **Make changes to public package interfaces manageable.** Use existing namespaces, exports, and version pins for a real migration. | In case of an incompatible schema change, the tool names the affected consumers. Old consumers remain buildable with the old pin; migrated ones pass acceptance with the new one. |
| 8 | **Adopt a change across multiple files as a whole.** Run the existing, revision-bound edit preview up to safe adoption for an entire project. | A change to library, caller, and tests becomes visible together. An outdated revision, write errors, and process abort leave a recoverable, consistent state. |
| 9 | **Shorten the path from change to feedback.** Re-check dependent modules and tests specifically. | For leaf, interface, and package changes, the incremental result matches a clean full check. Median and 95th percentile of time to green are measured on a larger project. |
| 10 | **Ensure reliable semantics across all execution paths.** For every language function required in the competitive field, run examples against development mode, tests, and ahead-of-time compiled program. | A publishable coverage matrix shows identical values, error locations, and budgets. Every remaining gap has a minimal reproducible example. |

### III · Operate data tools and services under real load

| Stage | Work | How we recognize completion |
|---:|---|---|
| 11 | **Improve runtime where real programs lose time.** Profile word processing, typed JSON decoding, and database access in the full workflow. | For the largest share, pre- and post-measurements exist for small and large data volumes. Throughput, startup time, peak memory, and error semantics are jointly reported. |
| 12 | **Deliver a fault-tolerant API service.** Build an order webhook with PostgreSQL, transactions, and repeatable delivery. | Duplicate message, timeout, and restart after successful commit each result in exactly one correct business case. Stored data are independently verified. |
| 13 | **Master concurrency and cancellation under load.** Extend the existing HTTP workers with the load limiting and cancellation propagation required by the service. | A load test documents throughput and 95. Response time percentile. Aborted requests free connections, and the number of pending tasks remains within the defined budget. |
| 14 | **Distribute packages independently and build reproducibly.** Build a verifiable package installation on top of the existing exact pins. | Two independent projects reference the same library. A clean machine builds from fixed content offline, a changed package is detected, and an upgrade can be rolled back. |
| 15 | **Make the language usable without project knowledge.** Align the onboarding path, library reference, and editor navigation with the most common questions from early applications. | Three previously uninvolved developers install TIDE, add a field, and fix a multi-file error using the guide. Time, follow-up questions, and cancellations are recorded. |

### IV · Gain trust outside the project

| Level | Task | How we recognize completion |
|---:|---|---|
| 16 | **Carry a second platform.** Propose Linux ARM64 as the next target platform alongside Linux x86-64. | Installation, build, tests, and the two reference applications run on both architectures without Python in the TIDE toolchain. Platform deviations are reproducibly recorded. |
| 17 | **Demonstrate operation and recovery.** Operate a release candidate with diagnostics, resource measurement, upgrade, and rollback to the previous version. | The service passes a 24-hour run including interrupted upgrade and database restart. A second person can locate a stored error using the diagnosis and restore operation. |
| 18 | **Accompany foreign projects across two versions.** Two independent teams shall each build a self-selected application and later extend it functionally. Contributions and language proposals shall receive a documented path to a decision. | For both applications, experience with installation, missing libraries, maintenance, and upgrade is available. It is recorded whether the teams TIDE voluntarily choose again and whether they could contribute an improvement themselves. |
| 19 | **Measure the actual agent advantage blindly.** Freeze tasks and implementations. Use a separately granted trial budget to run the same models on unknown tasks in both languages. | For each task family, success rate, all input and output tokens including failed attempts, repair time, and variance are published or prepared for publication. Without an own model budget, this statement remains open. The rest of the development can continue. |
| 20 | **Independently verify the leadership claim and select the next deployment area.** An external group repeats the final measurement with sealed tasks. For services, an idiomatic Go comparison is added alongside Python. | The decision specifies the deployment area, comparison versions, proven advantages, and open disadvantages. Upon success, set up the same trial for a second area, e.g., developer tools. With mixed results, the largest measured deficit determines the next development cycle. |

**Proposed scale for Stage 20.** For the claim "leading in agent-supported data tools and backend services", TIDE shall achieve at least as many correct solutions per task family on the held out tasks. As the first target marker, I propose a reproducible factor of at least 2 for actual total tokens per correct solution **or** time to successful repair compared to Python. The comparison with Go checks for services especially throughput, high response latencies, memory, and operational effort. Which limits are acceptable for the user will be agreed in Stage 1. The three 100× research goals remain separately visible. Small samples and contradictory repetitions are reported as open findings.

**First work block completed.** The order for the order import includes precise cancellation, repetition, and rollback of order lines. Of 30 tasks, five per family remain open and five are locally sealed. On the 15 open tasks, the tools solved 9/15 respectively; all reference programs passed acceptance. The logs included 3,187 tokens for TIDE and 3,583 for CPython. The complete import up to the first technical change is the next work block. [Specification](../experimente/72_bestellimport_basis/order-import.md) · [Local baseline measurement](../experimente/72_bestellimport_basis/report.md) · [Task status](todo.md#roadmap-in-20-stages)

Stage 4 now covers the complete import, a restart after an order-only release, redelivery, cancellations and rollback. The local comparison measures the source CLI and ahead-of-time executables separately. [Order-import report](../experimente/73_bestellimport/report.md)

Stage 5 reproduced the eight-event native speedup on the original workstation. Across the additional batch sizes, the median winner switched between 256 and 384 events. The public alpha awaits a repeat on independent hardware. [Replication and release decision](../experimente/74_alpha_review/report.md)

Stage 6 uses one pinned JSON input package for the order importer and measurement report. Each consumer binds its own document schema. The checker identifies a mismatched result at the caller's operand in all four CLI paths. [Shared package and acceptance results](../experimente/75_shared_types/report.md)

Stage 7 migrated three application call sites to `jsoninput@2.0.0`. Its bounded read takes an explicit byte budget, and its snapshot read has a separate export. The old applications build with the original pin alongside the new package. [Caller locations, diagnostics and acceptance](../experimente/76_package_migration/report.md)

Stage 8 committed a library, its caller and the test helper as one project revision. The fault replay verified stale bases, failed writes, reader and writer contention, and recovery after killing both the editor and a recovering checker. All 19 checks passed on Btrfs and tmpfs. [Atomic edits and recovery results](../experimente/77_atomic_edits/report.md)

Stage 9 matched the full checker on leaf, interface and package edits in a 33-example project. Compared with a full check in the same running process, median time to green improved by 5.51×, 1.43× and 5.57× respectively. [Median, P95 and diagnostic parity](../experimente/78_incremental_feedback/report.md)

## Three 100× goals

A factor of 100 means that for the same passed task, the value is at most one-hundredth of the respective Python comparison value. The three factors remain research goals and are reported separately. The publication decision follows the criterion described above. Repair time remains an additional measurement metric.

| Metric | Comparison |
|---|---|
| Runtime of the finished program | Native TIDE execution versus an idiomatic existing CPython reference with identical input, output, and error semantics on the same machine. Separate measurement of computation time for a warm process and time from start to result. Build time reported separately. |
| Tokens per correctly completed development task | The same model writes, edits, or repairs functionally equivalent programs. Sum the actually consumed input and output tokens of all model calls per trial. Documentation, tool responses, diagnostics, and repetitions count if passed to the model. Report cache portions and provider-reported thinking tokens separately, without double-counting. |
| Time per successful error investigation | Measure from handover of the same observable error to the first passed independent acceptance run. Include time for context search, diagnosis, remediation, and testing. Report repair attempts, tool calls, regressions, and unresolved tasks additionally. |

The pairings and acceptance tests are fixed before the trial. Both sides receive the same technical order, the same model with the same budget, and a fresh context. For repairs, erroneous programs in both languages are already available. The order alternates. Per task family, we report completion rate, total consumption including failed attempts, and median and spread of paired measurements. A result for a task family applies to exactly those tasks.

In the local comparison on 18 November 2026, TIDE and CPython each solved five of eight new multi-file tasks. In the paired control experiment with combined CPython search and adoption, TIDE achieved acceptance 1.94× faster in the median. The offline-counted repair logs were 9.4 % shorter across all eight trials. The actual total tokens of a model remain open for these tasks. [Measurement report with acceptance and raw data](../experimente/69_neue_mehrdateienaufgaben/report.md)

On ten additional three-file tasks, searching for argument swap, UTF-8 byte length, and last delimiter increased the success rate in both languages from 1/10 to 9/10 at program entry. With direct additional inspection of the intermediate module, 6/10 passed in each case. For successful program entries, TIDE required 16.6 ms in the median and Python-AST 32.0 ms. Across all ten trials, the TIDE logs were 7.8 % shorter. The measurement ran locally without model calls. [Paired before-after comparison](../experimente/70_strukturelle_reparatur/report.md)

On the same ten tasks, direct public inspection of the intermediate module before candidate selection raised the joint acceptance of entry and module for both tools from 6/10 to 9/10. In all three affected projects, the entry code remained held out. For the extended inspection, TIDE required 16.6 ms per successful repair in the median, and Python-AST 29.6 ms. The ten logs included 3,555 and 3,808 offline-counted tokens, respectively. [Measurement report and repaired projects](../experimente/71_modulvorpruefung/report.md)

**Current Status.** In the [Three-Way Trial](../experimente/07_dreiwege/report.md), task packages and submissions combined 2,847 tokens in prefix and 2,966 in Python-like TIDE notation (`o200k_base`). For the balance program with four fixed entries, measurements against real CPython and four isolated model runs are now available. Native TIDE achieved 174× throughput in the warm stack and 39× for single program calls. The TIDE write run consumed 78,662 total tokens, Python 58.341. Repairing the same incorrect subtraction took 9.28 and 7.29 seconds, respectively. Generalizability to other tasks is open. [Measurement report with raw data](../experimente/11_saldo/report.md)

In the subsequent [Trial with one function body per response](../experimente/12_funktionsrumpf/report.md), total tokens dropped to 19,203 for writing and 19,117 for repairing. Times to passing the balance test were 6.82 and 5.10 seconds, respectively. For both tasks, inspection was completed outside the model call.

In [Repair with unknown error location](../experimente/13_mehrdateien/report.md), two of four modules had to be corrected jointly. TIDE passed 20/20 cases with 58,789 tokens in 13.67 seconds, Python with 58,824 tokens in 13.54 seconds. Both repairs succeeded on the first attempt.

In the next [multi-file package intake error](../experimente/14_projektkontext/report.md), the precompiled project context reduced the TIDE repair of 79,628 to 19,833 tokens and from 21.37 to 6.96 seconds. Python with precompiled sources passed the same 25 cases with 19,861 tokens in 10.18 seconds. There was one model run per condition.

In the [follow-up attempt with three new errors and four pairs per error](../experimente/15_gepaarte_reparaturen/report.md), both languages received precompiled context. TIDE was faster in 3/12 pairs and consumed 3/12 fewer total tokens. In the median of the pair differences, TIDE required 3.07 seconds and 186.5 tokens more. All 24 answers passed acceptance in the first attempt.

In the [blind test with grouped function bodies](../experimente/16_gruppierte_reparaturen/report.md), the new TIDE processing saved, compared to the previous text edit, 3.08 seconds and 190.5 total tokens in the median of the eight comparison pairs. Against Python with similarly named repairs, it required TIDE 0.97 seconds and 110 tokens more. All 32 repairs passed acceptance and control cases. In prioritized comparisons, repeated field accesses and nested conditions remain visible in the response text. A next candidate is a reusable comparison operation for a primary key with a subsequent decision criterion.

In the [blind test with mixed priorities](../experimente/17_prioritaeten/report.md), the model used the new TIDE comparison functions in one of twelve repairs with an embedded library. Compared to TIDE without a library, the offer cost, in the median of the paired comparisons, 2.98 seconds and 144 total tokens more, compared to Python 3.97 seconds and 359 total tokens more. All 36 repairs passed 40 public and 40 held-out cases; one required a second answer for a missing closing bracket. The library remains optional.

The [local correction after a parser diagnosis](../experimente/18_lokale_syntaxreparatur/report.md) replaced, during replay of the specific bracket error, a second model answer with 20,708 tokens. On a new journal regression, all eight blind runs passed in the first attempt. Here, TIDE cost, in four pairs, a median of 2.63 seconds and 195.5 total tokens more than Python. The preparation of the TIDE context required, in the median, 0.58 seconds compared to 0.04 seconds for Python.

In the [setup of the grouped repair view](../experimente/19_kontextaufbau/report.md), the workbench reduced the preparation time in 24/24 local measurement pairs with identical contexts. Nano `step` now fits into the work budget with its 14 reachable function bodies. From the first failed test to the complete prompt, TIDE required, in the median on the journal, 372 ms, Python 33 ms. The reference CLI continues to start its own process for each queried function body.

The [native test for branched i64 expressions](../experimente/20_native_ausdruecke/report.md) translates an integer fold with conditions and checked arithmetic. For heating degree hours, the factor against CPython was 33.8× in warm throughput and 48.1× in single run. All 29 differential cases matched the TIDE reference in value or overflow code.

With [changing positional arguments](../experimente/21_native_eingaben/report.md), the same native file processed empty lists, 16, and 4,096 temperatures. The paired factors including startup and input binding were 23.9×, 23.7×, and 16.5× against CPython. The reference check covered both i64 limits, input errors, and the exact work limit of 100,000 steps. Native record processing and file input remain open.

In the [blind test with patch repairs](../experimente/22_fragmentreparatur/report.md), the explicit mention of already checked sources and the test run reduced the paired medians by 6.82 seconds and 40,073 total tokens compared to the neutral TIDE task. Against Python with the same hint, TIDE lagged by 1.61 seconds and 86.5 tokens.

The [native division test](../experimente/23_native_division/report.md) covers signed quotients and remainders even at i64 limits. For the carton balance with 4,096 entries, the paired factor for the full process call was 18.0× against CPython. A double stack buildup in the compiler found during the boundary check was eliminated. The two test programs that previously failed at the compiler budget can now be translated under the same limit.

The [native state rules](../experimente/24_native_regeln/report.md) process the unchanged applications for heat, pump, and light. 384 event sequences and 15 cases at the work limit matched the reference.

In the [blind test with jury and depot](../experimente/25_blinde_quellreparatur/report.md), a new source view saved 0.16 s in the paired median for preparation. Until acceptance, it required 1.81 s and 53.5 total tokens more compared to fully parenthesized TIDE, and 152 tokens more compared to Python 1.97 s. All 18 first proposals passed the public and held-out acceptance.

The [native stack query for parenthesized expressions](../experimente/26_native_reparaturansicht/report.md) replaces the separate reference process per function for the four checked projects. Measured is the time until the finished view.

The [native type check](../experimente/27_native_typpruefung/report.md) compares the public commands for individual type files with the reference and measures the full process runtime of `check`. Native application checks run nano- and game states through the compiled TIDE sources.

The [native module check](../experimente/28_native_module/report.md) compares transitive type references, file positions, order, and revision binding. The module graph is also accessible during a repair with an incomplete body.

The [native function execution](../experimente/29_native_funktionen/report.md) checks the priority module with its examples, cross-file calls, and exact work boundary. The runtime comparison distinguishes between repeated and always different arguments.

## Previous Research Plan

**Current Research Question.** Does this representation help me understand, modify an unknown program, or clarify an ambiguous task? The [language draft](../SPEC.md) provides candidates for experiments. The [local interpreter 0.3.0](../README.md)] executes data and event programs. Catalog, source context, typed replacement, and state trace are available for further experiments.

The [first experiments](../experimente/findings.md) have been evaluated. In 16 short tasks, I passed all first attempts with both notations. For four known rule pairs, my self-selected counterexamples were already minimal. For the user's first task on the temperature alarm, my first interpretation was correct. After brief feedback, I issued an explicit condition. For the next dialogue experiment, we will check whether a counterexample from the original requirement helps me incorporate an explanation without inadvertently changing another rule.

**Write and maintenance experiment for draft 0.3.** I solved new tasks for position marker, reservation, bonus booking, and pause in both forms. All four step functions and all four rule tables were correct on the first attempt. The rule bodies cost around 55 % more source tokens in these submissions. When switching the bonus start value from 1 to 3, a single change to the same named definition sufficed for both forms. I did not observe an additional maintenance advantage of `reset` here. The rule table remains an optional research candidate. [Write sample](../experimente/05-writing-study.md) · [Maintenance experiment](../experimente/findings.md)

Separately, the change across two functions remains an open question. There, I can switch between compact and expanded views. In both experiments, the example comparison shows when a change violates a previously confirmed case.

**Experiments on the nine design questions.** For local error diagnostics and call context, we compare similar repairs with and without the entry from the bound operation catalog. Separately, technical commitments can be objectively verified: an intentionally swapped catalog must report a version deviation, indirect file access in the call graph must be visible, and formatting must yield the same syntax tree. First-attempt success rate and token effort belong to self-experiments; reproducibility and type correctness belong to tool experiments. [Language draft 0.3](../SPEC.md)

## Development options after the research phase

The [source research for the language design](../experimente/language-design-research.md) supplements possible test conditions for state rules, debugging, and different program views.

The following stages describe the overall design. The first executable core already covers functions, state rules, examples, and typed JSON inputs.

| Stage | What we build or decide | How we recognize the result |
|---|---|---|
| 1 · Speech core | The compact prefix grammar, the operation table and the type rules on the examples set. Record valid and invalid programs as well as their exact expenses. Prepare the LLM comparison. | The original and the modified measured value program can be described with the same general rules. Missing operands and an incomplete `case` have clear test results. |
| 2 · Run the first program | Build a local interpreter with parser, type check and the commands `check` and `run`. First call a pure function. Then check type error and overflow through the same execution path. | An `main` returning `twice 7` will deliver `14`. `twice "7"` is rejected with source position. The execution does not require a model service. |
| 3 · Processing the measurement series | Options, lists, pairs, loops and limited reading supplement. Bind the file input to a handle opened by the starter. Perform the change task as a second program. | Both programs pass the example table and the boundary cases. Missing reading rights and exhausted budgets result in the agreed errors. |
| 4 · Evaluate language design | Compare programming, modification and repair jobs with three interfaces of the same TIDE semantics. On the same computer, compare the running time of correct measured value programs. | A report includes raw values, error types, and deciding which part of the language we keep or revise. |

Stage 2 requires the core rules from Stage 1. The small test programs and the Python comparison version can already be prepared in Stage 1. First model experiments are possible with the pure functions from Stage 2. The full comparison uses the frozen state after Stage 3. The [worklist](todo.md) contains the order and the individual check steps.

For error handling, we first build the path from a failed operation to the CLI. Then we supplement selective handlers and the error set determined by the checker per function. The acceptance test compares the same overflow once uncaught and once with a replacement value. A nested case additionally checks that an error in the replacement reaches the outer handler and that a re-trigger preserves the original source position. At the file example, we check the separation of source position and input line.

## Historical proposal for a Rust interpreter

We are writing the reference interpreter in Rust and initially letting it directly evaluate the type-checked syntax tree. This allows us to change syntax or diagnostics while the language core remains small. The interpreter performs only its own, built-in operations. For our own Rust code, we propose `#![forbid(unsafe_code)]`. Dependencies remain part of the trust base. [Rust documentation for Lint](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code)]

The planned architecture remains small. `src/` contains CLI, parser, type checking, and evaluation. `examples/` contains the two measurement programs. `tests/` checks behavior using the same commands that the model will later use. A bytecode or native compiler would then be a justified next investment if measurements show the interpreter as a bottleneck.

## Two attempts with decision criteria

**1. What difference does the interface make for me?** In the three-way self-experiment, all twelve tasks were completed in every form on the first attempt. Parenthesis-free prefix had the shortest submissions. With a deleted term, bracketed prefix immediately localized the incomplete call. Separate contexts and tasks of foreign origin remain outstanding. [Report on the three-way experiment](../experimente/07_dreiwege/report.md). A later comparison with real Python will examine the entire language and toolset. Comparing tree replacement and full regeneration, plus additional type information in the editor, remain separate experimental conditions.

**2. How fast does the finished program run?** We compare the correct TIDE program with a CPython version following the same input, error, and equality rules. Small, medium, and large files contain 10, 1.000, and 100,000 values. Per size, we measure 30 runs per language in varying order. A run measures process start to result; a second measurement captures pure processing in the already-started process with ahead-of-time read data. Results are checked for equality. Reported values are median, 95. Percentile, and maximum process memory, along with computer, software versions, and budget values.

The historical proposal for the reference interpreter anticipated a processing time within twice that of the Python reference for 100,000 values. For the native language, the three goals established above apply.

## Design experiment · A technical question derived from two programs

In case of an ambiguous change request, the model might suggest two plausible, type-correct program versions. The development tool first discards any version that violates an existing, still valid example. For the remaining versions, it searches for a small input where the observable results diverge. The person familiar with the request is presented with this concrete decision. Their answer can also be a third result. The chosen expectation is stored as an example for future changes.

In a local Python experiment, we compared two manually formulated rules for two requests. For each request, all 121 sequences of length 0 to 4 were tested over three possible values. Sorting was first by input length, then by the order of values specified below.

| Request | Which examples both rules already satisfy | Which question the comparison reveals |
|---|---|---|
| "Deliver the second largest measurement value." Values 1, 2, 3. | An empty list and a single value yield nothing. For `[1,3,2]`, both rules yield 2. | 60 sequences distinguish "second place with repetition" from "second largest distinct value". The shortest is `[1,1]` with results 1 and empty. To decide between two numbers, `[1,2,2]` is suitable: 2 or 1? |
| "Add an additional import that skips erroneous lines." Lines `0`, `1`, `x`. | An empty file yields empty. From lines `x, 0, 1`, both variants derive the maximum 1. | Four sequences differ. All contain exclusively invalid lines. Even file `x` separates the variants: empty success or `E_DATA` in line 1? |

The experiment finds differences between given rules. Generating good candidates from a request is a separate, open problem. For an experiment in the TIDE editor, two candidates, synthetic inputs, and a fixed search budget suffice. If the search finds no difference, it shows the tested input range. Only a technically clarified version is adopted as a program. The selection occurs during development. A delivered program does not need a model for this.

## Further suggestions from the review

- **Domain types and saturation.** For a counter, the value range 0 to 3 could belong to the type. A specially named saturating increment would stay at the maximum. Ordinary addition retains its overflow rules. Even the existing I64 type is finite; the small range facilitates complete investigation. First, check on another counter task whether the new type actually simplifies modeling.
- **Behavioral differences.** With deterministic rules, a finite searchable product state, and complete event classes, a breadth-first search can provide the shortest distinguishing sequence. For the heat counter, the classes "over 80" and "at most 80" suffice because the exact height has no further effect in both variants. In the model experiment, `hoch, niedrig, hoch, hoch` separates the series rule from the total count for the first time after four steps. All shorter sequences of both classes were checked. With arbitrary samples or an exhausted search budget, only the examined area is known.
- **Branch coverage and priority.** Counting the actually selected `when`-, `else`-, and `case`-branches can reveal missing examples. For the light rule, both `motion` and `eq missed 0` are true at startup with movement. The second branch is still reachable upon the first idle report. Report any observed overlap with witnesses; "untested", "overlapped", and "proven unreachable" must be distinguished. The prioritized semantics remain intact.
- **Data forms and time.** Initially test named fields with an event where two values of the same type can be swapped. For time rules, first clarify whether event time, arrival time, or elapsed duration is meant and what applies to gaps. This is its own task family.
- **Name.** TIDE stands for Typed Instructions, Deterministic Execution. Source files use the extension `.tide`.

## Acceptance of a later prototype

Functional acceptance requires correct results and reproducible diagnoses for both measurement programs. If the state experiment supports the rule form, add the examples from draft 0.3: a forgotten reset must violate the light example at step 3, and the targeted trace for step 2 must show the old and new counter values. The security acceptance requires tests for type checking, rights, and resource limits including large and deeply nested inputs. The comparison report evaluates the two intermediate goals separately. A missed goal remains visible as an open finding and determines the next development step.
