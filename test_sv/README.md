# SystemVerilog Test Directory (`test_sv/`)

This directory contains the standalone SystemVerilog simulation environment for the VeeR EL2 Secure Gateway SoC using Synopsys VCS.

## Quick Start

```bash
cd test_sv
./run_sv_test.sh
```

or simply:

```bash
cd test_sv
make
```

## Running with Waveforms

To dump VCD waveforms and open them in Synopsys Verdi:

```bash
make dump    # Runs simulation and dumps simv_soc_top.vcd
make verdi   # Opens waveform in Verdi GUI
```

## What This Does

1. Sets up the Synopsys VCS license (`27021@14.139.1.126`) and tool path.
2. Compiles:
   - Full SoC RTL (`rtl/soc_top/soc_top.v`)
   - VeeR EL2 core (`rtl/Cores-VeeR-EL2`)
   - All 7 AXI peripherals (AES-128, DMA, SPI, UART, Timer, GPIO, SRAM)
   - Testbench (`tb/soc/tb_soc_top.v`)
3. Loads `boot.hex` into the simulated Boot ROM via `$readmemh`.
4. Executes the simulation and live-streams UART ASCII and SPI CAN frames to the console.
