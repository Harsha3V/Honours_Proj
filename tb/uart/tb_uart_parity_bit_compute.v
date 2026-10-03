/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_uart_parity_bit_compute.v
 * Description : Testbench for uart_parity_bit_compute module.
 *
 * Tests:
 *  1. Reset behaviour: parity_bit_o must settle to known state after reset.
 *  2. Odd parity  (mode_i=0): verify bit toggles correctly on each '1' input.
 *  3. Even parity (mode_i=1): verify bit toggles correctly on each '1' input.
 *  4. Soft reset  (rst_i)   : mid-stream soft reset clears the counter.
 *  5. Ignore '0' input data : counter must not change on data_i=0 with valid_i=1.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_parity_bit_compute;

  // ---- DUT ports ----
  reg  clk_i;
  reg  arstn_i;
  reg  rst_i;
  reg  data_i;
  reg  valid_i;
  reg  mode_i;
  wire parity_bit_o;

  // ---- DUT instantiation ----
  uart_parity_bit_compute dut (
    .clk_i       (clk_i),
    .arstn_i     (arstn_i),
    .rst_i       (rst_i),
    .data_i      (data_i),
    .valid_i     (valid_i),
    .mode_i      (mode_i),
    .parity_bit_o(parity_bit_o)
  );

  // ---- 100 MHz clock ----
  initial clk_i = 1'b0;
  always  #5 clk_i = ~clk_i;

  // ---- helper: send one valid bit ----
  task send_bit;
    input bit_val;
    begin
      @(negedge clk_i);
      data_i  = bit_val;
      valid_i = 1'b1;
      @(posedge clk_i); #1;
      valid_i = 1'b0;
      data_i  = 1'b0;
    end
  endtask

  // ---- pass/fail counter ----
  integer pass_cnt, fail_cnt;

  task check;
    input expected;
    input [127:0] test_name;
    begin
      if (parity_bit_o === expected) begin
        $display("  PASS  %-40s  parity_bit_o=%b", test_name, parity_bit_o);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  %-40s  expected=%b  got=%b", test_name, expected, parity_bit_o);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  // ---- stimulus ----
  integer i;
  initial begin
    pass_cnt = 0; fail_cnt = 0;

    // Default inputs
    arstn_i = 1'b0; rst_i = 1'b0;
    data_i  = 1'b0; valid_i = 1'b0; mode_i = 1'b0;

    // ----------------------------------------------------------------
    // TEST 1: Async reset
    // ----------------------------------------------------------------
    $display("\n=== TEST 1: Async reset ===");
    repeat(3) @(posedge clk_i);
    arstn_i = 1'b1;
    @(posedge clk_i); #1;
    // counter_int=0 -> odd parity (mode=0) -> ~0 = 1
    check(1'b1, "odd parity after reset");

    // ----------------------------------------------------------------
    // TEST 2: Odd parity (mode_i=0)
    // ----------------------------------------------------------------
    $display("\n=== TEST 2: Odd parity (mode_i=0) ===");
    mode_i = 1'b0;
    // Send one '1' bit -> counter_int becomes 1 -> ~1 = 0
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b0, "odd: 1 one seen -> parity=0");

    // Send another '1' -> counter_int back to 0 -> ~0 = 1
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b1, "odd: 2 ones seen -> parity=1");

    // Send a '0' bit (should NOT change counter)
    send_bit(1'b0);
    @(posedge clk_i); #1;
    check(1'b1, "odd: '0' bit ignored -> parity unchanged");

    // Send '1' three more times (total 5 ones = odd -> parity=0)
    for (i = 0; i < 3; i = i+1)
      send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b0, "odd: 5 ones seen -> parity=0");

    // ----------------------------------------------------------------
    // TEST 3: Even parity (mode_i=1)
    // ----------------------------------------------------------------
    $display("\n=== TEST 3: Even parity (mode_i=1) ===");
    // Soft reset to clear counter before switching mode
    @(negedge clk_i);
    rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    mode_i = 1'b1;
    @(posedge clk_i); #1;
    // counter_int=0, mode=1 -> parity = 0
    check(1'b0, "even parity after soft reset");

    // Send one '1' -> counter_int=1 -> even parity = 1
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b1, "even: 1 one seen -> parity=1");

    // Send another '1' -> counter_int=0 -> even parity = 0
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b0, "even: 2 ones seen -> parity=0");

    // ----------------------------------------------------------------
    // TEST 4: Soft reset mid-stream
    // ----------------------------------------------------------------
    $display("\n=== TEST 4: Soft reset mid-stream ===");
    // State currently: counter_int=0, mode=1 -> parity=0
    send_bit(1'b1); // counter=1, parity=1
    @(posedge clk_i); #1;
    check(1'b1, "even before soft reset");

    @(negedge clk_i);
    rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    @(posedge clk_i); #1;
    // counter_int reset to 0, mode=1 -> parity = 0
    check(1'b0, "even: soft reset clears counter");

    // ----------------------------------------------------------------
    // TEST 5: valid_i=0 must not update counter
    // ----------------------------------------------------------------
    $display("\n=== TEST 5: valid_i=0 suppresses counter update ===");
    // Soft reset first
    @(negedge clk_i); rst_i=1'b1;
    @(posedge clk_i); #1; rst_i=1'b0;
    mode_i = 1'b0; // odd parity
    @(posedge clk_i); #1;
    // Send data_i=1 but valid_i=0
    @(negedge clk_i);
    data_i=1'b1; valid_i=1'b0;
    @(posedge clk_i); #1;
    data_i=1'b0;
    // counter must still be 0 -> odd parity = 1
    check(1'b1, "no change when valid_i=0 with data_i=1");

    // ----------------------------------------------------------------
    // Summary
    // ----------------------------------------------------------------
    $display("\n=== SUMMARY: %0d passed, %0d failed ===\n", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #50000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
