# From the failed example to the change in the imported module

`tide test --explain` creates a repair context on the first deviating example. In the prepared comparison, the number of TIDE calls dropped from seven to one. In twelve blind model runs, all first repair suggestions were correct. Against Python with also prepared context, TIDE was faster in four of six pairs and required fewer total tokens in two pairs. [Single answers, usage counters, and time measurements](messung.json)

## Generate the finding itself

In the report example, `after` calls the function `adjust` in the neighbor module. This copy incorrectly subtracts the change from the amount. The commands are executed in the project root.

```sh
work=$(mktemp -d)
cp native/bootstrap/fixtures/functions/report.tide "$work/report.tide"
printf 'adjust amount:i change:i > i\n- amount change\n\nratio amount:i count:i > i\ndiv amount count\n' > "$work/adjustment.tide"
./tide test "$work/report.tide" --explain 2>"$work/befund.json"
cat "$work/befund.json"
```

Example `update` reports status 1, expectation 3, and result 7 as before. Additionally included are the inputs, the project revision, the grouped body of `after` and that of `adjust`. The latter is `(- amount change)`. The node identifier is `adjustment.tide:2:1`. With the output revision, an agent can directly inspect and accept this change.

```sh
revision=$(jq -er .repair.revision "$work/befund.json")
./tide edit "$work/report.tide" --base "$revision" \
  --edits '[{"node":"adjustment.tide:2:1","op":"+"}]' --write
./tide test "$work/report.tide" --explain
# {"passed":6}
```

Field `repair.definitions` follows the static call graph of the example target. It also includes calls from inactive branches and each reachable function once. Thus, an agent can also investigate a faulty branch selection in the caller. For rules, the finding includes the original text with file and line number. Type, syntax, and load errors retain their previous diagnosis. [Implementation](../../native/bootstrap/explain.tide) · [CLI-Contract](../../LANGUAGE.md#tools-for-changes)

## Effort until the same prepared context

In the original eight pairs for equality and rounding, 40,612 of the 42,080 additional TIDE tokens were distributed over two sessions that, despite the prepared context, listed the files again. For equality, the answers repeated field accesses; for rounding, nearly identical folds. The previous measurement logged time and thought tokens per session. No thinking time can be assigned to individual expressions from this. The new command delivers the example and reachable definitions together. The new model experiment measures repairs with provided context without shell access. Whether an agent with free tool selection would still list files remains open. [Original Runs](../15_gepaarte_reparaturen/report.md) · [Evaluation of Answers](../25_blinde_quellreparatur/report.md)

For the old version, `test` ran first. The target was read from the reported example line. Two `context` queries per reachable function provided calls, root identifier, signature, and grouped body. The new call delivers the same structured information along with the underlying revision. Both JSON packages prepared during the experiment were content-identical for each task and compactly serialized at 869 bytes each.

| Project | Seven calls, previously | One call with `--explain` | Tool output previously / now |
|---|---:|---:|---:|
| Coordinate selection | 42.38 ms | 5.96 ms | 10,832 / 870 bytes |
| Grid display | 42.31 ms | 5.85 ms | 10,878 / 870 bytes |

Installed packages were measured on the same logical processor core with varying order. Each time is the median of 19 runs after three warm-up rounds. The previous sequence is a reproducible path to the same information. For an already passed balance, the current `test` 5.74 ms, with `--explain` also 5.74 ms. For a large Unicode contract, it was 12.41 and 13.31 ms. [Raw Measurements](messung.json)

## Blind experiment with prepared context for both languages

- **Coordinate selection.** From a list, the coordinate closest to the origin shall be selected. In case of equal distance, the smaller coordinate wins. The faulty version selected the larger one. Before the repair, there were 4 out of 6 public and 36 out of 72 held-out cases.
- **Grid display.** A measurement shall be rounded to the nearest grid point relative to a reference. Exact midpoints are rounded away from the reference. The faulty version halved an odd grid width using integer division before comparing the remainder. Before the repair, there were 3 out of 6 public and 63 out of 72 held-out cases.

Each task comprised three modules. The first deviation appeared at the public entry point, while the faulty expression lay in an imported module. Both languages delivered identical results for all 78 cases of each family before the repair. The validated reference repairs passed all cases. Inputs, order, and acceptance rules were fixed before the first model run. [Experiment plan with both versions](versuchsplan.json)

Three fresh Codex sessions per task and language received the technical assignment, the first observed deviation, and the reachable definitions. No assignment named the error location. For TIDE, the package came from `test --explain`; for Python, from a test run and the Python AST. The model was `gpt-6-astra` with `xhigh` and requested service class `priority`. The twelve sessions had an empty working directory, disabled reminders, and no shell. Each produced named function bodies without tool invocation. The TIDE editor checked the reported node identifier and revision. The public examples and subsequently 72 held-out cases were re-executed for each proposal. For TIDE, the held-out acceptance lay in a fresh project copy. The Python version ran with read-only sources in a separate mount namespace.

| Three pairs per task | TIDE, Median to acceptance | Python, Median to acceptance | TIDE, Median total tokens | Python, Median total tokens |
|---|---:|---:|---:|---:|
| Coordinate selection | 5.29 s | 6.59 s | 18,809 | 18,834 |
| Grid display | 6.94 s | 6.38 s | 18,881 | 18,823 |

For direct comparison, the difference within the same repetition counts. In the tie, TIDE was faster in all three pairs, in the paired median by 0,51s, and needed two more tokens in the paired median. At the rounding, TIDE was faster in a pair, in the paired median by 0,90s slower and by 77 tokens more expensive. Over all six pairs are the medians **0.29 s less time and 6.5 Total tokens more for TIDE**. The clock ran from context preparation to the end of independent acceptance. Total tokens include input including cache hits and output including think tokens. Differences in the cache and service latency are visible in the individual values. [Pair values and provider counters](messung.json)

An additional pilot run aborted in the measurement adapter before saving usage counters. The adapter had an additional CLI entry evaluated as a tool call. The twelve evaluated sessions were subsequently fully restarted. The corrected adapter distinguishes between CLI hints and model tools. Two small tasks, each requiring one source change, do not allow a general ranking. The comparison between the old and new TIDE version measures tool preparation. The model measurement compares the new version with Python.

## Acceptance of the tool change

26 checks on the public command covered, among other things, type and runtime errors, several deviating examples, option and text values, imported rules with CRLF, unused branches, a shared subcall, call depth 48, and a body spanning multiple node pages. An outdated revision was rejected after a module change. With the new finding, the module could be corrected. The permanent test suite includes the call graph with shared subcall and a correction via the revision read from the error finding. [TIDE-check](../../native/bootstrap/inspection_checks.tide) · [Integration test](../../Makefile)

The rebuild from an empty build directory succeeded without Python or experiment archive. All six installed tools were statically linked and byte-identical with a second build. Twelve ELF checksums, 553 comparisons for text processing and tools, 77 resource and diagnostic cases, and 1,041 node edits passed. For nine complete folds, the expected source bytes were determined independently because the historical reference terminates there. [Proofs](messung.json)
