# TIDE 0.6 · Language Reference

The reference describes the language rules of TIDE 0.6. The executable scope and remaining open commands of the native package are documented in the [Development status](tasks/todo.md).

## File and Module

UTF-8, a blank line between declarations. Line breaks in the function body separate operands just like spaces. An executable program has a function `main`. Libraries may contain only declarations and examples. The right-hand side of a function is exactly one expression. Each call may optionally be parenthesized. Names begin with a ASCII letter, followed by letters, digits, or underscores. Bindings are immutable. Name conflicts and recursive call chains result in check errors.

```tide
twice value:i > i
+ value value

main > i
twice 7
```

`use readings` loads the regular file `readings.tide` from the same directory. Neighbor files share the namespace of their project or package. Names from transitive neighbor imports are available there. Duplicate import paths load the same module once; cyclic imports fail. Modules are resolved during checking. The revision includes the source code of the entry program as well as paths and contents of all imported modules and packages.

`tide modules FILE [--json]` provides the module graph as a JSON. `modules` lists the files in the order of the first visit during depth-first search. `imports` specifies for each import location the source file, the target, and the one-based line and column of `use`. Repeated imports have distinct locations. The hash processes modules sorted by filename and matches the revision of `tide check` for a valid project. The command resolves imports before type checking and is thus also usable with an incomplete body.

### Versioned Packages

`use rowtext@2.0.0` loads `vendor/rowtext/2.0.0/package.tide` relative to the project entry directory. The package starts with `package rowtext 2.0.0`. Name and version must match the import. The three decimal parts of the version are exactly pinned. Each package name has one version per project. Contradictory pins result in `E_PACKAGE`. Versioned dependencies of a package also use the `vendor` directory of the project entry.

`export parse` makes a function callable as a `rowtext.parse` for the directly importing namespace. `export` can also grant rules, records, and variants. Types are referenced, for example, as `{rowtext.Result}`. Within the package, function and type names remain short. Neighboring files of a package belong to the same namespace, and an export declaration can grant names from them. Multiple export names are separated by spaces on the same line.

Packages and their exact versions appear in `tide modules --json`. `tide check`, `run`, `test`, and `build --aot` use the same package resolution. Inspection and edit preview also work on package sources. A mixed node edit can update the package and its callers together. For an edit confined to a single vendored file, open the package as the project.

### A package with a type parameter

A package can declare one named type parameter in its header. Its functions and record fields can refer to that parameter in type positions.

```tide
package jsoninput 1.0.0 Payload

export decode

decode bytes:y > {Payload}
json_decode {Payload} bytes
```

The importer supplies a visible record or variant by name. For example, `use jsoninput@1.0.0[Document]` gives `jsoninput.decode` the result type `{Document}` in that project. A dependency can also receive a qualified exported type or the importing package's own parameter. The checker resolves the concrete type before it checks function bodies. Calls use the usual nominal type rules and operand locations.

All imports of a given package in one project must agree on the version and concrete type. A missing, unexpected or conflicting argument produces `E_PACKAGE`. An unknown type produces `E_TYPE`. Check a parameterized package through a consumer that supplies its type. The module graph records the spelling at the import in `type_argument`.

### Comparing Keys with Different Priorities

The library module [ordering.tide](lib/ordering.tide) can be copied alongside your own modules and included with `use ordering`. `prefer_min candidate current on_equal` decides in favor of the smaller i64 value. `prefer_max` decides in favor of the larger. In case of equality, both return `on_equal`. This allows combining ascending and descending criteria across the entire i64 range.

```tide
use ordering

better delay:i old_delay:i capacity:i old_capacity:i > b
prefer_min delay old_delay (prefer_max capacity old_capacity false)
```

Here, lower latency wins; with equal latency, higher capacity wins. In case of a complete tie, the previous candidate is retained with `false`. All function arguments are evaluated before the call. If a subordinate criterion may only be read or computed in case of equality, it belongs in the corresponding branch of a `if`. [Executable Boundary and Evaluation Checks](lib/ordering_checks.tide)

## Types and JSON

| Type | Values |
|---|---|
| `i`, `b`, `t` | Signed 64-bit integer, boolean, Unicode text. Text literals use JSON quotes and escapes. |
| `q`, `z` | Exact decimal number with six decimal places or timestamp with UTC offset. |
| `n`, `w`, `p` | Rights bound by the caller for a HTTPS origin, a file line, or a PostgreSQL connection. |
| `d` | Database law as a function parameter. The caller binds it with `--db name=pfad` to an SQLite database. |
| `y` | Byte sequence up to 128 KiB. JSON-hex string with two digits per octet. |
| `%A` | Dictionary with text keys and a uniform, non-optional value type `A`. JSON-object. |
| `?A` | Option. Empty as `{"none":true}`, populated as `{"some":wert}`. |
| `*A` | List of homogeneous values as a JSON-array. |
| `&AB` | Pair with two fixed types as a JSON-array of two values. `&i?i` contains a number and an optional number. |
| `{Name}` | Named type. A record is a JSON-object with exactly the declared fields. A variant is a JSON-string with one of the declared case names. |
| `r` | Read permission bound by the host in a function parameter. Permissions can be passed to helper functions. Returns, record fields, options, lists, and pairs are restricted to data types. |

For typed JSON inputs, additional keys, missing parameters, duplicate object keys, and confusion between numbers and boolean values are errors.

In the native project evaluator, `pair` combines two data values. The components may have different types, such as `&{Buffer}{Effect}` for the condition after pressing a button and the requested action. Basic values, lists, options and other pairs can also be components. `pair` evaluates both arguments from left to right. `first` and `second` keep the respective type. In turn, lists and options can include pairs. Nested lists such as `**i` can be used as parameters and returns. [Executable list and loop examples](native/bootstrap/fixtures/functions/iteration.tide) [Executable Type Examples](native/bootstrap/fixtures/functions/composite_pairs.tide)

```tide
record Point
x:i y:i

shift point:{Point} > {Point}
with x point + get x point 1

main > {Point}
shift make Point x 2 y 5
```

Result: `{"x":3,"y":5}`. `make` checks field names in declaration order. `get` reads a field, `with` provides an updated value. Record types can contain other data structures. Cyclic record definitions are rejected.

The native project evaluator supports records as function parameters, returns, and accumulators. A field can contain a basic value, a named record, or a variant, as well as a list or option of these types. A field can also be a pair, a list of pairs, or an option with pair content. At the JSON boundary, record fields may appear in any order. This also applies to records within lists. Their type and names must match the declaration. If a field name is incorrect in the program, TIDE reports `E_FIELD` with the source position of the name. A mis-typed field value at `make` or `with` results in `E_TYPE` with field, expected type, and actual type. [Field examples](native/bootstrap/fixtures/functions/record_values.tide) · [Nested values](native/bootstrap/fixtures/functions/collections.tide)

### Variants

```tide
variant Signal
red green

speed light:{Signal} > i
match light
red   0
green 50
end

main > i
speed (tag Signal green)
```

`variant` declares a closed set of named cases without user data. `tag Signal green` generates a value of type `{Signal}`. Each variant type has its own identity, even if two types use the same case names. At an JSON border, TIDE checks the name based on the expected type. This also applies to variants in records, lists, options and pairs. The words `variant`, `tag`, `match` and `end` are reserved from version 0.4.

`match` evaluates the input exactly once. Each case requires exactly one branch. The order is arbitrary. All branches must yield the same result type or raise an error. Only the selected branch is executed. `end` unambiguously closes the expression even if a branch is missing.

For otherwise valid types and expressions, the diagnosis `E_MATCH` lists all incomplete `diagnostics` positions in the loaded project with function or rule, position, variant type, and missing cases under `match`. Adding a variant does not obligate returning it. The difference is shown by [Try with game phases](experimente/10-variants.md).

The native project evaluator processes variants as function arguments, results, local bindings, record fields, pair components, and as elements of a list or option. In `test --explain=executed`, the visited case appears under its name. [Variant examples](native/bootstrap/fixtures/functions/variants.tide) · [Lists and options](native/bootstrap/fixtures/functions/collections.tide)

## Bytes, dictionaries, and typed JSON import

`read_bytes input` reads the octets of a read permission directly. `read` and `read_bytes` share the same snapshot and the same input budget. `utf8_bytes` encodes text as UTF-8. `byte_len` counts octets. `byte_at` yields an optional number from 0 to 255. For negative indices and beyond the length, the option is empty. The hex representation accepts uppercase and lowercase letters and uses lowercase for output.

`dict i` creates an empty dictionary of type `%i`. `dict_put werte schlüssel wert` yields a new dictionary and replaces an existing entry. `dict_get werte schlüssel` yields an option. A dictionary holds up to 4096 keys with up to 4096 Unicode code points each. The output sorts keys by code points. Even the empty string is a valid key.

`json_decode {Document} payload` reads a complete UTF-8 document from `payload:y`. The compiler checks the target type. The decoder assigns record fields by name. Missing optional fields and `null` yield `none`. Other values must match the inner type. Unknown record fields may contain valid JSON values. In dictionaries, the decoder checks every value. Duplicate keys and invalid JSON yield `E_DATA`, invalid UTF-8 bytes yield `E_UTF8`.

The diagnosis includes the source position of `json_decode` and the JSON pointer `issue.path`. The root has the path `""`, array indices start at zero. In keys, `~` is converted to `~0` and `/` to `~1`. An example with `"expect_error":{"code":"E_DATA","path":"/readings/1/note"}` checks the exact path. Function arguments and results continue to use `{"some":…}` or `{"none":true}` for options. [Measurement report as JSON-Importer](apps/report_packages/json_report.tide)

`read_batch input limit` reads a granted regular file from offset zero into bytes. The limit is inclusive and ranges from 0 to 4,194,304 bytes. A larger file or invalid limit raises `E_LIMIT`. Each successful read charges its full size to the shared 128 MiB input quota. It credits eight evaluation steps and 64 memory-budget bytes per input byte, capped at two million steps and 32 MiB, then charges one step plus one per 32 bytes and eight memory-budget bytes plus the input size. A second call starts at offset zero and incurs its own charge.

## Evaluation

Expressions are evaluated from left to right. `if`, `and`, `or`, `case`, `match`, `need`, and `catch` evaluate only the operands required. `let` binds a local value. `fold` binds the accumulator, the position starting at **1**, and the element per item. The list index at `at` starts at **0** and yields an empty option outside the list. Checked arithmetic returns `E_OVERFLOW` on overflow. `div` rounds toward zero. Division or remainder by zero raises `E_DATA` with reason `division_by_zero`.

`< a b`, `> a b`, `<= a b`, `>= a b`, and `eq a b` compare two values of type `i` and return `b`. `<=` and `>=` include equality. A comparison covers the full signed 64-bit range without overflow.

`map B liste element rumpf` evaluates the list once. For each element, TIDE evaluates the body once in input order. The name is valid only within the body. Each result value must have the specified type `B`. An empty input yields an empty list of type `*B`. For example, `map i (list i 2 4 7) x (+ x 1)` yields the value `[5,8]`. On error, the mapping aborts at the first affected element. The diagnosis retains the source location and includes in `map_index` the zero-based index of the innermost affected mapping. The guest budget counts the list head once and each result value upon insertion. Operations in the body consume their usual budget. [Examples for records, pairs, errors, and nested mappings](native/bootstrap/fixtures/functions/maps.tide)

`while start zustand bedingung schritt` checks the condition before each step and returns the last state. `recur` calls the enclosing function with new arguments. The work budget applies, and at most 48 active recursive calls are allowed. The AOT compiler translates nested lists, these two control forms, and state rules, which a function with `scan` calls. [Light rule](apps/light.tide)

`nil T` and `some wert` produce options. `case option leer name voll` distinguishes both cases. `need option grund zeile` yields the content or a data error with reason and input line. `int` accepts exactly one decimal i64 number with an optional minus sign. `lines` splits at LF and CRLF, preserves embedded blank lines, and adds no line after a trailing separator.

`rule` describes a transition per input event. Start values, the first matching `when` branch, and a concluding `else` branch define the behavior. Each branch assigns exactly one action to each state field. `keep`, `set`, and `reset` read the old state. `out` reads the new state. An error aborts the transition before its output is published. `scan` restarts on every call. State fields support `i` and `b`; events and outputs may also be composed. Rules operate without file access, including all helper functions.

`text_len` counts Unicode code points. `text_slice text start stop` yields the section from `start` inclusive to `stop` exclusive. `text_find text muster start` searches forward from `start`. `text_rfind text muster stop` searches for the last match that lies completely before the boundary `stop`. Both return the absolute start of the match as `?i`. All indices start at zero. The operations limit indices to the range from zero to the text length.

The executable reference for all **75 operations** is retrievable via `tide describe`. Each catalog entry has a signature and an example expression.

## Errors, Rights, and Budgets

`catch CODE ausdruck name ersatz` handles exactly one catchable error. In the replacement, `name` binds the original diagnosis. `_` discards it. `input_line name`, `has_reason name text`, and `raise name` read or propagate this diagnosis. Catchable are `E_DATA`, `E_OVERFLOW`, `E_UTF8`, and `E_IO` during execution. Errors when binding inputs as well as `E_CAPABILITY`, `E_TRANSACTION`, and `E_LIMIT` abort the run.

File contents enter the program via `tide run FILE --read parameter=pfad`. The host checks the entire project and the input signature before opening the specified data files. `read` creates a limited snapshot on the first call. Further `read` calls with the same grant use this snapshot. Examples bind UTF-8 contents in memory. A path in `--inputs` cannot generate read rights. To write, the caller binds their own file or database right.

`fail_at reason index path` raises `E_DATA` with a text reason, a JSON Pointer in `issue.path`, and an optional integer index. For example, `fail_at "invalid_quantity" (some 2) "/events/2/qty"` reports `input_line: 2`. Use `(nil i)` for a document-wide failure. A handler can inspect the original reason with `has_reason`.

### External APIs and Services

`https_get {Antwort} api pfad header timeout_ms bytes` and `https_post {Antwort} api pfad header timeout_ms bytes rumpf` deliver a record with `status:i headers:%t body:y`. The caller binds `api:n` via `--https api=https://host:port`. The path starts with a single slash. Requests remain at the bound origin. The client checks the certificate and hostname. For a private CA, the caller may set `TIDE_HTTPS_CA_FILE`. HTTP error statuses reach the program. For transport errors, `E_IO` applies. Per request, 1 to 30,000 ms and up to 131,072 response bytes apply. An example may bind the right with a table of path and pair `[status,text]`. [Two-sided measurement report with error examples](apps/report_packages/api_report.tide)]

`json_encode wert` generates public UTF-8-JSON-bytes. An empty option appears as `null`, a populated one as its content. `utf8_text bytes` checks UTF-8. `q` stores signed i64-millionths. `q_units` and `q_from_units` allow checked integer arithmetic on this scale. During decoding, value and precision must be exactly representable. `z` accepts RFC-3339-datetimes including seconds, optional fractional seconds up to nine digits, and `Z` or numeric offset. `unix_seconds` provides the rounded seconds since the Unix epoch. [Decimal, time, and JSON examples](native/bootstrap/fixtures/functions/api_values.tide)

`write_bytes ziel daten` atomically replaces the file bound with `--write ziel=pfad` and returns the byte count. The runtime synchronizes the temporary file before renaming and afterward the directory. An error may occur in the final step after the new content has become visible. Examples bind write permission with `":memory:"`.

`pg_exec pg sql parameter` and `pg_query {Zeile} pg sql parameter` receive connection details via `--pg pg=DSN`. PostgreSQL binds placeholders `$1`, `$2` from a list `*?t` as text or SQL-NULL. The query maps columns by their names. Supported include among others `numeric` for `q` and `timestamptz` for `z`. The latter are read in UTC. The runtime sets five seconds for connection establishment and statement execution and a limit of 4,096 result rows per query. For a remote database, the caller can set the TLS check with `sslmode=verify-full` in DSN. [Executable PostgreSQL example](native/bootstrap/fixtures/functions/postgres_report.tide)

`tide build --service FILE OUTPUT HANDLER` builds an HTTP service. Its handler accepts `method:t path:t headers:%t body:y` followed by its declared capabilities. The response has the fields `status:i headers:%t body:y`. Startup requires `--listen IPv4:Port`. Port 0 lets the operating system choose a free port. The listener speaks HTTP and can sit behind a TLS endpoint. [Measurement service and HTTPS client](apps/report_packages/measurement_service.tide)

`--workers` sets the maximum number of concurrent handlers from 1 to 32 (default 4). `--queue` sets the number of complete requests that may wait for a handler from 0 to 96 (default 16). Waiters enter in arrival order at admission. A full queue returns HTTP 503 with `{"error":"queue_full"}` and `Retry-After: 1` before opening any handler capability. At zero capacity, an available worker can still serve a request immediately. The HTTP transport separately allows up to 128 connections, including incomplete uploads. Connections above that limit may wait at the TCP listener.

Clients should keep the connection open for the response. After upload, a peer closing its TCP write side signals cancellation. A waiting request releases its queue slot. Active guest computations, HTTPS transfers and running PostgreSQL queries check for cancellation. SIGTERM and SIGINT also cancel active and queued work. On orderly shutdown the service logs the highest active and queued counts, overload rejections and cancellations. A transaction that has already committed retains its effect. [Order webhook and retry contract](experimente/81_order_webhook/report.md)

### SQLite

A parameter `db:d` receives a connection for reading and writing with `--db db=messungen.db`. SQLite can create the file and use journal files alongside it. `--db db=:memory:` opens a fresh database for a run. An executable TIDE example binds `"db":":memory:"` in its inputs. Each example starts with its own empty database.

```tide
record Anzahl
n:i

anzahl db:d sensor:t > *{Anzahl}
sql_query {Anzahl} db "SELECT count(*) AS n FROM measurements WHERE sensor=:sensor" (dict_put (dict t) "sensor" sensor)
```

`sql_exec db sql parameter` executes a statement without result columns and returns the number of changed rows. `sql_query {Row} db sql parameter` executes a read statement. Each result column must correspond exactly to one record field. The order may differ. Both operations bind named placeholders like `:sensor` from a record or dictionary. The set of field names must match exactly. For a statement without placeholders, `(dict i)` suffices.

| TIDE-type | SQLite value |
|---|---|
| `i`, `b` | INTEGER in the i64 range, for `b` only 0 and 1 |
| `t`, `y` | UTF-8-TEXT or BLOB |
| `q`, `z` | INTEGER in millionths or TEXT with UTC-offset |
| Optional base type | Value of the base type or NULL |

An unsuitable column reports `E_DATA` with `reason="sqlite_column"` and a path like `/0/n`. For `sql_query`, at most 4,096 result rows and the remaining guest allocation budget apply. Long SQL statements may fail at the SQLite work budget with `E_LIMIT`.

`transaction db ausdruck` starts with `BEGIN IMMEDIATE` and yields the expression value after a successful commit. If an error leaves the body, TIDE reverts its changes before an outer `catch`. An error handled in the body allows continuation as long as the transaction remains active. A transaction abort triggered by SQLite itself leads to `E_TRANSACTION`. Nesting on the same connection reports `sqlite_nested`. Transaction control, `ATTACH`, and `PRAGMA` via guest-SQL are locked. [Measurement report with transaction](apps/report_packages/sqlite_report.tide) · [Executable SQL examples](native/bootstrap/fixtures/functions/sqlite.tide)

With `fold_rows {Zeile} db sql parameter start akk index zeile rumpf`, TIDE reads one typed SQLite row at a time and returns the accumulator at the end. The body receives the position starting at 1. If the result set is empty, the start value is preserved. Work and guest allocations remain bounded. [Export of 5,000 rows](native/bootstrap/fixtures/functions/exports.tide)

### Read line by line

`fold_lines input bytes start akk zeile text rumpf` reads from a grant starting at the file beginning and yields the final accumulator. `bytes` is an integer between 0 and 134.217.728. The first row has number 1. The body receives the current accumulator, the row number, and the decoded text. It yields a value of the start type. An empty file yields the start value. Each call has its own read position and reads the file in blocks. For reproducible results across multiple runs, its content must remain stable during the process.

LF and CRLF close a line. A single CR at the file end belongs to the text. A trailing LF does not create an additional empty line. The byte budget counts the original UTF-8 bytes including line endings. Exactly exhausted budget is valid at the file end. Another line or another byte within the current line leads to `E_LIMIT`. Per line, at most 128 KiB including the line ending are allowed. All streams of a run additionally share 128 MiB of actual input bytes. Re-reading counts again.

Before evaluating each complete line, the reader checks its UTF-8. Read, decode, and budget errors incur `input_line`. Errors in the body retain their source diagnosis. For a valid line, the run has up to 32 additional work steps and 128 logical allocation bytes per byte read. The remaining balance is capped at the below-mentioned initial limit. The line text costs 8 plus 4 allocation bytes per Unicode code point. A body with a consistently large accumulator can thus process long files with limited memory. [Executable measurement report](apps/report_packages/stream_report.tide)

| Resource | Local Default Setting |
|---|---:|
| Project source code including imported modules, CLI-JSON input, Snapshot bytes per run by `read` | 128 KiB each |
| Elements per list | 4,096 |
| Expression nesting and call depth | 48 each |
| Additional modules / Import depth | 64 / 32 levels including entry |
| Initial budget per run or example | 100,000 steps |
| Initial budget for evaluated guest allocations per run or example | 4 MiB |

The guest budget evaluates logical values, including partial values contained multiple times. It is a deterministic language boundary. The process requires additional memory for source code and internal data structures. The runtime operates locally on finite data and event sequences. The security of an isolated service for foreign programs and a real-time guarantee have not been qualified.

## Tools for changes

In case of a type error in a bound JSON input, `E_INPUT` can specify the affected location under `issue`. `path` is a JSON pointer from the root of `--inputs` or the example contract. List indices start at zero. `expected` names the TIDE type or violated condition, `actual` the found value type or structure. A missing field has `actual: "missing"`. For a wrongly typed target value, `E_EXAMPLE` carries the path from `/expect`. For multiple errors, another location may become visible after the first correction. For an overly long unknown field name, the diagnosis refers to the surrounding object. [Examples and tool measurement](experimente/48_eingabediagnosen/report.md)

`test --diff` reports the first deviation within a result. For an unequal record field, TIDE yields `"difference":{"path":"/rows/383/balance","expected":27,"actual":26}` for example. The path is a JSON pointer relative to the result. Record fields follow their declaration order; lists and pairs use indices starting at zero. For lists, TIDE checks the length first (`aspect: "length"`), for options first `some` or `none` (`aspect: "option"`). For equal form, the comparison follows the contained values. If one of two unequal texts exceeds 64 code points, `aspect: "codepoint"` yields the first differing code point with `offset` from zero. `null` denotes the text end here. A deviation can also occur at the root. Its path is the empty string.

For simple scalars at the root, `--diff` yields the usual fields `expected` and `actual`. A rule example names the first deviating event from one. For expected or unexpected runtime errors, the usual diagnosis format applies. The option can be combined with both explanatory approaches. `test` without `--diff` yields both complete output values. [Executable multi-file example](experimente/46_ergebnisvergleich/ledger/panel.tide)

`test --explain` appends the first deviation of an executed example to stderr with `repair`. This JSON entry contains `revision`, `entry`, `target`, the typed `inputs` or `events`, and `definitions`. Definitions follow static calls from the example target, including both branches of a condition and the rules of a `scan`. Each reachable definition appears once. Functions contain `signature`, the fully grouped `body`, and the node identifier `node` for the entire function body. Rules contain `file`, `line`, and the original text in `source`. Upon successful suite, the output is `{"passed":N}`. Errors during loading or type checking provide the regular diagnosis.

If a selected definition uses a record, `repair.records` lists its field names and types. This applies to both declaration modes. Example checking and the contract fingerprint also consider option values within a record field.

`test --explain=executed` re-executes the first deviating example for observation. With the same result or identical error diagnosis, `repair.execution.complete` reports the value `true`. Then, under `definitions`, the actually traversed definitions appear in the order of their first entry. `execution.branches` assigns observed decisions from `if`, `case`, `match`, `and`, `or`, `need`, or `catch` to a node identifier. For rules, the chosen branch number starting from one appears under the rule name. Each decision appears once per position. If more than 64 different combinations of position and decision exist, `branches_truncated: true` reports the truncation of the branch list. Traversal of reached definitions continues.

If the observation run reaches its step limit or deviates in result, TIDE provides the statically reachable definitions and `complete: false` with `reason` equal to `step_limit` or `replay_mismatch`. In the second case, TIDE also discards the observed branches. If the serialized input field including field names exceeds 1,024 Unicode code points, the finding under `input_example` names the example. `tide context FILE --function TARGET --example NAME` provides the input. The revision of both answers must match.

All CLI results except interactive terminal view, formatted source code, help, and version display are output as JSON. On a program error, stdout remains empty. The diagnosis on stderr contains a stable code and, for a source finding, the position from 1. `may_fail` is a conservative set of catchable errors; the analysis considers handlers and transitively called functions.

`tide lock` outputs the language version, tool version, and SHA-256 of the operation catalog. With `tide lock > tide.lock`, pin them in the project. The next lock file in the directory of the entry file or an ancestor applies to the call. `describe --project FILE` uses the same binding.

Since 0.6, `map` is reserved. For migrating from 0.5, first rename your own definitions or bindings of this name. A project with the old pin receives `E_VERSION`. You can first test the new pin and project examples in a copy. With `tide lock --json > tide.lock.new && mv -- tide.lock.new tide.lock`, you adopt it in the desired project.

`context` provides revision-bound node identifiers. At the entry, they have the form `Zeile:Spalte`; in modules, `Datei:Zeile:Spalte`. A selection shows compact and fully parenthesized forms. `hole` creates a virtual change draft at a selected node. `__hole__` is rejected as an unresolved name until a valid expression is used.

Before changing a package pin, run `tide context FILE --function PACKAGE.FUNCTION --call-sites` against the working version. The response contains the project revision and one `call_sites` entry for each direct call in the checked project. Each entry gives the caller definition, source file and one-based line and column of the call. A module filename is relative to the project entry directory. Calls to other packages with the same function name are resolved independently. Query each application entry you ship. Use `--example-index` in a separate query to see transitive callers and affected examples.

Normally, `context` contains all examples whose target directly or indirectly uses the selected definition. With `--example-index`, each example entry contains only `name`, `target`, and `contract_sha256`. With `--example NAME`, the answer contains the full entry for this name. A missing or irrelevant name for the definition yields `E_EXAMPLE`. The options are mutually exclusive and can each be combined with `--node ID`. The additional field `examples_view` reads `index` at the index and `selected` at the single selection. For the same project revision, fingerprints match across all views.

An example contract can use `requires` to define the input range of its target for repair search. Allowed are one to eight integer parameters, and per parameter, an object with conditions `gt`, `ge`, `lt`, `le`, or `eq`. On the right stands an i64 constant or the name of an integer parameter as a JSON string. Thus, `"a":{"le":"b"}` expresses the condition `a <= b`. All conditions apply simultaneously. Missing boundaries correspond to the respective i64 limit. Per target, there is at most one such declaration. Unknown parameters and contradictory conditions yield `E_INPUT`. The function call and execution of existing examples retain their input rules. `--pairs` uses the declared range in counterexample search. [Call and Example](workbench/README.md#generate-inputs-for-green-pairs)

The editor checks changes against one project revision. For natively supported projects, `--source PATH` checks a complete new version of the entry file. Its imports are resolved alongside the original entry file. Changed and deleted example contracts require `--change-examples`. Upon passing the check, the preview provides base and candidate revision, target, number of passed examples, contract changes, and candidate text. `--write` takes over the checked bytes and yields `written: true`.

`--edits` accepts a JSON array of 1 to 256 changes based on the same revision. Each entry has a `node` and either `op` or `replace`. The former replaces the operation, the latter the entire expression with a one-line expression in the same scope. Node locations refer to the original source. Overlapping changes within a file yield `E_EDIT`. Cross-file node edits must preserve imports. TIDE checks the combined project and its examples.

For multiple targets the preview returns a `files` array with each relative filename and its complete source. Add `--write` to commit the same bytes. The editor holds the project directory lock, stages changed files, and rereads the reachable sources before installing them. A stale base yields `E_REVISION`. Project snapshots taken by `check`, `context`, `test`, `run` and `build --aot` wait for the writer. A vendored package opened directly shares its enclosing project lock.

Multi-file writes use a private recovery journal in `.tide-edit-transaction-v1`. A process exit before the commit marker is removed leaves the old revision recoverable. After that point the new revision is recoverable. The next TIDE project command completes recovery before reading sources. Run `tide check FILE` to identify the current revision after an interrupted command or a final synchronization error. The writer and recovery need directory write access on a Linux filesystem supporting directory locks, hard links, directory sync and `RENAME_EXCHANGE` across all targets. Recovery uses the journal owner’s account. External programs opening individual paths without the lock can observe intermediate contents or interfere with a transaction.

`fmt` writes a checked, normalized version of the entry file to stdout.

### Run a single example

`tide test FILE --example NAME` checks the project and runs the named example against its declared expectation. A passing value produces `{"passed":1,"actual":VALUE}`. An expected error produces `{"passed":1,"error":DIAGNOSTIC}` with the original source location and structured details. An unknown name or a failed expectation produces an `E_EXAMPLE` diagnostic on stderr and exit status 1.

For a PostgreSQL parameter, use the literal `":host:"` in the example and supply the connection explicitly with `--pg NAME=DSN`. Every declared PostgreSQL parameter needs its own binding. Other grants use the ordinary example fixtures. For example, a read grant contains the input text and an HTTPS grant maps paths to response pairs.

### Incremental test sessions

Start a local session with `tide test FILE --incremental`. Send `test` on stdin after each save and read one JSON object from stdout. The first request runs the entire suite. Later requests may reuse the last successful check. Send `full` for a clean check in the same process. Closing stdin ends the session.

A successful reply includes `passed` (all passing examples), `checked_functions` (function and rule bodies checked on this request), and `executed_examples` (examples actually executed). Each failed request returns the ordinary test diagnostic as one JSON object. The session remains available for the next save. An unrecognized request exits with status 2.

The session reads the current tool pin and the reachable source files on each request. It checks declarations, contracts and the global call graph each time. Changed modules invalidate their bodies. A changed function interface also invalidates previously checked callers, and examples run again when their file or any reachable function changes. A change to the ordered function names or the record and variant layouts triggers a full check. Cached results live in this process and are discarded at exit.

## Interactive Terminal Programs

`tide play FILE` connects a TIDE program with an interactive POSIX terminal. The host starts with `main > T`; `size > &ii` provides width and height in character cells. With a suitable window size, it calls `tick world:T keys:{Keys} > T` twelve times per second and then `draw world:T > *{Glyph}`. Each call receives a fresh work budget. The four functions and their calls must be free of side effects.

`Keys` contains the five boolean fields `left`, `right`, `fire`, `start`, and `pause`. They indicate key presses since the last tick. `Glyph` has the fields `x:i y:i text:t ink:t`. The host records printable ASCII in list order starting from the top-left corner (0.0). Color names are `dim`, `cyan`, `green`, `pink`, `gold`, and `white`. Display, game rules, and state transitions can be read in the [playable example](apps/space_invaders.tide).

### Events and an open file

`tide play PROGRAM --document PATH` opens an interactive text document. The host reads UTF-8 from the named regular file or starts with a new path and empty text. The upper limit is 128 KiB. The filename for display is the last path component.

| Pure TIDE function | Call by the host |
|---|---|
| `main body:t > T` | Provides the initial state from the file content. |
| `step world:T key:{Input} value:t > &T{Effect}` | Processes a single event and provides the resulting state and desired effect. |
| `view world:T name:t > {View}` | Provides the fields `body:t caret:i title:t status:t help:t`. The cursor is a codepoint offset from zero up to and including the text length. |

`Input` contains `character`, `control`, `left`, `right`, `up`, `down`, `home_key`, `end_key`, `backspace`, `delete_key`, `enter_key`, `escape`, `stored`, and `io_error`. At `character`, `value` contains the character, at `control` the lowercase key of the key combination, and at `io_error` the error message. The host provides Tab as a character and keeps the cursor within the visible area during drawing.

`Effect` encompasses `idle`, `store`, and `finish`. At `store`, the host writes the text from `View.body` to the path selected at startup. Subsequently, the program receives `stored` or `io_error` and can continue working in the buffer or end the session. The host checks the file version before the atomic exchange. It does not overwrite a newly designated path that is already in use. The implementation of text editing and follow-up questions is in the [Nano Example](apps/nano.tide).
