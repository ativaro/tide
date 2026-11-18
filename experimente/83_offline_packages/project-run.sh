#!/usr/bin/env bash
# Runs inside a fresh filesystem and network namespace in the application directory.
set -euo pipefail
app=$1 phase=$2
store=${3:-/dist}
case $app in
    orders) entry=import.tide; suite=checks.tide; expected_tests=13 ;;
    report) entry=json_report.tide; suite=json_report.tide; expected_tests=9 ;;
    *) exit 2 ;;
esac
test ! -s /proc/net/route || test "$(wc -l </proc/net/route)" -eq 1
if [[ -d $store ]]; then install_result=$(tide pkg install . "$store"); else install_result=null; fi
suite_result=$(tide test "$suite")
jq -e --argjson n "$expected_tests" '.passed==$n' <<<"$suite_result" >/dev/null
tide modules "$entry" >modules.json
tide build --aot "$entry" app >&2
if [[ $app == orders ]]; then
    db=${TMPDIR:-/tmp}/orders
    printf '%s\n' '{"supplier":"ACME","events":[{"id":"E1","kind":"order","order":"O7","line":"1","sku":"Pièce猫","qty":3,"unit_cents":125}]}' >input.json
    receipt=$(./app --read input=input.json --db "db=$db")
    repeat=$(./app --read input=input.json --db "db=$db")
    [[ $(jq -c '[.applied,.duplicates]' <<<"$receipt") == '[1,0]' && $(jq -c '[.applied,.duplicates]' <<<"$repeat") == '[0,1]' ]]
    [[ $(sqlite3 "$db" 'SELECT (SELECT count(*) FROM events),count(*),outstanding,outstanding*cents FROM positions;') == '1|1|3|375' ]]
    outcome=$(jq -cn --argjson first "$receipt" --argjson repeat "$repeat" '{first:$first,repeat:$repeat,ledger_rows:1,quantity:3,cents:375}')
else
    printf '%s\n' '{"limits":{"A":79},"readings":[{"sensor":"A","value":80},{"sensor":"B","value":80},{"sensor":"C","value":98}]}' >input.json
    outcome=$(./app --read input=input.json --inputs '{"limit":80}')
    jq -e '.=={"above":2,"peak":{"some":98}}' <<<"$outcome" >/dev/null
fi
digest() { sha256sum "$1" | cut -d' ' -f1; }
json_path=$(awk '$2 ~ /^vendor\/jsoninput\// {print $2}' tide.packages)
jq -cn --arg phase "$phase" --arg project "$app" --arg path "$PWD" --arg json "$json_path" \
  --arg package "$(digest "$json_path")" --arg manifest "$(digest tide.packages)" --arg tool_pin "$(digest tide.lock)" \
  --arg binary "$(digest app)" --arg rev "$(jq -r .revision modules.json)" --argjson tests "$suite_result" \
  --argjson installation "$install_result" --argjson outcome "$outcome" \
  '{phase:$phase,project:$project,directory:$path,pin:$json,package_sha256:$package,manifest_sha256:$manifest,tool_lock_sha256:$tool_pin,revision:$rev,elf_sha256:$binary,tests:$tests.passed,installation:$installation,result:$outcome}'
