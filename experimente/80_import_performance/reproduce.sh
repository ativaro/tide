#!/usr/bin/env bash
# Run from any directory. The output directory receives the receipts for this run.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
study=$root/experimente/80_import_performance
previous=$root/experimente/73_bestellimport
mkdir -p build
results=${1:-"$root/build/stage11-results"}
mkdir -p "$results"
results=$(realpath "$results")
work=$(mktemp -d "$root/build/stage11.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
cpu=${TIDE_CPU:-24}
jobs=${JOBS:-4}
mkdir -p "$work"/{base,pre,post,apps}
git archive ba43358 -- Makefile tide tide.lock native apps lib workbench | tar -x -C "$work/base"
diff -r "$work/base/apps/orders" apps/orders
cp -r apps/orders "$work/apps/"
cp "$study"/{service,phases}.tide "$work/apps/orders/"
cp "$study/warm_reference.py" "$work/"
# Expose the same byte decoder to the HTTP baseline. The CLI reference stays byte-for-byte frozen.
test "$(grep -c '^    if len(data) > 4194304:' "$previous/cpython_import.py")" = 1
sed '/^    if len(data) > 4194304:/i\    return decode_document(data)\n\n\ndef decode_document(data):' "$previous/cpython_import.py" > "$work/reference.py"
make -sj"$jobs" -C "$work/base" install-native DESTDIR="$work/before"
make -sj"$jobs" install-native DESTDIR="$work/after"
before=$work/before/usr/local/bin/tide
after=$work/after/usr/local/bin/tide
export work
for arm in pre post; do
    if [[ $arm == pre ]]; then tool=$before; else tool=$after; fi
    export tool arm
    (cd "$work" && printf '%s\n' startup read_size utf8_size decode_size checked_quantity | xargs -n1 -P "$jobs" bash -ec '"$tool" build --aot apps/orders/phases.tide "$work/$arm/$1" "$1"' _)
    (cd "$work" && "$tool" build --service apps/orders/service.tide "$work/$arm/service" serve)
done
# Build each measured CLI artifact serially on the benchmark core, outside the import timings.
cd "$work"
for arm in pre post python; do
    case $arm in
        pre) cmd=("$before" build --aot apps/orders/import.tide "$work/pre/main");;
        post) cmd=("$after" build --aot apps/orders/import.tide "$work/post/main");;
        python) cmd=(python3 -c 'import py_compile,sys; py_compile.compile(sys.argv[1],cfile=sys.argv[2],doraise=True)' "$previous/cpython_import.py" "$work/reference.pyc");;
    esac
    taskset -c "$cpu" /usr/bin/zsh -fc 'zmodload zsh/datetime; t=$EPOCHREALTIME; "$@" >&2 || exit 1; printf "%.6f\n" $((EPOCHREALTIME-t))' -- "${cmd[@]}" >"$work/$arm.seconds"
    printf '%s\t%s\n' "$arm" "$(cat "$work/$arm.seconds")" >> "$work/build-seconds.tsv"
done
cd "$root"
for phase in pre post compare source warm; do
    bwrap --unshare-net --die-with-parent --bind / / --dev-bind /dev /dev --proc /proc -- \
      env LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1 taskset -c "$cpu" node "$study/measure.mjs" "$phase" "$work"
done
# Exercise fallback paths with the same project name and compare full error objects in both builds.
file=experimente/80_import_performance/scalar_records.tide
for arm in pre post; do
    if [[ $arm == pre ]]; then tool=$before; else tool=$after; fi
    "$tool" test "$file"
    "$tool" build --aot "$file" "$work/$arm/scalars"
    while read -r name; do
        "$tool" test "$file" --example "$name" | jq -c --arg n "$name" '{example:$n,result:del(.passed)}' >>"$work/$arm.edges"
        args=$(awk -v n="$name" '$1=="example" && $2==n {getline; print}' "$file" | jq -c .inputs)
        rc=0; "$work/$arm/scalars" --inputs "$args" >"$work/value" 2>"$work/error" || rc=$?
        if [[ $rc == 0 ]]; then test ! -s "$work/error"; observed=$(jq -cS '{actual:.}' "$work/value")
        else test "$rc" = 1; test ! -s "$work/value"; observed=$(jq -cS '{error:.}' "$work/error"); fi
        test "$observed" = "$(tail -1 "$work/$arm.edges" | jq -cS .result)"
    done < <(awk '$1=="example" {print $2}' "$file")
done
cmp "$work/pre.edges" "$work/post.edges"
# Run the original restart and rollback contract with the same four application arms.
mkdir -p "$work/accept/bin" "$work/accept/results"
cp -r apps/orders "$work/accept/v1"
cp "$previous/v1.tide" "$work/accept/v1/"
cp "$work/pre/main" "$work/accept/bin/initial"
cp "$work/post/main" "$work/accept/bin/final"
"$after" build --aot apps/orders/import.tide "$work/accept/bin/position" position
bwrap --unshare-all --die-with-parent --tmpfs / --ro-bind /usr /usr --symlink usr/bin /bin \
    --symlink usr/lib /lib --symlink usr/lib /lib64 --dev /dev --proc /proc --tmpfs /tmp \
    --ro-bind "$work/after/usr/local" /opt/tide --ro-bind "$root/apps/orders" /orders \
    --ro-bind "$work/accept/v1" /v1 --ro-bind "$work/accept/bin" /bins --bind "$work/accept/results" /results \
    --ro-bind "$previous" /study --ro-bind "$(command -v node)" /opt/node --setenv PATH /usr/bin \
    --chdir /results -- /opt/node /study/acceptance.mjs acceptance /bins /results
cp "$work/accept/results/acceptance.json" "$results/"
cp "$work/post.edges" "$results/edges.jsonl"
cp "$work"/{pre.json,post.json,compare.json,source.json,warm.json,build-seconds.tsv} "$results/"
