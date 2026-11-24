#=====================================================================
# tt_um_2048 Verification Environment Makefile (Synopsys VCS + URG)
#=====================================================================

# ---- Config ---------------------------------------------------------
TEST           ?= game_smoke_test

TESTLIST       ?= game_no_srst_gameover_test \
                  game_smoke_test \
                  game_all_32_prio_test \
                  game_glitch_and_overlap_test \
                  game_merge_rules_test \
                  game_invalid_and_reset_test \
                  game_occupied_retry_test \
                  game_unused_pins_test \
                  game_over_test \
                  game_random_test \
                  game_win_glyph_test
                 

NUM_RUNS       ?= 1
UVM_VERBOSITY  ?= UVM_LOW
UVM_TIMEOUT    ?= 500000000000
PER_RUN_REPORT ?= 0

# ---- Source Files (Compile Order: RTL -> Interface -> Package -> Top) -
# Note: game2048_sva.sv is bound/instantiated inside top.sv or project.v;
# if it is standalone, add game2048_sva.sv right after interface.sv.
FILES = project.v \
        hvsync_generator.v \
        debounce_top.v \
        randomizer.v \
        reset_sync.v \
        update.v \
        vga_controller.v \
        interface.sv \
        package.sv \
        top.sv

# ---- Compile & Coverage Flags (Code + Functional + Assertion) -------
# ---- Compile & Coverage Flags (Code + Functional + Assertion) -------
CM_OPTS        = -cm line+cond+fsm+tgl+branch+assert
URG_METRICS    = -metric line+cond+fsm+tgl+branch+assert+group

VCS_CMD        = vcs -full64 -sverilog -ntb_opts uvm-1.2 -licqueue \
                 +incdir+. -timescale=1ns/1ps -debug_access+all \
                 $(CM_OPTS) -assert enable_diag

DESIGN_VDB     ?= simv.vdb

# ---- Output Directories ---------------------------------------------
SINGLE_ROOT    ?= single_runs
REGR_ROOT      ?= regression_cm
REGR_RUNS_DIR  = $(REGR_ROOT)/runs
REGR_MERGED_DIR= $(REGR_ROOT)/merged
REGR_MERGED    = $(REGR_MERGED_DIR)/simv
REGR_REPORT    = $(REGR_MERGED_DIR)/report

.PHONY: all compile run regression merge_regression clean_regression clean

all: compile regression

# ---- 1. Compile -----------------------------------------------------
compile:
	$(VCS_CMD) $(FILES) -l compile.log

# ---- 2. Run a Single Test on Demand ---------------------------------
# Usage: make run TEST=game_smoke_test
#        make run TEST=game_random_test SEED=12345
run:
ifndef TEST
	$(error Usage: make run TEST=<test_name> [SEED=<n>])
endif
	@rm -rf $(SINGLE_ROOT)/$(TEST)
	@mkdir -p $(SINGLE_ROOT)/$(TEST)
	./simv $(CM_OPTS) -cm_dir $(SINGLE_ROOT)/$(TEST)/simv.vdb \
		+UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) \
		+UVM_TIMEOUT=$(UVM_TIMEOUT) \
		$(if $(SEED),+ntb_random_seed=$(SEED)) \
		-l $(SINGLE_ROOT)/$(TEST)/$(TEST).log
	urg -dir $(DESIGN_VDB) $(SINGLE_ROOT)/$(TEST)/simv.vdb \
		$(URG_METRICS) -format both -report $(SINGLE_ROOT)/$(TEST)/report
	@echo ">>> Log            : $(SINGLE_ROOT)/$(TEST)/$(TEST).log"
	@echo ">>> Coverage DB    : $(SINGLE_ROOT)/$(TEST)/simv.vdb"
	@echo ">>> HTML Report    : $(SINGLE_ROOT)/$(TEST)/report/dashboard.html"

# ---- 3. Full Regression (All Tests in TESTLIST) ---------------------
regression: compile
	@mkdir -p $(REGR_RUNS_DIR)
	@rm -f $(REGR_ROOT)/vdb_list.txt $(REGR_ROOT)/failed_runs.txt $(REGR_ROOT)/summary.txt
	@for t in $(TESTLIST); do \
		for i in $$(seq 1 $(NUM_RUNS)); do \
			run_dir=$(REGR_RUNS_DIR)/$${t}_run$${i}; \
			vdb=$$run_dir/simv.vdb; \
			log=$$run_dir/$${t}_run$${i}.log; \
			rm -rf $$run_dir; \
			mkdir -p $$run_dir; \
			extra=""; \
			if [ "$$t" = "game_random_test" ]; then extra="+ntb_random_seed_automatic"; fi; \
			echo ">>> Running $$t (run $$i/$(NUM_RUNS)) -> $$run_dir"; \
			./simv $(CM_OPTS) -cm_dir $$vdb \
				+UVM_TESTNAME=$$t +UVM_VERBOSITY=$(UVM_VERBOSITY) \
				+UVM_TIMEOUT=$(UVM_TIMEOUT) $$extra \
				-l $$log; \
			n_sva=$$(grep -cE "SVA_[A-Z0-9_]+:|failed at" $$log 2>/dev/null || true); \
			n_err=$$(awk '/^UVM_ERROR :/ {v=$$3} END {print v+0}' $$log 2>/dev/null); \
			n_fat=$$(awk '/^UVM_FATAL :/ {v=$$3} END {print v+0}' $$log 2>/dev/null); \
			if ! grep -q "UVM Report Summary" $$log 2>/dev/null; then \
				echo "  >>> $$t run $$i: CRASHED / NO UVM SUMMARY -> $$log" | tee -a $(REGR_ROOT)/summary.txt $(REGR_ROOT)/failed_runs.txt; \
			elif [ "$$n_sva" -ne 0 ] || [ "$$n_err" -ne 0 ] || [ "$$n_fat" -ne 0 ]; then \
				echo "  >>> $$t run $$i: FAIL (sva=$$n_sva uvm_error=$$n_err uvm_fatal=$$n_fat) -> $$log" | tee -a $(REGR_ROOT)/summary.txt $(REGR_ROOT)/failed_runs.txt; \
			else \
				echo "  $$t run $$i: CLEAN" | tee -a $(REGR_ROOT)/summary.txt; \
			fi; \
			if [ -d $$vdb ] && [ -n "$$(ls -A $$vdb 2>/dev/null)" ]; then \
				echo $$vdb >> $(REGR_ROOT)/vdb_list.txt; \
			else \
				echo "!!! $$t run $$i produced no coverage DB" >> $(REGR_ROOT)/failed_runs.txt; \
			fi; \
			if [ "$(PER_RUN_REPORT)" = "1" ] && [ -d $$vdb ]; then \
				urg -dir $(DESIGN_VDB) $$vdb $(URG_METRICS) -format both -report $$run_dir/report > /dev/null 2>&1; \
			fi; \
		done; \
	done
	@$(MAKE) merge_regression

# ---- 4. Merge All Regression Runs into One Combined Report ----------
merge_regression:
	@if [ ! -s $(REGR_ROOT)/vdb_list.txt ]; then \
		echo "!!! No coverage DBs found to merge. Check logs in $(REGR_RUNS_DIR)."; \
		exit 1; \
	fi
	@echo ">>> Merging coverage from $$(wc -l < $(REGR_ROOT)/vdb_list.txt) run(s)..."
	@rm -rf $(REGR_MERGED_DIR)
	@mkdir -p $(REGR_MERGED_DIR)
	urg -dir $(DESIGN_VDB) $$(cat $(REGR_ROOT)/vdb_list.txt) \
		$(URG_METRICS) -format both -dbname $(REGR_MERGED) -report $(REGR_REPORT)
	@echo ""
	@echo "=== Regression Summary ==="
	@cat $(REGR_ROOT)/summary.txt
	@echo ""
	@echo ">>> Merged Coverage DB : $(REGR_MERGED).vdb"
	@echo ">>> Overall Dashboard  : $(REGR_REPORT)/dashboard.html"
	@echo ">>> Assertion Report   : $(REGR_REPORT)/asserts.html"
	@echo ">>> Functional Groups  : $(REGR_REPORT)/groups.html"
	@echo ">>> Code Coverage      : $(REGR_REPORT)/modlist.html"

# ---- 5. Housekeeping ------------------------------------------------
clean_regression:
	rm -rf $(REGR_ROOT)

clean: clean_regression
	rm -rf simv simv.daidir csrc logs *.log *.vpd *.vcd *.fsdb *.key \
		vc_hdrs.h $(DESIGN_VDB) urgReport DVEfiles ucli.key \
		$(SINGLE_ROOT) cov_report assert_html_report