#!/usr/bin/env bash
# =============================================================================
# run_sim.sh  —  Run VeeR UART SoC simulation
#
# Runs the compiled simulation binary and captures:
#   - UART TX output (characters sent by VeeR core)
#   - Simulation log
#   - FSDB waveform (for Verdi)
#
# Usage:
#   ./Scripts/run_sim.sh                  # default 500000 cycles
#   ./Scripts/run_sim.sh 1000000          # custom cycle count
#
# After running, open waveform:
#   verdi -ssf run/dump_veer_uart.fsdb &
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_DIR="$PROJ_ROOT/run"

SIMV="$RUN_DIR/simv_veer_uart"
MAX_CYCLES="${1:-500000}"
SIM_LOG="$RUN_DIR/sim_veer_uart.log"
UART_LOG="$RUN_DIR/uart_output.txt"

echo "============================================"
echo " run_sim.sh  —  VeeR UART SoC"
echo "============================================"
echo " Simv      : $SIMV"
echo " Max cycles: $MAX_CYCLES"
echo " Log       : $SIM_LOG"
echo " UART out  : $UART_LOG"
echo ""

# -----------------------------------------------------------------------
# Check simulation binary exists
# -----------------------------------------------------------------------
if [ ! -f "$SIMV" ]; then
    echo "[run_sim] ERROR: Simulation binary not found: $SIMV"
    echo "[run_sim] Run './Scripts/build_sim.sh' first."
    exit 1
fi

# -----------------------------------------------------------------------
# Run simulation
# -----------------------------------------------------------------------
echo "[run_sim] Starting simulation ..."
echo ""

cd "$RUN_DIR"

"$SIMV" \
    +max_cycles="$MAX_CYCLES" \
    -l "$SIM_LOG" \
    +fsdbfile+dump_veer_uart.fsdb \
    2>&1 | tee /dev/tty | grep -E "UART|Hello|Error|Finish|cycles|WARNING" \
    > "$UART_LOG" || true

echo ""
echo "============================================"
echo " Simulation COMPLETE"
echo ""

# -----------------------------------------------------------------------
# Show UART output captured by testbench
# -----------------------------------------------------------------------
echo " UART output received by testbench:"
echo "--------------------------------------------"
if grep -q "UART RX" "$SIM_LOG" 2>/dev/null; then
    grep "UART RX" "$SIM_LOG"
else
    echo " (check $SIM_LOG for full output)"
fi

echo ""
echo " Log      : $SIM_LOG"
echo " Waveform : $RUN_DIR/dump_veer_uart.fsdb"
echo ""
echo " View waveform:"
echo "   verdi -ssf $RUN_DIR/dump_veer_uart.fsdb &"
echo "============================================"
