# Stage 18 · Independent application pilots

**The independent team pilots were skipped on 19 November 2026.** Neither of the two planned teams took part. The evidence below covers the maintainer’s local upgrade and patch handoff. Team experience and willingness to choose TIDE again remain unmeasured. [Team instructions and record](pilot.md) · [Contribution and decision process](../../CONTRIBUTING.md)

## Local rehearsal

On 19 November 2026, the maintainer installed TIDE 0.6.11 and 0.6.12 from their source revisions into separate empty prefixes on the same Linux x86-64 workstation. The builds and rehearsal ran in a network namespace with no external route. The application fixture was the existing balance example. Its second version added a function that reports when the closing balance falls below a threshold. No models were invoked.

| Check | Observed result |
|---|---|
| First application version on TIDE 0.6.11 | All 3 examples passed. The example account closed at 97. |
| Functional extension on TIDE 0.6.11 | All 5 examples passed. A balance of 89 triggered a floor of 90. A balance of 90 did not. |
| Offline contribution | A patch containing the extension applied to a fresh local clone of the first application revision. The resulting Git tree matched the author's tree. |
| First test on TIDE 0.6.12 with the original pin | The tool rejected the application with `E_VERSION`. |
| After adopting the 0.6.12 lock | All 5 examples passed. The original result was 97 and both floor decisions matched the previous tool. |
| After restoring the 0.6.11 lock and tool | All 5 examples passed again. The receiving checkout was clean. |

The rehearsal checks the instructions and offline patch handoff. Only independent teams can supply the project and adoption results for Stage 18. [Recorded results and exact revisions](rehearsal/results.json)

## Reproduce the local check

From the TIDE repository root, build each pinned tool into its own prefix. This checkout contains both revisions.

```sh
repo=$PWD
lab=$(mktemp -d)
old=c1bfb115ffb8259f04e121d53cb8c2c4c5110fdb
new=096db5100b7e9cc1bff872124ca80f039a1e2790
for rev in "$old" "$new"; do
  mkdir "$lab/$rev"
  git archive "$rev" Makefile tide native | tar -xC "$lab/$rev"
  make -C "$lab/$rev" -j4 install-native PREFIX="$lab/$rev/prefix"
done
old_tide=$lab/$old/prefix/bin/tide
new_tide=$lab/$new/prefix/bin/tide
```

Use a fresh application directory. This fixture has a plain tool lock. Projects with a package manifest also pin its digest using `tide lock --packages tide.packages`.

```sh
mkdir "$lab/app"
git show "$old:apps/balance.tide" > "$lab/app/balance.tide"
cd "$lab/app"
"$old_tide" lock > tide.lock
cp tide.lock "$lab/original.lock"
"$old_tide" test balance.tide
"$old_tide" run balance.tide
cp "$repo/experimente/87_independent_pilots/rehearsal/floor.tide" .
"$old_tide" test floor.tide
"$new_tide" test floor.tide
```

The last command should fail with `E_VERSION`. Adopt the new lock in this copy, test the extension, then verify that restoring the original pin still works.

```sh
"$new_tide" lock > tide.lock.new && mv tide.lock.new tide.lock
"$new_tide" test floor.tide
"$new_tide" run floor.tide --call below_floor --inputs '{"opening":100,"entries":[-10],"floor":90}'
cp "$lab/original.lock" tide.lock
"$old_tide" test floor.tide
```
