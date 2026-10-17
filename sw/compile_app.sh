#!/usr/bin/env bash
# =============================================================================
# compile_app.sh — Compile AUTOSAR SecOC Gateway C Application to boot.hex
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Add RISC-V GCC toolchain to PATH
export PATH="/home/student/tools/xpack-riscv-none-elf-gcc-14.3.0-1/bin:$PATH"

CC="riscv-none-elf-gcc"
OBJDUMP="riscv-none-elf-objdump"
OBJCOPY="riscv-none-elf-objcopy"

if ! command -v "$CC" &> /dev/null; then
    echo "[ERROR] $CC not found in PATH! Check /home/student/tools installation."
    exit 1
fi

SW_DIR="$PROJ_ROOT/sw"
BOOT_S="$SW_DIR/boot.S"
BOOT_LD="$SW_DIR/boot.ld"
APP_C="$SW_DIR/app/main.c"
ELF="$SW_DIR/boot.elf"
DUMP="$SW_DIR/boot.dump"
BIN="$SW_DIR/boot.bin"
HEX="$SW_DIR/boot.hex"

echo "=========================================================="
echo " [compile_app] Compiling C Firmware with RISC-V GCC"
echo "=========================================================="

echo "[1/4] Compiling sw/boot.S and sw/app/main.c -> boot.elf..."
$CC -march=rv32imc_zicsr -mabi=ilp32 -O2 \
    -fno-delete-null-pointer-checks \
    -nostdlib -nostartfiles -ffreestanding \
    -I "$SW_DIR/app" \
    -T "$BOOT_LD" \
    "$BOOT_S" "$APP_C" \
    -o "$ELF"

echo "[2/4] Generating disassembly -> boot.dump..."
$OBJDUMP -d "$ELF" > "$DUMP"

echo "[3/4] Converting ELF to raw binary -> boot.bin..."
$OBJCOPY -O binary "$ELF" "$BIN"

echo "[4/4] Formatting 32-bit word hex -> boot.hex (for \$readmemh)..."
python3 - << 'EOF'
import struct, sys

bin_file = "sw/boot.bin"
hex_file = "sw/boot.hex"
ROM_WORDS = 4096 # 16 KB Boot ROM
NOP = 0x00000013

with open(bin_file, "rb") as f:
    raw = f.read()

words = []
for i in range(0, len(raw), 4):
    chunk = raw[i:i+4]
    if len(chunk) < 4:
        chunk = chunk.ljust(4, b'\x00')
    val = struct.unpack("<I", chunk)[0]
    words.append(val)

# Pad to ROM_WORDS with NOP
while len(words) < ROM_WORDS:
    words.append(NOP)

with open(hex_file, "w") as f:
    for w in words:
        f.write(f"{w:08x}\n")

print(f" -> Generated {len(words)} x 32-bit words ({len(raw)} bytes binary code) into {hex_file}")
EOF

# Copy to sim directory so testbench can find it
cp "$HEX" "$PROJ_ROOT/sim/boot.hex"
echo " -> Copied boot.hex to sim/boot.hex"

echo "=========================================================="
echo " Compilation Successful!"
echo " ELF  : $ELF"
echo " DUMP : $DUMP"
echo " HEX  : $HEX"
echo "=========================================================="
