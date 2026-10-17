/* =============================================================================
 * Project  : Honours Project — AES-128 ECU Gateway SoC
 * File     : tb/gpio/tb_EF_GPIO8_axi.v
 * DUT      : EF_GPIO8_axi (AXI4-Lite wrapper for EF_GPIO8 8-bit GPIO)
 *
 * Test cases:
 *   TC1 — Reset check:       DATAO=0, DIR=0, IM=0 after reset
 *   TC2 — DIR write/read:    set all pins as output (DIR=0xFF), read back
 *   TC3 — DATAO write/read:  write 0xAA to output pins, read back DATAO
 *   TC4 — gpio_out match:    verify gpio_out = DATAO when DIR=output
 *   TC5 — DATAI read:        drive gpio_in externally, read DATAI
 *   TC6 — Posedge interrupt: drive GPIO pin 0 high → verify RIS posedge bit
 *   TC7 — IM mask + MIS:     set IM, check MIS = RIS & IM
 *   TC8 — IC clears RIS:     write IC, verify RIS bit clears
 *   TC9 — gpio_irq asserts:  unmask interrupt, verify gpio_irq goes high
 *   TC10 — Unknown addr:     read BAD_ADDR → 0xDEADBEEF, no hang
 * =============================================================================*/

`timescale 1ns/1ps

module tb_EF_GPIO8_axi;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
localparam CLK_PERIOD     = 10;   // 100 MHz
localparam AXI_ADDR_WIDTH = 32;
localparam AXI_DATA_WIDTH = 32;
localparam AXI_ID_WIDTH   = 8;
localparam AXI_STRB_WIDTH = 4;

// Register offsets (match EF_GPIO8_axi.v)
localparam DATAI_ADDR = 32'h0000;
localparam DATAO_ADDR = 32'h0004;
localparam DIR_ADDR   = 32'h0008;
localparam IM_ADDR    = 32'hFF00;
localparam MIS_ADDR   = 32'hFF04;
localparam RIS_ADDR   = 32'hFF08;
localparam IC_ADDR    = 32'hFF0C;
localparam BAD_ADDR   = 32'h1234;

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg  clk, rstn;
reg  [7:0] gpio_in;
wire [7:0] gpio_out;
wire [7:0] gpio_oe;
wire       gpio_irq;

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
EF_GPIO8_axi #(
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

    .gpio_in        (gpio_in),
    .gpio_out       (gpio_out),
    .gpio_oe        (gpio_oe),
    .gpio_irq       (gpio_irq)
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
    #2_000_000;
    $display("TIMEOUT: simulation exceeded 2 ms");
    $finish;
end

// ---------------------------------------------------------------------------
// Test body
// ---------------------------------------------------------------------------
reg [AXI_DATA_WIDTH-1:0] rd_data;
integer irq_wait;

initial begin
    // ---- initialise ----
    rstn          = 1'b0;
    gpio_in       = 8'h00;
    s_axi_awvalid = 1'b0; s_axi_wvalid = 1'b0; s_axi_bready = 1'b0;
    s_axi_arvalid = 1'b0; s_axi_rready = 1'b0;
    s_axi_awaddr  = 32'h0; s_axi_awid  = 8'h0;
    s_axi_wdata   = 32'h0; s_axi_wstrb = 4'hF;
    s_axi_araddr  = 32'h0; s_axi_arid  = 8'h0;

    // ---------- TC1: Reset check ----------
    repeat(10) @(posedge clk);
    rstn = 1'b1;
    repeat(5)  @(posedge clk);

    axi_read(DATAO_ADDR, rd_data);
    if (rd_data[7:0] === 8'h00)
        pass_test("TC1: DATAO = 0 after reset");
    else begin
        $display("      DATAO = 0x%02X (expected 0)", rd_data[7:0]);
        fail_test("TC1: DATAO not 0 after reset");
    end

    axi_read(DIR_ADDR, rd_data);
    if (rd_data[7:0] === 8'h00)
        pass_test("TC1: DIR = 0 after reset (all inputs)");
    else begin
        $display("      DIR = 0x%02X (expected 0)", rd_data[7:0]);
        fail_test("TC1: DIR not 0 after reset");
    end

    // ---------- TC2: DIR write/read (all outputs) ----------
    axi_write(DIR_ADDR, 32'hFF, 4'hF);
    axi_read (DIR_ADDR, rd_data);
    if (rd_data[7:0] === 8'hFF)
        pass_test("TC2: DIR = 0xFF (all outputs)");
    else begin
        $display("      DIR = 0x%02X (expected 0xFF)", rd_data[7:0]);
        fail_test("TC2: DIR readback mismatch");
    end

    // ---------- TC3: DATAO write/read ----------
    axi_write(DATAO_ADDR, 32'hAA, 4'hF);
    axi_read (DATAO_ADDR, rd_data);
    if (rd_data[7:0] === 8'hAA)
        pass_test("TC3: DATAO write/readback = 0xAA");
    else begin
        $display("      DATAO = 0x%02X (expected 0xAA)", rd_data[7:0]);
        fail_test("TC3: DATAO readback mismatch");
    end

    // ---------- TC4: gpio_out matches DATAO when DIR=output ----------
    // Allow 2-cycle propagation through EF_GPIO8 core
    repeat(4) @(posedge clk);
    if (gpio_out === 8'hAA)
        pass_test("TC4: gpio_out = 0xAA (matches DATAO)");
    else begin
        $display("      gpio_out = 0x%02X (expected 0xAA)", gpio_out);
        fail_test("TC4: gpio_out mismatch");
    end

    // ---------- TC5: DATAI read — drive gpio_in ----------
    // Switch pin 0 to input
    axi_write(DIR_ADDR, 32'hFE, 4'hF);  // pin 0 = input, rest = output
    gpio_in = 8'h5A;                     // drive externally
    repeat(5) @(posedge clk);            // let synchronizer settle
    axi_read(DATAI_ADDR, rd_data);
    if (rd_data[7:0] === 8'h5A)
        pass_test("TC5: DATAI = 0x5A (gpio_in read correctly)");
    else begin
        $display("      DATAI = 0x%02X (expected 0x5A)", rd_data[7:0]);
        fail_test("TC5: DATAI mismatch");
    end

    // ---------- TC6: Posedge interrupt on pin 0 ----------
    // Pin 0 is input. Drive 0→1 transition.
    gpio_in[0] = 1'b0;
    repeat(4) @(posedge clk);
    gpio_in[0] = 1'b1;   // rising edge
    repeat(5) @(posedge clk);

    axi_read(RIS_ADDR, rd_data);
    // bit[4*0+2] = pin0_pe = bit 2
    if (rd_data[2] === 1'b1)
        pass_test("TC6: RIS posedge bit for pin 0 set");
    else begin
        $display("      RIS = 0x%08X (expected bit2=1 for pin0 posedge)", rd_data);
        fail_test("TC6: RIS posedge bit not set");
    end

    // ---------- TC7: IM + MIS ----------
    // Set IM = only unmask pin0_pe (bit2)
    axi_write(IM_ADDR, 32'h0000_0004, 4'hF);  // bit2
    axi_read(MIS_ADDR, rd_data);
    if (rd_data[2] === 1'b1)
        pass_test("TC7: MIS[2] = 1 (RIS & IM, pin0_pe unmasked)");
    else begin
        $display("      MIS = 0x%08X (expected bit2=1)", rd_data);
        fail_test("TC7: MIS bit not set correctly");
    end

    // ---------- TC8: IC clears RIS ----------
    axi_write(IC_ADDR, 32'h0000_0004, 4'hF);  // clear pin0_pe
    repeat(4) @(posedge clk);
    axi_read(RIS_ADDR, rd_data);
    if (rd_data[2] === 1'b0)
        pass_test("TC8: IC write clears RIS[2] (pin0_pe)");
    else begin
        $display("      RIS[2] = %b after IC clear", rd_data[2]);
        fail_test("TC8: RIS[2] not cleared by IC");
    end

    // ---------- TC9: gpio_irq ----------
    // Make a fresh posedge on pin1, IM already has bit2 set, add pin1_pe=bit6
    axi_write(IM_ADDR, 32'h0000_0044, 4'hF);  // bit2 + bit6
    gpio_in[1] = 1'b0;
    repeat(4) @(posedge clk);
    gpio_in[1] = 1'b1;   // rising edge pin1
    repeat(5) @(posedge clk);

    if (gpio_irq === 1'b1)
        pass_test("TC9: gpio_irq asserted on unmasked interrupt");
    else begin
        $display("      gpio_irq = %b (expected 1)", gpio_irq);
        fail_test("TC9: gpio_irq not asserted");
    end

    // Clear all interrupts
    axi_write(IC_ADDR, 32'hFFFF_FFFF, 4'hF);
    axi_write(IM_ADDR, 32'h0000_0000, 4'hF);  // mask everything
    repeat(4) @(posedge clk);

    // ---------- TC10: Unknown address → DEADBEEF ----------
    axi_read(BAD_ADDR, rd_data);
    if (rd_data === 32'hDEAD_BEEF)
        pass_test("TC10: Unknown addr returns 0xDEADBEEF");
    else begin
        $display("      rd_data = 0x%08X", rd_data);
        fail_test("TC10: Expected 0xDEADBEEF for unknown addr");
    end

    // ---------- Summary ----------
    $display("========================================");
    $display("GPIO (EF_GPIO8) AXI Testbench Complete");
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
