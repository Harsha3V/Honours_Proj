// Language: Verilog 2001
// Testbench for axi_interconnect_wrap_2x8
// DUT: 2 AXI master inputs (s00, s01), 8 AXI slave outputs (m00..m07)
// Address map (auto-computed, M_REGIONS=1, all M_BASE_ADDR=0, M_ADDR_WIDTH=24):
//   M00: 0x00000000 - 0x00FFFFFF  (16 MB)
//   M01: 0x01000000 - 0x01FFFFFF
//   M02: 0x02000000 - 0x02FFFFFF
//   M03: 0x03000000 - 0x03FFFFFF
//   M04: 0x04000000 - 0x04FFFFFF
//   M05: 0x05000000 - 0x05FFFFFF
//   M06: 0x06000000 - 0x06FFFFFF
//   M07: 0x07000000 - 0x07FFFFFF

`timescale 1ns / 1ps

module axi_interconnect_tb;

// -----------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------
parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;
parameter STRB_WIDTH    = 4;
parameter ID_WIDTH      = 8;
parameter AWUSER_WIDTH  = 1;
parameter WUSER_WIDTH   = 1;
parameter BUSER_WIDTH   = 1;
parameter ARUSER_WIDTH  = 1;
parameter RUSER_WIDTH   = 1;

parameter CLK_PERIOD    = 10; // ns
parameter TIMEOUT_CYCLES = 500;

// Address base per slave (auto-computed by DUT when M_BASE_ADDR=0)
parameter [31:0] M00_BASE = 32'h0000_0000;
parameter [31:0] M01_BASE = 32'h0100_0000;
parameter [31:0] M02_BASE = 32'h0200_0000;
parameter [31:0] M03_BASE = 32'h0300_0000;
parameter [31:0] M04_BASE = 32'h0400_0000;
parameter [31:0] M05_BASE = 32'h0500_0000;
parameter [31:0] M06_BASE = 32'h0600_0000;
parameter [31:0] M07_BASE = 32'h0700_0000;

// -----------------------------------------------------------------------
// Clock and reset
// -----------------------------------------------------------------------
reg clk = 0;
reg rst = 0;

always #(CLK_PERIOD/2) clk = ~clk;

// -----------------------------------------------------------------------
// Master 0 (drives s00_axi) – inputs to DUT are reg, outputs are wire
// -----------------------------------------------------------------------
reg  [ID_WIDTH-1:0]     s00_axi_awid    = 0;
reg  [ADDR_WIDTH-1:0]   s00_axi_awaddr  = 0;
reg  [7:0]              s00_axi_awlen   = 0;
reg  [2:0]              s00_axi_awsize  = 3'b010; // 4 bytes
reg  [1:0]              s00_axi_awburst = 2'b01;  // INCR
reg                     s00_axi_awlock  = 0;
reg  [3:0]              s00_axi_awcache = 0;
reg  [2:0]              s00_axi_awprot  = 0;
reg  [3:0]              s00_axi_awqos   = 0;
reg  [AWUSER_WIDTH-1:0] s00_axi_awuser  = 0;
reg                     s00_axi_awvalid = 0;
wire                    s00_axi_awready;

reg  [DATA_WIDTH-1:0]   s00_axi_wdata   = 0;
reg  [STRB_WIDTH-1:0]   s00_axi_wstrb   = 4'hF;
reg                     s00_axi_wlast   = 0;
reg  [WUSER_WIDTH-1:0]  s00_axi_wuser   = 0;
reg                     s00_axi_wvalid  = 0;
wire                    s00_axi_wready;

wire [ID_WIDTH-1:0]     s00_axi_bid;
wire [1:0]              s00_axi_bresp;
wire [BUSER_WIDTH-1:0]  s00_axi_buser;
wire                    s00_axi_bvalid;
reg                     s00_axi_bready  = 1;

reg  [ID_WIDTH-1:0]     s00_axi_arid    = 0;
reg  [ADDR_WIDTH-1:0]   s00_axi_araddr  = 0;
reg  [7:0]              s00_axi_arlen   = 0;
reg  [2:0]              s00_axi_arsize  = 3'b010;
reg  [1:0]              s00_axi_arburst = 2'b01;
reg                     s00_axi_arlock  = 0;
reg  [3:0]              s00_axi_arcache = 0;
reg  [2:0]              s00_axi_arprot  = 0;
reg  [3:0]              s00_axi_arqos   = 0;
reg  [ARUSER_WIDTH-1:0] s00_axi_aruser  = 0;
reg                     s00_axi_arvalid = 0;
wire                    s00_axi_arready;

wire [ID_WIDTH-1:0]     s00_axi_rid;
wire [DATA_WIDTH-1:0]   s00_axi_rdata;
wire [1:0]              s00_axi_rresp;
wire                    s00_axi_rlast;
wire [RUSER_WIDTH-1:0]  s00_axi_ruser;
wire                    s00_axi_rvalid;
reg                     s00_axi_rready  = 1;

// -----------------------------------------------------------------------
// Master 1 (drives s01_axi)
// -----------------------------------------------------------------------
reg  [ID_WIDTH-1:0]     s01_axi_awid    = 0;
reg  [ADDR_WIDTH-1:0]   s01_axi_awaddr  = 0;
reg  [7:0]              s01_axi_awlen   = 0;
reg  [2:0]              s01_axi_awsize  = 3'b010;
reg  [1:0]              s01_axi_awburst = 2'b01;
reg                     s01_axi_awlock  = 0;
reg  [3:0]              s01_axi_awcache = 0;
reg  [2:0]              s01_axi_awprot  = 0;
reg  [3:0]              s01_axi_awqos   = 0;
reg  [AWUSER_WIDTH-1:0] s01_axi_awuser  = 0;
reg                     s01_axi_awvalid = 0;
wire                    s01_axi_awready;

reg  [DATA_WIDTH-1:0]   s01_axi_wdata   = 0;
reg  [STRB_WIDTH-1:0]   s01_axi_wstrb   = 4'hF;
reg                     s01_axi_wlast   = 0;
reg  [WUSER_WIDTH-1:0]  s01_axi_wuser   = 0;
reg                     s01_axi_wvalid  = 0;
wire                    s01_axi_wready;

wire [ID_WIDTH-1:0]     s01_axi_bid;
wire [1:0]              s01_axi_bresp;
wire [BUSER_WIDTH-1:0]  s01_axi_buser;
wire                    s01_axi_bvalid;
reg                     s01_axi_bready  = 1;

reg  [ID_WIDTH-1:0]     s01_axi_arid    = 0;
reg  [ADDR_WIDTH-1:0]   s01_axi_araddr  = 0;
reg  [7:0]              s01_axi_arlen   = 0;
reg  [2:0]              s01_axi_arsize  = 3'b010;
reg  [1:0]              s01_axi_arburst = 2'b01;
reg                     s01_axi_arlock  = 0;
reg  [3:0]              s01_axi_arcache = 0;
reg  [2:0]              s01_axi_arprot  = 0;
reg  [3:0]              s01_axi_arqos   = 0;
reg  [ARUSER_WIDTH-1:0] s01_axi_aruser  = 0;
reg                     s01_axi_arvalid = 0;
wire                    s01_axi_arready;

wire [ID_WIDTH-1:0]     s01_axi_rid;
wire [DATA_WIDTH-1:0]   s01_axi_rdata;
wire [1:0]              s01_axi_rresp;
wire                    s01_axi_rlast;
wire [RUSER_WIDTH-1:0]  s01_axi_ruser;
wire                    s01_axi_rvalid;
reg                     s01_axi_rready  = 1;

// -----------------------------------------------------------------------
// Slave 0 (m00_axi) – outputs from DUT are wire, responses are reg
// -----------------------------------------------------------------------
wire [ID_WIDTH-1:0]     m00_axi_awid;
wire [ADDR_WIDTH-1:0]   m00_axi_awaddr;
wire [7:0]              m00_axi_awlen;
wire [2:0]              m00_axi_awsize;
wire [1:0]              m00_axi_awburst;
wire                    m00_axi_awlock;
wire [3:0]              m00_axi_awcache;
wire [2:0]              m00_axi_awprot;
wire [3:0]              m00_axi_awqos;
wire [3:0]              m00_axi_awregion;
wire [AWUSER_WIDTH-1:0] m00_axi_awuser;
wire                    m00_axi_awvalid;
reg                     m00_axi_awready = 1;

wire [DATA_WIDTH-1:0]   m00_axi_wdata;
wire [STRB_WIDTH-1:0]   m00_axi_wstrb;
wire                    m00_axi_wlast;
wire [WUSER_WIDTH-1:0]  m00_axi_wuser;
wire                    m00_axi_wvalid;
reg                     m00_axi_wready  = 1;

reg  [ID_WIDTH-1:0]     m00_axi_bid     = 0;
reg  [1:0]              m00_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m00_axi_buser   = 0;
reg                     m00_axi_bvalid  = 0;
wire                    m00_axi_bready;

wire [ID_WIDTH-1:0]     m00_axi_arid;
wire [ADDR_WIDTH-1:0]   m00_axi_araddr;
wire [7:0]              m00_axi_arlen;
wire [2:0]              m00_axi_arsize;
wire [1:0]              m00_axi_arburst;
wire                    m00_axi_arlock;
wire [3:0]              m00_axi_arcache;
wire [2:0]              m00_axi_arprot;
wire [3:0]              m00_axi_arqos;
wire [3:0]              m00_axi_arregion;
wire [ARUSER_WIDTH-1:0] m00_axi_aruser;
wire                    m00_axi_arvalid;
reg                     m00_axi_arready = 1;

reg  [ID_WIDTH-1:0]     m00_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m00_axi_rdata   = 32'h1234_5678;
reg  [1:0]              m00_axi_rresp   = 0;
reg                     m00_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m00_axi_ruser   = 0;
reg                     m00_axi_rvalid  = 0;
wire                    m00_axi_rready;

// -----------------------------------------------------------------------
// Slave 1..7 – generic: awready/wready/arready=1, respond with OKAY
// -----------------------------------------------------------------------
// m01
wire [ID_WIDTH-1:0]     m01_axi_awid;
wire [ADDR_WIDTH-1:0]   m01_axi_awaddr;
wire [7:0]              m01_axi_awlen;
wire [2:0]              m01_axi_awsize;
wire [1:0]              m01_axi_awburst;
wire                    m01_axi_awlock;
wire [3:0]              m01_axi_awcache;
wire [2:0]              m01_axi_awprot;
wire [3:0]              m01_axi_awqos;
wire [3:0]              m01_axi_awregion;
wire [AWUSER_WIDTH-1:0] m01_axi_awuser;
wire                    m01_axi_awvalid;
reg                     m01_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m01_axi_wdata;
wire [STRB_WIDTH-1:0]   m01_axi_wstrb;
wire                    m01_axi_wlast;
wire [WUSER_WIDTH-1:0]  m01_axi_wuser;
wire                    m01_axi_wvalid;
reg                     m01_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m01_axi_bid     = 0;
reg  [1:0]              m01_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m01_axi_buser   = 0;
reg                     m01_axi_bvalid  = 0;
wire                    m01_axi_bready;
wire [ID_WIDTH-1:0]     m01_axi_arid;
wire [ADDR_WIDTH-1:0]   m01_axi_araddr;
wire [7:0]              m01_axi_arlen;
wire [2:0]              m01_axi_arsize;
wire [1:0]              m01_axi_arburst;
wire                    m01_axi_arlock;
wire [3:0]              m01_axi_arcache;
wire [2:0]              m01_axi_arprot;
wire [3:0]              m01_axi_arqos;
wire [3:0]              m01_axi_arregion;
wire [ARUSER_WIDTH-1:0] m01_axi_aruser;
wire                    m01_axi_arvalid;
reg                     m01_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m01_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m01_axi_rdata   = 32'hDEAD_0001;
reg  [1:0]              m01_axi_rresp   = 0;
reg                     m01_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m01_axi_ruser   = 0;
reg                     m01_axi_rvalid  = 0;
wire                    m01_axi_rready;

// m02
wire [ID_WIDTH-1:0]     m02_axi_awid;
wire [ADDR_WIDTH-1:0]   m02_axi_awaddr;
wire [7:0]              m02_axi_awlen;
wire [2:0]              m02_axi_awsize;
wire [1:0]              m02_axi_awburst;
wire                    m02_axi_awlock;
wire [3:0]              m02_axi_awcache;
wire [2:0]              m02_axi_awprot;
wire [3:0]              m02_axi_awqos;
wire [3:0]              m02_axi_awregion;
wire [AWUSER_WIDTH-1:0] m02_axi_awuser;
wire                    m02_axi_awvalid;
reg                     m02_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m02_axi_wdata;
wire [STRB_WIDTH-1:0]   m02_axi_wstrb;
wire                    m02_axi_wlast;
wire [WUSER_WIDTH-1:0]  m02_axi_wuser;
wire                    m02_axi_wvalid;
reg                     m02_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m02_axi_bid     = 0;
reg  [1:0]              m02_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m02_axi_buser   = 0;
reg                     m02_axi_bvalid  = 0;
wire                    m02_axi_bready;
wire [ID_WIDTH-1:0]     m02_axi_arid;
wire [ADDR_WIDTH-1:0]   m02_axi_araddr;
wire [7:0]              m02_axi_arlen;
wire [2:0]              m02_axi_arsize;
wire [1:0]              m02_axi_arburst;
wire                    m02_axi_arlock;
wire [3:0]              m02_axi_arcache;
wire [2:0]              m02_axi_arprot;
wire [3:0]              m02_axi_arqos;
wire [3:0]              m02_axi_arregion;
wire [ARUSER_WIDTH-1:0] m02_axi_aruser;
wire                    m02_axi_arvalid;
reg                     m02_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m02_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m02_axi_rdata   = 32'hDEAD_0002;
reg  [1:0]              m02_axi_rresp   = 0;
reg                     m02_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m02_axi_ruser   = 0;
reg                     m02_axi_rvalid  = 0;
wire                    m02_axi_rready;

// m03
wire [ID_WIDTH-1:0]     m03_axi_awid;
wire [ADDR_WIDTH-1:0]   m03_axi_awaddr;
wire [7:0]              m03_axi_awlen;
wire [2:0]              m03_axi_awsize;
wire [1:0]              m03_axi_awburst;
wire                    m03_axi_awlock;
wire [3:0]              m03_axi_awcache;
wire [2:0]              m03_axi_awprot;
wire [3:0]              m03_axi_awqos;
wire [3:0]              m03_axi_awregion;
wire [AWUSER_WIDTH-1:0] m03_axi_awuser;
wire                    m03_axi_awvalid;
reg                     m03_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m03_axi_wdata;
wire [STRB_WIDTH-1:0]   m03_axi_wstrb;
wire                    m03_axi_wlast;
wire [WUSER_WIDTH-1:0]  m03_axi_wuser;
wire                    m03_axi_wvalid;
reg                     m03_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m03_axi_bid     = 0;
reg  [1:0]              m03_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m03_axi_buser   = 0;
reg                     m03_axi_bvalid  = 0;
wire                    m03_axi_bready;
wire [ID_WIDTH-1:0]     m03_axi_arid;
wire [ADDR_WIDTH-1:0]   m03_axi_araddr;
wire [7:0]              m03_axi_arlen;
wire [2:0]              m03_axi_arsize;
wire [1:0]              m03_axi_arburst;
wire                    m03_axi_arlock;
wire [3:0]              m03_axi_arcache;
wire [2:0]              m03_axi_arprot;
wire [3:0]              m03_axi_arqos;
wire [3:0]              m03_axi_arregion;
wire [ARUSER_WIDTH-1:0] m03_axi_aruser;
wire                    m03_axi_arvalid;
reg                     m03_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m03_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m03_axi_rdata   = 32'hDEAD_0003;
reg  [1:0]              m03_axi_rresp   = 0;
reg                     m03_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m03_axi_ruser   = 0;
reg                     m03_axi_rvalid  = 0;
wire                    m03_axi_rready;

// m04
wire [ID_WIDTH-1:0]     m04_axi_awid;
wire [ADDR_WIDTH-1:0]   m04_axi_awaddr;
wire [7:0]              m04_axi_awlen;
wire [2:0]              m04_axi_awsize;
wire [1:0]              m04_axi_awburst;
wire                    m04_axi_awlock;
wire [3:0]              m04_axi_awcache;
wire [2:0]              m04_axi_awprot;
wire [3:0]              m04_axi_awqos;
wire [3:0]              m04_axi_awregion;
wire [AWUSER_WIDTH-1:0] m04_axi_awuser;
wire                    m04_axi_awvalid;
reg                     m04_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m04_axi_wdata;
wire [STRB_WIDTH-1:0]   m04_axi_wstrb;
wire                    m04_axi_wlast;
wire [WUSER_WIDTH-1:0]  m04_axi_wuser;
wire                    m04_axi_wvalid;
reg                     m04_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m04_axi_bid     = 0;
reg  [1:0]              m04_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m04_axi_buser   = 0;
reg                     m04_axi_bvalid  = 0;
wire                    m04_axi_bready;
wire [ID_WIDTH-1:0]     m04_axi_arid;
wire [ADDR_WIDTH-1:0]   m04_axi_araddr;
wire [7:0]              m04_axi_arlen;
wire [2:0]              m04_axi_arsize;
wire [1:0]              m04_axi_arburst;
wire                    m04_axi_arlock;
wire [3:0]              m04_axi_arcache;
wire [2:0]              m04_axi_arprot;
wire [3:0]              m04_axi_arqos;
wire [3:0]              m04_axi_arregion;
wire [ARUSER_WIDTH-1:0] m04_axi_aruser;
wire                    m04_axi_arvalid;
reg                     m04_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m04_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m04_axi_rdata   = 32'hDEAD_0004;
reg  [1:0]              m04_axi_rresp   = 0;
reg                     m04_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m04_axi_ruser   = 0;
reg                     m04_axi_rvalid  = 0;
wire                    m04_axi_rready;

// m05
wire [ID_WIDTH-1:0]     m05_axi_awid;
wire [ADDR_WIDTH-1:0]   m05_axi_awaddr;
wire [7:0]              m05_axi_awlen;
wire [2:0]              m05_axi_awsize;
wire [1:0]              m05_axi_awburst;
wire                    m05_axi_awlock;
wire [3:0]              m05_axi_awcache;
wire [2:0]              m05_axi_awprot;
wire [3:0]              m05_axi_awqos;
wire [3:0]              m05_axi_awregion;
wire [AWUSER_WIDTH-1:0] m05_axi_awuser;
wire                    m05_axi_awvalid;
reg                     m05_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m05_axi_wdata;
wire [STRB_WIDTH-1:0]   m05_axi_wstrb;
wire                    m05_axi_wlast;
wire [WUSER_WIDTH-1:0]  m05_axi_wuser;
wire                    m05_axi_wvalid;
reg                     m05_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m05_axi_bid     = 0;
reg  [1:0]              m05_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m05_axi_buser   = 0;
reg                     m05_axi_bvalid  = 0;
wire                    m05_axi_bready;
wire [ID_WIDTH-1:0]     m05_axi_arid;
wire [ADDR_WIDTH-1:0]   m05_axi_araddr;
wire [7:0]              m05_axi_arlen;
wire [2:0]              m05_axi_arsize;
wire [1:0]              m05_axi_arburst;
wire                    m05_axi_arlock;
wire [3:0]              m05_axi_arcache;
wire [2:0]              m05_axi_arprot;
wire [3:0]              m05_axi_arqos;
wire [3:0]              m05_axi_arregion;
wire [ARUSER_WIDTH-1:0] m05_axi_aruser;
wire                    m05_axi_arvalid;
reg                     m05_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m05_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m05_axi_rdata   = 32'hDEAD_0005;
reg  [1:0]              m05_axi_rresp   = 0;
reg                     m05_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m05_axi_ruser   = 0;
reg                     m05_axi_rvalid  = 0;
wire                    m05_axi_rready;

// m06
wire [ID_WIDTH-1:0]     m06_axi_awid;
wire [ADDR_WIDTH-1:0]   m06_axi_awaddr;
wire [7:0]              m06_axi_awlen;
wire [2:0]              m06_axi_awsize;
wire [1:0]              m06_axi_awburst;
wire                    m06_axi_awlock;
wire [3:0]              m06_axi_awcache;
wire [2:0]              m06_axi_awprot;
wire [3:0]              m06_axi_awqos;
wire [3:0]              m06_axi_awregion;
wire [AWUSER_WIDTH-1:0] m06_axi_awuser;
wire                    m06_axi_awvalid;
reg                     m06_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m06_axi_wdata;
wire [STRB_WIDTH-1:0]   m06_axi_wstrb;
wire                    m06_axi_wlast;
wire [WUSER_WIDTH-1:0]  m06_axi_wuser;
wire                    m06_axi_wvalid;
reg                     m06_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m06_axi_bid     = 0;
reg  [1:0]              m06_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m06_axi_buser   = 0;
reg                     m06_axi_bvalid  = 0;
wire                    m06_axi_bready;
wire [ID_WIDTH-1:0]     m06_axi_arid;
wire [ADDR_WIDTH-1:0]   m06_axi_araddr;
wire [7:0]              m06_axi_arlen;
wire [2:0]              m06_axi_arsize;
wire [1:0]              m06_axi_arburst;
wire                    m06_axi_arlock;
wire [3:0]              m06_axi_arcache;
wire [2:0]              m06_axi_arprot;
wire [3:0]              m06_axi_arqos;
wire [3:0]              m06_axi_arregion;
wire [ARUSER_WIDTH-1:0] m06_axi_aruser;
wire                    m06_axi_arvalid;
reg                     m06_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m06_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m06_axi_rdata   = 32'hDEAD_0006;
reg  [1:0]              m06_axi_rresp   = 0;
reg                     m06_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m06_axi_ruser   = 0;
reg                     m06_axi_rvalid  = 0;
wire                    m06_axi_rready;

// m07
wire [ID_WIDTH-1:0]     m07_axi_awid;
wire [ADDR_WIDTH-1:0]   m07_axi_awaddr;
wire [7:0]              m07_axi_awlen;
wire [2:0]              m07_axi_awsize;
wire [1:0]              m07_axi_awburst;
wire                    m07_axi_awlock;
wire [3:0]              m07_axi_awcache;
wire [2:0]              m07_axi_awprot;
wire [3:0]              m07_axi_awqos;
wire [3:0]              m07_axi_awregion;
wire [AWUSER_WIDTH-1:0] m07_axi_awuser;
wire                    m07_axi_awvalid;
reg                     m07_axi_awready = 1;
wire [DATA_WIDTH-1:0]   m07_axi_wdata;
wire [STRB_WIDTH-1:0]   m07_axi_wstrb;
wire                    m07_axi_wlast;
wire [WUSER_WIDTH-1:0]  m07_axi_wuser;
wire                    m07_axi_wvalid;
reg                     m07_axi_wready  = 1;
reg  [ID_WIDTH-1:0]     m07_axi_bid     = 0;
reg  [1:0]              m07_axi_bresp   = 0;
reg  [BUSER_WIDTH-1:0]  m07_axi_buser   = 0;
reg                     m07_axi_bvalid  = 0;
wire                    m07_axi_bready;
wire [ID_WIDTH-1:0]     m07_axi_arid;
wire [ADDR_WIDTH-1:0]   m07_axi_araddr;
wire [7:0]              m07_axi_arlen;
wire [2:0]              m07_axi_arsize;
wire [1:0]              m07_axi_arburst;
wire                    m07_axi_arlock;
wire [3:0]              m07_axi_arcache;
wire [2:0]              m07_axi_arprot;
wire [3:0]              m07_axi_arqos;
wire [3:0]              m07_axi_arregion;
wire [ARUSER_WIDTH-1:0] m07_axi_aruser;
wire                    m07_axi_arvalid;
reg                     m07_axi_arready = 1;
reg  [ID_WIDTH-1:0]     m07_axi_rid     = 0;
reg  [DATA_WIDTH-1:0]   m07_axi_rdata   = 32'hDEAD_0007;
reg  [1:0]              m07_axi_rresp   = 0;
reg                     m07_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m07_axi_ruser   = 0;
reg                     m07_axi_rvalid  = 0;
wire                    m07_axi_rready;

// -----------------------------------------------------------------------
// Test counters
// -----------------------------------------------------------------------
integer pass_count = 0;
integer fail_count = 0;

// -----------------------------------------------------------------------
// DUT instantiation
// -----------------------------------------------------------------------
axi_interconnect_wrap_2x8 #(
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDR_WIDTH     (ADDR_WIDTH),
    .STRB_WIDTH     (STRB_WIDTH),
    .ID_WIDTH       (ID_WIDTH),
    .AWUSER_WIDTH   (AWUSER_WIDTH),
    .WUSER_WIDTH    (WUSER_WIDTH),
    .BUSER_WIDTH    (BUSER_WIDTH),
    .ARUSER_WIDTH   (ARUSER_WIDTH),
    .RUSER_WIDTH    (RUSER_WIDTH),
    // M_BASE_ADDR = 0 for all -> auto-computed sequential map
    .M00_BASE_ADDR  (0), .M00_ADDR_WIDTH (24),
    .M01_BASE_ADDR  (0), .M01_ADDR_WIDTH (24),
    .M02_BASE_ADDR  (0), .M02_ADDR_WIDTH (24),
    .M03_BASE_ADDR  (0), .M03_ADDR_WIDTH (24),
    .M04_BASE_ADDR  (0), .M04_ADDR_WIDTH (24),
    .M05_BASE_ADDR  (0), .M05_ADDR_WIDTH (24),
    .M06_BASE_ADDR  (0), .M06_ADDR_WIDTH (24),
    .M07_BASE_ADDR  (0), .M07_ADDR_WIDTH (24)
) DUT (
    .clk            (clk),
    .rst            (rst),
    // s00
    .s00_axi_awid   (s00_axi_awid),   .s00_axi_awaddr (s00_axi_awaddr),
    .s00_axi_awlen  (s00_axi_awlen),  .s00_axi_awsize (s00_axi_awsize),
    .s00_axi_awburst(s00_axi_awburst),.s00_axi_awlock (s00_axi_awlock),
    .s00_axi_awcache(s00_axi_awcache),.s00_axi_awprot (s00_axi_awprot),
    .s00_axi_awqos  (s00_axi_awqos),  .s00_axi_awuser (s00_axi_awuser),
    .s00_axi_awvalid(s00_axi_awvalid),.s00_axi_awready(s00_axi_awready),
    .s00_axi_wdata  (s00_axi_wdata),  .s00_axi_wstrb  (s00_axi_wstrb),
    .s00_axi_wlast  (s00_axi_wlast),  .s00_axi_wuser  (s00_axi_wuser),
    .s00_axi_wvalid (s00_axi_wvalid), .s00_axi_wready (s00_axi_wready),
    .s00_axi_bid    (s00_axi_bid),    .s00_axi_bresp  (s00_axi_bresp),
    .s00_axi_buser  (s00_axi_buser),  .s00_axi_bvalid (s00_axi_bvalid),
    .s00_axi_bready (s00_axi_bready),
    .s00_axi_arid   (s00_axi_arid),   .s00_axi_araddr (s00_axi_araddr),
    .s00_axi_arlen  (s00_axi_arlen),  .s00_axi_arsize (s00_axi_arsize),
    .s00_axi_arburst(s00_axi_arburst),.s00_axi_arlock (s00_axi_arlock),
    .s00_axi_arcache(s00_axi_arcache),.s00_axi_arprot (s00_axi_arprot),
    .s00_axi_arqos  (s00_axi_arqos),  .s00_axi_aruser (s00_axi_aruser),
    .s00_axi_arvalid(s00_axi_arvalid),.s00_axi_arready(s00_axi_arready),
    .s00_axi_rid    (s00_axi_rid),    .s00_axi_rdata  (s00_axi_rdata),
    .s00_axi_rresp  (s00_axi_rresp),  .s00_axi_rlast  (s00_axi_rlast),
    .s00_axi_ruser  (s00_axi_ruser),  .s00_axi_rvalid (s00_axi_rvalid),
    .s00_axi_rready (s00_axi_rready),
    // s01
    .s01_axi_awid   (s01_axi_awid),   .s01_axi_awaddr (s01_axi_awaddr),
    .s01_axi_awlen  (s01_axi_awlen),  .s01_axi_awsize (s01_axi_awsize),
    .s01_axi_awburst(s01_axi_awburst),.s01_axi_awlock (s01_axi_awlock),
    .s01_axi_awcache(s01_axi_awcache),.s01_axi_awprot (s01_axi_awprot),
    .s01_axi_awqos  (s01_axi_awqos),  .s01_axi_awuser (s01_axi_awuser),
    .s01_axi_awvalid(s01_axi_awvalid),.s01_axi_awready(s01_axi_awready),
    .s01_axi_wdata  (s01_axi_wdata),  .s01_axi_wstrb  (s01_axi_wstrb),
    .s01_axi_wlast  (s01_axi_wlast),  .s01_axi_wuser  (s01_axi_wuser),
    .s01_axi_wvalid (s01_axi_wvalid), .s01_axi_wready (s01_axi_wready),
    .s01_axi_bid    (s01_axi_bid),    .s01_axi_bresp  (s01_axi_bresp),
    .s01_axi_buser  (s01_axi_buser),  .s01_axi_bvalid (s01_axi_bvalid),
    .s01_axi_bready (s01_axi_bready),
    .s01_axi_arid   (s01_axi_arid),   .s01_axi_araddr (s01_axi_araddr),
    .s01_axi_arlen  (s01_axi_arlen),  .s01_axi_arsize (s01_axi_arsize),
    .s01_axi_arburst(s01_axi_arburst),.s01_axi_arlock (s01_axi_arlock),
    .s01_axi_arcache(s01_axi_arcache),.s01_axi_arprot (s01_axi_arprot),
    .s01_axi_arqos  (s01_axi_arqos),  .s01_axi_aruser (s01_axi_aruser),
    .s01_axi_arvalid(s01_axi_arvalid),.s01_axi_arready(s01_axi_arready),
    .s01_axi_rid    (s01_axi_rid),    .s01_axi_rdata  (s01_axi_rdata),
    .s01_axi_rresp  (s01_axi_rresp),  .s01_axi_rlast  (s01_axi_rlast),
    .s01_axi_ruser  (s01_axi_ruser),  .s01_axi_rvalid (s01_axi_rvalid),
    .s01_axi_rready (s01_axi_rready),
    // m00
    .m00_axi_awid   (m00_axi_awid),   .m00_axi_awaddr (m00_axi_awaddr),
    .m00_axi_awlen  (m00_axi_awlen),  .m00_axi_awsize (m00_axi_awsize),
    .m00_axi_awburst(m00_axi_awburst),.m00_axi_awlock (m00_axi_awlock),
    .m00_axi_awcache(m00_axi_awcache),.m00_axi_awprot (m00_axi_awprot),
    .m00_axi_awqos  (m00_axi_awqos),  .m00_axi_awregion(m00_axi_awregion),
    .m00_axi_awuser (m00_axi_awuser), .m00_axi_awvalid(m00_axi_awvalid),
    .m00_axi_awready(m00_axi_awready),
    .m00_axi_wdata  (m00_axi_wdata),  .m00_axi_wstrb  (m00_axi_wstrb),
    .m00_axi_wlast  (m00_axi_wlast),  .m00_axi_wuser  (m00_axi_wuser),
    .m00_axi_wvalid (m00_axi_wvalid), .m00_axi_wready (m00_axi_wready),
    .m00_axi_bid    (m00_axi_bid),    .m00_axi_bresp  (m00_axi_bresp),
    .m00_axi_buser  (m00_axi_buser),  .m00_axi_bvalid (m00_axi_bvalid),
    .m00_axi_bready (m00_axi_bready),
    .m00_axi_arid   (m00_axi_arid),   .m00_axi_araddr (m00_axi_araddr),
    .m00_axi_arlen  (m00_axi_arlen),  .m00_axi_arsize (m00_axi_arsize),
    .m00_axi_arburst(m00_axi_arburst),.m00_axi_arlock (m00_axi_arlock),
    .m00_axi_arcache(m00_axi_arcache),.m00_axi_arprot (m00_axi_arprot),
    .m00_axi_arqos  (m00_axi_arqos),  .m00_axi_arregion(m00_axi_arregion),
    .m00_axi_aruser (m00_axi_aruser), .m00_axi_arvalid(m00_axi_arvalid),
    .m00_axi_arready(m00_axi_arready),
    .m00_axi_rid    (m00_axi_rid),    .m00_axi_rdata  (m00_axi_rdata),
    .m00_axi_rresp  (m00_axi_rresp),  .m00_axi_rlast  (m00_axi_rlast),
    .m00_axi_ruser  (m00_axi_ruser),  .m00_axi_rvalid (m00_axi_rvalid),
    .m00_axi_rready (m00_axi_rready),
    // m01
    .m01_axi_awid   (m01_axi_awid),   .m01_axi_awaddr (m01_axi_awaddr),
    .m01_axi_awlen  (m01_axi_awlen),  .m01_axi_awsize (m01_axi_awsize),
    .m01_axi_awburst(m01_axi_awburst),.m01_axi_awlock (m01_axi_awlock),
    .m01_axi_awcache(m01_axi_awcache),.m01_axi_awprot (m01_axi_awprot),
    .m01_axi_awqos  (m01_axi_awqos),  .m01_axi_awregion(m01_axi_awregion),
    .m01_axi_awuser (m01_axi_awuser), .m01_axi_awvalid(m01_axi_awvalid),
    .m01_axi_awready(m01_axi_awready),
    .m01_axi_wdata  (m01_axi_wdata),  .m01_axi_wstrb  (m01_axi_wstrb),
    .m01_axi_wlast  (m01_axi_wlast),  .m01_axi_wuser  (m01_axi_wuser),
    .m01_axi_wvalid (m01_axi_wvalid), .m01_axi_wready (m01_axi_wready),
    .m01_axi_bid    (m01_axi_bid),    .m01_axi_bresp  (m01_axi_bresp),
    .m01_axi_buser  (m01_axi_buser),  .m01_axi_bvalid (m01_axi_bvalid),
    .m01_axi_bready (m01_axi_bready),
    .m01_axi_arid   (m01_axi_arid),   .m01_axi_araddr (m01_axi_araddr),
    .m01_axi_arlen  (m01_axi_arlen),  .m01_axi_arsize (m01_axi_arsize),
    .m01_axi_arburst(m01_axi_arburst),.m01_axi_arlock (m01_axi_arlock),
    .m01_axi_arcache(m01_axi_arcache),.m01_axi_arprot (m01_axi_arprot),
    .m01_axi_arqos  (m01_axi_arqos),  .m01_axi_arregion(m01_axi_arregion),
    .m01_axi_aruser (m01_axi_aruser), .m01_axi_arvalid(m01_axi_arvalid),
    .m01_axi_arready(m01_axi_arready),
    .m01_axi_rid    (m01_axi_rid),    .m01_axi_rdata  (m01_axi_rdata),
    .m01_axi_rresp  (m01_axi_rresp),  .m01_axi_rlast  (m01_axi_rlast),
    .m01_axi_ruser  (m01_axi_ruser),  .m01_axi_rvalid (m01_axi_rvalid),
    .m01_axi_rready (m01_axi_rready),
    // m02
    .m02_axi_awid   (m02_axi_awid),   .m02_axi_awaddr (m02_axi_awaddr),
    .m02_axi_awlen  (m02_axi_awlen),  .m02_axi_awsize (m02_axi_awsize),
    .m02_axi_awburst(m02_axi_awburst),.m02_axi_awlock (m02_axi_awlock),
    .m02_axi_awcache(m02_axi_awcache),.m02_axi_awprot (m02_axi_awprot),
    .m02_axi_awqos  (m02_axi_awqos),  .m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser (m02_axi_awuser), .m02_axi_awvalid(m02_axi_awvalid),
    .m02_axi_awready(m02_axi_awready),
    .m02_axi_wdata  (m02_axi_wdata),  .m02_axi_wstrb  (m02_axi_wstrb),
    .m02_axi_wlast  (m02_axi_wlast),  .m02_axi_wuser  (m02_axi_wuser),
    .m02_axi_wvalid (m02_axi_wvalid), .m02_axi_wready (m02_axi_wready),
    .m02_axi_bid    (m02_axi_bid),    .m02_axi_bresp  (m02_axi_bresp),
    .m02_axi_buser  (m02_axi_buser),  .m02_axi_bvalid (m02_axi_bvalid),
    .m02_axi_bready (m02_axi_bready),
    .m02_axi_arid   (m02_axi_arid),   .m02_axi_araddr (m02_axi_araddr),
    .m02_axi_arlen  (m02_axi_arlen),  .m02_axi_arsize (m02_axi_arsize),
    .m02_axi_arburst(m02_axi_arburst),.m02_axi_arlock (m02_axi_arlock),
    .m02_axi_arcache(m02_axi_arcache),.m02_axi_arprot (m02_axi_arprot),
    .m02_axi_arqos  (m02_axi_arqos),  .m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser (m02_axi_aruser), .m02_axi_arvalid(m02_axi_arvalid),
    .m02_axi_arready(m02_axi_arready),
    .m02_axi_rid    (m02_axi_rid),    .m02_axi_rdata  (m02_axi_rdata),
    .m02_axi_rresp  (m02_axi_rresp),  .m02_axi_rlast  (m02_axi_rlast),
    .m02_axi_ruser  (m02_axi_ruser),  .m02_axi_rvalid (m02_axi_rvalid),
    .m02_axi_rready (m02_axi_rready),
    // m03
    .m03_axi_awid   (m03_axi_awid),   .m03_axi_awaddr (m03_axi_awaddr),
    .m03_axi_awlen  (m03_axi_awlen),  .m03_axi_awsize (m03_axi_awsize),
    .m03_axi_awburst(m03_axi_awburst),.m03_axi_awlock (m03_axi_awlock),
    .m03_axi_awcache(m03_axi_awcache),.m03_axi_awprot (m03_axi_awprot),
    .m03_axi_awqos  (m03_axi_awqos),  .m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser (m03_axi_awuser), .m03_axi_awvalid(m03_axi_awvalid),
    .m03_axi_awready(m03_axi_awready),
    .m03_axi_wdata  (m03_axi_wdata),  .m03_axi_wstrb  (m03_axi_wstrb),
    .m03_axi_wlast  (m03_axi_wlast),  .m03_axi_wuser  (m03_axi_wuser),
    .m03_axi_wvalid (m03_axi_wvalid), .m03_axi_wready (m03_axi_wready),
    .m03_axi_bid    (m03_axi_bid),    .m03_axi_bresp  (m03_axi_bresp),
    .m03_axi_buser  (m03_axi_buser),  .m03_axi_bvalid (m03_axi_bvalid),
    .m03_axi_bready (m03_axi_bready),
    .m03_axi_arid   (m03_axi_arid),   .m03_axi_araddr (m03_axi_araddr),
    .m03_axi_arlen  (m03_axi_arlen),  .m03_axi_arsize (m03_axi_arsize),
    .m03_axi_arburst(m03_axi_arburst),.m03_axi_arlock (m03_axi_arlock),
    .m03_axi_arcache(m03_axi_arcache),.m03_axi_arprot (m03_axi_arprot),
    .m03_axi_arqos  (m03_axi_arqos),  .m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser (m03_axi_aruser), .m03_axi_arvalid(m03_axi_arvalid),
    .m03_axi_arready(m03_axi_arready),
    .m03_axi_rid    (m03_axi_rid),    .m03_axi_rdata  (m03_axi_rdata),
    .m03_axi_rresp  (m03_axi_rresp),  .m03_axi_rlast  (m03_axi_rlast),
    .m03_axi_ruser  (m03_axi_ruser),  .m03_axi_rvalid (m03_axi_rvalid),
    .m03_axi_rready (m03_axi_rready),
    // m04
    .m04_axi_awid   (m04_axi_awid),   .m04_axi_awaddr (m04_axi_awaddr),
    .m04_axi_awlen  (m04_axi_awlen),  .m04_axi_awsize (m04_axi_awsize),
    .m04_axi_awburst(m04_axi_awburst),.m04_axi_awlock (m04_axi_awlock),
    .m04_axi_awcache(m04_axi_awcache),.m04_axi_awprot (m04_axi_awprot),
    .m04_axi_awqos  (m04_axi_awqos),  .m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser (m04_axi_awuser), .m04_axi_awvalid(m04_axi_awvalid),
    .m04_axi_awready(m04_axi_awready),
    .m04_axi_wdata  (m04_axi_wdata),  .m04_axi_wstrb  (m04_axi_wstrb),
    .m04_axi_wlast  (m04_axi_wlast),  .m04_axi_wuser  (m04_axi_wuser),
    .m04_axi_wvalid (m04_axi_wvalid), .m04_axi_wready (m04_axi_wready),
    .m04_axi_bid    (m04_axi_bid),    .m04_axi_bresp  (m04_axi_bresp),
    .m04_axi_buser  (m04_axi_buser),  .m04_axi_bvalid (m04_axi_bvalid),
    .m04_axi_bready (m04_axi_bready),
    .m04_axi_arid   (m04_axi_arid),   .m04_axi_araddr (m04_axi_araddr),
    .m04_axi_arlen  (m04_axi_arlen),  .m04_axi_arsize (m04_axi_arsize),
    .m04_axi_arburst(m04_axi_arburst),.m04_axi_arlock (m04_axi_arlock),
    .m04_axi_arcache(m04_axi_arcache),.m04_axi_arprot (m04_axi_arprot),
    .m04_axi_arqos  (m04_axi_arqos),  .m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser (m04_axi_aruser), .m04_axi_arvalid(m04_axi_arvalid),
    .m04_axi_arready(m04_axi_arready),
    .m04_axi_rid    (m04_axi_rid),    .m04_axi_rdata  (m04_axi_rdata),
    .m04_axi_rresp  (m04_axi_rresp),  .m04_axi_rlast  (m04_axi_rlast),
    .m04_axi_ruser  (m04_axi_ruser),  .m04_axi_rvalid (m04_axi_rvalid),
    .m04_axi_rready (m04_axi_rready),
    // m05
    .m05_axi_awid   (m05_axi_awid),   .m05_axi_awaddr (m05_axi_awaddr),
    .m05_axi_awlen  (m05_axi_awlen),  .m05_axi_awsize (m05_axi_awsize),
    .m05_axi_awburst(m05_axi_awburst),.m05_axi_awlock (m05_axi_awlock),
    .m05_axi_awcache(m05_axi_awcache),.m05_axi_awprot (m05_axi_awprot),
    .m05_axi_awqos  (m05_axi_awqos),  .m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser (m05_axi_awuser), .m05_axi_awvalid(m05_axi_awvalid),
    .m05_axi_awready(m05_axi_awready),
    .m05_axi_wdata  (m05_axi_wdata),  .m05_axi_wstrb  (m05_axi_wstrb),
    .m05_axi_wlast  (m05_axi_wlast),  .m05_axi_wuser  (m05_axi_wuser),
    .m05_axi_wvalid (m05_axi_wvalid), .m05_axi_wready (m05_axi_wready),
    .m05_axi_bid    (m05_axi_bid),    .m05_axi_bresp  (m05_axi_bresp),
    .m05_axi_buser  (m05_axi_buser),  .m05_axi_bvalid (m05_axi_bvalid),
    .m05_axi_bready (m05_axi_bready),
    .m05_axi_arid   (m05_axi_arid),   .m05_axi_araddr (m05_axi_araddr),
    .m05_axi_arlen  (m05_axi_arlen),  .m05_axi_arsize (m05_axi_arsize),
    .m05_axi_arburst(m05_axi_arburst),.m05_axi_arlock (m05_axi_arlock),
    .m05_axi_arcache(m05_axi_arcache),.m05_axi_arprot (m05_axi_arprot),
    .m05_axi_arqos  (m05_axi_arqos),  .m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser (m05_axi_aruser), .m05_axi_arvalid(m05_axi_arvalid),
    .m05_axi_arready(m05_axi_arready),
    .m05_axi_rid    (m05_axi_rid),    .m05_axi_rdata  (m05_axi_rdata),
    .m05_axi_rresp  (m05_axi_rresp),  .m05_axi_rlast  (m05_axi_rlast),
    .m05_axi_ruser  (m05_axi_ruser),  .m05_axi_rvalid (m05_axi_rvalid),
    .m05_axi_rready (m05_axi_rready),
    // m06
    .m06_axi_awid   (m06_axi_awid),   .m06_axi_awaddr (m06_axi_awaddr),
    .m06_axi_awlen  (m06_axi_awlen),  .m06_axi_awsize (m06_axi_awsize),
    .m06_axi_awburst(m06_axi_awburst),.m06_axi_awlock (m06_axi_awlock),
    .m06_axi_awcache(m06_axi_awcache),.m06_axi_awprot (m06_axi_awprot),
    .m06_axi_awqos  (m06_axi_awqos),  .m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser (m06_axi_awuser), .m06_axi_awvalid(m06_axi_awvalid),
    .m06_axi_awready(m06_axi_awready),
    .m06_axi_wdata  (m06_axi_wdata),  .m06_axi_wstrb  (m06_axi_wstrb),
    .m06_axi_wlast  (m06_axi_wlast),  .m06_axi_wuser  (m06_axi_wuser),
    .m06_axi_wvalid (m06_axi_wvalid), .m06_axi_wready (m06_axi_wready),
    .m06_axi_bid    (m06_axi_bid),    .m06_axi_bresp  (m06_axi_bresp),
    .m06_axi_buser  (m06_axi_buser),  .m06_axi_bvalid (m06_axi_bvalid),
    .m06_axi_bready (m06_axi_bready),
    .m06_axi_arid   (m06_axi_arid),   .m06_axi_araddr (m06_axi_araddr),
    .m06_axi_arlen  (m06_axi_arlen),  .m06_axi_arsize (m06_axi_arsize),
    .m06_axi_arburst(m06_axi_arburst),.m06_axi_arlock (m06_axi_arlock),
    .m06_axi_arcache(m06_axi_arcache),.m06_axi_arprot (m06_axi_arprot),
    .m06_axi_arqos  (m06_axi_arqos),  .m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser (m06_axi_aruser), .m06_axi_arvalid(m06_axi_arvalid),
    .m06_axi_arready(m06_axi_arready),
    .m06_axi_rid    (m06_axi_rid),    .m06_axi_rdata  (m06_axi_rdata),
    .m06_axi_rresp  (m06_axi_rresp),  .m06_axi_rlast  (m06_axi_rlast),
    .m06_axi_ruser  (m06_axi_ruser),  .m06_axi_rvalid (m06_axi_rvalid),
    .m06_axi_rready (m06_axi_rready),
    // m07
    .m07_axi_awid   (m07_axi_awid),   .m07_axi_awaddr (m07_axi_awaddr),
    .m07_axi_awlen  (m07_axi_awlen),  .m07_axi_awsize (m07_axi_awsize),
    .m07_axi_awburst(m07_axi_awburst),.m07_axi_awlock (m07_axi_awlock),
    .m07_axi_awcache(m07_axi_awcache),.m07_axi_awprot (m07_axi_awprot),
    .m07_axi_awqos  (m07_axi_awqos),  .m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser (m07_axi_awuser), .m07_axi_awvalid(m07_axi_awvalid),
    .m07_axi_awready(m07_axi_awready),
    .m07_axi_wdata  (m07_axi_wdata),  .m07_axi_wstrb  (m07_axi_wstrb),
    .m07_axi_wlast  (m07_axi_wlast),  .m07_axi_wuser  (m07_axi_wuser),
    .m07_axi_wvalid (m07_axi_wvalid), .m07_axi_wready (m07_axi_wready),
    .m07_axi_bid    (m07_axi_bid),    .m07_axi_bresp  (m07_axi_bresp),
    .m07_axi_buser  (m07_axi_buser),  .m07_axi_bvalid (m07_axi_bvalid),
    .m07_axi_bready (m07_axi_bready),
    .m07_axi_arid   (m07_axi_arid),   .m07_axi_araddr (m07_axi_araddr),
    .m07_axi_arlen  (m07_axi_arlen),  .m07_axi_arsize (m07_axi_arsize),
    .m07_axi_arburst(m07_axi_arburst),.m07_axi_arlock (m07_axi_arlock),
    .m07_axi_arcache(m07_axi_arcache),.m07_axi_arprot (m07_axi_arprot),
    .m07_axi_arqos  (m07_axi_arqos),  .m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser (m07_axi_aruser), .m07_axi_arvalid(m07_axi_arvalid),
    .m07_axi_arready(m07_axi_arready),
    .m07_axi_rid    (m07_axi_rid),    .m07_axi_rdata  (m07_axi_rdata),
    .m07_axi_rresp  (m07_axi_rresp),  .m07_axi_rlast  (m07_axi_rlast),
    .m07_axi_ruser  (m07_axi_ruser),  .m07_axi_rvalid (m07_axi_rvalid),
    .m07_axi_rready (m07_axi_rready)
);

// -----------------------------------------------------------------------
// Slave responder models (always blocks)
// Each slave:
//   - accepts AW+W and drives B response
//   - accepts AR and drives R response
// Slave 0 (m00) uses a per-beat counter so it can drive RLAST correctly
// for burst reads.  Slaves 1-7 are identical and handle single beats plus
// simple bursts the same way.
// -----------------------------------------------------------------------

// --- Slave 0 (m00) ---
reg [7:0] m00_rd_beat_cnt = 0;
reg [7:0] m00_wr_beat_cnt = 0;
reg [7:0] m00_wr_len_latch = 0;

always @(posedge clk) begin
    if (rst) begin
        m00_axi_bvalid  <= 0;
        m00_axi_rvalid  <= 0;
        m00_wr_beat_cnt <= 0;
    end else begin
        // Write: accept AW, count W beats, fire B
        if (m00_axi_awvalid && m00_axi_awready) begin
            m00_wr_len_latch <= m00_axi_awlen;
            m00_wr_beat_cnt  <= 0;
        end
        if (m00_axi_wvalid && m00_axi_wready) begin
            if (m00_axi_wlast) begin
                m00_axi_bid    <= m00_axi_awid;
                m00_axi_bresp  <= 2'b00;
                m00_axi_bvalid <= 1'b1;
            end
        end
        if (m00_axi_bvalid && m00_axi_bready)
            m00_axi_bvalid <= 1'b0;

        // Read: accept AR, drive R beats
        if (m00_axi_arvalid && m00_axi_arready) begin
            m00_rd_beat_cnt <= m00_axi_arlen;
            m00_axi_rid     <= m00_axi_arid;
            m00_axi_rresp   <= 2'b00;
            m00_axi_rdata   <= 32'h1234_5678;
            m00_axi_rlast   <= (m00_axi_arlen == 0);
            m00_axi_rvalid  <= 1'b1;
        end else if (m00_axi_rvalid && m00_axi_rready) begin
            if (m00_axi_rlast) begin
                m00_axi_rvalid <= 1'b0;
            end else begin
                m00_rd_beat_cnt <= m00_rd_beat_cnt - 1;
                m00_axi_rdata   <= m00_axi_rdata + 1;
                m00_axi_rlast   <= (m00_rd_beat_cnt == 1);
            end
        end
    end
end

// --- Generic slave macro (slaves 1-7) ---
// Slave 1 (m01)
reg [7:0] m01_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin
        m01_axi_bvalid <= 0; m01_axi_rvalid <= 0;
    end else begin
        if (m01_axi_awvalid && m01_axi_awready) begin end // latch if needed
        if (m01_axi_wvalid && m01_axi_wready && m01_axi_wlast) begin
            m01_axi_bid <= m01_axi_awid; m01_axi_bresp <= 2'b00; m01_axi_bvalid <= 1;
        end
        if (m01_axi_bvalid && m01_axi_bready) m01_axi_bvalid <= 0;
        if (m01_axi_arvalid && m01_axi_arready) begin
            m01_rd_cnt <= m01_axi_arlen; m01_axi_rid <= m01_axi_arid;
            m01_axi_rresp <= 0; m01_axi_rdata <= 32'hDEAD_0001;
            m01_axi_rlast <= (m01_axi_arlen == 0); m01_axi_rvalid <= 1;
        end else if (m01_axi_rvalid && m01_axi_rready) begin
            if (m01_axi_rlast) begin m01_axi_rvalid <= 0; end
            else begin m01_rd_cnt <= m01_rd_cnt-1; m01_axi_rdata <= m01_axi_rdata+1;
                m01_axi_rlast <= (m01_rd_cnt == 1); end
        end
    end
end

// Slave 2 (m02)
reg [7:0] m02_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m02_axi_bvalid <= 0; m02_axi_rvalid <= 0; end
    else begin
        if (m02_axi_wvalid && m02_axi_wready && m02_axi_wlast) begin
            m02_axi_bid <= m02_axi_awid; m02_axi_bresp <= 0; m02_axi_bvalid <= 1;
        end
        if (m02_axi_bvalid && m02_axi_bready) m02_axi_bvalid <= 0;
        if (m02_axi_arvalid && m02_axi_arready) begin
            m02_rd_cnt <= m02_axi_arlen; m02_axi_rid <= m02_axi_arid;
            m02_axi_rresp <= 0; m02_axi_rdata <= 32'hDEAD_0002;
            m02_axi_rlast <= (m02_axi_arlen == 0); m02_axi_rvalid <= 1;
        end else if (m02_axi_rvalid && m02_axi_rready) begin
            if (m02_axi_rlast) m02_axi_rvalid <= 0;
            else begin m02_rd_cnt <= m02_rd_cnt-1; m02_axi_rdata <= m02_axi_rdata+1;
                m02_axi_rlast <= (m02_rd_cnt == 1); end
        end
    end
end

// Slave 3 (m03)
reg [7:0] m03_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m03_axi_bvalid <= 0; m03_axi_rvalid <= 0; end
    else begin
        if (m03_axi_wvalid && m03_axi_wready && m03_axi_wlast) begin
            m03_axi_bid <= m03_axi_awid; m03_axi_bresp <= 0; m03_axi_bvalid <= 1;
        end
        if (m03_axi_bvalid && m03_axi_bready) m03_axi_bvalid <= 0;
        if (m03_axi_arvalid && m03_axi_arready) begin
            m03_rd_cnt <= m03_axi_arlen; m03_axi_rid <= m03_axi_arid;
            m03_axi_rresp <= 0; m03_axi_rdata <= 32'hDEAD_0003;
            m03_axi_rlast <= (m03_axi_arlen == 0); m03_axi_rvalid <= 1;
        end else if (m03_axi_rvalid && m03_axi_rready) begin
            if (m03_axi_rlast) m03_axi_rvalid <= 0;
            else begin m03_rd_cnt <= m03_rd_cnt-1; m03_axi_rdata <= m03_axi_rdata+1;
                m03_axi_rlast <= (m03_rd_cnt == 1); end
        end
    end
end

// Slave 4 (m04)
reg [7:0] m04_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m04_axi_bvalid <= 0; m04_axi_rvalid <= 0; end
    else begin
        if (m04_axi_wvalid && m04_axi_wready && m04_axi_wlast) begin
            m04_axi_bid <= m04_axi_awid; m04_axi_bresp <= 0; m04_axi_bvalid <= 1;
        end
        if (m04_axi_bvalid && m04_axi_bready) m04_axi_bvalid <= 0;
        if (m04_axi_arvalid && m04_axi_arready) begin
            m04_rd_cnt <= m04_axi_arlen; m04_axi_rid <= m04_axi_arid;
            m04_axi_rresp <= 0; m04_axi_rdata <= 32'hDEAD_0004;
            m04_axi_rlast <= (m04_axi_arlen == 0); m04_axi_rvalid <= 1;
        end else if (m04_axi_rvalid && m04_axi_rready) begin
            if (m04_axi_rlast) m04_axi_rvalid <= 0;
            else begin m04_rd_cnt <= m04_rd_cnt-1; m04_axi_rdata <= m04_axi_rdata+1;
                m04_axi_rlast <= (m04_rd_cnt == 1); end
        end
    end
end

// Slave 5 (m05)
reg [7:0] m05_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m05_axi_bvalid <= 0; m05_axi_rvalid <= 0; end
    else begin
        if (m05_axi_wvalid && m05_axi_wready && m05_axi_wlast) begin
            m05_axi_bid <= m05_axi_awid; m05_axi_bresp <= 0; m05_axi_bvalid <= 1;
        end
        if (m05_axi_bvalid && m05_axi_bready) m05_axi_bvalid <= 0;
        if (m05_axi_arvalid && m05_axi_arready) begin
            m05_rd_cnt <= m05_axi_arlen; m05_axi_rid <= m05_axi_arid;
            m05_axi_rresp <= 0; m05_axi_rdata <= 32'hDEAD_0005;
            m05_axi_rlast <= (m05_axi_arlen == 0); m05_axi_rvalid <= 1;
        end else if (m05_axi_rvalid && m05_axi_rready) begin
            if (m05_axi_rlast) m05_axi_rvalid <= 0;
            else begin m05_rd_cnt <= m05_rd_cnt-1; m05_axi_rdata <= m05_axi_rdata+1;
                m05_axi_rlast <= (m05_rd_cnt == 1); end
        end
    end
end

// Slave 6 (m06)
reg [7:0] m06_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m06_axi_bvalid <= 0; m06_axi_rvalid <= 0; end
    else begin
        if (m06_axi_wvalid && m06_axi_wready && m06_axi_wlast) begin
            m06_axi_bid <= m06_axi_awid; m06_axi_bresp <= 0; m06_axi_bvalid <= 1;
        end
        if (m06_axi_bvalid && m06_axi_bready) m06_axi_bvalid <= 0;
        if (m06_axi_arvalid && m06_axi_arready) begin
            m06_rd_cnt <= m06_axi_arlen; m06_axi_rid <= m06_axi_arid;
            m06_axi_rresp <= 0; m06_axi_rdata <= 32'hDEAD_0006;
            m06_axi_rlast <= (m06_axi_arlen == 0); m06_axi_rvalid <= 1;
        end else if (m06_axi_rvalid && m06_axi_rready) begin
            if (m06_axi_rlast) m06_axi_rvalid <= 0;
            else begin m06_rd_cnt <= m06_rd_cnt-1; m06_axi_rdata <= m06_axi_rdata+1;
                m06_axi_rlast <= (m06_rd_cnt == 1); end
        end
    end
end

// Slave 7 (m07)
reg [7:0] m07_rd_cnt = 0;
always @(posedge clk) begin
    if (rst) begin m07_axi_bvalid <= 0; m07_axi_rvalid <= 0; end
    else begin
        if (m07_axi_wvalid && m07_axi_wready && m07_axi_wlast) begin
            m07_axi_bid <= m07_axi_awid; m07_axi_bresp <= 0; m07_axi_bvalid <= 1;
        end
        if (m07_axi_bvalid && m07_axi_bready) m07_axi_bvalid <= 0;
        if (m07_axi_arvalid && m07_axi_arready) begin
            m07_rd_cnt <= m07_axi_arlen; m07_axi_rid <= m07_axi_arid;
            m07_axi_rresp <= 0; m07_axi_rdata <= 32'hDEAD_0007;
            m07_axi_rlast <= (m07_axi_arlen == 0); m07_axi_rvalid <= 1;
        end else if (m07_axi_rvalid && m07_axi_rready) begin
            if (m07_axi_rlast) m07_axi_rvalid <= 0;
            else begin m07_rd_cnt <= m07_rd_cnt-1; m07_axi_rdata <= m07_axi_rdata+1;
                m07_axi_rlast <= (m07_rd_cnt == 1); end
        end
    end
end

// -----------------------------------------------------------------------
// Utility task: wait N clock cycles
// -----------------------------------------------------------------------
task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            @(posedge clk);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 WRITE task – Master 0 (s00_axi)
//   addr  : byte address
//   data  : write data (single beat; awlen=0)
//   id    : AWID
//   bresp : output – captured BRESP
// -----------------------------------------------------------------------
task m0_axi_write;
    input  [31:0] addr;
    input  [31:0] data;
    input  [7:0]  id;
    output [1:0]  bresp;
    integer timeout;
    begin
        // Drive AW channel
        @(negedge clk);
        s00_axi_awid    = id;
        s00_axi_awaddr  = addr;
        s00_axi_awlen   = 8'd0;        // 1 beat
        s00_axi_awsize  = 3'b010;      // 4 bytes
        s00_axi_awburst = 2'b01;       // INCR
        s00_axi_awvalid = 1'b1;

        // Drive W channel simultaneously
        s00_axi_wdata   = data;
        s00_axi_wstrb   = 4'hF;
        s00_axi_wlast   = 1'b1;
        s00_axi_wvalid  = 1'b1;

        // Wait for AW handshake
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_awready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_WRITE] TIMEOUT waiting for AWREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s00_axi_awvalid = 1'b0;

        // Wait for W handshake
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_wready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_WRITE] TIMEOUT waiting for WREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s00_axi_wvalid = 1'b0;
        s00_axi_wlast  = 1'b0;

        // Wait for B response
        s00_axi_bready = 1'b1;
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_bvalid && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_WRITE] TIMEOUT waiting for BVALID addr=0x%08h", addr);
            fail_count = fail_count + 1;
            bresp = 2'b11;
        end else begin
            bresp = s00_axi_bresp;
        end
        @(negedge clk);
        s00_axi_bready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 READ task – Master 0 (s00_axi)
// -----------------------------------------------------------------------
task m0_axi_read;
    input  [31:0] addr;
    input  [7:0]  id;
    output [31:0] rdata;
    output [1:0]  rresp;
    integer timeout;
    begin
        @(negedge clk);
        s00_axi_arid    = id;
        s00_axi_araddr  = addr;
        s00_axi_arlen   = 8'd0;
        s00_axi_arsize  = 3'b010;
        s00_axi_arburst = 2'b01;
        s00_axi_arvalid = 1'b1;
        s00_axi_rready  = 1'b1;

        // Wait for AR handshake
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_arready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_READ] TIMEOUT waiting for ARREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s00_axi_arvalid = 1'b0;

        // Wait for R beat
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_rvalid && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_READ] TIMEOUT waiting for RVALID addr=0x%08h", addr);
            fail_count = fail_count + 1;
            rdata = 32'hDEAD_BEEF;
            rresp = 2'b11;
        end else begin
            rdata = s00_axi_rdata;
            rresp = s00_axi_rresp;
        end
        @(negedge clk);
        s00_axi_rready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 WRITE task – Master 1 (s01_axi)
// -----------------------------------------------------------------------
task m1_axi_write;
    input  [31:0] addr;
    input  [31:0] data;
    input  [7:0]  id;
    output [1:0]  bresp;
    integer timeout;
    begin
        @(negedge clk);
        s01_axi_awid    = id;
        s01_axi_awaddr  = addr;
        s01_axi_awlen   = 8'd0;
        s01_axi_awsize  = 3'b010;
        s01_axi_awburst = 2'b01;
        s01_axi_awvalid = 1'b1;
        s01_axi_wdata   = data;
        s01_axi_wstrb   = 4'hF;
        s01_axi_wlast   = 1'b1;
        s01_axi_wvalid  = 1'b1;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s01_axi_awready && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M1_WRITE] TIMEOUT AWREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s01_axi_awvalid = 1'b0;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s01_axi_wready && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M1_WRITE] TIMEOUT WREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s01_axi_wvalid = 1'b0;
        s01_axi_wlast  = 1'b0;

        s01_axi_bready = 1'b1;
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s01_axi_bvalid && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M1_WRITE] TIMEOUT BVALID addr=0x%08h", addr);
            fail_count = fail_count + 1;
            bresp = 2'b11;
        end else begin
            bresp = s01_axi_bresp;
        end
        @(negedge clk);
        s01_axi_bready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 READ task – Master 1 (s01_axi)
// -----------------------------------------------------------------------
task m1_axi_read;
    input  [31:0] addr;
    input  [7:0]  id;
    output [31:0] rdata;
    output [1:0]  rresp;
    integer timeout;
    begin
        @(negedge clk);
        s01_axi_arid    = id;
        s01_axi_araddr  = addr;
        s01_axi_arlen   = 8'd0;
        s01_axi_arsize  = 3'b010;
        s01_axi_arburst = 2'b01;
        s01_axi_arvalid = 1'b1;
        s01_axi_rready  = 1'b1;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s01_axi_arready && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M1_READ] TIMEOUT ARREADY addr=0x%08h", addr);
            fail_count = fail_count + 1;
        end
        @(negedge clk);
        s01_axi_arvalid = 1'b0;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s01_axi_rvalid && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M1_READ] TIMEOUT RVALID addr=0x%08h", addr);
            fail_count = fail_count + 1;
            rdata = 32'hDEAD_BEEF;
            rresp = 2'b11;
        end else begin
            rdata = s01_axi_rdata;
            rresp = s01_axi_rresp;
        end
        @(negedge clk);
        s01_axi_rready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 BURST WRITE task – Master 0
//   len_beats : number of beats (1-16); awlen = len_beats-1
// -----------------------------------------------------------------------
task m0_axi_burst_write;
    input  [31:0] addr;
    input  [7:0]  num_beats; // 1..16
    input  [7:0]  id;
    output [1:0]  bresp;
    integer timeout, beat;
    begin
        @(negedge clk);
        s00_axi_awid    = id;
        s00_axi_awaddr  = addr;
        s00_axi_awlen   = num_beats - 1;
        s00_axi_awsize  = 3'b010;
        s00_axi_awburst = 2'b01;   // INCR
        s00_axi_awvalid = 1'b1;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_awready && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_BURST_WRITE] TIMEOUT AWREADY"); fail_count = fail_count+1;
        end
        @(negedge clk);
        s00_axi_awvalid = 1'b0;

        // Send W beats
        for (beat = 0; beat < num_beats; beat = beat + 1) begin
            @(negedge clk);
            s00_axi_wdata  = 32'hA000_0000 | beat;
            s00_axi_wstrb  = 4'hF;
            s00_axi_wlast  = (beat == num_beats - 1);
            s00_axi_wvalid = 1'b1;
            timeout = TIMEOUT_CYCLES;
            @(posedge clk);
            while (!s00_axi_wready && timeout > 0) begin
                timeout = timeout - 1; @(posedge clk);
            end
            if (timeout == 0) begin
                $error("[M0_BURST_WRITE] TIMEOUT WREADY beat=%0d", beat);
                fail_count = fail_count + 1;
            end
        end
        @(negedge clk);
        s00_axi_wvalid = 1'b0;
        s00_axi_wlast  = 1'b0;

        s00_axi_bready = 1'b1;
        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_bvalid && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_BURST_WRITE] TIMEOUT BVALID"); fail_count = fail_count+1;
            bresp = 2'b11;
        end else begin
            bresp = s00_axi_bresp;
        end
        @(negedge clk);
        s00_axi_bready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// AXI4 BURST READ task – Master 0
// -----------------------------------------------------------------------
task m0_axi_burst_read;
    input  [31:0] addr;
    input  [7:0]  num_beats;
    input  [7:0]  id;
    output [1:0]  rresp_last;
    integer timeout, beat;
    reg [31:0] tmp_data;
    reg [1:0]  tmp_resp;
    begin
        @(negedge clk);
        s00_axi_arid    = id;
        s00_axi_araddr  = addr;
        s00_axi_arlen   = num_beats - 1;
        s00_axi_arsize  = 3'b010;
        s00_axi_arburst = 2'b01;
        s00_axi_arvalid = 1'b1;
        s00_axi_rready  = 1'b1;

        timeout = TIMEOUT_CYCLES;
        @(posedge clk);
        while (!s00_axi_arready && timeout > 0) begin
            timeout = timeout - 1; @(posedge clk);
        end
        if (timeout == 0) begin
            $error("[M0_BURST_READ] TIMEOUT ARREADY"); fail_count = fail_count+1;
        end
        @(negedge clk);
        s00_axi_arvalid = 1'b0;

        // Receive R beats
        rresp_last = 2'b00;
        for (beat = 0; beat < num_beats; beat = beat + 1) begin
            timeout = TIMEOUT_CYCLES;
            @(posedge clk);
            while (!s00_axi_rvalid && timeout > 0) begin
                timeout = timeout - 1; @(posedge clk);
            end
            if (timeout == 0) begin
                $error("[M0_BURST_READ] TIMEOUT RVALID beat=%0d", beat);
                fail_count = fail_count+1;
            end else begin
                tmp_data = s00_axi_rdata;
                tmp_resp = s00_axi_rresp;
                if (beat == num_beats - 1) begin
                    rresp_last = tmp_resp;
                    if (!s00_axi_rlast)
                        $error("[M0_BURST_READ] RLAST not set on last beat=%0d", beat);
                end
            end
            @(negedge clk);
        end
        s00_axi_rready = 1'b0;
        wait_cycles(2);
    end
endtask

// -----------------------------------------------------------------------
// Main test stimulus
// -----------------------------------------------------------------------
integer tc_bresp;
integer tc_rresp;
reg [31:0] tc_rdata;
reg [1:0]  tmp_bresp;
reg [1:0]  tmp_rresp;
reg [31:0] tmp_rdata;

initial begin
    // Waveform dump
    $dumpfile("axi_interconnect_tb.vcd");
    $dumpvars(0, axi_interconnect_tb);

    $display("=================================================");
    $display(" AXI4 2x8 Interconnect Testbench Starting");
    $display("=================================================");

    // -------------------------------------------------------
    // Reset sequence (active high)
    // -------------------------------------------------------
    rst = 1'b1;
    s00_axi_awvalid = 0; s00_axi_wvalid = 0; s00_axi_bready = 1;
    s00_axi_arvalid = 0; s00_axi_rready = 1;
    s01_axi_awvalid = 0; s01_axi_wvalid = 0; s01_axi_bready = 1;
    s01_axi_arvalid = 0; s01_axi_rready = 1;
    wait_cycles(10);
    rst = 1'b0;
    wait_cycles(5);
    $display("[RESET] Released at time %0t", $time);

    // =====================================================
    // TC1 – Master 0 single write to Slave 0 (M00)
    //        Address: 0x0000_0010 (within M00: 0x0000_0000–0x00FF_FFFF)
    // =====================================================
    $display("\n--- TC1: M0 single write to Slave 0 ---");
    m0_axi_write(32'h0000_0010, 32'hCAFE_BABE, 8'h01, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC1 PASS] M0 write to Slave0: BRESP=OKAY");
        pass_count = pass_count + 1;
    end else begin
        $error("[TC1 FAIL] M0 write to Slave0: BRESP=0x%0h (expected OKAY)", tmp_bresp);
        fail_count = fail_count + 1;
    end
    // Verify AW reached m00
    // (Functional check: the write completed successfully through m00 B response)

    // =====================================================
    // TC2 – Master 0 single read from Slave 0
    //        Slave 0 returns 32'h1234_5678
    // =====================================================
    $display("\n--- TC2: M0 single read from Slave 0 ---");
    m0_axi_read(32'h0000_0010, 8'h02, tmp_rdata, tmp_rresp);
    if (tmp_rresp === 2'b00) begin
        $display("[TC2] RRESP=OKAY, RDATA=0x%08h", tmp_rdata);
        if (tmp_rdata === 32'h1234_5678) begin
            $display("[TC2 PASS] RDATA matches expected 0x12345678");
            pass_count = pass_count + 1;
        end else begin
            $error("[TC2 FAIL] RDATA=0x%08h expected 0x12345678", tmp_rdata);
            fail_count = fail_count + 1;
        end
    end else begin
        $error("[TC2 FAIL] RRESP=0x%0h (expected OKAY)", tmp_rresp);
        fail_count = fail_count + 1;
    end

    // =====================================================
    // TC3 – Master 1 write and read to Slave 1 (M01)
    //        Address: 0x0100_0010
    // =====================================================
    $display("\n--- TC3: M1 write+read to Slave 1 ---");
    m1_axi_write(32'h0100_0010, 32'h1111_2222, 8'h10, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC3a PASS] M1 write to Slave1: BRESP=OKAY");
        pass_count = pass_count + 1;
    end else begin
        $error("[TC3a FAIL] M1 write Slave1: BRESP=0x%0h", tmp_bresp);
        fail_count = fail_count + 1;
    end

    m1_axi_read(32'h0100_0010, 8'h11, tmp_rdata, tmp_rresp);
    if (tmp_rresp === 2'b00) begin
        $display("[TC3b PASS] M1 read Slave1: RRESP=OKAY RDATA=0x%08h", tmp_rdata);
        pass_count = pass_count + 1;
    end else begin
        $error("[TC3b FAIL] M1 read Slave1: RRESP=0x%0h", tmp_rresp);
        fail_count = fail_count + 1;
    end

    // =====================================================
    // TC4 – Address decoding: target all 8 slaves
    //        One write per slave from Master 0
    // =====================================================
    $display("\n--- TC4: Address decoding - all 8 slaves ---");

    // Slave 0
    m0_axi_write(32'h0000_0004, 32'hAAAA_0000, 8'h20, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave0 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave0 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 1
    m0_axi_write(32'h0100_0004, 32'hAAAA_0001, 8'h21, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave1 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave1 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 2
    m0_axi_write(32'h0200_0004, 32'hAAAA_0002, 8'h22, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave2 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave2 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 3
    m0_axi_write(32'h0300_0004, 32'hAAAA_0003, 8'h23, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave3 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave3 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 4
    m0_axi_write(32'h0400_0004, 32'hAAAA_0004, 8'h24, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave4 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave4 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 5
    m0_axi_write(32'h0500_0004, 32'hAAAA_0005, 8'h25, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave5 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave5 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 6
    m0_axi_write(32'h0600_0004, 32'hAAAA_0006, 8'h26, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave6 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave6 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Slave 7
    m0_axi_write(32'h0700_0004, 32'hAAAA_0007, 8'h27, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC4 PASS] Slave7 write OKAY"); pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave7 write BRESP=0x%0h", tmp_bresp); fail_count = fail_count+1;
    end

    // Verify reads hit correct slaves (spot-check m02 and m05)
    m0_axi_read(32'h0200_0004, 8'h30, tmp_rdata, tmp_rresp);
    if (tmp_rresp === 2'b00 && tmp_rdata === 32'hDEAD_0002) begin
        $display("[TC4 PASS] Slave2 read routed correctly RDATA=0x%08h", tmp_rdata);
        pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave2 read: RRESP=0x%0h RDATA=0x%08h", tmp_rresp, tmp_rdata);
        fail_count = fail_count+1;
    end

    m0_axi_read(32'h0500_0004, 8'h31, tmp_rdata, tmp_rresp);
    if (tmp_rresp === 2'b00 && tmp_rdata === 32'hDEAD_0005) begin
        $display("[TC4 PASS] Slave5 read routed correctly RDATA=0x%08h", tmp_rdata);
        pass_count = pass_count+1;
    end else begin
        $error("[TC4 FAIL] Slave5 read: RRESP=0x%0h RDATA=0x%08h", tmp_rresp, tmp_rdata);
        fail_count = fail_count+1;
    end

    // =====================================================
    // TC5 – Arbitration: M0 and M1 issue writes
    //        simultaneously to different slaves
    //        M0 -> Slave 3 (0x0300_0008)
    //        M1 -> Slave 4 (0x0400_0008)
    //        Both are forked but since this is sequential
    //        Verilog-2001, we issue one at a time but
    //        tightly spaced to hit the arbiter
    // =====================================================
    $display("\n--- TC5: Arbitration test ---");
    // Issue M0 write – the interconnect is single-transaction
    // (shared-bus arbiter), so both will complete in order
    fork
        begin
            m0_axi_write(32'h0300_0008, 32'h5555_0000, 8'h40, tmp_bresp);
            if (tmp_bresp === 2'b00)
                $display("[TC5 PASS] Arb: M0->Slave3 BRESP=OKAY");
            else begin
                $error("[TC5 FAIL] Arb: M0->Slave3 BRESP=0x%0h", tmp_bresp);
                fail_count = fail_count+1;
            end
        end
        begin
            // Small offset so both hit the arbiter nearly simultaneously
            wait_cycles(1);
            m1_axi_write(32'h0400_0008, 32'h5555_0001, 8'h41, tmp_bresp);
            if (tmp_bresp === 2'b00)
                $display("[TC5 PASS] Arb: M1->Slave4 BRESP=OKAY");
            else begin
                $error("[TC5 FAIL] Arb: M1->Slave4 BRESP=0x%0h", tmp_bresp);
                fail_count = fail_count+1;
            end
        end
    join
    pass_count = pass_count + 1; // both completed without timeout
    $display("[TC5] Both arbitration transactions completed");

    // =====================================================
    // TC6 – Back-pressure test
    //        Hold slave AWREADY/WREADY/ARREADY low for
    //        several cycles, then release.
    // =====================================================
    $display("\n--- TC6: Back-pressure test ---");

    // Lower AWREADY and WREADY on slave 0 for 5 cycles
    m00_axi_awready = 1'b0;
    m00_axi_wready  = 1'b0;
    m00_axi_arready = 1'b0;

    // Issue write – should stall until we release
    // Launch write in background via a simple wait approach
    fork
        begin
            // After 6 cycles, release back-pressure
            wait_cycles(6);
            m00_axi_awready = 1'b1;
            m00_axi_wready  = 1'b1;
            m00_axi_arready = 1'b1;
        end
        begin
            m0_axi_write(32'h0000_0020, 32'hBACK_PRES, 8'h50, tmp_bresp);
            if (tmp_bresp === 2'b00) begin
                $display("[TC6a PASS] Back-pressure write completed BRESP=OKAY");
                pass_count = pass_count+1;
            end else begin
                $error("[TC6a FAIL] Back-pressure write BRESP=0x%0h", tmp_bresp);
                fail_count = fail_count+1;
            end
        end
    join

    // Back-pressure on BREADY (master holds bready low)
    s00_axi_bready = 1'b0;
    fork
        begin
            wait_cycles(8);
            s00_axi_bready = 1'b1;
        end
        begin
            m0_axi_write(32'h0000_0024, 32'hBACK_0002, 8'h51, tmp_bresp);
            if (tmp_bresp === 2'b00) begin
                $display("[TC6b PASS] BREADY back-pressure write completed OKAY");
                pass_count = pass_count+1;
            end else begin
                $error("[TC6b FAIL] BREADY back-pressure BRESP=0x%0h", tmp_bresp);
                fail_count = fail_count+1;
            end
        end
    join

    // Back-pressure on RREADY (master holds rready low for read)
    s00_axi_rready = 1'b0;
    fork
        begin
            wait_cycles(8);
            s00_axi_rready = 1'b1;
        end
        begin
            m0_axi_read(32'h0000_0020, 8'h52, tmp_rdata, tmp_rresp);
            if (tmp_rresp === 2'b00) begin
                $display("[TC6c PASS] RREADY back-pressure read completed OKAY");
                pass_count = pass_count+1;
            end else begin
                $error("[TC6c FAIL] RREADY back-pressure RRESP=0x%0h", tmp_rresp);
                fail_count = fail_count+1;
            end
        end
    join

    // =====================================================
    // TC7 – Burst transaction (4-beat INCR write + read)
    //        Address: 0x0100_0100 -> Slave 1
    // =====================================================
    $display("\n--- TC7: 4-beat burst write + read ---");
    m0_axi_burst_write(32'h0100_0100, 8'd4, 8'h60, tmp_bresp);
    if (tmp_bresp === 2'b00) begin
        $display("[TC7a PASS] 4-beat burst write BRESP=OKAY");
        pass_count = pass_count+1;
    end else begin
        $error("[TC7a FAIL] 4-beat burst write BRESP=0x%0h", tmp_bresp);
        fail_count = fail_count+1;
    end

    m0_axi_burst_read(32'h0100_0100, 8'd4, 8'h61, tmp_rresp);
    if (tmp_rresp === 2'b00) begin
        $display("[TC7b PASS] 4-beat burst read RRESP=OKAY on last beat");
        pass_count = pass_count+1;
    end else begin
        $error("[TC7b FAIL] 4-beat burst read RRESP=0x%0h", tmp_rresp);
        fail_count = fail_count+1;
    end

    // =====================================================
    // Summary
    // =====================================================
    wait_cycles(10);
    $display("\n=================================================");
    $display(" SIMULATION COMPLETE");
    $display(" PASSED : %0d", pass_count);
    $display(" FAILED : %0d", fail_count);
    if (fail_count == 0)
        $display(" OVERALL RESULT: *** PASS ***");
    else
        $display(" OVERALL RESULT: *** FAIL ***");
    $display("=================================================");
    $finish;
end

initial begin
    $fsdbDumpfile("dumpfsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA();
    $fadbDumpMDA();
end

endmodule
