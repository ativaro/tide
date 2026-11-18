# TIDE · Language design 0.3

A TIDE program shall run locally without a language model. The human describes the desired behavior and sets access rights. The model writes and changes the functions. **Confirmed examples belong to the same program version as the code.** This allows checking whether an already made technical decision still applies when a change is made.

**As of 16 November 2026.** TIDE stands for **Typed Instructions, Deterministic Execution**. The [current executable version](README.md) and the [language reference](LANGUAGE.md) document the current implementation status. This text records the original draft and its justifications. The draft defines the format of program examples. The new rule form for state transitions and its two views are proposals from the research phase. In previous attempts, I found errors in both the pump and the light with and without state trace. In the examined light error, the wrong idle counter was visible one step before the wrong output. Whether a trace improves my success rate or processing time is an open hypothesis. In the [writing test](experimente/05-writing-study.md), all four normal functions and all four rule tables were correct on the first attempt. The rule bodies were longer in tokens. When changing a jointly named bonus start value from 1 to 3, the same change in the definition was sufficient in both forms. Whether the rule form helps me with other maintenance tasks is open. [Test protocol](experimente/findings.md)

## What "three times in a row" means in the program

An alarm becomes due for the first time when three consecutive temperatures exceed 80. For the decision, four counter states are sufficient: 0, 1, 2, and 3 for "at least three". A value of 80 or less ends the series. In the proposed rule form, the reset case is where I can see it when changing.

```tide
rule heat_ready temperature:i > b
state streak:i=0
when > temperature 80 -> streak=set if < streak 3 + streak 1 3
else -> streak=reset
out eq streak 3

example heat_three heat_ready
{"events":[70,81,95,82],"expect":[false,false,false,true]}

example heat_interrupted heat_ready
{"events":[81,70,95,82],"expect":[false,false,false,false]}

example heat_boundary heat_ready
{"events":[81,80,95,82],"expect":[false,false,false,false]}
```

The first two examples use the same measurement values. A change to "count all values above 80" would yield a false `true` in the second example at the fourth event. `heat_ready` indicates per measurement whether the condition is currently met. When a signal should be sent again after the first alarm is an independent, open technical decision.

## An event, a state transition

The pump starts under 20 and stops via 80. At exactly 20 or 80, the previous state applies just as in between. The example reaches 20 once with the pump off and once with the pump running.

```tide
rule pump level:i > b
state on:b=false
when < level 20 -> on=set true
when > level 80 -> on=set false
else -> on=keep
out on

example pump_limits pump
{"events":[20,19,20,80,81],"expect":[false,true,true,true,false]}
```

Regarding the light, a movement affects two fields simultaneously. It switches the light on and resets the idle counter. The counter distinguishes 0, 1, and at least 2 consecutive messages without movement. At the first idle, the light remains in its previous state.

```tide
rule light motion:b > b
state on:b=false missed:i=0
when motion -> on=set true, missed=reset
when eq missed 0 -> on=keep, missed=set 1
else -> on=set false, missed=set 2
out on

example light_restart light
{"events":[false,true,false,false,true,false],"expect":[false,true,true,false,true,true]}
```

### How a step is evaluated

1. The header `rule name ereignis:Typ > Ergebnistyp` describes a step. `state` declares named fields with type and start literal. For the experiment, we use integers and boolean values. Each example and each new run start with these values. Pump and light start off.
2. For each event, the runtime reads the `when` conditions from top to bottom. It selects the first true condition, otherwise the final `else` branch. Each condition has the type `b`.
3. In each branch, every declared field gets exactly one action. `keep` takes over its previous value. `reset` restores its declared start literal. `set ausdruck` computes a value of the same type. Missing, unknown, and duplicate field names are precheck errors. A comma separates actions outside of text literals.
4. Conditions and right-hand sides read the same state **before** the event. Field computations occur in the order of their declaration. If multiple possible errors exist, the first encountered is reported. `out` reads the computed new state and the event. Only when all computations including `out` succeed are the successor state and output jointly adopted. In case of an error, the state before this step applies. Swapping two field actions does not change the result.
5. The rule operates on passed values. Rights, file operations, and device accesses are excluded in state fields and step computations, even via helper functions. The existing type checks, error rules, and resource budgets apply. Even via `scan`, the call graph of rules and functions must remain cycle-free. Pump, light, and alarm in this design provide values for a simulation.

Normal functions can run a rule with `scan regelname liste` over a finite event list. The result contains exactly one output per input in the same order. An empty list yields an empty list; another call starts again in the initial state. An executable file can, for example, contain the rule `pump` and this entry function:

```tide
main > *b
scan pump list i 5 20 19 20 80 81
```

## Verify confirmed examples with a change

A `example` block resides in the same TIDE file as its target. The header names a unique example identifier in the file and the name of a rule or function. The following line is a JSON object. Blank lines separate the blocks. When comparing examples, the JSON content counts. Exactly one of the fields `expect` and `expect_error` must be present.

| Target | Input | Expectation |
|---|---|---|
| Rule | `events` contains the events starting from the declared initial state. | `expect` contains the visible output after each event. The length must match `events`, even for an empty sequence. The example driver reports the first deviation as `E_EXAMPLE` with event number starting from 1, expected and actual. |
| Function | `inputs` binds each parameter by name. For a read permission, the example driver generates a local test input from the specified text. | `expect` compares the typed return value with the JSON value. |
| Expected error for one of the two goals | Input as above. | Instead of `expect`, `expect_error` appears with an error code and optionally `reason` or `input_line`. All specified fields must match. A successful run fails this expectation. |

`tide check` should check bindings, types and sample structure. `tide test` runs the examples individually with fresh condition and limited test input. Also a file of rules and examples can be checked in this way. First `tide run` requires the entry-level function `main`. For normal program runs, examples serve as supplied specifications and do not cause additional test runs.

In the case of a proposed code change, the editor checks the examples of the previous version. If the requirement also changes, it shows the change separately using the example with previous and new expectations. A modified program output does not overwrite an expectation. A deletion or renaming of an example remains visible in the comparison of the versions. Undercover tasks for research are kept outside of these visible program examples.

**Origin of Expectation.** The draft distinguishes proposed examples from confirmed contracts. An audit report shall identify the originator, certifying person or professional source, the audited programme revision and the precise version of the objective, input and expectation. The note may refer to this status outside the source text. A model proposal or a successful test run does not in itself give any technical confirmation. An amended target remains a new proposal until the decision is proven. In the case of a pure code change, the previously confirmed example is retained as a comparison. The examples shown here illustrate the rules; their origin must not be subsequently derived from their mere inclusion in the draft.

## Write compactly, look up specifically

The write view uses prefix expressions and meaningful names like `temperature` and `missed`. In our two maximum programs, meaningful names with the tested tokenizers cost the same number of tokens as individual letters. The check view can unfold exactly one branch of the same syntax tree: from `if < streak 3 + streak 1 3` to `(if (< streak 3) (+ streak 1) 3)`. Both views refer to the same expression in the same revision. [Token measurement](tasks/notation.md)

**Limit of diagnosis.** If the `1` is omitted in `if < streak 3 + streak 1 3`, `+ streak 3` remains a complete partial expression. Only at the end is the third operand of `if` missing. The same corrupted sequence also arises from `if < streak 3 + streak 3 0` if the final `0` is omitted. Therefore, the deleted position cannot be uniquely reconstructed from the input alone. With a fully parenthesized prefix, the corresponding first deletion would already be noticeable at the closing bracket of `(+ streak)`. In the self-experiment with a single marked operation, all six changes and repairs are found in every representation. For a deletion directly at the marked operation, the examiner named the affected call in 8 of 8 cases, compared to 3 of 8 without marking. For deeper deletions, the success rate remained at 4 of 16 with both views. An adjustable selection remains a proposal for the editor. [Experiment with local bracketing](experimente/08_lokale_klammern/report.md)

A state trace can be requested for an example and an event. For the **correct** light rule, the request would look like this:

```sh
tide trace sensors.tide --example light_restart --step 2 --fields on,missed
```

| Event | Chosen Branch | Field | Before | Action | After |
|---|---|---|---|---|---|
| 2 · Movement | `when motion` | `on` | `false` | `set true` | `true` |
| 2 · Movement | `when motion` | `missed` | `1` | `reset` | `0` |

If I were to replace `missed=reset` with `missed=keep`, the counter would remain at 1 here. The example reported its first incorrect **output** only at event 3. The trace for step 2 shows the actually chosen branch and its values; a specification for internal fields does not require this. It arises from the limited replay of the example from the initial state. A complete state log is not required for a normal run.

## Nine design questions from practice

The following table translates the mentioned difficulties into concrete requirements for TIDE. Previous self-experiments examined notations, examples, and state traces. The remaining rows are proposals that we must test on new tasks.

| Difficulty | Decision for TIDE 0.3 | How we can test them |
|---|---|---|
| Non-local effects | A file contains named functions and rules with statically resolvable calls. `check` shows per definition the direct call targets and transitively possible side effects, e.g., reading via a passed parameter. A rule state belongs to exactly one run. | If a helper function is indirectly called `read`, this effect must appear at the caller. A call from a rule branch is rejected with the concrete call chain. |
| Dynamic Typing | Parameters, results, and state fields have declared types. Local types are derived. The same strict check applies when writing in the editor and when starting via the CLI. | `eq "9" 9` reports the wrong operand type. A text value as a successor state of an integer field fails already during the precheck. |
| API and Version Drift | The project binds the language version and exact operation catalog. Editor, prechecker, and short reference use the same bound edition. An unknown operation leads to a finding at the call site. | With a deviating catalog, the tool reports the expected and found identifier before execution. A newer included reference must not change the finding. |
| Global Invariants | The prechecker controls the entire call graph for cycles and unauthorized effects. State changes are atomic per event. Computation and memory budgets apply across function boundaries. For domain rules like "consecutive", the order provides the expected examples. | An indirect cycle is detected during the precheck. If the second field calculation fails, the first field value and the output remain at the last completed step. |
| Syntactic Fragility | Arity, block form, and JSON-schema determine the structure. The planned formatting unifies whitespace and indentation. The parser reports the recognition position and, where determinable, the open expression along with the expected operand count. In case of an omission, the recognition position may only be at the expression end. | Reparsing a formatted file yields the same tree including examples. Formatting twice yields identical bytes. |
| Too Many Notations | For each core operation, there is one notation. Compact and precheck views read the same tree. For state actions, the intent remains visible: `reset` follows even after a change the declared start value. | A formatting retains `reset`; it does not replace it even with start value 0 by `set 0`. Both views must point to the same node. |
| Little Training Material | Each operation has a concise, offline retrievable entry with arity, types, effect, possible errors, and a valid example. In case of a gap, the model can specifically request the matching entries and visible helper functions. | For an unknown operator to me, we compare my first attempt with and without the matching reference entry. Additional context and repairs count. |
| Build and Tooling | For initial attempts, a bound local tool version suffices. Reproduction requires source state, tool and catalog identifiers, budgets, examples, and test inputs. A later library resolution must also be precisely defined. | Two isolated runs of the same tools with the same state and the same test data yield the same values and stable diagnostic fields. |
| Poor Error Messages | A diagnosis names the earliest observed violation, error code, and matching position. Type errors name expected and actual types. Example deviations name example, event, expected, and actual. A requested trace shows the involved field changes. | At the light, the example test reports the wrong output at step 3. The trace at step 2 shows the missed reset. The diagnosis separates these observations from a suspected cause. |

**Proposed Version Contract.** A project maintains language version (here `0.3`), content hash of the operation catalog, and exact tool version in a small lock file. Ad-hoc trials can record the same information in the trial log. `tide describe need --json` is intended as a targeted retrieval of the operation description used for verification. The planned verification finding contains the actually used version identifiers. Thus, a diagnosis can also be attributed in another work context of the same API. Tests for reproducibility begin with local, fixed inputs. File contents from another run would be an additional influencing factor.

## Functions for Data Processing

The following complete program reads integers from a granted file. It yields the highest value, an explicit empty result, or the line number of the first invalid value.

```tide
main input:r > ?i
fold lines read input nil i best row line
let value need int line "invalid_integer" row
some case best value previous if > value previous value previous
```

The first line is the contract. `input:r` denotes the read right bound by the caller, `?i` the result "Integer or empty". The rest is **one expression**. From the operation name or explicit list length, the number of operands is derived. For own functions, decomposition into calls presupposes known arity. Syntax thus depends on information outside the expression. The parser can thus uniquely decompose `lines read input` into "read input, then split by lines". In the function body, spaces and line breaks serve equally as separators.

`fold` processes the lines in order. It starts with `nil i`, the empty maximum. In each step, `best` stands for the previous result, `row` for the position from 1 and `line` for the current text line. `need` provides the number read or triggers a data error with reason and input line. In the program shown, this error reaches the caller. `case` covers both states of the previous maximum. The value of the last expression becomes the next state. The final state is the result of the function.

| File content, here with visible line break `\n` | Results |
|---|---|
| `-8\n-2\n-5\n` | `{"some":-2}` |
| File with zero bytes | `{"none":true}` |
| `4\nx\n` | `E_DATA`, reason `invalid_integer`, `input_line` 2 |
| `4\n\n7` | Same error in line 2 |

**Change order:** “In addition, return the line number of the first maximum.” The result type, the type of empty state and the expression for the new state will change. In the case of a tie, the existing pair is passed on. `-8\n-2\n-2` is `{"some":[-2,2]}`.

```tide
main input:r > ?&ii
fold lines read input nil &ii best row line
let value need int line "invalid_integer" row
some case best pair value row previous if > value first previous pair value row previous
```

## How the core works without brackets

| Component | Designation for the prototype |
|---|---|
| Functional limitations | The header says name, zero or more parameters `name:typ`, then `>` and the return type. Then follows exactly one expression. A blank line separates definitions and must not occur in the hull. The reserved headers `rule` and `example` indicate rules and examples. Function and rule names are file-wide unique. All signatures are read in before the calls are resolved. An executable file has exactly one `main`. |
| Types | `i` And it is a sign of sign. 64-bit integer, `b` a truth value, `t` UTF-8-text, `r` a reading right. The type constructors `?T`, `*T` and `&AB` form option, list and pair. Each constructor has a fixed position. So also `?&ii` has exactly one reading. |
| Values and ties | A literal or variable is a complete expression. Text literals use JSON quotes and escapes. `let name wert rumpf` binds an immutable local value. The result is the value of the hull. Function names, operation names and local bindings must be unique in their visible area. Type abbreviations are in their own type fields. |
| Calls | `+ a b` adds two integers with overflow check. `> a b`, `< a b`, `>= a b`, `<= a b` and `eq a b` compare two integers and give a truth value (`true` or `false`). `>=` and `<=` are also true of equality. Own functions follow the same rules. `twice x:i > i` with the hull `+ x x` is accessed by `twice 7`. Direct or indirect recursion is initially rejected by the examiner. |
| Control Flow | `if test ja nein` evaluates only the selected branch. `case option leer name voll` binds the content exclusively in the full branch. Both results must have the same type. `nil T` and `some wert` construct options. `need option grund position` unpacks an option or yields `E_DATA` with reason and position. Reason and position are only evaluated in case of error. |
| Repetition | `fold liste start zustand pos element rumpf` evaluates the list and start once. For each element, the three names are bound in the body. For an empty list, the result is the start value. Start, body result, and end value have the same type. A nested `fold` enables further loops and consumes the same work budget. |
| Data | `pair a b` forms a pair, `first p` and `second p` select components. `list T N` with subsequently exactly N element expressions constructs a list. N is a limited, parser-checked non-negative length specification. `read` accepts a read permission, `lines` splits text at LF or CRLF. The final separator does not generate an additional line. Embedded blank lines are preserved. |
| Checkable Errors | `int text` accepts ASCII-decimal digits with optional minus without space. Invalid or too large numbers yield an empty option. Overflow at `+` yields `E_OVERFLOW`. Unknown names, missing operands, invalid types, and excessive expressions are rejected before execution. |

The checker derives local types from the program. Model and checker share a versioned table with the signatures of the operations. This allows the model to save derived types, return statements, block endings, and parentheses when writing. Whether a concrete model reliably handles shorter text is decided by the model test.

## Error Handling

An empty maximum is a valid result. A defective measurement line is an error in the same order. The conversion into an error is visible in the program: `int` yields an option, `need` demands a value and generates `E_DATA` in the empty case. For own domain rules, there are `fail "grund"`. The text is a stable, program-selected reason within `E_DATA`. The runtime supplements the source position.

A function can handle a specific error specifically. This example yields the value for a representable sum and an empty option for an integer overflow.

```tide
sum_option x:i y:i > ?i
catch E_OVERFLOW some + x y _ nil i
```

`catch CODE ausdruck name ersatz` first evaluates the protected expression. On success, it returns its value directly. For the specified error code, the replacement is evaluated once, even if the error originates from a called function. Expression and replacement must have the same result type. A terminating expression like `fail` fits at any result point. Other errors proceed with their original diagnosis to the next surrounding handler. An error in the replacement also proceeds outward. There is no automatic repetition.

`_` discards the error details. A name at this point binds the diagnosis for the replacement. `input_line name` provides the input line as `?i`, `has_reason name "grund"` checks the technical reason, and `raise name` forwards the same diagnosis including its origin position. These operations expect a visible diagnosis name from a handler. Thus, a program can handle a known data error and forward an unknown reason.

| When the error occurs | Behavior |
|---|---|
| During the evaluation of an operation | `E_DATA` are catchable for technical input errors, `E_OVERFLOW` for arithmetic, `E_UTF8` for invalid text encoding, and `E_IO` for a read error on an already granted, opened handle. |
| When checking the program or setting up inputs | Syntax and type errors, as well as errors when opening the specified file, are reported by the starter. The evaluation of the program has not yet begun at this point. |
| In case of a rights or budget violation | `E_CAPABILITY` and `E_LIMIT` terminate the run. The checker returns these codes as well as unknown codes as the target of a `catch`. Even within a handler, the evaluation consumes the original budget. |

`tide check --json` specifies for each checked function under `may_fail` the set of potentially externally reachable **catchable** codes. It results from the operations and called functions. A handler removes its code from the protected expression and adds the possible errors of its replacement. At `scan`, the catchable errors of the conditions, field actions, and rule output also count. Thus, the checker reports an empty set for `sum_option`. The maximum program can forward `E_DATA`, `E_IO`, and `E_UTF8`.

For the file `4\nx\n`, the uncaught diagnosis of the maximum program is:

```json
{"code":"E_DATA","reason":"invalid_integer","file":"maximum.tide","line":3,"column":11,"input_line":2}
```

`line` and `column` refer to the triggering `need` in the TIDE source code. `input_line` points to the erroneous line in the measurement report. Only an error that reaches the starter generates the CLI error output. A successfully handled error yields a regular result.

## Small changes without full re-output

In "Find the Minimum", only the comparison `>` in the function body changes. The planned editor assigns a local node number, operands, and types to the model for a selected operation. If the session binds number 7 to the comparison, the entire technical change is `op 7 <`. The node number applies to exactly the read program state. The session and base revision belong to the editor call.

Before the takeover, the editor checks the target and base revision, as well as the types and permissions of the **entire** modified program. The confirmed examples must pass for the taken-over version. An intentionally modified contract is visible together with the change to its examples. For multiple related changes, such as the pair result, all affected parts are checked and taken over together. If the status is outdated or there is a check error, the saved status remains. In the model comparison, tokens for context, revision, tool call, and any repairs also count.

### What the editor should show when continuing to program

**The technical reason for a decision.** A function includes a small executable example from the order. For "first occurrence," this visible sample with two equally high measurement values is sufficient. The example driver binds the text as local test input to the read permission.

```tide
example first_peak main
{"inputs":{"input":"9\n9"},"expect":{"some":[9,1]}}

example invalid_line main
{"inputs":{"input":"4\nx\n"},"expect_error":{"code":"E_DATA","reason":"invalid_integer","input_line":2}}
```

A version that takes over the new pair in case of a tie provides `{"some":[9,2]}`. Both programs are type-correct. The example entry determines which choice corresponds to the order. In case of a failure, the driver reports input, expected, and actual. The sample belongs to the function's work context. The hidden tests of the model comparison remain separate from this.

**A precise answer in the middle of a change.** A model may mark a partial expression as a gap in the editor. At the position of the last `if` in the pair example, the checker should display the expected type `&ii` and the local bindings, for example `value:i`, `row:i`, and `previous:&ii`. Additionally, the permissions available at this position are shown. The editor holds this unfinished status as a draft. Only the fully implemented and checked version is executable. For this attempt, a gap in the already known syntax tree is sufficient.

## Limits of execution

The local starter checks source code, types, and required permissions before opening the requested data file. It binds a user-selected regular file to the matching parameter. A string cannot generate a read permission. Permissions can only be passed as arguments. Even nested return values must not contain permissions. Read data may appear in the result.

The language core binds file encoding, HTTPS requests, SQLite, and PostgreSQL to explicit permissions. A HTTP service binds the address granted by the caller. Shell and any native foreign calls are not accessible to the guest program. The language reference describes permissions and limits of individual operations. The trust foundation includes starters, parsers, checkers, interpreters, and their dependencies. Errors in these components remain a risk. The first target environment is a local process.

**Operating System Interface.** At `read input`, the runtime checks the bound read permission and executes the required operating system operation. The TIDE program knows the logical permission and the result type. With `--db name=pfad`, the caller binds a SQLite connection. `sql_exec` and `sql_query` bind values to named SQL parameters. `transaction` rolls back changes on this connection in case of an escaping error. [SQLite language rules](LANGUAGE.md#sqlite)

**Events and Interruptions.** The measurement value program and `scan` process completed inputs. For a later application that, for example, waits for new measurement values, a typed event input is suitable. The host could provide a sequence of measurement values or a stop signal. Direct hardware interrupts would be a separate design decision for a target such as firmware or device drivers. For this, permissible actions in the handler and the maximum reaction time must be defined.

The starter limits source size, nesting, and list lengths during parsing. The interpreter limits input bytes, guest memory, and work steps. Library operations are calculated based on the processed data volume. Exceedances yield `E_LIMIT`, missing permissions `E_CAPABILITY`. The short notation and the editor undergo the same checks as a complete program.

Planned commands for the measurement value example:

```sh
tide check maximum.tide --json
tide test maximum.tide
tide run maximum.tide --read input=werte.txt
```

`check` yields the signature with the required permissions or a diagnosis with a stable error code, file, line, and column from 1. For a type mismatch, operation, argument position, expected, and found type are added. A faulty data line has the separate field `input_line`. `run` writes a JSON result to stdout (exit code 0) on success, or a JSON diagnosis to stderr (exit code 1) on error. Decimal JSON integers must retain the entire I64 range.

The [Token comparison](tasks/notation.md) documents the first measurement values. The [Development plan](tasks/plan.md) describes how we check correctness, model effort, and execution time separately.
