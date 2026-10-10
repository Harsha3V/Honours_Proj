# RISC-V Hardware-Accelerated Encrypted ECU Gateway SoC

**Honours Final Year Project — RTL Design & Verification**
**Roll No: 1602-23-735-189**

[![Language](https://img.shields.io/badge/Language-Verilog%20%2F%20SystemVerilog-blue)]()
[![Simulator](https://img.shields.io/badge/Simulator-Synopsys%20VCS%202023.03-orange)]()
[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32IMC-green)]()
[![Bus](https://img.shields.io/badge/Bus-AXI4-purple)]()
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)]()

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Proposed Solution](#2-proposed-solution)
3. [SoC Architecture](#3-soc-architecture)
4. [Memory Map](#4-memory-map)
5. [IP Blocks](#5-ip-blocks)
6. [Data Flow](#6-data-flow)
7. [Repository Structure](#7-repository-structure)
8. [Implementation Progress](#8-implementation-progress)
9. [Simulation Results](#9-simulation-results)
10. [How to Simulate](#10-how-to-simulate)
11. [Tools & Environment](#11-tools--environment)
12. [References](#12-references)

---

## 1. Problem Statement

Modern vehicles contain dozens of **Electronic Control Units (ECUs)** — small computers controlling safety-critical functions like braking, steering, throttle, and airbags. These ECUs communicate over an internal vehicle network called the **CAN bus (Controller Area Network)**.

**The Security Problem:**
CAN bus was designed in the 1980s with **zero security**. Every message is broadcast in unencrypted plaintext. This means:
- An attacker with physical or remote access can **read all vehicle data**
- An attacker can **inject fake commands** — e.g., fake "brake = 0" — causing safety failures
- Modern standards (AUTOSAR SecOC) require **AES-128 encryption** on every safety-critical frame

**The Performance Problem:**
Encrypting AES-128 **in software** on a small RISC-V microcontroller adds **~2 milliseconds per block** — far exceeding microsecond real-time control deadlines. Software AES also consumes 100% of CPU bandwidth, leaving nothing for actual vehicle control.

---

## 2. Proposed Solution

This project builds a **RISC-V SoC with a hardware encryption pipeline** that:

1. **Receives** plaintext ECU frames over UART
2. **Encrypts** them autonomously using a hardware AES-128 engine
3. **Dispatches** the encrypted frames via SPI to an external CAN controller (MCP2515)
4. **Frees the CPU** completely — the RISC-V core only configures and supervises

The CPU never touches payload data during normal operation. Encryption and data movement happen entirely in hardware, at line-rate, with zero CPU overhead.

---

## 3. SoC Architecture

### Bus Structure

| Item | Detail |
|------|--------|
| Protocol | AXI4 only (no AHB, no APB) |
| Interconnect | 2 Masters × 8 Slaves crossbar |
| Master 0 (S00) | VeeR EL2 CPU — Load/Store Unit |
| Master 1 (S01) | DMA Controller — autonomous data movement |

### Block Diagram

```
                        ┌────────────────────────────┐
  boot.hex ────────────►│       VeeR EL2 CPU          │
                        │  ┌──────────┐ ┌──────────┐  │
                        │  │  ICCM    │ │  DCCM    │  │
                        │  │  64KB    │ │  64KB    │  │
                        │  │ (code)   │ │ (data)   │  │
                        │  └──────────┘ └──────────┘  │
                        └──────────────┬───────────────┘
                                       │ AXI4 LSU (Master 0)
                                       ▼
                        ┌──────────────────────────────────┐
                        │   AXI4 Interconnect  (2 × 8)     │
                        │   ◄── CPU (S00)                  │
                        │   ◄── DMA (S01)                  │
                        └──┬────┬────┬────┬────┬───────────┘
                           │    │    │    │    │
                          M00  M01  M02  M03  M04  M05
                          AES  DMA  SPI  UART Timer GPIO
                          ↓    ↓    ↓    ↓    ↓    ↓
                       0x0000 0x0100 0x0200 0x0300 0x0400 0x0500
                       _0000  _0000  _0000  _0000  _0000  _0000
```

### Internal CPU Memories (NOT on AXI bus)

| Memory | Address | Size | Purpose |
|--------|---------|------|---------|
| ICCM | `0xEE00_0000` | 64 KB | Instruction RAM — stores firmware code |
| DCCM | `0xF004_0000` | 64 KB | Data RAM — stack, variables, DMA buffers |
| ICache | Internal | 16 KB | Instruction cache |

These are tightly coupled SRAMs directly inside the VeeR EL2 core — single-cycle access, no AXI transaction needed.

---

## 4. Memory Map

| Slot | Base Address | End Address | Peripheral | Status |
|------|-------------|-------------|------------|--------|
| M00 | `0x0000_0000` | `0x00FF_FFFF` | AES-128 Engine | ✅ Wired |
| M01 | `0x0100_0000` | `0x01FF_FFFF` | DMA Controller CSR | ⚠️ Flat wrapper ready, wiring pending |
| M02 | `0x0200_0000` | `0x02FF_FFFF` | SPI Master | ✅ Wired |
| M03 | `0x0300_0000` | `0x03FF_FFFF` | UART | ✅ Wired |
| M04 | `0x0400_0000` | `0x04FF_FFFF` | Timer (EF_TCC32) | ✅ Wired |
| M05 | `0x0500_0000` | `0x05FF_FFFF` | GPIO (EF_GPIO8) | ✅ Wired |
| M06 | `0x0600_0000` | `0x06FF_FFFF` | — | Tied off |
| M07 | `0x0700_0000` | `0x07FF_FFFF` | — | Tied off |

Each slot has a dedicated **16 MB** region — no overlaps, 4KB aligned.

---

## 5. IP Blocks

### AES-128 Encryption Engine — M00 (`0x0000_0000`)
- Hardware 10-round AES-128 pipeline (NIST FIPS-197 compliant)
- Both **encrypt** and **decrypt** paths implemented
- CPU writes 128-bit key + plaintext, asserts START → engine runs autonomously
- DONE interrupt fires when ciphertext is ready
- Bridge: `axi_to_axilite_aes_bridge.v`

| Offset | Register | Access | Description |
|--------|----------|--------|-------------|
| `0x00` | CSR | R/W | bit16=START, bit1=BUSY, bit0=DONE |
| `0x04–0x10` | KEY[0:3] | R/W | 128-bit encryption key |
| `0x14–0x20` | TEXTIN[0:3] | R/W | 128-bit plaintext input |
| `0x24–0x30` | TEXTOUT[0:3] | R | 128-bit ciphertext output |
| `0x40` | INV_CSR | R/W | bit17=START, bit16=KEY_LOAD, bit0=DONE |
| `0x44–0x70` | INV_KEY/TEXTIN/TEXTOUT | R/W | Decrypt path registers |

### DMA Controller — M01 (`0x0100_0000`) + S01 Master
- Source: [aignacio/axi_dma](https://github.com/aignacio/axi_dma)
- **CSR Slave (M01):** CPU configures source, destination, byte count, GO bit
- **AXI4 Master (S01):** DMA moves data autonomously between any two AXI addresses
- Custom flat wrapper: `dma_axi_flat_wrapper.sv` (converts SV structs → flat wires)

| Offset | Register | Description |
|--------|----------|-------------|
| `0x00` | DMA_CONTROL | bit0=GO, bit1=ABORT |
| `0x08` | DMA_STATUS | bit16=DONE, bit17=ERROR |
| `0x20/0x28` | DESC0/1_SRC_ADDR | Source address |
| `0x30/0x38` | DESC0/1_DST_ADDR | Destination address |
| `0x40/0x48` | DESC0/1_NUM_BYTES | Byte count |

### SPI Master — M02 (`0x0200_0000`)
- Source: `SPI_Master_With_Single_CS.v` (Verilog, open-source)
- 4-wire SPI: SCLK, MOSI, MISO, CS_N
- Mode 0 (CPOL=0, CPHA=0), clock = system_clk / 4
- Connects to external **MCP2515 CAN controller** chip

| Offset | Register | Access | Description |
|--------|----------|--------|-------------|
| `0x00` | TX_DATA | W | Write byte → triggers SPI transmission |
| `0x04` | RX_DATA | R | Last received byte from MISO |
| `0x08` | STATUS | R | bit0=TX_READY, bit1=RX_DV |
| `0x0C` | TX_COUNT | R/W | Bytes per CS transaction |

### UART — M03 (`0x0300_0000`)
- Full-duplex UART with TX/RX FIFOs
- Configurable baud rate via divisor register
- Interrupt on RX data ready (IER register)
- Bridge: `axi_to_axilite_uart_bridge.v`

| Offset | Register | Description |
|--------|----------|-------------|
| `0x00` | RBR / THR | Receive buffer (R) / Transmit holding (W) |
| `0x04` | IER | Interrupt Enable Register |
| `0x08` | BAUD | Baud rate divisor |
| `0x0C` | LCR | Line Control (parity, stop bits, word length) |
| `0x14` | LSR | Line Status (TX empty, RX data ready) |

### Timer — M04 (`0x0400_0000`)
- Source: EF_TCC32 (efabless/anhducdinh IP)
- 32-bit down-counter with auto-reload and capture
- Fires `timer_irq` interrupt on underflow — used as system heartbeat
- Bridge: `axi_to_axilite_timer_bridge.v`

| Offset | Register | Description |
|--------|----------|-------------|
| `0x0000` | TIMER | Current counter value (RO) |
| `0x0004` | PERIOD | Reload value (RW) |
| `0x0010` | CONTROL | EN, TMR_EN, CLK_SRC, ONE_SHOT |
| `0x0F00` | ICR | Interrupt Clear (W1C) |
| `0x0F08` | IM | Interrupt Mask |

### GPIO — M05 (`0x0500_0000`)
- Source: EF_GPIO8 (efabless IP) — 8-bit bidirectional GPIO
- 2-stage metastability synchronizers on all inputs
- Per-pin edge detection (rising/falling) with interrupt mask
- Bridge: `axi_to_axilite_gpio_bridge.v`

| Offset | Register | Description |
|--------|----------|-------------|
| `0x0000` | DATAI | Input pin states (RO, synchronized) |
| `0x0004` | DATAO | Output data (RW) |
| `0x0008` | DIR | Direction: 1=output, 0=input |
| `0xFF00` | IM | Interrupt Mask |
| `0xFF08` | RIS | Raw Interrupt Status |

---

## 6. Data Flow

```
Source ECU
(plaintext frame)
      │
      │ uart_rx
      ▼
┌─────────┐   DMA reads    ┌──────────┐   DMA writes   ┌──────────┐
│  UART   │ ─────────────► │   DCCM   │ ─────────────► │ AES-128  │
│  RX     │  (UART→DCCM)   │ staging  │  (DCCM→AES)    │ Engine   │
└─────────┘                └──────────┘                └────┬─────┘
                                                            │ 10-round
                                                            │ hardware
                                                            ▼
┌──────────┐   DMA writes  ┌──────────┐   DMA reads   ┌──────────┐
│   SPI    │ ◄──────────── │   DCCM   │ ◄──────────── │  AES     │
│  Master  │  (DCCM→SPI)   │  output  │  (AES→DCCM)   │ TEXTOUT  │
└────┬─────┘               └──────────┘               └──────────┘
     │ spi_mosi
     ▼
MCP2515 CAN Controller
     │
     ▼
  CAN Bus → Destination ECU (receives encrypted frame)
```

**CPU Role (supervisor only):**
- Boot: loads AES key, configures DMA descriptors, sets timer period
- Runtime: sleeps between interrupts, handles faults via GPIO, debug via UART
- The CPU **never touches payload data** during normal operation

---

## 7. Repository Structure

```
Honours_Proj/
│
├── rtl/                          # Synthesizable RTL
│   ├── interconnect/             # AXI4 2×8 crossbar (arbiter, encoder, wrap_2x8)
│   ├── bridge/                   # AXI4 → AXI4-Lite bridges (AES, UART, Timer, GPIO)
│   ├── aes/                      # AES-128 engine (cipher, inv_cipher, sbox, key_expand)
│   ├── uart/                     # UART (controller, TX, RX, FIFOs, include/)
│   ├── spi/                      # SPI master + AXI4-Lite wrapper
│   ├── timer/                    # EF_TCC32 core + AXI4-Lite wrapper
│   ├── gpio/                     # EF_GPIO8 core + AXI4-Lite wrapper + sync
│   ├── dma/                      # aignacio/axi_dma + flat wrapper + submodules
│   ├── memory/                   # ifu_rom_stub (AXI4 boot ROM)
│   ├── top/                      # axi_interconnect_uart_top.v (6-IP integration)
│   └── soc_top/                  # Full SoC top (in progress)
│
├── tb/                           # Testbenches
│   ├── uart/                     # 6 UART testbenches — all passing ✅
│   ├── aes/                      # AES testbench — all passing ✅
│   ├── interconnect/             # AXI interconnect TB
│   ├── tb_axi_interconnect_uart_top.v  # 6-IP integration TB
│   └── soc/                      # Full SoC TB (in progress)
│
├── sim/                          # VCS simulation filelists
│   ├── run_uart.f                # UART simulation ✅
│   ├── run_aes.f                 # AES simulation ✅
│   ├── run_interconnect_uart.f   # 6-IP integration
│   └── run_dma.f                 # DMA compile check
│
├── sw/                           # RISC-V firmware
│   └── boot/                     # boot.S, boot.hex (NOP boot stub)
│
├── scripts/                      # Utility scripts
└── waveforms/                    # Simulation screenshots
    └── UART_wavef/
```

---

## 8. Implementation Progress

### ✅ RTL Complete & Simulated

| Module | File | Simulation |
|--------|------|------------|
| AXI4 Interconnect (2×8) | `rtl/interconnect/` | ✅ Passing |
| UART AXI4-Lite Slave | `rtl/uart/` | ✅ ALL 8 TESTS PASS |
| AXI4→AXI4-Lite Bridge (UART) | `rtl/bridge/axi_to_axilite_uart_bridge.v` | ✅ Passing |
| AES-128 Encrypt Engine | `rtl/aes/` | ✅ ALL TESTS PASS |
| AES-128 Decrypt Engine | `rtl/aes/` | ✅ NIST FIPS-197 verified |

### ✅ RTL Complete, Wired, Not Yet Simulated

| Module | File | Notes |
|--------|------|-------|
| SPI Master + AXI wrapper | `rtl/spi/spi_axi_top.v` | Wired at M02 |
| Timer EF_TCC32 + AXI wrapper | `rtl/timer/EF_TCC32_axi.v` | Wired at M04 |
| GPIO EF_GPIO8 + AXI wrapper | `rtl/gpio/EF_GPIO8_axi.v` | Wired at M05 |
| AXI→AXI-Lite Bridge (AES) | `rtl/bridge/axi_to_axilite_aes_bridge.v` | Wired at M00 |
| AXI→AXI-Lite Bridge (Timer) | `rtl/bridge/axi_to_axilite_timer_bridge.v` | Wired at M04 |
| AXI→AXI-Lite Bridge (GPIO) | `rtl/bridge/axi_to_axilite_gpio_bridge.v` | Wired at M05 |
| 6-IP Integration Top | `rtl/top/axi_interconnect_uart_top.v` | Compiles clean |

### ⚠️ Written, Not Yet Wired

| Module | File | Notes |
|--------|------|-------|
| DMA AXI Flat Wrapper | `rtl/dma/dma_axi_flat_wrapper.sv` | Compiles clean, M01+S01 wiring pending |

### ❌ Not Yet Written

| Module | Notes |
|--------|-------|
| Full SoC Top | `rtl/soc_top/soc_top.v` — wire VeeR EL2 + all IPs |
| Full SoC Testbench | `tb/soc/tb_soc_top.v` — end-to-end simulation |
| RISC-V Firmware | `sw/app/main.c` — AES encrypt + SPI send demo |

---

## 9. Simulation Results

### UART Simulation — ✅ ALL 8 TESTS PASSED

| Test | Description | Result |
|------|-------------|--------|
| TC1 | Reset check | ✅ PASS |
| TC2 | LCR + baud rate config | ✅ PASS |
| TC3 | TX byte 0x41 ('A') | ✅ PASS |
| TC4 | LSR read (TX empty) | ✅ PASS |
| TC5 | IER write (RX interrupt enable) | ✅ PASS |
| TC6 | RX byte 0x42 ('B') | ✅ PASS |
| TC7 | Loopback TX→RX 0x37 | ✅ PASS |
| TC8 | Unknown address (no hang) | ✅ PASS |

### AES Simulation — ✅ ALL TESTS PASSED

| Test | Description | Result |
|------|-------------|--------|
| TC1 | Reset check (CSR=0) | ✅ PASS |
| TC2 | Register read-back (KEY, TEXTIN) | ✅ PASS |
| TC3 | NIST FIPS-197 encrypt (Appendix B) | ✅ PASS |
| TC4 | Decrypt round-trip | ✅ PASS |
| TC5 | 5× encrypt/decrypt round-trip | ✅ PASS |
| TC6 | Read-only register protection | ✅ PASS |
| TC7 | Undefined address handling | ✅ PASS |

---

## 10. How to Simulate

All simulations run from the `sim/` directory on the Linux machine.

**Environment setup (required before any VCS command):**
```bash
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
VERDI_PLI=$VERDI_HOME/share/PLI/VCS/linux64
```

**UART standalone simulation:**
```bash
cd sim/
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/uart/include \
    -f run_uart.f -top tb_axi_uart_top \
    -P $VERDI_PLI/novas.tab -LDFLAGS "-Wl,-rpath,$VERDI_PLI" $VERDI_PLI/pli.a \
    -o simv_uart && ./simv_uart
```

**AES standalone simulation:**
```bash
cd sim/
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/aes \
    -f run_aes.f -top tb_aes_axi_slave \
    -P $VERDI_PLI/novas.tab -LDFLAGS "-Wl,-rpath,$VERDI_PLI" $VERDI_PLI/pli.a \
    -o simv_aes && ./simv_aes
```

**6-IP integration simulation:**
```bash
cd sim/
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/uart/include +incdir+../rtl/aes \
    -f run_interconnect_uart.f -top tb_axi_interconnect_uart_top \
    -P $VERDI_PLI/novas.tab -LDFLAGS "-Wl,-rpath,$VERDI_PLI" $VERDI_PLI/pli.a \
    -o simv_integration && ./simv_integration
```

**View waveforms in Verdi:**
```bash
verdi -ssf dump_integration.fsdb &
```

---

## 11. Tools & Environment

| Tool | Version | Purpose |
|------|---------|---------|
| Synopsys VCS | U-2023.03_Full64 | RTL Simulation |
| Synopsys Verdi | U-2023.03-SP1 | Waveform Viewer |
| VeeR EL2 (CHIPS Alliance) | Latest | RISC-V Processor Core |
| riscv64-unknown-elf-gcc | 16.1.0 | RISC-V C/ASM Toolchain |
| Linux | Rocky Linux 8.10 | Development & Simulation |
| License Server | 27021@14.139.1.126 | Synopsys license |

---

## 12. References

- [VeeR EL2 RISC-V Core — CHIPS Alliance](https://github.com/chipsalliance/Cores-VeeR-EL2)
- [NIST FIPS-197 — AES Standard](https://csrc.nist.gov/publications/detail/fips/197/final)
- [AUTOSAR SecOC Specification](https://www.autosar.org/)
- [AXI4 Protocol Specification — ARM IHI0022](https://developer.arm.com/documentation/ihi0022)
- [aignacio/axi_dma — DMA Controller IP](https://github.com/aignacio/axi_dma)
- [efabless EF_GPIO8 — GPIO IP](https://github.com/efabless/EF_GPIO8)
- [anhducdinh/IP_timer — EF_TCC32 Timer IP](https://github.com/anhducdinh/IP_timer)
