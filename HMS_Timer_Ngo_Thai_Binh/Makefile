#===============================================================================
# Makefile for HMS_Timer IP Core Verification
# Toolchain: QuestaSim / ModelSim / VCS / Verilator
# Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
#===============================================================================

# Simulator configuration
QUESTA_BIN ?= /home/ngobinh/Questasim/questasim/linux_x86_64
VLOG       = $(QUESTA_BIN)/vlog
VSIM       = $(QUESTA_BIN)/vsim
VLIB       = $(QUESTA_BIN)/vlib
VMAP       = $(QUESTA_BIN)/vmap
VCOVER     = $(QUESTA_BIN)/vcover

# Working directory and library
SIM_DIR    = sim
WORK_LIB   = $(SIM_DIR)/work

# Source directories
RTL_DIR    = rtl
TB_DIR     = tb

# RTL Source Files
RTL_SRCS   = $(RTL_DIR)/reset_sync.sv \
             $(RTL_DIR)/clk_prescaler.sv \
             $(RTL_DIR)/button_debouncer.sv \
             $(RTL_DIR)/button_controller.sv \
             $(RTL_DIR)/mode_controller.sv \
             $(RTL_DIR)/second_counter.sv \
             $(RTL_DIR)/minute_counter.sv \
             $(RTL_DIR)/hour_counter.sv \
             $(RTL_DIR)/output_switch.sv \
             $(RTL_DIR)/hms_timer.sv

# Testbench Source Files
TB_SRCS    = $(TB_DIR)/hms_timer_types_pkg.sv \
             $(TB_DIR)/hms_timer_if.sv \
             $(TB_DIR)/tb_hms_timer.sv

# Top Testbench Module
TB_TOP     = tb_hms_timer
TEST      ?= all

# Compilation flags
VLOG_FLAGS = -sv -timescale "1ns/1ps" +acc -lint +incdir+$(TB_DIR) +incdir+$(TB_DIR)/tests -work $(WORK_LIB)
COV_FLAGS  = +cover=bcesf

# Simulation flags
VSIM_FLAGS = -c -work $(WORK_LIB) $(TB_TOP) +TESTNAME=$(TEST) -do "run -all; quit -f"

# Detailed Coverage Report flags for vcover (source annotation, details, all covergroups and bins)
VCOVER_DETAIL_FLAGS = -details -annotate -assert -cvg -codeAll \
                      -showexcluded -nocompactcrossbins \
                      -threshH 90 -threshL 70

.PHONY: all compile sim run wave cov cov-view cov-view-cvg clean help verilator_test synth flow clean-synth

all: compile sim

# Display help menu
help:
	@echo "================================================================="
	@echo "                     HMS_Timer Build System                      "
	@echo "================================================================="
	@echo "  make compile     : Compile RTL and SystemVerilog TB using QuestaSim"
	@echo "  make sim         : Run batch simulation and display test scorecard"
	@echo "  make all         : Compile and run simulation (default)"
	@echo "  make wave        : Run simulation with waveform viewer (GUI mode)"
	@echo "  make cov         : Compile with code/func coverage and gen detailed report"
	@echo "  make cov-view    : Open HTML coverage report in web browser"
	@echo "  make cov-view-cvg: Open Functional Coverage & Bins page directly in browser"
	@echo "  make synth       : Run OpenLane 2 Logic Synthesis (Yosys + Sky130)"
	@echo "  make flow        : Run Full OpenLane 2 ASIC Flow (RTL -> GDSII)"
	@echo "  make clean-synth : Clean OpenLane runs artifacts"
	@echo "  make clean       : Clean up simulation work directory and logs"
	@echo "================================================================="

# Create working library
$(WORK_LIB):
	@mkdir -p $(SIM_DIR)
	@$(VLIB) $(WORK_LIB)
	@$(VMAP) work $(WORK_LIB)

# Compile RTL and Testbench
compile: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Compiling RTL and Testbench with QuestaSim vlog... <<<"
	@echo "-----------------------------------------------------------------"
	$(VLOG) $(VLOG_FLAGS) $(RTL_SRCS) $(TB_SRCS) | tee $(SIM_DIR)/compile.log

# Run batch simulation
sim: compile
	@echo "-----------------------------------------------------------------"
	@echo ">>> Running Simulation with QuestaSim vsim... <<<"
	@echo "-----------------------------------------------------------------"
	$(VSIM) $(VSIM_FLAGS) -l $(SIM_DIR)/sim.log

run: sim

# Run simulation with GUI Waveform viewer
wave: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Launching QuestaSim GUI Waveform Viewer... <<<"
	@echo "-----------------------------------------------------------------"
	$(VSIM) -gui -work $(WORK_LIB) $(TB_TOP) &

# Compile and run with Functional & Code Coverage
cov: $(WORK_LIB)
	@echo "-----------------------------------------------------------------"
	@echo ">>> Compiling RTL with Code Coverage Enabled... <<<"
	@echo "-----------------------------------------------------------------"
	$(VLOG) $(VLOG_FLAGS) $(COV_FLAGS) $(RTL_SRCS)
	@echo ">>> Compiling Testbench (Functional Coverage Only)... <<<"
	$(VLOG) $(VLOG_FLAGS) $(TB_SRCS)
	@echo ">>> Running Simulation with Coverage Collection... <<<"
	$(VSIM) -c -coverage -work $(WORK_LIB) $(TB_TOP) -do "coverage save -onexit $(SIM_DIR)/hms_cov.ucdb; run -all; quit -f" -l $(SIM_DIR)/sim_cov.log
	@echo ">>> Generating Detailed HTML Coverage Report (with Source Annotation)... <<<"
	$(VCOVER) report -html -output $(SIM_DIR)/cov_html $(VCOVER_DETAIL_FLAGS) $(SIM_DIR)/hms_cov.ucdb
	@echo ">>> Generating Text Coverage Reports... <<<"
	$(VCOVER) report -summary $(SIM_DIR)/hms_cov.ucdb -output $(SIM_DIR)/cov_summary.txt
	$(VCOVER) report -details -zeros -codeAll $(SIM_DIR)/hms_cov.ucdb -output $(SIM_DIR)/cov_details.txt
	$(VCOVER) report -cvg -details $(SIM_DIR)/hms_cov.ucdb -output $(SIM_DIR)/cov_functional.txt
	@echo "-----------------------------------------------------------------"
	@echo ">>> Overall Coverage Summary: <<<"
	@echo "-----------------------------------------------------------------"
	@cat $(SIM_DIR)/cov_summary.txt
	@echo "-----------------------------------------------------------------"
	@echo "Coverage HTML Report generated at: $(SIM_DIR)/cov_html/index.html"
	@echo "Functional Coverage Page at: $(SIM_DIR)/cov_html/cvg.html"
	@echo "Coverage Details Text generated at: $(SIM_DIR)/cov_details.txt"
	@echo "Functional Bins Text generated at: $(SIM_DIR)/cov_functional.txt"
	@echo "Run 'make cov-view' to open report in browser."
	@echo "Run 'make cov-view-cvg' to open Functional Coverage & Bins page."
	@echo "-----------------------------------------------------------------"

# Open Coverage HTML in default browser
cov-view:
	@echo ">>> Opening Coverage Report in browser: $(SIM_DIR)/cov_html/index.html <<<"
	@xdg-open $(SIM_DIR)/cov_html/index.html > /dev/null 2>&1 &

# Open Functional Coverage (Covergroups & Bins) page directly
cov-view-cvg:
	@echo ">>> Opening Functional Coverage Bins in browser: $(SIM_DIR)/cov_html/cvg.html <<<"
	@xdg-open $(SIM_DIR)/cov_html/cvg.html > /dev/null 2>&1 &

# Verilator lint check
verilator_test:
	verilator --lint-only -Wall -sv $(RTL_SRCS)

# Clean build artifacts
clean:
	@echo ">>> Cleaning build artifacts... <<<"
	rm -rf $(SIM_DIR) transcript *.wlf *.vcd covhtmlreport vsim.wlf

#===============================================================================
# OpenLane 2 Synthesis & ASIC Flow Targets
#===============================================================================
OPENLANE_WRAPPER = ./scripts/run_openlane.sh

synth:
	@chmod +x $(OPENLANE_WRAPPER)
	$(OPENLANE_WRAPPER) synth

flow:
	@chmod +x $(OPENLANE_WRAPPER)
	$(OPENLANE_WRAPPER) flow

clean-synth:
	@echo ">>> Cleaning OpenLane run artifacts... <<<"
	rm -rf openlane/runs runs

