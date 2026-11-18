.PHONY: check-package-types
check-package-types: checker catalog aot-runtime
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/package-types.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	fixtures=native/bootstrap/fixtures/package_types; \
	for pin in 1.0.0 2.0.0; do pkg=vendor/jsoninput/$$pin/package.tide; cmp "apps/orders/$$pkg" "apps/report_packages/$$pkg"; done; \
	cp -R apps/orders/. "$$tmp"; cp -R "$$fixtures/." "$$tmp"; \
	./tide lock --packages "$$tmp/tide.packages" > "$$tmp/tide.lock"; \
	p="$$tmp/offline"; mkdir "$$p"; f=native/bootstrap/fixtures/offline_packages; \
	cp "$$f/entry.tide" "$$f/tide.packages" "$$p/"; ./tide lock --packages "$$p/tide.packages" > "$$p/tide.lock"; \
	test "$$(./tide pkg install "$$p" "$$f/store")" = '{"verified":2,"installed":2}'; \
	test "$$(./tide test "$$p/entry.tide")" = '{"passed":1}'; \
	echo >> "$$p/vendor/offset/1.0.0/delta.tide"; \
	if ./tide test "$$p/entry.tide" > "$$tmp/out" 2> "$$tmp/err"; then exit 1; fi; \
	grep -Fq '"file":"vendor/offset/1.0.0/delta.tide","code":"E_PACKAGE_LOCK"' "$$tmp/err"; \
	test "$$(./tide test "$$tmp/binding.tide")" = '{"passed":3}'; \
	test "$$(./tide test "$$tmp/v2_reader.tide")" = '{"passed":5}'; \
	sed 's/^use jsoninput@1\.0\.0/use jsoninput@2.0.0/' "$$tmp/binding.tide" > "$$tmp/mixed.tide"; \
	if ./tide check "$$tmp/mixed.tide" > "$$tmp/out" 2> "$$tmp/err"; then exit 1; fi; \
	grep -Fq '"code":"E_PACKAGE","message":"Conflicting versions of jsoninput: 1.0.0 and 2.0.0"' "$$tmp/err"; \
	for mode in check run test aot; do \
	    set -- ./tide "$$mode" "$$tmp/wrong_order.tide"; \
	    if [ "$$mode" = aot ]; then set -- ./tide build --aot "$$tmp/wrong_order.tide" "$$tmp/rejected"; fi; \
	    if "$$@" > "$$tmp/out" 2> "$$tmp/err"; then exit 1; else test "$$?" = 1; fi; \
	    test ! -s "$$tmp/out"; test ! -e "$$tmp/rejected"; \
	    grep -Fq "\"file\":\"$$tmp/wrong_order.tide\",\"code\":\"E_TYPE\"" "$$tmp/err"; \
	    grep -Fq '"line":10,"column":15,"operation":"count_events","argument":1,"expected":"{OtherDocument}","actual":"{Document}"' "$$tmp/err"; \
	done; \
	for spec in '1.0.0:E_PACKAGE' '1.0.0[]:E_PACKAGE' '1.0.0[Missing]:E_TYPE' '1.0.0[Other]:E_PACKAGE'; do \
	    sed "s/^use jsoninput@.*/use jsoninput@$${spec%:*}/" "$$tmp/binding.tide" > "$$tmp/bad.tide"; \
	    printf '\nrecord Other\nvalue:i\n' >> "$$tmp/bad.tide"; \
	    if ./tide check "$$tmp/bad.tide" > "$$tmp/out" 2> "$$tmp/err"; then exit 1; fi; \
	    grep -Fq "\"code\":\"$${spec##*:}\"" "$$tmp/err"; \
	done; \
	echo 'Shared package, type bindings and call-site diagnostics OK'
