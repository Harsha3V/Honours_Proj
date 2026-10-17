import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = openpyxl.Workbook()

# Setup sheet
ws = wb.active
ws.title = "SoC Test Plan"
ws.views.sheetView[0].showGridLines = True

# Colors
navy_header_fill = PatternFill(start_color="1F4E78", end_color="1F4E78", fill_type="solid")
header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
title_font = Font(name="Calibri", size=16, bold=True, color="1F4E78")
subtitle_font = Font(name="Calibri", size=11, italic=True, color="595959")
data_font = Font(name="Calibri", size=10, bold=False, color="000000")
code_font = Font(name="Consolas", size=9, bold=False, color="002060")
bold_font = Font(name="Calibri", size=10, bold=True, color="000000")

# Fills
alt_row_fill = PatternFill(start_color="F2F5F8", end_color="F2F5F8", fill_type="solid")
white_fill = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
pass_fill = PatternFill(start_color="E2EFDA", end_color="E2EFDA", fill_type="solid")

# Borders
thin_border = Border(
    left=Side(style='thin', color='D9D9D9'),
    right=Side(style='thin', color='D9D9D9'),
    top=Side(style='thin', color='D9D9D9'),
    bottom=Side(style='thin', color='D9D9D9')
)
header_border = Border(
    left=Side(style='thin', color='FFFFFF'),
    right=Side(style='thin', color='FFFFFF'),
    top=Side(style='medium', color='1F4E78'),
    bottom=Side(style='medium', color='1F4E78')
)

# Title Block
ws.merge_cells("A1:F1")
ws["A1"] = "RISC-V Hardware-Accelerated Encrypted ECU Gateway SoC — Test Plan"
ws["A1"].font = title_font
ws["A1"].alignment = Alignment(horizontal="left", vertical="center")

ws.merge_cells("A2:F2")
ws["A2"] = "Roll No: 1602-23-735-189 (Honours Project) | VeeR EL2 RV32IMC Core + NIST AES-128 + AXI4 Crossbar"
ws["A2"].font = subtitle_font
ws["A2"].alignment = Alignment(horizontal="left", vertical="center")

headers = [
    "Serial No.",
    "Test Name",
    "Description",
    "Check Point",
    "C Portion",
    "SV Portion"
]

header_row = 4
for col_idx, h in enumerate(headers, 1):
    cell = ws.cell(row=header_row, column=col_idx, value=h)
    cell.fill = navy_header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    cell.border = header_border
ws.row_dimensions[header_row].height = 28

test_cases = [
    (
        "1",
        "TC_BOOT_01",
        "CPU Reset & CRT0 Initialization:\nVerify that the VeeR EL2 core wakes up from hardware reset at vector 0x8000_0000, establishes stack pointer in DCCM, and branches to main().",
        "1. CPU reset released at 245000 ps.\n2. PC sequence starts at 0x8000_0000 in Boot ROM.\n3. Stack pointer (sp) initialized to 0xF004_FFDC in DCCM.\n4. Successful commit transition into main().",
        "sw/boot.S (Lines 18-25):\n  lui sp, 0xF0050\n  addi sp, sp, -4\n  jal main\nsw/app/main.c (Line 41):\n  int main(void)",
        "tb/soc/tb_soc_top.v (Lines 130-170):\n  rst_vec = 31'h4000_0000\n  u_dut.u_veer.trace_rv_i_valid_ip\n  trace_rv_i_address_ip == 0x8000_0000"
    ),
    (
        "2",
        "TC_MEM_01",
        "VeeR MRAC Side-Effect I/O Configuration:\nConfigure VeeR Machine Region Access Control CSR (0x7C0) to set Region 0 (0x0000_0000–0x0FFF_FFFF) as non-cacheable side-effect I/O.",
        "1. CSR 0x7C0 written with 0x00000002.\n2. External peripheral addresses (AES, UART, SPI, GPIO) retain lower 3 address bits [2:0] without doubleword cache merging.",
        "sw/boot.S (Lines 30-33):\n  li t0, 0x00000002\n  csrw 0x7C0, t0",
        "rtl/Cores-VeeR-EL2/design/dec/el2_dec_tlu_ctl.sv:\n  dec_tlu_mrac_ff[0] == 2'b10 (side-effect I/O)\nrtl/soc_top/soc_top.v:\n  lsu_axi_awaddr / araddr unmasked"
    ),
    (
        "3",
        "TC_UART_01",
        "UART Baud Rate & Format Configuration:\nProgram 16550-compatible UART baud divisor (0x0300_0008) to 868 for 115200 baud at 100 MHz clock and set Line Control (8-N-1).",
        "1. UART_BAUD_REG latches 868.\n2. UART_LCR_REG latches 0x03 (8 data bits, 1 stop bit, no parity).\n3. Serial bit width matches 8680.55 ns.",
        "sw/app/main.c (Line 42):\n  uart_init(868);\nsw/app/soc_regs.h (Lines 150-153):\n  UART_BAUD_REG = baud_div;\n  UART_LCR_REG = 0x03;",
        "tb/soc/tb_soc_top.v (Lines 26-28):\n  BAUD_RATE = 115200\n  BIT_NS = 8680.55 ns\nrtl/uart/axi_uart_top.v:\n  uart_baud_rate_reg_int == 868"
    ),
    (
        "4",
        "TC_UART_02",
        "UART Startup Banner & Telemetry Transmission:\nStream ASCII header banner over UART TX FIFO, polling Transmit Holding Register Empty (THRE) in LSR (0x0300_0014).",
        "1. THRE bit polls high before each byte write.\n2. UART TX FIFO accepts characters without overrun.\n3. Complete Honours Project banner prints to terminal.",
        "sw/app/main.c (Lines 48-53):\n  uart_puts('=== Honours Project ===');\nsw/app/soc_regs.h (Lines 155-165):\n  while (!(UART_LSR_REG & UART_LSR_THRE));\n  UART_THR_REG = c;",
        "tb/soc/tb_soc_top.v (Lines 202-230):\n  Real-time serial RX monitor sampling uart_tx_o falling edges at center of bit period;\n  $write('%c', uart_char)"
    ),
    (
        "5",
        "TC_GPIO_01",
        "GPIO Output Config & LED State 1 (Init Ready):\nConfigure EF_GPIO8 direction register for 8 output lines and assert Status LED 0 to indicate system boot.",
        "1. GPIO direction register latches 0xFF (all outputs).\n2. `gpio_out_o` transitions to 8'b00000001 (0x01) at ~3.56 ms.\n3. `gpio_oe_o` drives 8'hFF.",
        "sw/app/main.c (Lines 43-44):\n  gpio_set_dir(0xFF);\n  gpio_write(0x01);",
        "tb/soc/tb_soc_top.v (Lines 263-267):\n  always @(gpio_out_o) logs:\n  '[TB-GPIO] LED State Updated: 8'b00000001 (0x01) @ 3565000'"
    ),
    (
        "6",
        "TC_AES_KEY_01",
        "128-Bit AUTOSAR SecOC AES Key Loading:\nLoad 128-bit NIST FIPS-197 Appendix B cryptographic key into AES hardware engine registers KEY0–KEY3 (0x0000_0004–0x0000_0010).",
        "1. AES KEY0–KEY3 registers successfully latch words:\n   0x16157e2b, 0xa6d2ae28, 0x8815f7ab, 0x3c4fcf09 across AXI4 interconnect.\n2. Key acknowledged via UART.",
        "sw/app/main.c (Line 56):\n  aes_set_key(nist_key);\nsw/app/soc_regs.h (Lines 60-65):\n  AES_KEY0_REG = key[0];\n  ... AES_KEY3_REG = key[3];",
        "rtl/aes/aes_axi_slave.v (Lines 291-294):\n  cipher_key0 == 32'h16157e2b\n  cipher_key1 == 32'ha6d2ae28\n  cipher_key2 == 32'h8815f7ab\n  cipher_key3 == 32'h3c4fcf09"
    ),
    (
        "7",
        "TC_SRAM_STAGE_01",
        "ECU Plaintext Frame Staging in AXI SRAM:\nStage raw 128-bit ECU sensor plaintext payload into dedicated 64KB AXI SRAM packet buffer at base address 0x0600_0000.",
        "1. AXI SRAM locations 0x0600_0000 to 0x0600_000C hold 4 words:\n   0xa8f64332, 0x8d305a88, 0xa2983131, 0x340737e0.\n2. UART prints payload hex confirmation.",
        "sw/app/main.c (Lines 60-69):\n  sram_staging[0] = ecu_plaintext[0];\n  ... sram_staging[3] = ecu_plaintext[3];\n  print_hex32(ecu_plaintext[i]);",
        "rtl/memory/axi_sram.v:\n  SRAM array mem[0..3] stores plaintext words across s_axi_wdata channel;\n  Console displays: Payload: 0xA8F643328D305A88..."
    ),
    (
        "8",
        "TC_GPIO_02",
        "GPIO Status LED State 2 (AES Active):\nAssert GPIO LED 0 + 1 (8'b00000011 = 0x03) immediately prior to triggering hardware AES pipeline.",
        "1. `gpio_out_o` transitions to 8'h03 at time 39.90 ms.\n2. Confirms transition from peripheral staging to crypto acceleration.",
        "sw/app/main.c (Line 72):\n  gpio_write(0x03);\n  uart_puts('[AES] Triggering pipeline...');",
        "tb/soc/tb_soc_top.v (Lines 263-267):\n  Logs: '[TB-GPIO] LED State Updated: 8'b00000011 (0x03) @ 39906445000'"
    ),
    (
        "9",
        "TC_AES_ENC_01",
        "Autonomous 10-Round AES-128 Hardware Execution:\nWrite plaintext to TEXTIN0–3 and trigger autonomous hardware encryption by setting START bit in AES_CSR_REG (0x0000_0000, bit 16).",
        "1. `cipher_start_reg` asserts 1-cycle pulse.\n2. Hardware autonomous 10-round pipeline executes in ~10 clock cycles.\n3. `cipher_done_reg` asserts high.\n4. CPU polls and detects DONE bit.",
        "sw/app/soc_regs.h (Lines 67-78):\n  AES_TEXTIN0_REG = plain[0];\n  ... AES_CSR_REG = AES_CSR_START;\n  while (!(AES_CSR_REG & AES_CSR_DONE));",
        "rtl/aes/aes_axi_slave.v:\n  cipher_start_reg asserts;\n  aes_cipher_top executes 10 state rounds;\n  cipher_done asserts;\n  cipher_done_reg latches 1'b1."
    ),
    (
        "10",
        "TC_AES_VERIFY_02",
        "Ciphertext Readback & Validation:\nRead back 128-bit ciphertext from AES_TEXTOUT0–3 (0x0000_0024–0x0000_0030) directly into CPU registers and verify against NIST Appendix B.",
        "1. AES_TEXTOUT registers produce exact NIST vector:\n   c0 = 0x9448fe5e, c1 = 0x7c88f20f,\n   c2 = 0x16431804, c3 = 0xfa8db16a.\n2. UART prints: Cipher: 0x9448FE5E7C88F20F16431804FA8DB16A.",
        "sw/app/main.c (Lines 80-87):\n  uint32_t c0 = AES_TEXTOUT0_REG;\n  ... print_hex32(c0); ... print_hex32(c3);",
        "tb/soc/tb_soc_top.v:\n  UART telemetry monitor confirms exact ASCII ciphertext stream matching hardware output."
    ),
    (
        "11",
        "TC_SRAM_CIPHER_01",
        "Ciphertext Storage in AXI SRAM Staging Buffer:\nStore the 128-bit encrypted ciphertext into SRAM staging buffer at offset +0x10 (0x0600_0010–0x0600_001C) for CAN transmission.",
        "1. SRAM words at 0x0600_0010, 0x0600_0014, 0x0600_0018, 0x0600_001C correctly store c0, c1, c2, c3.\n2. Verified without bus errors.",
        "sw/app/main.c (Lines 89-93):\n  sram_staging[4] = c0;\n  sram_staging[5] = c1;\n  sram_staging[6] = c2;\n  sram_staging[7] = c3;",
        "rtl/memory/axi_sram.v:\n  AXI write transactions to addresses 0x0600_0010..0x0600_001C succeed with BRESP=2'b00 (OKAY)."
    ),
    (
        "12",
        "TC_GPIO_03",
        "GPIO Status LED State 3 (SPI Transmission Active):\nAssert GPIO LED 0 + 1 + 2 (8'b00000111 = 0x07) to signal that encrypted frame is being dispatched to MCP2515 CAN controller.",
        "1. `gpio_out_o` transitions to 8'h07 at time 53.81 ms.\n2. Precedes SPI transmission loop.",
        "sw/app/main.c (Line 95):\n  gpio_write(0x07);\n  uart_puts('[SPI] Transmitting encrypted frame...');",
        "tb/soc/tb_soc_top.v (Lines 263-267):\n  Logs: '[TB-GPIO] LED State Updated: 8'b00000111 (0x07) @ 53815675000'"
    ),
    (
        "13",
        "TC_SPI_TX_01",
        "SPI Master 16-Byte CAN Frame Dispatch:\nStream 16 bytes of encrypted ciphertext payload over SPI Master (0x0200_0000) to external MCP2515 CAN bus controller.",
        "1. `spi_cs_n_o` asserts low (CS=0).\n2. Exactly 16 bytes captured on MOSI:\n   0x5E, 0xFE, 0x48, 0x94, 0x0F, 0xF2, 0x88, 0x7C,\n   0x04, 0x18, 0x43, 0x16, 0x6A, 0xB1, 0x8D, 0xFA.\n3. CS deasserts high upon completion.",
        "sw/app/main.c (Lines 97-113):\n  spi_send_byte((uint8_t)(c0 >> 0));\n  ... spi_send_byte((uint8_t)(c3 >> 24));\nsw/app/soc_regs.h (Lines 128-131):\n  while (!(SPI_STATUS_REG & SPI_STATUS_TX_READY));\n  SPI_TX_DATA_REG = data;",
        "tb/soc/tb_soc_top.v (Lines 234-258):\n  Real-time SPI monitor captures active-low CS frame;\n  Verifies 16 sequential bytes on posedge spi_clk_o;\n  Logs '[TB-SPI] Byte 1: 0x5e ... Byte 16: 0xfa'"
    ),
    (
        "14",
        "TC_GPIO_04",
        "GPIO Final Status LED (Transaction Success):\nAssert final status 8'b00000101 (0x05) indicating end-to-end AUTOSAR SecOC transaction completed successfully.",
        "1. `gpio_out_o` transitions to 8'h05 at time 68.68 ms.\n2. Triggers testbench success finish sequence.",
        "sw/app/main.c (Line 116):\n  gpio_write(0x05); // Green LED: Ready & Secure",
        "tb/soc/tb_soc_top.v (Lines 267-274):\n  if (gpio_out_o == 8'h05) begin\n    #2_000_000;\n    $display('[TB] SIMULATION SUCCESS: All 7 AUTOSAR SecOC Phases Completed!');\n    $finish;\n  end"
    ),
    (
        "15",
        "TC_AXI_BUS_01",
        "AXI4 2x8 Crossbar Routing & Single-Beat RLAST Integrity:\nVerify multi-slave routing across AES, DMA, SPI, UART, Timer, GPIO, and SRAM, ensuring all single-beat AXI4-Lite slaves drive RLAST=1.",
        "1. All 7 slave regions respond without DECERR.\n2. `m02_rlast` drives 1'b1, preventing read channel deadlocks.\n3. Concurrent AW and W transactions decode correctly.",
        "sw/app/main.c:\n  CPU executes reads and writes across AES (0x00..), SPI (0x02..), UART (0x03..), GPIO (0x05..), SRAM (0x06..).",
        "rtl/top/axi_interconnect_uart_top.v:\n  m00_axi through m06_axi channel handshakes;\n  assign m02_rlast = 1'b1;\n  s00_arready and rvalid complete cleanly."
    ),
    (
        "16",
        "TC_E2E_01",
        "End-to-End Autonomous SecOC Gateway Cycle:\nVerify full autonomous execution of secure gateway cycle from CPU boot, key load, plaintext staging, AES encryption, SPI CAN dispatch, to final LED confirmation.",
        "1. Full UART banner printed.\n2. 128-bit key loaded into AES.\n3. Plaintext staged in SRAM.\n4. AES generates valid ciphertext.\n5. 16 bytes transmitted over SPI.\n6. Status LEDs 0x01 -> 0x03 -> 0x07 -> 0x05.\n7. SIMULATION SUCCESS at 70.68 ms.",
        "sw/app/main.c (Full Application):\n  Phases 1 through 7 executed sequentially without exceptions.",
        "tb/soc/tb_soc_top.v (Full SoC Testbench):\n  All testbench monitors assert concurrently;\n  Reaches clean $finish at 70680235000 ps with zero errors."
    )
]

# Write data rows
row_start = 5
for row_idx, tc in enumerate(test_cases, start=row_start):
    fill = alt_row_fill if (row_idx % 2 == 1) else white_fill
    for col_idx, val in enumerate(tc, start=1):
        cell = ws.cell(row=row_idx, column=col_idx, value=val)
        cell.fill = fill
        cell.border = thin_border
        
        # Alignment & font
        if col_idx == 1:
            cell.alignment = Alignment(horizontal="center", vertical="top")
            cell.font = bold_font
        elif col_idx == 2:
            cell.alignment = Alignment(horizontal="center", vertical="top")
            cell.font = bold_font
        elif col_idx in (3, 4):
            cell.alignment = Alignment(horizontal="left", vertical="top", wrap_text=True)
            cell.font = data_font
        else: # C Portion and SV Portion
            cell.alignment = Alignment(horizontal="left", vertical="top", wrap_text=True)
            cell.font = code_font

    # Set row height based on content lines
    max_lines = max(val.count('\n') + 1 for val in tc)
    ws.row_dimensions[row_idx].height = max(24, max_lines * 17)

# Adjust column widths
col_widths = {
    "A": 12,  # Serial No.
    "B": 18,  # Test Name
    "C": 40,  # Description
    "D": 42,  # Check Point
    "E": 42,  # C Portion
    "F": 45   # SV Portion
}

for col_letter, width in col_widths.items():
    ws.column_dimensions[col_letter].width = width

out_file = "soc_test_plan.xlsx"
wb.save(out_file)
print(f"Successfully generated {out_file} with {len(test_cases)} test cases.")

# Also copy to docs/
import shutil
shutil.copy(out_file, "docs/soc_test_plan.xlsx")
print("Copied to docs/soc_test_plan.xlsx")
