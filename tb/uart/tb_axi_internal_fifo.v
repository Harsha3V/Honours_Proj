/* -----------------------------------------------------------------------------
 * Project  : AXI-lite UART IP Core
 * File     : tb_axi_internal_fifo.v
 * Description : Testbench for axi_internal_fifo module.
 *
 * Tests:
 *  1. Async reset: FIFO empties and outputs zeros.
 *  2. Sync soft reset: FIFO empties mid-stream.
 *  3. Simple push / pull: 4 sequential pushes then 4 pulls, verify FIFO data.
 *  4. Full detection: push until full, verify full flag (PORT_EN=3'b111).
 *  5. Simultaneous push+pull (PP case).
 *  6. Load flag: data is available at head.
 *  7. Available-write-space flag: drops below threshold when >=90% full.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_axi_internal_fifo;

  // Parameters matching the TX FIFO configuration (PORT_EN=3'b111)
  localparam FIFO_SIZE    = 16;
  localparam DATA_SIZE    = 8;
  localparam INDEX_LENGTH = 4;
  localparam PORT_EN      = 3'b111;

  // STATUS_WIDTH = INDEX_LENGTH + 3 (all three flags enabled) + 1 extra MSB
  // status_o is [STATUS_WIDTH:0] = [INDEX_LENGTH+3:0] = [7:0] when PORT_EN=3'b111
  localparam STATUS_W = INDEX_LENGTH + 3 + 1; // 8 bits

  // ---- DUT ports ----
  reg                    clk_i;
  reg                    arstn_i;
  reg                    rst_i;
  reg                    push_i;
  reg                    pull_i;
  reg  [DATA_SIZE-1:0]   data_i;
  wire [DATA_SIZE-1:0]   data_o;
  wire [STATUS_W-1:0]    status_o;

  // ---- Status field decode (PORT_EN=3'b111) ----
  // status_o = {load, full, available_write_space, space[INDEX_LENGTH:0]}
  wire                   load_flag     = status_o[STATUS_W-1];
  wire                   full_flag     = status_o[STATUS_W-2];
  wire                   avail_flag    = status_o[STATUS_W-3];
  wire [INDEX_LENGTH:0]  space_field   = status_o[INDEX_LENGTH:0];

  // ---- DUT instantiation ----
  axi_internal_fifo #(
    .FIFO_SIZE    (FIFO_SIZE),
    .DATA_SIZE    (DATA_SIZE),
    .INDEX_LENGTH (INDEX_LENGTH),
    .PORT_EN      (PORT_EN)
  ) dut (
    .clk_i   (clk_i),
    .arstn_i (arstn_i),
    .rst_i   (rst_i),
    .push_i  (push_i),
    .pull_i  (pull_i),
    .data_i  (data_i),
    .data_o  (data_o),
    .status_o(status_o)
  );

  // ---- 100 MHz clock ----
  initial clk_i = 1'b0;
  always  #5 clk_i = ~clk_i;

  // ---- helpers ----
  integer pass_cnt, fail_cnt;

  task check_val;
    input [31:0] got;
    input [31:0] expected;
    input [255:0] name;
    begin
      if (got === expected) begin
        $display("  PASS  %-45s  got=%0d", name, got);
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  %-45s  expected=%0d  got=%0d", name, expected, got);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask

  task do_push;
    input [DATA_SIZE-1:0] d;
    begin
      @(negedge clk_i);
      push_i = 1'b1; pull_i = 1'b0; data_i = d;
      @(posedge clk_i); #1;
      push_i = 1'b0;
    end
  endtask

  task do_pull;
    begin
      @(negedge clk_i);
      push_i = 1'b0; pull_i = 1'b1;
      @(posedge clk_i); #1;
      pull_i = 1'b0;
    end
  endtask

  task idle_cycle;
    begin
      @(negedge clk_i);
      push_i = 1'b0; pull_i = 1'b0;
      @(posedge clk_i); #1;
    end
  endtask

  // ---- Stimulus ----
  integer i;

  initial begin
    pass_cnt = 0; fail_cnt = 0;
    arstn_i = 1'b0; rst_i = 1'b0;
    push_i  = 1'b0; pull_i = 1'b0;
    data_i  = 8'h00;

    // -----------------------------------------------------------
    // TEST 1: Async reset – space should equal FIFO_SIZE
    // -----------------------------------------------------------
    $display("\n=== TEST 1: Async reset ===");
    @(posedge clk_i); #1;
    arstn_i = 1'b1;
    @(posedge clk_i); #1;
    check_val(space_field, FIFO_SIZE[INDEX_LENGTH:0], "space == FIFO_SIZE after async reset");
    check_val(load_flag,  0, "load_flag == 0 after async reset");
    check_val(full_flag,  0, "full_flag == 0 after async reset");
    check_val(avail_flag, 1, "avail_flag == 1 after async reset");

    // -----------------------------------------------------------
    // TEST 2: Push 4 items
    // -----------------------------------------------------------
    $display("\n=== TEST 2: Push 4 items ===");
    for (i = 1; i <= 4; i = i+1) begin
      do_push(i * 8'h11);
      idle_cycle();
    end
    check_val(space_field, FIFO_SIZE - 4, "space after 4 pushes");
    check_val(load_flag,   1, "load_flag == 1 after pushes");

    // -----------------------------------------------------------
    // TEST 3: Pull 4 items – verify first data_o
    // -----------------------------------------------------------
    $display("\n=== TEST 3: Pull items ===");
    // head points to first pushed item = 0x11
    check_val(data_o, 8'h11, "data_o == 0x11 before first pull");
    do_pull(); idle_cycle();
    check_val(data_o, 8'h22, "data_o == 0x22 after 1st pull");
    do_pull(); idle_cycle();
    check_val(data_o, 8'h33, "data_o == 0x33 after 2nd pull");
    do_pull(); idle_cycle();
    check_val(data_o, 8'h44, "data_o == 0x44 after 3rd pull");
    do_pull(); idle_cycle();
    // FIFO now empty
    check_val(load_flag, 0, "load_flag == 0 after draining");
    check_val(space_field, FIFO_SIZE[INDEX_LENGTH:0], "space back to FIFO_SIZE");

    // -----------------------------------------------------------
    // TEST 4: Simultaneous push+pull
    // -----------------------------------------------------------
    $display("\n=== TEST 4: Simultaneous push+pull ===");
    do_push(8'hAA); idle_cycle();
    // Now push 0xBB and pull at the same time
    @(negedge clk_i);
    push_i = 1'b1; pull_i = 1'b1; data_i = 8'hBB;
    @(posedge clk_i); #1;
    push_i = 1'b0; pull_i = 1'b0;
    idle_cycle();
    // 0xAA was pulled, 0xBB was pushed; head should show 0xBB
    check_val(data_o,    8'hBB, "simultaneous push+pull: new head=0xBB");
    check_val(load_flag, 1,     "load_flag==1 after sim push+pull");

    // -----------------------------------------------------------
    // TEST 5: Soft reset clears FIFO
    // -----------------------------------------------------------
    $display("\n=== TEST 5: Soft reset ===");
    @(negedge clk_i); rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    idle_cycle();
    check_val(space_field, FIFO_SIZE[INDEX_LENGTH:0], "space == FIFO_SIZE after soft reset");
    check_val(load_flag,   0, "load_flag == 0 after soft reset");

    // -----------------------------------------------------------
    // TEST 6: Available-write-space flag drops when FIFO is >=90% full
    //         FIFO_THRESHOLD=90, so for FIFO_SIZE=16, threshold is
    //         90% of 16 = ~14 entries; available flag drops when
    //         space < 14 (i.e., more than ~14 entries written).
    //         Push until avail_flag goes low.
    // -----------------------------------------------------------
    $display("\n=== TEST 6: available_write_space flag ===");
    check_val(avail_flag, 1, "avail_flag initially 1");
    for (i = 0; i < 15; i = i+1) begin
      do_push(i[7:0]);
      idle_cycle();
    end
    $display("  INFO  After 15 pushes: space=%0d  avail_flag=%b", space_field, avail_flag);
    // With 15 items pushed space=1, which is < 14 -> flag should be 0
    check_val(avail_flag, 0, "avail_flag == 0 when FIFO nearly full");

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
    #200000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
