import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

def generate_soc_testplan(filename):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Testplan"
    ws.views.sheetView[0].showGridLines = True

    # Styles matching /home/student/Downloads/VeeR_EL2_SoC_Testplan.xlsx exactly
    header_fill = PatternFill(fill_type='solid', start_color='FF1F4E78', end_color='FF1F4E78')
    header_font = Font(name='Arial', size=11.0, bold=True, color='FFFFFFFF')
    header_align = Alignment(horizontal='center', vertical='center', wrap_text=True)
    border_color = 'FF999999'
    cell_border = Border(
        left=Side(style='thin', color=border_color),
        right=Side(style='thin', color=border_color),
        top=Side(style='thin', color=border_color),
        bottom=Side(style='thin', color=border_color)
    )

    data_font = Font(name='Arial', size=10.0, bold=False, color=None)

    # Headers on Row 1
    headers = [
        "SNo.",
        "Testname",
        "Description",
        "Checkpoint",
        "C verification part",
        "SV verification part"
    ]

    for col_idx, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col_idx, value=h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = header_align
        cell.border = cell_border
    ws.row_dimensions[1].height = 15.0

    # Column widths
    ws.column_dimensions['A'].width = 7.0
    ws.column_dimensions['B'].width = 14.01
    ws.column_dimensions['C'].width = 140.75
    ws.column_dimensions['D'].width = 86.98
    ws.column_dimensions['E'].width = 177.01
    ws.column_dimensions['F'].width = 167.35

    # Test cases tailored for Honours Project SoC
    test_cases = [
        (
            1,
            "TC_BOOT_01",
            "Power-on Reset & Entry Vector Check: Reset de-assertion allows VeeR-EL2 core to wake up and fetch its first instruction from Boot ROM address 0x8000_0000 (_start).",
            "1. CPU reset released at 245 us. 2. PC starts at 0x8000_0000 in Boot ROM. 3. Stack pointer sp initialized to 0xF004_FFDC in DCCM. 4. Reset values asserted across peripheral registers.",
            "Execute entry bootstrap in sw/boot.S: initialize stack pointer (sp = 0xF004_FFDC), zero out .bss, copy .data if required, and jump to main() in sw/app/main.c.",
            "Drive active-low reset rst_vec = 31'h4000_0000 and core_rst_l = 0 for 24.5 us. Deassert and monitor trace_rv_i_address_ip === 32'h8000_0000 and trace_rv_i_valid_ip === 1'b1. Verify bus interfaces quiescent."
        ),
        (
            2,
            "TC_BOOT_02",
            "DCCM Stack Frame & Memory Integrity Check: Verify byte, half-word, and word reads and writes to VeeR local DCCM memory (0xF004_0000) without generating bus traps or ECC exceptions.",
            "Stack push/pop and local variable allocations return expected data without bus-error trap or ECC exceptions.",
            "Allocate nested function call stack frames in sw/app/main.c. Push/pop caller/callee registers. Verify local arrays and scratch variables retain integrity during peripheral operations.",
            "Snoop VeeR core LSU DCCM interface signals. Verify absence of dccm_ecc_single_error or dccm_ecc_double_error flags. Confirm trace_rv_i_exception_ip === 1'b0."
        ),
        (
            3,
            "TC_MEM_01",
            "VeeR MRAC Side-Effect I/O Configuration: Configure VeeR Machine Region Access Control CSR (0x7C0) to designate Region 0 (0x0000_0000-0x0FFF_FFFF) as non-cacheable side-effect I/O.",
            "1. CSR 0x7C0 written with 0x00000002. 2. Peripheral address lines retain lower bits [2:0] without doubleword cache merging or predictive speculative loads.",
            "In sw/boot.S, load immediate 0x00000002 into register t0 and execute csrw 0x7C0, t0 immediately prior to jumping to C runtime.",
            "Monitor core decode unit dec_tlu_mrac_ff[0] == 2'b10. Verify LSU AXI4 master port drives exact 32-bit peripheral byte/word addresses without cache bursting."
        ),
        (
            4,
            "TC_UART_01",
            "UART Baud Rate & Format Configuration: Program 16550-compatible UART baud divisor (0x0300_0008) to 868 for 115200 baud at 100 MHz clock and set Line Control (8-N-1).",
            "1. UART_BAUD_REG latches 868. 2. UART_LCR_REG latches 0x03 (8 data bits, 1 stop bit, no parity). 3. Serial bit width matches 8680.55 ns.",
            "Call uart_init(868) in sw/app/main.c. Write 868 to UART_BAUD_REG (0x0300_0008) and 0x03 to UART_LCR_REG (0x0300_000C). Read back and assert equality.",
            "BFM snoops AXI interconnect slave port M03 (0x0300_0000). Asserts awready/wready handshakes and verifies uart_baud_rate_reg_int == 868 with bresp === 2'b00 (OKAY)."
        ),
        (
            5,
            "TC_UART_02",
            "UART Transmitter Character Serialization & Banner Streaming: Stream ASCII header banner over UART TX FIFO, polling Transmit Holding Register Empty (THRE) in LSR (0x0300_0014).",
            "1. THRE bit polls high before each byte write. 2. UART TX FIFO accepts characters without overrun. 3. Complete Honours Project banner prints to terminal.",
            "Execute uart_puts('=== Honours Project: VeeR EL2 SoC ===\\r\\n') in sw/app/main.c. Function polls UART_LSR_REG & UART_LSR_THRE before writing each character to UART_THR_REG (0x0300_0000).",
            "Real-time serial RX monitor in tb/soc/tb_soc_top.v samples falling edges (start bit) on uart_tx_o, samples 8 bits sequentially mid-cycle at 8680.55 ns bit period, and prints characters to stdout."
        ),
        (
            6,
            "TC_UART_03",
            "UART Receiver Loopback & Data Injection: Inject external telemetry byte into uart_rx_i and verify reception in Receiver Buffer Register (UART_RBR).",
            "UART_RBR reads injected byte and uart_irq_o asserts on receive data ready.",
            "Wait in polling loop checking UART_LSR_REG for bit 0 (DR - Data Ready). Read UART_RBR_REG (0x0300_0000) and verify received byte matches injected character.",
            "Testbench drives start bit, data bits (8'hA5), and stop bit into uart_rx_i at 115200 baud. Asserts uart_irq_o === 1'b1 and checks data integrity in scoreboard."
        ),
        (
            7,
            "TC_UART_04",
            "UART FIFO / Buffer Overrun Detection: Force back-to-back unread RX byte injections into uart_rx_i to trigger receiver overrun status flag.",
            "Overrun Error (OE, bit 1) asserted in LSR; system interconnect remains unblocked without bus hang.",
            "Allow receiver to receive multiple consecutive characters without reading UART_RBR_REG. Read UART_LSR_REG and assert Overrun Error (bit 1) is flagged.",
            "Driver transmits multiple back-to-back bytes without pause. Scoreboard verifies uart_irq_o asserts and AXI slave interface responds normally to subsequent bus transactions."
        ),
        (
            8,
            "TC_TMR_01",
            "System Timer Prescaler & Counter Monotonicity: Program prescaler and step rate, enable timer core, and verify 64-bit counter progression.",
            "TIMER_VAL_LO increments monotonically at the configured tick frequency without jitter.",
            "Write prescaler configuration to Timer base address (0x0400_0000). Sample t0 = TIMER_VAL_LO, execute 50 NOPs, sample t1 = TIMER_VAL_LO, and assert t1 > t0.",
            "Snoop AXI slave port M04 (0x0400_0000). Verify internal counter advances monotonically every N system clocks and bus read channel returns updated count."
        ),
        (
            9,
            "TC_TMR_02",
            "System Timer Match Interrupt Generation & W1C Clear: Validate compare match trigger between counter value and compare register.",
            "timer_irq_o asserts on compare match and clears immediately upon write-1-to-clear.",
            "Read current counter, program compare register to t0 + 100, enable timer interrupt, and poll interrupt status. Clear interrupt via W1C and assert status returns to zero.",
            "Monitor timer_irq_o connected to extintsrc_req[1]. Assert that timer_irq_o transitions 0 -> 1 when counter equals compare value, and deasserts upon W1C write completion."
        ),
        (
            10,
            "TC_AES_01",
            "128-Bit AUTOSAR SecOC AES Key Loading: Load 128-bit NIST FIPS-197 Appendix B cryptographic key into AES hardware engine registers KEY0-KEY3 (0x0000_0004-0x0000_0010).",
            "1. AES KEY0-KEY3 registers successfully latch 0x16157e2b, 0xa6d2ae28, 0x8815f7ab, 0x3c4fcf09 across AXI4 interconnect. 2. Key load confirmed via UART telemetry.",
            "Call aes_set_key_128(0x16157E2B, 0xA6D2AE28, 0x8815F7AB, 0x3C4FCF09) in sw/app/main.c. Writes 4 words to AES_KEY0_REG..AES_KEY3_REG (0x0000_0004-0x0000_0010).",
            "Passive bus monitor on AXI slave M00 verifies awvalid/wvalid handshake on registers 0x04-0x10. Verifies internal register bank latches 128-bit key correctly."
        ),
        (
            11,
            "TC_AES_02",
            "Autonomous 10-Round AES-128 Hardware Execution: Write 128-bit ECU plaintext to TEXTIN0-3 and trigger encryption by asserting START bit in AES_CSR_REG (0x0000_0000, bit 16).",
            "1. cipher_start_reg asserts 1-cycle pulse. 2. Hardware 10-round pipeline executes autonomously in ~10 clock cycles. 3. cipher_done_reg asserts high. 4. CPU detects DONE bit.",
            "Call aes_encrypt_block(p0, p1, p2, p3) in sw/app/main.c. Writes plaintext words to AES_TEXTIN0_REG..3 (0x0000_0014-0x0000_0020), triggers START, and polls for DONE flag.",
            "Testbench monitors dut.u_periph_top.u_aes.cipher_start_reg, state progression across 10 rounds, and assertion of cipher_done_reg. Confirms completion in exactly 10 cycles."
        ),
        (
            12,
            "TC_AES_03",
            "Ciphertext Readback & NIST Standard Vector Validation: Read back 128-bit ciphertext from AES_TEXTOUT0-3 (0x0000_0024-0x0000_0030) directly into CPU registers and verify against NIST vector.",
            "1. AES_TEXTOUT registers produce exact NIST vector: c0 = 0x9448fe5e, c1 = 0x7c88f20f, c2 = 0x16431804, c3 = 0xfa8db16a. 2. UART prints hex confirmation.",
            "Read c0 = AES_TEXTOUT0_REG through c3 = AES_TEXTOUT3_REG in sw/app/main.c. Verify values directly in CPU registers without stack aliasing. Stream results to UART.",
            "Scoreboard latches inputs, executes reference C/DPI AES-128 model, and compares read-data bus values on s_axi_rdata against expected NIST ciphertext."
        ),
        (
            13,
            "TC_AES_04",
            "AES Busy Write-Protection Check: Attempt to overwrite Key and Plaintext registers while hardware encryption engine is actively running (BUSY state).",
            "Registers remain locked while cipher_busy is asserted; ciphertext calculation remains uncorrupted.",
            "Set START bit in AES_CSR_REG. Immediately attempt back-to-back writes of dummy data 0xDEADBEEF to AES_KEY0 and AES_TEXTIN0 before polling DONE. Confirm readback matches original FIPS vector.",
            "AXI monitor verifies slave M00 rejects or ignores overwrite requests while cipher_busy === 1'b1, maintaining cryptographic integrity throughout pipeline execution."
        ),
        (
            14,
            "TC_SRAM_01",
            "ECU Plaintext Frame Staging in AXI SRAM: Stage raw 128-bit ECU sensor plaintext payload into dedicated 64KB AXI SRAM packet buffer at base address 0x0600_0000.",
            "1. AXI SRAM locations 0x0600_0000 to 0x0600_000C hold 4 words: 0xa8f64332, 0x8d305a88, 0xa2983131, 0x340737e0. 2. Readback confirms data matches.",
            "In sw/app/main.c, cast 0x0600_0000 to volatile uint32_t pointer. Write p0, p1, p2, p3 into sram_buf[0..3]. Read back and verify equality.",
            "Monitor interconnect slave M06 (0x0600_0000). Verify axi_sram module performs single-cycle synchronous write and read handshakes with bresp === 2'b00."
        ),
        (
            15,
            "TC_SRAM_02",
            "Ciphertext Storage in AXI SRAM Staging Buffer: Store 128-bit encrypted ciphertext into SRAM staging buffer at offset +0x10 (0x0600_0010-0x0600_001C) for CAN transmission.",
            "SRAM words at 0x0600_0010, 0x0600_0014, 0x0600_0018, 0x0600_001C correctly store c0, c1, c2, c3 without bus errors or corruption.",
            "Store c0 through c3 into sram_buf[4..7] in sw/app/main.c. Retain for DMA block transfer or SPI transmission loop.",
            "Snoop M06 AXI write burst channels. Verify byte enables and address incrementing across 0x0600_0010 to 0x0600_001C with valid write completion."
        ),
        (
            16,
            "TC_DMA_01",
            "DMA Autonomous Burst Transfer (SRAM to Peripheral Space): Configure DMA engine to stream ciphertext buffer between AXI SRAM and target peripheral without CPU core intervention.",
            "Target peripheral/memory matches source SRAM data; DMA status indicates completion and triggers dma_done_o interrupt.",
            "Program DMA source address to 0x0600_0010, destination address to target peripheral, transfer length to 16 bytes. Enable DMA start bit in DMA CSR (0x0100_0000). Poll DMA status for completion.",
            "Passive bus monitor captures Master S01 burst requests on interconnect. Verifies correct incrementing addresses, burst size (axsize), and assertion of dma_done_o on extintsrc_req[4]."
        ),
        (
            17,
            "TC_DMA_02",
            "DMA Error Abort & Bus Slave Fault Reporting: Force DMA descriptor to access unmapped or illegal address range (e.g., 0x0700_0000).",
            "DMA aborts transfer, flags error status bit in CSR, and asserts dma_error_o interrupt without hanging the bus.",
            "Program DMA destination address to unmapped address 0x0700_0000. Trigger DMA transfer. Poll DMA status and assert DMA error bit is flagged.",
            "AXI crossbar returns bresp/rresp = 2'b10 (SLVERR/DECERR) to DMA master port S01. Assert that dma_error_o === 1'b1 on extintsrc_req[5] and DMA engine returns cleanly to IDLE."
        ),
        (
            18,
            "TC_SPI_01",
            "SPI Master Configuration & Clock Divisor: Program SPI Master control and baud divisor registers at base address 0x0200_0000 for target CAN controller baud rate.",
            "SPI control registers latch configuration; SCLK output generates expected clock rate when active.",
            "In sw/app/main.c, write SPI control register (0x0200_0000) to configure master mode, CPOL=0, CPHA=0, and clock prescaler. Read back and verify configuration.",
            "BFM monitors AXI slave port M02 (0x0200_0000). Asserts awready/wready handshakes and verifies m02_rlast === 1'b1 on read transactions."
        ),
        (
            19,
            "TC_SPI_02",
            "SPI Master 16-Byte CAN Frame Dispatch: Stream 16 bytes of encrypted ciphertext payload over SPI Master (0x0200_0000) to external MCP2515 CAN bus controller.",
            "1. spi_cs_n_o asserts low (CS=0). 2. Exactly 16 bytes captured on MOSI matching NIST vector. 3. CS deasserts high upon completion.",
            "Execute 16-byte transmission loop in sw/app/main.c using spi_transfer(byte). Writes to SPI_DATA_REG (0x0200_0000) and polls SPI_STATUS_REG (0x0200_0004) for transfer complete.",
            "Hardware SPI monitor in tb/soc/tb_soc_top.v captures spi_cs_n_o falling edge, samples MOSI on spi_sclk_o rising edges, and logs all 16 bytes: 0x5E, 0xFE, 0x48, 0x94, 0x0F, 0xF2, 0x88, 0x7C, 0x04, 0x18, 0x43, 0x16, 0x6A, 0xB1, 0x8D, 0xFA."
        ),
        (
            20,
            "TC_GPIO_01",
            "GPIO Output Direction & LED State 1 (Init Ready): Configure EF_GPIO8 direction register for 8 output lines and assert Status LED 0 to indicate system boot.",
            "1. GPIO direction register latches 0xFF (all outputs). 2. gpio_out_o transitions to 8'b00000001 (0x01) at ~3.56 ms. 3. gpio_oe_o drives 8'hFF.",
            "Call gpio_set_dir(0xFF) and gpio_write(0x01) in sw/app/main.c. Writes 0xFF to GPIO_DIR_REG (0x0500_0008) and 0x01 to GPIO_DATA_REG (0x0500_0000).",
            "Testbench monitors top-level gpio_out_o[7:0]. Asserts state transition to 8'h01 at simulation time ~3.56 ms and logs [TB-GPIO] LED State Updated: 0x01."
        ),
        (
            21,
            "TC_GPIO_02",
            "GPIO Status LED State 2 (AES Encryption Active): Assert GPIO LED 0 + 1 (8'b00000011 = 0x03) immediately prior to triggering hardware AES pipeline.",
            "gpio_out_o transitions to 8'h03 at time 39.90 ms, signaling transition from peripheral staging to cryptographic acceleration.",
            "Call gpio_write(0x03) in sw/app/main.c immediately before writing START bit to AES_CSR_REG.",
            "Testbench gpio_out_o monitor captures transition to 8'h03 at 39,905,000 ps and verifies synchronicity with AES start."
        ),
        (
            22,
            "TC_GPIO_03",
            "GPIO Status LED State 3 (SPI CAN Transmission Active): Assert GPIO LED 0 + 1 + 2 (8'b00000111 = 0x07) to signal that encrypted frame is being dispatched over SPI.",
            "gpio_out_o transitions to 8'h07 at time 53.81 ms prior to SPI transmission loop.",
            "Call gpio_write(0x07) in sw/app/main.c immediately before entering 16-byte SPI transmission loop.",
            "Testbench gpio_out_o monitor captures transition to 8'h07 at 53,815,000 ps and verifies SPI CS goes active immediately following LED update."
        ),
        (
            23,
            "TC_GPIO_04",
            "GPIO Final Status LED (Transaction Success): Assert final status 8'b00000101 (0x05) indicating end-to-end AUTOSAR SecOC transaction completed successfully.",
            "gpio_out_o transitions to 8'h05 at time 68.68 ms. Triggers testbench pass finish sequence.",
            "Call gpio_write(0x05) in sw/app/main.c upon successful completion of SPI dispatch and ciphertext verification.",
            "Testbench asserts gpio_out_o === 8'h05 at 68,685,000 ps and confirms system state passes before calling $finish."
        ),
        (
            24,
            "TC_GPIO_05",
            "GPIO External Pin Input Sampling & Synchronizer Check: Drive stimulus into gpio_in_i pins and verify CPU core samples values through 2-stage synchronizer.",
            "GPIO_DATA_REG returns injected external pattern after 2-clock synchronization.",
            "Configure upper 4 pins as inputs in GPIO_DIR_REG. Read GPIO_DATA_REG (0x0500_0000) and compare upper nibble against expected stimulus pattern.",
            "Testbench drives gpio_in_i[7:4] = 4'hA. Verifies signals pass through 2-stage synchronizers and asserts stable read response on interconnect slave M05 within 3 clock cycles."
        ),
        (
            25,
            "TC_BUS_01",
            "AXI4 2x8 Crossbar Routing & Single-Beat RLAST Integrity: Verify multi-slave routing across AES, DMA, SPI, UART, Timer, GPIO, and SRAM, ensuring all single-beat AXI4-Lite slaves drive RLAST=1.",
            "1. All 7 slave regions respond without DECERR. 2. m02_rlast drives 1'b1, preventing read channel deadlocks. 3. Concurrent AW and W transactions decode correctly.",
            "Execute consecutive bus operations across AES (0x0000_0000), SPI (0x0200_0000), UART (0x0300_0000), Timer (0x0400_0000), GPIO (0x0500_0000), and SRAM (0x0600_0000) in sw/app/main.c.",
            "Interconnect monitor in tb/soc/tb_soc_top.v verifies proper arbitration between CPU Master S00 and DMA Master S01. Verifies m02_rlast === 1'b1 on port M02 and no bus starvation."
        ),
        (
            26,
            "TC_BUS_02",
            "Unmapped Address Hole Access & SLVERR/DECERR Check: Verify bus access to unmapped peripheral space triggers error response without bus hang.",
            "Interconnect returns DECERR/SLVERR (bresp/rresp = 2'b10 or 2'b11); CPU or DMA encounters precise bus fault without hanging arready/awready.",
            "Perform 32-bit load to unmapped address hole (e.g., 0x0700_0000). Catch expected bus error trap in mtvec handler.",
            "Monitor interconnect master bus. Verify default slave decoder asserts rresp/bresp error without hanging arready/awready handshakes."
        ),
        (
            27,
            "TC_E2E_01",
            "End-to-End Autonomous SecOC Gateway Cycle: Verify full autonomous execution of secure gateway cycle from CPU boot, key load, plaintext staging, AES encryption, SPI CAN dispatch, to final LED confirmation.",
            "1. Full UART banner printed. 2. 128-bit key loaded into AES. 3. Plaintext staged in SRAM. 4. AES generates valid ciphertext. 5. 16 bytes transmitted over SPI. 6. Status LEDs 0x01 -> 0x03 -> 0x07 -> 0x05. 7. SIMULATION SUCCESS at 70.68 ms.",
            "Execute complete AUTOSAR SecOC Gateway pipeline in sw/app/main.c: uart_init() -> aes_set_key_128() -> sram_stage() -> aes_encrypt_block() -> spi_dispatch() -> gpio_write(0x05).",
            "Full SoC testbench in tb/soc/tb_soc_top.v evaluates all 7 phase monitors concurrently and displays '[TB] SIMULATION SUCCESS: All 7 AUTOSAR SecOC Phases Completed!' at 70,680,235,000 ps."
        )
    ]

    for row_idx, tc in enumerate(test_cases, 2):
        sno, name, desc, chk, c_part, sv_part = tc
        
        c_a = ws.cell(row=row_idx, column=1, value=sno)
        c_a.alignment = Alignment(horizontal='center', vertical='top', wrap_text=True)
        
        c_b = ws.cell(row=row_idx, column=2, value=name)
        c_b.alignment = Alignment(horizontal='center', vertical='top', wrap_text=True)
        
        c_c = ws.cell(row=row_idx, column=3, value=desc)
        c_c.alignment = Alignment(horizontal='left', vertical='top', wrap_text=True)
        
        c_d = ws.cell(row=row_idx, column=4, value=chk)
        c_d.alignment = Alignment(horizontal='left', vertical='top', wrap_text=True)
        
        c_e = ws.cell(row=row_idx, column=5, value=c_part)
        c_e.alignment = Alignment(horizontal='left', vertical='top', wrap_text=True)
        
        c_f = ws.cell(row=row_idx, column=6, value=sv_part)
        c_f.alignment = Alignment(horizontal='left', vertical='top', wrap_text=True)
        
        for col_idx in range(1, 7):
            cell = ws.cell(row=row_idx, column=col_idx)
            cell.font = data_font
            cell.border = cell_border
        
        ws.row_dimensions[row_idx].height = 15.0

    wb.save(filename)
    print(f"Successfully generated {filename} with {len(test_cases)} test cases in exact reference format.")

if __name__ == "__main__":
    generate_soc_testplan("soc_test_plan.xlsx")
    generate_soc_testplan("docs/soc_test_plan.xlsx")
