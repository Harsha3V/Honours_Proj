/* -----------------------------------------------------------------------------
 * Project        : Honours Project
 * File           : axi_interconnect_uart_top.v
 * Description    : Integration top-level — AXI4 interconnect + all 6 IPs
 *
 * FINAL Address Map:
 *   M00 = 0x0000_0000  AES-128 Engine       ✅ Connected
 *   M01 = 0x0100_0000  DMA Controller CSR   ⚠ Tied off (flat wrapper pending)
 *   M02 = 0x0200_0000  SPI Master           ✅ Connected
 *   M03 = 0x0300_0000  UART                 ✅ Connected
 *   M04 = 0x0400_0000  Timer (EF_TCC32)     ✅ Connected
 *   M05 = 0x0500_0000  GPIO (EF_GPIO8)      ✅ Connected
 *   M06 = 0x0600_0000  Tied off
 *   M07 = 0x0700_0000  Tied off
 *
 * Masters:
 *   S00 = VeeR EL2 CPU (LSU AXI4)
 *   S01 = DMA AXI4 master (tied off — flat wrapper pending)
 *
 * Bridges used:
 *   AES   : axi_to_axilite_aes_bridge   (LITE_ADDR_WIDTH=7,  no ID on AES_AXI)
 *   UART  : axi_to_axilite_uart_bridge  (LITE_ADDR_WIDTH=5,  LITE_ID_WIDTH=12)
 *   Timer : axi_to_axilite_timer_bridge (LITE_ADDR_WIDTH=16, IDs pass through)
 *   GPIO  : axi_to_axilite_gpio_bridge  (LITE_ADDR_WIDTH=16, IDs pass through)
 *   SPI   : direct (spi_axi_top has its own AXI4-Lite slave port with IDs)
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_interconnect_uart_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
    input  wire         clk,
    input  wire         rstn,

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
    output wire         uart_irq_o,

    // ----------------------------------------------------------------
    // SPI external pins
    // ----------------------------------------------------------------
    output wire         spi_clk_o,
    output wire         spi_mosi_o,
    input  wire         spi_miso_i,
    output wire         spi_cs_n_o,

    // ----------------------------------------------------------------
    // GPIO external pins
    // ----------------------------------------------------------------
    input  wire [7:0]   gpio_in_i,
    output wire [7:0]   gpio_out_o,
    output wire [7:0]   gpio_oe_o,
    output wire         gpio_irq_o,

    // ----------------------------------------------------------------
    // Timer external
    // ----------------------------------------------------------------
    input  wire         timer_ctr_in_i,
    output wire         timer_irq_o
);

// ====================================================================
// Tie-off wires for unused master/slave ports
// ====================================================================
wire [ID_WIDTH-1:0]   toff_id    = {ID_WIDTH{1'b0}};
wire [ADDR_WIDTH-1:0] toff_addr  = {ADDR_WIDTH{1'b0}};
wire [DATA_WIDTH-1:0] toff_data  = {DATA_WIDTH{1'b0}};
wire [STRB_WIDTH-1:0] toff_strb  = {STRB_WIDTH{1'b1}};
wire [7:0]            toff_len   = 8'h0;
wire [2:0]            toff_size  = 3'b010;
wire [1:0]            toff_burst = 2'b01;

// ====================================================================
// Per-slot interconnect wires — macro-style for cleanliness
// ====================================================================
// Each slot: awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
//            awqos, awregion, awvalid, awready,
//            wdata, wstrb, wlast, wvalid, wready,
//            bid, bresp, bvalid, bready,
//            arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
//            arqos, arregion, arvalid, arready,
//            rid, rdata, rresp, rlast, rvalid, rready

// ---- M00: AES ----
wire [ID_WIDTH-1:0]   m00_awid;   wire [ADDR_WIDTH-1:0] m00_awaddr;
wire [7:0]            m00_awlen;  wire [2:0]            m00_awsize;
wire [1:0]            m00_awburst;wire                  m00_awlock;
wire [3:0]            m00_awcache;wire [2:0]            m00_awprot;
wire [3:0]            m00_awqos;  wire [3:0]            m00_awregion;
wire                  m00_awvalid;wire                  m00_awready;
wire [DATA_WIDTH-1:0] m00_wdata;  wire [STRB_WIDTH-1:0] m00_wstrb;
wire                  m00_wlast;  wire                  m00_wvalid;
wire                  m00_wready; wire [ID_WIDTH-1:0]   m00_bid;
wire [1:0]            m00_bresp;  wire                  m00_bvalid;
wire                  m00_bready; wire [ID_WIDTH-1:0]   m00_arid;
wire [ADDR_WIDTH-1:0] m00_araddr; wire [7:0]            m00_arlen;
wire [2:0]            m00_arsize; wire [1:0]            m00_arburst;
wire                  m00_arlock; wire [3:0]            m00_arcache;
wire [2:0]            m00_arprot; wire [3:0]            m00_arqos;
wire [3:0]            m00_arregion;wire                 m00_arvalid;
wire                  m00_arready;wire [ID_WIDTH-1:0]   m00_rid;
wire [DATA_WIDTH-1:0] m00_rdata;  wire [1:0]            m00_rresp;
wire                  m00_rlast;  wire                  m00_rvalid;
wire                  m00_rready;

// ---- M02: SPI ----
wire [ID_WIDTH-1:0]   m02_awid;   wire [ADDR_WIDTH-1:0] m02_awaddr;
wire [7:0]            m02_awlen;  wire [2:0]            m02_awsize;
wire [1:0]            m02_awburst;wire                  m02_awlock;
wire [3:0]            m02_awcache;wire [2:0]            m02_awprot;
wire [3:0]            m02_awqos;  wire [3:0]            m02_awregion;
wire                  m02_awvalid;wire                  m02_awready;
wire [DATA_WIDTH-1:0] m02_wdata;  wire [STRB_WIDTH-1:0] m02_wstrb;
wire                  m02_wlast;  wire                  m02_wvalid;
wire                  m02_wready; wire [ID_WIDTH-1:0]   m02_bid;
wire [1:0]            m02_bresp;  wire                  m02_bvalid;
wire                  m02_bready; wire [ID_WIDTH-1:0]   m02_arid;
wire [ADDR_WIDTH-1:0] m02_araddr; wire [7:0]            m02_arlen;
wire [2:0]            m02_arsize; wire [1:0]            m02_arburst;
wire                  m02_arlock; wire [3:0]            m02_arcache;
wire [2:0]            m02_arprot; wire [3:0]            m02_arqos;
wire [3:0]            m02_arregion;wire                 m02_arvalid;
wire                  m02_arready;wire [ID_WIDTH-1:0]   m02_rid;
wire [DATA_WIDTH-1:0] m02_rdata;  wire [1:0]            m02_rresp;
wire                  m02_rlast;  wire                  m02_rvalid;
wire                  m02_rready;

// ---- M03: UART ----
wire [ID_WIDTH-1:0]   m03_awid;   wire [ADDR_WIDTH-1:0] m03_awaddr;
wire [7:0]            m03_awlen;  wire [2:0]            m03_awsize;
wire [1:0]            m03_awburst;wire                  m03_awlock;
wire [3:0]            m03_awcache;wire [2:0]            m03_awprot;
wire [3:0]            m03_awqos;  wire [3:0]            m03_awregion;
wire                  m03_awvalid;wire                  m03_awready;
wire [DATA_WIDTH-1:0] m03_wdata;  wire [STRB_WIDTH-1:0] m03_wstrb;
wire                  m03_wlast;  wire                  m03_wvalid;
wire                  m03_wready; wire [ID_WIDTH-1:0]   m03_bid;
wire [1:0]            m03_bresp;  wire                  m03_bvalid;
wire                  m03_bready; wire [ID_WIDTH-1:0]   m03_arid;
wire [ADDR_WIDTH-1:0] m03_araddr; wire [7:0]            m03_arlen;
wire [2:0]            m03_arsize; wire [1:0]            m03_arburst;
wire                  m03_arlock; wire [3:0]            m03_arcache;
wire [2:0]            m03_arprot; wire [3:0]            m03_arqos;
wire [3:0]            m03_arregion;wire                 m03_arvalid;
wire                  m03_arready;wire [ID_WIDTH-1:0]   m03_rid;
wire [DATA_WIDTH-1:0] m03_rdata;  wire [1:0]            m03_rresp;
wire                  m03_rlast;  wire                  m03_rvalid;
wire                  m03_rready;

// ---- M04: Timer ----
wire [ID_WIDTH-1:0]   m04_awid;   wire [ADDR_WIDTH-1:0] m04_awaddr;
wire [7:0]            m04_awlen;  wire [2:0]            m04_awsize;
wire [1:0]            m04_awburst;wire                  m04_awlock;
wire [3:0]            m04_awcache;wire [2:0]            m04_awprot;
wire [3:0]            m04_awqos;  wire [3:0]            m04_awregion;
wire                  m04_awvalid;wire                  m04_awready;
wire [DATA_WIDTH-1:0] m04_wdata;  wire [STRB_WIDTH-1:0] m04_wstrb;
wire                  m04_wlast;  wire                  m04_wvalid;
wire                  m04_wready; wire [ID_WIDTH-1:0]   m04_bid;
wire [1:0]            m04_bresp;  wire                  m04_bvalid;
wire                  m04_bready; wire [ID_WIDTH-1:0]   m04_arid;
wire [ADDR_WIDTH-1:0] m04_araddr; wire [7:0]            m04_arlen;
wire [2:0]            m04_arsize; wire [1:0]            m04_arburst;
wire                  m04_arlock; wire [3:0]            m04_arcache;
wire [2:0]            m04_arprot; wire [3:0]            m04_arqos;
wire [3:0]            m04_arregion;wire                 m04_arvalid;
wire                  m04_arready;wire [ID_WIDTH-1:0]   m04_rid;
wire [DATA_WIDTH-1:0] m04_rdata;  wire [1:0]            m04_rresp;
wire                  m04_rlast;  wire                  m04_rvalid;
wire                  m04_rready;

// ---- M05: GPIO ----
wire [ID_WIDTH-1:0]   m05_awid;   wire [ADDR_WIDTH-1:0] m05_awaddr;
wire [7:0]            m05_awlen;  wire [2:0]            m05_awsize;
wire [1:0]            m05_awburst;wire                  m05_awlock;
wire [3:0]            m05_awcache;wire [2:0]            m05_awprot;
wire [3:0]            m05_awqos;  wire [3:0]            m05_awregion;
wire                  m05_awvalid;wire                  m05_awready;
wire [DATA_WIDTH-1:0] m05_wdata;  wire [STRB_WIDTH-1:0] m05_wstrb;
wire                  m05_wlast;  wire                  m05_wvalid;
wire                  m05_wready; wire [ID_WIDTH-1:0]   m05_bid;
wire [1:0]            m05_bresp;  wire                  m05_bvalid;
wire                  m05_bready; wire [ID_WIDTH-1:0]   m05_arid;
wire [ADDR_WIDTH-1:0] m05_araddr; wire [7:0]            m05_arlen;
wire [2:0]            m05_arsize; wire [1:0]            m05_arburst;
wire                  m05_arlock; wire [3:0]            m05_arcache;
wire [2:0]            m05_arprot; wire [3:0]            m05_arqos;
wire [3:0]            m05_arregion;wire                 m05_arvalid;
wire                  m05_arready;wire [ID_WIDTH-1:0]   m05_rid;
wire [DATA_WIDTH-1:0] m05_rdata;  wire [1:0]            m05_rresp;
wire                  m05_rlast;  wire                  m05_rvalid;
wire                  m05_rready;

// ====================================================================
// AES Bridge → AES slave wires (AES_AXI has NO ID ports)
// ====================================================================
wire [6:0]  aes_awaddr; wire        aes_awvalid; wire        aes_awready;
wire [31:0] aes_wdata;  wire [3:0]  aes_wstrb;  wire        aes_wvalid;
wire        aes_wready; wire [1:0]  aes_bresp;  wire        aes_bvalid;
wire        aes_bready; wire [6:0]  aes_araddr; wire        aes_arvalid;
wire        aes_arready;wire [31:0] aes_rdata;  wire [1:0]  aes_rresp;
wire        aes_rvalid; wire        aes_rready;

// ====================================================================
// UART Bridge → UART slave wires
// ====================================================================
wire [11:0] uart_awid;   wire [4:0]  uart_awaddr; wire        uart_awvalid;
wire        uart_awready;wire [31:0] uart_wdata;  wire [3:0]  uart_wstrb;
wire        uart_wvalid; wire        uart_wready; wire [11:0] uart_bid;
wire [1:0]  uart_bresp;  wire        uart_bvalid; wire        uart_bready;
wire [11:0] uart_arid;   wire [4:0]  uart_araddr; wire        uart_arvalid;
wire        uart_arready;wire [11:0] uart_rid;    wire [31:0] uart_rdata;
wire [1:0]  uart_rresp;  wire        uart_rvalid; wire        uart_rready;

// ====================================================================
// Timer Bridge → Timer slave wires
// ====================================================================
wire [ID_WIDTH-1:0] tmr_awid;   wire [15:0] tmr_awaddr; wire        tmr_awvalid;
wire                tmr_awready;wire [31:0] tmr_wdata;  wire [3:0]  tmr_wstrb;
wire                tmr_wvalid; wire        tmr_wready; wire [ID_WIDTH-1:0] tmr_bid;
wire [1:0]          tmr_bresp;  wire        tmr_bvalid; wire        tmr_bready;
wire [ID_WIDTH-1:0] tmr_arid;   wire [15:0] tmr_araddr; wire        tmr_arvalid;
wire                tmr_arready;wire [ID_WIDTH-1:0] tmr_rid; wire [31:0] tmr_rdata;
wire [1:0]          tmr_rresp;  wire        tmr_rvalid; wire        tmr_rready;

// ====================================================================
// GPIO Bridge → GPIO slave wires
// ====================================================================
wire [ID_WIDTH-1:0] gpio_awid;   wire [15:0] gpio_awaddr; wire        gpio_awvalid;
wire                gpio_awready;wire [31:0] gpio_wdata;  wire [3:0]  gpio_wstrb;
wire                gpio_wvalid; wire        gpio_wready; wire [ID_WIDTH-1:0] gpio_bid;
wire [1:0]          gpio_bresp;  wire        gpio_bvalid; wire        gpio_bready;
wire [ID_WIDTH-1:0] gpio_arid;   wire [15:0] gpio_araddr; wire        gpio_arvalid;
wire                gpio_arready;wire [ID_WIDTH-1:0] gpio_rid; wire [31:0] gpio_rdata;
wire [1:0]          gpio_rresp;  wire        gpio_rvalid; wire        gpio_rready;

// ====================================================================
// AXI4 Interconnect (2 masters × 8 slaves)
// ====================================================================
axi_interconnect_wrap_2x8 #(
    .DATA_WIDTH        (DATA_WIDTH),
    .ADDR_WIDTH        (ADDR_WIDTH),
    .STRB_WIDTH        (STRB_WIDTH),
    .ID_WIDTH          (ID_WIDTH),
    .AWUSER_ENABLE     (0), .WUSER_ENABLE (0),
    .BUSER_ENABLE      (0), .ARUSER_ENABLE(0), .RUSER_ENABLE(0),
    .FORWARD_ID        (0),
    .M_REGIONS         (1),
    // M00 = AES at 0x0000_0000
    .M00_BASE_ADDR     (32'h0000_0000), .M00_ADDR_WIDTH({1{32'd24}}),
    .M00_CONNECT_READ  (2'b01),         .M00_CONNECT_WRITE(2'b01),
    // M01 = DMA CSR at 0x0100_0000 — tied off (flat wrapper pending)
    .M01_BASE_ADDR     (32'h0100_0000), .M01_ADDR_WIDTH({1{32'd24}}),
    .M01_CONNECT_READ  (2'b00),         .M01_CONNECT_WRITE(2'b00),
    // M02 = SPI at 0x0200_0000
    .M02_BASE_ADDR     (32'h0200_0000), .M02_ADDR_WIDTH({1{32'd24}}),
    .M02_CONNECT_READ  (2'b01),         .M02_CONNECT_WRITE(2'b01),
    // M03 = UART at 0x0300_0000
    .M03_BASE_ADDR     (32'h0300_0000), .M03_ADDR_WIDTH({1{32'd24}}),
    .M03_CONNECT_READ  (2'b01),         .M03_CONNECT_WRITE(2'b01),
    // M04 = Timer at 0x0400_0000
    .M04_BASE_ADDR     (32'h0400_0000), .M04_ADDR_WIDTH({1{32'd24}}),
    .M04_CONNECT_READ  (2'b01),         .M04_CONNECT_WRITE(2'b01),
    // M05 = GPIO at 0x0500_0000
    .M05_BASE_ADDR     (32'h0500_0000), .M05_ADDR_WIDTH({1{32'd24}}),
    .M05_CONNECT_READ  (2'b01),         .M05_CONNECT_WRITE(2'b01),
    // M06 / M07 tied off
    .M06_BASE_ADDR     (32'h0600_0000), .M06_ADDR_WIDTH({1{32'd24}}),
    .M06_CONNECT_READ  (2'b00),         .M06_CONNECT_WRITE(2'b00),
    .M07_BASE_ADDR     (32'h0700_0000), .M07_ADDR_WIDTH({1{32'd24}}),
    .M07_CONNECT_READ  (2'b00),         .M07_CONNECT_WRITE(2'b00)
) u_interconnect (
    .clk  (clk), .rst (~rstn),

    // ---- S00: CPU ----
    .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr),
    .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize),
    .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock),
    .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot),
    .s00_axi_awqos(s00_axi_awqos), .s00_axi_awuser(1'b0),
    .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready),
    .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb),
    .s00_axi_wlast(s00_axi_wlast), .s00_axi_wuser(1'b0),
    .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
    .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp),
    .s00_axi_buser(), .s00_axi_bvalid(s00_axi_bvalid),
    .s00_axi_bready(s00_axi_bready),
    .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr),
    .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize),
    .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
    .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
    .s00_axi_arqos(s00_axi_arqos), .s00_axi_aruser(1'b0),
    .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
    .s00_axi_rid(s00_axi_rid), .s00_axi_rdata(s00_axi_rdata),
    .s00_axi_rresp(s00_axi_rresp), .s00_axi_rlast(s00_axi_rlast),
    .s00_axi_ruser(), .s00_axi_rvalid(s00_axi_rvalid),
    .s00_axi_rready(s00_axi_rready),

    // ---- S01: DMA master (tied off) ----
    .s01_axi_awid(toff_id), .s01_axi_awaddr(toff_addr),
    .s01_axi_awlen(toff_len), .s01_axi_awsize(toff_size),
    .s01_axi_awburst(toff_burst), .s01_axi_awlock(1'b0),
    .s01_axi_awcache(4'h0), .s01_axi_awprot(3'h0),
    .s01_axi_awqos(4'h0), .s01_axi_awuser(1'b0),
    .s01_axi_awvalid(1'b0), .s01_axi_awready(),
    .s01_axi_wdata(toff_data), .s01_axi_wstrb(toff_strb),
    .s01_axi_wlast(1'b1), .s01_axi_wuser(1'b0),
    .s01_axi_wvalid(1'b0), .s01_axi_wready(),
    .s01_axi_bid(), .s01_axi_bresp(), .s01_axi_buser(),
    .s01_axi_bvalid(), .s01_axi_bready(1'b1),
    .s01_axi_arid(toff_id), .s01_axi_araddr(toff_addr),
    .s01_axi_arlen(toff_len), .s01_axi_arsize(toff_size),
    .s01_axi_arburst(toff_burst), .s01_axi_arlock(1'b0),
    .s01_axi_arcache(4'h0), .s01_axi_arprot(3'h0),
    .s01_axi_arqos(4'h0), .s01_axi_aruser(1'b0),
    .s01_axi_arvalid(1'b0), .s01_axi_arready(),
    .s01_axi_rid(), .s01_axi_rdata(), .s01_axi_rresp(),
    .s01_axi_rlast(), .s01_axi_ruser(), .s01_axi_rvalid(),
    .s01_axi_rready(1'b1),

    // ---- M00: AES ----
    .m00_axi_awid(m00_awid), .m00_axi_awaddr(m00_awaddr),
    .m00_axi_awlen(m00_awlen), .m00_axi_awsize(m00_awsize),
    .m00_axi_awburst(m00_awburst), .m00_axi_awlock(m00_awlock),
    .m00_axi_awcache(m00_awcache), .m00_axi_awprot(m00_awprot),
    .m00_axi_awqos(m00_awqos), .m00_axi_awregion(m00_awregion),
    .m00_axi_awuser(), .m00_axi_awvalid(m00_awvalid),
    .m00_axi_awready(m00_awready),
    .m00_axi_wdata(m00_wdata), .m00_axi_wstrb(m00_wstrb),
    .m00_axi_wlast(m00_wlast), .m00_axi_wuser(),
    .m00_axi_wvalid(m00_wvalid), .m00_axi_wready(m00_wready),
    .m00_axi_bid(m00_bid), .m00_axi_bresp(m00_bresp),
    .m00_axi_buser(1'b0), .m00_axi_bvalid(m00_bvalid),
    .m00_axi_bready(m00_bready),
    .m00_axi_arid(m00_arid), .m00_axi_araddr(m00_araddr),
    .m00_axi_arlen(m00_arlen), .m00_axi_arsize(m00_arsize),
    .m00_axi_arburst(m00_arburst), .m00_axi_arlock(m00_arlock),
    .m00_axi_arcache(m00_arcache), .m00_axi_arprot(m00_arprot),
    .m00_axi_arqos(m00_arqos), .m00_axi_arregion(m00_arregion),
    .m00_axi_aruser(), .m00_axi_arvalid(m00_arvalid),
    .m00_axi_arready(m00_arready),
    .m00_axi_rid(m00_rid), .m00_axi_rdata(m00_rdata),
    .m00_axi_rresp(m00_rresp), .m00_axi_rlast(m00_rlast),
    .m00_axi_ruser(1'b0), .m00_axi_rvalid(m00_rvalid),
    .m00_axi_rready(m00_rready),

    // ---- M01: DMA CSR tied off ----
    .m01_axi_awid(), .m01_axi_awaddr(), .m01_axi_awlen(), .m01_axi_awsize(),
    .m01_axi_awburst(), .m01_axi_awlock(), .m01_axi_awcache(), .m01_axi_awprot(),
    .m01_axi_awqos(), .m01_axi_awregion(), .m01_axi_awuser(), .m01_axi_awvalid(),
    .m01_axi_awready(1'b1), .m01_axi_wdata(), .m01_axi_wstrb(), .m01_axi_wlast(),
    .m01_axi_wuser(), .m01_axi_wvalid(), .m01_axi_wready(1'b1),
    .m01_axi_bid(8'h0), .m01_axi_bresp(2'b00), .m01_axi_buser(1'b0),
    .m01_axi_bvalid(1'b0), .m01_axi_bready(),
    .m01_axi_arid(), .m01_axi_araddr(), .m01_axi_arlen(), .m01_axi_arsize(),
    .m01_axi_arburst(), .m01_axi_arlock(), .m01_axi_arcache(), .m01_axi_arprot(),
    .m01_axi_arqos(), .m01_axi_arregion(), .m01_axi_aruser(), .m01_axi_arvalid(),
    .m01_axi_arready(1'b1), .m01_axi_rid(8'h0), .m01_axi_rdata(32'h0),
    .m01_axi_rresp(2'b00), .m01_axi_rlast(1'b1), .m01_axi_ruser(1'b0),
    .m01_axi_rvalid(1'b0), .m01_axi_rready(),

    // ---- M02: SPI ----
    .m02_axi_awid(m02_awid), .m02_axi_awaddr(m02_awaddr),
    .m02_axi_awlen(m02_awlen), .m02_axi_awsize(m02_awsize),
    .m02_axi_awburst(m02_awburst), .m02_axi_awlock(m02_awlock),
    .m02_axi_awcache(m02_awcache), .m02_axi_awprot(m02_awprot),
    .m02_axi_awqos(m02_awqos), .m02_axi_awregion(m02_awregion),
    .m02_axi_awuser(), .m02_axi_awvalid(m02_awvalid),
    .m02_axi_awready(m02_awready),
    .m02_axi_wdata(m02_wdata), .m02_axi_wstrb(m02_wstrb),
    .m02_axi_wlast(m02_wlast), .m02_axi_wuser(),
    .m02_axi_wvalid(m02_wvalid), .m02_axi_wready(m02_wready),
    .m02_axi_bid(m02_bid), .m02_axi_bresp(m02_bresp),
    .m02_axi_buser(1'b0), .m02_axi_bvalid(m02_bvalid),
    .m02_axi_bready(m02_bready),
    .m02_axi_arid(m02_arid), .m02_axi_araddr(m02_araddr),
    .m02_axi_arlen(m02_arlen), .m02_axi_arsize(m02_arsize),
    .m02_axi_arburst(m02_arburst), .m02_axi_arlock(m02_arlock),
    .m02_axi_arcache(m02_arcache), .m02_axi_arprot(m02_arprot),
    .m02_axi_arqos(m02_arqos), .m02_axi_arregion(m02_arregion),
    .m02_axi_aruser(), .m02_axi_arvalid(m02_arvalid),
    .m02_axi_arready(m02_arready),
    .m02_axi_rid(m02_rid), .m02_axi_rdata(m02_rdata),
    .m02_axi_rresp(m02_rresp), .m02_axi_rlast(m02_rlast),
    .m02_axi_ruser(1'b0), .m02_axi_rvalid(m02_rvalid),
    .m02_axi_rready(m02_rready),

    // ---- M03: UART ----
    .m03_axi_awid(m03_awid), .m03_axi_awaddr(m03_awaddr),
    .m03_axi_awlen(m03_awlen), .m03_axi_awsize(m03_awsize),
    .m03_axi_awburst(m03_awburst), .m03_axi_awlock(m03_awlock),
    .m03_axi_awcache(m03_awcache), .m03_axi_awprot(m03_awprot),
    .m03_axi_awqos(m03_awqos), .m03_axi_awregion(m03_awregion),
    .m03_axi_awuser(), .m03_axi_awvalid(m03_awvalid),
    .m03_axi_awready(m03_awready),
    .m03_axi_wdata(m03_wdata), .m03_axi_wstrb(m03_wstrb),
    .m03_axi_wlast(m03_wlast), .m03_axi_wuser(),
    .m03_axi_wvalid(m03_wvalid), .m03_axi_wready(m03_wready),
    .m03_axi_bid(m03_bid), .m03_axi_bresp(m03_bresp),
    .m03_axi_buser(1'b0), .m03_axi_bvalid(m03_bvalid),
    .m03_axi_bready(m03_bready),
    .m03_axi_arid(m03_arid), .m03_axi_araddr(m03_araddr),
    .m03_axi_arlen(m03_arlen), .m03_axi_arsize(m03_arsize),
    .m03_axi_arburst(m03_arburst), .m03_axi_arlock(m03_arlock),
    .m03_axi_arcache(m03_arcache), .m03_axi_arprot(m03_arprot),
    .m03_axi_arqos(m03_arqos), .m03_axi_arregion(m03_arregion),
    .m03_axi_aruser(), .m03_axi_arvalid(m03_arvalid),
    .m03_axi_arready(m03_arready),
    .m03_axi_rid(m03_rid), .m03_axi_rdata(m03_rdata),
    .m03_axi_rresp(m03_rresp), .m03_axi_rlast(m03_rlast),
    .m03_axi_ruser(1'b0), .m03_axi_rvalid(m03_rvalid),
    .m03_axi_rready(m03_rready),

    // ---- M04: Timer ----
    .m04_axi_awid(m04_awid), .m04_axi_awaddr(m04_awaddr),
    .m04_axi_awlen(m04_awlen), .m04_axi_awsize(m04_awsize),
    .m04_axi_awburst(m04_awburst), .m04_axi_awlock(m04_awlock),
    .m04_axi_awcache(m04_awcache), .m04_axi_awprot(m04_awprot),
    .m04_axi_awqos(m04_awqos), .m04_axi_awregion(m04_awregion),
    .m04_axi_awuser(), .m04_axi_awvalid(m04_awvalid),
    .m04_axi_awready(m04_awready),
    .m04_axi_wdata(m04_wdata), .m04_axi_wstrb(m04_wstrb),
    .m04_axi_wlast(m04_wlast), .m04_axi_wuser(),
    .m04_axi_wvalid(m04_wvalid), .m04_axi_wready(m04_wready),
    .m04_axi_bid(m04_bid), .m04_axi_bresp(m04_bresp),
    .m04_axi_buser(1'b0), .m04_axi_bvalid(m04_bvalid),
    .m04_axi_bready(m04_bready),
    .m04_axi_arid(m04_arid), .m04_axi_araddr(m04_araddr),
    .m04_axi_arlen(m04_arlen), .m04_axi_arsize(m04_arsize),
    .m04_axi_arburst(m04_arburst), .m04_axi_arlock(m04_arlock),
    .m04_axi_arcache(m04_arcache), .m04_axi_arprot(m04_arprot),
    .m04_axi_arqos(m04_arqos), .m04_axi_arregion(m04_arregion),
    .m04_axi_aruser(), .m04_axi_arvalid(m04_arvalid),
    .m04_axi_arready(m04_arready),
    .m04_axi_rid(m04_rid), .m04_axi_rdata(m04_rdata),
    .m04_axi_rresp(m04_rresp), .m04_axi_rlast(m04_rlast),
    .m04_axi_ruser(1'b0), .m04_axi_rvalid(m04_rvalid),
    .m04_axi_rready(m04_rready),

    // ---- M05: GPIO ----
    .m05_axi_awid(m05_awid), .m05_axi_awaddr(m05_awaddr),
    .m05_axi_awlen(m05_awlen), .m05_axi_awsize(m05_awsize),
    .m05_axi_awburst(m05_awburst), .m05_axi_awlock(m05_awlock),
    .m05_axi_awcache(m05_awcache), .m05_axi_awprot(m05_awprot),
    .m05_axi_awqos(m05_awqos), .m05_axi_awregion(m05_awregion),
    .m05_axi_awuser(), .m05_axi_awvalid(m05_awvalid),
    .m05_axi_awready(m05_awready),
    .m05_axi_wdata(m05_wdata), .m05_axi_wstrb(m05_wstrb),
    .m05_axi_wlast(m05_wlast), .m05_axi_wuser(),
    .m05_axi_wvalid(m05_wvalid), .m05_axi_wready(m05_wready),
    .m05_axi_bid(m05_bid), .m05_axi_bresp(m05_bresp),
    .m05_axi_buser(1'b0), .m05_axi_bvalid(m05_bvalid),
    .m05_axi_bready(m05_bready),
    .m05_axi_arid(m05_arid), .m05_axi_araddr(m05_araddr),
    .m05_axi_arlen(m05_arlen), .m05_axi_arsize(m05_arsize),
    .m05_axi_arburst(m05_arburst), .m05_axi_arlock(m05_arlock),
    .m05_axi_arcache(m05_arcache), .m05_axi_arprot(m05_arprot),
    .m05_axi_arqos(m05_arqos), .m05_axi_arregion(m05_arregion),
    .m05_axi_aruser(), .m05_axi_arvalid(m05_arvalid),
    .m05_axi_arready(m05_arready),
    .m05_axi_rid(m05_rid), .m05_axi_rdata(m05_rdata),
    .m05_axi_rresp(m05_rresp), .m05_axi_rlast(m05_rlast),
    .m05_axi_ruser(1'b0), .m05_axi_rvalid(m05_rvalid),
    .m05_axi_rready(m05_rready),

    // ---- M06 / M07: tied off ----
    .m06_axi_awid(), .m06_axi_awaddr(), .m06_axi_awlen(), .m06_axi_awsize(),
    .m06_axi_awburst(), .m06_axi_awlock(), .m06_axi_awcache(), .m06_axi_awprot(),
    .m06_axi_awqos(), .m06_axi_awregion(), .m06_axi_awuser(), .m06_axi_awvalid(),
    .m06_axi_awready(1'b1), .m06_axi_wdata(), .m06_axi_wstrb(), .m06_axi_wlast(),
    .m06_axi_wuser(), .m06_axi_wvalid(), .m06_axi_wready(1'b1),
    .m06_axi_bid(8'h0), .m06_axi_bresp(2'b00), .m06_axi_buser(1'b0),
    .m06_axi_bvalid(1'b0), .m06_axi_bready(),
    .m06_axi_arid(), .m06_axi_araddr(), .m06_axi_arlen(), .m06_axi_arsize(),
    .m06_axi_arburst(), .m06_axi_arlock(), .m06_axi_arcache(), .m06_axi_arprot(),
    .m06_axi_arqos(), .m06_axi_arregion(), .m06_axi_aruser(), .m06_axi_arvalid(),
    .m06_axi_arready(1'b1), .m06_axi_rid(8'h0), .m06_axi_rdata(32'h0),
    .m06_axi_rresp(2'b00), .m06_axi_rlast(1'b1), .m06_axi_ruser(1'b0),
    .m06_axi_rvalid(1'b0), .m06_axi_rready(),
    .m07_axi_awid(), .m07_axi_awaddr(), .m07_axi_awlen(), .m07_axi_awsize(),
    .m07_axi_awburst(), .m07_axi_awlock(), .m07_axi_awcache(), .m07_axi_awprot(),
    .m07_axi_awqos(), .m07_axi_awregion(), .m07_axi_awuser(), .m07_axi_awvalid(),
    .m07_axi_awready(1'b1), .m07_axi_wdata(), .m07_axi_wstrb(), .m07_axi_wlast(),
    .m07_axi_wuser(), .m07_axi_wvalid(), .m07_axi_wready(1'b1),
    .m07_axi_bid(8'h0), .m07_axi_bresp(2'b00), .m07_axi_buser(1'b0),
    .m07_axi_bvalid(1'b0), .m07_axi_bready(),
    .m07_axi_arid(), .m07_axi_araddr(), .m07_axi_arlen(), .m07_axi_arsize(),
    .m07_axi_arburst(), .m07_axi_arlock(), .m07_axi_arcache(), .m07_axi_arprot(),
    .m07_axi_arqos(), .m07_axi_arregion(), .m07_axi_aruser(), .m07_axi_arvalid(),
    .m07_axi_arready(1'b1), .m07_axi_rid(8'h0), .m07_axi_rdata(32'h0),
    .m07_axi_rresp(2'b00), .m07_axi_rlast(1'b1), .m07_axi_ruser(1'b0),
    .m07_axi_rvalid(1'b0), .m07_axi_rready()
);

// ====================================================================
// M00: AES — Bridge + IP
// ====================================================================
axi_to_axilite_aes_bridge #(
    .AXI_ID_WIDTH(8), .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32), .LITE_ADDR_WIDTH(7)
) u_aes_bridge (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(m00_awid), .s_axi_awaddr(m00_awaddr),
    .s_axi_awlen(m00_awlen), .s_axi_awsize(m00_awsize),
    .s_axi_awburst(m00_awburst), .s_axi_awvalid(m00_awvalid),
    .s_axi_awready(m00_awready),
    .s_axi_wdata(m00_wdata), .s_axi_wstrb(m00_wstrb),
    .s_axi_wlast(m00_wlast), .s_axi_wvalid(m00_wvalid),
    .s_axi_wready(m00_wready),
    .s_axi_bid(m00_bid), .s_axi_bresp(m00_bresp),
    .s_axi_bvalid(m00_bvalid), .s_axi_bready(m00_bready),
    .s_axi_arid(m00_arid), .s_axi_araddr(m00_araddr),
    .s_axi_arlen(m00_arlen), .s_axi_arsize(m00_arsize),
    .s_axi_arburst(m00_arburst), .s_axi_arvalid(m00_arvalid),
    .s_axi_arready(m00_arready),
    .s_axi_rid(m00_rid), .s_axi_rdata(m00_rdata),
    .s_axi_rresp(m00_rresp), .s_axi_rlast(m00_rlast),
    .s_axi_rvalid(m00_rvalid), .s_axi_rready(m00_rready),
    .m_axi_awaddr(aes_awaddr), .m_axi_awvalid(aes_awvalid),
    .m_axi_awready(aes_awready),
    .m_axi_wdata(aes_wdata), .m_axi_wstrb(aes_wstrb),
    .m_axi_wvalid(aes_wvalid), .m_axi_wready(aes_wready),
    .m_axi_bresp(aes_bresp), .m_axi_bvalid(aes_bvalid),
    .m_axi_bready(aes_bready),
    .m_axi_araddr(aes_araddr), .m_axi_arvalid(aes_arvalid),
    .m_axi_arready(aes_arready),
    .m_axi_rdata(aes_rdata), .m_axi_rresp(aes_rresp),
    .m_axi_rvalid(aes_rvalid), .m_axi_rready(aes_rready)
);

AES_AXI #(.C_S_AXI_DATA_WIDTH(32), .C_S_AXI_ADDR_WIDTH(7)) u_aes (
    .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
    .S_AXI_AWADDR(aes_awaddr), .S_AXI_AWVALID(aes_awvalid),
    .S_AXI_AWREADY(aes_awready),
    .S_AXI_WDATA(aes_wdata), .S_AXI_WSTRB(aes_wstrb),
    .S_AXI_WVALID(aes_wvalid), .S_AXI_WREADY(aes_wready),
    .S_AXI_BRESP(aes_bresp), .S_AXI_BVALID(aes_bvalid),
    .S_AXI_BREADY(aes_bready),
    .S_AXI_ARADDR(aes_araddr), .S_AXI_ARVALID(aes_arvalid),
    .S_AXI_ARREADY(aes_arready),
    .S_AXI_RDATA(aes_rdata), .S_AXI_RRESP(aes_rresp),
    .S_AXI_RVALID(aes_rvalid), .S_AXI_RREADY(aes_rready)
);

// ====================================================================
// M02: SPI — direct AXI4-Lite (no bridge needed, has own ID ports)
// ====================================================================
spi_axi_top #(
    .AXI_ADDR_WIDTH(32), .AXI_DATA_WIDTH(32), .AXI_ID_WIDTH(8),
    .SPI_MODE(0), .CLKS_PER_HALF_BIT(2), .MAX_BYTES_PER_CS(2)
) u_spi (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(m02_awid), .s_axi_awaddr(m02_awaddr),
    .s_axi_awvalid(m02_awvalid), .s_axi_awready(m02_awready),
    .s_axi_wdata(m02_wdata), .s_axi_wstrb(m02_wstrb),
    .s_axi_wvalid(m02_wvalid), .s_axi_wready(m02_wready),
    .s_axi_bid(m02_bid), .s_axi_bresp(m02_bresp),
    .s_axi_bvalid(m02_bvalid), .s_axi_bready(m02_bready),
    .s_axi_arid(m02_arid), .s_axi_araddr(m02_araddr),
    .s_axi_arvalid(m02_arvalid), .s_axi_arready(m02_arready),
    .s_axi_rid(m02_rid), .s_axi_rdata(m02_rdata),
    .s_axi_rresp(m02_rresp), .s_axi_rvalid(m02_rvalid),
    .s_axi_rready(m02_rready),
    .spi_clk(spi_clk_o), .spi_mosi(spi_mosi_o),
    .spi_miso(spi_miso_i), .spi_cs_n(spi_cs_n_o)
);

// ====================================================================
// M03: UART — Bridge + IP
// ====================================================================
axi_to_axilite_uart_bridge #(
    .AXI_ID_WIDTH(8), .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32), .LITE_ID_WIDTH(12), .LITE_ADDR_WIDTH(5)
) u_uart_bridge (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(m03_awid), .s_axi_awaddr(m03_awaddr),
    .s_axi_awlen(m03_awlen), .s_axi_awsize(m03_awsize),
    .s_axi_awburst(m03_awburst), .s_axi_awvalid(m03_awvalid),
    .s_axi_awready(m03_awready),
    .s_axi_wdata(m03_wdata), .s_axi_wstrb(m03_wstrb),
    .s_axi_wlast(m03_wlast), .s_axi_wvalid(m03_wvalid),
    .s_axi_wready(m03_wready),
    .s_axi_bid(m03_bid), .s_axi_bresp(m03_bresp),
    .s_axi_bvalid(m03_bvalid), .s_axi_bready(m03_bready),
    .s_axi_arid(m03_arid), .s_axi_araddr(m03_araddr),
    .s_axi_arlen(m03_arlen), .s_axi_arsize(m03_arsize),
    .s_axi_arburst(m03_arburst), .s_axi_arvalid(m03_arvalid),
    .s_axi_arready(m03_arready),
    .s_axi_rid(m03_rid), .s_axi_rdata(m03_rdata),
    .s_axi_rresp(m03_rresp), .s_axi_rlast(m03_rlast),
    .s_axi_rvalid(m03_rvalid), .s_axi_rready(m03_rready),
    .m_axi_awid(uart_awid), .m_axi_awaddr(uart_awaddr),
    .m_axi_awvalid(uart_awvalid), .m_axi_awready(uart_awready),
    .m_axi_wdata(uart_wdata), .m_axi_wstrb(uart_wstrb),
    .m_axi_wvalid(uart_wvalid), .m_axi_wready(uart_wready),
    .m_axi_bid(uart_bid), .m_axi_bresp(uart_bresp),
    .m_axi_bvalid(uart_bvalid), .m_axi_bready(uart_bready),
    .m_axi_arid(uart_arid), .m_axi_araddr(uart_araddr),
    .m_axi_arvalid(uart_arvalid), .m_axi_arready(uart_arready),
    .m_axi_rid(uart_rid), .m_axi_rdata(uart_rdata),
    .m_axi_rresp(uart_rresp), .m_axi_rvalid(uart_rvalid),
    .m_axi_rready(uart_rready)
);

axi_uart_top u_uart (
    .fixed_clk_i(clk), .axi_aclk_i(clk), .axi_aresetn_i(rstn),
    .axi_arid_i(uart_arid), .axi_araddr_i(uart_araddr),
    .axi_arvalid_i(uart_arvalid), .axi_arready_o(uart_arready),
    .axi_rid_o(uart_rid), .axi_rdata_o(uart_rdata),
    .axi_rresp_o(uart_rresp), .axi_rvalid_o(uart_rvalid),
    .axi_rready_i(uart_rready),
    .axi_awid_i(uart_awid), .axi_awaddr_i(uart_awaddr),
    .axi_awvalid_i(uart_awvalid), .axi_awready_o(uart_awready),
    .axi_wdata_i(uart_wdata), .axi_wstrb_i(uart_wstrb),
    .axi_wvalid_i(uart_wvalid), .axi_wready_o(uart_wready),
    .axi_bid_o(uart_bid), .axi_bresp_o(uart_bresp),
    .axi_bvalid_o(uart_bvalid), .axi_bready_i(uart_bready),
    .uart_rx_i(uart_rx_i), .uart_tx_o(uart_tx_o),
    .read_interrupt_o(uart_irq_o)
);

// ====================================================================
// M04: Timer — Bridge + IP
// ====================================================================
axi_to_axilite_timer_bridge #(
    .AXI_ID_WIDTH(8), .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32), .LITE_ADDR_WIDTH(16)
) u_timer_bridge (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(m04_awid), .s_axi_awaddr(m04_awaddr),
    .s_axi_awlen(m04_awlen), .s_axi_awsize(m04_awsize),
    .s_axi_awburst(m04_awburst), .s_axi_awvalid(m04_awvalid),
    .s_axi_awready(m04_awready),
    .s_axi_wdata(m04_wdata), .s_axi_wstrb(m04_wstrb),
    .s_axi_wlast(m04_wlast), .s_axi_wvalid(m04_wvalid),
    .s_axi_wready(m04_wready),
    .s_axi_bid(m04_bid), .s_axi_bresp(m04_bresp),
    .s_axi_bvalid(m04_bvalid), .s_axi_bready(m04_bready),
    .s_axi_arid(m04_arid), .s_axi_araddr(m04_araddr),
    .s_axi_arlen(m04_arlen), .s_axi_arsize(m04_arsize),
    .s_axi_arburst(m04_arburst), .s_axi_arvalid(m04_arvalid),
    .s_axi_arready(m04_arready),
    .s_axi_rid(m04_rid), .s_axi_rdata(m04_rdata),
    .s_axi_rresp(m04_rresp), .s_axi_rlast(m04_rlast),
    .s_axi_rvalid(m04_rvalid), .s_axi_rready(m04_rready),
    .m_axi_awid(tmr_awid), .m_axi_awaddr(tmr_awaddr),
    .m_axi_awvalid(tmr_awvalid), .m_axi_awready(tmr_awready),
    .m_axi_wdata(tmr_wdata), .m_axi_wstrb(tmr_wstrb),
    .m_axi_wvalid(tmr_wvalid), .m_axi_wready(tmr_wready),
    .m_axi_bid(tmr_bid), .m_axi_bresp(tmr_bresp),
    .m_axi_bvalid(tmr_bvalid), .m_axi_bready(tmr_bready),
    .m_axi_arid(tmr_arid), .m_axi_araddr(tmr_araddr),
    .m_axi_arvalid(tmr_arvalid), .m_axi_arready(tmr_arready),
    .m_axi_rid(tmr_rid), .m_axi_rdata(tmr_rdata),
    .m_axi_rresp(tmr_rresp), .m_axi_rvalid(tmr_rvalid),
    .m_axi_rready(tmr_rready)
);

EF_TCC32_axi #(
    .AXI_ADDR_WIDTH(32), .AXI_DATA_WIDTH(32), .AXI_ID_WIDTH(8)
) u_timer (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(tmr_awid), .s_axi_awaddr({16'h0, tmr_awaddr}),
    .s_axi_awvalid(tmr_awvalid), .s_axi_awready(tmr_awready),
    .s_axi_wdata(tmr_wdata), .s_axi_wstrb(tmr_wstrb),
    .s_axi_wvalid(tmr_wvalid), .s_axi_wready(tmr_wready),
    .s_axi_bid(tmr_bid), .s_axi_bresp(tmr_bresp),
    .s_axi_bvalid(tmr_bvalid), .s_axi_bready(tmr_bready),
    .s_axi_arid(tmr_arid), .s_axi_araddr({16'h0, tmr_araddr}),
    .s_axi_arvalid(tmr_arvalid), .s_axi_arready(tmr_arready),
    .s_axi_rid(tmr_rid), .s_axi_rdata(tmr_rdata),
    .s_axi_rresp(tmr_rresp), .s_axi_rvalid(tmr_rvalid),
    .s_axi_rready(tmr_rready),
    .ctr_in(timer_ctr_in_i),
    .timer_irq(timer_irq_o)
);

// ====================================================================
// M05: GPIO — Bridge + IP
// ====================================================================
axi_to_axilite_gpio_bridge #(
    .AXI_ID_WIDTH(8), .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32), .LITE_ADDR_WIDTH(16)
) u_gpio_bridge (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(m05_awid), .s_axi_awaddr(m05_awaddr),
    .s_axi_awlen(m05_awlen), .s_axi_awsize(m05_awsize),
    .s_axi_awburst(m05_awburst), .s_axi_awvalid(m05_awvalid),
    .s_axi_awready(m05_awready),
    .s_axi_wdata(m05_wdata), .s_axi_wstrb(m05_wstrb),
    .s_axi_wlast(m05_wlast), .s_axi_wvalid(m05_wvalid),
    .s_axi_wready(m05_wready),
    .s_axi_bid(m05_bid), .s_axi_bresp(m05_bresp),
    .s_axi_bvalid(m05_bvalid), .s_axi_bready(m05_bready),
    .s_axi_arid(m05_arid), .s_axi_araddr(m05_araddr),
    .s_axi_arlen(m05_arlen), .s_axi_arsize(m05_arsize),
    .s_axi_arburst(m05_arburst), .s_axi_arvalid(m05_arvalid),
    .s_axi_arready(m05_arready),
    .s_axi_rid(m05_rid), .s_axi_rdata(m05_rdata),
    .s_axi_rresp(m05_rresp), .s_axi_rlast(m05_rlast),
    .s_axi_rvalid(m05_rvalid), .s_axi_rready(m05_rready),
    .m_axi_awid(gpio_awid), .m_axi_awaddr(gpio_awaddr),
    .m_axi_awvalid(gpio_awvalid), .m_axi_awready(gpio_awready),
    .m_axi_wdata(gpio_wdata), .m_axi_wstrb(gpio_wstrb),
    .m_axi_wvalid(gpio_wvalid), .m_axi_wready(gpio_wready),
    .m_axi_bid(gpio_bid), .m_axi_bresp(gpio_bresp),
    .m_axi_bvalid(gpio_bvalid), .m_axi_bready(gpio_bready),
    .m_axi_arid(gpio_arid), .m_axi_araddr(gpio_araddr),
    .m_axi_arvalid(gpio_arvalid), .m_axi_arready(gpio_arready),
    .m_axi_rid(gpio_rid), .m_axi_rdata(gpio_rdata),
    .m_axi_rresp(gpio_rresp), .m_axi_rvalid(gpio_rvalid),
    .m_axi_rready(gpio_rready)
);

EF_GPIO8_axi #(
    .AXI_ADDR_WIDTH(32), .AXI_DATA_WIDTH(32), .AXI_ID_WIDTH(8)
) u_gpio (
    .clk(clk), .rstn(rstn),
    .s_axi_awid(gpio_awid), .s_axi_awaddr({16'h0, gpio_awaddr}),
    .s_axi_awvalid(gpio_awvalid), .s_axi_awready(gpio_awready),
    .s_axi_wdata(gpio_wdata), .s_axi_wstrb(gpio_wstrb),
    .s_axi_wvalid(gpio_wvalid), .s_axi_wready(gpio_wready),
    .s_axi_bid(gpio_bid), .s_axi_bresp(gpio_bresp),
    .s_axi_bvalid(gpio_bvalid), .s_axi_bready(gpio_bready),
    .s_axi_arid(gpio_arid), .s_axi_araddr({16'h0, gpio_araddr}),
    .s_axi_arvalid(gpio_arvalid), .s_axi_arready(gpio_arready),
    .s_axi_rid(gpio_rid), .s_axi_rdata(gpio_rdata),
    .s_axi_rresp(gpio_rresp), .s_axi_rvalid(gpio_rvalid),
    .s_axi_rready(gpio_rready),
    .gpio_in(gpio_in_i), .gpio_out(gpio_out_o),
    .gpio_oe(gpio_oe_o), .gpio_irq(gpio_irq_o)
);

endmodule
`default_nettype wire
