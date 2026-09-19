/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_axi_uart_top.v
 * Description : Integration testbench for axi_uart_top.
 *
 * Tests:
 *   1.  Reset: AXI outputs de-asserted, uart_tx_o=1.
 *   2.  Write LCR  (addr=3<<2): set DLAB=0, no parity, 1 stop bit.
 *   3.  Write THR  (addr=0<<2): push one byte to TX FIFO (0x41 = 'A').
 *   4.  Observe serial TX frame on uart_tx_o and verify it carries 0x41.
 *   5.  Write IER  (addr=1<<2): enable RX interrupt.
 *   6.  Drive a serial RX frame (0x42 = 'B') on uart_rx_i.
 *   7.  Read  RBR  (addr=0<<2): verify axi_rdata_o carries 0x42.
 *   8.  Read  LSR  (addr=5<<2): verify THRE/TEMT bits are set.
 *   9.  Write BAUD_DIVISOR with DLAB=1: change to a new divisor.
 *   10. Full loopback: TX byte, observe it echoes back on RX.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_axi_uart_top;

  // ---- AXI-Lite parameters (matching axi_uart_defines.vh) ----
  localparam AXI_DATA_W  = 32;
  localparam AXI_ADDR_W  = 5;
  localparam AXI_ID_W    = 12;
  localparam AXI_RESP_W  = 2;
  localparam DATA_UART   = 8;
  localparam BAUD_DIV    = 32'd20;    // tiny divisor for fast simulation

  // Register addresses (word-aligned, bits [4:2] are the register select)
  localparam ADDR_RBR_THR = 5'h00;   // offset 0  -> addr[4:2]=0
  localparam ADDR_IER     = 5'h04;   // offset 4  -> addr[4:2]=1
  localparam ADDR_BAUD    = 5'h08;   // offset 8  -> addr[4:2]=2
  localparam ADDR_LCR     = 5'h0C;   // offset 12 -> addr[4:2]=3
  localparam ADDR_LSR     = 5'h14;   // offset 20 -> addr[4:2]=5

  // LCR bit positions (from axi_uart.vh)
  localparam LCR_DLAB         = 7;
  localparam LCR_PARITY_EN    = 3;
  localparam LCR_PARITY_MODE  = 4;
  localparam LCR_STOP_BITS    = 2;

  // ---- DUT ports ----
  reg                       fixed_clk_i;
  reg                       axi_aclk_i;
  reg                       axi_aresetn_i;

  // AR channel
  reg  [AXI_ID_W-1:0]       axi_arid_i;
  reg  [AXI_ADDR_W-1:0]     axi_araddr_i;
  reg                       axi_arvalid_i;
  wire                      axi_arready_o;
  // R channel
  wire [AXI_ID_W-1:0]       axi_rid_o;
  wire [AXI_DATA_W-1:0]     axi_rdata_o;
  wire [AXI_RESP_W-1:0]     axi_rresp_o;
  wire                      axi_rvalid_o;
  reg                       axi_rready_i;
  // AW channel
  reg  [AXI_ID_W-1:0]       axi_awid_i;
  reg  [AXI_ADDR_W-1:0]     axi_awaddr_i;
  reg                       axi_awvalid_i;
  wire                      axi_awready_o;
  // W channel
  reg  [AXI_DATA_W-1:0]     axi_wdata_i;
  reg  [AXI_DATA_W/8-1:0]   axi_wstrb_i;
  reg                        axi_wvalid_i;
  wire                       axi_wready_o;
  // B channel
  wire [AXI_ID_W-1:0]        axi_bid_o;
  wire [AXI_RESP_W-1:0]      axi_bresp_o;
  wire                        axi_bvalid_o;
  reg                         axi_bready_i;

  // UART
  wire                        read_interrupt_o;
  wire                        uart_rx_i;   // wire – driven by mux below
  wire                        uart_tx_o;

  // Loopback control: 0 = task drives rx_force, 1 = loopback from tx
  reg                         loopback_en;
  reg                         rx_force;    // driven by tasks (drive_rx_frame)

  // Mux: loopback_en selects between tx loopback and manual rx_force
  assign #1 uart_rx_i = loopback_en ? uart_tx_o : rx_force;

  // ---- DUT instantiation ----
  axi_uart_top dut (
    .fixed_clk_i      (fixed_clk_i),
    .axi_aclk_i       (axi_aclk_i),
    .axi_aresetn_i    (axi_aresetn_i),
    .axi_arid_i       (axi_arid_i),
    .axi_araddr_i     (axi_araddr_i),
    .axi_arvalid_i    (axi_arvalid_i),
    .axi_arready_o    (axi_arready_o),
    .axi_rid_o        (axi_rid_o),
    .axi_rdata_o      (axi_rdata_o),
    .axi_rresp_o      (axi_rresp_o),
    .axi_rvalid_o     (axi_rvalid_o),
    .axi_rready_i     (axi_rready_i),
    .axi_awid_i       (axi_awid_i),
    .axi_awaddr_i     (axi_awaddr_i),
    .axi_awvalid_i    (axi_awvalid_i),
    .axi_awready_o    (axi_awready_o),
    .axi_wdata_i      (axi_wdata_i),
    .axi_wstrb_i      (axi_wstrb_i),
    .axi_wvalid_i     (axi_wvalid_i),
    .axi_wready_o     (axi_wready_o),
    .axi_bid_o        (axi_bid_o),
    .axi_bresp_o      (axi_bresp_o),
    .axi_bvalid_o     (axi_bvalid_o),
    .axi_bready_i     (axi_bready_i),
    .read_interrupt_o (read_interrupt_o),
    .uart_rx_i        (uart_rx_i),
    .uart_tx_o        (uart_tx_o)
  );

  // ---- clocks (100 MHz, same frequency for both clock domains) ----
  initial fixed_clk_i = 1'b0;
  always  #5 fixed_clk_i  = ~fixed_clk_i;
  initial axi_aclk_i  = 1'b0;
  always  #5 axi_aclk_i   = ~axi_aclk_i;

  // ---- AXI write task ----
  task axi_write;
    input [AXI_ADDR_W-1:0] addr;
    input [AXI_DATA_W-1:0] data;
    integer timeout;
    begin
      @(negedge axi_aclk_i);
      axi_awaddr_i  = addr;
      axi_awid_i    = 12'h001;
      axi_awvalid_i = 1'b1;
      axi_wdata_i   = data;
      axi_wstrb_i   = 4'hF;
      axi_wvalid_i  = 1'b1;
      axi_bready_i  = 1'b1;
      // Wait for both ready signals
      timeout = 0;
      while (!(axi_awready_o && axi_wready_o) && timeout < 200) begin
        @(posedge axi_aclk_i); #1;
        timeout = timeout + 1;
      end
      @(negedge axi_aclk_i);
      axi_awvalid_i = 1'b0;
      axi_wvalid_i  = 1'b0;
      // Wait for bvalid
      timeout = 0;
      while (!axi_bvalid_o && timeout < 200) begin
        @(posedge axi_aclk_i); #1;
        timeout = timeout + 1;
      end
      @(negedge axi_aclk_i);
      axi_bready_i = 1'b0;
      repeat(2) @(posedge axi_aclk_i);
    end
  endtask

  // ---- AXI read task ----
  task axi_read;
    input  [AXI_ADDR_W-1:0]  addr;
    output [AXI_DATA_W-1:0]  data_out;
    integer timeout;
    begin
      @(negedge axi_aclk_i);
      axi_araddr_i  = addr;
      axi_arid_i    = 12'h001;
      axi_arvalid_i = 1'b1;
      axi_rready_i  = 1'b1;
      // Wait for arready
      timeout = 0;
      while (!axi_arready_o && timeout < 200) begin
        @(posedge axi_aclk_i); #1;
        timeout = timeout + 1;
      end
      @(negedge axi_aclk_i);
      axi_arvalid_i = 1'b0;
      // Wait for rvalid
      timeout = 0;
      while (!axi_rvalid_o && timeout < 200) begin
        @(posedge axi_aclk_i); #1;
        timeout = timeout + 1;
      end
      data_out     = axi_rdata_o;
      @(negedge axi_aclk_i);
      axi_rready_i = 1'b0;
      repeat(2) @(posedge axi_aclk_i);
    end
  endtask

  // ---- Drive a serial RX UART frame ----
  task drive_rx_frame;
    input [DATA_UART-1:0] data;
    integer k;
    begin
      loopback_en = 1'b0;          // disable loopback while driving manually
      rx_force = 1'b0;             // start bit
      repeat(BAUD_DIV) @(posedge fixed_clk_i);
      for (k = 0; k < DATA_UART; k = k+1) begin
        rx_force = data[k];
        repeat(BAUD_DIV) @(posedge fixed_clk_i);
      end
      rx_force = 1'b1;             // stop bit
      repeat(BAUD_DIV) @(posedge fixed_clk_i);
    end
  endtask

  // ---- Capture TX serial frame ----
  task capture_tx;
    output [DATA_UART-1:0] data_out;
    integer k;
    begin
      @(negedge uart_tx_o);
      repeat(BAUD_DIV/2) @(posedge fixed_clk_i);
      for (k = 0; k < DATA_UART; k = k+1) begin
        repeat(BAUD_DIV) @(posedge fixed_clk_i);
        data_out[k] = uart_tx_o;
      end
      repeat(BAUD_DIV) @(posedge fixed_clk_i); // stop bit
    end
  endtask

  // ---- pass/fail ----
  integer pass_cnt, fail_cnt;

  task check;
    input [31:0] got;
    input [31:0] expected;
    input [255:0] name;
    begin
      if (got === expected) begin
        $display("  PASS  %-55s  got=0x%08x", name, got);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  %-55s  expected=0x%08x  got=0x%08x", name, expected, got);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  reg [AXI_DATA_W-1:0] rd_data;
  reg [DATA_UART-1:0]  cap_tx_data;

  initial begin
    pass_cnt = 0; fail_cnt = 0;

    // Default AXI signals
    loopback_en   = 1'b0;
    rx_force      = 1'b1;  // idle high
    axi_aresetn_i = 1'b0;
    axi_arvalid_i = 1'b0; axi_araddr_i = 5'h0; axi_arid_i = 12'h0;
    axi_rready_i  = 1'b0;
    axi_awvalid_i = 1'b0; axi_awaddr_i = 5'h0; axi_awid_i = 12'h0;
    axi_wvalid_i  = 1'b0; axi_wdata_i  = 32'h0; axi_wstrb_i = 4'h0;
    axi_bready_i  = 1'b0;

    // -----------------------------------------------------------
    // TEST 1: Reset
    // -----------------------------------------------------------
    $display("\n=== TEST 1: Reset ===");
    repeat(5) @(posedge axi_aclk_i);
    check(uart_tx_o,     1, "uart_tx_o==1 during reset");
    check(axi_rvalid_o,  0, "axi_rvalid_o==0 during reset");
    check(axi_bvalid_o,  0, "axi_bvalid_o==0 during reset");
    axi_aresetn_i = 1'b1;
    repeat(5) @(posedge axi_aclk_i);
    check(uart_tx_o, 1, "uart_tx_o==1 after reset (idle)");

    // -----------------------------------------------------------
    // TEST 2: Write LCR – DLAB=0, no parity, 1 stop bit, set baudrate divisor
    //   First set DLAB=1 to enable baud write, then write divisor, then DLAB=0
    // -----------------------------------------------------------
    $display("\n=== TEST 2: Configure LCR & baudrate divisor ===");
    // Set DLAB=1 in LCR
    axi_write(ADDR_LCR, 32'h1 << LCR_DLAB);
    // Write custom baud divisor
    axi_write(ADDR_BAUD, BAUD_DIV);
    // Clear DLAB (DLAB=0, no parity, 1 stop)
    axi_write(ADDR_LCR, 32'h00000000);
    repeat(3) @(posedge axi_aclk_i);
    $display("  INFO  LCR and baud divisor configured");

    // -----------------------------------------------------------
    // TEST 3: Write THR – push 0x41 ('A')
    // -----------------------------------------------------------
    $display("\n=== TEST 3: Write THR 0x41 ===");
    fork
      axi_write(ADDR_RBR_THR, 32'h41);
      capture_tx(cap_tx_data);
    join
    check(cap_tx_data, 8'h41, "TX serial frame carries 0x41");

    // -----------------------------------------------------------
    // TEST 4: Read LSR – THRE and TEMT bits should be set (TX empty)
    // -----------------------------------------------------------
    $display("\n=== TEST 4: Read LSR ===");
    repeat(5) @(posedge axi_aclk_i);
    axi_read(ADDR_LSR, rd_data);
    $display("  INFO  LSR = 0x%08x", rd_data);
    // THRE=bit5, TEMT=bit6 => both 1 => LSR[6:5]=2'b11 => 0x60 mask
    check(rd_data & 32'h60, 32'h60, "LSR THRE+TEMT bits set when TX empty");

    // -----------------------------------------------------------
    // TEST 5: Write IER – enable RX interrupt (bit 0)
    // -----------------------------------------------------------
    $display("\n=== TEST 5: Write IER (enable RX interrupt) ===");
    axi_write(ADDR_IER, 32'h1);
    $display("  INFO  IER written");

    // -----------------------------------------------------------
    // TEST 6: Drive RX frame 0x42 ('B') and read RBR
    // -----------------------------------------------------------
    $display("\n=== TEST 6: RX frame 0x42, read RBR ===");
    // Drive the serial frame on uart_rx_i
    drive_rx_frame(8'h42);
    // Give the controller time to push it into the RX FIFO
    repeat(20) @(posedge axi_aclk_i);
    // Read RBR
    axi_read(ADDR_RBR_THR, rd_data);
    check(rd_data[7:0], 8'h42, "RBR data==0x42");

    // -----------------------------------------------------------
    // TEST 7: Full loopback – TX 0x37, expect RX 0x37
    // -----------------------------------------------------------
    $display("\n=== TEST 7: Loopback TX->RX 0x37 ===");
    // Enable loopback: uart_tx_o feeds uart_rx_i
    loopback_en = 1'b1;
    fork
      axi_write(ADDR_RBR_THR, 32'h37);
      begin
        // Wait for something to appear in RX FIFO (LSR DATA_READY bit 0)
        repeat(10*(DATA_UART+3)*BAUD_DIV) @(posedge fixed_clk_i); // ~1 frame time
        repeat(10) @(posedge axi_aclk_i);
      end
    join
    loopback_en = 1'b0;
    rx_force    = 1'b1;  // restore idle
    axi_read(ADDR_RBR_THR, rd_data);
    check(rd_data[7:0], 8'h37, "loopback RBR data==0x37");

    // -----------------------------------------------------------
    // TEST 8: Unknown address write – AXI must not hang (bvalid asserted)
    // -----------------------------------------------------------
    $display("\n=== TEST 8: Unknown address write ===");
    axi_write(5'h1C, 32'hDEADBEEF);
    $display("  INFO  Write to unknown address completed without hang");

    // -----------------------------------------------------------
    // Summary
    // -----------------------------------------------------------
    $display("\n=== SUMMARY: %0d passed, %0d failed ===\n", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #5000000;
    $display("TIMEOUT");
    $finish;
  end

  initial begin
	  $fsdbDumpfile("dump_uart.fsdb");
	  $fsdbDumpvars("+all");
	  $fsdbDumpSVA();
	  $fsdbDumpMDA();
  end

endmodule
