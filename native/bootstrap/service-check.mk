.PHONY: check-language-io check-postgres

check-language-io: checker catalog aot-runtime
	@set -eu; tmp=$$(mktemp -d "$(abspath $(BUILD))/language-io.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	f=native/bootstrap/fixtures/functions; \
	for pair in api_values:9 exports:3 iteration:7; do test "$$(./tide test "$$f/$${pair%:*}.tide")" = "{\"passed\":$${pair#*:}}"; done; \
	test "$$(./tide test apps/report_packages/measurement_service.tide)" = '{"passed":3}'; \
	./tide build --aot "$$f/exports.tide" "$$tmp/export"; \
	for mode in run aot; do \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$f/exports.tide"; else set -- "$$tmp/export"; fi; \
	    echo previous > "$$tmp/$$mode.txt"; test "$$("$$@" --db db=:memory: --write output="$$tmp/$$mode.txt")" = 8; \
	    test "$$(cat "$$tmp/$$mode.txt")" = 12502500; \
	done; \
	./tide build --aot "$$f/iteration.tide" "$$tmp/depth" depth; \
	for mode in run aot; do \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$f/iteration.tide" --call depth; else set -- "$$tmp/depth"; fi; \
	    test "$$("$$@" --inputs '{"n":48}')" = 48; \
	    if "$$@" --inputs '{"n":49}' 2>"$$tmp/$$mode.err"; then exit 1; fi; grep -q '"E_LIMIT"' "$$tmp/$$mode.err"; \
	done; cmp "$$tmp/run.err" "$$tmp/aot.err"; \
	./tide build --aot apps/light.tide "$$tmp/light"; test "$$("$$tmp/light")" = "$$(./tide run apps/light.tide)"; \
	./tide build --aot "$$f/maps.tide" "$$tmp/divide" divide; \
	test "$$("$$tmp/divide" --inputs '{"values":[3,2]}')" = '[4,6]'; \
	for mode in run aot; do \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$f/maps.tide" --call divide; else set -- "$$tmp/divide"; fi; \
	    if "$$@" --inputs '{"values":[3,0]}' 2> "$$tmp/$$mode.err"; then exit 1; fi; grep -Fq '"map_index":1' "$$tmp/$$mode.err"; \
	done; cmp "$$tmp/run.err" "$$tmp/aot.err"; \
	echo 'Decimals, timestamps, JSON, cursor, atomic write, recursion, map and AOT rule OK'

# Uses a disposable PostgreSQL cluster owned by the current unprivileged user.
check-postgres: checker catalog aot-runtime
	@set -eu; tmp=$$(mktemp -d); server=; tls=; locker=; active=; pg=; \
	PATH="$$(pg_config --bindir):$$PATH"; export PATH; \
	trap 'for pid in $$server $$tls $$locker $$active; do kill "$$pid" 2>/dev/null || :; done; if [ -n "$$pg" ]; then pg_ctl -D "$$tmp/db" -m immediate -w stop >/dev/null; fi; rm -rf "$$tmp"' EXIT; \
	initdb -D "$$tmp/db" --locale=C --encoding=UTF8 -A trust -U tide > "$$tmp/init.log"; \
	pg_ctl -D "$$tmp/db" -l "$$tmp/pg.log" -o "-k $$tmp -c listen_addresses=''" -w start >/dev/null; pg=yes; \
	dsn="host=$$tmp dbname=postgres user=tide"; pgapp=native/bootstrap/fixtures/functions/postgres_report.tide; \
	params='{"sensor":"O’Neil"}'; ./tide build --aot "$$pgapp" "$$tmp/pgapp"; \
	./tide run "$$pgapp" --pg pg="$$dsn" --inputs "$$params" > "$$tmp/run.json"; "$$tmp/pgapp" --pg pg="$$dsn" --inputs "$$params" > "$$tmp/aot.json"; \
	cmp "$$tmp/run.json" "$$tmp/aot.json"; grep -Fq '"temperature":21.75,"observed":"2024-02-29T00:00:00Z","note":{"none":true}' "$$tmp/run.json"; \
	app=apps/report_packages/measurement_service.tide; ./tide run "$$app" --call prepare --pg pg="$$dsn" > /dev/null; \
	./tide build --service "$$app" "$$tmp/service" persist; ./tide build --aot "$$app" "$$tmp/publish" publish; \
	"$$tmp/service" --listen 127.0.0.1:0 --workers 4 --pg pg="$$dsn" > /dev/null 2>"$$tmp/listen" & server=$$!; \
	for n in $$(seq 1 150); do addr=$$(sed -n 's/^LISTEN //p' "$$tmp/listen"); [ -z "$$addr" ] || break; sleep .05; done; test -n "$$addr"; \
	url="http://$$addr/measurements"; sample='{"temperature":21.75,"measured":"2024-02-29T01:00:00+01:00"}'; jobs=; \
	for n in $$(seq 1 8); do (test "$$(curl -sS --noproxy '*' --max-time 8 -o /dev/null -w '%{http_code}' -H "X-Measurement-Id: $$n" --data "$$sample" "$$url")" = 201) & jobs="$$jobs $$!"; done; \
	for child in $$jobs; do wait "$$child"; done; \
	test "$$(curl -sS --noproxy '*' --max-time 5 -o /dev/null -w '%{http_code}' -H 'X-Measurement-Id: invalid' --data '{' "$$url")" = 422; \
	openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=localhost -addext 'subjectAltName=IP:127.0.0.1' -keyout "$$tmp/key" -out "$$tmp/cert" 2>/dev/null; \
	socat -d -d "OPENSSL-LISTEN:0,bind=127.0.0.1,cert=$$tmp/cert,key=$$tmp/key,verify=0,fork,reuseaddr" "TCP4:$$addr" </dev/null > /dev/null 2>"$$tmp/tls.log" & tls=$$!; \
	for n in $$(seq 1 100); do port=$$(sed -n 's/.*listening on AF=2 127\.0\.0\.1:\([0-9]*\).*/\1/p' "$$tmp/tls.log" | head -1); [ -z "$$port" ] || break; sleep .05; done; test -n "$$port"; \
	export TIDE_HTTPS_CA_FILE="$$tmp/cert"; params="{\"id\":\"tide\",\"sample\":$$sample}"; origin="api=https://127.0.0.1:$$port"; \
	test "$$(./tide run "$$app" --call publish --https "$$origin" --inputs "$$params")" = 201; \
	test "$$("$$tmp/publish" --https "$$origin" --inputs "$$params")" = 200; \
	test "$$(curl -fsS --noproxy '*' --max-time 5 "$$url" | awk -F '"temperature":21.75' '{print NF-1}')" = 9; \
	mkfifo "$$tmp/gate"; exec 7<>"$$tmp/gate"; psql "$$dsn" -XqAt -v ON_ERROR_STOP=1 < "$$tmp/gate" > "$$tmp/locked" & locker=$$!; \
	printf 'BEGIN;\nLOCK measurements IN ACCESS EXCLUSIVE MODE;\n\\echo LOCKED\n' >&7; \
	for n in $$(seq 1 100); do grep -q LOCKED "$$tmp/locked" && break; sleep .02; done; grep -q LOCKED "$$tmp/locked"; \
	curl -s --noproxy '*' --max-time 8 "$$url" > /dev/null & active=$$!; \
	locked=0; for n in $$(seq 1 80); do locked=$$(psql "$$dsn" -XqAtc "SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='Lock' AND query LIKE 'SELECT temperature,measured FROM measurements%'"); [ "$$locked" = 0 ] || break; sleep .02; done; test "$$locked" = 1; \
	test "$$(curl -sS --noproxy '*' --max-time 2 -o /dev/null -w '%{http_code}' "http://$$addr/missing")" = 404; \
	kill -TERM "$$server"; for n in $$(seq 1 60); do kill -0 "$$server" 2>/dev/null || break; sleep .04; done; \
	if kill -0 "$$server" 2>/dev/null; then echo 'Cancellation exceeded the bound with the database lock held' >&2; exit 1; fi; \
	wait "$$server"; server=; wait "$$active" || :; active=; printf 'ROLLBACK;\n\\q\n' >&7; wait "$$locker"; locker=; \
	echo 'PostgreSQL, TLS POST, idempotence, concurrent requests and in-flight cancellation OK'
