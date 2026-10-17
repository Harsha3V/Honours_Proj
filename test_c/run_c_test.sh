#!/usr/bin/env bash
# =============================================================================
# run_c_test.sh — Compile C Firmware Test and Generate Memory Hex for SoC
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Locate RISC-V GCC Toolchain
TOOLCHAIN_DIR="/home/student/tools/xpack-riscv-none-elf-gcc-14.3.0-1/bin"
if [ -d "$TOOLCHAIN_DIR" ]; then
    export PATH="$TOOLCHAIN_DIR:$PATH"
fi

if ! command -v riscv-none-elf-gcc &> /dev/null; then
    echo "[ERROR] riscv-none-elf-gcc not found in PATH or $TOOLCHAIN_DIR"
    exit 1
fi

CC="riscv-none-elf-gcc"
OBJCOPY="riscv-none-elf-objcopy"
OBJDUMP="riscv-none-elf-objdump"

echo "=========================================================="
echo " [C Test] Compiling Autonomous ECU Gateway C Firmware"
echo "=========================================================="

CFLAGS=(
    -march=rv32imc_zicsr
    -mabi=ilp32
    -O2
    -ffreestanding
    -nostdlib
    -nostartfiles
    -fno-builtin
    -fno-delete-null-pointer-checks
    -Wall
    -Wextra
    -Wno-array-bounds
    -I"$PROJ_ROOT/sw/app"
)

LDFLAGS=(
    -T "$PROJ_ROOT/sw/boot.ld"
    -Wl,--build-id=none
    -Wl,--strip-debug
)

SRC_BOOT="$PROJ_ROOT/sw/boot.S"
SRC_APP="$PROJ_ROOT/sw/app/main.c"
OUT_ELF="$SCRIPT_DIR/boot.elf"
OUT_DUMP="$SCRIPT_DIR/boot.dump"
OUT_BIN="$SCRIPT_DIR/boot.bin"
OUT_HEX="$SCRIPT_DIR/boot.hex"

echo "[1/4] Compiling $SRC_BOOT and $SRC_APP -> $(basename "$OUT_ELF")..."
$CC "${CFLAGS[@]}" "${LDFLAGS[@]}" "$SRC_BOOT" "$SRC_APP" -o "$OUT_ELF"

echo "[2/4] Generating disassembly -> $(basename "$OUT_DUMP")..."
$OBJDUMP -D -S "$OUT_ELF" > "$OUT_DUMP"

echo "[3/4] Converting ELF to binary -> $(basename "$OUT_BIN")..."
$OBJCOPY -O binary "$OUT_ELF" "$OUT_BIN"

echo "[4/4] Generating 32-bit word hex -> $(basename "$OUT_HEX") for \$readmemh..."
python3 -c "
with open('$OUT_BIN', 'rb') as f:
    data = f.read()

words = []
for i in range(0, len(data), 4):
    chunk = data[i:i+4]
    if len(chunk) < 4:
        chunk = chunk + b'\x00' * (4 - len(chunk))
    val = int.from_bytes(chunk, byteorder='little')
    words.append(f'{val:08x}')

target_depth = 4096
while len(words) < target_depth:
    words.append('00000013')  # NOP padding

with open('$OUT_HEX', 'w') as f:
    for w in words:
        f.write(w + '\n')
"

# Synchronize generated boot.hex with sw/, sim/, and test_sv/
cp "$OUT_HEX" "$PROJ_ROOT/sw/boot.hex"
cp "$OUT_HEX" "$PROJ_ROOT/sim/boot.hex"
mkdir -p "$PROJ_ROOT/test_sv"
cp "$OUT_HEX" "$PROJ_ROOT/test_sv/boot.hex"

echo "=========================================================="
echo " C Test Compilation Successful!"
echo " ELF   : $OUT_ELF"
echo " DUMP  : $OUT_DUMP"
echo " HEX   : $OUT_HEX (4096 words, copied to sim/ and test_sv/)"
echo "=========================================================="
