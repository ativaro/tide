.PHONY: check-package-types
check-package-types: checker catalog aot-runtime
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/package-types.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	fixtures=native/bootstrap/fixtures/package_types; \
	pkg=vendor/jsoninput/1.0.0/package.tide; cmp "apps/orders/$$pkg" "apps/report_packages/$$pkg"; \
	cp -R "$$fixtures/." "$$tmp"; cp -R apps/orders/. "$$tmp"; \
	test "$$(./tide test "$$tmp/binding.tide")" = '{"passed":3}'; \
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
