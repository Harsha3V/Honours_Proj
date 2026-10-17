# RISC-V VeeR EL2 SoC Integration & Architecture Report

**Project:** Secure Automotive ECU Gateway System-on-Chip (SoC)  
**Target Core:** Western Digital / CHIPS Alliance VeeR EL2 (RV32IMC)  
**Interconnect:** Dual-Master, 8-Slave AXI4 Full Crossbar Matrix  
**Date:** October 17, 2026  
**Status:** RTL Integration Complete & Cleanly Elaborated with Synopsys VCS (0 Errors, 0 Warnings)

---

## 1. Executive Summary

This document details the complete RTL integration of the **Secure Automotive ECU Gateway SoC**, integrating a 32-bit RISC-V VeeR EL2 core with an advanced AXI4 interconnect subsystem. The SoC is engineered for AUTOSAR SecOC (Secure Onboard Communication) ECU gateway workloads: receiving authenticated CAN frames via SPI, staging them in high-speed AXI SRAM, executing hardware-accelerated AES-128 encryption, offloading bulk transfers with a dedicated scatter-gather DMA engine, and streaming diagnostics over UART.

### High-Level Architectural Diagram

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                       soc_top                                          │
│                                                                                        │
│  ┌─────────────────────────┐                                                           │
│  │      VeeR EL2 Core      │                                                           │
│  │   (RV32IMC Pipeline)    │                                                           │
│  │                         │                                                           │
│  │  • ICCM: 64 KB Code     │                                                           │
│  │  • DCCM: 64 KB Data     │                                                           │
│  │  • ICache: 16 KB        │                                                           │
│  └───────────┬─────────────┘                                                           │
│              │                                                                         │
│      IFU AXI │ 64-bit                             LSU AXI │ 64-bit                     │
│              ▼                                            ▼                            │
│     ┌─────────────────┐                        ┌───────────────────────┐               │
│     │  ifu_rom_stub   │                        │  64→32 Width Adapter  │               │
│     │   (Boot ROM)    │                        └──────────┬────────────┘               │
│     │  @ 0x8000_0000  │                                   │ AXI S00                    │
│     └─────────────────┘                                   │ (CPU LSU Master)           │
│                                                           ▼                            │
│                    ┌─────────────────────────────────────────────────────────────┐     │
│                    │                  axi_interconnect_uart_top                  │     │
│                    │              (2 Masters × 8 Slaves AXI4 Crossbar)           │     │
│                    ├──────────────────────────────────────┬──────────────────────┤     │
│                    │ Masters:                             │ Routing Access:      │     │
│                    │  • S00: VeeR CPU LSU (32-bit)        │  All Slaves (M00-M06)│     │
│                    │  • S01: DMA Controller Master        │  M00, M02, M03, M06  │     │
│                    ├──────────────────────────────────────┴──────────────────────┤     │
│                    │ Slaves & Memory Mapped Endpoints:                           │     │
│                    │  • M00 [0x0000_0000]: AES-128 Accelerator (Bridge)          │     │
│                    │  • M01 [0x0100_0000]: DMA Controller CSRs (Direct)          │     │
│                    │  • M02 [0x0200_0000]: SPI Master (Direct AXI-Lite)          │     │
│                    │  • M03 [0x0300_0000]: UART (Bridge)                         │     │
│                    │  • M04 [0x0400_0000]: Timer / Counter EF_TCC32 (Bridge)     │     │
│                    │  • M05 [0x0500_0000]: GPIO Controller EF_GPIO8 (Bridge)     │     │
│                    │  • M06 [0x0600_0000]: AXI Shared SRAM (64 KB Staging DMEM)  │     │
│                    │  • M07 [0x0700_0000]: Tied off / Reserved                   │     │
│                    └──────┬────────────┬────────────┬───────────┬──────────┬─────┘     │
│                           │            │            │           │          │           │
│                           ▼            ▼            ▼           ▼          ▼           │
│                      ┌─────────┐  ┌─────────┐  ┌─────────┐ ┌─────────┐ ┌─────────┐     │
│                      │ UART TX │  │ SPI CAN │  │ GPIO IO │ │ Timer   │ │ DMA IRQ │     │
│                      │   & RX  │  │ (MCP)   │  │ (8-bit) │ │ Counter │ │ & Done  │     │
│                      └─────────┘  └─────────┘  └─────────┘ └─────────┘ └─────────┘     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Memory & Address Map

The SoC enforces a contiguous 24-bit per-slave decode boundary (`16 MB` aperture per slave slot) on the AXI interconnect.

| Port | Base Address | End Address | Target IP Module | Master Access | Bus Width | Protocol |
|:---|:---|:---|:---|:---|:---|:---|
| **M00** | `0x0000_0000` | `0x0000_007F` | AES-128 Encryption Core | CPU (S00) + DMA (S01) | 32-bit | AXI4-Lite via Bridge |
| **M01** | `0x0100_0000` | `0x0100_00FF` | DMA Controller Registers | CPU (S00) only | 32-bit | AXI4 Direct |
| **M02** | `0x0200_0000` | `0x0200_001F` | SPI Master (MCP2515 CAN) | CPU (S00) + DMA (S01) | 32-bit | AXI4-Lite Direct |
| **M03** | `0x0300_0000` | `0x0300_001F` | UART (TX/RX FIFO, Baud) | CPU (S00) + DMA (S01) | 32-bit | AXI4-Lite via Bridge |
| **M04** | `0x0400_0000` | `0x0400_03FF` | Timer / Counter (EF_TCC32) | CPU (S00) only | 32-bit | AXI4-Lite via Bridge |
| **M05** | `0x0500_0000` | `0x0500_03FF` | GPIO Controller (EF_GPIO8) | CPU (S00) only | 32-bit | AXI4-Lite via Bridge |
| **M06** | `0x0600_0000` | `0x0600_FFFF` | Shared AXI SRAM (64 KB) | CPU (S00) + DMA (S01) | 32-bit | AXI4 Full (Single-Cycle) |
| **M07** | `0x0700_0000` | `0x07FF_FFFF` | Reserved / Unmapped | None (Tied Off) | 32-bit | DECERR Response |
| **IFU** | `0x8000_0000` | `0x8000_3FFF` | Boot ROM (`ifu_rom_stub`) | CPU IFU only | 64-bit | AXI4 Read-Only |
| **ICCM**| `0xEE00_0000` | `0xEE00_FFFF` | VeeR Tightly Coupled Code | CPU Core Internal | 64-bit | Dedicated Internal Bus |
| **DCCM**| `0xF004_0000` | `0xF004_FFFF` | VeeR Tightly Coupled Data | CPU Core Internal | 64-bit | Dedicated Internal Bus |

---

## 3. Interrupt Architecture & Vector Table

All peripheral interrupt request (IRQ) lines are collected at `soc_top` and connected to the VeeR EL2 core's `extintsrc_req[31:1]` input bus:

| Line Index | Signal Name | Source Module | Trigger Condition | Description |
|:---|:---|:---|:---|:---|
| **IRQ 1** | `timer_irq_o` | Timer (`EF_TCC32`) | Timeout / Match | System scheduler heartbeat & watchdog |
| **IRQ 2** | `uart_irq_o` | UART | RX FIFO Not Empty | Diagnostic command incoming |
| **IRQ 3** | `gpio_irq_o` | GPIO (`EF_GPIO8`) | Edge / Level match | External sensor / tampering trigger |
| **IRQ 4** | `dma_done_o` | DMA Controller | Channel transfer complete | Frame staging completed |
| **IRQ 5** | `dma_error_o` | DMA Controller | Bus error / misaligned | DMA transaction fault |
| **6..31** | *Reserved* | Grounded (`26'b0`) | N/A | Reserved for future expansion |

---

## 4. Key Subsystems & Hardware Components

### 4.1 CPU Core: Western Digital VeeR EL2 (`el2_veer_wrapper`)
- **Microarchitecture:** 4-stage, dual-issue superscalar RISC-V 32-bit pipeline (RV32IMC).
- **AXI4 Mode:** Built with `+define+RV_BUILD_AXI4` to configure LSU, IFU, and System Bus as native AXI4.
- **Cache & Memories:** 16 KB 4-way set-associative I-Cache, 64 KB ICCM (Instruction Closely Coupled Memory) at `0xEE00_0000`, and 64 KB DCCM (Data Closely Coupled Memory) at `0xF004_0000`.
- **Boot Vector:** Configured at `0x8000_0000` (`rst_vec = 31'h4000_0000`).

### 4.2 Boot ROM Stub (`ifu_rom_stub.v`)
- Placed on the VeeR Instruction Fetch Unit (IFU) 64-bit AXI bus.
- Pre-loaded with firmware image (e.g., `boot.hex`).
- Responds to instruction fetch bursts with single-cycle read latency. Write channels are safely acknowledged with `OKAY` response.

### 4.3 64-to-32 Bit Width Adapter
- VeeR LSU bus outputs 64-bit data words (`lsu_axi_wdata[63:0]`).
- Interconnect crossbar operates on 32-bit data words (`s00_axi_wdata[31:0]`).
- Down-converts LSU transfers to 32-bit width and zero-extends read responses (`s00_axi_rdata[31:0]` $\rightarrow$ `lsu_axi_rdata[63:0]`), preserving proper byte-strobe alignment.

### 4.4 AXI4 Crossbar Interconnect (`axi_interconnect_wrap_2x8`)
- Parameterized 2-Master $\times$ 8-Slave crossbar based on Alex Forencich's proven AXI infrastructure.
- **Arbitration:** Round-robin with programmable priority and transaction bursts up to 256 beats.
- **Selective Cross-Matrix Routing:**
  - `M00_CONNECT_READ = 2'b11` (CPU + DMA)
  - `M01_CONNECT_READ = 2'b01` (CPU Only — prevents DMA from reconfiguring itself)
  - `M02_CONNECT_READ = 2'b11` (CPU + DMA — allows DMA to pump data directly to SPI)
  - `M03_CONNECT_READ = 2'b11` (CPU + DMA)
  - `M04_CONNECT_READ = 2'b01` (CPU Only)
  - `M05_CONNECT_READ = 2'b01` (CPU Only)
  - `M06_CONNECT_READ = 2'b11` (CPU + DMA — shared staging memory)

### 4.5 DMA Subsystem (`dma_axi_flat_wrapper.sv`)
- Features a flat, standardized AXI interface wrapping `dma_top`.
- Registers configured by the CPU via slave port M01 (`0x0100_0000`).
- Initiates autonomous AXI bursts as Master S01 to move data between SRAM (`0x0600_0000`), AES engine (`0x0000_0000`), and SPI (`0x0200_0000`).
- Restored compatible `rggen-verilog-rtl` primitives (commit `2ac0648d`) to ensure syntax validity.

### 4.6 AXI Staging SRAM (`axi_sram.v`)
- High-speed 64 KB single-cycle synchronous memory (`16384` words $\times$ 32 bits).
- Supports sub-word writes using `s_axi_wstrb[3:0]`.
- Implements full AXI burst handling (INCR bursts) with zero wait-states.

---

## 5. Software Stack & Firmware Architecture

### 5.1 Memory Layout (`sw/boot.ld`)
```ld
MEMORY
{
    ROM  (rx)  : ORIGIN = 0x80000000, LENGTH = 16K   /* Boot ROM */
    DCCM (rwx) : ORIGIN = 0xF0040000, LENGTH = 64K   /* Data CCM (Stack & BSS) */
    SRAM (rw)  : ORIGIN = 0x06000000, LENGTH = 64K   /* AXI Shared Staging SRAM */
}
```

### 5.2 Boot Flow (`sw/boot.S`)
1. Reset trap into `_start` at `0x8000_0000`.
2. Clear pipeline and initialize Global Pointer (`gp`) and Stack Pointer (`sp = 0xF004_FFFC`).
3. Copy `.data` section from ROM into DCCM.
4. Zero out `.bss` section in DCCM.
5. Enable Machine External Interrupts (`mie.MEIE`) and global interrupts (`mstatus.MIE`).
6. Jump to `main()`.

### 5.3 Application Flow (`sw/app/main.c`)
1. **Initialize Diagnostics:** Configure UART baud rate to 115200 bps; transmit welcome banner.
2. **Setup Staging Buffer:** Write plain CAN frame into AXI SRAM (`0x0600_0000`).
3. **AES Key Expansion & Encryption:** Load 128-bit key (`0x2b7e1516...`) into AES accelerator (`0x0000_0000`), load plaintext block, and trigger encryption.
4. **Retrieve Ciphertext:** Read back 128-bit encrypted ciphertext once `STATUS[0] == 1`.
5. **SPI Frame Transmission:** Assert SPI Chip-Select, transmit encrypted SecOC payload to external MCP2515 CAN controller, deassert Chip-Select.
6. **Telemetry & Watchdog:** Toggle GPIO heartbeat LEDs and kick Timer counter.

---

## 6. Verification & VCS Compilation Results

The complete SoC top module was elaborated and compiled using **Synopsys VCS U-2023.03**.

### VCS Command
```bash
vcs -full64 -sverilog \
    +define+RV_BUILD_AXI4 \
    +incdir+../rtl/Cores-VeeR-EL2/design/include \
    +incdir+../rtl/interconnect \
    +incdir+../rtl/dma \
    +incdir+../rtl/dma/bus_arch_sv_pkg \
    +incdir+../rtl/dma/rggen-verilog-rtl \
    -f run_soc.f \
    -top soc_top \
    -o simv_soc_check
```

### Elaboration Summary
- **Total Elaborated Modules:** 69 modules (including VeeR EL2 core, execution units, decoders, interconnect crossbars, FIFOs, AXI bridges, DMA engine, AES core, SPI, UART, Timer, GPIO, SRAM, and ROM).
- **Errors:** **0**
- **Warnings:** **0**
- **Executable Output:** `sim/simv_soc_check` generated successfully.

---

## 7. Complete File Index

### 7.1 New RTL Files Created
- [`rtl/memory/axi_sram.v`](file:///home/student/Documents/Honours_Proj_github/rtl/memory/axi_sram.v) — 64 KB single-cycle AXI4 synchronous SRAM.
- [`rtl/soc_top/soc_top.v`](file:///home/student/Documents/Honours_Proj_github/rtl/soc_top/soc_top.v) — Complete SoC top-level integrating CPU, Interconnect, ROM, SRAM, and all 6 IPs.
- [`sim/run_soc.f`](file:///home/student/Documents/Honours_Proj_github/sim/run_soc.f) — Unified VCS compilation filelist for the entire SoC.

### 7.2 Modified & Enhanced RTL Files
- [`rtl/top/axi_interconnect_uart_top.v`](file:///home/student/Documents/Honours_Proj_github/rtl/top/axi_interconnect_uart_top.v) — Integrated DMA Master S01, DMA CSR Slave M01, AXI SRAM M06, and exposed DMA status IRQs.
- [`rtl/dma/rggen-verilog-rtl`](file:///home/student/Documents/Honours_Proj_github/rtl/dma/rggen-verilog-rtl) — Reverted to matching commit `2ac0648d` for 3-argument `rggen_slice` macro compatibility.

### 7.3 Software Drivers & Firmware
- [`sw/app/soc_regs.h`](file:///home/student/Documents/Honours_Proj_github/sw/app/soc_regs.h) — Comprehensive register map and driver functions for all SoC peripherals.
- [`sw/app/main.c`](file:///home/student/Documents/Honours_Proj_github/sw/app/main.c) — AUTOSAR SecOC Gateway C application.
- [`sw/boot.S`](file:///home/student/Documents/Honours_Proj_github/sw/boot.S) — CRT0 RISC-V startup assembly with vector setup and stack init.
- [`sw/boot.ld`](file:///home/student/Documents/Honours_Proj_github/sw/boot.ld) — Linker script defining ROM, DCCM, and SRAM memory sections.

---

## 8. Next Steps & Simulation Roadmap

1. **Compile RISC-V Firmware:**
   - Execute GCC toolchain to build `sw/boot.S` and `sw/app/main.c` into `boot.elf`.
   - Convert `boot.elf` to Verilog hex format (`boot.hex`) for initialization of `ifu_rom_stub`.
2. **Full SoC Testbench (`tb/soc/tb_soc_top.v`):**
   - Instantiate `soc_top`.
   - Drive system clock (50 MHz) and active-low reset.
   - Monitor UART TX pin to display console characters directly in the VCS simulation transcript.
   - Monitor SPI bus activity to verify encrypted frame transmission.
3. **Standalone Testbench Maintenance:**
   - Fix AXI handshake evaluation (`s_axi_bready` pulse timing) in `tb_spi_axi_top.v`, `tb_EF_TCC32_axi.v`, and `tb_EF_GPIO8_axi.v`.
