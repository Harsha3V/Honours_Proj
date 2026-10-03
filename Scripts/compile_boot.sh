#!/usr/bin/env bash
# =============================================================================
# compile_boot.sh  —  Compile RISC-V boot assembly program
#
# Compiles rtl/boot.s using the RISC-V GCC toolchain into:
#   rtl/boot.elf   — ELF executable
#   rtl/boot.dump  — disassembly (for inspection)
#
# Then calls gen_hex.py to produce:
#   run/boot.hex   — 64-bit hex image for ifu_rom_stub
#
# Usage:
#   ./Scripts/compile_boot.sh
#   bash Scripts/compile_boot.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RTL_DIR="$PROJ_ROOT/rtl"
RUN_DIR="$PROJ_ROOT/run"

export PATH="/opt/riscv/bin:$PATH"

GCC="riscv64-unknown-elf-gcc"
OBJDUMP="riscv64-unknown-elf-objdump"

BOOT_S="$RTL_DIR/sw/src/boot.s"
BOOT_LD="$RTL_DIR/sw/src/boot.ld"
BOOT_ELF="$RTL_DIR/sw/build/boot.elf"
BOOT_DUMP="$RTL_DIR/sw/build/boot.dump"
BOOT_HEX="$RTL_DIR/sw/hex/boot.hex"

# Ensure output directories exist
mkdir -p "$RTL_DIR/sw/build"
mkdir -p "$RTL_DIR/sw/hex"

echo "============================================"
echo " compile_boot.sh"
echo "============================================"

# -----------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------
if [ ! -f "$BOOT_S" ]; then
    echo "[ERROR] boot.s not found: $BOOT_S"
    exit 1
fi
if [ ! -f "$BOOT_LD" ]; then
    echo "[ERROR] boot.ld not found: $BOOT_LD"
    exit 1
fi

# -----------------------------------------------------------------------
# Compile
# -----------------------------------------------------------------------
echo "[compile_boot] Compiling boot.s → boot.elf ..."
$GCC \
    -march=rv32imc \
    -mabi=ilp32 \
    -nostdlib \
    -nostartfiles \
    -T "$BOOT_LD" \
    -o "$BOOT_ELF" \
    "$BOOT_S"

echo "[compile_boot] ELF created: $BOOT_ELF"

# -----------------------------------------------------------------------
# Disassembly (useful for debugging)
# -----------------------------------------------------------------------
echo "[compile_boot] Generating disassembly → boot.dump ..."
$OBJDUMP -d "$BOOT_ELF" > "$BOOT_DUMP"
echo "[compile_boot] Disassembly saved: $BOOT_DUMP"

# -----------------------------------------------------------------------
# Show entry point and sections
# -----------------------------------------------------------------------
echo ""
echo "[compile_boot] ELF sections:"
$OBJDUMP -h "$BOOT_ELF" | grep -E "Idx|\.text|\.rodata|\.bss"

echo ""
echo "[compile_boot] First 10 instructions:"
$OBJDUMP -d "$BOOT_ELF" | grep -A 20 "<_start>" | head -15

# -----------------------------------------------------------------------
# Generate hex
# -----------------------------------------------------------------------
echo ""
echo "[compile_boot] Generating boot.hex ..."
mkdir -p "$RUN_DIR"
python3 "$SCRIPT_DIR/gen_hex.py" "$BOOT_ELF" "$BOOT_HEX"

echo ""
echo "============================================"
echo " Compile COMPLETE"
echo " ELF  : $BOOT_ELF"
echo " HEX  : $BOOT_HEX"
echo " DUMP : $BOOT_DUMP"
echo "============================================"
