# First-use session

You have a fresh local checkout and the [getting started guide](../../GETTING_STARTED.md). Work in the same shell throughout. You can use the project documentation, CLI help and your usual editor. Ask the observer when you need help. You can stop at any point.

## 1. Install TIDE

From the checkout root, follow the guide to install TIDE into a fresh prefix. Show the installed executable's path and version, the result of the balance examples and the balance for an opening of 100 and entries of −20, 15, −8 and 10.

## 2. Extend the measurement importer

Prepare your own copy of the project. The store under `packages` is available offline.

```sh
cd "$repo"
session=$(mktemp -d)
mkdir "$session/field"
cd apps/report_packages
cp json_readings.tide json_report.tide tide.lock tide.packages "$session/field/"
cd "$repo"
cp experimente/84_onboarding/field_checks.tide "$session/field/"
tide pkg install "$session/field" "$repo/packages"
cd "$session/field"
tide test json_report.tide
tide test field_checks.tide
```

The existing application passes nine examples. The new contract starts red. Add an optional text field named `unit` to each decoded reading. Preserve a supplied unit, accept missing and null units, and report a non-text unit at its exact input path. The summary output and all earlier behavior must still pass. You may extend the existing decoded-record expectations to account for the new field. Keep the three new examples and the library pin intact.

Finish by running both test entries. Show the observer the results.

## 3. Repair the single and batch readers

```sh
cp -R "$repo/experimente/84_onboarding/repair" "$session/repair"
cd "$session/repair"
tide test checks.tide --diff --explain=executed
```

A sample is accepted when it falls between the lower and upper bounds, including both endpoints. The batch reader counts accepted samples, including repeats. A library migration broke both readers. Its current public contract and the eight examples are fixed.

Locate the shared declaration and both calls with the installed CLI. Repair the application and show the observer the source locations and the result of `tide test checks.tide`.
