/* =============================================================================
 * Project  : Honours Project — AES-128 ECU Gateway SoC
 * File     : tb/spi/tb_spi_axi_top.v
 * DUT      : spi_axi_top (wraps SPI_Master_With_Single_CS)
 *
 * Test cases:
 *   TC1 — Reset check:       all AXI outputs idle after reset
 *   TC2 — TX_COUNT write:    set TX_COUNT=1, read back, verify
 *   TC3 — STATUS read:       TX_READY=1 when idle (SPI not busy)
 *   TC4 — TX byte 0xA5:      write TX_DATA → SPI CS_N asserts, MOSI bit-bangs
 *   TC5 — MOSI capture:      reconstruct byte from MOSI, compare to 0xA5
 *   TC6 — RX_DATA read:      loopback MISO=MOSI, verify RX_DATA after transfer
 *   TC7 — Unknown addr:      write/read garbage addr → no hang, DEADBEEF on read
 *
 * SPI parameters: SPI_MODE=0, CLKS_PER_HALF_BIT=2, MAX_BYTES_PER_CS=2
 * =============================================================================*/

`timescale 1ns/1ps

module tb_spi_axi_top;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
localparam CLK_PERIOD        = 10;    // 100 MHz
localparam AXI_ADDR_WIDTH    = 32;
localparam AXI_DATA_WIDTH    = 32;
localparam AXI_ID_WIDTH      = 8;
localparam AXI_STRB_WIDTH    = 4;

// Register offsets
localparam TX_DATA_ADDR  = 32'h00;
localparam RX_DATA_ADDR  = 32'h04;
localparam STATUS_ADDR   = 32'h08;
localparam TX_COUNT_ADDR = 32'h0C;
localparam BAD_ADDR      = 32'hFF;

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg  clk, rstn;

// AXI4-Lite write
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

// AXI4-Lite read
reg  [AXI_ID_WIDTH-1:0]   s_axi_arid;
reg  [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
reg                        s_axi_arvalid;
wire                       s_axi_arready;

wire [AXI_ID_WIDTH-1:0]   s_axi_rid;
wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
wire [1:0]                 s_axi_rresp;
wire                       s_axi_rvalid;
reg                        s_axi_rready;

// SPI pins
wire spi_clk;
wire spi_mosi;
reg  spi_miso;
wire spi_cs_n;

// ---------------------------------------------------------------------------
// DUT instantiation
// ---------------------------------------------------------------------------
spi_axi_top #(
    .AXI_ADDR_WIDTH    (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH      (AXI_ID_WIDTH),
    .SPI_MODE          (0),
    .CLKS_PER_HALF_BIT (2),
    .MAX_BYTES_PER_CS  (2),
    .CS_INACTIVE_CLKS  (1)
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

    .spi_clk        (spi_clk),
    .spi_mosi       (spi_mosi),
    .spi_miso       (spi_miso),
    .spi_cs_n       (spi_cs_n)
);

// ---------------------------------------------------------------------------
// MISO loopback — echo MOSI back with a small delay (slave echos)
// ---------------------------------------------------------------------------
always @(posedge spi_clk) spi_miso <= spi_mosi;

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
// Capture MOSI byte during SPI transfer
// ---------------------------------------------------------------------------
reg [7:0] mosi_byte;
integer   mosi_bit_idx;

task capture_mosi_byte;
    begin
        mosi_byte    = 8'h00;
        mosi_bit_idx = 7;
        // wait for CS to assert
        @(negedge spi_cs_n);
        repeat(8) begin
            @(posedge spi_clk);
            mosi_byte[mosi_bit_idx] = spi_mosi;
            mosi_bit_idx = mosi_bit_idx - 1;
        end
        @(posedge spi_cs_n);
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

initial begin
    // ---- initialise all AXI signals ----
    rstn          = 1'b0;
    s_axi_awvalid = 1'b0;  s_axi_wvalid = 1'b0;  s_axi_bready = 1'b0;
    s_axi_arvalid = 1'b0;  s_axi_rready = 1'b0;
    s_axi_awaddr  = 32'h0; s_axi_awid   = 8'h0;
    s_axi_wdata   = 32'h0; s_axi_wstrb  = 4'hF;
    s_axi_araddr  = 32'h0; s_axi_arid   = 8'h0;
    spi_miso      = 1'b0;

    // ---------- TC1: Reset check ----------
    repeat(10) @(posedge clk);
    rstn = 1'b1;
    repeat(5)  @(posedge clk);

    if (spi_cs_n === 1'b1)
        pass_test("TC1: CS_N inactive after reset");
    else
        fail_test("TC1: CS_N should be high after reset");

    // ---------- TC2: TX_COUNT write/read-back ----------
    axi_write(TX_COUNT_ADDR, 32'h1, 4'hF);
    axi_read (TX_COUNT_ADDR, rd_data);
    if (rd_data[0] === 1'b1)
        pass_test("TC2: TX_COUNT write/readback = 1");
    else
        fail_test("TC2: TX_COUNT readback mismatch");

    // ---------- TC3: STATUS read — TX_READY=1 when idle ----------
    axi_read(STATUS_ADDR, rd_data);
    if (rd_data[0] === 1'b1)
        pass_test("TC3: STATUS.TX_READY=1 when SPI idle");
    else
        fail_test("TC3: TX_READY should be 1 when SPI idle");

    // ---------- TC4 + TC5: transmit 0xA5, capture MOSI ----------
    fork
        begin
            // Write TX_DATA — triggers SPI transfer
            axi_write(TX_DATA_ADDR, 32'hA5, 4'hF);
            $display("TC4: TX_DATA=0xA5 written — SPI transfer triggered");
        end
        begin
            capture_mosi_byte;
        end
    join

    if (mosi_byte === 8'hA5)
        pass_test("TC4+TC5: MOSI byte = 0xA5 correct");
    else begin
        $display("      MOSI captured = 0x%02X (expected 0xA5)", mosi_byte);
        fail_test("TC4+TC5: MOSI byte mismatch");
    end

    // ---------- TC6: RX_DATA — MISO loopback → should read 0xA5 ----------
    // Wait for SPI transfer to fully complete
    repeat(100) @(posedge clk);
    axi_read(RX_DATA_ADDR, rd_data);
    if (rd_data[7:0] === 8'hA5)
        pass_test("TC6: RX_DATA = 0xA5 (MISO loopback)");
    else begin
        $display("      RX_DATA = 0x%02X (expected 0xA5)", rd_data[7:0]);
        fail_test("TC6: RX_DATA mismatch");
    end

    // ---------- TC7: Unknown address — no hang, DEADBEEF ----------
    axi_read(BAD_ADDR, rd_data);
    if (rd_data === 32'hDEAD_BEEF)
        pass_test("TC7: Unknown addr returns 0xDEADBEEF");
    else begin
        $display("      rd_data = 0x%08X", rd_data);
        fail_test("TC7: Expected 0xDEADBEEF for unknown addr");
    end

    // ---------- Summary ----------
    $display("========================================");
    $display("SPI AXI Testbench Complete");
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
