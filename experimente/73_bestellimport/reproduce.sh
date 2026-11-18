#!/bin/sh
# Run from the checkout root on Linux. Both the fixtures and the databases are synthetic.
set -eu
study=$PWD/experimente/73_bestellimport
work=$(mktemp -d)
mkdir -p "$PWD/build"
results=$(mktemp -d "$PWD/build/order-study.XXXXXXXX")
trap 'rm -rf "$work" "$results"' EXIT
mkdir -p "$work/before" "$work/bin"
cp -a Makefile tide tide.lock native apps lib workbench "$work/before/"
(cd "$work/before" && patch -s -p1 < "$study/baseline.patch")
make -s -j2 -C "$work/before" install DESTDIR="$work/pre"
make -s -j2 install DESTDIR="$work/post"
before=$work/pre/usr/local/bin/tide
after=$work/post/usr/local/bin/tide
b=$work/bin
cp "$study/count.tide" "$study/read.tide" "$work/before/apps/orders/"
(cd "$work/before" && "$before" build --aot apps/orders/import.tide "$b/initial" && "$before" build --aot apps/orders/count.tide "$b/count_pre" && "$before" build --aot apps/orders/read.tide "$b/read_pre")
mkdir "$work/mixed"
cp "$study/v1.tide" "$work/mixed/"
cp apps/orders/*.tide "$work/mixed/"
"$before" build --aot "$work/mixed/import.tide" "$b/db_only"
"$after" build --aot apps/orders/import.tide "$b/final"
"$after" build --aot apps/orders/import.tide "$b/position" position
for phase in profile isolate compare source acceptance; do
    bwrap --unshare-all --die-with-parent --new-session --tmpfs / --ro-bind /usr /usr \
      --symlink usr/bin /bin --symlink usr/lib /lib --symlink usr/lib /lib64 --proc /proc --dev /dev --tmpfs /tmp \
      --ro-bind "$study" /study --ro-bind "$PWD/apps/orders" /orders --ro-bind "$work/post/usr/local" /opt/tide \
      --ro-bind "$work/before/apps/orders" /before-orders --ro-bind "$work/pre/usr/local" /opt/before --ro-bind "$work/mixed" /v1 --ro-bind "$b" /bins --bind "$results" /results --ro-bind "$(command -v node)" /opt/node \
      --clearenv --setenv PATH /usr/bin --setenv LC_ALL C.UTF-8 --chdir /results \
      taskset -c "${TIDE_CPU:-24}" /opt/node "/study/$(if [ "$phase" = acceptance ]; then echo acceptance; else echo measure; fi).mjs" "$phase" /bins /results
    cp "$results/$phase.json" "$study/$phase.json"
done
