# Getting started with TIDE

This guide takes you from a first function to a typed JSON importer and a call across two modules. Start in the root of a TIDE checkout on Linux x86-64 or Linux ARM64. Building from source requires GNU Make, C and C++20 compilers with static runtime libraries, XZ, GNU coreutils and the libcurl, libpq and libmicrohttpd development headers. Use the same shell throughout so the installed CLI stays on your path.

## Install and run one example

Install into an empty directory owned by your user. Keep the checkout for the examples.

```sh
repo=$PWD
prefix=$(mktemp -d)
make -j4 install-native PREFIX="$prefix"
export PATH="$prefix/bin:$PATH"
command -v tide
tide --version
tide test apps/balance.tide
tide run apps/balance.tide --call balance --inputs '{"opening":100,"entries":[-20,15,-8,10]}'
```

The executable should be under your new prefix. For this checkout the version is `TIDE 0.6.12`, all three examples pass, and the balance is `97`. In a later shell, add the same prefix's `bin` directory to your path.

## Write a function and its examples

Suppose a warehouse needs to know how many units of an order it cannot fill. In an empty directory, save the following as `shortfall.tide`.

```tide
shortfall stock:i requested:i > i
if (> requested stock) (- requested stock) 0

example partial_order shortfall
{"inputs":{"stock":7,"requested":10},"expect":3}

example exact_stock shortfall
{"inputs":{"stock":10,"requested":10},"expect":0}
```

The first line names two signed integers and declares an integer result after `>`. The next line is the whole function body. In `(> requested stock)`, the same symbol is a comparison in operator position. `if` evaluates the condition and picks one branch. When the order exceeds stock, the subtraction gives the missing quantity. Otherwise the result is zero.

From the directory containing your file, call the function with your own inputs and then check both examples.

```sh
tide run shortfall.tide --call shortfall --inputs '{"stock":4,"requested":9}'
# 5
tide test shortfall.tide
# {"passed":2}
```

To see a diagnostic, reverse the operands of the subtraction and run `tide test shortfall.tide --diff`. The partial order now produces `-3` where the example expects `3`. Restore the subtraction and run the examples again.

## Change a JSON record

In the measurement app, the project owns the record layout and the pinned library decodes it. To see that boundary, run this from the checkout.

```sh
cd "$repo/apps/report_packages"
tide modules json_report.tide
tide context json_report.tide --function jsoninput.decode --call-sites
tide test json_report.tide --example optional_and_unknown
```

Open `json_readings.tide`. Its `use jsoninput@2.0.0[Document]` binds the library to this application's `Document`. Each row has type `Reading`. Its `note:?t` field accepts text and may be absent. For a change to a row, edit that record in your working copy. The vendored decoder stays at its verified pin. [Library reference](LANGUAGE.md#libraries-used-by-the-importers)

The same value has two forms. A supplier sends the JSON field `"note":"ok"` and may omit it or send `null`. A TIDE example that expects the *decoded record* writes `"note":{"some":"ok"}` or `"note":{"none":true}`. An expected record lists every declared field. When you extend that record, update existing expectations that return it. A report that returns only a summary keeps its own result shape.

Run the examples again after the edit. For `E_EXAMPLE` with `Invalid expected value`, follow `issue.path` into the example. For a decoder error, the path names the offending field in the incoming document. Array indexes in both paths start at zero.

## Navigate a multi-file failure

Run these commands from the directory containing the test entry. Then every reported path opens directly from your editor's working directory.

```sh
cd "$repo/apps"
tide modules summary_checks.tide
tide context summary_checks.tide --function higher --call-sites
tide test summary_checks.tide --example threshold
```

For `higher`, `declaration` points to the signature in `readings.tide` and `call_sites` points to the call inside `summarize` in `summary.tide`. Both locations are one-based. Open the reported file in your editor and jump to its line and column. For instance, `vim +4 readings.tide` opens this declaration at line four. Repeat the query after moving code.

For a failing project, `tide test FILE --diff --explain=executed` shows what the failing example actually called. Use `tide context FILE --function NAME --example-index` to find examples affected by a change. Run each suspected path with `tide test FILE --example NAME`, then run `tide test FILE` across the whole entry. [Editor and repair commands](workbench/README.md)
