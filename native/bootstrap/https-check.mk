.PHONY: check-https
check-https: checker catalog aot-runtime
	@set -eu; tmp=$$(mktemp -d "$(abspath $(BUILD))/https.XXXXXXXX"); server=; slow=; \
	trap 'for pid in $$server $$slow; do kill "$$pid" 2>/dev/null || :; wait "$$pid" 2>/dev/null || :; done; rm -rf "$$tmp"' EXIT; \
	app=apps/report_packages/api_report.tide; \
	test "$$(./tide test "$$app")" = '{"passed":4}'; \
	./tide build --aot "$$app" "$$tmp/import"; \
	openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=tide-fixture -addext 'subjectAltName=IP:127.0.0.1' -keyout "$$tmp/key" -out "$$tmp/ca.pem" 2>/dev/null; \
	(cd "$$tmp"; exec openssl s_server -accept 127.0.0.1:0 -cert ca.pem -key key -HTTP) </dev/null > "$$tmp/server.log" 2>&1 & server=$$!; \
	for n in $$(seq 1 100); do port=$$(sed -n 's/^ACCEPT 127.0.0.1://p' "$$tmp/server.log" | head -1); [ -z "$$port" ] || break; sleep .05; done; test -n "$$port"; \
	mkfifo "$$tmp/gate"; exec 7<>"$$tmp/gate"; \
	openssl s_server -accept 127.0.0.1:0 -cert "$$tmp/ca.pem" -key "$$tmp/key" -ign_eof < "$$tmp/gate" > "$$tmp/slow.log" 2>&1 & slow=$$!; \
	for n in $$(seq 1 100); do slowport=$$(sed -n 's/^ACCEPT 127.0.0.1://p' "$$tmp/slow.log" | head -1); [ -z "$$slowport" ] || break; sleep .05; done; test -n "$$slowport"; \
	reply() { printf 'HTTP/1.0 %s\r\nContent-Type: application/json\r\n\r\n%s' "$$1" "$$2" > "$$tmp/$$3"; }; \
	params='{"headers":{"Authorization":"Bearer local-fixture"},"source":"station","limit":80}'; \
	for mode in run aot; do \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$app"; else set -- "$$tmp/import"; fi; \
	    set -- "$$@" --db "db=$$tmp/$$mode.db" --inputs "$$params"; \
	    for reason in https_timeout https_certificate; do \
	        case $$reason in https_timeout) testorigin="127.0.0.1:$$slowport";; https_certificate) testorigin="localhost:$$port";; esac; \
	        if TIDE_HTTPS_CA_FILE="$$tmp/ca.pem" "$$@" --https "api=https://$$testorigin" > "$$tmp/out" 2> "$$tmp/$$mode.$$reason"; then exit 1; fi; \
	        grep -Fq "\"reason\":\"$$reason\"" "$$tmp/$$mode.$$reason"; \
	    done; \
	    set -- "$$@" --https "api=https://127.0.0.1:$$port"; \
	    reply '200 OK' '{"readings":[{"id":"1","sensor":"A","value":7}],"next":"/second"}' measurements; \
	    reply '200 OK' '{"readings":[{"id":"2","sensor":"A","value":92}]}' second; \
	    if TIDE_HTTPS_CA_FILE=/dev/null "$$@" >/dev/null 2>/dev/null; then exit 1; fi; \
	    for n in 1 2; do test "$$(TIDE_HTTPS_CA_FILE="$$tmp/ca.pem" "$$@")" = '{"above":1,"peak":{"some":92}}'; done; \
	    reply '200 OK' '{"readings":[{"id":"3","sensor":"A","value":99}],"next":"/second"}' measurements; \
	    for reason in http_status invalid_json sqlite_constraint; do \
	        case $$reason in http_status) reply '503 Unavailable' '{}' second;; invalid_json) reply '200 OK' '{' second;; sqlite_constraint) reply '200 OK' '{"readings":[{"id":"4","sensor":"","value":3}]}' second;; esac; \
	        if TIDE_HTTPS_CA_FILE="$$tmp/ca.pem" "$$@" > "$$tmp/out" 2> "$$tmp/$$mode.$$reason"; then exit 1; else test "$$?" = 1; fi; \
	        test ! -s "$$tmp/out"; grep -Fq "\"reason\":\"$$reason\"" "$$tmp/$$mode.$$reason"; \
	    done; \
	    test "$$(./tide run "$$app" --call by_sensor --db "db=$$tmp/$$mode.db" --inputs '{"sensor":"A"}')" = '[{"sensor":"A","value":7,"note":{"none":true}},{"sensor":"A","value":92,"note":{"none":true}}]'; \
	done; \
	for reason in https_timeout https_certificate http_status invalid_json sqlite_constraint; do cmp "$$tmp/run.$$reason" "$$tmp/aot.$$reason"; done; echo 'HTTPS import, retries and rollback OK (run, test, AOT)'
