#!/usr/bin/env bash
# The fixtures and service are TIDE programs. This driver only builds, supplies
# host grants, invokes the three public paths and compares their receipts.
set -euo pipefail
export LC_ALL=C
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
study=experimente/79_execution_parity
tide=${TIDE_CLI:-"$root/tide"}
tmp=$(mktemp -d)
server= tls= pg=
cleanup() {
    for pid in "$tls" "$server"; do
        if [[ -n $pid ]]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
    done
    if [[ -n $pg ]]; then pg_ctl -D "$tmp/db" -m immediate -w stop >/dev/null; fi
    rm -rf "$tmp"
}
trap cleanup EXIT
bins="$tmp/bin"
mkdir -p "$bins"
test "$(jq -cn 'have_decnum')" = true
export tide bins
cut -f1-3 "$study/targets.tsv" | xargs -P "${JOBS:-4}" -n 3 bash -ec '"$tide" build --aot "$2" "$bins/$1" "$3"' _ >&2
"$tide" build --service apps/report_packages/measurement_service.tide "$bins/service" main >&2
export PATH="$(pg_config --bindir):$PATH"
initdb -D "$tmp/db" --locale=C --encoding=UTF8 -A trust -U tide > "$tmp/init"
pg_ctl -D "$tmp/db" -l "$tmp/pg.log" -o "-k $tmp -c listen_addresses=''" -w start >/dev/null
pg=yes
dsn="host=$tmp dbname=postgres user=tide"
"$bins/service" --listen 127.0.0.1:0 --workers 2 > /dev/null 2>"$tmp/listen" & server=$!
for n in {1..150}; do addr=$(sed -n 's/^LISTEN //p' "$tmp/listen"); [[ -n $addr ]] && break; sleep .04; done
test -n "$addr"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -addext 'subjectAltName=IP:127.0.0.1' -keyout "$tmp/key" -out "$tmp/cert" >/dev/null 2>&1
socat -d -d "OPENSSL-LISTEN:0,bind=127.0.0.1,cert=$tmp/cert,key=$tmp/key,verify=0,fork,reuseaddr" "TCP4:$addr" </dev/null > /dev/null 2>"$tmp/tls" & tls=$!
for n in {1..150}; do port=$(sed -n 's/.*listening on AF=2 127.0.0.1:\([0-9]*\).*/\1/p' "$tmp/tls" | head -1); [[ -n $port ]] && break; sleep .04; done
test -n "$port"
export TIDE_HTTPS_CA_FILE="$tmp/cert"
while IFS=$'\t' read -r id file fn bindings; do
    awk -v fn="$fn" '$1=="example" && $3==fn {name=$2; if (getline != 1) exit 1; print name "\t" $0}' "$file" > "$tmp/contracts"
    if [[ ! -s $tmp/contracts ]]; then echo "Missing examples for $file $fn" >&2; exit 1; fi
    while IFS=$'\t' read -r name contract; do
        args=$(jq -c .inputs <<<"$contract")
        grants=(); testgrants=()
        for binding in $bindings; do
            key=${binding#*:}
            case ${binding%:*} in
                r) jq -jr --arg k "$key" '.inputs[$k]' <<<"$contract" > "$tmp/$key"; grants+=(--read "$key=$tmp/$key");;
                w) grants+=(--write "$key=$tmp/export");;
                d) grants+=(--db "$key=:memory:");;
                n) grants+=(--https "$key=https://127.0.0.1:$port");;
                p) grants+=(--pg "$key=$dsn"); testgrants+=(--pg "$key=$dsn");;
                *) echo "Unknown grant $binding" >&2; exit 1;;
            esac
            args=$(jq -c --arg k "$key" 'del(.[$k])' <<<"$args")
        done
        "$tide" test "$file" --example "$name" "${testgrants[@]}" > "$tmp/test" 2> "$tmp/test.err" || { cat "$tmp/test.err" >&2; exit 1; }
        test ! -s "$tmp/test.err"
        jq -e '.passed == 1 and (has("error") != has("actual"))' "$tmp/test" >/dev/null
        expected=$(jq -cS 'del(.passed)' "$tmp/test")
        for mode in run aot; do
            if [[ $mode == run ]]; then cmd=("$tide" run "$file" --call "$fn"); else cmd=("$bins/$id"); fi
            printf 'previous' > "$tmp/export"
            rc=0; "${cmd[@]}" --inputs "$args" "${grants[@]}" > "$tmp/out" 2> "$tmp/err" || rc=$?
            if [[ $rc == 0 ]]; then test ! -s "$tmp/err"; observed=$(jq -cS '{actual:.}' "$tmp/out")
            else
                if [[ $rc != 1 || -s $tmp/out ]]; then echo "$id/$name $mode exited $rc" >&2; cat "$tmp/err" >&2; exit 1; fi
                observed=$(jq -cS '{error:.}' "$tmp/err")
            fi
            if [[ $expected != "$observed" ]]; then
                printf '%s/%s %s\ntest %s\n%s %s\n' "$id" "$name" "$mode" "$expected" "$mode" "$observed" >&2
                exit 1
            fi
            if [[ $name == write_file ]]; then printf 'é猫' | cmp - "$tmp/export"; fi
        done
        jq -c --arg id "$id" --arg name "$name" '{target:$id,example:$name,observed:del(.passed)}' "$tmp/test"
    done < "$tmp/contracts"
done < "$study/targets.tsv" | tee "$tmp/results"
# Every catalog operation needs a named case that actually ran in all three modes.
while IFS=$'\t' read -r id case_name ops; do
    jq -es --arg id "$id" --arg n "$case_name" 'any(.[];.target==$id and .example==$n)' "$tmp/results" >/dev/null
done < "$study/witnesses.tsv"
"$tide" describe | jq -r '.operations[]' | sort -u > "$tmp/catalog"
cut -f3 "$study/witnesses.tsv" | tr ' ' '\n' | sort -u | diff -u "$tmp/catalog" -
