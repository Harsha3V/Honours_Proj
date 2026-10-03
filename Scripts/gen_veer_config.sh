#!/usr/bin/env bash
# =============================================================================
# gen_veer_config.sh  —  Generate VeeR EL2 configuration header files
#
# Runs the VeeR Perl configuration script (configs/veer.config) with
# AXI4 build mode and places the output headers into the configs/ directory.
#
# Generated files:
#   configs/common_defines.vh   — `define macros (RV_BUILD_AXI4 etc.)
#   configs/el2_param.vh        — parameter struct for el2_veer_wrapper
#   configs/el2_pdef.vh         — package definitions
#   configs/defines.h           — C header (for software builds)
#   configs/link.ld             — default linker script
#
# Usage:
#   ./Scripts/gen_veer_config.sh              # from project root
#   bash Scripts/gen_veer_config.sh
# =============================================================================

set -e   # exit on first error

# -----------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RV_ROOT="$PROJ_ROOT/rtl/Cores-VeeR-EL2"
CONFIG_SCRIPT="$RV_ROOT/configs/veer.config"
OUTPUT_DIR="$RV_ROOT/configs"

echo "============================================"
echo " gen_veer_config.sh"
echo "============================================"
echo " RV_ROOT    : $RV_ROOT"
echo " Output dir : $OUTPUT_DIR"
echo ""

# -----------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------
if [ ! -d "$RV_ROOT" ]; then
    echo "[ERROR] VeeR EL2 not found at: $RV_ROOT"
    echo "        Run:  git clone https://github.com/chipsalliance/Cores-VeeR-EL2 \\"
    echo "                   $RV_ROOT"
    exit 1
fi

if [ ! -f "$CONFIG_SCRIPT" ]; then
    echo "[ERROR] veer.config script not found: $CONFIG_SCRIPT"
    exit 1
fi

# -----------------------------------------------------------------------
# Run VeeR configuration
#   -set build_axi4     → select AXI4 bus interface (not AHB)
#   -target=default     → default VeeR EL2 configuration
# -----------------------------------------------------------------------
echo "[gen_veer_config] Running veer.config ..."
BUILD_PATH="$OUTPUT_DIR" \
    "$CONFIG_SCRIPT" \
    -target=default \
    -set build_axi4

echo ""
echo "[gen_veer_config] Generated files:"
for f in common_defines.vh el2_param.vh el2_pdef.vh defines.h link.ld; do
    if [ -f "$OUTPUT_DIR/$f" ]; then
        echo "   OK  $OUTPUT_DIR/$f"
    else
        echo "   MISSING  $OUTPUT_DIR/$f"
    fi
done

echo ""
echo "[gen_veer_config] Key parameters confirmed:"
grep -E "lsu_bus_tag|ifu_bus_tag|build_axi4|reset_vec" \
    "$OUTPUT_DIR/common_defines.vh" | head -10

echo ""
echo "[gen_veer_config] Done."
