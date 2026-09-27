# RISC-V Hardware-Accelerated Encrypted ECU Gateway SoC

> Honours Project — RTL Design & Verification  
> RISC-V based System-on-Chip with AES-128 hardware encryption for automotive CAN security

---

## Overview

This project designs and verifies a complete RTL-based System-on-Chip (SoC) targeting automotive Controller Area Network (CAN) security. Legacy CAN buses transmit data in unencrypted plaintext, exposing safety-critical ECU commands to replay and spoofing attacks.

This SoC offloads AES-128 encryption, DMA data transfers, and serial bus communication to dedicated hardware accelerators, keeping the RISC-V processor free for real-time vehicle control tasks.

---

## SoC Architecture

```
                    RISC-V VeeR EL2 (RV32IMC)
                           │
              AXI4 Interconnect (2 Masters × 8 Slaves)
                           │
     ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
   IMEM       DMEM       UART       AES        DMA       Timer      GPIO       SPI
0x0000_0000 0x0100_0000 0x0200_0000 0x0300_0000 0x0400_0000 0x0500_0000 0x0600_0000 0x0700_0000
```

**Data Flow:**
```
Sensor Data → DMA → Data RAM → DMA → AES Engine → DMA → SPI TX → CAN Bus
                                         ↑
                               RISC-V loads AES key
```

---

## Repository Structure

```
Honours_Proj/
├── rtl/                        # Synthesizable RTL sources
│   ├── interconnect/           # AXI4 crossbar (2x8)
│   ├── uart/                   # UART AXI4-Lite slave
│   ├── aes/                    # AES-128 encrypt/decrypt engine
│   ├── bridge/                 # AXI4 → AXI4-Lite bridge
│   ├── memory/                 # Instruction & Data RAM (TODO)
│   ├── timer/                  # Hardware timer (TODO)
│   ├── gpio/                   # GPIO controller (TODO)
│   ├── spi/                    # SPI master (TODO)
│   ├── dma/                    # DMA controller (TODO)
│   └── soc_top/                # Full SoC integration top (TODO)
│
├── tb/                         # Testbenches
│   ├── uart/                   # UART block-level testbenches
│   ├── aes/                    # AES block-level testbench
│   ├── interconnect/           # Interconnect testbench
│   └── soc/                    # Full SoC testbench (TODO)
│
├── sim/                        # VCS simulation filelists (.f files)
│   ├── run_uart.f
│   ├── run_aes.f
│   └── run_interconnect_uart.f
│
├── sw/                         # RISC-V software
│   ├── boot/                   # Boot program (TODO)
│   └── app/                    # Application code (TODO)
│
├── docs/                       # Documentation
│   ├── architecture/           # Block diagrams, memory map
│   └── reports/                # Project reports
│
├── scripts/                    # Utility scripts
│   └── axi_interconnect_wrap.py
│
└── waveforms/                  # Simulation waveform screenshots
```

---

## IP Blocks

| Block | Status | Interface | Description |
|---|---|---|---|
| AXI Interconnect (2×8) | ✅ Done | AXI4 | 2-master 8-slave crossbar |
| UART | ✅ Done | AXI4-Lite | Serial debug interface with TX/RX FIFOs |
| AXI4 → AXI4-Lite Bridge | ✅ Done | AXI4/AXI4-Lite | Protocol converter |
| AES-128 Engine | ✅ RTL done | AXI4-Lite | Encrypt + Decrypt, 10-round pipeline |
| RISC-V CPU (VeeR EL2) | 🔄 Integration | AXI4 | RV32IMC, 4-stage pipeline |
| Instruction Memory | 🔄 In progress | AXI4 | ROM stub |
| Data Memory | ❌ TODO | AXI4 | SRAM |
| Timer | ❌ TODO | AXI4-Lite | Countdown + interrupt |
| GPIO | ❌ TODO | AXI4-Lite | Digital I/O |
| SPI Master | ❌ TODO | AXI4-Lite | Automotive serial bus |
| DMA Controller | ❌ TODO | AXI4 (master) | Autonomous data mover |

---

## Memory Map

| Address | Size | Peripheral |
|---|---|---|
| `0x0000_0000` | 16 MB | Instruction Memory (IMEM) |
| `0x0100_0000` | 16 MB | Data Memory (DMEM) |
| `0x0200_0000` | 16 MB | UART |
| `0x0300_0000` | 16 MB | AES Engine |
| `0x0400_0000` | 16 MB | DMA Controller |
| `0x0500_0000` | 16 MB | Timer |
| `0x0600_0000` | 16 MB | GPIO |
| `0x0700_0000` | 16 MB | SPI Master |

---

## Simulation

Requires Synopsys VCS. Run from the `sim/` directory.

**UART simulation:**
```bash
vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
    +incdir+../rtl/uart/include \
    -f run_uart.f -top tb_axi_uart_top \
    -o simv_uart && ./simv_uart
```

**AES simulation:**
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

---

## Tools

| Tool | Purpose |
|---|---|
| Synopsys VCS | RTL Simulation |
| Synopsys Verdi | Waveform viewer |
| riscv64-unknown-elf-gcc | RISC-V toolchain |
| Python 3 | Scripts |

---

## Project Status

- [x] AXI Interconnect designed and verified  
- [x] UART designed and verified  
- [x] AES-128 engine designed and verified  
- [x] AXI4 → AXI4-Lite bridge designed  
- [ ] VeeR EL2 RISC-V core integration  
- [ ] Data Memory  
- [ ] Timer, GPIO, SPI, DMA  
- [ ] Full SoC integration  
- [ ] RISC-V boot program  
- [ ] End-to-end simulation  
