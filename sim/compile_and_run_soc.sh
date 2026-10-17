#!/usr/bin/env bash
# =============================================================================
# compile_and_run_soc.sh — Compile and Run VeeR EL2 Secure Gateway SoC in VCS
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

echo "=========================================================="
echo " [1/2] Compiling Full SoC with Synopsys VCS..."
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
    -f run_soc.f \
    -top tb_soc_top \
    -o simv_soc_tb

echo "=========================================================="
echo " [2/2] Running Simulation (simv_soc_tb)..."
echo "=========================================================="
./simv_soc_tb "$@"
