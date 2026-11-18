.PHONY: check-atomic-edit
check-atomic-edit: editor checker inspector catalog
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/atomic-edit.XXXXXXXX"); \
	trap 'rm -rf "$$tmp"' EXIT; \
	fixture=native/bootstrap/fixtures/atomic_edit; cp -R "$$fixture" "$$tmp/project"; \
	entry=$$tmp/project/checks.tide; edits=$$(cat "$$fixture/edits.json"); \
	revision() { sed -n 's/.*"revision":"\([0-9a-f]\{64\}\)".*/\1/p'; }; \
	base=$$(./tide check "$$entry" | revision); test -n "$$base"; \
	./tide edit "$$entry" --base "$$base" --edits "$$edits" > "$$tmp/preview"; \
	next=$$(revision < "$$tmp/preview"); test -n "$$next"; test "$$next" != "$$base"; \
	grep -Fq '"written":false,"files":[' "$$tmp/preview"; diff -r "$$fixture" "$$tmp/project"; \
	./tide edit "$$entry" --base "$$base" --edits "$$edits" --write > "$$tmp/result"; \
	sed 's/"written":false/"written":true/' "$$tmp/preview" | cmp - "$$tmp/result"; \
	test "$$(./tide check "$$entry" | revision)" = "$$next"; \
	test "$$(./tide test "$$entry")" = '{"passed":1}'; \
	if ./tide edit "$$entry" --base "$$base" --edits "$$edits" --write > "$$tmp/out" 2> "$$tmp/err"; then exit 1; fi; \
	test ! -s "$$tmp/out"; grep -Fq '"code":"E_REVISION"' "$$tmp/err"; \
	test "$$(./tide check "$$entry" | revision)" = "$$next"; test ! -e "$$tmp/project/.tide-edit-transaction-v1"; \
	echo 'Atomic edit across package, caller and example OK'
