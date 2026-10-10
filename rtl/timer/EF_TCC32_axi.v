/* =============================================================================
 * Project        : Honours Project
 * File           : EF_TCC32_axi.v
 * Description    : AXI4-Lite wrapper for EF_TCC32 32-bit Timer/Counter/Capture
 *
 * Connects to AXI Interconnect at Slave M04 (0x0400_0000).
 *
 * Register Map (offsets from base address 0x0400_0000):
 * ┌────────┬──────────────────┬─────┬─────────────────────────────────────┐
 * │ Offset │ Name             │ R/W │ Description                         │
 * ├────────┼──────────────────┼─────┼─────────────────────────────────────┤
 * │ 0x0000 │ TIMER_REG        │ RO  │ Current timer value [31:0]          │
 * │ 0x0004 │ PERIOD_REG       │ RW  │ Timer period / terminal count       │
 * │ 0x0008 │ COUNTER_REG      │ RO  │ Event capture counter value         │
 * │ 0x000C │ COUNTER_MATCH    │ RW  │ Counter match value                 │
 * │ 0x0010 │ CONTROL_REG      │ RW  │ Control (see below)                 │
 * │ 0x0F00 │ ICR_REG          │ W1C │ Interrupt Clear Register            │
 * │ 0x0F04 │ RIS_REG          │ RO  │ Raw Interrupt Status                │
 * │ 0x0F08 │ IM_REG           │ RW  │ Interrupt Mask                      │
 * │ 0x0F0C │ MIS_REG          │ RO  │ Masked Interrupt Status (RIS & IM)  │
 * └────────┴──────────────────┴─────┴─────────────────────────────────────┘
 *
 * CONTROL_REG bits:
 *   bit0        = EN       (module enable)
 *   bit1        = TMR_EN   (timer enable)
 *   bit3        = CP_EN    (capture enable)
 *   bits[11:8]  = CLK_SRC  (clock source select)
 *   bit16       = UP       (1=count up, 0=count down)
 *   bit17       = ONE_SHOT (1=one-shot, 0=continuous)
 *   bits[25:24] = CP_EVENT (capture event select)
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module EF_TCC32_axi #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ID_WIDTH   = 8,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8
)(
    input  wire                      clk,
    input  wire                      rstn,

    // ----------------------------------------------------------------
    // AXI4-Lite Slave Interface
    // ----------------------------------------------------------------
    input  wire [AXI_ID_WIDTH-1:0]   s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [AXI_STRB_WIDTH-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [AXI_ID_WIDTH-1:0]   s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [AXI_ID_WIDTH-1:0]   s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [AXI_ID_WIDTH-1:0]   s_axi_rid,
    output reg  [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // ----------------------------------------------------------------
    // Timer capture input
    // ----------------------------------------------------------------
    input  wire                      ctr_in,

    // ----------------------------------------------------------------
    // Interrupt output
    // ----------------------------------------------------------------
    output wire                      timer_irq
);

// ====================================================================
// Register addresses (16-bit offset)
// ====================================================================
localparam TIMER_ADDR   = 16'h0000;
localparam PERIOD_ADDR  = 16'h0004;
localparam COUNTER_ADDR = 16'h0008;
localparam CMATCH_ADDR  = 16'h000C;
localparam CTRL_ADDR    = 16'h0010;
localparam ICR_ADDR     = 16'h0F00;
localparam RIS_ADDR     = 16'h0F04;
localparam IM_ADDR      = 16'h0F08;
localparam MIS_ADDR     = 16'h0F0C;

// ====================================================================
// Internal registers
// ====================================================================
reg [31:0] period_reg;
reg [31:0] cmatch_reg;
reg [31:0] ctrl_reg;
reg [31:0] im_reg;
reg [31:0] icr_reg;

// ====================================================================
// EF_TCC32 core wires
// ====================================================================
wire [31:0] tmr_out;
wire [31:0] cp_count_out;
wire        to_flag;
wire        match_flag;
wire        cp_flag;

wire        en_w       = ctrl_reg[0];
wire        tmr_en_w   = ctrl_reg[1];
wire        cp_en_w    = ctrl_reg[3];
wire [3:0]  clk_src_w  = ctrl_reg[11:8];
wire        up_w       = ctrl_reg[16];
wire        one_shot_w = ctrl_reg[17];
wire [1:0]  cp_event_w = ctrl_reg[25:24];

// ====================================================================
// Interrupt logic
// ====================================================================
reg [31:0] ris_reg;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        ris_reg <= 32'h0;
    end else begin
        if (to_flag)    ris_reg[0] <= 1'b1;
        if (match_flag) ris_reg[1] <= 1'b1;
        if (cp_flag)    ris_reg[2] <= 1'b1;
        // clear on ICR write
        ris_reg <= ris_reg & ~icr_reg;
        icr_reg <= 32'h0;
    end
end

wire [31:0] mis_wire = ris_reg & im_reg;
assign timer_irq = |mis_wire;

// ====================================================================
// EF_TCC32 instantiation
// ====================================================================
EF_TCC32 u_tcc32 (
    .clk        (clk),
    .rst_n      (rstn),
    .ctr_in     (ctr_in),
    .en         (en_w),
    .period     (period_reg),
    .ctr_match  (cmatch_reg),
    .clk_src    (clk_src_w),
    .tmr_en     (tmr_en_w),
    .one_shot   (one_shot_w),
    .up         (up_w),
    .cp_en      (cp_en_w),
    .cp_event   (cp_event_w),
    .tmr        (tmr_out),
    .cp_count   (cp_count_out),
    .to_flag    (to_flag),
    .match_flag (match_flag),
    .cp_flag    (cp_flag)
);

// ====================================================================
// AXI Write logic
// ====================================================================
reg [AXI_ADDR_WIDTH-1:0] wr_addr;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_awready <= 1'b0; s_axi_wready <= 1'b0;
        s_axi_bvalid  <= 1'b0; s_axi_bresp  <= 2'b0;
        s_axi_bid     <= {AXI_ID_WIDTH{1'b0}};
        period_reg <= 32'hFFFF_FFFF;
        cmatch_reg <= 32'h0;
        ctrl_reg   <= 32'h0;
        im_reg     <= 32'h0;
        icr_reg    <= 32'h0;
        wr_addr    <= {AXI_ADDR_WIDTH{1'b0}};
    end else begin
        // AW
        if (s_axi_awvalid && !s_axi_awready) begin
            s_axi_awready <= 1'b1;
            wr_addr       <= s_axi_awaddr;
            s_axi_bid     <= s_axi_awid;
        end else s_axi_awready <= 1'b0;

        // W
        if (s_axi_wvalid && !s_axi_wready) begin
            s_axi_wready <= 1'b1;
            case (wr_addr[15:0])
                PERIOD_ADDR: period_reg <= s_axi_wdata;
                CMATCH_ADDR: cmatch_reg <= s_axi_wdata;
                CTRL_ADDR:   ctrl_reg   <= s_axi_wdata;
                ICR_ADDR:    icr_reg    <= s_axi_wdata;
                IM_ADDR:     im_reg     <= s_axi_wdata;
                default: ;
            endcase
        end else s_axi_wready <= 1'b0;

        // B
        if (s_axi_wready && !s_axi_bvalid) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
        end else if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
    end
end

// ====================================================================
// AXI Read logic
// ====================================================================
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_arready <= 1'b0; s_axi_rvalid <= 1'b0;
        s_axi_rdata   <= 32'h0; s_axi_rresp <= 2'b0;
        s_axi_rid     <= {AXI_ID_WIDTH{1'b0}};
    end else begin
        if (s_axi_arvalid && !s_axi_arready) begin
            s_axi_arready <= 1'b1;
            s_axi_rid     <= s_axi_arid;
            s_axi_rresp   <= 2'b00;
            case (s_axi_araddr[15:0])
                TIMER_ADDR:   s_axi_rdata <= tmr_out;
                PERIOD_ADDR:  s_axi_rdata <= period_reg;
                COUNTER_ADDR: s_axi_rdata <= cp_count_out;
                CMATCH_ADDR:  s_axi_rdata <= cmatch_reg;
                CTRL_ADDR:    s_axi_rdata <= ctrl_reg;
                RIS_ADDR:     s_axi_rdata <= ris_reg;
                IM_ADDR:      s_axi_rdata <= im_reg;
                MIS_ADDR:     s_axi_rdata <= mis_wire;
                default:      s_axi_rdata <= 32'hDEAD_BEEF;
            endcase
            s_axi_rvalid <= 1'b1;
        end else begin
            s_axi_arready <= 1'b0;
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end
end

endmodule
`default_nettype wire
