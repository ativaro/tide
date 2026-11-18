BUILD ?= build/native
.DEFAULT_GOAL := native
PREFIX ?= /usr/local
pkgdir = $(DESTDIR)$(PREFIX)/lib/tide
CXX ?= c++
BOOTFLAGS := -std=c++20 -O1 -fno-ident -Wl,--build-id=none -s
MODULES := $(addprefix native/,elf64.tide source.tide scalar.tide argv_i64.tide scan_image.tide rule_scan.tide fold_i64.tide)
SEED_MODULES := native/bootstrap/syntax.tide native/bootstrap/seed.tide native/bootstrap/sqlite_abi.tide native/bootstrap/https_abi.tide native/bootstrap/write_abi.tide native/bootstrap/pg_abi.tide
PROJECT_MODULES := $(addprefix native/bootstrap/,syntax.tide schema.tide json_text.tide json_stream.tide scalar_json.tide measurement_types.tide functions.tide rules.tide value_tree.tide compound_json.tide input_issue.tide samples.tide packages.tide project_model.tide)
EVAL_MODULES := $(addprefix native/bootstrap/,eval_values.tide public_data.tide sqlite.tide https.tide postgres.tide value_diff.tide run_inputs.tide function_run.tide)
CHECKER_MODULES := $(PROJECT_MODULES) $(EVAL_MODULES) native/catalog/lookup.tide native/bootstrap/service_abi.tide native/bootstrap/aot.tide native/bootstrap/project.tide
AOT_RUNTIME_MODULES := $(PROJECT_MODULES) $(addprefix native/bootstrap/,eval_values.tide public_data.tide sqlite.tide https.tide postgres.tide run_inputs.tide aot_runtime.tide service_runtime.tide)
INSPECTOR_MODULES := $(PROJECT_MODULES) native/bootstrap/nodes.tide $(EVAL_MODULES) native/bootstrap/execution.tide native/bootstrap/sha256.tide native/bootstrap/probe_domain.tide native/bootstrap/explain.tide native/bootstrap/inspection.tide
EDITOR_MODULES := $(PROJECT_MODULES) native/bootstrap/nodes.tide $(EVAL_MODULES) native/bootstrap/sha256.tide native/bootstrap/editor.tide native/bootstrap/edit_json.tide native/bootstrap/node_edits.tide
SOURCE ?= apps/balance.tide
ENTRY ?= main
ifndef OUT
OUT := $(BUILD)/program
endif
override SOURCE := $(value SOURCE)
override ENTRY := $(value ENTRY)
override OUT := $(value OUT)
export SOURCE ENTRY OUT

SQLITE := $(BUILD)/sqlite3.o
SQL_FLAGS := -I$(BUILD) $(SQLITE) -lm -pthread

$(BUILD)/sqlite3.c $(BUILD)/sqlite3.h: $(BUILD)/%: native/vendor/sqlite/%.xz native/vendor/sqlite/source.sha256 | $(BUILD)
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; xz -dc "$<" > "$$tmp"; \
	expected=$$(awk -v f="$(@F)" '$$2 == f {print $$1}' native/vendor/sqlite/source.sha256); \
	test "$$(sha256sum < "$$tmp" | cut -d' ' -f1)" = "$$expected"; mv -f "$$tmp" "$@"

$(SQLITE): $(BUILD)/sqlite3.c $(BUILD)/sqlite3.h
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	$(CC) -O2 -ffunction-sections -fdata-sections -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_DQS=0 -DSQLITE_MAX_ATTACHED=0 -DSQLITE_TEMP_STORE=3 -DSQLITE_TRUSTED_SCHEMA=0 -DSQLITE_MAX_SQL_LENGTH=131072 -DSQLITE_MAX_LENGTH=4194304 -c "$<" -o "$$tmp"; mv -f "$$tmp" "$@"

.PHONY: native bootstrap-check program
native: $(BUILD)/tidec

$(BUILD):
	mkdir -p "$@"

$(BUILD)/seed0: native/bootstrap/seed-linux-x86_64.xz native/bootstrap/seed.sha256 | $(BUILD)
	@set -eu; sha256sum --status -c native/bootstrap/seed.sha256; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	xz -dc "$<" > "$$tmp"; chmod 755 "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/bootstrap.tide: $(SEED_MODULES) | $(BUILD)
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	for unit in $^; do cat "$$unit"; echo; done > "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/seed1.cpp: $(BUILD)/seed0 $(BUILD)/bootstrap.tide
$(BUILD)/seed.cpp: $(BUILD)/seed1 $(BUILD)/bootstrap.tide
$(BUILD)/seed.cpp: private SEED_ENTRY = main@compiler

$(BUILD)/seed1.cpp $(BUILD)/seed.cpp:
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	"$<" $(SEED_ENTRY) < "$(BUILD)/bootstrap.tide" > "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/seed1 $(BUILD)/seed: %: %.cpp
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	$(CXX) $(BOOTFLAGS) -static "$<" -o "$$tmp"; chmod 755 "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/compiler.tide: $(MODULES) | $(BUILD)
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	for module in $(MODULES); do cat "$$module"; echo; done > "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/compiler.cpp: $(BUILD)/compiler.tide $(BUILD)/seed
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	"$(BUILD)/seed" compile_entry < "$<" > "$$tmp"; mv -f "$$tmp" "$@"

$(BUILD)/tidec: $(BUILD)/compiler.cpp
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	$(CXX) $(BOOTFLAGS) -static "$<" -o "$$tmp"; chmod 755 "$$tmp"; mv -f "$$tmp" "$@"

bootstrap-check: $(BUILD)/seed
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/rebuild.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	"$(BUILD)/seed" main@compiler < "$(BUILD)/bootstrap.tide" > "$$tmp/two.cpp"; \
	$(CXX) $(BOOTFLAGS) -static "$$tmp/two.cpp" -o "$$tmp/two"; \
	"$$tmp/two" main@compiler < "$(BUILD)/bootstrap.tide" > "$$tmp/three.cpp"; cmp "$$tmp/two.cpp" "$$tmp/three.cpp"; \
	$(CXX) $(BOOTFLAGS) -static "$$tmp/three.cpp" -o "$$tmp/three"; cmp "$$tmp/two" "$$tmp/three"

program: $(BUILD)/tidec
	@sh native/write-image "$(BUILD)/tidec" "$$SOURCE" "$$OUT" "$$ENTRY"

.PHONY: install install-native
install: install-native

# Package-owned remnants of older installations.
REFERENCE_MODULES := __init__ analysis catalog cli core document program runtime terminal values workbench

install-native: native catalog forms checker inspector editor aot-runtime
	@install -d "$(pkgdir)/bin" "$(pkgdir)/native/catalog" "$(DESTDIR)$(PREFIX)/bin"
	@install -m755 tide "$(pkgdir)"
	@install -m755 "$(BUILD)/tidec" "$(BUILD)/catalog" "$(BUILD)/forms" "$(BUILD)/checker" "$(BUILD)/inspector" "$(BUILD)/editor" "$(pkgdir)/bin"
	@install -m644 native/write-image "$(pkgdir)/native"
	@install -m644 "$(BUILD)/aot-runtime.cpp" "$(SQLITE)" "$(BUILD)/sqlite3.h" "$(pkgdir)/native"
	@install -m644 native/catalog/*.tsv "$(pkgdir)/native/catalog"
	@ln -fT "$(pkgdir)/bin/checker" "$(pkgdir)/bin/tide"
	@ln -sfnT ../lib/tide/bin/tide "$(DESTDIR)$(PREFIX)/bin/tide"
	@set -eu; modules="$(pkgdir)/tide_lang"; cache="$$modules/__pycache__"; \
	rm -f -- "$(pkgdir)/compat-interpreter" "$(pkgdir)/reference-tide"; \
	if [ -d "$$modules" ] && [ ! -L "$$modules" ]; then \
	    for name in $(REFERENCE_MODULES); do \
	        rm -f -- "$$modules/$$name.py" "$$modules/$$name.pyc" "$$modules/$$name.pyo"; \
	        if [ -d "$$cache" ] && [ ! -L "$$cache" ]; then \
	            rm -f -- "$$cache/$$name".*.pyc; \
	        fi; \
	    done; \
	    rmdir -- "$$cache" "$$modules" 2>/dev/null || :; \
	fi

.PHONY: test check-native check-sqlite
test: check-native check-sqlite check-https check-language-io check-package-types

include native/bootstrap/https-check.mk
include native/bootstrap/service-check.mk
include native/bootstrap/package-types-check.mk

check-sqlite: checker catalog aot-runtime
	@./tide test apps/orders/checks.tide
	@set -eu; \
	tmp=$$(mktemp -d "$(BUILD)/sqlite-check.XXXXXXXX"); \
	trap 'rm -rf "$$tmp"' EXIT; \
	app=apps/report_packages/sqlite_report.tide; \
	./tide build --aot "$$app" "$$tmp/import"; \
	./tide build --aot "$$app" "$$tmp/query" by_sensor; \
	printf '%s\n' '{"readings":[{"sensor":"A","value":7,"note":"vorher"}],"limits":{}}' > "$$tmp/seed.json"; \
	printf '%s\n' '{"readings":[{"sensor":"A","value":99},{"sensor":"","value":40}],"limits":{}}' > "$$tmp/bad.json"; \
	for mode in run aot; do \
	    db="db=$$tmp/$$mode.db"; \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$app"; else set -- "$$tmp/import"; fi; \
	    test "$$("$$@" --db "$$db" --read input="$$tmp/seed.json" --inputs '{"limit":80}')" = '{"above":0,"peak":{"some":7}}'; \
	    if "$$@" --db "$$db" --read input="$$tmp/bad.json" --inputs '{"limit":80}' > "$$tmp/out" 2> "$$tmp/$$mode.err"; then exit 1; else test "$$?" = 1; fi; \
	    test ! -s "$$tmp/out"; grep -Fq '"reason":"sqlite_constraint"' "$$tmp/$$mode.err"; \
	    if [ "$$mode" = run ]; then set -- ./tide run "$$app" --call by_sensor; else set -- "$$tmp/query"; fi; \
	    test "$$("$$@" --db "$$db" --inputs '{"sensor":"A"}')" = '[{"sensor":"A","value":7,"note":{"some":"vorher"}}]'; \
	done; \
	cmp "$$tmp/run.err" "$$tmp/aot.err"; echo "SQLite file rollback OK (run, AOT)"

# Only the sources needed for a native build enter the optional verification image.
.PHONY: check-no-python
check-no-python:
	@tar -cf - Makefile tide tide.lock apps lib native workbench | \
	    docker buildx build --output=type=cacheonly --no-cache-filter build,installed -f native/bootstrap/no-python.Dockerfile -

check-native: bootstrap-check $(BUILD)/inspector $(BUILD)/inspection_checks $(BUILD)/editor_checks $(BUILD)/editor $(BUILD)/compiler_checks $(BUILD)/tidec $(BUILD)/checker $(BUILD)/nano_checks $(BUILD)/invaders_checks
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/checks.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	for unit in $(CHECKER_MODULES) native/bootstrap/function_cases.tide native/bootstrap/checks.tide; do cat "$$unit"; echo; done > "$$tmp/checks.tide"; \
	"$(BUILD)/seed" all_bootstrap_checks < "$$tmp/checks.tide" > "$$tmp/checks.cpp"; \
	$(CXX) $(BOOTFLAGS) "$$tmp/checks.cpp" $(SQL_FLAGS) -o "$$tmp/checks"; \
	for suite in "$(BUILD)/inspection_checks" "$(BUILD)/editor_checks" "$(BUILD)/compiler_checks" "$$tmp/checks" "$(BUILD)/nano_checks" "$(BUILD)/invaders_checks"; do \
	    result=$$("$$suite"); test "$$result" = true; done; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/modules/report.tide '?report.tide'); \
	test "$$result" = '{"passed":0}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/report.tide '?report.tide'); \
	test "$$result" = '{"passed":6}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/lists.tide '?lists.tide'); \
	test "$$result" = '{"passed":7}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/rules/control.tide '?control.tide'); \
	test "$$result" = '{"passed":4}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/rules/handler.tide '?handler.tide'); \
	test "$$result" = '{"passed":2}'; \
	result=$$("$(BUILD)/checker" --read-project apps/cursor.tide '?cursor.tide'); \
	test "$$result" = '{"passed":5}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/text.tide '?text.tide'); \
	test "$$result" = '{"passed":10}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/pairs.tide '?pairs.tide'); \
	test "$$result" = '{"passed":5}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/composite_pairs.tide '?composite_pairs.tide'); \
	test "$$result" = '{"passed":9}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/maps.tide '?maps.tide'); \
	test "$$result" = '{"passed":20}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/inclusive.tide '?inclusive.tide'); \
	test "$$result" = '{"passed":8}'; \
	result=$$("$(BUILD)/checker" --read-project apps/nano_checks.tide '?nano_checks.tide'); \
	test "$$result" = '{"passed":10}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/record_values.tide '?record_values.tide'); \
	test "$$result" = '{"passed":3}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/variants.tide '?variants.tide'); \
	test "$$result" = '{"passed":10}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/collections.tide '?collections.tide'); \
	test "$$result" = '{"passed":5}'; \
	result=$$("$(BUILD)/checker" --read-project apps/invaders_checks.tide '?invaders_checks.tide'); \
	test "$$result" = '{"passed":11}'; \
	result=$$("$(BUILD)/checker" --read-project apps/peak_lines.tide '?peak_lines.tide'); \
	test "$$result" = '{"passed":3}'; \
	result=$$("$(BUILD)/checker" --read-project apps/reading_check.tide '?reading_check.tide'); \
	test "$$result" = '{"passed":3}'; \
	result=$$("$(BUILD)/checker" --read-project apps/summary_checks.tide '?summary_checks.tide'); \
	test "$$result" = '{"passed":4}'; \
	result=$$("$(BUILD)/checker" --read-project apps/report.tide '?report.tide'); \
	test "$$result" = '{"passed":3}'; \
	result=$$("$(BUILD)/checker" --read-project apps/report_packages/report.tide '?report.tide'); \
	test "$$result" = '{"passed":6}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/public_data.tide '?public_data.tide'); test "$$result" = '{"passed":5}'; \
	result=$$("$(BUILD)/checker" --read-project apps/report_packages/sqlite_report.tide '?sqlite_report.tide'); test "$$result" = '{"passed":4}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/sqlite.tide '?sqlite.tide'); test "$$result" = '{"passed":8}'; \
	result=$$("$(BUILD)/checker" --read-project apps/report_packages/json_report.tide '?json_report.tide'); test "$$result" = '{"passed":9}'; \
	result=$$("$(BUILD)/checker" --read-project apps/report_packages/stream_report.tide '?stream_report.tide'); \
	test "$$result" = '{"passed":7}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/stream_lines.tide '?stream_lines.tide'); \
	test "$$result" = '{"passed":6}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/read_grants.tide '?read_grants.tide'); \
	test "$$result" = '{"passed":3}'; \
	result=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/handlers.tide '?handlers.tide'); \
	test "$$result" = '{"passed":8}'; \
	if diag=$$("$(BUILD)/checker" --read-project native/bootstrap/fixtures/functions/forbidden_handler.tide ':forbidden_handler.tide' 2>&1); then exit 1; fi; \
	test "$$diag" = '{"file":"forbidden_handler.tide","code":"E_TYPE","message":"Unsupported catch target","line":2,"column":7}'; \
	result=$$("$(BUILD)/checker" --read-project workbench/source_layout.tide '?source_layout.tide'); \
	test "$$result" = '{"passed":2}'; \
	result=$$("$(BUILD)/checker" --read-project workbench/project_context.tide '?project_context.tide'); \
	test "$$result" = '{"passed":7}'; \
	printf 'use adjustment\n\nmain > i\nadjust 3 4\n\nexample total main\n{"inputs":{},"expect":7}\n' > "$$tmp/report.tide"; \
	printf 'adjust x:i y:i > i\n- x y\n' > "$$tmp/adjustment.tide"; \
	if diag=$$("$(BUILD)/inspector" --read-project "$$tmp/report.tide" ':report.tide' '' explain 2>&1); then exit 1; fi; \
	revision=$${diag#*'"repair":{"revision":"'}; revision=$${revision%%'"'*}; \
	"$(BUILD)/editor" --replace-nodes "$$tmp/report.tide" ':report.tide' '[{"node":"adjustment.tide:2:1","op":"+"}]' "$$revision" no yes > "$$tmp/edit"; \
	result=$$("$(BUILD)/inspector" --read-project "$$tmp/report.tide" ':report.tide' '' explain); test "$$result" = '{"passed":1}'; \
	cat apps/balance.tide > "$$tmp/balance.tide"; base=$$(sha256sum "$$tmp/balance.tide"); \
	"$(BUILD)/editor" --replace-nodes "$$tmp/balance.tide" ':balance.tide' '[{"node":"2:38","replace":"+ entry total"}]' "$${base%% *}" no yes > "$$tmp/edit"; \
	if cmp -s apps/balance.tide "$$tmp/balance.tide"; then exit 1; fi; \
	result=$$("$(BUILD)/checker" --read-project "$$tmp/balance.tide" '?balance.tide'); \
	test "$$result" = '{"passed":3}'; echo true

$(BUILD)/inspection_checks $(BUILD)/editor_checks $(BUILD)/checker $(BUILD)/inspector $(BUILD)/editor: $(SQLITE)

$(BUILD)/inspection_checks: $(INSPECTOR_MODULES) native/bootstrap/inspection_checks.tide $(BUILD)/seed
$(BUILD)/editor_checks: $(EDITOR_MODULES) native/bootstrap/editor_checks.tide $(BUILD)/seed

$(BUILD)/nano_checks: apps/cursor.tide apps/nano.tide apps/nano_checks.tide $(BUILD)/seed
$(BUILD)/invaders_checks: apps/invaders_game.tide apps/space_invaders.tide apps/invaders_checks.tide $(BUILD)/seed

$(BUILD)/inspection_checks $(BUILD)/editor_checks $(BUILD)/nano_checks $(BUILD)/invaders_checks:
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/app-check.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	for unit in $(filter %.tide,$^); do cat "$$unit"; echo; done > "$$tmp/source.tide"; \
	"$(BUILD)/seed" "$(@F)" < "$$tmp/source.tide" > "$$tmp/check.cpp"; \
	$(CXX) $(BOOTFLAGS) "$$tmp/check.cpp" $(if $(filter $(SQLITE),$^),$(SQL_FLAGS)) -o "$$tmp/check"; mv -f "$$tmp/check" "$@"

.PHONY: catalog
catalog: $(BUILD)/catalog

$(BUILD)/catalog: native/catalog/lookup.tide native/catalog/query.tide $(BUILD)/seed
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/catalog.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	{ cat native/catalog/lookup.tide; echo; cat native/catalog/query.tide; } | "$(BUILD)/seed" > "$$tmp/catalog.cpp"; \
	$(CXX) $(BOOTFLAGS) -static "$$tmp/catalog.cpp" -o "$$tmp/catalog"; chmod 755 "$$tmp/catalog"; mv -f "$$tmp/catalog" "$@"

.PHONY: forms checker inspector editor aot-runtime
editor: $(BUILD)/editor
inspector: $(BUILD)/inspector
forms: $(BUILD)/forms
checker: $(BUILD)/checker
aot-runtime: $(BUILD)/aot-runtime.cpp $(SQLITE)

$(BUILD)/aot-runtime.cpp: $(AOT_RUNTIME_MODULES) $(BUILD)/seed
	@set -eu; tmp=$$(mktemp "$@.XXXXXXXX"); trap 'rm -f "$$tmp"' EXIT; \
	for unit in $(AOT_RUNTIME_MODULES); do cat "$$unit"; echo; done | "$(BUILD)/seed" main@aot > "$$tmp"; \
	mv -f "$$tmp" "$@"

$(BUILD)/checker: $(CHECKER_MODULES) $(BUILD)/seed
$(BUILD)/inspector: $(INSPECTOR_MODULES) $(BUILD)/seed
$(BUILD)/editor: $(EDITOR_MODULES) native/bootstrap/editor_transaction.tide $(BUILD)/seed
$(BUILD)/editor: PROJECT_ENTRY = check_schema@transaction
$(BUILD)/inspector: PROJECT_ENTRY = check_schema@project
$(BUILD)/checker: PROJECT_ENTRY = check_schema@runner

$(BUILD)/inspector $(BUILD)/checker $(BUILD)/editor:
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/checker.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	for unit in $(filter %.tide,$^); do cat "$$unit"; echo; done > "$$tmp/checker.tide"; \
	"$(BUILD)/seed" $(PROJECT_ENTRY) < "$$tmp/checker.tide" > "$$tmp/checker.cpp"; \
	$(CXX) $(BOOTFLAGS) -static "$$tmp/checker.cpp" $(SQL_FLAGS) -o "$$tmp/checker"; chmod 755 "$$tmp/checker"; mv -f "$$tmp/checker" "$@"

$(BUILD)/compiler_checks: $(SEED_MODULES) native/bootstrap/schema.tide native/bootstrap/forms.tide native/bootstrap/compiler_checks.tide $(BUILD)/seed
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/compiler-check.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	for unit in $(filter %.tide,$^); do cat "$$unit"; echo; done > "$$tmp/source.tide"; \
	"$(BUILD)/seed" bootstrap_checks < "$$tmp/source.tide" > "$$tmp/check.cpp"; \
	$(CXX) $(BOOTFLAGS) "$$tmp/check.cpp" -o "$$tmp/check"; mv -f "$$tmp/check" "$@"

$(BUILD)/forms: native/bootstrap/forms.tide $(BUILD)/bootstrap.tide $(BUILD)/seed
	@set -eu; tmp=$$(mktemp -d "$(BUILD)/forms.XXXXXXXX"); trap 'rm -rf "$$tmp"' EXIT; \
	{ cat "$(BUILD)/bootstrap.tide"; echo; cat "$<"; } > "$$tmp/forms.tide"; \
	"$(BUILD)/seed" group_forms < "$$tmp/forms.tide" > "$$tmp/forms.cpp"; \
	$(CXX) $(BOOTFLAGS) -static "$$tmp/forms.cpp" -o "$$tmp/forms"; chmod 755 "$$tmp/forms"; mv -f "$$tmp/forms" "$@"
