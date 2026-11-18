#!/usr/bin/env bash
# Assemble a single reachable project from existing, public application suites.
set -eu
root=$(cd "$(dirname "$0")/../.." && pwd)
out=$1
mkdir -p "$out/vendor"
cp -a "$root/apps/orders/." "$out/"
cp -a "$root/apps/report_packages/vendor/measurements" "$out/vendor/"
cp "$root/apps/"{cursor,invaders_game}.tide "$out/"
sed -e 's/^main /stream_summary /' -e 's/^example empty main$/example stream_empty main/' \
    -e 's/^\(example .*\) main$/\1 stream_summary/' \
    "$root/apps/report_packages/stream_report.tide" > "$out/stream_report.tide"
printf 'use checks\n\nuse stream_report\n\nuse cursor\n\nuse invaders_game\n' > "$out/suite.tide"
