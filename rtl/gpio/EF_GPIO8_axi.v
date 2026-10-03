/* =============================================================================
 * Project        : Honours Project
 * File           : EF_GPIO8_axi.v
 * Description    : AXI4-Lite wrapper for EF_GPIO8 8-bit GPIO peripheral
 *
 * This wrapper connects the EF_GPIO8 core to the AXI4 Interconnect at
 * Slave M05 (0x0500_0000).
 *
 * Register Map (offsets from base address 0x0500_0000):
 * ┌────────┬───────────┬─────┬──────────────────────────────────────────┐
 * │ Offset │ Name      │ R/W │ Description                              │
 * ├────────┼───────────┼─────┼──────────────────────────────────────────┤
 * │ 0x0000 │ DATAI     │ RO  │ GPIO input data  [7:0] (synchronized)    │
 * │ 0x0004 │ DATAO     │ RW  │ GPIO output data [7:0]                   │
 * │ 0x0008 │ DIR       │ RW  │ GPIO direction   [7:0] (1=output,0=input)│
 * │ 0xFF00 │ IM        │ RW  │ Interrupt Mask   [31:0]                  │
 * │ 0xFF04 │ MIS       │ RO  │ Masked Interrupt Status (RIS & IM)       │
 * │ 0xFF08 │ RIS       │ RO  │ Raw Interrupt Status                     │
 * │ 0xFF0C │ IC        │ RW  │ Interrupt Clear                          │
 * └────────┴───────────┴─────┴──────────────────────────────────────────┘
 *
 * Interrupt sources (one bit per GPIO pin):
 *   Each pin has 4 interrupt flags: hi, lo, posedge, negedge
 *   Packed into RIS as 32 bits (8 pins × 4 flags)
 *   bit[4i+0] = pin_i_hi, bit[4i+1] = pin_i_lo
 *   bit[4i+2] = pin_i_pe, bit[4i+3] = pin_i_ne
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module EF_GPIO8_axi #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ID_WIDTH   = 8,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8
)(
    input  wire                      clk,
    input  wire                      rstn,       // active-low reset

    // ----------------------------------------------------------------
    // AXI4-Lite Slave Interface
    // ----------------------------------------------------------------
    // AW channel
    input  wire [AXI_ID_WIDTH-1:0]   s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    // W channel
    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [AXI_STRB_WIDTH-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    // B channel
    output reg  [AXI_ID_WIDTH-1:0]   s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    // AR channel
    input  wire [AXI_ID_WIDTH-1:0]   s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    // R channel
    output reg  [AXI_ID_WIDTH-1:0]   s_axi_rid,
    output reg  [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // ----------------------------------------------------------------
    // GPIO physical pins
    // ----------------------------------------------------------------
    input  wire [7:0]                gpio_in,    // physical input pins
    output wire [7:0]                gpio_out,   // physical output pins
    output wire [7:0]                gpio_oe,    // output enable (1=drive)
    output wire                      gpio_irq    // interrupt output
);

// ====================================================================
// Register addresses (16-bit offset)
// ====================================================================
localparam DATAI_ADDR = 16'h0000;
localparam DATAO_ADDR = 16'h0004;
localparam DIR_ADDR   = 16'h0008;
localparam IM_ADDR    = 16'hFF00;
localparam MIS_ADDR   = 16'hFF04;
localparam RIS_ADDR   = 16'hFF08;
localparam IC_ADDR    = 16'hFF0C;

// ====================================================================
// Internal registers
// ====================================================================
reg [7:0]  DATAO_REG;
reg [7:0]  DIR_REG;
reg [31:0] IM_REG;
reg [31:0] IC_REG;
reg [31:0] RIS_REG;

wire [31:0] MIS_REG = RIS_REG & IM_REG;

// ====================================================================
// EF_GPIO8 core wires
// ====================================================================
wire [7:0] bus_in;  // synchronized input from core

// Per-pin interrupt flags from core
wire pin0_hi, pin1_hi, pin2_hi, pin3_hi, pin4_hi, pin5_hi, pin6_hi, pin7_hi;
wire pin0_lo, pin1_lo, pin2_lo, pin3_lo, pin4_lo, pin5_lo, pin6_lo, pin7_lo;
wire pin0_pe, pin1_pe, pin2_pe, pin3_pe, pin4_pe, pin5_pe, pin6_pe, pin7_pe;
wire pin0_ne, pin1_ne, pin2_ne, pin3_ne, pin4_ne, pin5_ne, pin6_ne, pin7_ne;

// ====================================================================
// EF_GPIO8 core instance
// ====================================================================
EF_GPIO8 u_gpio (
    .clk      (clk),
    .rst_n    (rstn),
    .io_in    (gpio_in),
    .bus_in   (bus_in),
    .io_out   (gpio_out),
    .bus_out  (DATAO_REG),
    .io_oe    (gpio_oe),
    .bus_oe   (DIR_REG),
    .pin0_hi  (pin0_hi), .pin1_hi(pin1_hi), .pin2_hi(pin2_hi), .pin3_hi(pin3_hi),
    .pin4_hi  (pin4_hi), .pin5_hi(pin5_hi), .pin6_hi(pin6_hi), .pin7_hi(pin7_hi),
    .pin0_lo  (pin0_lo), .pin1_lo(pin1_lo), .pin2_lo(pin2_lo), .pin3_lo(pin3_lo),
    .pin4_lo  (pin4_lo), .pin5_lo(pin5_lo), .pin6_lo(pin6_lo), .pin7_lo(pin7_lo),
    .pin0_pe  (pin0_pe), .pin1_pe(pin1_pe), .pin2_pe(pin2_pe), .pin3_pe(pin3_pe),
    .pin4_pe  (pin4_pe), .pin5_pe(pin5_pe), .pin6_pe(pin6_pe), .pin7_pe(pin7_pe),
    .pin0_ne  (pin0_ne), .pin1_ne(pin1_ne), .pin2_ne(pin2_ne), .pin3_ne(pin3_ne),
    .pin4_ne  (pin4_ne), .pin5_ne(pin5_ne), .pin6_ne(pin6_ne), .pin7_ne(pin7_ne)
);

// ====================================================================
// Raw Interrupt Status — pack all 32 pin flags
// bit[4i+0]=hi, bit[4i+1]=lo, bit[4i+2]=pe, bit[4i+3]=ne
// ====================================================================
wire [31:0] pin_flags = {
    pin7_ne, pin7_pe, pin7_lo, pin7_hi,
    pin6_ne, pin6_pe, pin6_lo, pin6_hi,
    pin5_ne, pin5_pe, pin5_lo, pin5_hi,
    pin4_ne, pin4_pe, pin4_lo, pin4_hi,
    pin3_ne, pin3_pe, pin3_lo, pin3_hi,
    pin2_ne, pin2_pe, pin2_lo, pin2_hi,
    pin1_ne, pin1_pe, pin1_lo, pin1_hi,
    pin0_ne, pin0_pe, pin0_lo, pin0_hi
};

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        RIS_REG <= 32'b0;
        IC_REG  <= 32'b0;
    end else begin
        IC_REG <= 32'b0; // IC is self-clearing

        // Set on any pin flag
        RIS_REG <= RIS_REG | pin_flags;

        // Clear bits written to IC
        RIS_REG <= (RIS_REG | pin_flags) & ~IC_REG;
    end
end

// Interrupt output — any unmasked interrupt
assign gpio_irq = |MIS_REG;

// ====================================================================
// AXI4-Lite Write Path
// ====================================================================
reg [AXI_ADDR_WIDTH-1:0] wr_addr;
reg [AXI_ID_WIDTH-1:0]   wr_id;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= 2'b0;
        s_axi_bid     <= {AXI_ID_WIDTH{1'b0}};
        wr_addr       <= {AXI_ADDR_WIDTH{1'b0}};
        wr_id         <= {AXI_ID_WIDTH{1'b0}};
        DATAO_REG     <= 8'h0;
        DIR_REG       <= 8'h0;
        IM_REG        <= 32'h0;
    end else begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;

        // Accept AW
        if (s_axi_awvalid && !s_axi_awready) begin
            s_axi_awready <= 1'b1;
            wr_addr       <= s_axi_awaddr;
            wr_id         <= s_axi_awid;
        end

        // Accept W and write register
        if (s_axi_wvalid && !s_axi_wready) begin
            s_axi_wready <= 1'b1;
            case (wr_addr[15:0])
                DATAO_ADDR: begin
                    if (s_axi_wstrb[0]) DATAO_REG <= s_axi_wdata[7:0];
                end
                DIR_ADDR: begin
                    if (s_axi_wstrb[0]) DIR_REG <= s_axi_wdata[7:0];
                end
                IM_ADDR: begin
                    if (s_axi_wstrb[0]) IM_REG[7:0]   <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) IM_REG[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) IM_REG[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) IM_REG[31:24] <= s_axi_wdata[31:24];
                end
                IC_ADDR: begin
                    if (s_axi_wstrb[0]) IC_REG[7:0]   <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) IC_REG[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) IC_REG[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) IC_REG[31:24] <= s_axi_wdata[31:24];
                end
                default: ; // read-only registers — ignore writes
            endcase

            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
            s_axi_bid    <= wr_id;
        end

        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
    end
end

// ====================================================================
// AXI4-Lite Read Path
// ====================================================================
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= 32'h0;
        s_axi_rresp   <= 2'b0;
        s_axi_rid     <= {AXI_ID_WIDTH{1'b0}};
    end else begin
        s_axi_arready <= 1'b0;

        if (s_axi_arvalid && !s_axi_arready) begin
            s_axi_arready <= 1'b1;
            s_axi_rid     <= s_axi_arid;
            s_axi_rresp   <= 2'b00;
            s_axi_rvalid  <= 1'b1;

            case (s_axi_araddr[15:0])
                DATAI_ADDR: s_axi_rdata <= {24'b0, bus_in};
                DATAO_ADDR: s_axi_rdata <= {24'b0, DATAO_REG};
                DIR_ADDR:   s_axi_rdata <= {24'b0, DIR_REG};
                IM_ADDR:    s_axi_rdata <= IM_REG;
                MIS_ADDR:   s_axi_rdata <= MIS_REG;
                RIS_ADDR:   s_axi_rdata <= RIS_REG;
                IC_ADDR:    s_axi_rdata <= IC_REG;
                default:    s_axi_rdata <= 32'hDEAD_BEEF;
            endcase
        end

        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;
    end
end

endmodule

`default_nettype wire
