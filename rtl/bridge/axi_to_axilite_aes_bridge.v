/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_to_axilite_aes_bridge.v
 * Description    : AXI4 to AXI4-Lite Bridge for AES-128 Engine
 *                  Sits between the AXI Interconnect Master port (M03)
 *                  and the AES AXI4-Lite Slave (AES_AXI).
 *
 *  Interconnect side (AXI4):           AES side (AXI4-Lite):
 *  ─────────────────────────           ─────────────────────
 *  ID_WIDTH    = 8                     No ID (AES_AXI has no ID port)
 *  ADDR_WIDTH  = 32                    ADDR_WIDTH = 7 (0x00–0x70)
 *  DATA_WIDTH  = 32                    DATA_WIDTH = 32
 *  Has AWLEN, AWSIZE, AWBURST          No burst (single beat only)
 *  Has RLAST                           No RLAST
 *
 *  Bridge responsibilities:
 *  1. Accept AXI4 burst — forward only the FIRST beat
 *  2. Truncate address to 7 bits [6:0] for AES register select
 *  3. AES_AXI has NO ID ports — IDs are tracked internally, returned on response
 *  4. Generate RLAST=1 always (single-beat)
 *  5. Pass BRESP/RRESP through unchanged
 *
 *  AES Register Map (from aes_axi_slave.v):
 *    Encrypt:
 *      0x00 = CSR (bit16=START, bit0=DONE, bit1=BUSY)
 *      0x04-0x10 = KEY[0:3]
 *      0x14-0x20 = TEXTIN[0:3]
 *      0x24-0x30 = TEXTOUT[0:3]  (read-only)
 *    Decrypt:
 *      0x40 = INV_CSR (bit17=START, bit16=KEY_LOAD, bit0=DONE)
 *      0x44-0x50 = INV_KEY[0:3]
 *      0x54-0x60 = INV_TEXTIN[0:3]
 *      0x64-0x70 = INV_TEXTOUT[0:3] (read-only)
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_to_axilite_aes_bridge #(
    // AXI4 side (Interconnect)
    parameter AXI_ID_WIDTH    = 8,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_STRB_WIDTH  = AXI_DATA_WIDTH/8,

    // AXI4-Lite side (AES) — 7-bit address covers 0x00–0x70
    parameter LITE_ADDR_WIDTH = 7
)(
    input  wire                         clk,
    input  wire                         rstn,   // active-low reset

    // ----------------------------------------------------------------
    // AXI4 Slave port (connects TO Interconnect M03 output)
    // ----------------------------------------------------------------

    // AW channel
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]                   s_axi_awlen,
    input  wire [2:0]                   s_axi_awsize,
    input  wire [1:0]                   s_axi_awburst,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,

    // W channel
    input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [AXI_STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire                         s_axi_wlast,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,

    // B channel
    output wire [AXI_ID_WIDTH-1:0]      s_axi_bid,
    output wire [1:0]                   s_axi_bresp,
    output wire                         s_axi_bvalid,
    input  wire                         s_axi_bready,

    // AR channel
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]                   s_axi_arlen,
    input  wire [2:0]                   s_axi_arsize,
    input  wire [1:0]                   s_axi_arburst,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,

    // R channel
    output wire [AXI_ID_WIDTH-1:0]      s_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]                   s_axi_rresp,
    output wire                         s_axi_rlast,
    output wire                         s_axi_rvalid,
    input  wire                         s_axi_rready,

    // ----------------------------------------------------------------
    // AXI4-Lite Master port (connects TO AES_AXI slave)
    // Note: AES_AXI has no ID ports — bridge tracks IDs internally
    // ----------------------------------------------------------------

    // AW channel
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,

    // W channel
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,

    // B channel
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,

    // AR channel
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire                         m_axi_arvalid,
    input  wire                         m_axi_arready,

    // R channel
    input  wire [AXI_DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rvalid,
    output wire                         m_axi_rready
);

// ====================================================================
// WRITE PATH FSM
// ====================================================================

localparam WR_IDLE = 2'b00;
localparam WR_ADDR = 2'b01;   // forwarding AW to AES, waiting for awready
localparam WR_DATA = 2'b10;   // forwarding W to AES, waiting for wready
localparam WR_RESP = 2'b11;   // waiting for AES bvalid, then return to master

reg [1:0]                  wr_state, wr_state_d;
reg [AXI_ID_WIDTH-1:0]     wr_id,    wr_id_d;
reg [LITE_ADDR_WIDTH-1:0]  wr_addr,  wr_addr_d;
reg [AXI_DATA_WIDTH-1:0]   wr_data,  wr_data_d;
reg [AXI_STRB_WIDTH-1:0]   wr_strb,  wr_strb_d;
reg [1:0]                  wr_bresp, wr_bresp_d;
reg                        wr_bvalid, wr_bvalid_d;

always @(*) begin
    wr_state_d  = wr_state;
    wr_id_d     = wr_id;
    wr_addr_d   = wr_addr;
    wr_data_d   = wr_data;
    wr_strb_d   = wr_strb;
    wr_bresp_d  = wr_bresp;
    wr_bvalid_d = wr_bvalid;

    case (wr_state)
        WR_IDLE: begin
            wr_bvalid_d = 1'b0;
            if (s_axi_awvalid) begin
                wr_id_d    = s_axi_awid;
                wr_addr_d  = s_axi_awaddr[LITE_ADDR_WIDTH-1:0]; // truncate to 7 bits
                wr_state_d = WR_ADDR;
            end
        end

        WR_ADDR: begin
            if (m_axi_awready) begin
                wr_state_d = WR_DATA;
            end
        end

        WR_DATA: begin
            if (s_axi_wvalid) begin
                wr_data_d = s_axi_wdata;
                wr_strb_d = s_axi_wstrb;
                if (m_axi_wready) begin
                    wr_state_d = WR_RESP;
                end
            end
        end

        WR_RESP: begin
            if (m_axi_bvalid) begin
                wr_bresp_d  = m_axi_bresp;
                wr_bvalid_d = 1'b1;
                wr_state_d  = WR_IDLE;
            end
        end

        default: wr_state_d = WR_IDLE;
    endcase

    // Clear bvalid once master accepts
    if (wr_bvalid && s_axi_bready)
        wr_bvalid_d = 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        wr_state  <= WR_IDLE;
        wr_id     <= {AXI_ID_WIDTH{1'b0}};
        wr_addr   <= {LITE_ADDR_WIDTH{1'b0}};
        wr_data   <= {AXI_DATA_WIDTH{1'b0}};
        wr_strb   <= {AXI_STRB_WIDTH{1'b0}};
        wr_bresp  <= 2'b0;
        wr_bvalid <= 1'b0;
    end else begin
        wr_state  <= wr_state_d;
        wr_id     <= wr_id_d;
        wr_addr   <= wr_addr_d;
        wr_data   <= wr_data_d;
        wr_strb   <= wr_strb_d;
        wr_bresp  <= wr_bresp_d;
        wr_bvalid <= wr_bvalid_d;
    end
end

// Write channel outputs — AXI4 slave side
assign s_axi_awready = (wr_state == WR_IDLE) && s_axi_awvalid;
assign s_axi_wready  = (wr_state == WR_DATA) && m_axi_wready;
assign s_axi_bid     = wr_id;
assign s_axi_bresp   = wr_bresp;
assign s_axi_bvalid  = wr_bvalid;

// Write channel outputs — AES AXI4-Lite master side
assign m_axi_awaddr  = wr_addr;
assign m_axi_awvalid = (wr_state == WR_ADDR);
assign m_axi_wdata   = (wr_state == WR_DATA) ? s_axi_wdata : wr_data;
assign m_axi_wstrb   = (wr_state == WR_DATA) ? s_axi_wstrb : wr_strb;
assign m_axi_wvalid  = (wr_state == WR_DATA) && s_axi_wvalid;
assign m_axi_bready  = (wr_state == WR_RESP);

// ====================================================================
// READ PATH FSM
// ====================================================================

localparam RD_IDLE = 2'b00;
localparam RD_ADDR = 2'b01;   // forwarding AR to AES, waiting for arready
localparam RD_DATA = 2'b10;   // waiting for AES rvalid
localparam RD_RESP = 2'b11;   // forwarding R to master, waiting for rready

reg [1:0]                  rd_state, rd_state_d;
reg [AXI_ID_WIDTH-1:0]     rd_id,    rd_id_d;
reg [LITE_ADDR_WIDTH-1:0]  rd_addr,  rd_addr_d;
reg [AXI_DATA_WIDTH-1:0]   rd_data,  rd_data_d;
reg [1:0]                  rd_rresp, rd_rresp_d;
reg                        rd_rvalid, rd_rvalid_d;

always @(*) begin
    rd_state_d  = rd_state;
    rd_id_d     = rd_id;
    rd_addr_d   = rd_addr;
    rd_data_d   = rd_data;
    rd_rresp_d  = rd_rresp;
    rd_rvalid_d = rd_rvalid;

    case (rd_state)
        RD_IDLE: begin
            rd_rvalid_d = 1'b0;
            if (s_axi_arvalid) begin
                rd_id_d    = s_axi_arid;
                rd_addr_d  = s_axi_araddr[LITE_ADDR_WIDTH-1:0]; // truncate to 7 bits
                rd_state_d = RD_ADDR;
            end
        end

        RD_ADDR: begin
            if (m_axi_arready) begin
                rd_state_d = RD_DATA;
            end
        end

        RD_DATA: begin
            if (m_axi_rvalid) begin
                rd_data_d   = m_axi_rdata;
                rd_rresp_d  = m_axi_rresp;
                rd_rvalid_d = 1'b1;
                rd_state_d  = RD_RESP;
            end
        end

        RD_RESP: begin
            if (s_axi_rready) begin
                rd_rvalid_d = 1'b0;
                rd_state_d  = RD_IDLE;
            end
        end

        default: rd_state_d = RD_IDLE;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        rd_state  <= RD_IDLE;
        rd_id     <= {AXI_ID_WIDTH{1'b0}};
        rd_addr   <= {LITE_ADDR_WIDTH{1'b0}};
        rd_data   <= {AXI_DATA_WIDTH{1'b0}};
        rd_rresp  <= 2'b0;
        rd_rvalid <= 1'b0;
    end else begin
        rd_state  <= rd_state_d;
        rd_id     <= rd_id_d;
        rd_addr   <= rd_addr_d;
        rd_data   <= rd_data_d;
        rd_rresp  <= rd_rresp_d;
        rd_rvalid <= rd_rvalid_d;
    end
end

// Read channel outputs — AXI4 slave side
assign s_axi_arready = (rd_state == RD_IDLE) && s_axi_arvalid;
assign s_axi_rid     = rd_id;
assign s_axi_rdata   = rd_data;
assign s_axi_rresp   = rd_rresp;
assign s_axi_rlast   = 1'b1;       // AXI4-Lite = always single beat
assign s_axi_rvalid  = rd_rvalid;

// Read channel outputs — AES AXI4-Lite master side
assign m_axi_araddr  = rd_addr;
assign m_axi_arvalid = (rd_state == RD_ADDR);
assign m_axi_rready  = (rd_state == RD_DATA);

endmodule

`default_nettype wire
