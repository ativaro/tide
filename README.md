# TIDE

TIDE (*Typed Instructions, Deterministic Execution*) is a statically typed language for data tools and backend services. You can run a program from source or compile it ahead of time to a native Linux executable. Functions declare what they accept and return, including the files, databases and HTTPS endpoints they need as inputs. A named example lives beside the function it exercises, so a developer or coding agent can run it, inspect a failure and check an edit against the same expectation.

**TIDE is experimental and testing is still incomplete.** The native suite has passed on Linux x86-64 and on ARM64 under emulation. Firsthand reports from physical ARM64 machines and from people using TIDE for their own projects would help us see what we have missed. Contributions are warmly welcome. A small failing program, the command you ran, your TIDE version and the result you expected make a good first issue. [Tested platforms](experimente/85_linux_arm64/report.md) · [How to contribute](CONTRIBUTING.md)

If you are a coding agent writing your first TIDE program, start with the [coding agent quickstart](#coding-agent-quickstart).

## Quick start

Here is a function and one of its examples from the balance application.

```tide
balance opening:i entries:*i > i
fold entries opening total row entry + total entry

example movements balance
{"inputs":{"opening":100,"entries":[-20,15,-8,10]},"expect":97}
```

Read the signature as “`balance` takes an opening integer and a list of integers, and returns an integer.” TIDE writes the operation first, so `+ total entry` adds the current entry to the running total. `fold` starts at `opening` and visits the entries in order. At each step, `total` holds the running balance, `row` the one-based position and `entry` the current amount. An empty list returns the opening balance.

Run the checked-in program from the repository root on Linux x86-64 or ARM64. The launcher builds the native tools on first use.

```sh
./tide run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
# 97
./tide test apps/balance.tide
# {"passed":3}
```

The other two examples cover an empty list and integer overflow. In the getting started guide, you write a stock-shortfall function, import it into a second module and compile a program that reads an order from JSON. [Write your first function](GETTING_STARTED.md#write-a-function-and-its-examples) · [Read an order from JSON](GETTING_STARTED.md#read-an-order-from-json)

## Reading and writing TIDE

A function body is one expression. Calls start with a function name or operator, followed by its operands. Parentheses can group a nested call. For example, `if (> value limit) 1 0` reads as “if the value exceeds the limit, return one, otherwise zero.” A `let` binds a name for the expression that follows. Bindings are immutable. Blank lines separate declarations.

| Type notation | Meaning |
|---|---|
| `i`, `b`, `t`, `y` | Signed 64-bit integer, boolean, Unicode text, bytes |
| `q`, `z` | Fixed-point decimal with six fractional digits, timestamp with UTC offset |
| `*i`, `?i`, `%i` | List of integers, optional integer, dictionary from text keys to integers |
| `{Reading}`, `*{Reading}` | A named record and a list of those records |

**Records and typed JSON.** The measurement importer gives each reading a sensor name, a value and an optional note. Its decoder returns the application's own document type.

```tide
use jsoninput@2.0.0[Document]

record Reading
sensor:t value:i note:?t

record Document
readings:*{Reading} limits:%i

parse payload:y > {Document}
jsoninput.decode payload
```

The import pins the package version and binds its type parameter to `Document`. Missing notes and JSON `null` both produce an empty option. A boolean where the second reading's note should be text yields `E_DATA` at `/readings/1/note`. You can run that exact error case with `./tide test apps/report_packages/json_report.tide --example wrong_optional`. [Importer examples](apps/report_packages/json_report.tide) · [Types and JSON](LANGUAGE.md#types-and-json)

Use `map` to transform each element of a list, `fold` to accumulate a result and `case` to handle both outcomes of an option. A `variant` declares named alternatives. A `match` must cover each one, so adding a case brings the affected matches to the checker's attention. [Collection examples](native/bootstrap/fixtures/functions/maps.tide) · [Variants and matching](LANGUAGE.md#variants)

**Rules for state over time.** A pump turns on below 20 and off above 80. Between those thresholds, including at either boundary, it keeps its previous state.

```tide
rule pump level:i > b
state on:b=false
when < level 20 -> on=set true
when > level 80 -> on=set false
else -> on=keep
out on
```

The first matching branch updates the state. `out` reads the updated value. The application's `simulate` function uses `scan pump levels` to return one output per event. You can inspect a single transition with `trace`. [Pump source and examples](apps/pump.tide)

```sh
./tide run apps/pump.tide --call simulate --inputs '{"levels":[19,20,80,81]}'
# [true,true,true,false]
./tide trace apps/pump.tide --example boundaries --step 3 --fields on
```

In step 3 of `boundaries`, the level is exactly 20. The trace shows that `on` was `true`, the action was `keep`, and the output is still `true`. For larger examples of event-driven code, see the editor and game logic. [Nano](apps/nano.tide) · [Space Invaders](apps/space_invaders.tide)

## Files, databases and services

The measurement report declares `main input:r limit:i > {Summary}`. The caller grants read access to a particular file and supplies the threshold as an ordinary integer. This command counts values strictly above 80 and returns the highest reading as an option.

```sh
demo=$(mktemp -d)
printf '80\n81\n98\n' > "$demo/readings.txt"
./tide run apps/report.tide --read input="$demo/readings.txt" --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

| What you can build | How TIDE supports it |
|---|---|
| Streaming import | `fold_lines` processes UTF-8 lines under a byte budget. An invalid reading carries its input line number. [Streaming report](apps/report_packages/stream_report.tide) |
| Transactional import | The order importer binds a SQLite database, applies a batch in a transaction and rolls it back on an invalid event. Repeat deliveries are recognized by event ID. [Order importer](apps/orders/import.tide) |
| API client | An HTTPS capability grants access to a specific origin. The measurement client fetches pages, decodes their typed payloads and stores the results in SQLite. [API importer](apps/report_packages/api_report.tide) |
| HTTP service | The order webhook decodes a request body and books its events in PostgreSQL with parameterized SQL. Its worker and queue limits bound how many requests it admits at once. [Webhook](apps/orders/webhook.tide) · [Operating guide](experimente/86_webhook_operations/runbook.md) |

`use readings` imports a neighboring module. A versioned package exposes its public names with `export`, so `rowtext.parse` and `measurements.parse` can coexist. Projects can pin the package contents by SHA-256 and install from a local directory. [Two packages exporting parse](apps/report_packages/report.tide) · [Offline packages](LANGUAGE.md#installing-packages-offline)

## Coding agent quickstart

Start with an observable result. Suppose the caller needs one boolean per stock level, with a reorder flag only for quantities strictly below a minimum. Save this complete module as `reorder.tide` in a scratch directory.

```tide
reorder quantities:*i minimum:i > *b
map b quantities qty (< qty minimum)

example boundary reorder
{"inputs":{"quantities":[2,3,4],"minimum":3},"expect":[true,false,false]}
```

Read the signature from left to right. The inputs are a list of integers and one integer. The result is a list of booleans. The next line is the entire body. In `map b quantities qty (< qty minimum)`, `b` names the output element type, `qty` names one input element and `<` takes two operands. The middle case in the example catches an accidental change from `<` to `<=`.

Run these commands in that directory with the installed CLI. From a TIDE checkout you can instead invoke its `./tide` launcher and pass the path to your module.

```sh
tide describe map
tide check reorder.tide
tide test reorder.tide --example boundary
tide run reorder.tide --call reorder --inputs '{"quantities":[5,1],"minimum":3}'
# [false,true]
```

When writing a new function, use `describe` to look up an unfamiliar operation’s signature and operand order. Give a boundary case a name and run it before checking the whole module with `tide test reorder.tide`. For a failing example, `tide test reorder.tide --diff --explain=executed` shows the expected and actual values and the expressions that ran. When the task needs file or database access, declare the capability in the function signature and bind it at the CLI. Keep application logic, libraries and executable examples in TIDE. [Two-module JSON tutorial](GETTING_STARTED.md#read-an-order-from-json) · [Project conventions](AGENTS.md)

### Prepare a change

For the balance function, `context` identifies `main` as a caller and `E_OVERFLOW` as a possible error. An agent can request the example index first, then fetch the inputs and expectation for just one example. To prepare an edit, `hole` gives the required type and the names available at the selected expression. Here `2:38` identifies the addition on line 2, column 38 of this revision.

```sh
./tide describe fold
./tide context apps/balance.tide --function balance --example-index
./tide hole apps/balance.tide --function balance --node 2:38
```

### Check and accept a change

Try swapping the operands of the addition on a temporary copy. The first edit previews the replacement and runs the examples. The second writes the checked change. Both use the revision read from that copy. These commands use `jq` to extract the revision.

```sh
work=$(mktemp -d)
cp apps/balance.tide "$work/balance.tide"
base=$(./tide check "$work/balance.tide" | jq -er .revision)
patch='[{"node":"2:38","replace":"+ entry total"}]'
./tide edit "$work/balance.tide" --base "$base" --edits "$patch"
./tide edit "$work/balance.tide" --base "$base" --edits "$patch" --write
```

An outdated base yields `E_REVISION`. One edit can update related nodes across multiple files atomically. To investigate an unexpected result, `tide test FILE --diff --explain=executed` reports the differing value and the code the failing example executed. [Editing and repair recipes](workbench/README.md)

## Installation and verification

TIDE 0.6.12 builds and runs on Linux x86-64 and ARM64. The native toolchain runs without Python. From a checkout, install the CLI with `make install-native PREFIX="$HOME/.local"`. The getting started guide lists the build dependencies. [Installation guide](GETTING_STARTED.md) · [Native compiler](native/README.md)

To compile the measurement report ahead of time, reuse the input file from the earlier example. The resulting Linux executable takes the same grants and inputs.

```sh
./tide build --aot apps/report.tide "$demo/report"
"$demo/report" --read input="$demo/readings.txt" --inputs '{"limit":80}'
# {"above":2,"peak":{"some":98}}
```

Runtime depends on the workload. In a local 100 MiB streaming benchmark, the compiled TIDE report processed 131.0 MiB/s and CPython processed 25.6 MiB/s. In a separate 1,000-event order import, TIDE took 39.09 ms and CPython took 19.93 ms. [Streaming benchmark](experimente/67_zeilenstrom/report.md) · [Order import benchmark](experimente/80_import_performance/report.md)

Run `make test` for the native regression suite and `make check-postgres` for the local database integration checks. The language reference covers evaluation, error handling, capabilities and resource budgets. [Language reference](LANGUAGE.md) · [Design and research roadmap](tasks/plan.md) · [Contributing](CONTRIBUTING.md)
