/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_to_axilite_timer_bridge.v
 * Description    : AXI4 to AXI4-Lite Bridge for Timer (EF_TCC32_axi)
 *
 * Interconnect M04 (AXI4, 32-bit) → Bridge → EF_TCC32_axi (AXI4-Lite, 16-bit addr)
 *
 * EF_TCC32_axi has its own ID ports (8-bit) so this bridge passes IDs through.
 * Address truncated to 16 bits [15:0] — covers 0x0000–0x0F0C timer registers.
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_to_axilite_timer_bridge #(
    parameter AXI_ID_WIDTH    = 8,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_STRB_WIDTH  = AXI_DATA_WIDTH/8,
    parameter LITE_ADDR_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rstn,

    // AXI4 Slave (from Interconnect M04)
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]                   s_axi_awlen,
    input  wire [2:0]                   s_axi_awsize,
    input  wire [1:0]                   s_axi_awburst,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,
    input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [AXI_STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire                         s_axi_wlast,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,
    output wire [AXI_ID_WIDTH-1:0]      s_axi_bid,
    output wire [1:0]                   s_axi_bresp,
    output wire                         s_axi_bvalid,
    input  wire                         s_axi_bready,
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]                   s_axi_arlen,
    input  wire [2:0]                   s_axi_arsize,
    input  wire [1:0]                   s_axi_arburst,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,
    output wire [AXI_ID_WIDTH-1:0]      s_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]                   s_axi_rresp,
    output wire                         s_axi_rlast,
    output wire                         s_axi_rvalid,
    input  wire                         s_axi_rready,

    // AXI4-Lite Master (to EF_TCC32_axi)
    output wire [AXI_ID_WIDTH-1:0]      m_axi_awid,
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]      m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0]      m_axi_arid,
    output wire [LITE_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire                         m_axi_arvalid,
    input  wire                         m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]      m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rvalid,
    output wire                         m_axi_rready
);

// ====================================================================
// WRITE PATH FSM
// ====================================================================
localparam WR_IDLE = 2'b00;
localparam WR_ADDR = 2'b01;
localparam WR_DATA = 2'b10;
localparam WR_RESP = 2'b11;

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
                wr_addr_d  = s_axi_awaddr[LITE_ADDR_WIDTH-1:0];
                wr_state_d = WR_ADDR;
            end
        end
        WR_ADDR: if (m_axi_awready) wr_state_d = WR_DATA;
        WR_DATA: begin
            if (s_axi_wvalid) begin
                wr_data_d = s_axi_wdata;
                wr_strb_d = s_axi_wstrb;
                if (m_axi_wready) wr_state_d = WR_RESP;
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
    if (wr_bvalid && s_axi_bready) wr_bvalid_d = 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        wr_state  <= WR_IDLE; wr_id     <= {AXI_ID_WIDTH{1'b0}};
        wr_addr   <= {LITE_ADDR_WIDTH{1'b0}};
        wr_data   <= {AXI_DATA_WIDTH{1'b0}};
        wr_strb   <= {AXI_STRB_WIDTH{1'b0}};
        wr_bresp  <= 2'b0;    wr_bvalid <= 1'b0;
    end else begin
        wr_state  <= wr_state_d; wr_id    <= wr_id_d;
        wr_addr   <= wr_addr_d;  wr_data  <= wr_data_d;
        wr_strb   <= wr_strb_d;  wr_bresp <= wr_bresp_d;
        wr_bvalid <= wr_bvalid_d;
    end
end

assign s_axi_awready = (wr_state == WR_IDLE) && s_axi_awvalid;
assign s_axi_wready  = (wr_state == WR_DATA) && m_axi_wready;
assign s_axi_bid     = wr_id;
assign s_axi_bresp   = wr_bresp;
assign s_axi_bvalid  = wr_bvalid;

assign m_axi_awid    = wr_id;
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
localparam RD_ADDR = 2'b01;
localparam RD_DATA = 2'b10;
localparam RD_RESP = 2'b11;

reg [1:0]                  rd_state, rd_state_d;
reg [AXI_ID_WIDTH-1:0]     rd_id,    rd_id_d;
reg [LITE_ADDR_WIDTH-1:0]  rd_addr,  rd_addr_d;
reg [AXI_DATA_WIDTH-1:0]   rd_data,  rd_data_d;
reg [1:0]                  rd_rresp, rd_rresp_d;
reg                        rd_rvalid, rd_rvalid_d;

always @(*) begin
    rd_state_d  = rd_state;  rd_id_d     = rd_id;
    rd_addr_d   = rd_addr;   rd_data_d   = rd_data;
    rd_rresp_d  = rd_rresp;  rd_rvalid_d = rd_rvalid;
    case (rd_state)
        RD_IDLE: begin
            rd_rvalid_d = 1'b0;
            if (s_axi_arvalid) begin
                rd_id_d    = s_axi_arid;
                rd_addr_d  = s_axi_araddr[LITE_ADDR_WIDTH-1:0];
                rd_state_d = RD_ADDR;
            end
        end
        RD_ADDR: if (m_axi_arready) rd_state_d = RD_DATA;
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
    if (!rstn) begin
        rd_state  <= RD_IDLE; rd_id     <= {AXI_ID_WIDTH{1'b0}};
        rd_addr   <= {LITE_ADDR_WIDTH{1'b0}};
        rd_data   <= {AXI_DATA_WIDTH{1'b0}};
        rd_rresp  <= 2'b0;    rd_rvalid <= 1'b0;
    end else begin
        rd_state  <= rd_state_d; rd_id    <= rd_id_d;
        rd_addr   <= rd_addr_d;  rd_data  <= rd_data_d;
        rd_rresp  <= rd_rresp_d; rd_rvalid <= rd_rvalid_d;
    end
end

assign s_axi_arready = (rd_state == RD_IDLE) && s_axi_arvalid;
assign s_axi_rid     = rd_id;
assign s_axi_rdata   = rd_data;
assign s_axi_rresp   = rd_rresp;
assign s_axi_rlast   = 1'b1;
assign s_axi_rvalid  = rd_rvalid;

assign m_axi_arid    = rd_id;
assign m_axi_araddr  = rd_addr;
assign m_axi_arvalid = (rd_state == RD_ADDR);
assign m_axi_rready  = (rd_state == RD_DATA);

endmodule

`default_nettype wire
