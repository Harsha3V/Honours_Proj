/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_interconnect_uart_top.v
 * Description    : Integration top-level connecting:
 *                    - axi_interconnect_wrap_2x8  (2 masters × 8 slaves)
 *                    - axi_uart_top               (AXI4-Lite UART — M02)
 *                    - AES_AXI                    (AXI4-Lite AES-128 — M03)
 *
 * Address Map (AXI Slave Slots):
 *   M00 = 0x0000_0000  TIED OFF  (Boot ROM — not needed, VeeR boots from ICCM)
 *   M01 = 0x0100_0000  TIED OFF  (Ext DMEM — not needed, VeeR uses internal DCCM)
 *   M02 = 0x0200_0000  UART      ✅ Connected
 *   M03 = 0x0300_0000  AES-128   ✅ Connected
 *   M04 = 0x0400_0000  TIED OFF  (DMA config — not yet built)
 *   M05 = 0x0500_0000  TIED OFF  (Timer     — not yet built)
 *   M06 = 0x0600_0000  TIED OFF  (GPIO      — not yet built)
 *   M07 = 0x0700_0000  TIED OFF  (SPI       — not yet built)
 *
 * UART Register offsets (from 0x0200_0000):
 *   0x00 = RBR/THR   0x04 = IER   0x08 = BAUD
 *   0x0C = LCR       0x14 = LSR
 *
 * AES Register offsets (from 0x0300_0000):
 *   Encrypt: 0x00=CSR  0x04-0x10=KEY  0x14-0x20=TEXTIN  0x24-0x30=TEXTOUT
 *   Decrypt: 0x40=CSR  0x44-0x50=KEY  0x54-0x60=TEXTIN  0x64-0x70=TEXTOUT
 *
 * Bridge details:
 *   UART bridge : LITE_ADDR_WIDTH=5  (ID 8→12-bit extended)
 *   AES  bridge : LITE_ADDR_WIDTH=7  (no ID ports on AES_AXI — tracked internally)
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_interconnect_uart_top #(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter ID_WIDTH      = 8,
    parameter STRB_WIDTH    = DATA_WIDTH/8,

    // Base addresses
    parameter [ADDR_WIDTH-1:0] UART_BASE_ADDR = 32'h0200_0000,
    parameter                  UART_ADDR_WIDTH = 24,
    parameter [ADDR_WIDTH-1:0] AES_BASE_ADDR  = 32'h0300_0000,
    parameter                  AES_ADDR_WIDTH  = 24
)(
    input  wire         clk,
    input  wire         rstn,   // active-low reset

    // ----------------------------------------------------------------
    // AXI Slave port S00 — CPU / testbench master
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
    // UART external pins
    // ----------------------------------------------------------------
    input  wire         uart_rx_i,
    output wire         uart_tx_o,
    output wire         uart_interrupt_o
);

// ====================================================================
// Tie-off wires for unused master/slave ports
// ====================================================================
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
// M02 wires: Interconnect M02 <-> UART Bridge
// ====================================================================
wire [ID_WIDTH-1:0]     m02_awid;
wire [ADDR_WIDTH-1:0]   m02_awaddr;
wire [7:0]              m02_awlen;
wire [2:0]              m02_awsize;
wire [1:0]              m02_awburst;
wire                    m02_awlock;
wire [3:0]              m02_awcache;
wire [2:0]              m02_awprot;
wire [3:0]              m02_awqos;
wire [3:0]              m02_awregion;
wire                    m02_awvalid;
wire                    m02_awready;
wire [DATA_WIDTH-1:0]   m02_wdata;
wire [STRB_WIDTH-1:0]   m02_wstrb;
wire                    m02_wlast;
wire                    m02_wvalid;
wire                    m02_wready;
wire [ID_WIDTH-1:0]     m02_bid;
wire [1:0]              m02_bresp;
wire                    m02_bvalid;
wire                    m02_bready;
wire [ID_WIDTH-1:0]     m02_arid;
wire [ADDR_WIDTH-1:0]   m02_araddr;
wire [7:0]              m02_arlen;
wire [2:0]              m02_arsize;
wire [1:0]              m02_arburst;
wire                    m02_arlock;
wire [3:0]              m02_arcache;
wire [2:0]              m02_arprot;
wire [3:0]              m02_arqos;
wire [3:0]              m02_arregion;
wire                    m02_arvalid;
wire                    m02_arready;
wire [ID_WIDTH-1:0]     m02_rid;
wire [DATA_WIDTH-1:0]   m02_rdata;
wire [1:0]              m02_rresp;
wire                    m02_rlast;
wire                    m02_rvalid;
wire                    m02_rready;

// ====================================================================
// UART Bridge → UART slave wires
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
// M03 wires: Interconnect M03 <-> AES Bridge
// ====================================================================
wire [ID_WIDTH-1:0]     m03_awid;
wire [ADDR_WIDTH-1:0]   m03_awaddr;
wire [7:0]              m03_awlen;
wire [2:0]              m03_awsize;
wire [1:0]              m03_awburst;
wire                    m03_awlock;
wire [3:0]              m03_awcache;
wire [2:0]              m03_awprot;
wire [3:0]              m03_awqos;
wire [3:0]              m03_awregion;
wire                    m03_awvalid;
wire                    m03_awready;
wire [DATA_WIDTH-1:0]   m03_wdata;
wire [STRB_WIDTH-1:0]   m03_wstrb;
wire                    m03_wlast;
wire                    m03_wvalid;
wire                    m03_wready;
wire [ID_WIDTH-1:0]     m03_bid;
wire [1:0]              m03_bresp;
wire                    m03_bvalid;
wire                    m03_bready;
wire [ID_WIDTH-1:0]     m03_arid;
wire [ADDR_WIDTH-1:0]   m03_araddr;
wire [7:0]              m03_arlen;
wire [2:0]              m03_arsize;
wire [1:0]              m03_arburst;
wire                    m03_arlock;
wire [3:0]              m03_arcache;
wire [2:0]              m03_arprot;
wire [3:0]              m03_arqos;
wire [3:0]              m03_arregion;
wire                    m03_arvalid;
wire                    m03_arready;
wire [ID_WIDTH-1:0]     m03_rid;
wire [DATA_WIDTH-1:0]   m03_rdata;
wire [1:0]              m03_rresp;
wire                    m03_rlast;
wire                    m03_rvalid;
wire                    m03_rready;

// ====================================================================
// AES Bridge → AES slave wires (AES_AXI has no ID ports)
// ====================================================================
wire [6:0]  aes_awaddr;
wire        aes_awvalid;
wire        aes_awready;
wire [31:0] aes_wdata;
wire [3:0]  aes_wstrb;
wire        aes_wvalid;
wire        aes_wready;
wire [1:0]  aes_bresp;
wire        aes_bvalid;
wire        aes_bready;
wire [6:0]  aes_araddr;
wire        aes_arvalid;
wire        aes_arready;
wire [31:0] aes_rdata;
wire [1:0]  aes_rresp;
wire        aes_rvalid;
wire        aes_rready;

// ====================================================================
// AXI4 Interconnect (2 masters × 8 slaves)
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
    // M00 tied off — Boot ROM not needed (VeeR boots from ICCM)
    .M00_BASE_ADDR      (32'h0000_0000), .M00_ADDR_WIDTH ({1{32'd24}}),
    .M00_CONNECT_READ   (2'b00),
    .M00_CONNECT_WRITE  (2'b00),
    // M01 tied off — External DMEM not needed (VeeR uses internal DCCM)
    .M01_BASE_ADDR      (32'h0100_0000), .M01_ADDR_WIDTH ({1{32'd24}}),
    .M01_CONNECT_READ   (2'b00),
    .M01_CONNECT_WRITE  (2'b00),
    // M02 = UART at 0x0200_0000
    .M02_BASE_ADDR      (UART_BASE_ADDR), .M02_ADDR_WIDTH ({1{32'd24}}),
    .M02_CONNECT_READ   (2'b01),
    .M02_CONNECT_WRITE  (2'b01),
    // M03 = AES at 0x0300_0000
    .M03_BASE_ADDR      (AES_BASE_ADDR),  .M03_ADDR_WIDTH ({1{32'd24}}),
    .M03_CONNECT_READ   (2'b01),
    .M03_CONNECT_WRITE  (2'b01),
    // M04–M07 tied off (Timer, DMA, GPIO, SPI — not yet built)
    .M04_BASE_ADDR      (32'h0400_0000), .M04_ADDR_WIDTH ({1{32'd24}}),
    .M04_CONNECT_READ   (2'b00), .M04_CONNECT_WRITE (2'b00),
    .M05_BASE_ADDR      (32'h0500_0000), .M05_ADDR_WIDTH ({1{32'd24}}),
    .M05_CONNECT_READ   (2'b00), .M05_CONNECT_WRITE (2'b00),
    .M06_BASE_ADDR      (32'h0600_0000), .M06_ADDR_WIDTH ({1{32'd24}}),
    .M06_CONNECT_READ   (2'b00), .M06_CONNECT_WRITE (2'b00),
    .M07_BASE_ADDR      (32'h0700_0000), .M07_ADDR_WIDTH ({1{32'd24}}),
    .M07_CONNECT_READ   (2'b00), .M07_CONNECT_WRITE (2'b00)
) u_interconnect (
    .clk                (clk),
    .rst                (~rstn),

    // ---- S00 — CPU / testbench master ----
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

    // ---- S01 — DMA master (tied off, not yet built) ----
    .s01_axi_awid       (unused_awid),    .s01_axi_awaddr  (unused_awaddr),
    .s01_axi_awlen      (unused_awlen),   .s01_axi_awsize  (unused_awsize),
    .s01_axi_awburst    (unused_awburst), .s01_axi_awlock  (unused_awlock),
    .s01_axi_awcache    (unused_awcache), .s01_axi_awprot  (unused_awprot),
    .s01_axi_awqos      (unused_awqos),   .s01_axi_awuser  (1'b0),
    .s01_axi_awvalid    (unused_awvalid), .s01_axi_awready (),
    .s01_axi_wdata      (unused_wdata),   .s01_axi_wstrb   (unused_wstrb),
    .s01_axi_wlast      (unused_wlast),   .s01_axi_wuser   (1'b0),
    .s01_axi_wvalid     (unused_wvalid),  .s01_axi_wready  (),
    .s01_axi_bid        (),               .s01_axi_bresp   (),
    .s01_axi_buser      (),               .s01_axi_bvalid  (),
    .s01_axi_bready     (unused_bready),
    .s01_axi_arid       (unused_arid),    .s01_axi_araddr  (unused_araddr),
    .s01_axi_arlen      (unused_arlen),   .s01_axi_arsize  (unused_arsize),
    .s01_axi_arburst    (unused_arburst), .s01_axi_arlock  (unused_arlock),
    .s01_axi_arcache    (unused_arcache), .s01_axi_arprot  (unused_arprot),
    .s01_axi_arqos      (unused_arqos),   .s01_axi_aruser  (1'b0),
    .s01_axi_arvalid    (unused_arvalid), .s01_axi_arready (),
    .s01_axi_rid        (),               .s01_axi_rdata   (),
    .s01_axi_rresp      (),               .s01_axi_rlast   (),
    .s01_axi_ruser      (),               .s01_axi_rvalid  (),
    .s01_axi_rready     (unused_rready),

    // ---- M00 — tied off ----
    .m00_axi_awid(), .m00_axi_awaddr(), .m00_axi_awlen(), .m00_axi_awsize(),
    .m00_axi_awburst(), .m00_axi_awlock(), .m00_axi_awcache(), .m00_axi_awprot(),
    .m00_axi_awqos(), .m00_axi_awregion(), .m00_axi_awuser(), .m00_axi_awvalid(),
    .m00_axi_awready(1'b1), .m00_axi_wdata(), .m00_axi_wstrb(), .m00_axi_wlast(),
    .m00_axi_wuser(), .m00_axi_wvalid(), .m00_axi_wready(1'b1),
    .m00_axi_bid(8'h0), .m00_axi_bresp(2'b0), .m00_axi_buser(1'b0),
    .m00_axi_bvalid(1'b0), .m00_axi_bready(),
    .m00_axi_arid(), .m00_axi_araddr(), .m00_axi_arlen(), .m00_axi_arsize(),
    .m00_axi_arburst(), .m00_axi_arlock(), .m00_axi_arcache(), .m00_axi_arprot(),
    .m00_axi_arqos(), .m00_axi_arregion(), .m00_axi_aruser(), .m00_axi_arvalid(),
    .m00_axi_arready(1'b1), .m00_axi_rid(8'h0), .m00_axi_rdata(32'h0),
    .m00_axi_rresp(2'b0), .m00_axi_rlast(1'b1), .m00_axi_ruser(1'b0),
    .m00_axi_rvalid(1'b0), .m00_axi_rready(),

    // ---- M01 — tied off ----
    .m01_axi_awid(), .m01_axi_awaddr(), .m01_axi_awlen(), .m01_axi_awsize(),
    .m01_axi_awburst(), .m01_axi_awlock(), .m01_axi_awcache(), .m01_axi_awprot(),
    .m01_axi_awqos(), .m01_axi_awregion(), .m01_axi_awuser(), .m01_axi_awvalid(),
    .m01_axi_awready(1'b1), .m01_axi_wdata(), .m01_axi_wstrb(), .m01_axi_wlast(),
    .m01_axi_wuser(), .m01_axi_wvalid(), .m01_axi_wready(1'b1),
    .m01_axi_bid(8'h0), .m01_axi_bresp(2'b0), .m01_axi_buser(1'b0),
    .m01_axi_bvalid(1'b0), .m01_axi_bready(),
    .m01_axi_arid(), .m01_axi_araddr(), .m01_axi_arlen(), .m01_axi_arsize(),
    .m01_axi_arburst(), .m01_axi_arlock(), .m01_axi_arcache(), .m01_axi_arprot(),
    .m01_axi_arqos(), .m01_axi_arregion(), .m01_axi_aruser(), .m01_axi_arvalid(),
    .m01_axi_arready(1'b1), .m01_axi_rid(8'h0), .m01_axi_rdata(32'h0),
    .m01_axi_rresp(2'b0), .m01_axi_rlast(1'b1), .m01_axi_ruser(1'b0),
    .m01_axi_rvalid(1'b0), .m01_axi_rready(),

    // ---- M02 — UART ----
    .m02_axi_awid       (m02_awid),     .m02_axi_awaddr  (m02_awaddr),
    .m02_axi_awlen      (m02_awlen),    .m02_axi_awsize  (m02_awsize),
    .m02_axi_awburst    (m02_awburst),  .m02_axi_awlock  (m02_awlock),
    .m02_axi_awcache    (m02_awcache),  .m02_axi_awprot  (m02_awprot),
    .m02_axi_awqos      (m02_awqos),    .m02_axi_awregion(m02_awregion),
    .m02_axi_awuser     (),             .m02_axi_awvalid (m02_awvalid),
    .m02_axi_awready    (m02_awready),
    .m02_axi_wdata      (m02_wdata),    .m02_axi_wstrb   (m02_wstrb),
    .m02_axi_wlast      (m02_wlast),    .m02_axi_wuser   (),
    .m02_axi_wvalid     (m02_wvalid),   .m02_axi_wready  (m02_wready),
    .m02_axi_bid        (m02_bid),      .m02_axi_bresp   (m02_bresp),
    .m02_axi_buser      (1'b0),         .m02_axi_bvalid  (m02_bvalid),
    .m02_axi_bready     (m02_bready),
    .m02_axi_arid       (m02_arid),     .m02_axi_araddr  (m02_araddr),
    .m02_axi_arlen      (m02_arlen),    .m02_axi_arsize  (m02_arsize),
    .m02_axi_arburst    (m02_arburst),  .m02_axi_arlock  (m02_arlock),
    .m02_axi_arcache    (m02_arcache),  .m02_axi_arprot  (m02_arprot),
    .m02_axi_arqos      (m02_arqos),    .m02_axi_arregion(m02_arregion),
    .m02_axi_aruser     (),             .m02_axi_arvalid (m02_arvalid),
    .m02_axi_arready    (m02_arready),
    .m02_axi_rid        (m02_rid),      .m02_axi_rdata   (m02_rdata),
    .m02_axi_rresp      (m02_rresp),    .m02_axi_rlast   (m02_rlast),
    .m02_axi_ruser      (1'b0),         .m02_axi_rvalid  (m02_rvalid),
    .m02_axi_rready     (m02_rready),

    // ---- M03 — AES ----
    .m03_axi_awid       (m03_awid),     .m03_axi_awaddr  (m03_awaddr),
    .m03_axi_awlen      (m03_awlen),    .m03_axi_awsize  (m03_awsize),
    .m03_axi_awburst    (m03_awburst),  .m03_axi_awlock  (m03_awlock),
    .m03_axi_awcache    (m03_awcache),  .m03_axi_awprot  (m03_awprot),
    .m03_axi_awqos      (m03_awqos),    .m03_axi_awregion(m03_awregion),
    .m03_axi_awuser     (),             .m03_axi_awvalid (m03_awvalid),
    .m03_axi_awready    (m03_awready),
    .m03_axi_wdata      (m03_wdata),    .m03_axi_wstrb   (m03_wstrb),
    .m03_axi_wlast      (m03_wlast),    .m03_axi_wuser   (),
    .m03_axi_wvalid     (m03_wvalid),   .m03_axi_wready  (m03_wready),
    .m03_axi_bid        (m03_bid),      .m03_axi_bresp   (m03_bresp),
    .m03_axi_buser      (1'b0),         .m03_axi_bvalid  (m03_bvalid),
    .m03_axi_bready     (m03_bready),
    .m03_axi_arid       (m03_arid),     .m03_axi_araddr  (m03_araddr),
    .m03_axi_arlen      (m03_arlen),    .m03_axi_arsize  (m03_arsize),
    .m03_axi_arburst    (m03_arburst),  .m03_axi_arlock  (m03_arlock),
    .m03_axi_arcache    (m03_arcache),  .m03_axi_arprot  (m03_arprot),
    .m03_axi_arqos      (m03_arqos),    .m03_axi_arregion(m03_arregion),
    .m03_axi_aruser     (),             .m03_axi_arvalid (m03_arvalid),
    .m03_axi_arready    (m03_arready),
    .m03_axi_rid        (m03_rid),      .m03_axi_rdata   (m03_rdata),
    .m03_axi_rresp      (m03_rresp),    .m03_axi_rlast   (m03_rlast),
    .m03_axi_ruser      (1'b0),         .m03_axi_rvalid  (m03_rvalid),
    .m03_axi_rready     (m03_rready),

    // ---- M04 — tied off (DMA config) ----
    .m04_axi_awid(), .m04_axi_awaddr(), .m04_axi_awlen(), .m04_axi_awsize(),
    .m04_axi_awburst(), .m04_axi_awlock(), .m04_axi_awcache(), .m04_axi_awprot(),
    .m04_axi_awqos(), .m04_axi_awregion(), .m04_axi_awuser(), .m04_axi_awvalid(),
    .m04_axi_awready(1'b1), .m04_axi_wdata(), .m04_axi_wstrb(), .m04_axi_wlast(),
    .m04_axi_wuser(), .m04_axi_wvalid(), .m04_axi_wready(1'b1),
    .m04_axi_bid(8'h0), .m04_axi_bresp(2'b0), .m04_axi_buser(1'b0),
    .m04_axi_bvalid(1'b0), .m04_axi_bready(),
    .m04_axi_arid(), .m04_axi_araddr(), .m04_axi_arlen(), .m04_axi_arsize(),
    .m04_axi_arburst(), .m04_axi_arlock(), .m04_axi_arcache(), .m04_axi_arprot(),
    .m04_axi_arqos(), .m04_axi_arregion(), .m04_axi_aruser(), .m04_axi_arvalid(),
    .m04_axi_arready(1'b1), .m04_axi_rid(8'h0), .m04_axi_rdata(32'h0),
    .m04_axi_rresp(2'b0), .m04_axi_rlast(1'b1), .m04_axi_ruser(1'b0),
    .m04_axi_rvalid(1'b0), .m04_axi_rready(),

    // ---- M05 — tied off (Timer) ----
    .m05_axi_awid(), .m05_axi_awaddr(), .m05_axi_awlen(), .m05_axi_awsize(),
    .m05_axi_awburst(), .m05_axi_awlock(), .m05_axi_awcache(), .m05_axi_awprot(),
    .m05_axi_awqos(), .m05_axi_awregion(), .m05_axi_awuser(), .m05_axi_awvalid(),
    .m05_axi_awready(1'b1), .m05_axi_wdata(), .m05_axi_wstrb(), .m05_axi_wlast(),
    .m05_axi_wuser(), .m05_axi_wvalid(), .m05_axi_wready(1'b1),
    .m05_axi_bid(8'h0), .m05_axi_bresp(2'b0), .m05_axi_buser(1'b0),
    .m05_axi_bvalid(1'b0), .m05_axi_bready(),
    .m05_axi_arid(), .m05_axi_araddr(), .m05_axi_arlen(), .m05_axi_arsize(),
    .m05_axi_arburst(), .m05_axi_arlock(), .m05_axi_arcache(), .m05_axi_arprot(),
    .m05_axi_arqos(), .m05_axi_arregion(), .m05_axi_aruser(), .m05_axi_arvalid(),
    .m05_axi_arready(1'b1), .m05_axi_rid(8'h0), .m05_axi_rdata(32'h0),
    .m05_axi_rresp(2'b0), .m05_axi_rlast(1'b1), .m05_axi_ruser(1'b0),
    .m05_axi_rvalid(1'b0), .m05_axi_rready(),

    // ---- M06 — tied off (GPIO) ----
    .m06_axi_awid(), .m06_axi_awaddr(), .m06_axi_awlen(), .m06_axi_awsize(),
    .m06_axi_awburst(), .m06_axi_awlock(), .m06_axi_awcache(), .m06_axi_awprot(),
    .m06_axi_awqos(), .m06_axi_awregion(), .m06_axi_awuser(), .m06_axi_awvalid(),
    .m06_axi_awready(1'b1), .m06_axi_wdata(), .m06_axi_wstrb(), .m06_axi_wlast(),
    .m06_axi_wuser(), .m06_axi_wvalid(), .m06_axi_wready(1'b1),
    .m06_axi_bid(8'h0), .m06_axi_bresp(2'b0), .m06_axi_buser(1'b0),
    .m06_axi_bvalid(1'b0), .m06_axi_bready(),
    .m06_axi_arid(), .m06_axi_araddr(), .m06_axi_arlen(), .m06_axi_arsize(),
    .m06_axi_arburst(), .m06_axi_arlock(), .m06_axi_arcache(), .m06_axi_arprot(),
    .m06_axi_arqos(), .m06_axi_arregion(), .m06_axi_aruser(), .m06_axi_arvalid(),
    .m06_axi_arready(1'b1), .m06_axi_rid(8'h0), .m06_axi_rdata(32'h0),
    .m06_axi_rresp(2'b0), .m06_axi_rlast(1'b1), .m06_axi_ruser(1'b0),
    .m06_axi_rvalid(1'b0), .m06_axi_rready(),

    // ---- M07 — tied off (SPI) ----
    .m07_axi_awid(), .m07_axi_awaddr(), .m07_axi_awlen(), .m07_axi_awsize(),
    .m07_axi_awburst(), .m07_axi_awlock(), .m07_axi_awcache(), .m07_axi_awprot(),
    .m07_axi_awqos(), .m07_axi_awregion(), .m07_axi_awuser(), .m07_axi_awvalid(),
    .m07_axi_awready(1'b1), .m07_axi_wdata(), .m07_axi_wstrb(), .m07_axi_wlast(),
    .m07_axi_wuser(), .m07_axi_wvalid(), .m07_axi_wready(1'b1),
    .m07_axi_bid(8'h0), .m07_axi_bresp(2'b0), .m07_axi_buser(1'b0),
    .m07_axi_bvalid(1'b0), .m07_axi_bready(),
    .m07_axi_arid(), .m07_axi_araddr(), .m07_axi_arlen(), .m07_axi_arsize(),
    .m07_axi_arburst(), .m07_axi_arlock(), .m07_axi_arcache(), .m07_axi_arprot(),
    .m07_axi_arqos(), .m07_axi_arregion(), .m07_axi_aruser(), .m07_axi_arvalid(),
    .m07_axi_arready(1'b1), .m07_axi_rid(8'h0), .m07_axi_rdata(32'h0),
    .m07_axi_rresp(2'b0), .m07_axi_rlast(1'b1), .m07_axi_ruser(1'b0),
    .m07_axi_rvalid(1'b0), .m07_axi_rready()
);

// ====================================================================
// AXI4 → AXI4-Lite Bridge for UART (M02)
// ====================================================================
axi_to_axilite_uart_bridge #(
    .AXI_ID_WIDTH    (8),
    .AXI_ADDR_WIDTH  (32),
    .AXI_DATA_WIDTH  (32),
    .LITE_ID_WIDTH   (12),
    .LITE_ADDR_WIDTH (5)
) u_uart_bridge (
    .clk             (clk),
    .rstn            (rstn),

    .s_axi_awid      (m02_awid),    .s_axi_awaddr  (m02_awaddr),
    .s_axi_awlen     (m02_awlen),   .s_axi_awsize  (m02_awsize),
    .s_axi_awburst   (m02_awburst), .s_axi_awvalid (m02_awvalid),
    .s_axi_awready   (m02_awready),
    .s_axi_wdata     (m02_wdata),   .s_axi_wstrb   (m02_wstrb),
    .s_axi_wlast     (m02_wlast),   .s_axi_wvalid  (m02_wvalid),
    .s_axi_wready    (m02_wready),
    .s_axi_bid       (m02_bid),     .s_axi_bresp   (m02_bresp),
    .s_axi_bvalid    (m02_bvalid),  .s_axi_bready  (m02_bready),
    .s_axi_arid      (m02_arid),    .s_axi_araddr  (m02_araddr),
    .s_axi_arlen     (m02_arlen),   .s_axi_arsize  (m02_arsize),
    .s_axi_arburst   (m02_arburst), .s_axi_arvalid (m02_arvalid),
    .s_axi_arready   (m02_arready),
    .s_axi_rid       (m02_rid),     .s_axi_rdata   (m02_rdata),
    .s_axi_rresp     (m02_rresp),   .s_axi_rlast   (m02_rlast),
    .s_axi_rvalid    (m02_rvalid),  .s_axi_rready  (m02_rready),

    .m_axi_awid      (uart_awid),   .m_axi_awaddr  (uart_awaddr),
    .m_axi_awvalid   (uart_awvalid),.m_axi_awready (uart_awready),
    .m_axi_wdata     (uart_wdata),  .m_axi_wstrb   (uart_wstrb),
    .m_axi_wvalid    (uart_wvalid), .m_axi_wready  (uart_wready),
    .m_axi_bid       (uart_bid),    .m_axi_bresp   (uart_bresp),
    .m_axi_bvalid    (uart_bvalid), .m_axi_bready  (uart_bready),
    .m_axi_arid      (uart_arid),   .m_axi_araddr  (uart_araddr),
    .m_axi_arvalid   (uart_arvalid),.m_axi_arready (uart_arready),
    .m_axi_rid       (uart_rid),    .m_axi_rdata   (uart_rdata),
    .m_axi_rresp     (uart_rresp),  .m_axi_rvalid  (uart_rvalid),
    .m_axi_rready    (uart_rready)
);

// ====================================================================
// UART AXI4-Lite Slave (M02 — 0x0200_0000)
// ====================================================================
axi_uart_top u_uart (
    .fixed_clk_i        (clk),
    .axi_aclk_i         (clk),
    .axi_aresetn_i      (rstn),
    .axi_arid_i         (uart_arid),   .axi_araddr_i  (uart_araddr),
    .axi_arvalid_i      (uart_arvalid),.axi_arready_o (uart_arready),
    .axi_rid_o          (uart_rid),    .axi_rdata_o   (uart_rdata),
    .axi_rresp_o        (uart_rresp),  .axi_rvalid_o  (uart_rvalid),
    .axi_rready_i       (uart_rready),
    .axi_awid_i         (uart_awid),   .axi_awaddr_i  (uart_awaddr),
    .axi_awvalid_i      (uart_awvalid),.axi_awready_o (uart_awready),
    .axi_wdata_i        (uart_wdata),  .axi_wstrb_i   (uart_wstrb),
    .axi_wvalid_i       (uart_wvalid), .axi_wready_o  (uart_wready),
    .axi_bid_o          (uart_bid),    .axi_bresp_o   (uart_bresp),
    .axi_bvalid_o       (uart_bvalid), .axi_bready_i  (uart_bready),
    .uart_rx_i          (uart_rx_i),
    .uart_tx_o          (uart_tx_o),
    .read_interrupt_o   (uart_interrupt_o)
);

// ====================================================================
// AXI4 → AXI4-Lite Bridge for AES (M03)
// ====================================================================
axi_to_axilite_aes_bridge #(
    .AXI_ID_WIDTH    (8),
    .AXI_ADDR_WIDTH  (32),
    .AXI_DATA_WIDTH  (32),
    .LITE_ADDR_WIDTH (7)
) u_aes_bridge (
    .clk             (clk),
    .rstn            (rstn),

    .s_axi_awid      (m03_awid),    .s_axi_awaddr  (m03_awaddr),
    .s_axi_awlen     (m03_awlen),   .s_axi_awsize  (m03_awsize),
    .s_axi_awburst   (m03_awburst), .s_axi_awvalid (m03_awvalid),
    .s_axi_awready   (m03_awready),
    .s_axi_wdata     (m03_wdata),   .s_axi_wstrb   (m03_wstrb),
    .s_axi_wlast     (m03_wlast),   .s_axi_wvalid  (m03_wvalid),
    .s_axi_wready    (m03_wready),
    .s_axi_bid       (m03_bid),     .s_axi_bresp   (m03_bresp),
    .s_axi_bvalid    (m03_bvalid),  .s_axi_bready  (m03_bready),
    .s_axi_arid      (m03_arid),    .s_axi_araddr  (m03_araddr),
    .s_axi_arlen     (m03_arlen),   .s_axi_arsize  (m03_arsize),
    .s_axi_arburst   (m03_arburst), .s_axi_arvalid (m03_arvalid),
    .s_axi_arready   (m03_arready),
    .s_axi_rid       (m03_rid),     .s_axi_rdata   (m03_rdata),
    .s_axi_rresp     (m03_rresp),   .s_axi_rlast   (m03_rlast),
    .s_axi_rvalid    (m03_rvalid),  .s_axi_rready  (m03_rready),

    .m_axi_awaddr    (aes_awaddr),  .m_axi_awvalid (aes_awvalid),
    .m_axi_awready   (aes_awready),
    .m_axi_wdata     (aes_wdata),   .m_axi_wstrb   (aes_wstrb),
    .m_axi_wvalid    (aes_wvalid),  .m_axi_wready  (aes_wready),
    .m_axi_bresp     (aes_bresp),   .m_axi_bvalid  (aes_bvalid),
    .m_axi_bready    (aes_bready),
    .m_axi_araddr    (aes_araddr),  .m_axi_arvalid (aes_arvalid),
    .m_axi_arready   (aes_arready),
    .m_axi_rdata     (aes_rdata),   .m_axi_rresp   (aes_rresp),
    .m_axi_rvalid    (aes_rvalid),  .m_axi_rready  (aes_rready)
);

// ====================================================================
// AES-128 AXI4-Lite Slave (M03 — 0x0300_0000)
// ====================================================================
AES_AXI #(
    .C_S_AXI_DATA_WIDTH (32),
    .C_S_AXI_ADDR_WIDTH (7)
) u_aes (
    .S_AXI_ACLK     (clk),
    .S_AXI_ARESETN  (rstn),

    .S_AXI_AWADDR   (aes_awaddr),
    .S_AXI_AWVALID  (aes_awvalid),
    .S_AXI_AWREADY  (aes_awready),

    .S_AXI_WDATA    (aes_wdata),
    .S_AXI_WSTRB    (aes_wstrb),
    .S_AXI_WVALID   (aes_wvalid),
    .S_AXI_WREADY   (aes_wready),

    .S_AXI_BRESP    (aes_bresp),
    .S_AXI_BVALID   (aes_bvalid),
    .S_AXI_BREADY   (aes_bready),

    .S_AXI_ARADDR   (aes_araddr),
    .S_AXI_ARVALID  (aes_arvalid),
    .S_AXI_ARREADY  (aes_arready),

    .S_AXI_RDATA    (aes_rdata),
    .S_AXI_RRESP    (aes_rresp),
    .S_AXI_RVALID   (aes_rvalid),
    .S_AXI_RREADY   (aes_rready)
);

endmodule

`default_nettype wire
