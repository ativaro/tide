#!/usr/bin/env bash
# Replay the Stage 6 consumers and the migration against one local TIDE toolchain.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
tide="$root/tide"
base=cb93e76a862da076de5858b458e1b2eabbf481a9
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/old"
git -C "$root" archive "$base" apps/orders apps/report_packages | tar -x -C "$work/old"
cp "$root/tide.lock" "$work/old/"
for project in orders report_packages; do
    package=apps/$project/vendor/jsoninput
    cmp "$work/old/$package/1.0.0/package.tide" "$root/$package/1.0.0/package.tide"
    cp -R "$root/$package/2.0.0" "$work/old/$package/"
done
cp -R "$work/old" "$work/pin-only"
sed -i 's/jsoninput@1\.0\.0\[/jsoninput@2.0.0[/' "$work/pin-only/apps/"{orders/import,report_packages/json_readings}.tide

# The expectations and input bytes below come from the applications' TIDE examples.
check_aot() {
    local suite=$1 entry=$2 good=$3 bad=$4 pin=$5 label args status
    local db_args=()
    "$tide" build --aot "$entry" "$work/app" >&2
    for label in "$good" "$bad"; do
        "$tide" context "$suite" --function main --example "$label" | jq '.examples[0]' >"$work/example"
        jq -jr .inputs.input "$work/example" >"$work/input"
        args=$(jq -c '.inputs | del(.input,.db)' "$work/example")
        if jq -e '.inputs | has("db")' "$work/example" >/dev/null; then db_args=(--db db=:memory:); fi
        status=0
        "$work/app" --inputs "$args" "${db_args[@]}" --read "input=$work/input" >"$work/out" 2>"$work/err" || status=$?
        if [[ $label == "$good" ]]; then
            test "$status" = 0
            test -s "$work/out"
            jq -e --slurpfile ex "$work/example" '. == $ex[0].expect' "$work/out" >/dev/null
            jq -c --arg pin "$pin" --arg entry "$entry" --arg example "$label" '{pin:$pin,entry:$entry,example:$example,aot_result:.}' "$work/out"
        else
            test "$status" = 1
            test ! -s "$work/out"
            test -s "$work/err"
            jq -e --slurpfile ex "$work/example" '{code,reason,path:.issue.path} == $ex[0].expect_error' "$work/err" >/dev/null
            jq -c --arg pin "$pin" --arg entry "$entry" --arg example "$label" '{pin:$pin,entry:$entry,example:$example,aot_error:{code,reason,path:.issue.path}}' "$work/err"
        fi
    done
}

while read -r suite entry good bad expected_tests; do
    cd "$work/old"
    "$tide" context "$suite" --function jsoninput.load --call-sites >"$work/sites"
    "$tide" context "$suite" --function jsoninput.load --example-index |
        jq -c --arg project "$suite" --slurpfile sites "$work/sites" '
            if .revision != $sites[0].revision then error("source revision changed") else
            {project:$project,old_revision:.revision,call_sites:$sites[0].call_sites,affected_callers,affected_examples:[.examples[].name]} end'
    cd "$work/pin-only"
    if [[ $good == - ]]; then
        jq -e '.call_sites == []' "$work/sites" >/dev/null
        "$tide" test "$suite" | jq -ce --arg project "$suite" --argjson n "$expected_tests" 'select(.passed==$n) | {project:$project,pin_only_tests:.passed}'
    else
        if "$tide" check "$suite" >"$work/out" 2>"$work/err"; then exit 1; else test "$?" = 1; fi
        test ! -s "$work/out"
        jq -e --slurpfile sites "$work/sites" '
            .code=="E_TYPE" and .operation=="jsoninput.load" and .argument==2 and
            .actual=="?i" and .expected=="{jsoninput.ReadBudget}" and
            ($sites[0].call_sites | length) == 1 and $sites[0].call_sites[0].caller=="main" and
            ([.file,.line] == ($sites[0].call_sites | map([.file,.line]) | first))' "$work/err" >/dev/null
        jq -c --arg project "$suite" '{project:$project,pin_only_error:.}' "$work/err"
    fi
    for pin in 1.0.0 2.0.0; do
        if [[ $pin == 1.0.0 ]]; then cd "$work/old"; else cd "$root"; fi
        "$tide" modules "$suite" | jq -e --arg pin "$pin" '[.imports[] | select(.package=="jsoninput") | .version] == [$pin]' >/dev/null
        "$tide" test "$suite" | jq -ce --arg pin "$pin" --arg suite "$suite" --argjson n "$expected_tests" 'select(.passed==$n) | {pin:$pin,suite:$suite,passed}'
        if [[ $good != - ]]; then check_aot "$suite" "$entry" "$good" "$bad" "$pin"; fi
    done
done <<'CASES'
apps/orders/checks.tide apps/orders/import.tide partial_and_full bad_qty 13
apps/report_packages/json_report.tide apps/report_packages/json_report.tide thresholds wrong_optional 9
apps/report_packages/sqlite_report.tide apps/report_packages/sqlite_report.tide persisted_values json_failure 4
apps/report_packages/api_report.tide apps/report_packages/api_report.tide - - 4
CASES
