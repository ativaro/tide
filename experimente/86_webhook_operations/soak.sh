#!/usr/bin/env bash
set -euo pipefail
umask 077
repo=$(cd "$(dirname "$0")/../.." && pwd)
cd "${1:?prepared run directory required}"
root=$PWD
mode=${2:-soak}
case "$mode" in soak|operator-drill) ;; *) exit 2 ;; esac
export PATH="$(pg_config --bindir):$PATH"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
exec 9>campaign.lock
flock -n 9 || exit 2
[[ -f releases/SHA256SUMS && ! -e status.json ]]
(cd releases && sha256sum --check --status SHA256SUMS)
cp "$repo/experimente/86_webhook_operations/deploy.sh" deploy
unit="tide-$(basename "$root")-web.service"
printf '%s\n' "$unit" > web.unit
uptime_ms() { awk '{printf "%.0f\n",1000*$1}' /proc/uptime; }
now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
status() {
    jq -cn --arg state "$1" --arg why "$2" --arg time "$(now)" --argjson slot "${slot:-0}" \
        '{state:$state,detail:$why,updated_utc:$time,slot:$slot}' > status.next
    mv -fT status.next status.json
}
event() {
    jq -cn --arg time "$(now)" --arg event "$1" --argjson detail "${2:-null}" \
        --argjson elapsed "$(( $(uptime_ms) - start ))" '{utc:$time,elapsed_ms:$elapsed,event:$event,detail:$detail}' >> events.jsonl
}
web_started= db_started= interrupted_pid= done_ok= slot=0
cleanup() {
    local rc=$?
    trap - EXIT
    set +e
    if [[ -n $interrupted_pid ]]; then kill -TERM -- "-$interrupted_pid" 2>/dev/null; fi
    if [[ -n $web_started ]]; then systemctl --user stop "$unit"; fi
    if [[ -n $db_started ]] && pg_ctl -D db status >/dev/null; then pg_ctl -D db -m fast -w stop; fi
    if [[ -z $done_ok ]]; then status failed "See campaign.log and the last request, deployment and resource records"; fi
    exit "$rc"
}
trap cleanup EXIT
trap 'exit 143' TERM INT
trap 'printf "Failure at line %s, slot %s\n" "$LINENO" "$slot" >&2' ERR
status starting "Initializing a dedicated cluster and loopback listener"
mkdir -m700 socket
initdb -D db --locale=C --encoding=UTF8 -A trust -U observer \
    -c "unix_socket_directories=$root/socket" -c "listen_addresses=" -c "log_line_prefix=%m [%p] %e " >init.log
pg_ctl -D db -l "$root/postgres.log" -w start
db_started=yes
observer="host=$root/socket dbname=postgres user=observer"
dsn="host=$root/socket dbname=postgres user=webhook_app application_name=tide-operations connect_timeout=2"
sql() { psql "$observer" -XqAt -v ON_ERROR_STOP=1 -c "$1"; }
sql 'CREATE ROLE webhook_app LOGIN'
sql 'GRANT CREATE ON DATABASE postgres TO webhook_app'
"$repo/tide" run "$repo/apps/orders/webhook.tide" --call prepare --pg "pg=$dsn" | jq -e '.==0' >/dev/null
order() { jq -c --arg id "$1" '(.events[0].id,.events[0].order)=$id' order.json; }
order witness >witness.json
ln -s releases/candidate active
ln -s releases/candidate confirmed
# Let the kernel allocate the first socket, then reuse that endpoint on every restart.
printf '%s\n' 127.0.0.1:0 > listen
cat > start-webhook <<'LAUNCH'
#!/bin/sh
set -eu
exec ./active --listen "$(cat listen)" --workers 4 --queue 8 --pg "$1"
LAUNCH
chmod 700 start-webhook
systemd-run --user --quiet --unit="$unit" --property=Type=exec --property="WorkingDirectory=$root" \
    --property="StandardError=append:$root/service.log" --property=Restart=no \
    "$root/start-webhook" "pg=$dsn"
web_started=yes
webpid() { systemctl --user show -p MainPID --value "$unit"; }
for attempt in {1..80}; do
    address=$(sed -n 's/^LISTEN //p' service.log)
    [[ -z $address ]] || break
    systemctl --user is-active --quiet "$unit"
    sleep .1
done
[[ $address =~ ^127\.0\.0\.1:[1-9][0-9]*$ ]]
printf '%s\n' "$address" > listen.next
mv -fT listen.next listen
url="http://$address"
printf '%s\n' "$url" > url
curl --noproxy '*' -fsS --retry 3 --retry-connrefused --max-time 3 "$url/ready" | jq -e '.=={"ready":true}' >/dev/null
pid=$(webpid)
[[ $pid != 0 && $(readlink "/proc/$pid/exe") == "$root/releases/candidate" ]]
start=$(uptime_ms)
started=$(now)
boot=$(cat /proc/sys/kernel/random/boot_id)
hz=$(getconf CLK_TCK)
jq -n --arg start "$started" --arg boot "$boot" --argjson ticks "$hz" --argjson up "$start" \
  '{started_utc:$start,boot_id:$boot,start_uptime_ms:$up,clock_ticks_per_second:$ticks,duration_seconds:86400,interval_seconds:60,maximum_gap_seconds:90,workers:4,queue:8}' > run.json
printf 'slot,utc,elapsed_ms,pid,release,rss_kib,hwm_kib,cpu_ticks,fds,threads,pg_pss_kib,db_bytes,app_sessions\n' > samples.csv
printf 'utc,elapsed_ms,slot,id,http_status,latency_seconds,release\n' > requests.csv
post() {
    local id=$1 expected=$2 release rc
    order "$id" > request.json
    rc=0
    curl --noproxy '*' --silent --show-error --max-time 5 --header 'Content-Type: application/json' \
        --data-binary @request.json --output reply.json --write-out '%{http_code} %{time_total}\n' "$url/orders" > transfer || rc=$?
    read -r code latency < transfer
    release=$(basename "$(readlink active)")
    printf '%s,%s,%s,%s,%s,%s,%s\n' "$(now)" "$(( $(uptime_ms)-start ))" "$slot" "$id" "$code" "$latency" "$release" >> requests.csv
    [[ $rc == 0 && $code == "$expected" ]]
    case "$expected" in
        201) jq -e '.=={"applied":1,"duplicates":0}' reply.json >/dev/null ;;
        200) jq -e '.=={"applied":0,"duplicates":1}' reply.json >/dev/null ;;
        503) jq -e '.=={"error":"dependency_unavailable"}' reply.json >/dev/null ;;
    esac
}
sample() {
    local release mem fds ticks pgpid pgpss dbstats
    [[ $(webpid) == "$pid" ]]
    release=$(basename "$(readlink active)")
    [[ $(readlink "/proc/$pid/exe") == "$root/releases/$release" ]]
    mem=$(awk '/^VmRSS:/ {rss=$2} /^VmHWM:/ {peak=$2} /^Threads:/ {n=$2} END {print rss,peak,n}' "/proc/$pid/status")
    read -r rss peak threads <<< "$mem"
    ticks=$(awk '{print $14+$15}' "/proc/$pid/stat")
    fds=$(ls -1 "/proc/$pid/fd" | wc -l)
    read -r pgpid < db/postmaster.pid
    local children child files=("/proc/$pgpid/smaps_rollup")
    children=$(cat "/proc/$pgpid/task/$pgpid/children")
    for child in $children; do [[ ! -r /proc/$child/smaps_rollup ]] || files+=("/proc/$child/smaps_rollup"); done
    # A short-lived backend may exit between reading the child list and opening its rollup.
    pgpss=$(awk 'BEGIN { for(i=1;i<ARGC;i++){while((getline line < ARGV[i])>0) if(line~/^Pss:/){split(line,a);k+=a[2]} close(ARGV[i])} print k+0 }' "${files[@]}" </dev/null)
    ((pgpss>0))
    dbstats=$(sql "SELECT pg_database_size(current_database())||','||count(*) FROM pg_stat_activity WHERE application_name='tide-operations'")
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' "$slot" "$(now)" "$(( $(uptime_ms)-start ))" "$pid" "$release" "$rss" "$peak" "$ticks" "$fds" "$threads" "$pgpss" "$dbstats" >> samples.csv
}
check_order() {
    [[ $(sql "SELECT count(*) FROM order_webhook.events e JOIN order_webhook.positions p USING (supplier,ord,line) WHERE e.id='$1' AND e.supplier='load' AND e.ord=e.id AND e.kind='order' AND e.qty=3 AND e.cents=125 AND p.original=3 AND p.outstanding=3 AND p.cents=125 AND e.sku=p.sku") == 1 ]]
}
change() {
    ./deploy "$root" "$@"
    pid=$(webpid)
    post witness 200
    check_order witness
}
interrupted_upgrade() {
    change activate previous
    event rolled_back_to_previous
    exec 8>confirmation.lock
    flock -x 8
    setsid ./deploy "$root" activate candidate 8>&- 9>&- & interrupted_pid=$!
    for attempt in {1..150}; do
        if jq -se --argjson pid "$interrupted_pid" 'any(.[]; .updater_pid==$pid and .event=="serving")' deployments.jsonl >/dev/null; then break; fi
        sleep .1
    done
    jq -se --argjson pid "$interrupted_pid" 'any(.[]; .updater_pid==$pid and .event=="serving")' deployments.jsonl >/dev/null
    [[ $(readlink active) == releases/candidate && $(readlink confirmed) == releases/previous ]]
    post witness 200
    kill -KILL -- "-$interrupted_pid"
    rc=0; wait "$interrupted_pid" || rc=$?; interrupted_pid=
    [[ $rc == 137 ]]
    flock -u 8; exec 8>&-
    event upgrade_killed_before_confirmation '{"signal":"SIGKILL","active":"candidate","confirmed":"previous"}'
    change recover
    [[ $(readlink active) == releases/previous && $(readlink confirmed) == releases/previous ]]
    event recovered_previous
    change activate candidate
    event candidate_confirmed
}
restart_db() {
    local before down code ready
    before=$(sql 'SELECT pg_postmaster_start_time()')
    down=$(uptime_ms)
    pg_ctl -D db -m immediate -w stop
    if pg_isready -qd "$observer"; then return 1; fi
    post db-restart 503
    code=$(curl --noproxy '*' -sS --max-time 3 -D ready.headers -o ready.body -w '%{http_code}' "$url/ready")
    [[ $code == 503 ]]
    jq -e '.error=="dependency_unavailable"' ready.body >/dev/null
    grep -Eiq '^Retry-After: 1[[:space:]]*$' ready.headers
    event database_offline "$(jq -cn --slurpfile response ready.body --argjson http "$code" '{ready_status:$http,reply:$response[0],postgres_accepting:false}')"
    pg_ctl -D db -l "$root/postgres.log" -w start
    [[ $(sql 'SELECT pg_postmaster_start_time()') != "$before" ]]
    [[ $(sql "SELECT count(*) FROM order_webhook.events WHERE id='db-restart'") == 0 ]]
    post db-restart 201; post db-restart 200; check_order db-restart; check_order witness
    ready=$(curl --noproxy '*' -fsS --max-time 3 "$url/ready")
    jq -e '.ready==true' <<<"$ready" >/dev/null
    event database_recovered "$(jq -cn --argjson ms "$(( $(uptime_ms)-down ))" '{stop_to_verified_recovery_ms:$ms}')"
}
post witness 201
event started
if [[ $mode == operator-drill ]]; then
    pg_ctl -D db -m immediate -w stop
    order operator-retry > pending-order.json
    post operator-retry 503
    event delivery_failed "$(jq -cn --slurpfile body reply.json '{request:"pending-order.json",http_status:503,body:$body[0]}')"
    status awaiting_operator "See events.jsonl and the operator runbook"
    while [[ ! -s operator-note.txt ]]; do sleep 2; done
    curl --noproxy '*' -fsS --max-time 5 "$url/ready" | jq -e '.ready==true' >/dev/null
    check_order operator-retry
    post operator-retry 200
    check_order witness
    event drill_restored
    status drill_complete "Independent identity and diagnostic notes require review"
    done_ok=yes
    exit 0
fi
last=$start
for ((slot=0;slot<=1440;slot++)); do
    target=$((start + slot*60000))
    current=$(uptime_ms)
    if ((current < target)); then sleep "$(awk -v ms="$((target-current))" 'BEGIN{printf "%.3f",ms/1000}')"; fi
    current=$(uptime_ms)
    [[ $(cat /proc/sys/kernel/random/boot_id) == "$boot" ]]
    ((current-last<=90000 && current>=target))
    last=$current
    post "pulse-$slot" 201; post "pulse-$slot" 200; check_order "pulse-$slot"
    sample
    status running "Verified scheduled delivery and replay"
    case "$slot" in
        1) interrupted_upgrade ;;
        2) restart_db ;;
    esac
done
slot=1440
totals=$(sql "SELECT (SELECT count(*) FROM order_webhook.events)||','||count(*)||','||sum(outstanding)||','||sum(outstanding*cents) FROM order_webhook.positions")
[[ $totals == 1443,1443,4329,541125 ]]
# Compare the full key sets and every stored business field once more after the final pulse.
bad=$(sql "WITH wanted(id) AS (SELECT 'pulse-'||n FROM generate_series(0,1440) AS n UNION ALL VALUES ('witness'),('db-restart')), booked AS (SELECT e.id FROM order_webhook.events e JOIN order_webhook.positions p USING(supplier,ord,line) WHERE e.supplier='load' AND e.id=e.ord AND e.line='1' AND e.kind='order' AND e.qty=3 AND e.cents=125 AND e.sku='Pièce猫' AND p.sku=e.sku AND p.original=3 AND p.outstanding=3 AND p.cents=125) SELECT count(*) FROM wanted FULL JOIN booked USING(id) WHERE wanted.id IS NULL OR booked.id IS NULL")
[[ $bad == 0 ]]
event completed "$(jq -cn --arg counts "$totals" '{events_positions_quantity_value_cents:$counts,key_or_value_mismatches:0}')"
status complete "24 hours verified"
done_ok=yes
