#!/usr/bin/env bash
# Deploy one of the two immutable releases in a Stage 17 run directory.
set -euo pipefail
cd "${1:?run directory required}"
exec 9>deployment.lock
flock -x 9
action=${2:?use activate or recover}
case "$action" in activate) target=${3:?release required} ;; recover) target=$(basename "$(readlink confirmed)") ;; *) exit 2 ;; esac
case "$target" in previous|candidate) ;; *) exit 2 ;; esac
unit=$(cat web.unit)
url=$(cat url)
log() {
    jq -cn --arg time "$(date -u -Ins)" --arg event "$1" --arg release "$target" \
        --arg action "$action" --argjson pid "$$" '{time:$time,event:$event,release:$release,action:$action,updater_pid:$pid}' >> deployments.jsonl
}
publish() {
    local tmp
    tmp=$(mktemp -d .link-XXXXXXXX)
    ln -s "releases/$target" "$tmp/link"
    mv -Tf "$tmp/link" "$1"
    rmdir "$tmp"
    sync -f .
}
(cd releases && sha256sum --check --status SHA256SUMS)
outgoing=$(systemctl --user show -p MainPID --value "$unit")
if [[ $outgoing != 0 ]]; then
    read -r user system < <(awk '{print $14,$15}' "/proc/$outgoing/stat")
    jq -cn --arg time "$(date -u -Ins)" --argjson pid "$outgoing" --argjson ticks "$((user+system))" \
        '{time:$time,pid:$pid,cpu_ticks:$ticks}' >> retiring.jsonl
fi
publish active
log selected
systemctl --user restart "$unit"
healthy() {
    local pid code
    pid=$(systemctl --user show --property=MainPID --value "$unit")
    [[ $pid != 0 && $(readlink "/proc/$pid/exe") == "$PWD/releases/$target" ]] || return 1
    code=$(curl --noproxy '*' -s --max-time 2 -o deploy.reply -w '%{http_code}' "$url/ready") || return 1
    if [[ $target == candidate ]]; then
        [[ $code == 200 ]] && jq -e '.=={"ready":true}' deploy.reply >/dev/null || return 1
    else
        [[ $code == 404 ]] && jq -e '.error=="not_found"' deploy.reply >/dev/null || return 1
    fi
    code=$(curl --noproxy '*' -s --max-time 2 -H 'Content-Type: application/json' \
        --data-binary @witness.json -o deploy.reply -w '%{http_code}' "$url/orders") || return 1
    [[ $code == 200 ]] && jq -e '.=={"applied":0,"duplicates":1}' deploy.reply >/dev/null
}
for attempt in {1..80}; do
    if healthy; then
        log serving
        # The operator may hold this lock to inspect a live release before confirmation.
        exec 8>confirmation.lock
        flock -x 8
        healthy
        publish confirmed
        log confirmed
        exit 0
    fi
    sleep .1
done
log unhealthy
exit 1
