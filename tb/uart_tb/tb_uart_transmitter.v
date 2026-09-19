/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_uart_transmitter.v
 * Description : Testbench for uart_transmitter module.
 *
 * Strategy:
 *   - Use a small baud divisor (10) so simulation is fast.
 *   - A bit-capture task samples tx_o at the centre of each baud period.
 *   - Tests:
 *       1. Reset state: tx_o=1, busy=0, ready=0.
 *       2. No-parity, 1 stop bit  – 8-bit data 0x55.
 *       3. Even parity, 1 stop bit – 8-bit data 0xA5.
 *       4. Odd  parity, 1 stop bit – 8-bit data 0xA5.
 *       5. No-parity, 2 stop bits  – 8-bit data 0xFF.
 *       6. Enable gate: assert en_i=0 -> transmitter must not start.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_transmitter;

  localparam DATA_UART  = 8;
  localparam DIV_SIZE   = 16;
  localparam BAUD_DIV   = 16'd10;   // tiny divisor for fast simulation

  // ---- DUT ports ----
  reg                   clk_i;
  reg                   rstn_i;
  reg                   en_i;
  reg                   stop_bits_i;
  reg                   parity_bit_i;
  reg                   parity_bit_mode_i;
  reg  [DIV_SIZE-1:0]   baud_div_i;
  wire                  tx_o;
  reg  [DATA_UART-1:0]  tx_data_i;
  reg                   tx_send_i;
  wire                  tx_ready_o;
  wire                  busy_o;

  // ---- DUT instantiation ----
  uart_transmitter #(
    .DIV_SIZE  (DIV_SIZE),
    .DATA_UART (DATA_UART)
  ) dut (
    .clk_i             (clk_i),
    .rstn_i            (rstn_i),
    .en_i              (en_i),
    .stop_bits_i       (stop_bits_i),
    .parity_bit_i      (parity_bit_i),
    .parity_bit_mode_i (parity_bit_mode_i),
    .baud_div_i        (baud_div_i),
    .tx_o              (tx_o),
    .tx_data_i         (tx_data_i),
    .tx_send_i         (tx_send_i),
    .tx_ready_o        (tx_ready_o),
    .busy_o            (busy_o)
  );

  // ---- 100 MHz clock (period=10 ns) ----
  initial clk_i = 1'b0;
  always  #5 clk_i = ~clk_i;

  // ---- helper: wait half baud, then sample tx_o ----
  // The transmitter shifts one bit per baud_div_i clocks.
  task sample_bit;
    output bit_val;
    integer j;
    begin
      // Wait BAUD_DIV clocks (one bit period)
      repeat(BAUD_DIV) @(posedge clk_i);
      bit_val = tx_o;
    end
  endtask

  // ---- capture a full UART frame ----
  // Returns {stop[1:0], parity, data[7:0], start} – caller discards what's unused.
  task capture_frame;
    input  use_parity;
    input  two_stop;
    output [DATA_UART-1:0] data_out;
    output                 parity_out;
    output [1:0]           stop_out;
    reg                    bv;
    integer                k;
    begin
      // Wait for start bit (tx_o goes low)
      @(negedge tx_o);
      // Sample centre of start bit (half baud delay)
      repeat(BAUD_DIV/2) @(posedge clk_i);

      // Sample 8 data bits (LSB first)
      for (k = 0; k < DATA_UART; k = k+1) begin
        repeat(BAUD_DIV) @(posedge clk_i);
        data_out[k] = tx_o;
      end

      // Optional parity bit
      if (use_parity) begin
        repeat(BAUD_DIV) @(posedge clk_i);
        parity_out = tx_o;
      end else begin
        parity_out = 1'bx;
      end

      // Stop bit(s)
      repeat(BAUD_DIV) @(posedge clk_i);
      stop_out[0] = tx_o;
      if (two_stop) begin
        repeat(BAUD_DIV) @(posedge clk_i);
        stop_out[1] = tx_o;
      end else begin
        stop_out[1] = 1'bx;
      end
    end
  endtask

  // ---- send one byte ----
  task send_byte;
    input [DATA_UART-1:0] d;
    begin
      @(negedge clk_i);
      tx_data_i = d;
      tx_send_i = 1'b1;
      @(posedge clk_i); #1;
      tx_send_i = 1'b0;
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

  // ---- captured values ----
  reg [DATA_UART-1:0] cap_data;
  reg                 cap_parity;
  reg [1:0]           cap_stop;
  reg                 expected_parity;
  integer             ones_cnt;
  integer             k;

  initial begin
    pass_cnt = 0; fail_cnt = 0;
    rstn_i   = 1'b0; en_i = 1'b1;
    stop_bits_i  = 1'b0; parity_bit_i = 1'b0; parity_bit_mode_i = 1'b0;
    baud_div_i   = BAUD_DIV;
    tx_data_i    = 8'h00; tx_send_i = 1'b0;

    // -----------------------------------------------------------
    // TEST 1: Reset state
    // -----------------------------------------------------------
    $display("\n=== TEST 1: Reset state ===");
    repeat(3) @(posedge clk_i);
    check(tx_o,       1, "tx_o==1 during reset");
    rstn_i = 1'b1;
    @(posedge clk_i); #1;
    check(tx_o,       1, "tx_o==1 after reset in idle");
    check(busy_o,     0, "busy_o==0 after reset");
    check(tx_ready_o, 0, "tx_ready_o==0 after reset");

    // -----------------------------------------------------------
    // TEST 2: No parity, 1 stop bit – data 0x55
    // -----------------------------------------------------------
    $display("\n=== TEST 2: No parity, 1 stop bit, data=0x55 ===");
    stop_bits_i       = 1'b0;
    parity_bit_i      = 1'b0;
    parity_bit_mode_i = 1'b0;
    fork
      send_byte(8'h55);
      capture_frame(0, 0, cap_data, cap_parity, cap_stop);
    join
    check(cap_data,    8'h55, "received data==0x55");
    check(cap_stop[0], 1'b1,  "stop bit==1");
    // Wait for ready
    @(posedge tx_ready_o or posedge clk_i);
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 3: Even parity – data 0xA5 (4 ones -> even -> parity=0)
    // -----------------------------------------------------------
    $display("\n=== TEST 3: Even parity, 1 stop bit, data=0xA5 ===");
    stop_bits_i       = 1'b0;
    parity_bit_i      = 1'b1;
    parity_bit_mode_i = 1'b1; // even
    // Count ones in 0xA5 = 1010_0101 -> 4 ones -> even parity bit = 0
    expected_parity = 1'b0;
    fork
      send_byte(8'hA5);
      capture_frame(1, 0, cap_data, cap_parity, cap_stop);
    join
    check(cap_data,    8'hA5,            "received data==0xA5");
    check(cap_parity,  expected_parity,  "even parity bit correct");
    check(cap_stop[0], 1'b1,             "stop bit==1");
    @(posedge tx_ready_o or posedge clk_i);
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 4: Odd parity – data 0xA5 (4 ones -> odd parity bit = 1)
    // -----------------------------------------------------------
    $display("\n=== TEST 4: Odd parity, 1 stop bit, data=0xA5 ===");
    stop_bits_i       = 1'b0;
    parity_bit_i      = 1'b1;
    parity_bit_mode_i = 1'b0; // odd
    expected_parity   = 1'b1; // 4 ones, need 1 extra to make total odd
    fork
      send_byte(8'hA5);
      capture_frame(1, 0, cap_data, cap_parity, cap_stop);
    join
    check(cap_data,   8'hA5,           "received data==0xA5");
    check(cap_parity, expected_parity, "odd parity bit correct");
    @(posedge tx_ready_o or posedge clk_i);
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 5: No parity, 2 stop bits – data 0xFF
    // -----------------------------------------------------------
    $display("\n=== TEST 5: No parity, 2 stop bits, data=0xFF ===");
    stop_bits_i       = 1'b1;
    parity_bit_i      = 1'b0;
    parity_bit_mode_i = 1'b0;
    fork
      send_byte(8'hFF);
      capture_frame(0, 1, cap_data, cap_parity, cap_stop);
    join
    check(cap_data,    8'hFF, "received data==0xFF");
    check(cap_stop[0], 1'b1,  "stop bit 1 == 1");
    check(cap_stop[1], 1'b1,  "stop bit 2 == 1");
    @(posedge tx_ready_o or posedge clk_i);
    repeat(3) @(posedge clk_i);

    // -----------------------------------------------------------
    // TEST 6: en_i=0 -> transmitter should not start
    // -----------------------------------------------------------
    $display("\n=== TEST 6: en_i=0 suppresses transmission ===");
    stop_bits_i  = 1'b0; parity_bit_i = 1'b0;
    en_i = 1'b0;
    @(negedge clk_i); tx_data_i = 8'hAA; tx_send_i = 1'b1;
    @(posedge clk_i); #1; tx_send_i = 1'b0;
    repeat(5) @(posedge clk_i); #1;
    check(busy_o, 0, "busy_o==0 when en_i=0");
    check(tx_o,   1, "tx_o==1 (idle) when en_i=0");
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
