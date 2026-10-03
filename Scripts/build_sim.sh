#!/usr/bin/env bash
# =============================================================================
# build_sim.sh  —  Compile the VeeR + UART SoC with Synopsys VCS
#
# What it does:
#   1. Checks that VeeR config headers exist (runs gen_veer_config.sh if not)
#   2. Checks that boot.hex exists (runs gen_hex.py if not)
#   3. Runs VCS to elaborate and compile the full design + testbench
#   4. Produces the simulation binary:  run/simv_veer_uart
#
# Usage:
#   ./Scripts/build_sim.sh              # from project root
#   bash Scripts/build_sim.sh
#
# Optional env vars:
#   VCS_EXTRA_ARGS   — pass extra flags to VCS
# =============================================================================

set -e

# -----------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RV_ROOT="$PROJ_ROOT/rtl/Cores-VeeR-EL2"
RUN_DIR="$PROJ_ROOT/run"
SCRIPTS_DIR="$PROJ_ROOT/Scripts"

export PATH="/opt/riscv/bin:$PATH"

echo "============================================"
echo " build_sim.sh  —  VeeR UART SoC"
echo "============================================"
echo " PROJ_ROOT : $PROJ_ROOT"
echo " RV_ROOT   : $RV_ROOT"
echo " RUN_DIR   : $RUN_DIR"
echo ""

# -----------------------------------------------------------------------
# Step 1: Ensure VeeR config headers exist
# -----------------------------------------------------------------------
COMMON_DEF="$RV_ROOT/configs/common_defines.vh"
if [ ! -f "$COMMON_DEF" ]; then
    echo "[build_sim] VeeR config headers missing — running gen_veer_config.sh ..."
    bash "$SCRIPTS_DIR/gen_veer_config.sh"
else
    echo "[build_sim] VeeR config headers found. OK"
fi

# -----------------------------------------------------------------------
# Step 2: Ensure boot.elf and boot.hex exist
# -----------------------------------------------------------------------
ELF="$PROJ_ROOT/rtl/boot.elf"
HEX="$RUN_DIR/boot.hex"

if [ ! -f "$ELF" ]; then
    echo "[build_sim] boot.elf not found — compiling from boot.s ..."
    bash "$SCRIPTS_DIR/compile_boot.sh"
fi

if [ ! -f "$HEX" ]; then
    echo "[build_sim] boot.hex not found — running gen_hex.py ..."
    python3 "$SCRIPTS_DIR/gen_hex.py" "$ELF" "$HEX"
else
    echo "[build_sim] boot.hex found. OK"
fi

# -----------------------------------------------------------------------
# Step 3: Run VCS compilation
# -----------------------------------------------------------------------
echo ""
echo "[build_sim] Starting VCS compilation ..."
echo ""

cd "$RUN_DIR"

vcs \
    -full64 \
    -debug_access+all \
    -kdb \
    -sverilog \
    +define+RV_BUILD_AXI4 \
    +incdir+"$RV_ROOT/design/include" \
    +incdir+"$RV_ROOT/configs" \
    +incdir+"$PROJ_ROOT/rtl/uart/include" \
    -timescale=1ns/1ps \
    -f "$RUN_DIR/run_veer_uart_soc.f" \
    -top tb_veer_uart_soc \
    -l "$RUN_DIR/compile.log" \
    -o "$RUN_DIR/simv_veer_uart" \
    ${VCS_EXTRA_ARGS:-}

echo ""
echo "============================================"
echo " Build COMPLETE"
echo " Binary  : $RUN_DIR/simv_veer_uart"
echo " Log     : $RUN_DIR/compile.log"
echo " Run with: ./Scripts/run_sim.sh"
echo "============================================"
