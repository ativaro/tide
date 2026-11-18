#!/usr/bin/env bash
# Run inside the target's offline build environment, after install-native and make test.
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
prefix=$(realpath "${1:?supply the installation prefix}")
export PATH="$prefix/bin:$PATH" LC_ALL=C
arch=$(uname -m)
case "$arch" in
    aarch64) machine=AArch64 ;;
    x86_64) machine='Advanced Micro Devices X86-64' ;;
    *) exit 2 ;;
esac
[[ $(command -v tide) == "$prefix/bin/tide" && $(uname -s) == Linux ]]
[[ -z $(find /usr "$prefix" ! -type d \( -name python -o -name 'python[23]' -o -name 'python[23].[0-9]*' -o -name 'libpython*.so*' -o -name 'libpython*.a' -o -name Python.h -o -path '*/python[23].*/os.py' \) -print -quit) ]]
[[ $(wc -l </proc/net/route) -le 1 ]]
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
check_elf() {
    local path=$1
    [[ $(readelf -h "$path" | sed -n 's/^ *Machine: *//p') == "$machine" ]]
    readelf -ld "$path" >"$work/linkage"
    if grep -Eq 'INTERP|\(NEEDED\)' "$work/linkage"; then return 1; fi
}
for tool in "$prefix"/lib/tide/bin/*; do check_elf "$tool"; done
for seed in seed0 seed1 seed; do check_elf "$repo/build/native/$seed"; done
tide build "$repo/apps/balance.tide" "$work/balance" > "$work/build.stdout"
[[ ! -s "$work/build.stdout" ]]
check_elf "$work/balance"
[[ $("$work/balance") == 97 ]]
fixture="$repo/native/bootstrap/fixtures/functions/inclusive.tide"
tide build "$fixture" "$work/fold" bounded >&2
tide build "$fixture" "$work/scan" simulate >&2
check_elf "$work/fold"
check_elf "$work/scan"
if [[ $arch == aarch64 ]]; then
    total=$("$work/fold" --inputs '{"seed":7,"values":[-3,-2,-1,2,2,3]}')
    states=$("$work/scan" --inputs '{"events":[-3,-2,-1,2,3]}')
else
    total=$("$work/fold" 7 -3 -2 -1 2 2 3)
    states=$("$work/scan" -3 -2 -1 2 3)
fi
[[ $total == 8 && $states == '[false,true,true,true,false]' ]]
jq -cn --arg arch "$arch" --arg machine "$machine" --arg version "$(tide --version)" \
    --argjson total "$total" --argjson states "$states" \
    '{architecture:$arch,elf_machine:$machine,version:$version,plain_build_balance:97,fold:$total,scan:$states}'
for app in orders report; do
    case "$app" in
        orders) source=orders; entry=import.tide ;;
        report) source=report_packages; entry=json_report.tide ;;
    esac
    mkdir "$work/$app"
    cd "$work/$app"
    cp "$repo/apps/$source/"*.tide "$repo/apps/$source"/tide.{lock,packages} .
    result=$(TMPDIR=$PWD bash "$repo/experimente/83_offline_packages/project-run.sh" "$app" platform "$repo/packages")
    jq -e '.installation | .installed==.verified and .installed>0' <<<"$result" >/dev/null
    check_elf app
    if [[ $app == orders ]]; then
        observed=$(tide run "$entry" --read input=input.json --db db=interpreted.db)
        repeated=$(tide run "$entry" --read input=input.json --db db=interpreted.db)
        jq -e --argjson first "$observed" --argjson repeat "$repeated" \
            '.result.first==$first and .result.repeat==$repeat' <<<"$result" >/dev/null
    else
        observed=$(tide run "$entry" --read input=input.json --inputs '{"limit":80}')
        jq -e --argjson expected "$observed" '.result==$expected' <<<"$result" >/dev/null
    fi
    jq -c --arg arch "$arch" 'del(.directory,.phase) + {architecture:$arch}' <<<"$result"
done
