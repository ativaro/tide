#!/usr/bin/env bash
# Exercise the native editor on disposable project copies. GDB stops at Linux
# syscalls so process death uses the shipped binary and real filesystem state.
set -euo pipefail
export LC_ALL=C
root=$(cd "$(dirname "$0")/../.." && pwd)
tide="$root/tide"
bin="$root/build/native"
fixture="$root/native/bootstrap/fixtures/atomic_edit"
work=$(mktemp -d)
trap 'chmod -R u+rwX "$work"; rm -rf "$work"' EXIT
test "$(id -u)" != 0 || { echo 'Run as an ordinary user for the permission tests.' >&2; exit 1; }
proj="$work/live"
entry="$proj/checks.tide"
package=vendor/fees/1.0.0/package.tide
members=(checks.tide orders.tide "$package")
journal="$proj/.tide-edit-transaction-v1"
edits=$(cat "$fixture/edits.json")
cp -R "$fixture" "$work/old"
chmod 640 "$work/old/orders.tide"
printf 'unrelated\n' > "$work/old/untouched.txt"
reset_project() {
    rm -rf "$proj"
    cp -a "$work/old" "$proj"
}
reset_project
revision() { "$tide" check "$entry" | jq -er .revision; }
base=$(revision)
edit() { "$tide" edit "$entry" --base "$base" --edits "$edits" "$@"; }
edit > "$work/preview"
next=$(jq -er .revision "$work/preview")
test "$base" != "$next"
jq -e '.written == false and .examples.passed == 1 and (.files | length == 3)' "$work/preview" >/dev/null
cp -a "$work/old" "$work/new"
for file in "${members[@]}"; do
    jq -jer --arg file "$file" '.files[] | select(.file == $file) | .source' "$work/preview" > "$work/new/$file"
done
grep -Fxq '+ (amount units) 2' "$work/new/checks.tide"
grep -Fxq '+ (fees.charge units) 4' "$work/new/orders.tide"
grep -Fxq '+ units 1' "$work/new/$package"
equal_tree() {
    diff -r "$work/$1" "$proj" >&2
    for file in "${members[@]}"; do
        test "$(stat -c %a "$work/$1/$file")" = "$(stat -c %a "$proj/$file")"
    done
}
accept() {
    local wanted=$base
    if [[ $1 == new ]]; then wanted=$next; fi
    test "$(revision)" = "$wanted"
    test "$("$tide" test "$entry")" = '{"passed":1}'
    equal_tree "$1"
}
receipt() { jq -cn --arg case "$1" --arg result "$2" '{case:$case,result:$result}'; }
reject() {
    local code=$1 rc=0
    shift
    "$@" > "$work/out" 2> "$work/err" || rc=$?
    test "$rc" = 1
    test ! -s "$work/out"
    jq -e --arg code "$code" '.code == $code' "$work/err" >/dev/null
}
# Count only known whole-file versions before recovery; a torn file fails.
raw_count() {
    local n=0
    for file in "${members[@]}"; do
        if cmp -s "$work/new/$file" "$proj/$file"; then n=$((n+1)); else cmp "$work/old/$file" "$proj/$file"; fi
    done
    echo "$n"
}
gdb_base=(gdb -nx -nh -q -batch -iex 'set auto-load off' -ex 'set confirm off')
editor=("$bin/editor" --replace-nodes "$entry" :checks.tide "$edits" "$base" no yes)
kill_at() {
    local call=$1 skip=$2
    shift 2
    "${gdb_base[@]}" -ex "catch syscall $call" -ex "ignore 1 $skip" -ex run -ex kill --args "$@" > "$work/gdb" 2>&1
    grep -Eq "Catchpoint 1 \((call to|returned from) syscall $call\)" "$work/gdb"
    grep -Eq 'Inferior .* killed' "$work/gdb"
}
equal_tree old
receipt preview old
edit --write > "$work/written"
jq -e --slurpfile preview "$work/preview" '. == ($preview[0] | .written=true)' "$work/written" >/dev/null
accept new
receipt commit new
reject E_REVISION edit --write
accept new
receipt stale_base E_REVISION

reset_project
partial=$(jq -c '.[:2]' <<< "$edits")
reject E_EXAMPLE "$tide" edit "$entry" --base "$base" --edits "$partial" --write
equal_tree old
receipt failing_example E_EXAMPLE
for mask in 1 2 3 4 5 6; do
    reset_project
    for i in 0 1 2; do
        if ((mask & (1 << i))); then cp "$work/new/${members[i]}" "$proj/${members[i]}"; fi
    done
    reject E_EXAMPLE "$tide" test "$entry"
done
receipt six_partial_revisions 'all failed the example'
reset_project

chmod a-w "$proj"
reject E_IO edit --write
chmod u+w "$proj"
equal_tree old
receipt journal_creation_denied old

# The kernel refuses the first staged data write. A pipe still carries the diagnostic.
rc=0
(ulimit -f 0; trap '' XFSZ; exec "${editor[@]}") 2>&1 | cat > "$work/limit" || rc=$?
test "$rc" != 0
jq -se 'length == 1 and .[0].code == "E_IO" and (.[0].message | startswith("[Errno 27]"))' "$work/limit" >/dev/null
equal_tree old
receipt staged_write_EFBIG old

# Two writable members precede the package. The third exchange fails with EACCES.
chmod a-w "${proj}/${package%/*}"
reject E_IO edit --write
grep -Fq "$package" "$work/err"
chmod u+w "${proj}/${package%/*}"
equal_tree old
edit --write > /dev/null
accept new
receipt third_exchange_denied 'old; retry committed'

# A raw writer changes a reachable source after staging. Preserve its bytes.
reset_project
cp -a "$work/old" "$work/drift"
printf '\n' >> "$work/drift/orders.tide"
"${gdb_base[@]}" -ex 'catch syscall linkat' -ex 'ignore 1 5' -ex run \
    -ex "shell cp \"$work/drift/orders.tide\" \"$proj/orders.tide\"" -ex 'disable 1' -ex continue \
    --args "${editor[@]}" > "$work/gdb" 2>&1
grep -Fq '"code":"E_REVISION"' "$work/gdb"
equal_tree drift
receipt stale_during_staging E_REVISION

while read -r label syscall skip raw expected; do
    reset_project
    kill_at "$syscall" "$skip" "${editor[@]}"
    test -d "$journal"
    test "$(raw_count)" = "$raw"
    # A directly opened package uses the same coordinator as its consumer.
    "$tide" check "$proj/$package" > /dev/null
    accept "$expected"
    if [[ $expected == old ]]; then edit --write > /dev/null; else reject E_REVISION edit --write; fi
    accept new
    jq -cn --arg case "$label" --argjson raw "$raw" --arg result "$expected" \
        '{case:$case,signal:"SIGKILL",raw_new_files:$raw,recovered:$result,retry:"verified"}'
done <<'CASES'
staging linkat 1 0 old
before_first_exchange renameat2 0 0 old
after_first_exchange renameat2 1 1 old
after_second_exchange renameat2 3 2 old
all_exchanged_before_commit renameat2 5 3 old
after_commit unlinkat 1 3 new
during_cleanup unlinkat 3 3 new
CASES

reset_project
kill_at renameat2 3 "${editor[@]}"
kill_at renameat2 1 "$bin/checker" --read-project "$entry" :checks.tide
test "$(raw_count)" = 1
test -d "$journal"
accept old
receipt interrupted_recovery 'old after second SIGKILL'

# Hold the writer at the first exchanged file until a checker is waiting in flock.
reset_project
mkfifo "$work/release"
"${gdb_base[@]}" -ex 'catch syscall renameat2' -ex 'ignore 1 1' -ex run \
    -ex "shell touch \"$work/ready\" && timeout 20 cat \"$work/release\"" \
    -ex 'disable 1' -ex continue --args "${editor[@]}" > "$work/gdb" 2>&1 &
writer=$!
for i in {1..500}; do [[ -f $work/ready ]] && break; sleep .01; done
test -f "$work/ready"
test "$(raw_count)" = 1
"$bin/checker" --read-project "$entry" :checks.tide > "$work/reader" &
reader=$!
waiting=false
for i in {1..500}; do
    if [[ $(cat "/proc/$reader/wchan" 2>/dev/null) == *lock* ]]; then waiting=true; break; fi
    sleep .01
done
echo release > "$work/release"
wait "$writer"
wait "$reader"
test "$waiting" = true
test "$(tail -n +2 "$work/reader" | sha256sum | cut -d' ' -f1)" = "$next"
accept new
receipt concurrent_reader 'blocked until complete new revision'

reset_project
edit --write > "$work/a" 2> "$work/ae" & first=$!
edit --write > "$work/b" 2> "$work/be" & second=$!
a=0; b=0
wait "$first" || a=$?
wait "$second" || b=$?
test "$((a+b))" = 1
cat "$work/a" "$work/b" | jq -se 'length == 1 and .[0].written == true' >/dev/null
cat "$work/ae" "$work/be" | jq -se 'length == 1 and .[0].code == "E_REVISION"' >/dev/null
accept new
receipt concurrent_writers 'one commit, one E_REVISION'
