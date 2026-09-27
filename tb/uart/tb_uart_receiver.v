/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_uart_receiver.v
 * Description : Testbench for uart_receiver module.
 *
 * Strategy:
 *   Drives a bit-accurate UART serial stream into rx_i using a small
 *   baud divisor so simulation stays fast.  After each frame the
 *   testbench waits for rx_valid_o and checks rx_data_o.
 *
 * Tests:
 *   1. Reset state: rx_valid_o=0.
 *   2. 8N1 frame – data 0x55.
 *   3. 8N1 frame – data 0xA3.
 *   4. 8E1 (even parity) – data 0x49 (3 ones -> parity=1 for even).
 *   5. 8O1 (odd  parity) – data 0x49 (3 ones -> parity=0 for odd).
 *   6. 8N2 (two stop bits) – data 0xFF.
 *   7. en_i=0 gate: receiver must ignore incoming frame.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_receiver;

  localparam DATA_UART  = 8;
  localparam DIV_SIZE   = 16;
  localparam BAUD_DIV   = 16'd20;   // small divisor for fast simulation

  // ---- DUT ports ----
  reg                   clk_i;
  reg                   rstn_i;
  reg                   en_i;
  reg                   stop_bits_i;
  reg                   parity_bit_i;
  reg  [DIV_SIZE-1:0]   baud_div_i;
  reg                   rx_i;
  wire [DATA_UART-1:0]  rx_data_o;
  wire                  rx_valid_o;

  // ---- DUT instantiation ----
  uart_receiver #(
    .DIV_SIZE   (DIV_SIZE),
    .DATA_UART  (DATA_UART)
  ) dut (
    .clk_i        (clk_i),
    .rstn_i       (rstn_i),
    .en_i         (en_i),
    .stop_bits_i  (stop_bits_i),
    .parity_bit_i (parity_bit_i),
    .baud_div_i   (baud_div_i),
    .rx_i         (rx_i),
    .rx_data_o    (rx_data_o),
    .rx_valid_o   (rx_valid_o)
  );

  // ---- 100 MHz clock ----
  initial clk_i = 1'b0;
  always  #5 clk_i = ~clk_i;

  // ---- drive one bit for BAUD_DIV clocks ----
  task drive_bit;
    input bit_val;
    integer j;
    begin
      rx_i = bit_val;
      repeat(BAUD_DIV) @(posedge clk_i);
    end
  endtask

  // ---- drive a full UART frame ----
  task drive_frame;
    input [DATA_UART-1:0] data;
    input                 use_parity;
    input                 parity_mode; // 0=odd, 1=even
    input                 two_stop;
    integer               k;
    integer               ones;
    reg                   pbit;
    begin
      // Compute parity
      ones = 0;
      for (k = 0; k < DATA_UART; k = k+1)
        if (data[k]) ones = ones + 1;
      if (parity_mode == 1) // even: make total count even
        pbit = (ones % 2 == 0) ? 1'b0 : 1'b1;
      else                  // odd: make total count odd
        pbit = (ones % 2 != 0) ? 1'b0 : 1'b1;

      // Start bit
      drive_bit(1'b0);
      // Data bits (LSB first)
      for (k = 0; k < DATA_UART; k = k+1)
        drive_bit(data[k]);
      // Parity
      if (use_parity)
        drive_bit(pbit);
      // Stop bit(s)
      drive_bit(1'b1);
      if (two_stop)
        drive_bit(1'b1);
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
        $display("  PASS  %-50s  got=0x%02x", name, got);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  %-50s  expected=0x%02x  got=0x%02x", name, expected, got);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  // ---- wait for valid with timeout ----
  task wait_valid;
    input [31:0] timeout_cycles;
    integer cnt;
    begin
      cnt = 0;
      while (!rx_valid_o && cnt < timeout_cycles) begin
        @(posedge clk_i); #1;
        cnt = cnt + 1;
      end
      if (cnt >= timeout_cycles)
        $display("  WARN  wait_valid timed out after %0d cycles", timeout_cycles);
    end
  endtask

  initial begin
    pass_cnt = 0; fail_cnt = 0;
    rstn_i   = 1'b0; en_i = 1'b1;
    stop_bits_i  = 1'b0; parity_bit_i = 1'b0;
    baud_div_i   = BAUD_DIV;
    rx_i         = 1'b1;  // idle high

    // -----------------------------------------------------------
    // TEST 1: Reset state
    // -----------------------------------------------------------
    $display("\n=== TEST 1: Reset state ===");
    repeat(3) @(posedge clk_i);
    check(rx_valid_o, 0, "rx_valid_o==0 during reset");
    rstn_i = 1'b1;
    @(posedge clk_i); #1;
    check(rx_valid_o, 0, "rx_valid_o==0 after reset in idle");

    // -----------------------------------------------------------
    // TEST 2: 8N1, data=0x55
    // -----------------------------------------------------------
    $display("\n=== TEST 2: 8N1, data=0x55 ===");
    stop_bits_i  = 1'b0; parity_bit_i = 1'b0;
    drive_frame(8'h55, 0, 0, 0);
    wait_valid(200);
    check(rx_valid_o, 1,    "rx_valid_o==1");
    check(rx_data_o,  8'h55, "rx_data_o==0x55");
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 3: 8N1, data=0xA3
    // -----------------------------------------------------------
    $display("\n=== TEST 3: 8N1, data=0xA3 ===");
    drive_frame(8'hA3, 0, 0, 0);
    wait_valid(200);
    check(rx_valid_o, 1,    "rx_valid_o==1");
    check(rx_data_o,  8'hA3, "rx_data_o==0xA3");
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 4: 8E1 (even parity), data=0x49
    //         0x49 = 0100_1001 -> 3 ones -> even parity=1
    // -----------------------------------------------------------
    $display("\n=== TEST 4: 8E1, data=0x49 ===");
    stop_bits_i  = 1'b0; parity_bit_i = 1'b1;
    drive_frame(8'h49, 1, 1, 0);  // parity_mode=1=even
    wait_valid(200);
    check(rx_valid_o, 1,    "rx_valid_o==1 (8E1)");
    check(rx_data_o,  8'h49, "rx_data_o==0x49 (8E1)");
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 5: 8O1 (odd parity), data=0x49 (3 ones -> parity=0)
    // -----------------------------------------------------------
    $display("\n=== TEST 5: 8O1, data=0x49 ===");
    stop_bits_i  = 1'b0; parity_bit_i = 1'b1;
    drive_frame(8'h49, 1, 0, 0);  // parity_mode=0=odd
    wait_valid(200);
    check(rx_valid_o, 1,    "rx_valid_o==1 (8O1)");
    check(rx_data_o,  8'h49, "rx_data_o==0x49 (8O1)");
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 6: 8N2 (two stop bits), data=0xFF
    // -----------------------------------------------------------
    $display("\n=== TEST 6: 8N2, data=0xFF ===");
    stop_bits_i  = 1'b1; parity_bit_i = 1'b0;
    drive_frame(8'hFF, 0, 0, 1);
    wait_valid(300);
    check(rx_valid_o, 1,    "rx_valid_o==1 (8N2)");
    check(rx_data_o,  8'hFF, "rx_data_o==0xFF (8N2)");
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 7: en_i=0 – frame must be ignored
    // -----------------------------------------------------------
    $display("\n=== TEST 7: en_i=0 suppresses reception ===");
    stop_bits_i  = 1'b0; parity_bit_i = 1'b0;
    en_i = 1'b0;
    drive_frame(8'hAA, 0, 0, 0);
    // Give a few extra cycles for any erroneous valid
    repeat(10) @(posedge clk_i); #1;
    check(rx_valid_o, 0, "rx_valid_o==0 when en_i=0");
    en_i = 1'b1;

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
    #500000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
