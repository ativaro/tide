#!/usr/bin/env bash
# Capture a terminal campaign after the observer releases its lock.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(realpath "${1:?run required}")
out=${2:?output directory required}
mkdir -p "$out"
out=$(realpath "$out")
cd "$root"
exec 7<campaign.lock
flock -s 7
state=$(jq -r .state status.json)
case $state in complete|failed) ;; *) exit 1 ;; esac
"$here/report.sh" "$root" "$out"
cp "$here/runbook.md" "$out/runbook.md"
files=(run.json status.json releases/SHA256SUMS source.sha256 checks.json samples.csv requests.csv events.jsonl)
for f in deployments.jsonl retiring.jsonl service.log ready.headers ready.body regression.status database-regression.status schema-failure.json setup-notes.md operator-rehearsal.jsonl cutoff-audit.json requested-stop.utc; do
    if [[ -f $f ]]; then files+=("$f"); fi
done
tar -czf "$out/evidence.next" "${files[@]}"
mv -fT "$out/evidence.next" "$out/evidence.tar.gz"
jq -e '.verified_24_hours or .state=="stopped_at_user_request"' "$out/summary.json" >/dev/null
