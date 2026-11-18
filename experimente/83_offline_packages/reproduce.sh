#!/usr/bin/env bash
set -euo pipefail
export GIT_NO_LAZY_FETCH=1
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
study=$root/experimente/83_offline_packages
out=$(realpath -m "${1:-build/stage14-results}")
mkdir -p "$out" "$root/build"
work=$(mktemp -d "$root/build/offline-packages.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
# Only host system headers, binaries and libraries enter the empty root.
jail=(bwrap --die-with-parent --unshare-net --unshare-pid --ro-bind /usr /usr --tmpfs /usr/local
    --symlink usr/bin /bin --symlink usr/lib /lib --symlink usr/lib /lib64 --proc /proc --dev /dev
    --tmpfs /tmp --dir /etc --dir /home/builder --clearenv --setenv HOME /home/builder --setenv LC_ALL C
    --setenv TZ UTC --setenv PATH /tools/bin:/usr/bin)
toolroot="$work/toolchain"
mkdir "$toolroot" "$work/tool-build"
"${jail[@]}" --ro-bind "$root" /src --bind "$work/tool-build" /src/build --bind "$toolroot" /dest \
    --chdir /src -- make -sj4 install-native DESTDIR=/dest >&2
tool=$toolroot/usr/local/bin/tide
store=$root/packages
fixture=$root/native/bootstrap/fixtures/offline_packages
old=cb93e76a862da076de5858b458e1b2eabbf481a9
declare -A folder=([orders]=orders [report]=report_packages)
declare -A sources=([orders]='import model store checks' [report]='json_report json_readings')
# Only the application sources and trusted locks are exported. Consumers receive no vendor tree.
for app in orders report; do
    dir=apps/${folder[$app]}
    for version in old new; do
        dest="$work/$version/$app"; mkdir -p "$dest"
        for module in ${sources[$app]}; do
            if [[ $version == old ]]; then git show "$old:$dir/$module.tide" > "$dest/$module.tide"
            else cp "$dir/$module.tide" "$dest/"; fi
        done
        if [[ $version == old ]]; then
            awk 'FNR==NR{old=$0;next} /  vendor\/jsoninput\//{print old;next} {print}' "$study/v1.packages" "$dir/tide.packages" >"$dest/tide.packages"
            "$tool" lock --packages "$dest/tide.packages" >"$dest/tide.lock"
        else
            cp "$dir/tide.packages" "$dir/tide.lock" "$dest/"
            "$tool" lock --packages "$dest/tide.packages" | cmp - "$dest/tide.lock"
        fi
    done
done
box() {
    local project=$1 location=$2 distribution=$3; shift 3
    local mounts=()
    if [[ $distribution != - ]]; then mounts+=(--ro-bind "$distribution" /dist); fi
    "${jail[@]}" --ro-bind "$toolroot/usr/local" /tools --ro-bind "$study" /study \
        --bind "$project" "$location" "${mounts[@]}" --chdir "$location" -- "$@"
}
results="$work/results.jsonl"
build_pair() {
    local state=$1 mount=$2 distribution=$3 phase=$4
    local jobs=() rc=0
    for app in orders report; do
        box "$work/$state/$app" "$mount/$app" "$distribution" bash /study/project-run.sh "$app" "$phase" >"$work/$state/$app.receipt" & jobs+=("$!")
    done
    for pid in "${jobs[@]}"; do wait "$pid" || rc=1; done
    (( rc==0 ))
    cat "$work/$state/"{orders,report}.receipt >>"$results"
}
cp -r "$work/new" "$work/independent-a"
cp -r "$work/new" "$work/independent-b"
touch -d @946684800 "$work/independent-a/"{orders,report}/*.tide
touch -d @1704067200 "$work/independent-b/"{orders,report}/*.tide
build_pair independent-a /first/projects "$store" fresh_a
build_pair independent-b /separate/checkout "$store" fresh_b
for app in orders report; do cmp "$work/independent-a/$app/app" "$work/independent-b/$app/app"; done
cp -r "$work/old" "$work/migration"
build_pair migration /migration "$store" before_upgrade
for app in orders report; do
    p="$work/migration/$app"; cp "$p/app" "$work/$app.before"
    cp "$work/new/$app/"{tide.lock,tide.packages} "$p/"
    box "$p" /migration/project "$store" tide pkg install . /dist >/dev/null
    entry=import.tide; pin=import.tide
    if [[ $app == report ]]; then entry=json_report.tide; pin=json_readings.tide; fi
    sed -i 's/jsoninput@1\.0\.0/jsoninput@2.0.0/' "$p/$pin"
    if box "$p" /migration/project - tide check "$entry" >"$work/stdout" 2>"$work/err"; then exit 1; fi
    test ! -s "$work/stdout"
    jq -ce --arg project "$app" 'select(.code=="E_TYPE")|{phase:"pin_only_upgrade",project:$project,code,file,line,column}' "$work/err" >>"$results"
    cp "$work/new/$app/"*.tide "$p/"
done
build_pair migration /migration "$store" after_upgrade
for app in orders report; do
    p="$work/migration/$app"; cmp "$p/app" "$work/independent-a/$app/app"
    cp "$work/old/$app/"{*.tide,tide.lock,tide.packages} "$p/"
done
build_pair migration /migration - rollback_without_store
for app in orders report; do cmp "$work/migration/$app/app" "$work/$app.before"; done
reject() {
    local phase=$1 project=$2 location=$3 dist=$4; shift 4
    if box "$project" "$location" "$dist" "$@" >"$work/stdout" 2>"$work/err"; then echo "Unexpected success in $phase" >&2; return 1; fi
    test ! -s "$work/stdout"
    jq -ce --arg phase "$phase" 'select(.code=="E_PACKAGE_LOCK")|{phase:$phase,code,file,message}' "$work/err" >>"$results"
}
cp -r "$store" "$work/changed-store"
# The last listed report dependency is damaged. Earlier verified files must stay unpublished.
printf '\n' >>"$work/changed-store/rowtext/2.0.0/package.tide"
cp -r "$work/new/report" "$work/clean-report"
reject distribution_last_file "$work/clean-report" /consumer "$work/changed-store" tide pkg install . /dist
test ! -e "$work/clean-report/vendor"
cp -r "$store" "$work/changed-json"
printf '\n' >>"$work/changed-json/jsoninput/2.0.0/package.tide"
for app in orders report; do
    p="$work/independent-b/$app"; path=vendor/jsoninput/2.0.0/package.tide
    e=import.tide; suite=checks.tide; [[ $app == orders ]] || { e=json_report.tide; suite=$e; }
    reject "changed_distribution_$app" "$p" /consumer "$work/changed-json" tide pkg install . /dist
    cp "$work/changed-json/jsoninput/2.0.0/package.tide" "$p/$path"
    for command in check run test build; do
        case $command in test) args=(test "$suite");; build) args=(build --aot "$e" app);; *) args=("$command" "$e");; esac
        reject "changed_vendor_${app}_$command" "$p" /consumer - tide "${args[@]}"
    done
    cmp "$p/app" "$work/independent-a/$app/app"
    reject "changed_existing_install_$app" "$p" /consumer "$store" tide pkg install . /dist
    # Changing the manifest to match the modified file still disagrees with the trusted tool lock.
    (cd "$p"; sha256sum "$path" >new-row; sed -i '1d' tide.packages; cat new-row >>tide.packages)
    reject "changed_manifest_$app" "$p" /consumer - tide check "$e"
    rm "$p/tide.packages"
    reject "missing_manifest_$app" "$p" /consumer - tide check "$e"
done
p="$work/siblings"; mkdir "$p"
cp "$fixture/"{entry.tide,tide.packages} "$p/"
"$tool" lock --packages "$p/tide.packages" >"$p/tide.lock"
for attempt in first second; do
    box "$p" /consumer "$fixture/store" tide pkg install . /dist >"$work/install-$attempt" &
    if [[ $attempt == first ]]; then first=$!; else second=$!; fi
done
wait "$first"; wait "$second"
jq -cse 'map(.installed)|sort|select(.==[0,2])|{phase:"concurrent_install",installed:.}' "$work/"install-{first,second} >>"$results"
[[ $(box "$p" /consumer - tide test entry.tide) == '{"passed":1}' ]]
printf '\n' >>"$p/vendor/offset/1.0.0/delta.tide"
reject changed_sibling "$p" /consumer - tide test entry.tide
sed -i '/delta\.tide$/d' "$p/tide.packages"
"$tool" lock --packages "$p/tide.packages" >"$p/tide.lock"
reject unpinned_sibling "$p" /consumer - tide check entry.tide
jq -cn --arg tool "$("$tool" --version)" --arg cc "$(c++ -dumpfullversion)" --arg sys "$(uname -sm)" \
  --arg compiler "$(sha256sum "$toolroot/usr/local/lib/tide/bin/checker" | cut -d' ' -f1)" \
  --arg runtime "$(sha256sum "$toolroot/usr/local/lib/tide/native/aot-runtime.cpp" | cut -d' ' -f1)" \
  '{phase:"environment",tool:$tool,compiler_sha256:$compiler,runtime_source_sha256:$runtime,cxx:$cc,platform:$sys,network:"private namespace without routes"}' >>"$results"
# The package edit and caller edit must remain one revision if a locked package rejects the write.
p="$work/locked-edit"; cp -r native/bootstrap/fixtures/atomic_edit "$p"
(cd "$p"; sha256sum vendor/fees/1.0.0/package.tide >tide.packages)
"$tool" lock --packages "$p/tide.packages" >"$p/tide.lock"
base=$(box "$p" /consumer - tide check checks.tide | jq -r .revision)
reject locked_multi_file_edit "$p" /consumer - tide edit checks.tide --base "$base" --edits "$(cat "$p/edits.json")" --write
[[ $(box "$p" /consumer - tide check checks.tide | jq -r .revision) == "$base" ]]
jq -se 'map(select(has("elf_sha256")))|length==10' "$results" >/dev/null
mkdir -p "$out/bin"
install -m755 "$work/independent-a/orders/app" "$out/bin/order-import"
install -m755 "$work/independent-a/report/app" "$out/bin/measurement-report"
cp "$results" "$out/results.jsonl"
