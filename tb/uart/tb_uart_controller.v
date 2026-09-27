/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_uart_controller.v
 * Description : Testbench for uart_controller module.
 *
 * The uart_controller wraps uart_transmitter + uart_receiver and owns
 * the "load from TX FIFO" FSM.
 *
 * Tests:
 *   1. Reset: tx_pull_o=0, uart_tx_o=1.
 *   2. TX path: assert tx_load_i + tx_data_i, verify tx_pull_o pulse and
 *      the resulting serial stream on uart_tx_o.
 *   3. RX path: drive a serial frame on uart_rx_i, verify rx_data_o and
 *      rx_push_o pulse.
 *   4. Loopback: connect uart_tx_o -> uart_rx_i; write a byte and check
 *      the controller echoes it back via rx_push_o / rx_data_o.
 *   5. Back-to-back TX: two bytes in a row without a gap.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_controller;

  localparam DATA_UART  = 8;
  localparam DATA_SIZE  = 32;
  localparam DIV_SIZE   = 16;
  localparam BAUD_DIV   = 16'd20;  // small for fast simulation

  // ---- DUT ports ----
  reg                    clk_i;
  reg                    rstn_i;
  reg                    uart_en_i;
  reg                    uart_stop_bits_i;
  reg                    uart_parity_bit_i;
  reg                    uart_parity_bit_mode_i;
  reg  [DIV_SIZE-1:0]    uart_baudrate_div_i;
  reg                    uart_rx_i;
  wire                   uart_tx_o;
  wire [DATA_UART-1:0]   rx_data_o;
  wire                   rx_push_o;
  reg                    tx_load_i;
  reg  [DATA_UART-1:0]   tx_data_i;
  wire                   tx_pull_o;

  // ---- DUT instantiation ----
  uart_controller #(
    .DATA_UART (DATA_UART),
    .DATA_SIZE (DATA_SIZE),
    .DIV_SIZE  (DIV_SIZE)
  ) dut (
    .clk_i                  (clk_i),
    .rstn_i                 (rstn_i),
    .uart_en_i              (uart_en_i),
    .uart_stop_bits_i       (uart_stop_bits_i),
    .uart_parity_bit_i      (uart_parity_bit_i),
    .uart_parity_bit_mode_i (uart_parity_bit_mode_i),
    .uart_baudrate_div_i    (uart_baudrate_div_i),
    .uart_rx_i              (uart_rx_i),
    .uart_tx_o              (uart_tx_o),
    .rx_data_o              (rx_data_o),
    .rx_push_o              (rx_push_o),
    .tx_load_i              (tx_load_i),
    .tx_data_i              (tx_data_i),
    .tx_pull_o              (tx_pull_o)
  );

  // ---- 100 MHz clock ----
  initial clk_i = 1'b0;
  always  #5 clk_i = ~clk_i;

  // ---- Drive a serial UART frame onto uart_rx_i ----
  task drive_rx_frame;
    input [DATA_UART-1:0] data;
    integer k;
    begin
      // start bit
      uart_rx_i = 1'b0;
      repeat(BAUD_DIV) @(posedge clk_i);
      // data bits LSB first
      for (k = 0; k < DATA_UART; k = k+1) begin
        uart_rx_i = data[k];
        repeat(BAUD_DIV) @(posedge clk_i);
      end
      // stop bit
      uart_rx_i = 1'b1;
      repeat(BAUD_DIV) @(posedge clk_i);
    end
  endtask

  // ---- Capture TX serial stream ----
  task capture_tx_frame;
    output [DATA_UART-1:0] data_out;
    integer k;
    begin
      // wait for start bit
      @(negedge uart_tx_o);
      // skip to centre of start bit
      repeat(BAUD_DIV/2) @(posedge clk_i);
      // sample data bits
      for (k = 0; k < DATA_UART; k = k+1) begin
        repeat(BAUD_DIV) @(posedge clk_i);
        data_out[k] = uart_tx_o;
      end
      // consume stop bit
      repeat(BAUD_DIV) @(posedge clk_i);
    end
  endtask

  // ---- wait for signal with timeout ----
  task wait_sig;
    input sig;          // not synthesisable, used for value only
    input [31:0] tout;
    // not needed as a generic; use inline @(posedge ...) in tests
    begin end
  endtask

  // ---- pass/fail ----
  integer pass_cnt, fail_cnt;

  task check;
    input [31:0] got;
    input [31:0] expected;
    input [255:0] name;
    begin
      if (got === expected) begin
        $display("  PASS  %-50s  got=0x%02x", name, got);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  %-50s  expected=0x%02x  got=0x%02x", name, expected, got);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  // ---- captured data ----
  reg [DATA_UART-1:0] cap_tx;
  integer             pull_detected;
  integer             push_detected;
  integer             i;

  initial begin
    pass_cnt = 0; fail_cnt = 0;
    rstn_i                  = 1'b0;
    uart_en_i               = 1'b1;
    uart_stop_bits_i        = 1'b0;
    uart_parity_bit_i       = 1'b0;
    uart_parity_bit_mode_i  = 1'b0;
    uart_baudrate_div_i     = BAUD_DIV;
    uart_rx_i               = 1'b1;
    tx_load_i               = 1'b0;
    tx_data_i               = 8'h00;

    // -----------------------------------------------------------
    // TEST 1: Reset state
    // -----------------------------------------------------------
    $display("\n=== TEST 1: Reset state ===");
    repeat(4) @(posedge clk_i);
    check(uart_tx_o, 1, "uart_tx_o==1 during reset");
    check(tx_pull_o, 0, "tx_pull_o==0 during reset");
    rstn_i = 1'b1;
    @(posedge clk_i); #1;
    check(tx_pull_o, 0, "tx_pull_o==0 after reset");

    // -----------------------------------------------------------
    // TEST 2: TX path – transmit 0x5A, observe tx_pull_o and serial data
    // -----------------------------------------------------------
    $display("\n=== TEST 2: TX path, data=0x5A ===");
    pull_detected = 0;
    fork
      begin // load trigger
        @(negedge clk_i);
        tx_data_i = 8'h5A; tx_load_i = 1'b1;
        @(posedge clk_i); #1;
        tx_load_i = 1'b0;
      end
      begin // watch tx_pull_o
        @(posedge tx_pull_o);
        pull_detected = 1;
      end
      begin // capture serial frame
        capture_tx_frame(cap_tx);
      end
    join
    check(pull_detected, 1,     "tx_pull_o pulsed");
    check(cap_tx,        8'h5A, "TX serial data==0x5A");
    repeat(5) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 3: RX path – drive 0xC3 on uart_rx_i
    // -----------------------------------------------------------
    $display("\n=== TEST 3: RX path, data=0xC3 ===");
    push_detected = 0;
    fork
      drive_rx_frame(8'hC3);
      begin
        @(posedge rx_push_o);
        push_detected = 1;
      end
    join
    @(posedge clk_i); #1;
    check(push_detected, 1,     "rx_push_o pulsed");
    check(rx_data_o,     8'hC3, "RX data==0xC3");
    repeat(5) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 4: Loopback – TX out -> RX in
    // -----------------------------------------------------------
    $display("\n=== TEST 4: Loopback TX->RX, data=0x37 ===");
    push_detected = 0;
    // Connect loopback
    // (uart_tx_o drives uart_rx_i via continuous assign below)
    fork
      begin
        @(negedge clk_i);
        tx_data_i = 8'h37; tx_load_i = 1'b1;
        @(posedge clk_i); #1; tx_load_i = 1'b0;
      end
      begin
        @(posedge rx_push_o);
        push_detected = 1;
      end
    join
    @(posedge clk_i); #1;
    check(push_detected, 1,     "loopback rx_push_o pulsed");
    check(rx_data_o,     8'h37, "loopback rx_data_o==0x37");
    repeat(5) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 5: Back-to-back TX – 0xAA then 0x55
    // -----------------------------------------------------------
    $display("\n=== TEST 5: Back-to-back TX ===");
    fork
      begin
        // First byte
        @(negedge clk_i); tx_data_i=8'hAA; tx_load_i=1'b1;
        @(posedge clk_i); #1; tx_load_i=1'b0;
        // Wait for pull (FSM back to idle), then immediately load second byte
        @(posedge tx_pull_o);
        @(negedge clk_i); tx_data_i=8'h55; tx_load_i=1'b1;
        @(posedge clk_i); #1; tx_load_i=1'b0;
      end
      begin
        capture_tx_frame(cap_tx);
        check(cap_tx, 8'hAA, "back-to-back: first frame==0xAA");
        capture_tx_frame(cap_tx);
        check(cap_tx, 8'h55, "back-to-back: second frame==0x55");
      end
    join
    repeat(5) @(posedge clk_i);

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

  // Loopback connection for TEST 4
  assign #1 uart_rx_i = uart_tx_o;  // Note: this overrides task driving after TEST 3

  // Timeout watchdog
  initial begin
    #2000000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
