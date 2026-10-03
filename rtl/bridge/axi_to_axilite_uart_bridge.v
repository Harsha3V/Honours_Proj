/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_to_axilite_uart_bridge.v
 * Description    : AXI4 to AXI4-Lite Bridge
 *                  Sits between the AXI Interconnect Master port (M00)
 *                  and the UART AXI4-Lite Slave.
 *
 *  Interconnect side (AXI4):           UART side (AXI4-Lite):
 *  ─────────────────────────           ──────────────────────
 *  ID_WIDTH    = 8                     ID_WIDTH    = 12
 *  ADDR_WIDTH  = 32                    ADDR_WIDTH  = 5
 *  DATA_WIDTH  = 32                    DATA_WIDTH  = 32
 *  Has AWLEN, AWSIZE, AWBURST          No burst (single beat only)
 *  Has RLAST                           No RLAST
 *
 *  Bridge responsibilities:
 *  1. Accept AXI4 burst — forward only the FIRST beat (AXI4-Lite = single beat)
 *  2. Truncate address [4:0] for UART register select
 *  3. Zero-extend ID from 8-bit to 12-bit for UART
 *  4. Truncate ID from 12-bit back to 8-bit for response
 *  5. Generate RLAST=1 always (single-beat response)
 *  6. Pass BRESP/RRESP through unchanged
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_to_axilite_uart_bridge #(
    // AXI4 side (Interconnect)
    parameter AXI_ID_WIDTH    = 8,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_STRB_WIDTH  = AXI_DATA_WIDTH/8,

    // AXI4-Lite side (UART)
    parameter LITE_ID_WIDTH   = 12,
    parameter LITE_ADDR_WIDTH = 5
)(
    input  wire                         clk,
    input  wire                         rstn,   // active-low reset

    // ----------------------------------------------------------------
    // AXI4 Slave port (connects TO Interconnect M00 output)
    // ----------------------------------------------------------------

    // AW channel
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]                   s_axi_awlen,   // burst length (ignored, only 1st beat used)
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
    input  wire [7:0]                   s_axi_arlen,   // ignored
    input  wire [2:0]                   s_axi_arsize,
    input  wire [1:0]                   s_axi_arburst,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,

    // R channel
    output wire [AXI_ID_WIDTH-1:0]      s_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]                   s_axi_rresp,
    output wire                         s_axi_rlast,   // always 1 (single beat)
    output wire                         s_axi_rvalid,
    input  wire                         s_axi_rready,

    // ----------------------------------------------------------------
    // AXI4-Lite Master port (connects TO UART slave)
    // ----------------------------------------------------------------

    // AW channel
    output wire [LITE_ID_WIDTH-1:0]     m_axi_awid,
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,

    // W channel
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,

    // B channel
    input  wire [LITE_ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,

    // AR channel
    output wire [LITE_ID_WIDTH-1:0]     m_axi_arid,
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire                         m_axi_arvalid,
    input  wire                         m_axi_arready,

    // R channel
    input  wire [LITE_ID_WIDTH-1:0]     m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rvalid,
    output wire                         m_axi_rready
);

// ====================================================================
// WRITE PATH
// ====================================================================
//
//  State machine:
//  IDLE → accept AW → forward to UART → accept W → forward to UART
//       → wait B from UART → forward B to master → back to IDLE
//
// ====================================================================

localparam WR_IDLE    = 2'b00;
localparam WR_ADDR    = 2'b01;  // waiting for UART awready
localparam WR_DATA    = 2'b10;  // waiting for UART wready
localparam WR_RESP    = 2'b11;  // waiting for UART bvalid

reg [1:0]                  wr_state, wr_state_d;
reg [AXI_ID_WIDTH-1:0]     wr_id,    wr_id_d;
reg [LITE_ADDR_WIDTH-1:0]  wr_addr,  wr_addr_d;
reg [AXI_DATA_WIDTH-1:0]   wr_data,  wr_data_d;
reg [AXI_STRB_WIDTH-1:0]   wr_strb,  wr_strb_d;
reg [1:0]                  wr_bresp, wr_bresp_d;
reg                        wr_bvalid, wr_bvalid_d;

// Write FSM combinational
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
                // Latch address and ID
                wr_id_d    = s_axi_awid;
                wr_addr_d  = s_axi_awaddr[LITE_ADDR_WIDTH-1:0]; // truncate to 5 bits
                wr_state_d = WR_ADDR;
            end
        end

        WR_ADDR: begin
            // Hold AW until UART accepts it
            if (m_axi_awready) begin
                wr_state_d = WR_DATA;
            end
        end

        WR_DATA: begin
            if (s_axi_wvalid) begin
                wr_data_d = s_axi_wdata;
                wr_strb_d = s_axi_wstrb;
                if (m_axi_wready) begin
                    // Both UART ready and master providing data
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

    // Clear bvalid when master accepts response
    if (wr_bvalid && s_axi_bready)
        wr_bvalid_d = 1'b0;
end

// Write FSM sequential
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

// Write channel output assignments
assign s_axi_awready = (wr_state == WR_IDLE) && s_axi_awvalid;
assign s_axi_wready  = (wr_state == WR_DATA) && m_axi_wready;
assign s_axi_bid     = wr_id;
assign s_axi_bresp   = wr_bresp;
assign s_axi_bvalid  = wr_bvalid;

// To UART AW channel
assign m_axi_awid    = {{(LITE_ID_WIDTH-AXI_ID_WIDTH){1'b0}}, wr_id};  // zero-extend 8→12
assign m_axi_awaddr  = wr_addr;
assign m_axi_awvalid = (wr_state == WR_ADDR);

// To UART W channel
assign m_axi_wdata   = (wr_state == WR_DATA) ? s_axi_wdata : wr_data;
assign m_axi_wstrb   = (wr_state == WR_DATA) ? s_axi_wstrb : wr_strb;
assign m_axi_wvalid  = (wr_state == WR_DATA) && s_axi_wvalid;

// Accept B from UART
assign m_axi_bready  = (wr_state == WR_RESP);


// ====================================================================
// READ PATH
// ====================================================================
//
//  State machine:
//  IDLE → accept AR → forward to UART → wait R from UART
//       → forward R to master → back to IDLE
//
// ====================================================================

localparam RD_IDLE = 2'b00;
localparam RD_ADDR = 2'b01;  // waiting for UART arready
localparam RD_DATA = 2'b10;  // waiting for UART rvalid
localparam RD_RESP = 2'b11;  // forwarding R to master

reg [1:0]                  rd_state, rd_state_d;
reg [AXI_ID_WIDTH-1:0]     rd_id,    rd_id_d;
reg [LITE_ADDR_WIDTH-1:0]  rd_addr,  rd_addr_d;
reg [AXI_DATA_WIDTH-1:0]   rd_data,  rd_data_d;
reg [1:0]                  rd_rresp, rd_rresp_d;
reg                        rd_rvalid, rd_rvalid_d;

// Read FSM combinational
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
                rd_addr_d  = s_axi_araddr[LITE_ADDR_WIDTH-1:0];
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

// Read FSM sequential
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

// Read channel output assignments
assign s_axi_arready = (rd_state == RD_IDLE) && s_axi_arvalid;
assign s_axi_rid     = rd_id;
assign s_axi_rdata   = rd_data;
assign s_axi_rresp   = rd_rresp;
assign s_axi_rlast   = 1'b1;          // always 1 — AXI4-Lite = single beat
assign s_axi_rvalid  = rd_rvalid;

// To UART AR channel
assign m_axi_arid    = {{(LITE_ID_WIDTH-AXI_ID_WIDTH){1'b0}}, rd_id};  // zero-extend 8→12
assign m_axi_araddr  = rd_addr;
assign m_axi_arvalid = (rd_state == RD_ADDR);

// Accept R from UART
assign m_axi_rready  = (rd_state == RD_DATA);

endmodule

`default_nettype wire
