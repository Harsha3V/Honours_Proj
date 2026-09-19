/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_interconnect_uart_top.v
 * Description    : Integration top-level connecting:
 *                    - axi_interconnect_wrap_2x8 as AXI Master (M00 port)
 *                    - axi_uart_top              as AXI Slave
 *
 * Address Map:
 *   UART is mapped to M00 of the interconnect
 *   M00_BASE_ADDR = 32'h0000_0000
 *   M00_ADDR_WIDTH = 24 (16MB region)
 *
 *   UART Register offsets (from UART base):
 *     0x00 = RBR/THR  (RX data / TX data)
 *     0x04 = IER      (Interrupt Enable)
 *     0x08 = BAUD     (Baud Divisor, DLAB=1)
 *     0x0C = LCR      (Line Control)
 *     0x14 = LSR      (Line Status)
 *
 * Parameter Notes:
 *   Interconnect ID_WIDTH  = 8  (extended to 12 for UART with zero-padding)
 *   Interconnect ADDR_WIDTH = 32 (UART uses lower 5 bits [4:0])
 *   Data width = 32 bits (matches on both sides)
 *
 * Clock Domains:
 *   clk       → AXI clock (axi_aclk_i + fixed_clk_i of UART)
 *   rstn      → Active-low reset
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_interconnect_uart_top #(
    // ----------------------------------------------------------------
    // Interconnect parameters
    // ----------------------------------------------------------------
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter ID_WIDTH      = 8,
    parameter STRB_WIDTH    = DATA_WIDTH/8,

    // ----------------------------------------------------------------
    // UART base address on the interconnect
    // ----------------------------------------------------------------
    parameter [ADDR_WIDTH-1:0] UART_BASE_ADDR  = 32'h0000_0000,
    parameter                  UART_ADDR_WIDTH = 24  // 16MB region
)(
    // ----------------------------------------------------------------
    // Global signals
    // ----------------------------------------------------------------
    input  wire         clk,        // single clock for both domains
    input  wire         rstn,       // active-low reset

    // ----------------------------------------------------------------
    // AXI Slave port (S00) — connects to CPU/testbench Master 0
    // ----------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]      s00_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_awaddr,
    input  wire [7:0]               s00_axi_awlen,
    input  wire [2:0]               s00_axi_awsize,
    input  wire [1:0]               s00_axi_awburst,
    input  wire                     s00_axi_awlock,
    input  wire [3:0]               s00_axi_awcache,
    input  wire [2:0]               s00_axi_awprot,
    input  wire [3:0]               s00_axi_awqos,
    input  wire                     s00_axi_awvalid,
    output wire                     s00_axi_awready,
    input  wire [DATA_WIDTH-1:0]    s00_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s00_axi_wstrb,
    input  wire                     s00_axi_wlast,
    input  wire                     s00_axi_wvalid,
    output wire                     s00_axi_wready,
    output wire [ID_WIDTH-1:0]      s00_axi_bid,
    output wire [1:0]               s00_axi_bresp,
    output wire                     s00_axi_bvalid,
    input  wire                     s00_axi_bready,
    input  wire [ID_WIDTH-1:0]      s00_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_araddr,
    input  wire [7:0]               s00_axi_arlen,
    input  wire [2:0]               s00_axi_arsize,
    input  wire [1:0]               s00_axi_arburst,
    input  wire                     s00_axi_arlock,
    input  wire [3:0]               s00_axi_arcache,
    input  wire [2:0]               s00_axi_arprot,
    input  wire [3:0]               s00_axi_arqos,
    input  wire                     s00_axi_arvalid,
    output wire                     s00_axi_arready,
    output wire [ID_WIDTH-1:0]      s00_axi_rid,
    output wire [DATA_WIDTH-1:0]    s00_axi_rdata,
    output wire [1:0]               s00_axi_rresp,
    output wire                     s00_axi_rlast,
    output wire                     s00_axi_rvalid,
    input  wire                     s00_axi_rready,

    // ----------------------------------------------------------------
    // UART serial interface (external pins)
    // ----------------------------------------------------------------
    input  wire         uart_rx_i,          // serial RX input
    output wire         uart_tx_o,          // serial TX output
    output wire         uart_interrupt_o    // RX data ready interrupt
);

// ====================================================================
// Internal wires: Interconnect M00 <-> UART Slave
// ====================================================================

// AW channel
wire [ID_WIDTH-1:0]     m00_awid;
wire [ADDR_WIDTH-1:0]   m00_awaddr;
wire [7:0]              m00_awlen;
wire [2:0]              m00_awsize;
wire [1:0]              m00_awburst;
wire                    m00_awlock;
wire [3:0]              m00_awcache;
wire [2:0]              m00_awprot;
wire [3:0]              m00_awqos;
wire [3:0]              m00_awregion;
wire                    m00_awvalid;
wire                    m00_awready;

// W channel
wire [DATA_WIDTH-1:0]   m00_wdata;
wire [STRB_WIDTH-1:0]   m00_wstrb;
wire                    m00_wlast;
wire                    m00_wvalid;
wire                    m00_wready;

// B channel
wire [ID_WIDTH-1:0]     m00_bid;
wire [1:0]              m00_bresp;
wire                    m00_bvalid;
wire                    m00_bready;

// AR channel
wire [ID_WIDTH-1:0]     m00_arid;
wire [ADDR_WIDTH-1:0]   m00_araddr;
wire [7:0]              m00_arlen;
wire [2:0]              m00_arsize;
wire [1:0]              m00_arburst;
wire                    m00_arlock;
wire [3:0]              m00_arcache;
wire [2:0]              m00_arprot;
wire [3:0]              m00_arqos;
wire [3:0]              m00_arregion;
wire                    m00_arvalid;
wire                    m00_arready;

// R channel
wire [ID_WIDTH-1:0]     m00_rid;
wire [DATA_WIDTH-1:0]   m00_rdata;
wire [1:0]              m00_rresp;
wire                    m00_rlast;
wire                    m00_rvalid;
wire                    m00_rready;

// Unused master ports (M01-M07) — tied off
wire [ID_WIDTH-1:0]     unused_awid    = {ID_WIDTH{1'b0}};
wire [ADDR_WIDTH-1:0]   unused_awaddr  = {ADDR_WIDTH{1'b0}};
wire [7:0]              unused_awlen   = 8'h0;
wire [2:0]              unused_awsize  = 3'b010;
wire [1:0]              unused_awburst = 2'b01;
wire                    unused_awlock  = 1'b0;
wire [3:0]              unused_awcache = 4'h0;
wire [2:0]              unused_awprot  = 3'h0;
wire [3:0]              unused_awqos   = 4'h0;
wire                    unused_awvalid = 1'b0;
wire [DATA_WIDTH-1:0]   unused_wdata   = {DATA_WIDTH{1'b0}};
wire [STRB_WIDTH-1:0]   unused_wstrb   = {STRB_WIDTH{1'b1}};
wire                    unused_wlast   = 1'b1;
wire                    unused_wvalid  = 1'b0;
wire                    unused_bready  = 1'b1;
wire                    unused_arvalid = 1'b0;
wire [ID_WIDTH-1:0]     unused_arid    = {ID_WIDTH{1'b0}};
wire [ADDR_WIDTH-1:0]   unused_araddr  = {ADDR_WIDTH{1'b0}};
wire [7:0]              unused_arlen   = 8'h0;
wire [2:0]              unused_arsize  = 3'b010;
wire [1:0]              unused_arburst = 2'b01;
wire                    unused_arlock  = 1'b0;
wire [3:0]              unused_arcache = 4'h0;
wire [2:0]              unused_arprot  = 3'h0;
wire [3:0]              unused_arqos   = 4'h0;
wire                    unused_rready  = 1'b1;

// ====================================================================
// Bridge wires: Bridge → UART
// ====================================================================
wire [11:0] uart_awid;
wire [4:0]  uart_awaddr;
wire        uart_awvalid;
wire        uart_awready;

wire [31:0] uart_wdata;
wire [3:0]  uart_wstrb;
wire        uart_wvalid;
wire        uart_wready;

wire [11:0] uart_bid;
wire [1:0]  uart_bresp;
wire        uart_bvalid;
wire        uart_bready;

wire [11:0] uart_arid;
wire [4:0]  uart_araddr;
wire        uart_arvalid;
wire        uart_arready;

wire [11:0] uart_rid;
wire [31:0] uart_rdata;
wire [1:0]  uart_rresp;
wire        uart_rvalid;
wire        uart_rready;

// ====================================================================
// AXI4 to AXI4-Lite Bridge
// Interconnect M00 (AXI4) → Bridge → UART (AXI4-Lite)
// ====================================================================
axi_to_axilite_uart_bridge #(
    .AXI_ID_WIDTH    (8),
    .AXI_ADDR_WIDTH  (32),
    .AXI_DATA_WIDTH  (32),
    .LITE_ID_WIDTH   (12),
    .LITE_ADDR_WIDTH (5)
) u_bridge (
    .clk             (clk),
    .rstn            (rstn),

    // AXI4 Slave side (from Interconnect M00)
    .s_axi_awid      (m00_awid),
    .s_axi_awaddr    (m00_awaddr),
    .s_axi_awlen     (m00_awlen),
    .s_axi_awsize    (m00_awsize),
    .s_axi_awburst   (m00_awburst),
    .s_axi_awvalid   (m00_awvalid),
    .s_axi_awready   (m00_awready),
    .s_axi_wdata     (m00_wdata),
    .s_axi_wstrb     (m00_wstrb),
    .s_axi_wlast     (m00_wlast),
    .s_axi_wvalid    (m00_wvalid),
    .s_axi_wready    (m00_wready),
    .s_axi_bid       (m00_bid),
    .s_axi_bresp     (m00_bresp),
    .s_axi_bvalid    (m00_bvalid),
    .s_axi_bready    (m00_bready),
    .s_axi_arid      (m00_arid),
    .s_axi_araddr    (m00_araddr),
    .s_axi_arlen     (m00_arlen),
    .s_axi_arsize    (m00_arsize),
    .s_axi_arburst   (m00_arburst),
    .s_axi_arvalid   (m00_arvalid),
    .s_axi_arready   (m00_arready),
    .s_axi_rid       (m00_rid),
    .s_axi_rdata     (m00_rdata),
    .s_axi_rresp     (m00_rresp),
    .s_axi_rlast     (m00_rlast),
    .s_axi_rvalid    (m00_rvalid),
    .s_axi_rready    (m00_rready),

    // AXI4-Lite Master side (to UART)
    .m_axi_awid      (uart_awid),
    .m_axi_awaddr    (uart_awaddr),
    .m_axi_awvalid   (uart_awvalid),
    .m_axi_awready   (uart_awready),
    .m_axi_wdata     (uart_wdata),
    .m_axi_wstrb     (uart_wstrb),
    .m_axi_wvalid    (uart_wvalid),
    .m_axi_wready    (uart_wready),
    .m_axi_bid       (uart_bid),
    .m_axi_bresp     (uart_bresp),
    .m_axi_bvalid    (uart_bvalid),
    .m_axi_bready    (uart_bready),
    .m_axi_arid      (uart_arid),
    .m_axi_araddr    (uart_araddr),
    .m_axi_arvalid   (uart_arvalid),
    .m_axi_arready   (uart_arready),
    .m_axi_rid       (uart_rid),
    .m_axi_rdata     (uart_rdata),
    .m_axi_rresp     (uart_rresp),
    .m_axi_rvalid    (uart_rvalid),
    .m_axi_rready    (uart_rready)
);
// Only M00 is used (connected to UART)
// M01-M07 are tied off
// ====================================================================
axi_interconnect_wrap_2x8 #(
    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),
    .STRB_WIDTH         (STRB_WIDTH),
    .ID_WIDTH           (ID_WIDTH),
    .AWUSER_ENABLE      (0),
    .WUSER_ENABLE       (0),
    .BUSER_ENABLE       (0),
    .ARUSER_ENABLE      (0),
    .RUSER_ENABLE       (0),
    .FORWARD_ID         (0),
    .M_REGIONS          (1),
    // M00 = UART
    .M00_BASE_ADDR      (UART_BASE_ADDR),
    .M00_ADDR_WIDTH     ({1{32'd24}}),
    .M00_CONNECT_READ   (2'b01),  // connect to S00 only
    .M00_CONNECT_WRITE  (2'b01),  // connect to S00 only
    // M01-M07 = unused, set to non-overlapping addresses
    .M01_BASE_ADDR      (32'h0100_0000), .M01_ADDR_WIDTH ({1{32'd24}}),
    .M02_BASE_ADDR      (32'h0200_0000), .M02_ADDR_WIDTH ({1{32'd24}}),
    .M03_BASE_ADDR      (32'h0300_0000), .M03_ADDR_WIDTH ({1{32'd24}}),
    .M04_BASE_ADDR      (32'h0400_0000), .M04_ADDR_WIDTH ({1{32'd24}}),
    .M05_BASE_ADDR      (32'h0500_0000), .M05_ADDR_WIDTH ({1{32'd24}}),
    .M06_BASE_ADDR      (32'h0600_0000), .M06_ADDR_WIDTH ({1{32'd24}}),
    .M07_BASE_ADDR      (32'h0700_0000), .M07_ADDR_WIDTH ({1{32'd24}})
) u_interconnect (
    .clk                (clk),
    .rst                (~rstn),      // interconnect uses active-high reset

    // S00 — external master (CPU/TB)
    .s00_axi_awid       (s00_axi_awid),
    .s00_axi_awaddr     (s00_axi_awaddr),
    .s00_axi_awlen      (s00_axi_awlen),
    .s00_axi_awsize     (s00_axi_awsize),
    .s00_axi_awburst    (s00_axi_awburst),
    .s00_axi_awlock     (s00_axi_awlock),
    .s00_axi_awcache    (s00_axi_awcache),
    .s00_axi_awprot     (s00_axi_awprot),
    .s00_axi_awqos      (s00_axi_awqos),
    .s00_axi_awuser     (1'b0),
    .s00_axi_awvalid    (s00_axi_awvalid),
    .s00_axi_awready    (s00_axi_awready),
    .s00_axi_wdata      (s00_axi_wdata),
    .s00_axi_wstrb      (s00_axi_wstrb),
    .s00_axi_wlast      (s00_axi_wlast),
    .s00_axi_wuser      (1'b0),
    .s00_axi_wvalid     (s00_axi_wvalid),
    .s00_axi_wready     (s00_axi_wready),
    .s00_axi_bid        (s00_axi_bid),
    .s00_axi_bresp      (s00_axi_bresp),
    .s00_axi_buser      (),
    .s00_axi_bvalid     (s00_axi_bvalid),
    .s00_axi_bready     (s00_axi_bready),
    .s00_axi_arid       (s00_axi_arid),
    .s00_axi_araddr     (s00_axi_araddr),
    .s00_axi_arlen      (s00_axi_arlen),
    .s00_axi_arsize     (s00_axi_arsize),
    .s00_axi_arburst    (s00_axi_arburst),
    .s00_axi_arlock     (s00_axi_arlock),
    .s00_axi_arcache    (s00_axi_arcache),
    .s00_axi_arprot     (s00_axi_arprot),
    .s00_axi_arqos      (s00_axi_arqos),
    .s00_axi_aruser     (1'b0),
    .s00_axi_arvalid    (s00_axi_arvalid),
    .s00_axi_arready    (s00_axi_arready),
    .s00_axi_rid        (s00_axi_rid),
    .s00_axi_rdata      (s00_axi_rdata),
    .s00_axi_rresp      (s00_axi_rresp),
    .s00_axi_rlast      (s00_axi_rlast),
    .s00_axi_ruser      (),
    .s00_axi_rvalid     (s00_axi_rvalid),
    .s00_axi_rready     (s00_axi_rready),

    // S01 — tied off (unused second master)
    .s01_axi_awid       (unused_awid),
    .s01_axi_awaddr     (unused_awaddr),
    .s01_axi_awlen      (unused_awlen),
    .s01_axi_awsize     (unused_awsize),
    .s01_axi_awburst    (unused_awburst),
    .s01_axi_awlock     (unused_awlock),
    .s01_axi_awcache    (unused_awcache),
    .s01_axi_awprot     (unused_awprot),
    .s01_axi_awqos      (unused_awqos),
    .s01_axi_awuser     (1'b0),
    .s01_axi_awvalid    (unused_awvalid),
    .s01_axi_awready    (),
    .s01_axi_wdata      (unused_wdata),
    .s01_axi_wstrb      (unused_wstrb),
    .s01_axi_wlast      (unused_wlast),
    .s01_axi_wuser      (1'b0),
    .s01_axi_wvalid     (unused_wvalid),
    .s01_axi_wready     (),
    .s01_axi_bid        (),
    .s01_axi_bresp      (),
    .s01_axi_buser      (),
    .s01_axi_bvalid     (),
    .s01_axi_bready     (unused_bready),
    .s01_axi_arid       (unused_arid),
    .s01_axi_araddr     (unused_araddr),
    .s01_axi_arlen      (unused_arlen),
    .s01_axi_arsize     (unused_arsize),
    .s01_axi_arburst    (unused_arburst),
    .s01_axi_arlock     (unused_arlock),
    .s01_axi_arcache    (unused_arcache),
    .s01_axi_arprot     (unused_arprot),
    .s01_axi_arqos      (unused_arqos),
    .s01_axi_aruser     (1'b0),
    .s01_axi_arvalid    (unused_arvalid),
    .s01_axi_arready    (),
    .s01_axi_rid        (),
    .s01_axi_rdata      (),
    .s01_axi_rresp      (),
    .s01_axi_rlast      (),
    .s01_axi_ruser      (),
    .s01_axi_rvalid     (),
    .s01_axi_rready     (unused_rready),

    // M00 — UART slave
    .m00_axi_awid       (m00_awid),
    .m00_axi_awaddr     (m00_awaddr),
    .m00_axi_awlen      (m00_awlen),
    .m00_axi_awsize     (m00_awsize),
    .m00_axi_awburst    (m00_awburst),
    .m00_axi_awlock     (m00_awlock),
    .m00_axi_awcache    (m00_awcache),
    .m00_axi_awprot     (m00_awprot),
    .m00_axi_awqos      (m00_awqos),
    .m00_axi_awregion   (m00_awregion),
    .m00_axi_awuser     (),
    .m00_axi_awvalid    (m00_awvalid),
    .m00_axi_awready    (m00_awready),
    .m00_axi_wdata      (m00_wdata),
    .m00_axi_wstrb      (m00_wstrb),
    .m00_axi_wlast      (m00_wlast),
    .m00_axi_wuser      (),
    .m00_axi_wvalid     (m00_wvalid),
    .m00_axi_wready     (m00_wready),
    .m00_axi_bid        (m00_bid),
    .m00_axi_bresp      (m00_bresp),
    .m00_axi_buser      (1'b0),
    .m00_axi_bvalid     (m00_bvalid),
    .m00_axi_bready     (m00_bready),
    .m00_axi_arid       (m00_arid),
    .m00_axi_araddr     (m00_araddr),
    .m00_axi_arlen      (m00_arlen),
    .m00_axi_arsize     (m00_arsize),
    .m00_axi_arburst    (m00_arburst),
    .m00_axi_arlock     (m00_arlock),
    .m00_axi_arcache    (m00_arcache),
    .m00_axi_arprot     (m00_arprot),
    .m00_axi_arqos      (m00_arqos),
    .m00_axi_arregion   (m00_arregion),
    .m00_axi_aruser     (),
    .m00_axi_arvalid    (m00_arvalid),
    .m00_axi_arready    (m00_arready),
    .m00_axi_rid        (m00_rid),
    .m00_axi_rdata      (m00_rdata),
    .m00_axi_rresp      (m00_rresp),
    .m00_axi_rlast      (m00_rlast),
    .m00_axi_ruser      (1'b0),
    .m00_axi_rvalid     (m00_rvalid),
    .m00_axi_rready     (m00_rready),

    // M01-M07 — tied off (outputs ignored)
    .m01_axi_awid(), .m01_axi_awaddr(), .m01_axi_awlen(), .m01_axi_awsize(),
    .m01_axi_awburst(), .m01_axi_awlock(), .m01_axi_awcache(), .m01_axi_awprot(),
    .m01_axi_awqos(), .m01_axi_awregion(), .m01_axi_awuser(), .m01_axi_awvalid(),
    .m01_axi_awready(1'b1), .m01_axi_wdata(), .m01_axi_wstrb(), .m01_axi_wlast(),
    .m01_axi_wuser(), .m01_axi_wvalid(), .m01_axi_wready(1'b1),
    .m01_axi_bid(8'h0), .m01_axi_bresp(2'b0), .m01_axi_buser(1'b0),
    .m01_axi_bvalid(1'b0), .m01_axi_bready(), .m01_axi_arid(), .m01_axi_araddr(),
    .m01_axi_arlen(), .m01_axi_arsize(), .m01_axi_arburst(), .m01_axi_arlock(),
    .m01_axi_arcache(), .m01_axi_arprot(), .m01_axi_arqos(), .m01_axi_arregion(),
    .m01_axi_aruser(), .m01_axi_arvalid(), .m01_axi_arready(1'b1),
    .m01_axi_rid(8'h0), .m01_axi_rdata(32'h0), .m01_axi_rresp(2'b0),
    .m01_axi_rlast(1'b1), .m01_axi_ruser(1'b0), .m01_axi_rvalid(1'b0), .m01_axi_rready(),

    .m02_axi_awid(), .m02_axi_awaddr(), .m02_axi_awlen(), .m02_axi_awsize(),
    .m02_axi_awburst(), .m02_axi_awlock(), .m02_axi_awcache(), .m02_axi_awprot(),
    .m02_axi_awqos(), .m02_axi_awregion(), .m02_axi_awuser(), .m02_axi_awvalid(),
    .m02_axi_awready(1'b1), .m02_axi_wdata(), .m02_axi_wstrb(), .m02_axi_wlast(),
    .m02_axi_wuser(), .m02_axi_wvalid(), .m02_axi_wready(1'b1),
    .m02_axi_bid(8'h0), .m02_axi_bresp(2'b0), .m02_axi_buser(1'b0),
    .m02_axi_bvalid(1'b0), .m02_axi_bready(), .m02_axi_arid(), .m02_axi_araddr(),
    .m02_axi_arlen(), .m02_axi_arsize(), .m02_axi_arburst(), .m02_axi_arlock(),
    .m02_axi_arcache(), .m02_axi_arprot(), .m02_axi_arqos(), .m02_axi_arregion(),
    .m02_axi_aruser(), .m02_axi_arvalid(), .m02_axi_arready(1'b1),
    .m02_axi_rid(8'h0), .m02_axi_rdata(32'h0), .m02_axi_rresp(2'b0),
    .m02_axi_rlast(1'b1), .m02_axi_ruser(1'b0), .m02_axi_rvalid(1'b0), .m02_axi_rready(),

    .m03_axi_awid(), .m03_axi_awaddr(), .m03_axi_awlen(), .m03_axi_awsize(),
    .m03_axi_awburst(), .m03_axi_awlock(), .m03_axi_awcache(), .m03_axi_awprot(),
    .m03_axi_awqos(), .m03_axi_awregion(), .m03_axi_awuser(), .m03_axi_awvalid(),
    .m03_axi_awready(1'b1), .m03_axi_wdata(), .m03_axi_wstrb(), .m03_axi_wlast(),
    .m03_axi_wuser(), .m03_axi_wvalid(), .m03_axi_wready(1'b1),
    .m03_axi_bid(8'h0), .m03_axi_bresp(2'b0), .m03_axi_buser(1'b0),
    .m03_axi_bvalid(1'b0), .m03_axi_bready(), .m03_axi_arid(), .m03_axi_araddr(),
    .m03_axi_arlen(), .m03_axi_arsize(), .m03_axi_arburst(), .m03_axi_arlock(),
    .m03_axi_arcache(), .m03_axi_arprot(), .m03_axi_arqos(), .m03_axi_arregion(),
    .m03_axi_aruser(), .m03_axi_arvalid(), .m03_axi_arready(1'b1),
    .m03_axi_rid(8'h0), .m03_axi_rdata(32'h0), .m03_axi_rresp(2'b0),
    .m03_axi_rlast(1'b1), .m03_axi_ruser(1'b0), .m03_axi_rvalid(1'b0), .m03_axi_rready(),

    .m04_axi_awid(), .m04_axi_awaddr(), .m04_axi_awlen(), .m04_axi_awsize(),
    .m04_axi_awburst(), .m04_axi_awlock(), .m04_axi_awcache(), .m04_axi_awprot(),
    .m04_axi_awqos(), .m04_axi_awregion(), .m04_axi_awuser(), .m04_axi_awvalid(),
    .m04_axi_awready(1'b1), .m04_axi_wdata(), .m04_axi_wstrb(), .m04_axi_wlast(),
    .m04_axi_wuser(), .m04_axi_wvalid(), .m04_axi_wready(1'b1),
    .m04_axi_bid(8'h0), .m04_axi_bresp(2'b0), .m04_axi_buser(1'b0),
    .m04_axi_bvalid(1'b0), .m04_axi_bready(), .m04_axi_arid(), .m04_axi_araddr(),
    .m04_axi_arlen(), .m04_axi_arsize(), .m04_axi_arburst(), .m04_axi_arlock(),
    .m04_axi_arcache(), .m04_axi_arprot(), .m04_axi_arqos(), .m04_axi_arregion(),
    .m04_axi_aruser(), .m04_axi_arvalid(), .m04_axi_arready(1'b1),
    .m04_axi_rid(8'h0), .m04_axi_rdata(32'h0), .m04_axi_rresp(2'b0),
    .m04_axi_rlast(1'b1), .m04_axi_ruser(1'b0), .m04_axi_rvalid(1'b0), .m04_axi_rready(),

    .m05_axi_awid(), .m05_axi_awaddr(), .m05_axi_awlen(), .m05_axi_awsize(),
    .m05_axi_awburst(), .m05_axi_awlock(), .m05_axi_awcache(), .m05_axi_awprot(),
    .m05_axi_awqos(), .m05_axi_awregion(), .m05_axi_awuser(), .m05_axi_awvalid(),
    .m05_axi_awready(1'b1), .m05_axi_wdata(), .m05_axi_wstrb(), .m05_axi_wlast(),
    .m05_axi_wuser(), .m05_axi_wvalid(), .m05_axi_wready(1'b1),
    .m05_axi_bid(8'h0), .m05_axi_bresp(2'b0), .m05_axi_buser(1'b0),
    .m05_axi_bvalid(1'b0), .m05_axi_bready(), .m05_axi_arid(), .m05_axi_araddr(),
    .m05_axi_arlen(), .m05_axi_arsize(), .m05_axi_arburst(), .m05_axi_arlock(),
    .m05_axi_arcache(), .m05_axi_arprot(), .m05_axi_arqos(), .m05_axi_arregion(),
    .m05_axi_aruser(), .m05_axi_arvalid(), .m05_axi_arready(1'b1),
    .m05_axi_rid(8'h0), .m05_axi_rdata(32'h0), .m05_axi_rresp(2'b0),
    .m05_axi_rlast(1'b1), .m05_axi_ruser(1'b0), .m05_axi_rvalid(1'b0), .m05_axi_rready(),

    .m06_axi_awid(), .m06_axi_awaddr(), .m06_axi_awlen(), .m06_axi_awsize(),
    .m06_axi_awburst(), .m06_axi_awlock(), .m06_axi_awcache(), .m06_axi_awprot(),
    .m06_axi_awqos(), .m06_axi_awregion(), .m06_axi_awuser(), .m06_axi_awvalid(),
    .m06_axi_awready(1'b1), .m06_axi_wdata(), .m06_axi_wstrb(), .m06_axi_wlast(),
    .m06_axi_wuser(), .m06_axi_wvalid(), .m06_axi_wready(1'b1),
    .m06_axi_bid(8'h0), .m06_axi_bresp(2'b0), .m06_axi_buser(1'b0),
    .m06_axi_bvalid(1'b0), .m06_axi_bready(), .m06_axi_arid(), .m06_axi_araddr(),
    .m06_axi_arlen(), .m06_axi_arsize(), .m06_axi_arburst(), .m06_axi_arlock(),
    .m06_axi_arcache(), .m06_axi_arprot(), .m06_axi_arqos(), .m06_axi_arregion(),
    .m06_axi_aruser(), .m06_axi_arvalid(), .m06_axi_arready(1'b1),
    .m06_axi_rid(8'h0), .m06_axi_rdata(32'h0), .m06_axi_rresp(2'b0),
    .m06_axi_rlast(1'b1), .m06_axi_ruser(1'b0), .m06_axi_rvalid(1'b0), .m06_axi_rready(),

    .m07_axi_awid(), .m07_axi_awaddr(), .m07_axi_awlen(), .m07_axi_awsize(),
    .m07_axi_awburst(), .m07_axi_awlock(), .m07_axi_awcache(), .m07_axi_awprot(),
    .m07_axi_awqos(), .m07_axi_awregion(), .m07_axi_awuser(), .m07_axi_awvalid(),
    .m07_axi_awready(1'b1), .m07_axi_wdata(), .m07_axi_wstrb(), .m07_axi_wlast(),
    .m07_axi_wuser(), .m07_axi_wvalid(), .m07_axi_wready(1'b1),
    .m07_axi_bid(8'h0), .m07_axi_bresp(2'b0), .m07_axi_buser(1'b0),
    .m07_axi_bvalid(1'b0), .m07_axi_bready(), .m07_axi_arid(), .m07_axi_araddr(),
    .m07_axi_arlen(), .m07_axi_arsize(), .m07_axi_arburst(), .m07_axi_arlock(),
    .m07_axi_arcache(), .m07_axi_arprot(), .m07_axi_arqos(), .m07_axi_arregion(),
    .m07_axi_aruser(), .m07_axi_arvalid(), .m07_axi_arready(1'b1),
    .m07_axi_rid(8'h0), .m07_axi_rdata(32'h0), .m07_axi_rresp(2'b0),
    .m07_axi_rlast(1'b1), .m07_axi_ruser(1'b0), .m07_axi_rvalid(1'b0), .m07_axi_rready()
);

// ====================================================================
// UART AXI4-Lite Slave (connected via bridge)
// ====================================================================
axi_uart_top u_uart (
    .fixed_clk_i        (clk),
    .axi_aclk_i         (clk),
    .axi_aresetn_i      (rstn),

    // AR channel
    .axi_arid_i         (uart_arid),
    .axi_araddr_i       (uart_araddr),
    .axi_arvalid_i      (uart_arvalid),
    .axi_arready_o      (uart_arready),

    // R channel
    .axi_rid_o          (uart_rid),
    .axi_rdata_o        (uart_rdata),
    .axi_rresp_o        (uart_rresp),
    .axi_rvalid_o       (uart_rvalid),
    .axi_rready_i       (uart_rready),

    // AW channel
    .axi_awid_i         (uart_awid),
    .axi_awaddr_i       (uart_awaddr),
    .axi_awvalid_i      (uart_awvalid),
    .axi_awready_o      (uart_awready),

    // W channel
    .axi_wdata_i        (uart_wdata),
    .axi_wstrb_i        (uart_wstrb),
    .axi_wvalid_i       (uart_wvalid),
    .axi_wready_o       (uart_wready),

    // B channel
    .axi_bid_o          (uart_bid),
    .axi_bresp_o        (uart_bresp),
    .axi_bvalid_o       (uart_bvalid),
    .axi_bready_i       (uart_bready),

    // UART serial
    .uart_rx_i          (uart_rx_i),
    .uart_tx_o          (uart_tx_o),
    .read_interrupt_o   (uart_interrupt_o)
);

endmodule

`default_nettype wire
