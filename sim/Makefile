TEST ?= base_single_read_test
VERB ?= UVM_MEDIUM
SEED ?= random

# Simulator tools
VLIB = vlib
VMAP = vmap
VLOG = vlog
VSIM = vsim

# Compiler and Simulator Flags
VLOG_OPTS = -sv -timescale "1ns/1ps" +acc=all -suppress 2223 -suppress 12003 -suppress 3843
VSIM_OPTS = -voptargs="+acc" -suppress 3843 -suppress 3839 -suppress 3838

# All 14 Testcases
TESTS = power_on_rst_test \
        base_single_read_test \
        cache_hit_repeat_read_test \
        line_boundary_first_word_test \
        line_boundary_last_word_test \
        addr_min_boundary_test \
        addr_max_boundary_test \
        all_lines_walk_test \
        all_zeroes_data_test \
        all_ones_data_test \
        alternating_bits_pattern_test \
        back_to_back_miss_requests_test \
        pipelined_cache_hits_test \
        pipelined_miss_then_hit_test \
        ahb_burst_test

.PHONY: all help build run view_wave wave run_gui regress clean $(TESTS)

all: build run

#-----------------------------------------------------------------------
# Help Menu: Shows all commands and testcase descriptions
#-----------------------------------------------------------------------
help:
	@echo "=========================================================================================="
	@echo "                   QSPI XiP CONTROLLER TESTBENCH - HELP MENU                              "
	@echo "=========================================================================================="
	@echo " QUICK COMMANDS:"
	@echo "   make run TEST=<name>          : Run test -> creates <name>.log AND <name>.wlf"
	@echo "   make view_wave TEST=<name>    : Open <name>.wlf in QuestaSim Waveform Viewer"
	@echo "   make wave TEST=<name>         : Run test AND immediately open waveform in QuestaSim"
	@echo "   make run_gui TEST=<name>      : Run interactive simulation inside QuestaSim GUI"
	@echo "   make regress                  : Run all 14 tests (generates .log and .wlf for each)"
	@echo "   make clean                    : Remove work library, all *.log, and all *.wlf files"
	@echo ""
	@echo " SHORTCUTS (Works for ANY testcase):"
	@echo "   make <testname>               : e.g. make base_single_read_test"
	@echo "   make wave_<testname>          : e.g. make wave_base_single_read_test"
	@echo "                                 : e.g. make wave_pipelined_cache_hits_test"
	@echo ""
	@echo " AVAILABLE TESTCASES:"
	@echo " -----------------------------------------------------------------------------------------"
	@echo "  #  | TESTNAME                        | SHORT DESCRIPTION"
	@echo " -----------------------------------------------------------------------------------------"
	@echo "  1  | power_on_rst_test               | Reset release and post-reset read at 0x00000000"
	@echo "  2  | base_single_read_test           | Single cold-miss read to 0x000000A0 (flash fetch)"
	@echo "  3  | cache_hit_repeat_read_test      | Reads same line again (verifies cache hit, 0 QSPI)" 
	@echo "  4  | all_lines_walk_test             | Fills all 16 cache lines + reads all words in line 0"
	@echo " 5  | alternating_bits_pattern_test   | Verifies flash with alternating 0xAA/0x55 pattern"
	@echo " 6  | back_to_back_miss_requests_test | 4 consecutive misses across lines with 0 idle gap"
	@echo " 7  | pipelined_cache_hits_test       | Pipelined back-to-back reads (1 transfer/clock cycle)"
	@echo " 8  | pipelined_miss_then_hit_test    | Pipelined miss: address held during HREADY=0 wait"
	@echo " 9 | ahb_burst_test   | ahb_burst test"
	@echo " -----------------------------------------------------------------------------------------"
	@echo "=========================================================================================="

#-----------------------------------------------------------------------
# Compilation
#-----------------------------------------------------------------------
build:
	@if [ ! -d work ]; then $(VLIB) work; $(VMAP) work work; fi
	$(VLOG) $(VLOG_OPTS) -f filelist.f

#-----------------------------------------------------------------------
# Simulation: Automatically creates <testname>.log AND <testname>.wlf
#-----------------------------------------------------------------------
run: build
	$(VSIM) -c $(VSIM_OPTS) -l $(TEST).log -wlf $(TEST).wlf -do "log -r /*; run -all; quit -f" \
		-sv_seed $(SEED) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERB) work.tb_top
	@echo ">>> Simulation completed."
	@echo ">>> Log file saved to      : $(TEST).log"
	@echo ">>> Waveform file saved to : $(TEST).wlf"

# Open waveform in QuestaSim GUI (generates wave if not yet present)
view_wave:
	@if [ ! -f $(TEST).wlf ]; then \
		echo ">>> $(TEST).wlf not found. Running simulation first to generate it..."; \
		$(MAKE) run TEST=$(TEST); \
	fi
	$(VSIM) -gui -view $(TEST).wlf -do "add wave -r /*; zoom full;"

# Run test AND immediately open waveform in QuestaSim GUI
wave: run
	$(VSIM) -gui -view $(TEST).wlf -do "add wave -r /*; zoom full;"

# Interactive simulation directly inside QuestaSim GUI
run_gui: build
	$(VSIM) -gui $(VSIM_OPTS) -l $(TEST).log -wlf $(TEST).wlf -do "add wave -r /tb_top/*; run -all;" \
		-sv_seed $(SEED) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERB) work.tb_top

#-----------------------------------------------------------------------
# Direct shortcuts for ANY testcase
#   e.g.: make base_single_read_test       (Runs test, saves .log & .wlf)
#   e.g.: make wave_base_single_read_test  (Runs test & opens GUI wave)
#-----------------------------------------------------------------------
$(TESTS): build
	$(MAKE) run TEST=$@

wave_%: build
	$(MAKE) wave TEST=$*

#-----------------------------------------------------------------------
# Full Regression: Generates individual .log and .wlf for all 14 tests
#-----------------------------------------------------------------------
regress: build
	@echo "=========================================================="
	@echo "   RUNNING FULL REGRESSION (ALL 14 TESTS)                 "
	@echo "=========================================================="
	@for t in $(TESTS); do \
		echo ">>> Running $$t ..."; \
		$(VSIM) -c $(VSIM_OPTS) -l $$t.log -wlf $$t.wlf -do "log -r /*; run -all; quit -f" \
			-sv_seed $(SEED) +UVM_TESTNAME=$$t +UVM_VERBOSITY=$(VERB) work.tb_top; \
		if grep -q "TEST STATUS: ALL CHECKS PASSED" $$t.log; then \
			echo "    [PASSED] $$t (Log: $$t.log | Wave: $$t.wlf)"; \
		else \
			echo "    [FAILED] $$t (Check $$t.log)"; \
		fi; \
	done
	@echo "=========================================================="

#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------
clean:
	rm -rf work transcript *.wlf *.log *.vstf modelsim.ini

