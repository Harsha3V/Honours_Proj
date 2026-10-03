#!/usr/bin/env python3
# =============================================================================
# gen_hex.py  —  Convert boot.elf  to  boot.hex  (64-bit ROM format)
#
# Usage:
#   python3 gen_hex.py                        # uses defaults
#   python3 gen_hex.py boot.elf boot.hex      # explicit paths
# =============================================================================

import sys
import os
import struct
import subprocess

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------
PROJ_ROOT   = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RTL_DIR     = os.path.join(PROJ_ROOT, "rtl")

DEFAULT_ELF = os.path.join(RTL_DIR, "sw", "build", "boot.elf")
DEFAULT_HEX = os.path.join(RTL_DIR, "sw", "hex",   "boot.hex")

OBJCOPY     = "/opt/riscv/bin/riscv64-unknown-elf-objcopy"
ROM_DEPTH   = 512        # number of 64-bit entries — must match ifu_rom_stub
NOP         = 0x00000013 # RISC-V NOP: ADDI x0, x0, 0

# -----------------------------------------------------------------------
def elf_to_bin(elf_path, bin_path):
    """Convert ELF to raw binary using objcopy."""
    print("[gen_hex] Converting ELF to binary: " + elf_path)
    result = subprocess.run(
        [OBJCOPY, "-O", "binary", "--gap-fill", "0x13", elf_path, bin_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if result.returncode != 0:
        print("[gen_hex] ERROR: objcopy failed:")
        print(result.stderr.decode("utf-8"))
        sys.exit(1)
    print("[gen_hex] Binary created: " + bin_path)

# -----------------------------------------------------------------------
def bin_to_hex(bin_path, hex_path, rom_depth):
    """Pack raw binary into 64-bit hex file for $readmemh."""
    print("[gen_hex] Packing binary to hex: " + hex_path)

    with open(bin_path, "rb") as f:
        raw = f.read()

    bin_size  = len(raw)
    max_bytes = rom_depth * 8   # ROM_DEPTH x 8 bytes per 64-bit entry

    if bin_size > max_bytes:
        print("[gen_hex] WARNING: binary (%d B) exceeds ROM (%d B). Truncating." % (bin_size, max_bytes))
        raw = raw[:max_bytes]

    # Pad to max_bytes with NOPs using extend (much faster than loop)
    pad_needed = max_bytes - len(raw)
    nop_word   = struct.pack("<I", NOP)  # 4 bytes
    nop_count  = (pad_needed + 3) // 4  # number of NOP words needed
    padded     = bytearray(raw) + bytearray(nop_word * nop_count)
    padded     = padded[:max_bytes]      # trim to exact size

    # Write hex file — each line = 64 bits = 2 x 32-bit words
    os.makedirs(os.path.dirname(hex_path), exist_ok=True)
    with open(hex_path, "w") as f:
        for i in range(0, len(padded), 8):
            lo = struct.unpack_from("<I", padded, i)[0]
            hi = struct.unpack_from("<I", padded, i + 4)[0]
            f.write("%08x%08x\n" % (hi, lo))

    entries = len(padded) // 8
    print("[gen_hex] Written %d x 64-bit entries to %s" % (entries, hex_path))
    print("[gen_hex] ROM usage: %d / %d bytes (%.1f%%)" % (
        bin_size, max_bytes, 100.0 * bin_size / max_bytes))

# -----------------------------------------------------------------------
def main():
    elf_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ELF
    hex_path = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_HEX

    if not os.path.exists(elf_path):
        print("[gen_hex] ERROR: ELF not found: " + elf_path)
        print("[gen_hex] Run compile_boot.sh first.")
        sys.exit(1)

    # Temp binary file alongside the ELF
    bin_path = elf_path.replace(".elf", ".bin")

    elf_to_bin(elf_path, bin_path)
    bin_to_hex(bin_path, hex_path, ROM_DEPTH)

    # Clean up temp binary
    if os.path.exists(bin_path):
        os.remove(bin_path)

    print("[gen_hex] Done.")
    print("[gen_hex] Load in simulation with:")
    print('          $readmemh("%s", rom);' % hex_path)

# -----------------------------------------------------------------------
if __name__ == "__main__":
    main()
