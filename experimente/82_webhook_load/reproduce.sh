#!/usr/bin/env bash
set -euo pipefail
if [[ ${1-} != --isolated ]]; then
    exec bwrap --unshare-net --die-with-parent --bind / / --dev-bind /dev /dev --proc /proc -- bash "$0" --isolated "$@"
fi
shift
cd "$(dirname "$0")/../.."
root=$PWD
out=$(realpath -m "${1:-build/stage13-results}")
mkdir -p "$out"
tmp=$(mktemp -d)
export PATH="$(pg_config --bindir):$PATH" LC_ALL=C no_proxy="*"
server= locker= cluster= clients=()
cleanup() {
    local rc=$?
    if (( rc )); then
        if [[ -f $tmp/server ]]; then tail -12 "$tmp/server" >&2; fi
        if [[ -f $tmp/pg.log ]]; then tail -8 "$tmp/pg.log" >&2; fi
        if [[ -f $tmp/csv ]]; then cp "$tmp/csv" "$out/failed-transfers.csv"; fi
    fi
    for pid in "${clients[@]}" "$server" "$locker"; do
        if [[ -n $pid ]]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
    done
    if [[ -n $cluster ]]; then pg_ctl -D "$tmp/db" -m immediate -w stop >/dev/null; fi
    rm -rf "$tmp"
}
trap cleanup EXIT
baseline=${STAGE12_SERVICE:-"$tmp/baseline"}
current=${STAGE13_SERVICE:-"$tmp/current"}
if [[ -z ${STAGE12_SERVICE:-} ]]; then
    mkdir "$tmp/base"
    git archive ac8fbbc -- Makefile tide tide.lock native apps lib workbench | tar -x -C "$tmp/base"
    (cd "$tmp/base"; ./tide build --service apps/orders/webhook.tide "$baseline" main)
fi
if [[ -z ${STAGE13_SERVICE:-} ]]; then ./tide build --service apps/orders/webhook.tide "$current" main; fi
checks=apps/orders/webhook_load_checks.tide
./tide test "$checks" >&2
for value in -1 97 no; do
    rc=0; timeout 2 "$current" --listen 127.0.0.1:0 "--queue=$value" 2>"$tmp/option" || rc=$?
    [[ $rc == 1 ]]; grep -Eq 'Expected (0 to 96 queued requests|a queue size)' "$tmp/option"
done
initdb -D "$tmp/db" --locale=C --encoding=UTF8 -A trust -U observer >"$tmp/init"
pg_ctl -D "$tmp/db" -l "$tmp/pg.log" -o "-k $tmp -c listen_addresses=''" -w start >/dev/null
cluster=yes
observer="host=$tmp user=observer dbname=postgres"
dsn="host=$tmp user=webhook_app dbname=postgres application_name=tide-orders"
sql() { psql "$observer" -XqAt -v ON_ERROR_STOP=1 -c "$1"; }
sql 'CREATE ROLE webhook_app LOGIN; GRANT CREATE ON DATABASE postgres TO webhook_app'
./tide run apps/orders/webhook.tide --call prepare --pg "pg=$dsn" > /dev/null
truncate_db() { sql 'TRUNCATE order_webhook.events,order_webhook.positions'; }
now() { date +%s%N; }
start() {
    local bin=$1; shift
    : >"$tmp/server"
    "$bin" --listen 127.0.0.1:0 --pg "pg=$dsn" "$@" 2>>"$tmp/server" & server=$!
    for _ in {1..150}; do
        addr=$(sed -n 's/^LISTEN //p' "$tmp/server")
        if [[ -n $addr ]]; then url="http://$addr/orders"; return; fi
        kill -0 "$server"; sleep .025
    done
    cat "$tmp/server" >&2; return 1
}
stop() { kill -TERM "$server"; wait "$server"; server=; }
stats() {
    awk '/^SERVICE /{for(i=2;i<=NF;i++){split($i,a,"=");print a[1],a[2]}}' "$tmp/server" |
        jq -Rn '[inputs|split(" ")|{(.[0]):(.[1]|tonumber)}]|add'
}
budget() {
    local stats_json=$1 args
    args=$(jq -c --argjson w "$2" --argjson q "$3" '{workers:$w,capacity:$q,peak_active,peak_queued}' <<<"$stats_json")
    [[ $(./tide run "$checks" --call within_budget --inputs "$args") == true ]]
}
# Each transfer uses a fresh connection and a distinct supplier event. Prebuild all bodies.
count=1024
for ((i=0;i<count;i+=16)); do
    args=$(jq -cn --argjson i "$i" '{ids:[range($i;$i+16)|tostring]}')
    ./tide run "$checks" --call orders --inputs "$args" | jq -rc '.[]' >>"$tmp/orders"
done
audit() {
    local accepted=$1 observed
    observed=$(sql "SELECT json_build_object('events',COALESCE((SELECT json_agg(id ORDER BY id COLLATE \"C\") FROM order_webhook.events),'[]'),'positions',COALESCE((SELECT json_agg(ord ORDER BY ord COLLATE \"C\") FROM order_webhook.positions),'[]'),'invalid',(SELECT count(*) FROM order_webhook.events WHERE (supplier,kind,id,line,qty,sku,cents) IS DISTINCT FROM ('load','order',ord,'1',3,'Pièce猫',125))+(SELECT count(*) FROM order_webhook.positions WHERE (supplier,line,sku,original,outstanding,cents) IS DISTINCT FROM ('load','1','Pièce猫',3,3,125)))")
    [[ $(./tide run "$checks" --call stored --inputs "$(jq -c --argjson ok "$accepted" '.+{accepted:$ok}' <<<"$observed")") == true ]]
}
get_db() { sql "SELECT count(*) FROM pg_stat_activity WHERE application_name='tide-orders' $1"; }
lock_positions() {
    mkfifo "$tmp/lock"; exec 7<>"$tmp/lock"; rm "$tmp/lock"
    : >"$tmp/locked"
    psql "$observer" -XqAt -v ON_ERROR_STOP=1 <&7 >>"$tmp/locked" & locker=$!
    printf 'BEGIN;\nLOCK TABLE order_webhook.positions IN SHARE MODE;\n\\echo LOCKED\n' >&7
    for _ in {1..100}; do grep -q LOCKED "$tmp/locked" && return; sleep .02; done; return 1
}
release_lock() { printf 'ROLLBACK;\n\\q\n' >&7; wait "$locker"; locker=; exec 7>&-; }
post() {
    local n=$1
    curl --noproxy '*' -sS --max-time 9 -H 'Connection: close' -H 'Content-Type: application/json' \
        -D "$tmp/h$n" -o "$tmp/b$n" -w '%{http_code}' --data-binary "$(sed -n "$((n+1))p" "$tmp/orders")" "$url" >"$tmp/s$n" & client=$!
    clients+=("$client")
}
wait_lock() {
    for _ in {1..150}; do
        [[ $(get_db "AND cardinality(pg_blocking_pids(pid))>0 AND query LIKE 'INSERT INTO order_webhook.positions%'") == 1 ]] && return
        sleep .015
    done; return 1
}
await_empty() {
    local start=$1
    for _ in {1..400}; do
        if [[ $(get_db '') == 0 ]]; then released_ms=$(( ($(now)-start)/1000000 )); return; fi
        sleep .015
    done; return 1
}
kill_client() { kill -TERM "$1"; wait "$1" || [[ $? == 143 ]]; }
faults="$out/faults.jsonl"
: >"$faults"
for arm in stage12 stage13; do
    truncate_db
    if [[ $arm == stage12 ]]; then start "$baseline" --workers 1; else start "$current" --workers 1 --queue 0; fi
    lock_positions; post 0; active=$client; wait_lock
    pid=$(sql "SELECT pid FROM pg_stat_activity WHERE application_name='tide-orders'")
    if [[ $arm == stage13 ]]; then
        post 1; wait "$client"; [[ $(cat "$tmp/s1") == 503 ]]
        jq -e '.error=="queue_full"' "$tmp/b1" >/dev/null; grep -iq '^Retry-After: 1' "$tmp/h1"
    fi
    t=$(now); kill_client "$active"; await_empty "$t"; clients=()
    audit '[]'
    if [[ $arm == stage13 ]]; then
        (( released_ms < 1500 )); grep -q 'canceling statement due to user request' "$tmp/pg.log"
    fi
    release_lock
    post 0; wait "$client"; clients=(); [[ $(cat "$tmp/s0") == 201 ]]; audit '["0"]'; stop
    counters=$(stats)
    if [[ $arm == stage13 ]]; then budget "$counters" 1 0; jq -e '.active_aborts==1 and .rejected==1' <<<"$counters" >/dev/null; fi
    jq -cn --arg arm "$arm" --argjson ms "$released_ms" --argjson pid "$pid" --argjson stats "$counters" '{case:"client_abort_blocked_insert",arm:$arm,backend_pid:$pid,release_ms:$ms,connections_while_lock_held:0,bookings_before_retry:0,bookings_after_retry:1,stats:$stats}' >>"$faults"
done
truncate_db; start "$current" --workers 1 --queue 1; lock_positions; post 0; active=$client; wait_lock
post 1; a=$client; post 2; b=$client
wait -n -p done "$a" "$b"
if [[ $done == "$a" ]]; then queued=$b; refused=1; else queued=$a; refused=2; fi
[[ $(cat "$tmp/s$refused") == 503 ]]; jq -e '.error=="queue_full"' "$tmp/b$refused" >/dev/null
[[ $(get_db '') == 1 ]]
kill_client "$queued"
# Keep the first query locked while the queued peer is removed.
sleep .12
t=$(now); kill_client "$active"; await_empty "$t"; (( released_ms < 1500 )); clients=()
audit '[]'; release_lock; post 3; wait "$client"; clients=(); [[ $(cat "$tmp/s3") == 201 ]]; audit '["3"]'; stop
counters=$(stats); budget "$counters" 1 1
jq -e '.peak_queued==1 and .queued_aborts==1 and .active_aborts==1 and .rejected==1' <<<"$counters" >/dev/null
jq -cn --argjson ms "$released_ms" --argjson stats "$counters" '{case:"abort_queued_and_active",release_ms:$ms,connections_at_saturation:1,connections_after_aborts:0,bookings_before_retry:0,healthy_followup:201,stats:$stats}' >>"$faults"
# Send a termination signal with one query and one queued order outstanding.
truncate_db; start "$current" --workers 1 --queue 1; lock_positions; post 0; active=$client; wait_lock
post 1; a=$client; post 2; b=$client
wait -n -p done "$a" "$b"
if [[ $done == "$a" ]]; then refused=1; queued=$b; else refused=2; queued=$a; fi
[[ $(cat "$tmp/s$refused") == 503 ]]
t=$(now); stop; await_empty "$t"; (( released_ms < 1500 ))
wait "$active" || :; wait "$queued" || :; clients=()
audit '[]'; release_lock; counters=$(stats); budget "$counters" 1 1
jq -e '.queued_aborts==1 and .active_aborts==1' <<<"$counters" >/dev/null
jq -cn --argjson ms "$released_ms" --argjson stats "$counters" '{case:"shutdown_with_queue",release_ms:$ms,connections_after_shutdown:0,bookings:0,stats:$stats}' >>"$faults"

# Fixed client concurrency, no retries, one distinct durable order per transfer.
# curl times each transfer from its start through the last response byte.
samples="$out/requests.csv"
printf 'arm,round,clients,id,status,seconds\n' >"$samples"
: >"$out/blocks.jsonl"
mkdir "$tmp/bodies"
rounds=4
for ((round=1;round<=rounds;round++)); do
    levels=(1 4 12 32); arms=(stage12 stage13)
    if (( round % 2 == 0 )); then levels=(32 12 4 1); arms=(stage13 stage12); fi
    for level in "${levels[@]}"; do
        for arm in "${arms[@]}"; do
            truncate_db
            if [[ $arm == stage12 ]]; then start "$baseline" --workers 4; else start "$current" --workers 4 --queue 8; fi
            post 0; wait "$client"; clients=(); [[ $(cat "$tmp/s0") == 201 ]]; truncate_db
            jq -Rrs --arg url "$url" --arg dir "$tmp/bodies" '
                split("\n")|map(select(length>0))|to_entries|map(
                (.key|tostring) as $id |
                "url = "+($url|tojson)+"\nheader = \"Connection: close\"\nheader = \"Content-Type: application/json\"\nmax-time = 10\ndata-binary = "+(.value|tojson)+
                "\noutput = "+($dir+"/"+$id|tojson)+"\nwrite-out = "+($id+",%{http_code},%{time_total}\\n"|tojson)
                )|join("\nnext\n")' "$tmp/orders" >"$tmp/curl.cfg"
            begin=$(now)
            curl --silent --show-error --noproxy '*' --http1.1 --parallel --parallel-immediate --parallel-max "$level" --config "$tmp/curl.cfg" >"$tmp/csv"
            elapsed=$(( $(now)-begin ))
            [[ $(wc -l <"$tmp/csv") == "$count" ]]
            awk -F, -v base="$tmp/bodies/" -v count="$count" '
                {if(NF!=3 || $1 !~ /^[0-9]+$/ || $1>=count || seen[$1]++ || $3<=0)exit 1;
                 path=base $1; if((getline body < path)!=1)exit 1;close(path);
                 if($2==201 && body=="{\"applied\":1,\"duplicates\":0}")next;
                 if($2==503 && body=="{\"error\":\"queue_full\"}")next;exit 1;}' "$tmp/csv"
            accepted=$(awk -F, '$2==201{print $1}' "$tmp/csv" | sort | jq -Rn '[inputs]')
            audit "$accepted"; [[ $(get_db '') == 0 ]]; stop
            ok=$(jq length <<<"$accepted"); counters=$(stats)
            if [[ $arm == stage13 ]]; then
                budget "$counters" 4 8; [[ $(jq '.rejected' <<<"$counters") == "$((count-ok))" ]]
            else [[ $ok == "$count" ]]; fi
            awk -v p="$arm,$round,$level," '{print p $0}' "$tmp/csv" >>"$samples"
            jq -cn --arg arm "$arm" --argjson r "$round" --argjson c "$level" --argjson ns "$elapsed" --argjson ok "$ok" --argjson n "$count" --argjson stats "$counters" \
               '{arm:$arm,round:$r,clients:$c,seconds:($ns/1e9),attempts:$n,booked:$ok,rejected:($n-$ok),stats:$stats}' >>"$out/blocks.jsonl"
        done
    done
done
jq -Rn '[inputs|split(",")|select(.[0]!="arm")|{arm:.[0],clients:(.[2]|tonumber),status:(.[4]|tonumber),ms:(.[5]|tonumber*1000)}]' "$samples" >"$tmp/transfers"
jq -sn --slurpfile blocks "$out/blocks.jsonl" --slurpfile requests "$tmp/transfers" '
    def p95: sort | if length>0 then .[(length*.95|ceil)-1] else null end;
    $blocks|group_by(.arm,.clients)|map(. as $b | $requests[0]|map(select(.arm==$b[0].arm and .clients==$b[0].clients)) as $r |
    ($b|map(.seconds)|add) as $sec | ($b|map(.booked)|add) as $ok |
    {arm:$b[0].arm,clients:$b[0].clients,sent:($r|length),booked:$ok,rejected:(($r|length)-$ok),responses_per_s:(($r|length)/$sec),bookings_per_s:($ok/$sec),
     p95_ms:($r|map(.ms)|p95),booked_p95_ms:($r|map(select(.status==201)|.ms)|p95),rejected_p95_ms:($r|map(select(.status==503)|.ms)|p95)})' >"$out/summary.json"
gzip -nf "$samples"
jq -n --arg tide "$(./tide --version)" --arg postgres "$(sql 'SHOW server_version')" --arg cpu "$(LC_ALL=C lscpu | sed -n 's/^Model name: *//p' | head -1)" \
   --arg curl "$(curl --version | head -1)" --arg kernel "$(uname -srmo)" --arg fsync "$(sql 'SHOW fsync')" --arg sync "$(sql 'SHOW synchronous_commit')" \
   '{tide:$tide,postgres:$postgres,cpu:$cpu,curl:$curl,kernel:$kernel,fsync:$fsync,synchronous_commit:$sync}' >"$out/environment.json"
