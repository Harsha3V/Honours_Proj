/* =============================================================================
 * Project  : Honours Project — AES-128 ECU Gateway SoC
 * File     : tb/timer/tb_EF_TCC32_axi.v
 * DUT      : EF_TCC32_axi (AXI4-Lite wrapper for EF_TCC32 32-bit timer)
 *
 * Test cases:
 *   TC1 — Reset check:         TIMER_REG readable, CONTROL_REG=0 after reset
 *   TC2 — PERIOD write/read:   write 0x000000FF, read back, verify
 *   TC3 — CONTROL write/read:  write EN+TMR_EN (bits[1:0]=2'b11), read back
 *   TC4 — Timer counts down:   enable timer, poll TIMER_REG, verify it decrements
 *   TC5 — Timeout interrupt:   enable IM[0], wait for timer_irq assert
 *   TC6 — ICR clears RIS:      write ICR[0]=1, verify RIS[0] clears
 *   TC7 — One-shot mode:       set ONE_SHOT, verify timer stops after one period
 *   TC8 — Unknown addr:        read unknown offset → 0xDEADBEEF, no hang
 * =============================================================================*/

`timescale 1ns/1ps

module tb_EF_TCC32_axi;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
localparam CLK_PERIOD     = 10;   // 100 MHz
localparam AXI_ADDR_WIDTH = 32;
localparam AXI_DATA_WIDTH = 32;
localparam AXI_ID_WIDTH   = 8;
localparam AXI_STRB_WIDTH = 4;

// Register offsets (match EF_TCC32_axi.v)
localparam TIMER_ADDR   = 32'h0000;
localparam PERIOD_ADDR  = 32'h0004;
localparam COUNTER_ADDR = 32'h0008;
localparam CMATCH_ADDR  = 32'h000C;
localparam CTRL_ADDR    = 32'h0010;
localparam ICR_ADDR     = 32'h0F00;
localparam RIS_ADDR     = 32'h0F04;
localparam IM_ADDR      = 32'h0F08;
localparam MIS_ADDR     = 32'h0F0C;
localparam BAD_ADDR     = 32'hABCD;

// CONTROL_REG bit masks
localparam CTRL_EN      = 32'h0000_0001;  // bit0
localparam CTRL_TMR_EN  = 32'h0000_0002;  // bit1
localparam CTRL_ONE_SHOT= 32'h0002_0002;  // bit17+bit1
localparam CTRL_CLK_SRC8= 32'h0000_0102; // bits[11:8]=8 (clk, no prescaler) + TMR_EN

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg  clk, rstn;
reg  ctr_in;
wire timer_irq;

// AXI write
reg  [AXI_ID_WIDTH-1:0]   s_axi_awid;
reg  [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
reg                        s_axi_awvalid;
wire                       s_axi_awready;

reg  [AXI_DATA_WIDTH-1:0] s_axi_wdata;
reg  [AXI_STRB_WIDTH-1:0] s_axi_wstrb;
reg                        s_axi_wvalid;
wire                       s_axi_wready;

wire [AXI_ID_WIDTH-1:0]   s_axi_bid;
wire [1:0]                 s_axi_bresp;
wire                       s_axi_bvalid;
reg                        s_axi_bready;

// AXI read
reg  [AXI_ID_WIDTH-1:0]   s_axi_arid;
reg  [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
reg                        s_axi_arvalid;
wire                       s_axi_arready;

wire [AXI_ID_WIDTH-1:0]   s_axi_rid;
wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
wire [1:0]                 s_axi_rresp;
wire                       s_axi_rvalid;
reg                        s_axi_rready;

// ---------------------------------------------------------------------------
// DUT instantiation
// ---------------------------------------------------------------------------
EF_TCC32_axi #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_ID_WIDTH)
) dut (
    .clk            (clk),
    .rstn           (rstn),

    .s_axi_awid     (s_axi_awid),
    .s_axi_awaddr   (s_axi_awaddr),
    .s_axi_awvalid  (s_axi_awvalid),
    .s_axi_awready  (s_axi_awready),

    .s_axi_wdata    (s_axi_wdata),
    .s_axi_wstrb    (s_axi_wstrb),
    .s_axi_wvalid   (s_axi_wvalid),
    .s_axi_wready   (s_axi_wready),

    .s_axi_bid      (s_axi_bid),
    .s_axi_bresp    (s_axi_bresp),
    .s_axi_bvalid   (s_axi_bvalid),
    .s_axi_bready   (s_axi_bready),

    .s_axi_arid     (s_axi_arid),
    .s_axi_araddr   (s_axi_araddr),
    .s_axi_arvalid  (s_axi_arvalid),
    .s_axi_arready  (s_axi_arready),

    .s_axi_rid      (s_axi_rid),
    .s_axi_rdata    (s_axi_rdata),
    .s_axi_rresp    (s_axi_rresp),
    .s_axi_rvalid   (s_axi_rvalid),
    .s_axi_rready   (s_axi_rready),

    .ctr_in         (ctr_in),
    .timer_irq      (timer_irq)
);

// ---------------------------------------------------------------------------
// Clock
// ---------------------------------------------------------------------------
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ---------------------------------------------------------------------------
// Scoreboard
// ---------------------------------------------------------------------------
integer pass_count = 0;
integer fail_count = 0;

task pass_test;
    input [255:0] name;
    begin
        $display("[PASS] %0s", name);
        pass_count = pass_count + 1;
    end
endtask

task fail_test;
    input [255:0] name;
    begin
        $display("[FAIL] %0s", name);
        fail_count = fail_count + 1;
    end
endtask

// ---------------------------------------------------------------------------
// AXI helper tasks
// ---------------------------------------------------------------------------
task axi_write;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;
    input [AXI_STRB_WIDTH-1:0] strb;
    begin
        @(posedge clk); #1;
        s_axi_awaddr  = addr;
        s_axi_awid    = 8'h01;
        s_axi_awvalid = 1'b1;
        s_axi_wdata   = data;
        s_axi_wstrb   = strb;
        s_axi_wvalid  = 1'b1;
        s_axi_bready  = 1'b1;

        fork
            begin @(posedge clk iff s_axi_awready); #1; s_axi_awvalid = 1'b0; end
            begin @(posedge clk iff s_axi_wready);  #1; s_axi_wvalid  = 1'b0; end
        join
        @(posedge clk iff s_axi_bvalid);
        #1; s_axi_bready = 1'b0;
        @(posedge clk);
    end
endtask

task axi_read;
    input  [AXI_ADDR_WIDTH-1:0] addr;
    output [AXI_DATA_WIDTH-1:0] data;
    begin
        @(posedge clk); #1;
        s_axi_araddr  = addr;
        s_axi_arid    = 8'h01;
        s_axi_arvalid = 1'b1;
        s_axi_rready  = 1'b1;

        @(posedge clk iff s_axi_arready); #1;
        s_axi_arvalid = 1'b0;
        @(posedge clk iff s_axi_rvalid);
        data = s_axi_rdata;
        #1; s_axi_rready = 1'b0;
        @(posedge clk);
    end
endtask

// ---------------------------------------------------------------------------
// Timeout watchdog
// ---------------------------------------------------------------------------
initial begin
    #5_000_000;
    $display("TIMEOUT: simulation exceeded 5 ms");
    $finish;
end

// ---------------------------------------------------------------------------
// Test body
// ---------------------------------------------------------------------------
reg [AXI_DATA_WIDTH-1:0] rd_data;
reg [AXI_DATA_WIDTH-1:0] tmr_val1, tmr_val2;
integer irq_timeout;

initial begin
    // ---- initialise ----
    rstn          = 1'b0;
    ctr_in        = 1'b0;
    s_axi_awvalid = 1'b0; s_axi_wvalid = 1'b0; s_axi_bready = 1'b0;
    s_axi_arvalid = 1'b0; s_axi_rready = 1'b0;
    s_axi_awaddr  = 32'h0; s_axi_awid  = 8'h0;
    s_axi_wdata   = 32'h0; s_axi_wstrb = 4'hF;
    s_axi_araddr  = 32'h0; s_axi_arid  = 8'h0;

    // ---------- TC1: Reset check ----------
    repeat(10) @(posedge clk);
    rstn = 1'b1;
    repeat(5)  @(posedge clk);

    axi_read(CTRL_ADDR, rd_data);
    if (rd_data === 32'h0)
        pass_test("TC1: CONTROL_REG = 0 after reset");
    else begin
        $display("      CTRL = 0x%08X (expected 0)", rd_data);
        fail_test("TC1: CONTROL_REG not 0 after reset");
    end

    // ---------- TC2: PERIOD write/read ----------
    axi_write(PERIOD_ADDR, 32'h0000_00FF, 4'hF);
    axi_read (PERIOD_ADDR, rd_data);
    if (rd_data === 32'h0000_00FF)
        pass_test("TC2: PERIOD write/readback = 0xFF");
    else begin
        $display("      PERIOD = 0x%08X (expected 0xFF)", rd_data);
        fail_test("TC2: PERIOD readback mismatch");
    end

    // ---------- TC3: CONTROL write/read ----------
    // EN=1, TMR_EN=1, CLK_SRC=8 (direct clk), up=0 (down-count)
    axi_write(CTRL_ADDR, 32'h0000_0903, 4'hF);  // EN+TMR_EN+CLK_SRC=9
    axi_read (CTRL_ADDR, rd_data);
    if (rd_data[1:0] === 2'b11)
        pass_test("TC3: CONTROL EN+TMR_EN bits set");
    else begin
        $display("      CTRL[1:0] = %b (expected 11)", rd_data[1:0]);
        fail_test("TC3: CONTROL bits mismatch");
    end

    // ---------- TC4: Timer counts ----------
    // Timer already running. Read twice with gap, verify decrement.
    axi_read(TIMER_ADDR, tmr_val1);
    repeat(20) @(posedge clk);
    axi_read(TIMER_ADDR, tmr_val2);

    if (tmr_val2 < tmr_val1)
        pass_test("TC4: Timer is counting down");
    else begin
        $display("      tmr1=0x%08X  tmr2=0x%08X", tmr_val1, tmr_val2);
        fail_test("TC4: Timer not counting down");
    end

    // ---------- TC5: Timeout interrupt ----------
    // Reload a small period so interrupt fires quickly
    // Stop timer first
    axi_write(CTRL_ADDR, 32'h0, 4'hF);

    // Set period = 32 counts
    axi_write(PERIOD_ADDR, 32'h0000_0020, 4'hF);

    // Unmask TO interrupt (IM[0]=1)
    axi_write(IM_ADDR, 32'h0000_0001, 4'hF);

    // Enable: EN+TMR_EN+CLK_SRC=8 (direct clk)
    axi_write(CTRL_ADDR, 32'h0000_0903, 4'hF);

    // Wait up to 200 cycles for IRQ
    irq_timeout = 0;
    while (!timer_irq && irq_timeout < 200) begin
        @(posedge clk);
        irq_timeout = irq_timeout + 1;
    end

    if (timer_irq)
        pass_test("TC5: timer_irq asserted on timeout");
    else
        fail_test("TC5: timer_irq did NOT assert within timeout");

    // ---------- TC6: ICR clears RIS ----------
    axi_read(RIS_ADDR, rd_data);
    if (rd_data[0] === 1'b1) begin
        // Clear bit0
        axi_write(ICR_ADDR, 32'h0000_0001, 4'hF);
        // Stop timer so no new interrupts fire
        axi_write(CTRL_ADDR, 32'h0, 4'hF);
        repeat(5) @(posedge clk);
        axi_read(RIS_ADDR, rd_data);
        if (rd_data[0] === 1'b0)
            pass_test("TC6: ICR write clears RIS[0]");
        else begin
            $display("      RIS[0] = %b after ICR clear", rd_data[0]);
            fail_test("TC6: RIS[0] not cleared by ICR");
        end
    end else begin
        fail_test("TC6: RIS[0] was not set — cannot test ICR");
    end

    // ---------- TC7: One-shot mode — timer stops after 1 period ----------
    axi_write(PERIOD_ADDR, 32'h0000_0020, 4'hF);
    // EN+TMR_EN+ONE_SHOT(bit17)+CLK_SRC=9(bits11:8)
    axi_write(CTRL_ADDR, 32'h0002_0903, 4'hF);

    // Wait enough cycles for one period to expire
    repeat(200) @(posedge clk);

    axi_read(TIMER_ADDR, tmr_val1);
    repeat(50) @(posedge clk);
    axi_read(TIMER_ADDR, tmr_val2);

    if (tmr_val1 === tmr_val2)
        pass_test("TC7: One-shot — timer stopped after 1 period");
    else begin
        $display("      tmr after stop: 0x%08X then 0x%08X", tmr_val1, tmr_val2);
        fail_test("TC7: One-shot — timer still running");
    end

    // ---------- TC8: Unknown address — no hang, DEADBEEF ----------
    axi_write(CTRL_ADDR, 32'h0, 4'hF); // stop timer
    axi_read(BAD_ADDR, rd_data);
    if (rd_data === 32'hDEAD_BEEF)
        pass_test("TC8: Unknown addr returns 0xDEADBEEF");
    else begin
        $display("      rd_data = 0x%08X", rd_data);
        fail_test("TC8: Expected 0xDEADBEEF for unknown addr");
    end

    // ---------- Summary ----------
    $display("========================================");
    $display("Timer (EF_TCC32) AXI Testbench Complete");
    $display("PASS: %0d   FAIL: %0d", pass_count, fail_count);
    $display("========================================");
    if (fail_count == 0)
        $display(">>> ALL TESTS PASSED <<<");
    else
        $display(">>> SOME TESTS FAILED <<<");

    #100;
    $finish;
end

endmodule
