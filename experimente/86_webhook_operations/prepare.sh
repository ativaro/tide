#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
cd "$repo"
out=${1:?supply a new run directory}
mkdir -m700 "$out"
out=$(realpath "$out")
mkdir "$out"/{previous-src,releases}
baseline=8a268bd3adf763ca16d12483dd108f05446bacbd
git archive "$baseline" Makefile tide tide.lock apps native | tar -xf - -C "$out/previous-src"
"$out/previous-src/tide" build --service "$out/previous-src/apps/orders/webhook.tide" "$out/releases/previous" main
./tide build --service apps/orders/webhook.tide "$out/releases/candidate" main
(cd "$out/releases" && sha256sum previous candidate > SHA256SUMS)
./tide run apps/orders/webhook_load_checks.tide --call orders --inputs '{"ids":["fixture-id"]}' | jq -er '.[0]' > "$out/order.json"
./tide test apps/orders/webhook_checks.tide > "$out/checks.json"
sha256sum apps/orders/webhook.tide native/bootstrap/aot.tide > "$out/source.sha256"
