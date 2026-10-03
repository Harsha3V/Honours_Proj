/* =============================================================================
 * Project        : Honours Project
 * File           : tb_veer_uart_soc.v
 * Description    : VCS simulation testbench for veer_uart_soc_top.
 *
 *   - Generates 100 MHz clock and reset sequence.
 *   - Sets VeeR reset vector to 0x8000_0000 (start of ifu_rom_stub).
 *   - Monitors uart_tx_o and decodes received characters in real time.
 *   - Prints each character to the console as it arrives.
 *   - Stops simulation after receiving the full "Hello UART\r\n" string
 *     OR after a timeout of 5 ms simulated time.
 *   - Generates FSDB waveform for Verdi (if VCS compiled with -kdb).
 *
 * Baud rate assumed: 115200 bps → bit period = 1s/115200 ≈ 8680 ns
 * Clock period     : 10 ns (100 MHz)
 *
 * Compile & run:
 *   export RV_ROOT=../rtl/Cores-VeeR-EL2
 *   vcs -full64 -debug_access+all -kdb                  \
 *       -sverilog +define+RV_BUILD_AXI4                 \
 *       +incdir+$RV_ROOT/design/include                 \
 *       +incdir+$RV_ROOT/configs                        \
 *       +incdir+../rtl/uart/include                     \
 *       -timescale=1ns/1ps                              \
 *       -f run_veer_uart_soc.f                          \
 *       -top tb_veer_uart_soc                           \
 *       -o simv_veer_uart && ./simv_veer_uart
 * =============================================================================*/

`timescale 1ns/1ps

module tb_veer_uart_soc;

// =========================================================================
// Parameters
// =========================================================================

// Clock & timing
localparam CLK_PERIOD   = 10;           // ns  (100 MHz)
localparam RESET_CYCLES = 20;           // clock cycles to hold reset

// UART parameters
localparam BAUD_RATE    = 115200;
// Bit period in ns (rounded)
localparam real BIT_NS  = 1.0e9 / BAUD_RATE;  // ≈ 8680 ns
// Timeout = 1 ms (shortened for debug)
localparam TIMEOUT_NS   = 1_000_000;

// Expected string (must match boot.S)
localparam EXP_STR = "Hello UART\r\n";
localparam EXP_LEN = 12;               // 12 characters including \r\n

// =========================================================================
// DUT port signals
// =========================================================================

reg         clk;
reg         rst_l;      // active-high reset for VeeR
reg         rstn;       // active-low  reset for IC / UART

// VeeR control
reg [31:1]  rst_vec;
reg         nmi_int;
reg [31:1]  nmi_vec;
reg [31:1]  jtag_id;

// JTAG (unused)
reg         jtag_tck;
reg         jtag_tms;
reg         jtag_tdi;
wire        jtag_tdo;

// UART
wire        uart_tx_o;
reg         uart_rx_i;
wire        uart_interrupt_o;

// =========================================================================
// DUT instantiation
// =========================================================================

veer_uart_soc_top #(
    .LSU_BUS_TAG  (3),
    .IFU_BUS_TAG  (3),
    .SB_BUS_TAG   (1),
    .DMA_BUS_TAG  (1),
    .IC_ID_WIDTH  (8),
    .IC_ADDR_WIDTH(32),
    .IC_DATA_WIDTH(32),
    .ROM_DEPTH    (1024)
) u_dut (
    .clk            (clk),
    .rst_l          (rst_l),
    .rstn           (rstn),

    .rst_vec        (rst_vec),
    .nmi_int        (nmi_int),
    .nmi_vec        (nmi_vec),
    .jtag_id        (jtag_id),

    .jtag_tck       (jtag_tck),
    .jtag_tms       (jtag_tms),
    .jtag_tdi       (jtag_tdi),
    .jtag_tdo       (jtag_tdo),

    .uart_rx_i      (uart_rx_i),
    .uart_tx_o      (uart_tx_o),
    .uart_interrupt_o(uart_interrupt_o)
);

// =========================================================================
// Clock generation  — 100 MHz
// =========================================================================

initial clk = 1'b0;
always #(CLK_PERIOD/2) clk = ~clk;

// =========================================================================
// Reset sequence
// =========================================================================

initial begin
    // Initialise all inputs
    rst_l    = 1'b0;        // VeeR: held in reset (active-high)
    rstn     = 1'b0;        // IC/UART: held in reset (active-low)
    rst_vec  = 31'h40000000; // 0x8000_0000 >> 1  (reset vector)
    nmi_int  = 1'b0;
    nmi_vec  = 31'h00000010; // NMI vector (not used)
    jtag_id  = 31'h0;
    jtag_tck = 1'b0;
    jtag_tms = 1'b1;        // JTAG: keep in reset state
    jtag_tdi = 1'b0;
    uart_rx_i = 1'b1;       // UART idle line = HIGH

    // Hold reset for RESET_CYCLES clock cycles
    repeat (RESET_CYCLES) @(posedge clk);
    #1;                     // small delay past clock edge
    rst_l = 1'b1;           // release VeeR reset
    rstn  = 1'b1;           // release IC/UART reset

    $display("[TB] Reset released at time %0t ns", $time);
end

// =========================================================================
// UART RX monitor — decodes bits from uart_tx_o
//   - Waits for start bit (falling edge on uart_tx_o)
//   - Samples at middle of each bit period
//   - Assembles 8 data bits (LSB first)
//   - Prints the character and accumulates received string
// =========================================================================

integer     char_idx;
reg [7:0]   rx_char;
reg [7:0]   received [0:EXP_LEN-1];
integer     rx_count;
integer     match;
integer     i;

initial begin
    rx_count = 0;
    char_idx = 0;

    $display("[TB] UART monitor started. Waiting for transmission...");
    $display("[TB] Baud rate = %0d bps, bit period = %0.1f ns", BAUD_RATE, BIT_NS);

    // Wait until reset is released
    wait (rst_l === 1'b1);

    forever begin
        // Wait for start bit: falling edge on TX
        @(negedge uart_tx_o);

        // Confirm it is a real start bit (not glitch): sample mid-bit
        #(BIT_NS / 2.0);
        if (uart_tx_o !== 1'b0) begin
            $display("[TB] Spurious glitch on uart_tx_o at %0t — ignored", $time);
            disable start_bit_check;
        end

        // Sample 8 data bits at centre of each bit period
        rx_char = 8'h00;
        begin : start_bit_check
            repeat (8) begin
                #(BIT_NS);  // advance by one full bit period
                rx_char = {uart_tx_o, rx_char[7:1]};   // LSB first
            end
        end

        // Skip stop bit
        #(BIT_NS);

        // Print received character
        if (rx_char >= 8'h20 && rx_char < 8'h7F)
            $display("[UART RX] char = '%s'  (0x%02X)  @ %0t ns",
                     rx_char, rx_char, $time);
        else if (rx_char == 8'h0D)
            $display("[UART RX] char = <CR>  (0x0D)  @ %0t ns", $time);
        else if (rx_char == 8'h0A)
            $display("[UART RX] char = <LF>  (0x0A)  @ %0t ns", $time);
        else
            $display("[UART RX] char = <0x%02X>  @ %0t ns", rx_char, $time);

        // Store and check
        if (rx_count < EXP_LEN) begin
            received[rx_count] = rx_char;
            rx_count = rx_count + 1;
        end

        // Once we have enough characters, check the string
        if (rx_count == EXP_LEN) begin
            $display("");
            $display("[TB] ====================================");
            $display("[TB] Received %0d characters. Checking...", EXP_LEN);

            match = 1;
            for (i = 0; i < EXP_LEN; i = i + 1) begin
                if (received[i] !== EXP_STR[((EXP_LEN-1-i)*8) +: 8]) begin
                    match = 0;
                    $display("[TB] MISMATCH at char %0d: got 0x%02X expected 0x%02X",
                             i, received[i],
                             EXP_STR[((EXP_LEN-1-i)*8) +: 8]);
                end
            end

            if (match) begin
                $display("[TB] PASS — received string matches 'Hello UART\\r\\n'");
            end else begin
                $display("[TB] FAIL — received string does NOT match expected");
            end

            $display("[TB] ====================================");
            $display("");
            $finish;
        end
    end
end

// =========================================================================
// Simulation timeout
// =========================================================================

initial begin
    #TIMEOUT_NS;
    $display("[TB] TIMEOUT at %0t ns — simulation ended without full string", $time);
    if (rx_count > 0)
        $display("[TB] Received %0d/%0d characters before timeout", rx_count, EXP_LEN);
    $finish;
end

// =========================================================================
// Waveform dump (FSDB for Verdi)
// =========================================================================

initial begin
`ifdef FSDB
    $fsdbDumpfile("tb_veer_uart_soc.fsdb");
    $fsdbDumpvars(0, tb_veer_uart_soc);
    $display("[TB] FSDB waveform dump enabled");
`endif
`ifdef VCD
    $dumpfile("tb_veer_uart_soc.vcd");
    $dumpvars(0, tb_veer_uart_soc);
    $display("[TB] VCD waveform dump enabled");
`endif
end

// =========================================================================
// Optional: display key signal states at reset release
// =========================================================================

initial begin
    wait (rst_l === 1'b1);
    @(posedge clk);
    $display("[TB] rst_vec = 0x%08X (boot from 0x%08X)",
             {rst_vec, 1'b0}, {rst_vec, 1'b0});
    $display("[TB] Core running — monitoring uart_tx_o...");
end

// =========================================================================
// IFU AXI monitor — print every instruction fetch address
// =========================================================================
always @(posedge clk) begin
    if (u_dut.ifu_axi_arvalid && u_dut.ifu_axi_arready)
        $display("[IFU AR] addr=0x%08X len=%0d @ %0t ns",
                 u_dut.ifu_axi_araddr, u_dut.ifu_axi_arlen, $time);
end

// =========================================================================
// LSU AXI monitor — print every load/store
// =========================================================================
always @(posedge clk) begin
    if (u_dut.lsu_axi_awvalid && u_dut.lsu_axi_awready)
        $display("[LSU AW] addr=0x%08X @ %0t ns",
                 u_dut.lsu_axi_awaddr, $time);
    if (u_dut.lsu_axi_arvalid && u_dut.lsu_axi_arready)
        $display("[LSU AR] addr=0x%08X @ %0t ns",
                 u_dut.lsu_axi_araddr, $time);
    if (u_dut.lsu_axi_wvalid && u_dut.lsu_axi_wready)
        $display("[LSU W ] data=0x%016X strb=0x%02X @ %0t ns",
                 u_dut.lsu_axi_wdata, u_dut.lsu_axi_wstrb, $time);
end

// =========================================================================
// uart_tx_o change monitor
// =========================================================================
always @(u_dut.uart_tx_o)
    $display("[TX PIN] uart_tx_o changed to %b @ %0t ns",
             u_dut.uart_tx_o, $time);

endmodule
