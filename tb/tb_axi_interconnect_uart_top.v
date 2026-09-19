/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : tb_axi_interconnect_uart_top.v
 * Description    : Testbench for axi_interconnect_uart_top
 *                  Tests the full path:
 *                  Testbench → Interconnect → Bridge → UART
 *
 * Tests:
 *   TC1: Reset check
 *   TC2: Configure UART (LCR + baud divisor) via interconnect
 *   TC3: Write THR (TX byte 0x41 'A') via interconnect, capture serial TX
 *   TC4: Read LSR via interconnect — verify TX empty (0x60)
 *   TC5: Enable RX interrupt (IER) via interconnect
 *   TC6: Drive RX serial frame (0x42 'B'), read RBR via interconnect
 *   TC7: Loopback — TX 0x37, verify RX 0x37 via interconnect
 *   TC8: Unknown address write — bus must not hang
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_axi_interconnect_uart_top;

// ====================================================================
// Parameters
// ====================================================================
localparam DATA_WIDTH  = 32;
localparam ADDR_WIDTH  = 32;
localparam ID_WIDTH    = 8;
localparam DATA_UART   = 8;
localparam BAUD_DIV    = 32'd20;   // small for fast simulation
localparam CLK_PERIOD  = 10;       // 100MHz
localparam TIMEOUT     = 500;

// UART register addresses (full 32-bit, lower 5 bits select register)
// These go through the interconnect → bridge → UART
// UART base address = 0x0000_0000 (M00 of interconnect)
localparam ADDR_THR_RBR = 32'h0000_0000;  // TX write / RX read
localparam ADDR_IER     = 32'h0000_0004;  // Interrupt enable
localparam ADDR_BAUD    = 32'h0000_0008;  // Baud divisor (DLAB=1)
localparam ADDR_LCR     = 32'h0000_000C;  // Line control
localparam ADDR_LSR     = 32'h0000_0014;  // Line status

// LCR bit positions
localparam LCR_DLAB = 7;

// ====================================================================
// DUT port signals
// ====================================================================
reg                      clk;
reg                      rstn;

// S00 AXI4 — driven by testbench
reg  [ID_WIDTH-1:0]      s00_awid;
reg  [ADDR_WIDTH-1:0]    s00_awaddr;
reg  [7:0]               s00_awlen;
reg  [2:0]               s00_awsize;
reg  [1:0]               s00_awburst;
reg                      s00_awlock;
reg  [3:0]               s00_awcache;
reg  [2:0]               s00_awprot;
reg  [3:0]               s00_awqos;
reg                      s00_awvalid;
wire                     s00_awready;

reg  [DATA_WIDTH-1:0]    s00_wdata;
reg  [DATA_WIDTH/8-1:0]  s00_wstrb;
reg                      s00_wlast;
reg                      s00_wvalid;
wire                     s00_wready;

wire [ID_WIDTH-1:0]      s00_bid;
wire [1:0]               s00_bresp;
wire                     s00_bvalid;
reg                      s00_bready;

reg  [ID_WIDTH-1:0]      s00_arid;
reg  [ADDR_WIDTH-1:0]    s00_araddr;
reg  [7:0]               s00_arlen;
reg  [2:0]               s00_arsize;
reg  [1:0]               s00_arburst;
reg                      s00_arlock;
reg  [3:0]               s00_arcache;
reg  [2:0]               s00_arprot;
reg  [3:0]               s00_arqos;
reg                      s00_arvalid;
wire                     s00_arready;

wire [ID_WIDTH-1:0]      s00_rid;
wire [DATA_WIDTH-1:0]    s00_rdata;
wire [1:0]               s00_rresp;
wire                     s00_rlast;
wire                     s00_rvalid;
reg                      s00_rready;

// UART serial
wire                     uart_tx_o;
reg                      uart_rx_i;
wire                     uart_interrupt_o;

// Loopback control
reg                      loopback_en;
reg                      rx_force;
assign #1 uart_rx_i = loopback_en ? uart_tx_o : rx_force;

// ====================================================================
// DUT instantiation
// ====================================================================
axi_interconnect_uart_top #(
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDR_WIDTH     (ADDR_WIDTH),
    .ID_WIDTH       (ID_WIDTH),
    .UART_BASE_ADDR (32'h0000_0000),
    .UART_ADDR_WIDTH(24)
) dut (
    .clk            (clk),
    .rstn           (rstn),

    .s00_axi_awid   (s00_awid),
    .s00_axi_awaddr (s00_awaddr),
    .s00_axi_awlen  (s00_awlen),
    .s00_axi_awsize (s00_awsize),
    .s00_axi_awburst(s00_awburst),
    .s00_axi_awlock (s00_awlock),
    .s00_axi_awcache(s00_awcache),
    .s00_axi_awprot (s00_awprot),
    .s00_axi_awqos  (s00_awqos),
    .s00_axi_awvalid(s00_awvalid),
    .s00_axi_awready(s00_awready),

    .s00_axi_wdata  (s00_wdata),
    .s00_axi_wstrb  (s00_wstrb),
    .s00_axi_wlast  (s00_wlast),
    .s00_axi_wvalid (s00_wvalid),
    .s00_axi_wready (s00_wready),

    .s00_axi_bid    (s00_bid),
    .s00_axi_bresp  (s00_bresp),
    .s00_axi_bvalid (s00_bvalid),
    .s00_axi_bready (s00_bready),

    .s00_axi_arid   (s00_arid),
    .s00_axi_araddr (s00_araddr),
    .s00_axi_arlen  (s00_arlen),
    .s00_axi_arsize (s00_arsize),
    .s00_axi_arburst(s00_arburst),
    .s00_axi_arlock (s00_arlock),
    .s00_axi_arcache(s00_arcache),
    .s00_axi_arprot (s00_arprot),
    .s00_axi_arqos  (s00_arqos),
    .s00_axi_arvalid(s00_arvalid),
    .s00_axi_arready(s00_arready),

    .s00_axi_rid    (s00_rid),
    .s00_axi_rdata  (s00_rdata),
    .s00_axi_rresp  (s00_rresp),
    .s00_axi_rlast  (s00_rlast),
    .s00_axi_rvalid (s00_rvalid),
    .s00_axi_rready (s00_rready),

    .uart_rx_i      (uart_rx_i),
    .uart_tx_o      (uart_tx_o),
    .uart_interrupt_o(uart_interrupt_o)
);

// ====================================================================
// Clock generation — 100 MHz
// ====================================================================
initial clk = 1'b0;
always #(CLK_PERIOD/2) clk = ~clk;

// ====================================================================
// AXI Write Task
// Master → Interconnect → Bridge → UART
// ====================================================================
task axi_write;
    input [ADDR_WIDTH-1:0]  addr;
    input [DATA_WIDTH-1:0]  data;
    integer timeout;
    begin
        @(negedge clk);
        s00_awid    = 8'h01;
        s00_awaddr  = addr;
        s00_awlen   = 8'h00;      // 1 beat
        s00_awsize  = 3'b010;     // 4 bytes
        s00_awburst = 2'b01;      // INCR
        s00_awlock  = 1'b0;
        s00_awcache = 4'h0;
        s00_awprot  = 3'h0;
        s00_awqos   = 4'h0;
        s00_awvalid = 1'b1;
        s00_wdata   = data;
        s00_wstrb   = 4'hF;
        s00_wlast   = 1'b1;
        s00_wvalid  = 1'b1;
        s00_bready  = 1'b1;

        // Wait for AW handshake
        timeout = 0;
        @(posedge clk); #1;
        while (!s00_awready && timeout < TIMEOUT) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= TIMEOUT)
            $display("  [TIMEOUT] axi_write AWREADY addr=0x%08h", addr);

        @(negedge clk);
        s00_awvalid = 1'b0;

        // Wait for W handshake
        timeout = 0;
        @(posedge clk); #1;
        while (!s00_wready && timeout < TIMEOUT) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= TIMEOUT)
            $display("  [TIMEOUT] axi_write WREADY addr=0x%08h", addr);

        @(negedge clk);
        s00_wvalid = 1'b0;
        s00_wlast  = 1'b0;

        // Wait for B response
        timeout = 0;
        @(posedge clk); #1;
        while (!s00_bvalid && timeout < TIMEOUT) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= TIMEOUT)
            $display("  [TIMEOUT] axi_write BVALID addr=0x%08h", addr);

        @(negedge clk);
        s00_bready = 1'b0;
        repeat(2) @(posedge clk);
    end
endtask

// ====================================================================
// AXI Read Task
// Master → Interconnect → Bridge → UART → back
// ====================================================================
task axi_read;
    input  [ADDR_WIDTH-1:0]  addr;
    output [DATA_WIDTH-1:0]  data_out;
    integer timeout;
    begin
        @(negedge clk);
        s00_arid    = 8'h01;
        s00_araddr  = addr;
        s00_arlen   = 8'h00;
        s00_arsize  = 3'b010;
        s00_arburst = 2'b01;
        s00_arlock  = 1'b0;
        s00_arcache = 4'h0;
        s00_arprot  = 3'h0;
        s00_arqos   = 4'h0;
        s00_arvalid = 1'b1;
        s00_rready  = 1'b1;

        // Wait for AR handshake
        timeout = 0;
        @(posedge clk); #1;
        while (!s00_arready && timeout < TIMEOUT) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= TIMEOUT)
            $display("  [TIMEOUT] axi_read ARREADY addr=0x%08h", addr);

        @(negedge clk);
        s00_arvalid = 1'b0;

        // Wait for R data
        timeout = 0;
        @(posedge clk); #1;
        while (!s00_rvalid && timeout < TIMEOUT) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= TIMEOUT)
            $display("  [TIMEOUT] axi_read RVALID addr=0x%08h", addr);
        else
            data_out = s00_rdata;

        @(negedge clk);
        s00_rready = 1'b0;
        repeat(2) @(posedge clk);
    end
endtask

// ====================================================================
// Drive RX serial frame on uart_rx_i
// ====================================================================
task drive_rx_frame;
    input [DATA_UART-1:0] data;
    integer k;
    begin
        loopback_en = 1'b0;
        rx_force    = 1'b0;           // START bit
        repeat(BAUD_DIV) @(posedge clk);
        for (k = 0; k < DATA_UART; k = k+1) begin
            rx_force = data[k];       // DATA bits LSB first
            repeat(BAUD_DIV) @(posedge clk);
        end
        rx_force = 1'b1;              // STOP bit
        repeat(BAUD_DIV) @(posedge clk);
    end
endtask

// ====================================================================
// Capture TX serial frame from uart_tx_o
// ====================================================================
task capture_tx;
    output [DATA_UART-1:0] data_out;
    integer k;
    begin
        @(negedge uart_tx_o);                        // wait for START bit
        repeat(BAUD_DIV/2) @(posedge clk);           // move to center
        for (k = 0; k < DATA_UART; k = k+1) begin
            repeat(BAUD_DIV) @(posedge clk);
            data_out[k] = uart_tx_o;                 // sample each bit
        end
        repeat(BAUD_DIV) @(posedge clk);             // STOP bit
    end
endtask

// ====================================================================
// Pass / Fail checker
// ====================================================================
integer pass_cnt, fail_cnt;

task check;
    input [31:0]   got;
    input [31:0]   expected;
    input [255:0]  name;
    begin
        if (got === expected) begin
            $display("  PASS  %-50s  got=0x%08h", name, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL  %-50s  exp=0x%08h  got=0x%08h",
                     name, expected, got);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

// ====================================================================
// Main Test
// ====================================================================
reg [DATA_WIDTH-1:0] rd_data;
reg [DATA_UART-1:0]  cap_tx;

initial begin
    // ------------------------------------------------------------
    // Initialise
    // ------------------------------------------------------------
    pass_cnt    = 0;
    fail_cnt    = 0;
    rstn        = 1'b0;
    loopback_en = 1'b0;
    rx_force    = 1'b1;     // idle HIGH

    s00_awvalid = 0; s00_awaddr = 0; s00_awid = 0;
    s00_wvalid  = 0; s00_wdata  = 0; s00_wstrb = 4'hF;
    s00_wlast   = 0; s00_bready = 0;
    s00_arvalid = 0; s00_araddr = 0; s00_arid  = 0;
    s00_arlen   = 0; s00_arsize = 3'b010;
    s00_arburst = 2'b01; s00_arlock = 0;
    s00_arcache = 0; s00_arprot = 0; s00_arqos = 0;
    s00_awlen   = 0; s00_awsize = 3'b010;
    s00_awburst = 2'b01; s00_awlock = 0;
    s00_awcache = 0; s00_awprot = 0; s00_awqos = 0;
    s00_rready  = 0;

    // ------------------------------------------------------------
    // TC1: Reset check
    // ------------------------------------------------------------
    $display("\n========================================");
    $display("  AXI Interconnect + Bridge + UART TB");
    $display("========================================");
    $display("\n--- TC1: Reset check ---");
    repeat(10) @(posedge clk);
    check(uart_tx_o,        1, "uart_tx_o=1 during reset (idle)");
    check(s00_rvalid,       0, "rvalid=0 during reset");
    check(s00_bvalid,       0, "bvalid=0 during reset");
    check(uart_interrupt_o, 0, "interrupt=0 during reset");

    // Release reset
    rstn = 1'b1;
    repeat(10) @(posedge clk);
    check(uart_tx_o, 1, "uart_tx_o=1 after reset (idle)");
    $display("  INFO  Reset released");

    // ------------------------------------------------------------
    // TC2: Configure UART via interconnect
    //   Step 1: Write LCR with DLAB=1  → unlock baud register
    //   Step 2: Write baud divisor = 20
    //   Step 3: Write LCR with DLAB=0  → lock baud register
    // ------------------------------------------------------------
    $display("\n--- TC2: Configure UART (LCR + baud divisor) ---");
    $display("  INFO  Path: TB → Interconnect S00 → M00 → Bridge → UART");

    // Set DLAB=1
    axi_write(ADDR_LCR, 32'h1 << LCR_DLAB);
    $display("  INFO  LCR written: DLAB=1");

    // Write baud divisor
    axi_write(ADDR_BAUD, BAUD_DIV);
    $display("  INFO  Baud divisor written: %0d", BAUD_DIV);

    // Clear DLAB
    axi_write(ADDR_LCR, 32'h00000000);
    $display("  INFO  LCR written: DLAB=0, no parity, 1 stop bit");

    repeat(3) @(posedge clk);

    // ------------------------------------------------------------
    // TC3: Write THR 0x41 ('A') and capture serial TX frame
    // ------------------------------------------------------------
    $display("\n--- TC3: TX byte 0x41 via interconnect ---");
    $display("  INFO  Path: TB → Interconnect → Bridge → UART TX FIFO → uart_tx_o");
    fork
        axi_write(ADDR_THR_RBR, 32'h41);
        capture_tx(cap_tx);
    join
    check(cap_tx, 8'h41, "TX serial frame = 0x41 (A)");

    // ------------------------------------------------------------
    // TC4: Read LSR — verify TX empty
    // ------------------------------------------------------------
    $display("\n--- TC4: Read LSR via interconnect ---");
    $display("  INFO  Path: TB → Interconnect → Bridge → UART LSR → back");
    repeat(5) @(posedge clk);
    axi_read(ADDR_LSR, rd_data);
    $display("  INFO  LSR = 0x%08h", rd_data);
    // bit5=THRE, bit6=TEMT → both 1 = 0x60 when TX empty
    check(rd_data & 32'h60, 32'h60, "LSR THRE+TEMT=1 (TX empty)");

    // ------------------------------------------------------------
    // TC5: Enable RX interrupt
    // ------------------------------------------------------------
    $display("\n--- TC5: Enable RX interrupt (IER) ---");
    axi_write(ADDR_IER, 32'h1);
    $display("  INFO  IER=1 written via interconnect");

    // ------------------------------------------------------------
    // TC6: Drive RX frame 0x42 ('B'), read RBR
    // ------------------------------------------------------------
    $display("\n--- TC6: RX byte 0x42 via serial, read via interconnect ---");
    $display("  INFO  Path: uart_rx_i → UART RX → RX FIFO → Bridge → Interconnect → TB");
    drive_rx_frame(8'h42);
    repeat(20) @(posedge clk);
    // Check interrupt fired
    check(uart_interrupt_o, 1, "read_interrupt_o=1 after RX byte");
    // Read RBR via interconnect
    axi_read(ADDR_THR_RBR, rd_data);
    check(rd_data[7:0], 8'h42, "RBR = 0x42 (B) via interconnect");

    // ------------------------------------------------------------
    // TC7: Loopback 0x37 — TX feeds RX via interconnect
    // ------------------------------------------------------------
    $display("\n--- TC7: Loopback TX->RX 0x37 via interconnect ---");
    $display("  INFO  uart_tx_o connected back to uart_rx_i");
    loopback_en = 1'b1;
    fork
        axi_write(ADDR_THR_RBR, 32'h37);
        begin
            repeat(10*(DATA_UART+3)*BAUD_DIV) @(posedge clk);
            repeat(10) @(posedge clk);
        end
    join
    loopback_en = 1'b0;
    rx_force    = 1'b1;
    axi_read(ADDR_THR_RBR, rd_data);
    check(rd_data[7:0], 8'h37, "Loopback RBR = 0x37 via interconnect");

    // ------------------------------------------------------------
    // TC8: Unknown address write — bus must not hang
    // ------------------------------------------------------------
    $display("\n--- TC8: Unknown address write (no hang check) ---");
    // Address 0x0200_0000 maps to M02 which is tied off with ready=1
    axi_write(32'h0200_0000, 32'hDEADBEEF);
    $display("  INFO  Write to unused slave (M02) completed without hang");

    // ------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------
    repeat(10) @(posedge clk);
    $display("\n========================================");
    $display("  SUMMARY: %0d passed, %0d failed", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display("  ALL TESTS PASSED ✓");
    else
        $display("  SOME TESTS FAILED ✗");
    $display("========================================\n");
    $finish;
end

// ====================================================================
// Waveform dump
// ====================================================================
initial begin
    $fsdbDumpfile("dump_integration.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA();
    $fsdbDumpMDA();
end

// ====================================================================
// Watchdog
// ====================================================================
initial begin
    #10000000;
    $display("WATCHDOG TIMEOUT at %0t", $time);
    $finish;
end

endmodule
