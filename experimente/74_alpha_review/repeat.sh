#!/bin/sh
# One offline campaign per invocation. Use the same on-disk results directory for all three.
set -eu
phase=${1:?expected orders, tasks, sizes or current-tasks}
out=${2:?expected a results directory}
case "$phase" in
    orders|sizes|current-tasks) revision=33f0972a2e001f3158630446f2e579ab355e0da1 ;;
    tasks) revision=96c0a936b215ca21d3a58222b42ac96872f4d8b8
        ;;
    *) echo "unknown campaign: $phase" >&2; exit 2 ;;
esac
case "$phase" in
    tasks|current-tasks) : "${TOKENIZER_JSON:?set the path to the frozen vocabulary}" "${TOKENIZER_PYTHON:?set the interpreter with tokenizers}" ;;
esac
review=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$review/../.." && pwd)
mkdir -p "$out"
out=$(cd "$out" && pwd)
temp=$(mktemp -d "$out/.stage5.XXXXXXXX")
trap 'rm -r -- "$temp"' EXIT
git clone -q --no-local --no-checkout "$repo" "$temp/checkout"
cd "$temp/checkout"
git checkout -q --detach "$revision"
test "$(git rev-parse HEAD)" = "$revision"
test -z "$(git status --porcelain)"
test ! -e build
cpu=${TIDE_CPU:-24}
export TIDE_CPU="$cpu"
orders=experimente/73_bestellimport
tasks=experimente/72_bestellimport_basis

isolated() {
    bwrap --unshare-all --die-with-parent --new-session --tmpfs / --ro-bind /usr /usr \
        --symlink usr/bin /bin --symlink usr/lib /lib --symlink usr/lib /lib64 \
        --proc /proc --dev /dev --tmpfs /tmp --ro-bind "$(command -v node)" /opt/node \
        --clearenv --setenv PATH /usr/bin --setenv LC_ALL C.UTF-8 "$@"
}
case "$phase" in
    orders)
        sh "$orders/reproduce.sh"
        mkdir -p "$out/orders"
        for file in profile isolate compare source acceptance; do cp "$orders/$file.json" "$out/orders/"; done
        make -s -j2 test
        ;;
    tasks|current-tasks)
        make -s -j2 install DESTDIR="$temp/install"
        prefix=$temp/install/usr/local
        TIDE_BIN="$prefix/bin/tide" sh "$tasks/lokal-messen.sh"
        mkdir "$temp/control"
        isolated --ro-bind "$PWD/$tasks" /study --ro-bind "$prefix" /opt/tide --bind "$temp/control" /result \
            --setenv TIDE_BIN /opt/tide/bin/tide --setenv RESULT_DIR /result \
            taskset -c "$cpu" /opt/node /study/kontrolle.mjs
        node "$tasks/auswerten.mjs"
        mkdir -p "$out/$phase"
        cp "$tasks/messung.json" "$out/$phase/observations.json"
        cp "$tasks/auswertung.json" "$out/$phase/evaluation.json"
        cp "$temp/control/kontrollmessung.json" "$out/$phase/writing-control.json"
        cp "$tasks/protokolle.json" "$out/$phase/protocols.json"
        ;;
    sizes)
        mkdir "$temp/study" "$temp/bin" "$temp/data"
        cp "$orders/measure.mjs" "$orders/cpython_import.py" "$temp/study/"
        patch -s -p1 -d "$temp/study" < "$review/size-sweep.patch"
        make -s -j2 install DESTDIR="$temp/install"
        "$temp/install/usr/local/bin/tide" build --aot apps/orders/import.tide "$temp/bin/final"
        isolated --ro-bind "$temp/study" /study --ro-bind "$temp/bin" /bins --bind "$temp/data" /results \
            --chdir /results taskset -c "$cpu" /opt/node /study/measure.mjs compare /bins /results
        cp "$temp/data/compare.json" "$out/sizes.json"
        ;;
esac
