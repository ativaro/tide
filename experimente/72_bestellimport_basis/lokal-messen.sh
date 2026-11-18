#!/bin/sh
# Run from the repository root on Linux with a locally installed TIDE CLI.
set -eu
d=experimente/72_bestellimport_basis
(cd "$d" && sha256sum -c vertrag.sha256 >/dev/null && sha256sum -c werkzeuge.sha256 >/dev/null)
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
prefix=$(dirname "$(dirname "${TIDE_BIN:?Set TIDE_BIN to PREFIX/bin/tide}")")
bwrap --unshare-all --die-with-parent --new-session --tmpfs / --ro-bind /usr /usr \
  --symlink usr/bin /bin --symlink usr/lib /lib --symlink usr/lib /lib64 --proc /proc --dev /dev --tmpfs /tmp \
  --ro-bind "$PWD/experimente" /study/experimente --ro-bind "$prefix" /opt/tide --bind "$out" /results \
  --ro-bind "$(command -v node)" /opt/node \
  --clearenv --setenv PATH /usr/bin --setenv LC_ALL C.UTF-8 --setenv TIDE_BIN /opt/tide/bin/tide \
  --setenv RESULT_DIR /results --chdir /study taskset -c "${TIDE_CPU:-24}" /opt/node "/study/$d/messen.mjs"
cp "$out/messung.json" "$out/protokolle.json" "$d/"
