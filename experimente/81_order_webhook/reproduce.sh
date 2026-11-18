#!/usr/bin/env bash
# Fault injection uses local processes. The requests and expected database rows come from TIDE.
set -euo pipefail
if [[ ${1-} != --isolated ]]; then
    exec bwrap --unshare-net --die-with-parent --bind / / --dev-bind /dev /dev --proc /proc -- bash "$0" --isolated
fi
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
tide=${TIDE_CLI:-"$root/tide"}
app=apps/orders/webhook.tide
fixtures=apps/orders/webhook_checks.tide
tmp=$(mktemp -d)
export PATH="$(pg_config --bindir):$PATH"
server= cluster= locker= relay= sender=
cleanup() {
    if [[ -n $relay ]]; then printf 'release\n' >&8 || :; fi
    if [[ -n $locker ]]; then printf 'ROLLBACK;\n\\q\n' >&7 || :; fi
    for pid in "$sender" "$relay" "$server" "$locker"; do
        if [[ -n $pid ]]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
    done
    if [[ -n $cluster ]]; then pg_ctl -D "$tmp/db" -m immediate -w stop >/dev/null; fi
    rm -rf "$tmp"
}
trap cleanup EXIT
"$tide" build --service "$app" "$tmp/orders" main >&2
initdb -D "$tmp/db" --locale=C --encoding=UTF8 -A trust -U observer >"$tmp/init"
pg_ctl -D "$tmp/db" -l "$tmp/postgres.log" -o "-k $tmp -c listen_addresses='' -c log_line_prefix=%e:" -w start >/dev/null
cluster=yes
observer="host=$tmp dbname=postgres user=observer"
dsn="host=$tmp dbname=postgres user=webhook_app application_name=tide-orders"
psql "$observer" -Xq -v ON_ERROR_STOP=1 -c 'CREATE ROLE webhook_app LOGIN' -c 'GRANT CREATE ON DATABASE postgres TO webhook_app'
"$tide" run "$app" --call prepare --pg "pg=$dsn" >"$tmp/prepare"
jq -e '. == 0' "$tmp/prepare" >/dev/null
"$tide" test "$fixtures" >&2
settings=$(psql "$observer" -XqAt -v ON_ERROR_STOP=1 -c "SELECT json_build_object('version',current_setting('server_version'),'fsync',current_setting('fsync'),'synchronous_commit',current_setting('synchronous_commit'),'unix_socket',inet_server_addr() IS NULL)")
jq -e '.fsync=="on" and .synchronous_commit=="on" and .unix_socket' <<<"$settings" >/dev/null
jq -cn --arg tool "$("$tide" --version)" --argjson postgres "$settings" '{check:"environment",tool:$tool,postgres:$postgres}'

start_service() {
    : >"$tmp/listen"
    "$tmp/orders" --listen 127.0.0.1:0 --workers 4 --pg "pg=$dsn" > /dev/null 2>>"$tmp/listen" & server=$!
    for _ in {1..150}; do
        addr=$(sed -n 's/^LISTEN //p' "$tmp/listen")
        if [[ -n $addr ]]; then url="http://$addr/orders"; return; fi
        kill -0 "$server"; sleep .03
    done
    cat "$tmp/listen" >&2; return 1
}
fixture() {
    supplier=$1
    "$tide" run "$fixtures" --call requests --inputs "$(jq -cn --arg s "$supplier" '{supplier:$s}')" >"$tmp/requests"
}
snapshot() {
    local label=$1 phase=$2 actual args
    actual=$(psql "$observer" -XqAt -v ON_ERROR_STOP=1 -v s="$supplier" <<'SQL'
SELECT json_build_object(
 'events',COALESCE((SELECT json_agg(e ORDER BY e.id COLLATE "C") FROM
  (SELECT supplier,id,kind,ord,line,qty,sku,cents FROM order_webhook.events WHERE supplier=:'s') e),'[]'),
 'positions',COALESCE((SELECT json_agg(p ORDER BY p.ord,p.line) FROM
  (SELECT supplier,ord,line,sku,original,outstanding,cents,outstanding*cents AS value_cents
   FROM order_webhook.positions WHERE supplier=:'s') p),'[]'));
SQL
)
    args=$(jq -cn --arg s "$supplier" --arg p "$phase" --argjson db "$actual" '{supplier:$s,phase:$p,observed:$db}')
    [[ $("$tide" run "$fixtures" --call check_database --inputs "$args") == true ]] || {
        echo "$label: unexpected DB state $actual" >&2; return 1;
    }
    jq -cn --arg check "$label" --arg s "$supplier" --argjson db "$actual" '{check:$check,supplier:$s,db:$db}'
}
send_request() {
    local dest=$1 body=$2 response=$3 timeout=${4:-12}
    curl --silent --show-error --noproxy '*' --http1.1 --max-time "$timeout" -H 'Connection: close' \
      -H 'Content-Type: application/json' --data-binary "$body" -o "$response.body" -w '%{http_code}' "$dest" >"$response.status"
}
check_reply() {
    local label=$1 prefix=$2 outcome=$3 status body args
    status=$(cat "$prefix.status"); body=$(cat "$prefix.body")
    args=$(jq -cn --arg o "$outcome" --argjson s "$status" --arg b "$body" '{outcome:$o,status:$s,body:$b}')
    [[ $("$tide" run "$fixtures" --call check_response --inputs "$args") == true ]] || {
        echo "$label: unexpected $status $body" >&2; return 1;
    }
    jq -cn --arg check "$label" --argjson status "$status" --argjson body "$body" '{check:$check,status:$status,body:$body}'
}
post() {
    send_request "$url" "$(jq -r --arg key "$2" '.[$key]' "$tmp/requests")" "$tmp/reply"
    check_reply "$1" "$tmp/reply" "$3"
}
hold_table() {
    local gate=$1
    mkfifo "$tmp/$gate.control"; exec 7<>"$tmp/$gate.control"
    : >"$tmp/lock-log"
    psql "$observer" -XqAt -v ON_ERROR_STOP=1 <"$tmp/$gate.control" >>"$tmp/lock-log" & locker=$!
    printf 'BEGIN;\nLOCK TABLE order_webhook.%s IN ACCESS EXCLUSIVE MODE;\n\\echo LOCKED\n' "$gate" >&7
    for _ in {1..150}; do grep -q LOCKED "$tmp/lock-log" && break; sleep .02; done
    grep -q LOCKED "$tmp/lock-log"
}
wait_for_inserts() {
    local table=$1 minimum=$2 waiting
    for _ in {1..100}; do
        waiting=$(psql "$observer" -XqAt -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM pg_stat_activity WHERE application_name='tide-orders' AND cardinality(pg_blocking_pids(pid))>0 AND query LIKE 'INSERT INTO order_webhook.$table%'")
        if (( waiting >= minimum )); then return 0; fi
        sleep .02
    done
    echo "Expected $minimum blocked INSERT(s) into $table" >&2; return 1
}
release_table() {
    printf 'ROLLBACK;\n\\q\n' >&7
    wait "$locker"; locker=; exec 7>&-
}
created='{"applied":1,"duplicates":0}'
start_service

fixture parallel
sale=$(jq -r .order "$tmp/requests")
jobs=()
hold_table events
for i in {1..8}; do send_request "$url" "$sale" "$tmp/race$i" & jobs+=("$!"); done
wait_for_inserts events 2
release_table
for pid in "${jobs[@]}"; do wait "$pid"; done
new=0; repeats=0
for i in {1..8}; do
    if [[ $(cat "$tmp/race$i.status") == 201 ]]; then
        check_reply parallel "$tmp/race$i" created >/dev/null; ((new+=1))
    else
        check_reply parallel "$tmp/race$i" duplicate >/dev/null; ((repeats+=1))
    fi
done
[[ $("$tide" run "$fixtures" --call check_race --inputs "{\"created\":$new,\"duplicates\":$repeats}") == true ]]
jq -cn --argjson new "$new" --argjson dup "$repeats" '{check:"parallel_responses",overlapping_inserts_at_least:2,created:$new,duplicates:$dup}'
snapshot parallel_commit booked
post conflicting_id conflict event_conflict
post batch_rejected rejected over_cancel
send_request "$url" '{"supplier":"parallel","events":[}' "$tmp/malformed"
check_reply malformed_json "$tmp/malformed" invalid_json
snapshot after_rejections booked
post partial_cancel cancel created
post cancel_replayed cancel duplicate
snapshot after_cancel cancelled

fixture sql_timeout
hold_table positions
send_request "$url" "$(jq -r .order "$tmp/requests")" "$tmp/blocked" & sender=$!
wait_for_inserts positions 1
wait "$sender"; sender=
check_reply statement_timeout "$tmp/blocked" database_failure
grep -q '^57014:.*canceling statement due to statement timeout' "$tmp/postgres.log"
echo '{"check":"postgres_timeout","sqlstate":"57014","blocked_insert":"positions"}'
release_table
snapshot after_statement_timeout empty
post retry_after_statement_timeout order created
snapshot statement_timeout_recovered booked

# Forward the real request, capture the upstream HTTP reply, and hold the downstream socket open.
cat >"$tmp/hold-response" <<'SH'
#!/bin/sh
socat STDIO "TCP4:$UPSTREAM" >"$ACK_FILE" || exit 1
IFS= read -r release <"$RELEASE_FIFO"
SH
chmod +x "$tmp/hold-response"
withhold_reply() {
    local timeout=$1 port
    export UPSTREAM=$addr ACK_FILE="$tmp/$supplier.ack" RELEASE_FIFO="$tmp/$supplier.fifo"
    mkfifo "$RELEASE_FIFO"; exec 8<>"$RELEASE_FIFO"
    : >"$tmp/relay-log"
    socat -d -d TCP4-LISTEN:0,bind=127.0.0.1,reuseaddr EXEC:"$tmp/hold-response" 2>>"$tmp/relay-log" & relay=$!
    for _ in {1..150}; do
        port=$(sed -n 's/.*listening on AF=2 127\.0\.0\.1:\([0-9]*\).*/\1/p' "$tmp/relay-log")
        [[ -z $port ]] || break; sleep .02
    done
    [[ -n $port ]]
    send_request "http://127.0.0.1:$port/orders" "$(jq -r .order "$tmp/requests")" "$tmp/$supplier-client" "$timeout" 2>"$tmp/$supplier-client.err" & sender=$!
    for _ in {1..150}; do
        [[ -s $ACK_FILE ]] && grep -qF "$created" "$ACK_FILE" && break
        sleep .02
    done
    grep -q '^HTTP/1.1 201 ' "$ACK_FILE"
    sed '1,/^\r$/d' "$ACK_FILE" | jq -e --argjson receipt "$created" '.==$receipt' >/dev/null
    kill -0 "$sender"
}
finish_sender() {
    local expected_rc=$1 rc=0
    wait "$sender" || rc=$?; sender=
    [[ $rc == "$expected_rc" && $(cat "$tmp/$supplier-client.status") == 000 && ! -s "$tmp/$supplier-client.body" ]]
    jq -cn --arg check "$supplier" --argjson rc "$rc" '{check:$check,upstream_status:201,client_http_status:"000",client_body_bytes:0,curl_exit:$rc}'
}
open_gate() { printf 'release\n' >&8; wait "$relay"; relay=; exec 8>&-; }

fixture client_timeout
withhold_reply 3
snapshot committed_before_client_timeout booked
finish_sender 28
open_gate
post retry_after_client_timeout order duplicate
snapshot client_timeout_recovered booked

fixture restart
withhold_reply 12
snapshot committed_before_kill booked
kill -0 "$sender"
old=$server
kill -KILL "$server"; rc=0; wait "$server" 2>/dev/null || rc=$?; server=
[[ $rc == 137 ]]
echo '{"check":"webhook_killed","signal":"SIGKILL","exit":137}'
snapshot service_down booked
open_gate
finish_sender 52
start_service
[[ $server != "$old" ]]
echo '{"check":"webhook_restarted","new_process":true}'
post retry_after_restart order duplicate
snapshot restarted_service booked

fixture database_restart
post before_database_restart order created
snapshot committed_before_database_restart booked
pg_ctl -D "$tmp/db" -l "$tmp/postgres.log" -m immediate -w restart >/dev/null
grep -q 'automatic recovery in progress' "$tmp/postgres.log"
echo '{"check":"postgres_restarted","shutdown":"immediate","wal_recovery":true}'
snapshot after_database_restart booked
post retry_after_database_restart order duplicate
snapshot database_restart_recovered booked
