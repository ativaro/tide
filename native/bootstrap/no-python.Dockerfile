FROM debian:trixie-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends xxd libcurl4t64 libpq5 && rm -rf /var/lib/apt/lists/*

FROM runtime AS toolchain
RUN apt-get update && apt-get install -y --no-install-recommends g++ make xz-utils libcurl4-openssl-dev libpq-dev libmicrohttpd-dev openssl && rm -rf /var/lib/apt/lists/*

FROM toolchain AS build
WORKDIR /src
COPY . .
# This filesystem contains both the runtime and all build dependencies.
RUN --network=none set -eu; \
    found=$(find /usr ! -type d \( -name python -o -name 'python[23]' -o -name 'python[23].[0-9]*' \
        -o -name 'libpython*.so*' -o -name 'libpython*.a' -o -name Python.h -o -path '*/python[23].*/os.py' \) -print -quit); \
    if [ -n "$found" ]; then echo "Unexpected Python component: $found" >&2; exit 1; fi; \
    test ! -e build; test ! -e experimente; \
    make -j2 test install DESTDIR=/stage; \
    extra=$(find /src /stage \( -name '*.py' -o -name '*.py[cowz]' -o -name __pycache__ -o -name 'libpython*' -o -name pyproject.toml \) -print -quit); \
    if [ -n "$extra" ]; then echo "Unexpected Python file: $extra" >&2; exit 1; fi; \
    readelf -ld /stage/usr/local/lib/tide/bin/* > /tmp/linkage; \
    if grep -Eq 'INTERP|\(NEEDED\)' /tmp/linkage; then cat /tmp/linkage >&2; exit 1; fi; \
    test "$(./tide test apps/balance.tide)" = '{"passed":3}'; \
    ./tide build apps/balance.tide /tmp/checkout-saldo; test "$(/tmp/checkout-saldo)" = 97; \
    /stage/usr/local/bin/tide build --aot /src/apps/report.tide /tmp/report-aot; \
    /stage/usr/local/bin/tide build --aot /src/apps/report_packages/json_report.tide /tmp/json-report-aot; \
    /stage/usr/local/bin/tide build --aot /src/apps/report_packages/stream_report.tide /tmp/stream-report-aot; \
    /stage/usr/local/bin/tide build --aot /src/apps/report_packages/report.tide /tmp/package-report-aot; \
    /stage/usr/local/bin/tide build --aot /src/native/bootstrap/fixtures/functions/aot_memory.tide /tmp/memory-aot; \
    /stage/usr/local/bin/tide build --aot /src/native/bootstrap/fixtures/functions/inclusive.tide /tmp/inclusive-aot

# Upgrade a legacy package without an interpreter and compare it to a clean install.
RUN --network=none set -eu; \
    pkg=/upgrade/usr/local/lib/tide; mods=$pkg/tide_lang; mkdir -p "$mods/__pycache__"; \
    touch "$pkg/compat-interpreter" "$pkg/reference-tide" "$mods/cli.py" "$mods/cli.pyc" \
        "$mods/cli.pyo" "$mods/__pycache__/cli.cpython-310.opt-1.pyc"; \
    printf 'local\n' > "$mods/local.py"; \
    make -s install DESTDIR=/upgrade; test "$(cat "$mods/local.py")" = local; test "$(ls -A "$mods")" = local.py; \
    rm "$mods/local.py"; make -s install DESTDIR=/upgrade; diff -r --no-dereference /stage /upgrade

FROM runtime AS installed
COPY --from=build /stage/usr/local /usr/local
COPY --from=build /tmp/json-report-aot /tmp/report-aot /tmp/package-report-aot /tmp/stream-report-aot /tmp/memory-aot /tmp/inclusive-aot /tmp/
RUN --network=none --mount=from=build,source=/src/apps,target=/apps,ro \
    --mount=from=build,source=/src/native/bootstrap/fixtures/functions,target=/fixtures,ro \
    --mount=from=build,source=/src/tide.lock,target=/tide.lock,ro \
    set -eu; test -z "$(command -v c++)"; test -z "$(command -v make)"; test -z "$(command -v python3)"; \
    tide --version > /tmp/version; grep -Eq '^TIDE [0-9]' /tmp/version; \
    tide test --help > /tmp/help; grep -Fq -- '--explain=executed' /tmp/help; \
    tide lock --json > /tmp/installed.lock; cmp /tide.lock /tmp/installed.lock; \
    tide describe '<=' --project /fixtures/inclusive.tide | grep -Fq '"operation":"<="'; \
    tide describe '>=' --project /fixtures/inclusive.tide | grep -Fq '"operation":">="'; \
    test "$(tide test /fixtures/inclusive.tide)" = '{"passed":8}'; \
    test "$(/tmp/inclusive-aot --inputs '{"a":-9223372036854775808,"b":9223372036854775807}')" = -1; \
    test "$(/tmp/inclusive-aot --inputs '{"a":9223372036854775807,"b":9223372036854775807}')" = 0; \
    tide build /fixtures/inclusive.tide /tmp/inclusive-fold bounded; \
    test "$(/tmp/inclusive-fold 7 -3 -2 -1 2 2 3)" = 8; \
    tide build /fixtures/inclusive.tide /tmp/inclusive-scan simulate; \
    test "$(/tmp/inclusive-scan -3 -2 -1 2 3)" = '[false,true,true,true,false]'; \
    tide describe fold --project /apps/balance.tide > /tmp/fold; grep -Fq '"operation":"fold"' /tmp/fold; \
    tide check /apps/balance.tide > /tmp/check; grep -Fq '"examples":3' /tmp/check; \
    tide fmt /apps/balance.tide > /tmp/fmt; cmp /apps/balance.tide /tmp/fmt; \
    tide modules /apps/reading_check.tide > /tmp/modules; grep -Fq '"modules":["readings.tide"]' /tmp/modules; \
    test "$(tide test /apps/balance.tide)" = '{"passed":3}'; \
    test "$(tide test /fixtures/variants.tide)" = '{"passed":10}'; \
    test "$(tide test /fixtures/collections.tide)" = '{"passed":5}'; \
    test "$(tide test /apps/space_invaders.tide)" = '{"passed":10}'; \
    state=$(tide run /apps/space_invaders.tide); \
    tide run /apps/space_invaders.tide --call draw --inputs "{\"world\":$state}" > /tmp/scene; \
    grep -Fq 'S P A C E   I N V A D E R S' /tmp/scene; \
    cp /apps/space_invaders.tide /tmp/game.tide; \
    sed '/^variant Phase$/{n;s/$/ intermission/;}' /apps/invaders_game.tide > /tmp/invaders_game.tide; \
    if tide check /tmp/game.tide >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; \
    for name in draw tick; do grep -Fq "\"definition\":\"$name\",\"variant\":\"Phase\",\"missing\":[\"intermission\"]" /tmp/error; done; \
    sed 's/if hurt (tag Phase respawn)/if hurt (tag Phase paused)/' /apps/invaders_game.tide > /tmp/invaders_game.tide; \
    if tide test /tmp/game.tide --diff --explain=executed >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"difference":{"path":"/mode","expected":"respawn","actual":"paused"}' /tmp/error; \
    grep -Fq '"execution":{"complete":true' /tmp/error; \
    test "$(tide test /apps/peak_lines.tide)" = '{"passed":3}'; \
    test "$(tide test /apps/nano_checks.tide)" = '{"passed":10}'; \
    test "$(tide test /fixtures/composite_pairs.tide)" = '{"passed":9}'; \
    test "$(tide test /fixtures/maps.tide)" = '{"passed":20}'; \
    tide describe map --project /fixtures/maps.tide | grep -Fq '"operation":"map"'; \
    test "$(tide run /apps/reading_check.tide --call first_invalid --inputs '{"rows":["1","x","3"]}')" = '{"some":2}'; \
    test "$(tide run /apps/summary.tide --call summarize --inputs '{"rows":["80","81","98"],"limit":80}')" = '{"above":2,"peak":{"some":98}}'; \
    test "$(tide run /apps/peak_lines.tide --call peak_lines --inputs '{"rows":["-8","-2","-2"]}')" = '{"some":[-2,2]}'; \
    test "$(tide run /apps/balance.tide)" = 97; \
    if tide run /apps/balance.tide >/dev/full 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    grep -Fxq 'Could not write TIDE output.' /tmp/error; \
    tide build /apps/balance.tide /tmp/saldo; test "$(/tmp/saldo)" = 97; \
    tide forms < /apps/balance.tide > /tmp/forms; grep -Fq '(+ total entry)' /tmp/forms; \
    tide context /apps/balance.tide --function balance > /tmp/context; grep -Fq '"definition":"balance"' /tmp/context; \
    tide hole /apps/balance.tide --function balance --node 2:1 > /tmp/hole; grep -Fq '"expected_type":"i"' /tmp/hole; \
    tide trace /apps/light.tide --example restart --step 2 > /tmp/trace; grep -Fq '"output":true' /tmp/trace; \
    sed 's/+ total entry/- total entry/' /apps/balance.tide > /tmp/balance.tide; \
    if tide test /tmp/balance.tide --explain > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"repair":{' /tmp/error; \
    if tide test /tmp/balance.tide --explain=executed > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"execution":{"complete":true,"branches":{}}' /tmp/error; \
    if tide test /tmp/balance.tide --diff --explain=nodes > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"nodes":[{"node":"2:38"' /tmp/error; \
    if tide test /tmp/balance.tide --diff --explain=candidates > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"candidates":[{"node":"2:38","op":"+"}]' /tmp/error; \
    if tide test /fixtures/surcharge_draft.tide --diff --explain=candidates >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"candidates":[{"node":"2:1","replace":"(* units (+ rate 2))"}]' /tmp/error; \
    probes=$(printf '%s\n' '{"a":0,"b":1}' '{"a":1,"b":1}'); \
    if tide test /fixtures/remainder_draft.tide --diff --explain=candidates --probes "$probes" >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"counterexample":{"inputs":{"a":1,"b":1},"outcomes":[{"edit":{"node":"2:1","op":"div"},"actual":1},{"edit":{"node":"2:1","op":"mod"},"actual":0}]}' /tmp/error; \
    mkdir /tmp/counters; \
    printf 'use route\n\nmain a:i b:i > i\nroute a b\n\nexample sample main\n{"inputs":{"a":42,"b":4},"expect":413}\n\nexample later main\n{"inputs":{"a":7,"b":6},"expect":65}\n\nexample small main\n{"inputs":{"a":6,"b":5},"expect":54}\n' > /tmp/counters/panel.tide; \
    printf 'use rulebook\n\nroute a:i b:i > i\n+ (compute a b) (+ b 1)\n' > /tmp/counters/route.tide; \
    printf 'compute a:i b:i > i\n* (+ a 1) 10\n' > /tmp/counters/rulebook.tide; \
    if tide test /tmp/counters/panel.tide --diff --explain=candidates --pairs --probes "$probes" > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    edits='[{"node":"route.tide:4:18","op":"-"},{"node":"rulebook.tide:2:4","op":"-"}]'; \
    grep -Fq "\"pair_checks\":{\"tested\":64,\"truncated\":false},\"pair_candidates\":[$edits]" /tmp/error; \
    base=$(sed -n 's/.*"revision":"\([0-9a-f]\{64\}\)".*/\1/p' /tmp/error); test -n "$base"; \
    tide edit /tmp/counters/panel.tide --base "$base" --edits "$edits" > /tmp/edit; \
    grep -Fq '"examples":{"passed":3},"contract_changes":[],"written":false,"files":[' /tmp/edit; \
    grep -Fq '"file":"route.tide","source":"use rulebook\n\nroute a:i b:i > i\n+ (compute a b) (- b 1)\n"' /tmp/edit; \
    grep -Fq '"file":"rulebook.tide","source":"compute a:i b:i > i\n* (- a 1) 10\n"' /tmp/edit; \
    tide edit /tmp/counters/panel.tide --base "$base" --edits "$edits" --write > /tmp/saved; \
    sed 's/"written":false/"written":true/' /tmp/edit | cmp - /tmp/saved; \
    test "$(tide test /tmp/counters/panel.tide)" = '{"passed":3}'; \
    if tide edit /tmp/counters/panel.tide --base "$base" --edits "$edits" --write > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"code":"E_REVISION"' /tmp/error; \
    mkdir /tmp/autoprobe; \
    printf 'use calc\n\nmain a:i b:i > i\n- (material a b) b\n\nexample square main\n{"inputs":{"a":2,"b":2},"expect":8}\n' > /tmp/autoprobe/panel.tide; \
    printf 'material a:i b:i > i\n- a b\n' > /tmp/autoprobe/calc.tide; \
    if tide test /tmp/autoprobe/panel.tide --diff --explain=candidates --pairs --probes '{"b":2,"a":2}' --probe-range '{"a":[1,3],"b":[1,3]}' > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"counterexample":{"inputs":{"a":1,"b":1}' /tmp/error; \
    grep -Fq '"probes_checked":1,"generated_probes_checked":1,"counterexample_source":"generated"' /tmp/error; \
    sed -i 's/"expect":8}/"expect":8,"requires":{"a":{"gt":0,"lt":4},"b":{"ge":1,"le":3}}}/' /tmp/autoprobe/panel.tide; \
    if tide test /tmp/autoprobe/panel.tide --diff --explain=candidates --pairs --probes '{"a":0,"b":1}' > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"counterexample":{"inputs":{"a":1,"b":1}' /tmp/error; \
    grep -Fq '"probes_checked":1,"generated_probes_checked":1,"counterexample_source":"generated","probe_range":{"a":[1,3],"b":[1,3]}' /tmp/error; \
    sed -i 's/"lt":4/"eq":"b"/' /tmp/autoprobe/panel.tide; \
    if tide test /tmp/autoprobe/panel.tide --diff --explain=candidates --pairs --probes '{"a":2,"b":1}' > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"counterexample":{"inputs":{"a":1,"b":1}' /tmp/error; \
    grep -Fq '"probes_checked":1,"generated_probes_checked":1,"counterexample_source":"generated","probe_range":{"a":[1,3],"b":[1,3]}' /tmp/error; \
    base=$(sha256sum /tmp/balance.tide); \
    tide edit /tmp/balance.tide --base "${base%% *}" --edits '[{"node":"2:38","op":"+"}]' --write > /tmp/edit; \
    cmp /apps/balance.tide /tmp/balance.tide; test "$(tide test /tmp/balance.tide)" = '{"passed":3}'; \
    for app in nano space_invaders; do \
        if tide play "/apps/$app.tide" >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
        test ! -s /tmp/out; grep -Fq '"code":"E_BACKEND"' /tmp/error; \
    done; \
    printf '80\r\n81\r\n98\r\n' > /tmp/readings; \
    test "$(tide run /apps/report.tide --inputs '{"limit":80}' --read input=/tmp/readings)" = '{"above":2,"peak":{"some":98}}'; \
    test "$(tide test /apps/report_packages/json_report.tide)" = '{"passed":9}'; \
    printf '%s' '{"limits":{"A":79},"readings":[{"sensor":"A","value":80,"future":[0,null]}]}' > /tmp/measurement.json; \
    test "$(/tmp/json-report-aot --inputs '{"limit":80}' --read input=/tmp/measurement.json)" = '{"above":1,"peak":{"some":80}}'; \
    printf '%s' '{"limits":{"A~/B":null},"readings":[]}' > /tmp/measurement.json; \
    if /tmp/json-report-aot --inputs '{"limit":80}' --read input=/tmp/measurement.json >/tmp/out 2>/tmp/error; then exit 1; fi; \
    grep -Fq '"issue":{"path":"/limits/A~0~1B","expected":"i","actual":"null"}' /tmp/error; \
    test "$(tide test /apps/report_packages/stream_report.tide)" = '{"passed":7}'; \
    printf '\377' > /tmp/bad-source.tide; \
    if tide test /tmp/bad-source.tide >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fxq '{"file":"/tmp/bad-source.tide","code":"E_UTF8","message":"Expected UTF-8 source"}' /tmp/error; \
    test "$(/tmp/stream-report-aot --inputs '{"bytes":12,"limit":80}' --read input=/tmp/readings)" = '{"above":2,"peak":{"some":98}}'; \
    test "$(tide test /apps/report_packages/report.tide)" = '{"passed":6}'; \
    tide modules /apps/report_packages/report.tide --json > /tmp/packages; \
    grep -Fq '"package":"rowtext","version":"2.0.0"' /tmp/packages; \
    grep -Fq '"package":"measurements","version":"1.3.0"' /tmp/packages; \
    test "$(tide run /apps/report_packages/report.tide --inputs '{"limit":80}' --read input=/tmp/readings)" = '{"above":2,"peak":{"some":98}}'; \
    test "$(/tmp/package-report-aot --inputs '{"limit":80}' --read input=/tmp/readings)" = '{"above":2,"peak":{"some":98}}'; \
    if tide run /apps/report_packages/report.tide --call measurements.decode_measurement --inputs '{"line":"98","row":1}' > /tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    grep -Fq '"code":"E_ENTRY"' /tmp/error; \
    test "$(/tmp/report-aot --read=input=/tmp/readings --inputs='{"limit":80}')" = '{"above":2,"peak":{"some":98}}'; \
    if /tmp/report-aot --read input=/tmp/readings --inputs '{' >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fxq '{"code":"E_BACKEND","message":"This invocation is unavailable in the native TIDE package."}' /tmp/error; \
    printf '80\nx\n' > /tmp/bad-reading; \
    if /tmp/report-aot --read input=/tmp/bad-reading --inputs '{"limit":80}' >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fxq '{"file":"readings.tide","code":"E_DATA","message":"A value is required","line":2,"column":1,"reason":"invalid_integer","input_line":2}' /tmp/error; \
    { printf '%0286d81\n' 0; yes 81 | head -n 3423; printf '80\n'; } > /tmp/work-exact; \
    test "$(/tmp/report-aot --read input=/tmp/work-exact --inputs '{"limit":80}')" = '{"above":3424,"peak":{"some":81}}'; \
    { printf '%0286d81\n%030d81\n' 0 0; yes 81 | head -n 3422; printf '80\n'; } > /tmp/work-extra; \
    if /tmp/report-aot --read input=/tmp/work-extra --inputs '{"limit":80}' >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fxq '{"file":"readings.tide","code":"E_LIMIT","message":"Work budget exhausted","line":5,"column":51}' /tmp/error; \
    { printf '\r\n\r\n\n\n\n'; head -c 131060 /dev/zero | tr '\0' x; printf '\n'; } > /tmp/memory-exact; \
    test "$(/tmp/memory-aot --read input=/tmp/memory-exact)" = 6; \
    { printf x; cat /tmp/memory-exact; } > /tmp/memory-extra; \
    if /tmp/memory-aot --read input=/tmp/memory-extra >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fxq '{"file":"/src/native/bootstrap/fixtures/functions/aot_memory.tide","code":"E_LIMIT","message":"Guest allocation budget exhausted","line":3,"column":14}' /tmp/error; \
    if tide run /apps/report.tide --inputs '{"limit":80}' >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"code":"E_CAPABILITY"' /tmp/error; \
    mkdir /tmp/report; cp /apps/report.tide /apps/readings.tide /tmp/report/; \
    sed 's/(> value limit)/(< value limit)/' /apps/summary.tide > /tmp/report/summary.tide; \
    if tide test /tmp/report/report.tide --diff --explain=executed >/tmp/out 2>/tmp/error; then exit 1; else test "$?" = 1; fi; \
    test ! -s /tmp/out; grep -Fq '"difference":{"path":"/above","expected":2,"actual":0}' /tmp/error; \
    base=$(sed -n 's/.*"revision":"\([0-9a-f]\{64\}\)".*/\1/p' /tmp/error); test -n "$base"; \
    tide edit /tmp/report/report.tide --base "$base" --edits '[{"node":"summary.tide:10:12","op":">"}]' --write > /tmp/edit; \
    cmp /apps/summary.tide /tmp/report/summary.tide; \
    test "$(tide test /tmp/report/report.tide)" = '{"passed":3}'; \
    test "$(tide run /tmp/report/report.tide --inputs '{"limit":80}' --read input=/tmp/readings)" = '{"above":2,"peak":{"some":98}}'; \
    printf '\377' > /tmp/readings; \
    test "$(tide run /fixtures/read_grants.tide --call valid_or --read input=/tmp/readings)" = '"invalid UTF-8"'
