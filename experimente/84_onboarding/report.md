# Stage 15 · First use of TIDE

**The materials are ready for the participant study. Stage 15 remains open.** A local technical rehearsal completed all three tasks. The study has recorded **0 of 3 participant sessions**. Developer completion rates, elapsed times, follow-up questions and abandonments are still unmeasured. [Roadmap criterion](../../tasks/plan.md#20-stages-from-feasibility-study-to-leading-language) · [Session protocol and worksheet](protocol.md)

## What a new user gets

The README now links directly to an unprivileged installation and a first runnable example. The guide uses the measurement application to show which record owns a JSON field, how a decoded option appears in a test, and how to jump between a library declaration and its callers. The library reference lists the five public calls used for JSON, line splitting and measurement parsing. These topics come from the existing applications and their tests. Participant questions will provide the first evidence of which explanations need revision. [Getting started](../../GETTING_STARTED.md) · [Importer library reference](../../LANGUAGE.md#libraries-used-by-the-importers) · [Participant tasks](tasks.md)

## Technical rehearsal

The rehearsal used source commit `8c436d3`, a fresh local clone with an empty build directory, an empty installation prefix and a Linux x86-64 network namespace with external networking disabled. The exercise ran through the installed binary. No additional model runs were used.

| Task | Observed result |
|---|---|
| Install | `make -j4 install-native` took 37.011 seconds in this run. The new binary reported `TIDE 0.6.12`. Three balance examples passed and the requested calculation returned `97`. The time covers the build and installation only. |
| Add a field | Offline installation verified and installed three package files. The unmodified report passed 9 examples. The new contract initially failed at `/expect/readings/0/unit`. Adding the optional field passed all 3 new examples. The existing decoded-record expectation then flagged the missing field at the same path. Extending that expectation restored all 9 report examples. |
| Navigate | The installed CLI located the vendored `jsoninput.decode` declaration and its application caller. The guide's editor jump opened the `higher` signature in Vim. For the repair, the CLI located the shared declaration at `band.tide:1:1` and the calls at `single.tide:4:1` and `batch.tide:5:14`. |
| Repair | Fixing only the single reader left the batch example red (0 accepted, expected 2). Fixing only the batch reader left the single example red (false, expected true). Fixing both passed all 8 examples with the original library and test file. |

The local `make test check-postgres` suite passed. The inspection regression checks independent declarations for two packages exporting the same function name, repeated calls in a single expression and an entry function with no callers. [TIDE regression checks](../../native/bootstrap/inspection_checks.tide)
