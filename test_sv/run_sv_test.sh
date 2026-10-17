#!/usr/bin/env bash
# =============================================================================
# run_sv_test.sh — Compile and Run VeeR EL2 SoC Simulation in Synopsys VCS
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Setup Synopsys License & Tools
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"
export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"
export RV_ROOT="../rtl/Cores-VeeR-EL2"

cd "$SCRIPT_DIR"

# 2. Check that boot.hex exists
if [ ! -f "boot.hex" ]; then
    if [ -f "$PROJ_ROOT/test_c/boot.hex" ]; then
        cp "$PROJ_ROOT/test_c/boot.hex" boot.hex
    elif [ -f "$PROJ_ROOT/sw/boot.hex" ]; then
        cp "$PROJ_ROOT/sw/boot.hex" boot.hex
    else
        echo "[INFO] boot.hex not found. Compiling C test firmware first..."
        "$PROJ_ROOT/test_c/run_c_test.sh"
        cp "$PROJ_ROOT/test_c/boot.hex" boot.hex
    fi
fi

echo "=========================================================="
echo " [SV Test] Compiling Full SoC with Synopsys VCS"
echo "=========================================================="
vcs -full64 -sverilog +define+RV_BUILD_AXI4 \
    +incdir+../rtl/Cores-VeeR-EL2/configs \
    +incdir+../rtl/Cores-VeeR-EL2/design/include \
    +incdir+../rtl/uart/include \
    +incdir+../rtl/aes \
    +incdir+../rtl/interconnect \
    +incdir+../rtl/dma \
    +incdir+../rtl/dma/rtl/inc \
    +incdir+../rtl/dma/bus_arch_sv_pkg \
    +incdir+../rtl/dma/rggen-verilog-rtl \
    -timescale=1ns/1ps \
    -f "$PROJ_ROOT/sim/run_soc.f" \
    -top tb_soc_top \
    -o simv_soc_tb

echo "=========================================================="
echo " [SV Test] Running Simulation (simv_soc_tb)..."
echo "=========================================================="
./simv_soc_tb "$@"
