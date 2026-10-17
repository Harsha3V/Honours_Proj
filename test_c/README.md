# C Test Directory (`test_c/`)

This directory contains the standalone environment to compile and verify the C test firmware for the RISC-V SoC.

## Quick Start

```bash
cd test_c
./run_c_test.sh
```

or simply:

```bash
cd test_c
make
```

## What This Does

1. Invokes the RISC-V 32-bit GCC compiler (`riscv-none-elf-gcc`) with RV32IMC architecture flags.
2. Compiles `sw/boot.S` (bootloader + vector setup) and `sw/app/main.c` (AUTOSAR SecOC gateway application).
3. Produces:
   - `boot.elf`: Linked RISC-V executable.
   - `boot.dump`: Assembly disassembly with source mapping.
   - `boot.bin`: Raw flat binary image.
   - `boot.hex`: Formatted 32-bit word ASCII hex file used by `$readmemh` in hardware simulations.
4. Automatically copies `boot.hex` to `sim/boot.hex` and `test_sv/boot.hex` so the SystemVerilog simulator is always synchronized.
