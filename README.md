# RISC-V Hardware-Accelerated Encrypted ECU Gateway SoC

**Honours Project — RTL Design & Verification**

[![Language](https://img.shields.io/badge/Language-Verilog%20%2F%20SystemVerilog-blue)]()
[![Simulator](https://img.shields.io/badge/Simulator-Synopsys%20VCS-orange)]()
[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32IMC-green)]()
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)]()

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Proposed Solution](#2-proposed-solution)
3. [SoC Architecture](#3-soc-architecture)
4. [Block Diagram](#4-block-diagram)
5. [Memory Map](#5-memory-map)
6. [IP Blocks](#6-ip-blocks)
7. [Data Flow](#7-data-flow)
8. [Repository Structure](#8-repository-structure)
9. [Implementation Progress](#9-implementation-progress)
10. [Simulation](#10-simulation)
11. [Tools & Environment](#11-tools--environment)

---

## 1. Problem Statement

Modern vehicles contain dozens of **Electronic Control Units (ECUs)** — small computers that control safety-critical functions like braking, steering, throttle, and airbags. These ECUs communicate over an internal vehicle network called the **Controller Area Network (CAN bus)**.

**The problem:** CAN bus was designed without any security. Every message is broadcast in **unencrypted plaintext**. This means:
- An attacker with physical or remote access can **read all vehicle data**
- An attacker can **inject fake commands** — fake braking or steering signals — causing safety failures
- Modern security standards (AUTOSAR SecOC) require **AES-128 encryption** on every safety-critical frame

**The engineering challenge:** Encrypting in software on a small RISC-V microcontroller adds **2+ milliseconds per block** — far too slow for microsecond real-time control loops. Running AES in software also consumes 100% of CPU bandwidth, leaving nothing for actual vehicle control.

---

## 2. Proposed Solution

This project designs a **RISC-V based SoC with a Hardware Security Module (HSM)** architecture. Instead of running AES encryption in software, a dedicated **hardware AES engine** performs encryption autonomously. A **DMA controller** moves data between memory, the AES engine, and the SPI bus — all without CPU intervention.

**Result:** The RISC-V processor is free for real-time vehicle control while frame encryption and transmission happen in hardware at line-rate.

---

## 3. SoC Architecture

The SoC is built around the **VeeR EL2 RISC-V core** (RV32IMC, 4-stage pipeline) as the central processing unit, connected via an **AXI4 bus interconnect** to instruction memory, data memory, and a set of peripheral IP blocks.

**Two AXI masters:**
- **Master 0** — RISC-V CPU (LSU — Load/Store Unit for data access)
- **Master 1** — DMA Controller (autonomous data movement, no CPU needed)

**Eight AXI slaves (peripherals):**

| Slave | Peripheral |
|---|---|
| S0 | Instruction Memory (IMEM) |
| S1 | Data Memory (DMEM) |
| S2 | UART |
| S3 | AES-128 Engine |
| S4 | DMA Controller |
| S5 | Timer |
| S6 | GPIO |
| S7 | SPI Master |

---

## 4. Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RISC-V SoC                                      │
│                                                                         │
│   ┌──────────────────┐                                                  │
│   │   VeeR EL2 CPU   │  RV32IMC · 4-stage pipeline                     │
│   │   (RISC-V Core)  │  Manages keys, config, interrupts                │
│   └────────┬─────────┘                                                  │
│            │ AXI4 (Master 0 — CPU LSU)                                  │
│   ┌────────▼──────────────────────────────┐                             │
│   │     AXI4 Interconnect  (2 × 8)        │◄── Master 1: DMA Controller │
│   └──┬──────┬──────┬──────┬──────┬──────┬─┘                            │
│      │      │      │      │      │      │                               │
│    IMEM   DMEM   UART    AES    DMA   Timer  GPIO   SPI                 │
│                           │      │                   │                  │
│                      Encrypt  Auto-move         Automotive              │
│                      /Decrypt  data             Serial Bus              │
│                           │      │                   │                  │
│                           └──────┴───────────────────┘                  │
│                              Encrypted Frame Pipeline                   │
└─────────────────────────────────────────────────────────────────────────┘
```

**Encryption Pipeline:**
```
Sensor Data
    │
    ▼
[Data RAM] ──DMA──► [AES Engine] ──DMA──► [SPI TX FIFO] ──► CAN Bus
                    (encrypt in                (send out
                     hardware)                  frame)
    ▲
    │
RISC-V CPU
(loads AES key,
 configures DMA,
 handles faults via GPIO,
 monitors via Timer)
```

---

## 5. Memory Map

| Base Address | Size | Peripheral | Notes |
|---|---|---|---|
| `0x0000_0000` | 16 MB | Instruction Memory (IMEM) | CPU fetches program instructions |
| `0x0100_0000` | 16 MB | Data Memory (DMEM) | Variables, frame staging buffers |
| `0x0200_0000` | 16 MB | UART | Serial debug / host interface |
| `0x0300_0000` | 16 MB | AES-128 Engine | Encrypt + Decrypt registers |
| `0x0400_0000` | 16 MB | DMA Controller | Transfer configuration registers |
| `0x0500_0000` | 16 MB | Timer | Countdown + interrupt |
| `0x0600_0000` | 16 MB | GPIO | Fault pins, status flags |
| `0x0700_0000` | 16 MB | SPI Master | Automotive serial bus interface |

---

## 6. IP Blocks

### AXI4 Interconnect (2 Masters × 8 Slaves)
- Custom-designed parameterized AXI4 crossbar
- Supports simultaneous transfers from CPU and DMA
- Address-based routing, round-robin arbitration
- Files: `rtl/interconnect/`

### UART (AXI4-Lite Slave)
- Full duplex UART with separate TX and RX FIFOs
- Configurable baud rate via divisor register
- Interrupt on RX data ready
- AXI4-Lite register interface (5 registers)
- Files: `rtl/uart/`

### AXI4 → AXI4-Lite Bridge
- Protocol converter: handles burst-to-single-beat conversion
- ID width adaptation (8-bit → 12-bit)
- Address truncation (32-bit → 5-bit for UART)
- Files: `rtl/bridge/`

### AES-128 Encryption Engine (AXI4-Lite Slave)
- Hardware AES-128 encryption and decryption
- 10-round pipelined cipher compliant with NIST FIPS-197
- Memory-mapped registers: KEY (128-bit), DATA_IN (128-bit), DATA_OUT (128-bit), CSR
- Both forward cipher and inverse cipher implemented
- START/DONE status polling via CSR register
- Files: `rtl/aes/`

**AES Register Map:**

| Offset | Register | Description |
|---|---|---|
| `0x00` | CIPHER_CSR | Control (START bit) + Status (DONE, BUSY) |
| `0x04–0x10` | CIPHER_KEY[0:3] | 128-bit encryption key (4 × 32-bit) |
| `0x14–0x20` | CIPHER_TEXTIN[0:3] | 128-bit plaintext input |
| `0x24–0x30` | CIPHER_TEXTOUT[0:3] | 128-bit ciphertext output |
| `0x40` | INV_CSR | Inverse cipher control + status |
| `0x44–0x50` | INV_KEY[0:3] | 128-bit decryption key |
| `0x54–0x60` | INV_TEXTIN[0:3] | 128-bit ciphertext input |
| `0x64–0x70` | INV_TEXTOUT[0:3] | 128-bit plaintext output |

### RISC-V VeeR EL2 Core
- Open-source core from CHIPS Alliance
- RV32IMC ISA (32-bit integer + multiply + compressed)
- 4-stage in-order scalar pipeline
- AXI4 master interfaces: LSU (data), IFU (instruction fetch)
- JTAG debug port
- Source: [Cores-VeeR-EL2](https://github.com/chipsalliance/Cores-VeeR-EL2)

### Remaining IPs (In Progress)
| IP | Description |
|---|---|
| Data Memory (DMEM) | AXI4 SRAM — payload staging buffers |
| Timer | Memory-mapped countdown timer with interrupt |
| GPIO | Digital I/O for fault signals and status flags |
| SPI Master | Automotive serial bus interface with TX/RX FIFOs |
| DMA Controller | AXI4 bus master — autonomous data movement engine |

---

## 7. Data Flow

**Step 1 — Ingress (no CPU involved)**
```
Sensor/CAN data arrives → DMA writes directly into Data RAM staging buffer
```

**Step 2 — Encryption (no CPU involved)**
```
DMA reads staging buffer → writes to AES DATA_IN registers
AES engine encrypts automatically (hardware, ~10 clock cycles)
DMA reads AES DATA_OUT → writes to SPI TX buffer
```

**Step 3 — Egress (no CPU involved)**
```
SPI controller sends encrypted frame over automotive bus at line-rate
```

**Step 4 — CPU supervision (runs in parallel)**
```
Timer interrupt fires every control loop period
CPU checks GPIO fault pins
CPU prints debug status over UART
CPU reloads AES key if needed
CPU initiates next DMA transfer
```

---

## 8. Repository Structure

```
Honours_Proj/
│
├── rtl/                        # Synthesizable RTL (Verilog)
│   ├── interconnect/           # AXI4 crossbar — arbiter, priority encoder, wrap_2x8
│   ├── uart/                   # UART IP — controller, transmitter, receiver, FIFOs
│   ├── aes/                    # AES-128 engine — cipher, inv_cipher, sbox, key_expand
│   ├── bridge/                 # AXI4 → AXI4-Lite protocol bridge
│   ├── memory/                 # Instruction & Data RAM (in progress)
│   ├── timer/                  # Hardware timer (in progress)
│   ├── gpio/                   # GPIO controller (in progress)
│   ├── spi/                    # SPI master (in progress)
│   ├── dma/                    # DMA controller (in progress)
│   └── soc_top/                # Full SoC integration top (in progress)
│
├── tb/                         # Testbenches (Verilog)
│   ├── uart/                   # UART block-level testbenches (6 files)
│   ├── aes/                    # AES block-level testbench
│   ├── interconnect/           # AXI interconnect testbench
│   └── soc/                    # Full SoC testbench (in progress)
│
├── sim/                        # VCS simulation filelists (.f files)
│   ├── run_uart.f              # UART standalone simulation
│   ├── run_aes.f               # AES standalone simulation
│   └── run_interconnect_uart.f # Interconnect + UART integration
│
├── sw/                         # RISC-V software (in progress)
│   ├── boot/                   # Boot code — UART init, AES key load
│   └── app/                    # Application — encryption pipeline demo
│
├── docs/                       # Documentation
│   ├── architecture/           # Block diagrams, interface specs
│   └── reports/                # Project reports
│
├── scripts/                    # Utility scripts
│   └── axi_interconnect_wrap.py  # AXI wrapper generator
│
└── waveforms/                  # Simulation waveform screenshots
    └── UART_wavef/             # UART verified waveforms
```

---

## 9. Implementation Progress

### ✅ Completed

| Module | Description | Verified |
|---|---|---|
| AXI4 Interconnect (2×8) | Parameterized crossbar, address decode, arbitration | ✅ Simulated |
| UART AXI4-Lite Slave | Full TX/RX FIFOs, baud rate config, interrupt | ✅ Simulated |
| AXI4 → AXI4-Lite Bridge | Burst-to-single conversion, ID/addr adaptation | ✅ Simulated |
| AES-128 Encrypt Engine | 10-round hardware cipher, AXI4-Lite interface | ✅ Simulated |
| AES-128 Decrypt Engine | Inverse cipher, key expansion, AXI4-Lite interface | ✅ Simulated |
| Interconnect + UART | AXI interconnect driving UART via bridge | ✅ Simulated |

### 🔄 In Progress

| Module | Status |
|---|---|
| VeeR EL2 RISC-V Core integration | Core cloned, SoC top-level wiring in progress |
| Instruction Memory (IMEM) | AXI4 ROM stub created |

### ❌ Remaining

| Module | Notes |
|---|---|
| Data Memory (DMEM) | AXI4 SRAM block |
| Timer | Memory-mapped countdown + interrupt |
| GPIO | Digital I/O register block |
| SPI Master | Automotive serial bus interface |
| DMA Controller | AXI4 bus-mastering transfer engine |
| Full SoC Top | Wire all IPs into single top module |
| RISC-V Boot Program | Assembly/C — UART init + AES encrypt demo |
| Full SoC Testbench | End-to-end simulation |

---

## 10. Simulation

All simulations use **Synopsys VCS**. Run from the `sim/` directory.

**UART block simulation:**
```bash
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/uart/include \
    -f run_uart.f -top tb_axi_uart_top \
    -o simv_uart && ./simv_uart
```

**AES block simulation:**
```bash
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    -f run_aes.f -top tb_aes_axi_slave \
    -o simv_aes && ./simv_aes
```

**Interconnect + UART integration:**
```bash
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/uart/include \
    -f run_interconnect_uart.f -top tb_axi_interconnect_uart_top \
    -o simv_integration && ./simv_integration
```

**View waveforms in Verdi:**
```bash
verdi -ssf dump.fsdb &
```

---

## 11. Tools & Environment

| Tool | Version | Purpose |
|---|---|---|
| Synopsys VCS | 2023.03 | RTL Simulation |
| Synopsys Verdi | 2023.03 | Waveform Viewer |
| VeeR EL2 (CHIPS Alliance) | Latest | RISC-V Processor Core |
| riscv64-unknown-elf-gcc | 16.1.0 | RISC-V Toolchain |
| Python 3 | 3.x | Scripts |
| Linux (Ubuntu) | — | Development Environment |

---

## References

- [VeeR EL2 RISC-V Core — CHIPS Alliance](https://github.com/chipsalliance/Cores-VeeR-EL2)
- [NIST FIPS-197 — AES Standard](https://csrc.nist.gov/publications/detail/fips/197/final)
- [AUTOSAR SecOC Specification](https://www.autosar.org/)
- [AXI4 Protocol Specification — ARM IHI0022](https://developer.arm.com/documentation/ihi0022)
