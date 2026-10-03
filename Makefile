# =============================================================================
# Makefile  —  VeeR EL2 + UART SoC  (Honours Project)
#
# Targets:
#   make all          — full flow: config → compile SW → build sim → run
#   make config       — generate VeeR EL2 config headers
#   make sw           — compile RISC-V boot program (boot.elf + boot.hex)
#   make sim          — build simulation binary with VCS
#   make run          — run simulation
#   make run CYCLES=N — run for N cycles
#   make verdi        — open last waveform in Verdi
#   make clean        — remove generated files
#   make clean_all    — remove everything including config headers
#
# Quick start:
#   make all
# =============================================================================

# -----------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------
PROJ_ROOT  := $(shell pwd)
SCRIPTS    := $(PROJ_ROOT)/Scripts
RTL        := $(PROJ_ROOT)/rtl
RUN        := $(PROJ_ROOT)/run
RV_ROOT    := $(RTL)/Cores-VeeR-EL2

# -----------------------------------------------------------------------
# Tools
# -----------------------------------------------------------------------
PYTHON3    := python3
BASH       := bash
VCS        := vcs

# -----------------------------------------------------------------------
# Files
# -----------------------------------------------------------------------
BOOT_S     := $(RTL)/sw/src/boot.s
BOOT_LD    := $(RTL)/sw/src/boot.ld
BOOT_ELF   := $(RTL)/sw/build/boot.elf
BOOT_HEX   := $(RTL)/sw/hex/boot.hex
VEER_CFG   := $(RV_ROOT)/configs/common_defines.vh
SIMV       := $(RUN)/simv_veer_uart
FSDB       := $(RUN)/dump_veer_uart.fsdb

# -----------------------------------------------------------------------
# Parameters
# -----------------------------------------------------------------------
CYCLES     ?= 500000

# -----------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------
.PHONY: all config sw sim run verdi clean clean_all help

# -----------------------------------------------------------------------
# Default target
# -----------------------------------------------------------------------
all: config sw sim run

# -----------------------------------------------------------------------
# 1. Generate VeeR EL2 configuration headers
# -----------------------------------------------------------------------
config: $(VEER_CFG)

$(VEER_CFG):
	@echo ""
	@echo "=== STEP 1: Generate VeeR config headers ==="
	$(BASH) $(SCRIPTS)/gen_veer_config.sh

# -----------------------------------------------------------------------
# 2. Compile RISC-V boot program
# -----------------------------------------------------------------------
sw: $(BOOT_HEX)

$(BOOT_HEX): $(BOOT_ELF)
	@echo ""
	@echo "=== STEP 2b: Generate ROM hex ==="
	$(PYTHON3) $(SCRIPTS)/gen_hex.py $(BOOT_ELF) $(BOOT_HEX)

$(BOOT_ELF): $(BOOT_S) $(BOOT_LD)
	@echo ""
	@echo "=== STEP 2a: Compile boot.s ==="
	$(BASH) $(SCRIPTS)/compile_boot.sh

# -----------------------------------------------------------------------
# 3. Build simulation with VCS
# -----------------------------------------------------------------------
sim: $(SIMV)

$(SIMV): $(VEER_CFG) $(BOOT_HEX)
	@echo ""
	@echo "=== STEP 3: Build simulation ==="
	$(BASH) $(SCRIPTS)/build_sim.sh

# -----------------------------------------------------------------------
# 4. Run simulation
# -----------------------------------------------------------------------
run: $(SIMV)
	@echo ""
	@echo "=== STEP 4: Run simulation ($(CYCLES) cycles) ==="
	$(BASH) $(SCRIPTS)/run_sim.sh $(CYCLES)

# -----------------------------------------------------------------------
# 5. Open waveform in Verdi
# -----------------------------------------------------------------------
verdi:
	@if [ ! -f "$(FSDB)" ]; then \
	    echo "[ERROR] No waveform found. Run 'make run' first."; \
	    exit 1; \
	fi
	@echo "Opening waveform in Verdi ..."
	verdi -ssf $(FSDB) &

# -----------------------------------------------------------------------
# Clean
# -----------------------------------------------------------------------
clean:
	@echo "Cleaning simulation artifacts ..."
	rm -f  $(RUN)/simv_veer_uart
	rm -rf $(RUN)/simv_veer_uart.daidir
	rm -rf $(RUN)/csrc
	rm -f  $(RUN)/compile.log
	rm -f  $(RUN)/sim_veer_uart.log
	rm -f  $(RUN)/uart_output.txt
	rm -f  $(RUN)/dump_veer_uart.fsdb
	rm -f  $(RUN)/ucli.key
	rm -f  $(RTL)/sw/build/boot.elf
	rm -f  $(RTL)/sw/build/boot.bin
	rm -f  $(RTL)/sw/build/boot.dump
	rm -f  $(RTL)/sw/hex/boot.hex
	@echo "Clean done."

clean_all: clean
	@echo "Removing VeeR config headers ..."
	rm -f  $(RV_ROOT)/configs/common_defines.vh
	rm -f  $(RV_ROOT)/configs/el2_param.vh
	rm -f  $(RV_ROOT)/configs/el2_pdef.vh
	rm -f  $(RV_ROOT)/configs/defines.h
	rm -f  $(RV_ROOT)/configs/link.ld
	rm -f  $(RV_ROOT)/configs/pd_defines.vh
	rm -f  $(RV_ROOT)/configs/perl_configs.pl
	rm -f  $(RV_ROOT)/configs/whisper.json
	@echo "Clean all done."

# -----------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------
help:
	@echo ""
	@echo "VeeR EL2 + UART SoC — Build System"
	@echo "===================================="
	@echo ""
	@echo "  make all          Full flow (config + sw + sim + run)"
	@echo "  make config       Generate VeeR EL2 config headers only"
	@echo "  make sw           Compile RISC-V boot program only"
	@echo "  make sim          Build VCS simulation binary only"
	@echo "  make run          Run simulation (default 500000 cycles)"
	@echo "  make run CYCLES=N Run simulation for N cycles"
	@echo "  make verdi        Open last waveform in Verdi"
	@echo "  make clean        Remove simulation/build outputs"
	@echo "  make clean_all    Remove everything including config headers"
	@echo ""
	@echo "  Scripts:"
	@echo "    Scripts/gen_veer_config.sh  — VeeR config header generator"
	@echo "    Scripts/compile_boot.sh     — RISC-V assembly compiler"
	@echo "    Scripts/gen_hex.py          — ELF to ROM hex converter"
	@echo "    Scripts/build_sim.sh        — VCS compilation"
	@echo "    Scripts/run_sim.sh          — Simulation runner"
	@echo ""
