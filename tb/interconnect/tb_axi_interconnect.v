// Language: Verilog 2001
// =============================================================================
// Testbench: axi_interconnect_wrap_2x8 – Single Write Transaction Probe
//
// Purpose:
//   All 8 slave base addresses in the DUT default to M_BASE_ADDR = 0.
//   When M_BASE_ADDR = 0 the core runs calcBaseAddrs() which auto-assigns:
//     M00: base = 0x00000000,  width = 24  (16 MB region)
//     M01: base = 0x01000000,  width = 24
//     ...
//     M07: base = 0x07000000,  width = 24
//   Address decode: loop i=0..7, last hit wins → with AWADDR = 0x00000000
//   only M00 matches (0x00000000 >> 24 == 0 == M00 base >> 24).
//
//   This testbench sends EXACTLY ONE write from Master 0 at the common
//   default base address (0x00000000) and monitors all 8 slave interfaces
//   to observe which slave actually receives the transaction.
// =============================================================================
`timescale 1ns / 1ps

module axi_interconnect_tb;

// ---------------------------------------------------------------------------
// Parameters – must match DUT defaults
// ---------------------------------------------------------------------------
parameter DATA_WIDTH   = 32;
parameter ADDR_WIDTH   = 32;
parameter STRB_WIDTH   = 4;
parameter ID_WIDTH     = 8;
parameter AWUSER_WIDTH = 1;
parameter WUSER_WIDTH  = 1;
parameter BUSER_WIDTH  = 1;
parameter ARUSER_WIDTH = 1;
parameter RUSER_WIDTH  = 1;

// Common base address used for all 8 slaves in the DUT (M_BASE_ADDR = 0
// for every slave → calcBaseAddrs() auto-computes starting from 0).
// We test with AWADDR = 0x00000000 which is M00's auto-computed base.
parameter [ADDR_WIDTH-1:0] COMMON_BASE_ADDR = 32'h0000_0000;

parameter CLK_PERIOD    = 10;   // ns
parameter TIMEOUT_CYCLES = 200;

// ---------------------------------------------------------------------------
// Clock and reset (active-high rst per DUT)
// ---------------------------------------------------------------------------
reg clk = 1'b0;
reg rst = 1'b1;

always #(CLK_PERIOD/2) clk = ~clk;

// ---------------------------------------------------------------------------
// Master 0 – s00_axi (driven by testbench)
// ---------------------------------------------------------------------------
reg  [ID_WIDTH-1:0]     s00_axi_awid    = 0;
reg  [ADDR_WIDTH-1:0]   s00_axi_awaddr  = 0;
reg  [7:0]              s00_axi_awlen   = 0;
reg  [2:0]              s00_axi_awsize  = 3'b010;
reg  [1:0]              s00_axi_awburst = 2'b01;
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

// AR/R channels – tied off (no reads in this test)
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
reg                     s00_axi_rready  = 0;

// ---------------------------------------------------------------------------
// Master 1 – s01_axi (tied off – unused in this test)
// ---------------------------------------------------------------------------
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
reg                     s01_axi_rready  = 0;

// ---------------------------------------------------------------------------
// Slave 0 (m00_axi) – DUT drives AW/W/AR, TB drives ready + B/R response
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m00_axi_rdata   = 0;
reg  [1:0]              m00_axi_rresp   = 0;
reg                     m00_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m00_axi_ruser   = 0;
reg                     m00_axi_rvalid  = 0;
wire                    m00_axi_rready;

// ---------------------------------------------------------------------------
// Slave 1 (m01_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m01_axi_rdata   = 0;
reg  [1:0]              m01_axi_rresp   = 0;
reg                     m01_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m01_axi_ruser   = 0;
reg                     m01_axi_rvalid  = 0;
wire                    m01_axi_rready;

// ---------------------------------------------------------------------------
// Slave 2 (m02_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m02_axi_rdata   = 0;
reg  [1:0]              m02_axi_rresp   = 0;
reg                     m02_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m02_axi_ruser   = 0;
reg                     m02_axi_rvalid  = 0;
wire                    m02_axi_rready;

// ---------------------------------------------------------------------------
// Slave 3 (m03_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m03_axi_rdata   = 0;
reg  [1:0]              m03_axi_rresp   = 0;
reg                     m03_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m03_axi_ruser   = 0;
reg                     m03_axi_rvalid  = 0;
wire                    m03_axi_rready;

// ---------------------------------------------------------------------------
// Slave 4 (m04_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m04_axi_rdata   = 0;
reg  [1:0]              m04_axi_rresp   = 0;
reg                     m04_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m04_axi_ruser   = 0;
reg                     m04_axi_rvalid  = 0;
wire                    m04_axi_rready;

// ---------------------------------------------------------------------------
// Slave 5 (m05_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m05_axi_rdata   = 0;
reg  [1:0]              m05_axi_rresp   = 0;
reg                     m05_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m05_axi_ruser   = 0;
reg                     m05_axi_rvalid  = 0;
wire                    m05_axi_rready;

// ---------------------------------------------------------------------------
// Slave 6 (m06_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m06_axi_rdata   = 0;
reg  [1:0]              m06_axi_rresp   = 0;
reg                     m06_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m06_axi_ruser   = 0;
reg                     m06_axi_rvalid  = 0;
wire                    m06_axi_rready;

// ---------------------------------------------------------------------------
// Slave 7 (m07_axi)
// ---------------------------------------------------------------------------
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
reg  [DATA_WIDTH-1:0]   m07_axi_rdata   = 0;
reg  [1:0]              m07_axi_rresp   = 0;
reg                     m07_axi_rlast   = 0;
reg  [RUSER_WIDTH-1:0]  m07_axi_ruser   = 0;
reg                     m07_axi_rvalid  = 0;
wire                    m07_axi_rready;

// ---------------------------------------------------------------------------
// DUT instantiation
// ---------------------------------------------------------------------------
axi_interconnect_wrap_2x8 #(
    .DATA_WIDTH    (DATA_WIDTH),
    .ADDR_WIDTH    (ADDR_WIDTH),
    .STRB_WIDTH    (STRB_WIDTH),
    .ID_WIDTH      (ID_WIDTH),
    .AWUSER_WIDTH  (AWUSER_WIDTH),
    .WUSER_WIDTH   (WUSER_WIDTH),
    .BUSER_WIDTH   (BUSER_WIDTH),
    .ARUSER_WIDTH  (ARUSER_WIDTH),
    .RUSER_WIDTH   (RUSER_WIDTH),
    // All base addresses = 0 → calcBaseAddrs() auto-assigns sequential regions
    .M00_BASE_ADDR (0), .M00_ADDR_WIDTH (24),
    .M01_BASE_ADDR (0), .M01_ADDR_WIDTH (24),
    .M02_BASE_ADDR (0), .M02_ADDR_WIDTH (24),
    .M03_BASE_ADDR (0), .M03_ADDR_WIDTH (24),
    .M04_BASE_ADDR (0), .M04_ADDR_WIDTH (24),
    .M05_BASE_ADDR (0), .M05_ADDR_WIDTH (24),
    .M06_BASE_ADDR (0), .M06_ADDR_WIDTH (24),
    .M07_BASE_ADDR (0), .M07_ADDR_WIDTH (24)
) DUT (
    .clk             (clk),
    .rst             (rst),
    // s00
    .s00_axi_awid    (s00_axi_awid),
    .s00_axi_awaddr  (s00_axi_awaddr),
    .s00_axi_awlen   (s00_axi_awlen),
    .s00_axi_awsize  (s00_axi_awsize),
    .s00_axi_awburst (s00_axi_awburst),
    .s00_axi_awlock  (s00_axi_awlock),
    .s00_axi_awcache (s00_axi_awcache),
    .s00_axi_awprot  (s00_axi_awprot),
    .s00_axi_awqos   (s00_axi_awqos),
    .s00_axi_awuser  (s00_axi_awuser),
    .s00_axi_awvalid (s00_axi_awvalid),
    .s00_axi_awready (s00_axi_awready),
    .s00_axi_wdata   (s00_axi_wdata),
    .s00_axi_wstrb   (s00_axi_wstrb),
    .s00_axi_wlast   (s00_axi_wlast),
    .s00_axi_wuser   (s00_axi_wuser),
    .s00_axi_wvalid  (s00_axi_wvalid),
    .s00_axi_wready  (s00_axi_wready),
    .s00_axi_bid     (s00_axi_bid),
    .s00_axi_bresp   (s00_axi_bresp),
    .s00_axi_buser   (s00_axi_buser),
    .s00_axi_bvalid  (s00_axi_bvalid),
    .s00_axi_bready  (s00_axi_bready),
    .s00_axi_arid    (s00_axi_arid),
    .s00_axi_araddr  (s00_axi_araddr),
    .s00_axi_arlen   (s00_axi_arlen),
    .s00_axi_arsize  (s00_axi_arsize),
    .s00_axi_arburst (s00_axi_arburst),
    .s00_axi_arlock  (s00_axi_arlock),
    .s00_axi_arcache (s00_axi_arcache),
    .s00_axi_arprot  (s00_axi_arprot),
    .s00_axi_arqos   (s00_axi_arqos),
    .s00_axi_aruser  (s00_axi_aruser),
    .s00_axi_arvalid (s00_axi_arvalid),
    .s00_axi_arready (s00_axi_arready),
    .s00_axi_rid     (s00_axi_rid),
    .s00_axi_rdata   (s00_axi_rdata),
    .s00_axi_rresp   (s00_axi_rresp),
    .s00_axi_rlast   (s00_axi_rlast),
    .s00_axi_ruser   (s00_axi_ruser),
    .s00_axi_rvalid  (s00_axi_rvalid),
    .s00_axi_rready  (s00_axi_rready),
    // s01
    .s01_axi_awid    (s01_axi_awid),
    .s01_axi_awaddr  (s01_axi_awaddr),
    .s01_axi_awlen   (s01_axi_awlen),
    .s01_axi_awsize  (s01_axi_awsize),
    .s01_axi_awburst (s01_axi_awburst),
    .s01_axi_awlock  (s01_axi_awlock),
    .s01_axi_awcache (s01_axi_awcache),
    .s01_axi_awprot  (s01_axi_awprot),
    .s01_axi_awqos   (s01_axi_awqos),
    .s01_axi_awuser  (s01_axi_awuser),
    .s01_axi_awvalid (s01_axi_awvalid),
    .s01_axi_awready (s01_axi_awready),
    .s01_axi_wdata   (s01_axi_wdata),
    .s01_axi_wstrb   (s01_axi_wstrb),
    .s01_axi_wlast   (s01_axi_wlast),
    .s01_axi_wuser   (s01_axi_wuser),
    .s01_axi_wvalid  (s01_axi_wvalid),
    .s01_axi_wready  (s01_axi_wready),
    .s01_axi_bid     (s01_axi_bid),
    .s01_axi_bresp   (s01_axi_bresp),
    .s01_axi_buser   (s01_axi_buser),
    .s01_axi_bvalid  (s01_axi_bvalid),
    .s01_axi_bready  (s01_axi_bready),
    .s01_axi_arid    (s01_axi_arid),
    .s01_axi_araddr  (s01_axi_araddr),
    .s01_axi_arlen   (s01_axi_arlen),
    .s01_axi_arsize  (s01_axi_arsize),
    .s01_axi_arburst (s01_axi_arburst),
    .s01_axi_arlock  (s01_axi_arlock),
    .s01_axi_arcache (s01_axi_arcache),
    .s01_axi_arprot  (s01_axi_arprot),
    .s01_axi_arqos   (s01_axi_arqos),
    .s01_axi_aruser  (s01_axi_aruser),
    .s01_axi_arvalid (s01_axi_arvalid),
    .s01_axi_arready (s01_axi_arready),
    .s01_axi_rid     (s01_axi_rid),
    .s01_axi_rdata   (s01_axi_rdata),
    .s01_axi_rresp   (s01_axi_rresp),
    .s01_axi_rlast   (s01_axi_rlast),
    .s01_axi_ruser   (s01_axi_ruser),
    .s01_axi_rvalid  (s01_axi_rvalid),
    .s01_axi_rready  (s01_axi_rready),
    // m00
    .m00_axi_awid    (m00_axi_awid),   .m00_axi_awaddr  (m00_axi_awaddr),
    .m00_axi_awlen   (m00_axi_awlen),  .m00_axi_awsize  (m00_axi_awsize),
    .m00_axi_awburst (m00_axi_awburst),.m00_axi_awlock  (m00_axi_awlock),
    .m00_axi_awcache (m00_axi_awcache),.m00_axi_awprot  (m00_axi_awprot),
    .m00_axi_awqos   (m00_axi_awqos),  .m00_axi_awregion(m00_axi_awregion),
    .m00_axi_awuser  (m00_axi_awuser), .m00_axi_awvalid (m00_axi_awvalid),
    .m00_axi_awready (m00_axi_awready),
    .m00_axi_wdata   (m00_axi_wdata),  .m00_axi_wstrb   (m00_axi_wstrb),
    .m00_axi_wlast   (m00_axi_wlast),  .m00_axi_wuser   (m00_axi_wuser),
    .m00_axi_wvalid  (m00_axi_wvalid), .m00_axi_wready  (m00_axi_wready),
    .m00_axi_bid     (m00_axi_bid),    .m00_axi_bresp   (m00_axi_bresp),
    .m00_axi_buser   (m00_axi_buser),  .m00_axi_bvalid  (m00_axi_bvalid),
    .m00_axi_bready  (m00_axi_bready),
    .m00_axi_arid    (m00_axi_arid),   .m00_axi_araddr  (m00_axi_araddr),
    .m00_axi_arlen   (m00_axi_arlen),  .m00_axi_arsize  (m00_axi_arsize),
    .m00_axi_arburst (m00_axi_arburst),.m00_axi_arlock  (m00_axi_arlock),
    .m00_axi_arcache (m00_axi_arcache),.m00_axi_arprot  (m00_axi_arprot),
    .m00_axi_arqos   (m00_axi_arqos),  .m00_axi_arregion(m00_axi_arregion),
    .m00_axi_aruser  (m00_axi_aruser), .m00_axi_arvalid (m00_axi_arvalid),
    .m00_axi_arready (m00_axi_arready),
    .m00_axi_rid     (m00_axi_rid),    .m00_axi_rdata   (m00_axi_rdata),
    .m00_axi_rresp   (m00_axi_rresp),  .m00_axi_rlast   (m00_axi_rlast),
    .m00_axi_ruser   (m00_axi_ruser),  .m00_axi_rvalid  (m00_axi_rvalid),
    .m00_axi_rready  (m00_axi_rready),
    // m01
    .m01_axi_awid    (m01_axi_awid),   .m01_axi_awaddr  (m01_axi_awaddr),
    .m01_axi_awlen   (m01_axi_awlen),  .m01_axi_awsize  (m01_axi_awsize),
    .m01_axi_awburst (m01_axi_awburst),.m01_axi_awlock  (m01_axi_awlock),
    .m01_axi_awcache (m01_axi_awcache),.m01_axi_awprot  (m01_axi_awprot),
    .m01_axi_awqos   (m01_axi_awqos),  .m01_axi_awregion(m01_axi_awregion),
    .m01_axi_awuser  (m01_axi_awuser), .m01_axi_awvalid (m01_axi_awvalid),
    .m01_axi_awready (m01_axi_awready),
    .m01_axi_wdata   (m01_axi_wdata),  .m01_axi_wstrb   (m01_axi_wstrb),
    .m01_axi_wlast   (m01_axi_wlast),  .m01_axi_wuser   (m01_axi_wuser),
    .m01_axi_wvalid  (m01_axi_wvalid), .m01_axi_wready  (m01_axi_wready),
    .m01_axi_bid     (m01_axi_bid),    .m01_axi_bresp   (m01_axi_bresp),
    .m01_axi_buser   (m01_axi_buser),  .m01_axi_bvalid  (m01_axi_bvalid),
    .m01_axi_bready  (m01_axi_bready),
    .m01_axi_arid    (m01_axi_arid),   .m01_axi_araddr  (m01_axi_araddr),
    .m01_axi_arlen   (m01_axi_arlen),  .m01_axi_arsize  (m01_axi_arsize),
    .m01_axi_arburst (m01_axi_arburst),.m01_axi_arlock  (m01_axi_arlock),
    .m01_axi_arcache (m01_axi_arcache),.m01_axi_arprot  (m01_axi_arprot),
    .m01_axi_arqos   (m01_axi_arqos),  .m01_axi_arregion(m01_axi_arregion),
    .m01_axi_aruser  (m01_axi_aruser), .m01_axi_arvalid (m01_axi_arvalid),
    .m01_axi_arready (m01_axi_arready),
    .m01_axi_rid     (m01_axi_rid),    .m01_axi_rdata   (m01_axi_rdata),
    .m01_axi_rresp   (m01_axi_rresp),  .m01_axi_rlast   (m01_axi_rlast),
    .m01_axi_ruser   (m01_axi_ruser),  .m01_axi_rvalid  (m01_axi_rvalid),
    .m01_axi_rready  (m01_axi_rready),
    // m02
    .m02_axi_awid    (m02_axi_awid),   .m02_axi_awaddr  (m02_axi_awaddr),
    .m02_axi_awlen   (m02_axi_awlen),  .m02_axi_awsize  (m02_axi_awsize),
    .m02_axi_awburst (m02_axi_awburst),.m02_axi_awlock  (m02_axi_awlock),
    .m02_axi_awcache (m02_axi_awcache),.m02_axi_awprot  (m02_axi_awprot),
    .m02_axi_awqos   (m02_axi_awqos),  .m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser  (m02_axi_awuser), .m02_axi_awvalid (m02_axi_awvalid),
    .m02_axi_awready (m02_axi_awready),
    .m02_axi_wdata   (m02_axi_wdata),  .m02_axi_wstrb   (m02_axi_wstrb),
    .m02_axi_wlast   (m02_axi_wlast),  .m02_axi_wuser   (m02_axi_wuser),
    .m02_axi_wvalid  (m02_axi_wvalid), .m02_axi_wready  (m02_axi_wready),
    .m02_axi_bid     (m02_axi_bid),    .m02_axi_bresp   (m02_axi_bresp),
    .m02_axi_buser   (m02_axi_buser),  .m02_axi_bvalid  (m02_axi_bvalid),
    .m02_axi_bready  (m02_axi_bready),
    .m02_axi_arid    (m02_axi_arid),   .m02_axi_araddr  (m02_axi_araddr),
    .m02_axi_arlen   (m02_axi_arlen),  .m02_axi_arsize  (m02_axi_arsize),
    .m02_axi_arburst (m02_axi_arburst),.m02_axi_arlock  (m02_axi_arlock),
    .m02_axi_arcache (m02_axi_arcache),.m02_axi_arprot  (m02_axi_arprot),
    .m02_axi_arqos   (m02_axi_arqos),  .m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser  (m02_axi_aruser), .m02_axi_arvalid (m02_axi_arvalid),
    .m02_axi_arready (m02_axi_arready),
    .m02_axi_rid     (m02_axi_rid),    .m02_axi_rdata   (m02_axi_rdata),
    .m02_axi_rresp   (m02_axi_rresp),  .m02_axi_rlast   (m02_axi_rlast),
    .m02_axi_ruser   (m02_axi_ruser),  .m02_axi_rvalid  (m02_axi_rvalid),
    .m02_axi_rready  (m02_axi_rready),
    // m03
    .m03_axi_awid    (m03_axi_awid),   .m03_axi_awaddr  (m03_axi_awaddr),
    .m03_axi_awlen   (m03_axi_awlen),  .m03_axi_awsize  (m03_axi_awsize),
    .m03_axi_awburst (m03_axi_awburst),.m03_axi_awlock  (m03_axi_awlock),
    .m03_axi_awcache (m03_axi_awcache),.m03_axi_awprot  (m03_axi_awprot),
    .m03_axi_awqos   (m03_axi_awqos),  .m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser  (m03_axi_awuser), .m03_axi_awvalid (m03_axi_awvalid),
    .m03_axi_awready (m03_axi_awready),
    .m03_axi_wdata   (m03_axi_wdata),  .m03_axi_wstrb   (m03_axi_wstrb),
    .m03_axi_wlast   (m03_axi_wlast),  .m03_axi_wuser   (m03_axi_wuser),
    .m03_axi_wvalid  (m03_axi_wvalid), .m03_axi_wready  (m03_axi_wready),
    .m03_axi_bid     (m03_axi_bid),    .m03_axi_bresp   (m03_axi_bresp),
    .m03_axi_buser   (m03_axi_buser),  .m03_axi_bvalid  (m03_axi_bvalid),
    .m03_axi_bready  (m03_axi_bready),
    .m03_axi_arid    (m03_axi_arid),   .m03_axi_araddr  (m03_axi_araddr),
    .m03_axi_arlen   (m03_axi_arlen),  .m03_axi_arsize  (m03_axi_arsize),
    .m03_axi_arburst (m03_axi_arburst),.m03_axi_arlock  (m03_axi_arlock),
    .m03_axi_arcache (m03_axi_arcache),.m03_axi_arprot  (m03_axi_arprot),
    .m03_axi_arqos   (m03_axi_arqos),  .m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser  (m03_axi_aruser), .m03_axi_arvalid (m03_axi_arvalid),
    .m03_axi_arready (m03_axi_arready),
    .m03_axi_rid     (m03_axi_rid),    .m03_axi_rdata   (m03_axi_rdata),
    .m03_axi_rresp   (m03_axi_rresp),  .m03_axi_rlast   (m03_axi_rlast),
    .m03_axi_ruser   (m03_axi_ruser),  .m03_axi_rvalid  (m03_axi_rvalid),
    .m03_axi_rready  (m03_axi_rready),
    // m04
    .m04_axi_awid    (m04_axi_awid),   .m04_axi_awaddr  (m04_axi_awaddr),
    .m04_axi_awlen   (m04_axi_awlen),  .m04_axi_awsize  (m04_axi_awsize),
    .m04_axi_awburst (m04_axi_awburst),.m04_axi_awlock  (m04_axi_awlock),
    .m04_axi_awcache (m04_axi_awcache),.m04_axi_awprot  (m04_axi_awprot),
    .m04_axi_awqos   (m04_axi_awqos),  .m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser  (m04_axi_awuser), .m04_axi_awvalid (m04_axi_awvalid),
    .m04_axi_awready (m04_axi_awready),
    .m04_axi_wdata   (m04_axi_wdata),  .m04_axi_wstrb   (m04_axi_wstrb),
    .m04_axi_wlast   (m04_axi_wlast),  .m04_axi_wuser   (m04_axi_wuser),
    .m04_axi_wvalid  (m04_axi_wvalid), .m04_axi_wready  (m04_axi_wready),
    .m04_axi_bid     (m04_axi_bid),    .m04_axi_bresp   (m04_axi_bresp),
    .m04_axi_buser   (m04_axi_buser),  .m04_axi_bvalid  (m04_axi_bvalid),
    .m04_axi_bready  (m04_axi_bready),
    .m04_axi_arid    (m04_axi_arid),   .m04_axi_araddr  (m04_axi_araddr),
    .m04_axi_arlen   (m04_axi_arlen),  .m04_axi_arsize  (m04_axi_arsize),
    .m04_axi_arburst (m04_axi_arburst),.m04_axi_arlock  (m04_axi_arlock),
    .m04_axi_arcache (m04_axi_arcache),.m04_axi_arprot  (m04_axi_arprot),
    .m04_axi_arqos   (m04_axi_arqos),  .m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser  (m04_axi_aruser), .m04_axi_arvalid (m04_axi_arvalid),
    .m04_axi_arready (m04_axi_arready),
    .m04_axi_rid     (m04_axi_rid),    .m04_axi_rdata   (m04_axi_rdata),
    .m04_axi_rresp   (m04_axi_rresp),  .m04_axi_rlast   (m04_axi_rlast),
    .m04_axi_ruser   (m04_axi_ruser),  .m04_axi_rvalid  (m04_axi_rvalid),
    .m04_axi_rready  (m04_axi_rready),
    // m05
    .m05_axi_awid    (m05_axi_awid),   .m05_axi_awaddr  (m05_axi_awaddr),
    .m05_axi_awlen   (m05_axi_awlen),  .m05_axi_awsize  (m05_axi_awsize),
    .m05_axi_awburst (m05_axi_awburst),.m05_axi_awlock  (m05_axi_awlock),
    .m05_axi_awcache (m05_axi_awcache),.m05_axi_awprot  (m05_axi_awprot),
    .m05_axi_awqos   (m05_axi_awqos),  .m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser  (m05_axi_awuser), .m05_axi_awvalid (m05_axi_awvalid),
    .m05_axi_awready (m05_axi_awready),
    .m05_axi_wdata   (m05_axi_wdata),  .m05_axi_wstrb   (m05_axi_wstrb),
    .m05_axi_wlast   (m05_axi_wlast),  .m05_axi_wuser   (m05_axi_wuser),
    .m05_axi_wvalid  (m05_axi_wvalid), .m05_axi_wready  (m05_axi_wready),
    .m05_axi_bid     (m05_axi_bid),    .m05_axi_bresp   (m05_axi_bresp),
    .m05_axi_buser   (m05_axi_buser),  .m05_axi_bvalid  (m05_axi_bvalid),
    .m05_axi_bready  (m05_axi_bready),
    .m05_axi_arid    (m05_axi_arid),   .m05_axi_araddr  (m05_axi_araddr),
    .m05_axi_arlen   (m05_axi_arlen),  .m05_axi_arsize  (m05_axi_arsize),
    .m05_axi_arburst (m05_axi_arburst),.m05_axi_arlock  (m05_axi_arlock),
    .m05_axi_arcache (m05_axi_arcache),.m05_axi_arprot  (m05_axi_arprot),
    .m05_axi_arqos   (m05_axi_arqos),  .m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser  (m05_axi_aruser), .m05_axi_arvalid (m05_axi_arvalid),
    .m05_axi_arready (m05_axi_arready),
    .m05_axi_rid     (m05_axi_rid),    .m05_axi_rdata   (m05_axi_rdata),
    .m05_axi_rresp   (m05_axi_rresp),  .m05_axi_rlast   (m05_axi_rlast),
    .m05_axi_ruser   (m05_axi_ruser),  .m05_axi_rvalid  (m05_axi_rvalid),
    .m05_axi_rready  (m05_axi_rready),
    // m06
    .m06_axi_awid    (m06_axi_awid),   .m06_axi_awaddr  (m06_axi_awaddr),
    .m06_axi_awlen   (m06_axi_awlen),  .m06_axi_awsize  (m06_axi_awsize),
    .m06_axi_awburst (m06_axi_awburst),.m06_axi_awlock  (m06_axi_awlock),
    .m06_axi_awcache (m06_axi_awcache),.m06_axi_awprot  (m06_axi_awprot),
    .m06_axi_awqos   (m06_axi_awqos),  .m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser  (m06_axi_awuser), .m06_axi_awvalid (m06_axi_awvalid),
    .m06_axi_awready (m06_axi_awready),
    .m06_axi_wdata   (m06_axi_wdata),  .m06_axi_wstrb   (m06_axi_wstrb),
    .m06_axi_wlast   (m06_axi_wlast),  .m06_axi_wuser   (m06_axi_wuser),
    .m06_axi_wvalid  (m06_axi_wvalid), .m06_axi_wready  (m06_axi_wready),
    .m06_axi_bid     (m06_axi_bid),    .m06_axi_bresp   (m06_axi_bresp),
    .m06_axi_buser   (m06_axi_buser),  .m06_axi_bvalid  (m06_axi_bvalid),
    .m06_axi_bready  (m06_axi_bready),
    .m06_axi_arid    (m06_axi_arid),   .m06_axi_araddr  (m06_axi_araddr),
    .m06_axi_arlen   (m06_axi_arlen),  .m06_axi_arsize  (m06_axi_arsize),
    .m06_axi_arburst (m06_axi_arburst),.m06_axi_arlock  (m06_axi_arlock),
    .m06_axi_arcache (m06_axi_arcache),.m06_axi_arprot  (m06_axi_arprot),
    .m06_axi_arqos   (m06_axi_arqos),  .m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser  (m06_axi_aruser), .m06_axi_arvalid (m06_axi_arvalid),
    .m06_axi_arready (m06_axi_arready),
    .m06_axi_rid     (m06_axi_rid),    .m06_axi_rdata   (m06_axi_rdata),
    .m06_axi_rresp   (m06_axi_rresp),  .m06_axi_rlast   (m06_axi_rlast),
    .m06_axi_ruser   (m06_axi_ruser),  .m06_axi_rvalid  (m06_axi_rvalid),
    .m06_axi_rready  (m06_axi_rready),
    // m07
    .m07_axi_awid    (m07_axi_awid),   .m07_axi_awaddr  (m07_axi_awaddr),
    .m07_axi_awlen   (m07_axi_awlen),  .m07_axi_awsize  (m07_axi_awsize),
    .m07_axi_awburst (m07_axi_awburst),.m07_axi_awlock  (m07_axi_awlock),
    .m07_axi_awcache (m07_axi_awcache),.m07_axi_awprot  (m07_axi_awprot),
    .m07_axi_awqos   (m07_axi_awqos),  .m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser  (m07_axi_awuser), .m07_axi_awvalid (m07_axi_awvalid),
    .m07_axi_awready (m07_axi_awready),
    .m07_axi_wdata   (m07_axi_wdata),  .m07_axi_wstrb   (m07_axi_wstrb),
    .m07_axi_wlast   (m07_axi_wlast),  .m07_axi_wuser   (m07_axi_wuser),
    .m07_axi_wvalid  (m07_axi_wvalid), .m07_axi_wready  (m07_axi_wready),
    .m07_axi_bid     (m07_axi_bid),    .m07_axi_bresp   (m07_axi_bresp),
    .m07_axi_buser   (m07_axi_buser),  .m07_axi_bvalid  (m07_axi_bvalid),
    .m07_axi_bready  (m07_axi_bready),
    .m07_axi_arid    (m07_axi_arid),   .m07_axi_araddr  (m07_axi_araddr),
    .m07_axi_arlen   (m07_axi_arlen),  .m07_axi_arsize  (m07_axi_arsize),
    .m07_axi_arburst (m07_axi_arburst),.m07_axi_arlock  (m07_axi_arlock),
    .m07_axi_arcache (m07_axi_arcache),.m07_axi_arprot  (m07_axi_arprot),
    .m07_axi_arqos   (m07_axi_arqos),  .m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser  (m07_axi_aruser), .m07_axi_arvalid (m07_axi_arvalid),
    .m07_axi_arready (m07_axi_arready),
    .m07_axi_rid     (m07_axi_rid),    .m07_axi_rdata   (m07_axi_rdata),
    .m07_axi_rresp   (m07_axi_rresp),  .m07_axi_rlast   (m07_axi_rlast),
    .m07_axi_ruser   (m07_axi_ruser),  .m07_axi_rvalid  (m07_axi_rvalid),
    .m07_axi_rready  (m07_axi_rready)
);

// ---------------------------------------------------------------------------
// Slave responder models – respond only to what the DUT actually presents.
// All 8 slaves use the same pattern: when they see awvalid+awready and
// wvalid+wready+wlast they fire bvalid=1 with bresp=OKAY.
// ---------------------------------------------------------------------------

// Slave 0
always @(posedge clk) begin
    if (rst) begin
        m00_axi_bvalid <= 0;
    end else begin
        if (m00_axi_wvalid && m00_axi_wready && m00_axi_wlast) begin
            m00_axi_bid    <= m00_axi_awid;
            m00_axi_bresp  <= 2'b00;
            m00_axi_bvalid <= 1'b1;
        end
        if (m00_axi_bvalid && m00_axi_bready)
            m00_axi_bvalid <= 1'b0;
    end
end

// Slave 1
always @(posedge clk) begin
    if (rst) begin
        m01_axi_bvalid <= 0;
    end else begin
        if (m01_axi_wvalid && m01_axi_wready && m01_axi_wlast) begin
            m01_axi_bid    <= m01_axi_awid;
            m01_axi_bresp  <= 2'b00;
            m01_axi_bvalid <= 1'b1;
        end
        if (m01_axi_bvalid && m01_axi_bready)
            m01_axi_bvalid <= 1'b0;
    end
end

// Slave 2
always @(posedge clk) begin
    if (rst) begin
        m02_axi_bvalid <= 0;
    end else begin
        if (m02_axi_wvalid && m02_axi_wready && m02_axi_wlast) begin
            m02_axi_bid    <= m02_axi_awid;
            m02_axi_bresp  <= 2'b00;
            m02_axi_bvalid <= 1'b1;
        end
        if (m02_axi_bvalid && m02_axi_bready)
            m02_axi_bvalid <= 1'b0;
    end
end

// Slave 3
always @(posedge clk) begin
    if (rst) begin
        m03_axi_bvalid <= 0;
    end else begin
        if (m03_axi_wvalid && m03_axi_wready && m03_axi_wlast) begin
            m03_axi_bid    <= m03_axi_awid;
            m03_axi_bresp  <= 2'b00;
            m03_axi_bvalid <= 1'b1;
        end
        if (m03_axi_bvalid && m03_axi_bready)
            m03_axi_bvalid <= 1'b0;
    end
end

// Slave 4
always @(posedge clk) begin
    if (rst) begin
        m04_axi_bvalid <= 0;
    end else begin
        if (m04_axi_wvalid && m04_axi_wready && m04_axi_wlast) begin
            m04_axi_bid    <= m04_axi_awid;
            m04_axi_bresp  <= 2'b00;
            m04_axi_bvalid <= 1'b1;
        end
        if (m04_axi_bvalid && m04_axi_bready)
            m04_axi_bvalid <= 1'b0;
    end
end

// Slave 5
always @(posedge clk) begin
    if (rst) begin
        m05_axi_bvalid <= 0;
    end else begin
        if (m05_axi_wvalid && m05_axi_wready && m05_axi_wlast) begin
            m05_axi_bid    <= m05_axi_awid;
            m05_axi_bresp  <= 2'b00;
            m05_axi_bvalid <= 1'b1;
        end
        if (m05_axi_bvalid && m05_axi_bready)
            m05_axi_bvalid <= 1'b0;
    end
end

// Slave 6
always @(posedge clk) begin
    if (rst) begin
        m06_axi_bvalid <= 0;
    end else begin
        if (m06_axi_wvalid && m06_axi_wready && m06_axi_wlast) begin
            m06_axi_bid    <= m06_axi_awid;
            m06_axi_bresp  <= 2'b00;
            m06_axi_bvalid <= 1'b1;
        end
        if (m06_axi_bvalid && m06_axi_bready)
            m06_axi_bvalid <= 1'b0;
    end
end

// Slave 7
always @(posedge clk) begin
    if (rst) begin
        m07_axi_bvalid <= 0;
    end else begin
        if (m07_axi_wvalid && m07_axi_wready && m07_axi_wlast) begin
            m07_axi_bid    <= m07_axi_awid;
            m07_axi_bresp  <= 2'b00;
            m07_axi_bvalid <= 1'b1;
        end
        if (m07_axi_bvalid && m07_axi_bready)
            m07_axi_bvalid <= 1'b0;
    end
end

// ---------------------------------------------------------------------------
// Observation registers – latch the peak AWVALID/WVALID seen on each slave
// so we can report it in the final summary even if the pulse is short.
// ---------------------------------------------------------------------------
reg obs_m00_awvalid = 0, obs_m00_wvalid = 0;
reg obs_m01_awvalid = 0, obs_m01_wvalid = 0;
reg obs_m02_awvalid = 0, obs_m02_wvalid = 0;
reg obs_m03_awvalid = 0, obs_m03_wvalid = 0;
reg obs_m04_awvalid = 0, obs_m04_wvalid = 0;
reg obs_m05_awvalid = 0, obs_m05_wvalid = 0;
reg obs_m06_awvalid = 0, obs_m06_wvalid = 0;
reg obs_m07_awvalid = 0, obs_m07_wvalid = 0;

reg [ADDR_WIDTH-1:0] obs_m00_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m01_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m02_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m03_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m04_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m05_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m06_awaddr = 0;
reg [ADDR_WIDTH-1:0] obs_m07_awaddr = 0;

reg [DATA_WIDTH-1:0] obs_m00_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m01_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m02_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m03_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m04_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m05_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m06_wdata = 0;
reg [DATA_WIDTH-1:0] obs_m07_wdata = 0;

always @(posedge clk) begin
    if (m00_axi_awvalid) begin obs_m00_awvalid <= 1; obs_m00_awaddr <= m00_axi_awaddr; end
    if (m01_axi_awvalid) begin obs_m01_awvalid <= 1; obs_m01_awaddr <= m01_axi_awaddr; end
    if (m02_axi_awvalid) begin obs_m02_awvalid <= 1; obs_m02_awaddr <= m02_axi_awaddr; end
    if (m03_axi_awvalid) begin obs_m03_awvalid <= 1; obs_m03_awaddr <= m03_axi_awaddr; end
    if (m04_axi_awvalid) begin obs_m04_awvalid <= 1; obs_m04_awaddr <= m04_axi_awaddr; end
    if (m05_axi_awvalid) begin obs_m05_awvalid <= 1; obs_m05_awaddr <= m05_axi_awaddr; end
    if (m06_axi_awvalid) begin obs_m06_awvalid <= 1; obs_m06_awaddr <= m06_axi_awaddr; end
    if (m07_axi_awvalid) begin obs_m07_awvalid <= 1; obs_m07_awaddr <= m07_axi_awaddr; end

    if (m00_axi_wvalid) begin obs_m00_wvalid <= 1; obs_m00_wdata <= m00_axi_wdata; end
    if (m01_axi_wvalid) begin obs_m01_wvalid <= 1; obs_m01_wdata <= m01_axi_wdata; end
    if (m02_axi_wvalid) begin obs_m02_wvalid <= 1; obs_m02_wdata <= m02_axi_wdata; end
    if (m03_axi_wvalid) begin obs_m03_wvalid <= 1; obs_m03_wdata <= m03_axi_wdata; end
    if (m04_axi_wvalid) begin obs_m04_wvalid <= 1; obs_m04_wdata <= m04_axi_wdata; end
    if (m05_axi_wvalid) begin obs_m05_wvalid <= 1; obs_m05_wdata <= m05_axi_wdata; end
    if (m06_axi_wvalid) begin obs_m06_wvalid <= 1; obs_m06_wdata <= m06_axi_wdata; end
    if (m07_axi_wvalid) begin obs_m07_wvalid <= 1; obs_m07_wdata <= m07_axi_wdata; end
end

// ---------------------------------------------------------------------------
// Write-transaction counter (to verify BVALID back to master)
// ---------------------------------------------------------------------------
reg  bresp_received = 0;
reg  [1:0] final_bresp = 2'b11;

// ---------------------------------------------------------------------------
// Utility task
// ---------------------------------------------------------------------------
task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            @(posedge clk);
    end
endtask

// ---------------------------------------------------------------------------
// Main stimulus
// ---------------------------------------------------------------------------
integer timeout;

initial begin
    // ------------------------------------------------------------------
    // Waveform dump – all master-0 write signals + all slave write ports
    // ------------------------------------------------------------------
    $dumpfile("single_write_test.vcd");
    $dumpvars(0, axi_interconnect_tb);

    $display("=================================================");
    $display(" AXI 2x8 Interconnect – Single Write Probe");
    $display(" RTL default: ALL M_BASE_ADDR = 0");
    $display(" calcBaseAddrs() auto-assigns sequential regions:");
    $display("   M00: 0x00000000 / 24-bit (0x00000000-0x00FFFFFF)");
    $display("   M01: 0x01000000 / 24-bit (0x01000000-0x01FFFFFF)");
    $display("   M02: 0x02000000 / 24-bit (0x02000000-0x02FFFFFF)");
    $display("   M03: 0x03000000 / 24-bit (0x03000000-0x03FFFFFF)");
    $display("   M04: 0x04000000 / 24-bit (0x04000000-0x04FFFFFF)");
    $display("   M05: 0x05000000 / 24-bit (0x05000000-0x05FFFFFF)");
    $display("   M06: 0x06000000 / 24-bit (0x06000000-0x06FFFFFF)");
    $display("   M07: 0x07000000 / 24-bit (0x07000000-0x07FFFFFF)");
    $display("=================================================");

    // ------------------------------------------------------------------
    // Reset (active-high, 10 cycles)
    // ------------------------------------------------------------------
    rst             = 1'b1;
    s00_axi_awvalid = 1'b0;
    s00_axi_wvalid  = 1'b0;
    s00_axi_bready  = 1'b1;
    s00_axi_arvalid = 1'b0;
    s00_axi_rready  = 1'b0;
    wait_cycles(10);
    @(negedge clk);
    rst = 1'b0;
    wait_cycles(5);
    $display("[RESET] De-asserted at time %0t ns", $time);

    // ------------------------------------------------------------------
    // Drive ONE write transaction from Master 0
    //   AWADDR  = 0x00000000  (COMMON_BASE_ADDR from RTL)
    //   WDATA   = 0xA5A51234
    //   AWID    = 8'h10
    //   AWLEN   = 8'h00  (1 beat)
    //   AWSIZE  = 3'b010 (4 bytes)
    //   AWBURST = 2'b01  (INCR)
    //   WLAST   = 1
    // ------------------------------------------------------------------
    $display("\n===== SINGLE WRITE TEST =====");
    $display("Master 0:");
    $display("  AWADDR  = %08h", COMMON_BASE_ADDR);
    $display("  WDATA   = A5A51234");
    $display("  AWID    = 10");
    $display("  AWLEN   = 00  (1 beat)");
    $display("  AWSIZE  = 010 (4 bytes)");
    $display("  AWBURST = 01  (INCR)");
    $display("  WLAST   = 1");

    // Present AW and W simultaneously (valid after negedge to avoid race)
    @(negedge clk);
    s00_axi_awid    = 8'h10;
    s00_axi_awaddr  = COMMON_BASE_ADDR;  // 32'h00000000
    s00_axi_awlen   = 8'h00;
    s00_axi_awsize  = 3'b010;
    s00_axi_awburst = 2'b01;
    s00_axi_awvalid = 1'b1;

    s00_axi_wdata   = 32'hA5A5_1234;
    s00_axi_wstrb   = 4'hF;
    s00_axi_wlast   = 1'b1;
    s00_axi_wvalid  = 1'b1;

    // ---- Wait for AW handshake ----
    timeout = TIMEOUT_CYCLES;
    @(posedge clk);
    while (!s00_axi_awready && timeout > 0) begin
        timeout = timeout - 1;
        @(posedge clk);
    end
    if (timeout == 0) begin
        $display("[ERROR] TIMEOUT waiting for s00_axi_awready");
        $finish;
    end
    // Deassert AWVALID one negedge after handshake
    @(negedge clk);
    s00_axi_awvalid = 1'b0;
    $display("[INFO]  AW handshake at time %0t ns  (awready=1)", $time);

    // ---- Wait for W handshake ----
    timeout = TIMEOUT_CYCLES;
    @(posedge clk);
    while (!s00_axi_wready && timeout > 0) begin
        timeout = timeout - 1;
        @(posedge clk);
    end
    if (timeout == 0) begin
        $display("[ERROR] TIMEOUT waiting for s00_axi_wready");
        $finish;
    end
    @(negedge clk);
    s00_axi_wvalid = 1'b0;
    s00_axi_wlast  = 1'b0;
    $display("[INFO]  W  handshake at time %0t ns  (wready=1)", $time);

    // ---- Wait for B response ----
    s00_axi_bready = 1'b1;
    timeout = TIMEOUT_CYCLES;
    @(posedge clk);
    while (!s00_axi_bvalid && timeout > 0) begin
        timeout = timeout - 1;
        @(posedge clk);
    end
    if (timeout == 0) begin
        $display("[ERROR] TIMEOUT waiting for s00_axi_bvalid");
        $finish;
    end
    bresp_received = 1'b1;
    final_bresp    = s00_axi_bresp;
    @(negedge clk);
    s00_axi_bready = 1'b0;
    $display("[INFO]  B  response  at time %0t ns  (bvalid=1, bresp=%02b)",
             $time, final_bresp);

    // Let observation latches settle
    wait_cycles(5);

    // ------------------------------------------------------------------
    // Per-slave status display
    // ------------------------------------------------------------------
    $display("\n===== SLAVE INTERFACE STATUS AFTER TRANSACTION =====");

    $display("\nSlave 0 (m00_axi):");
    $display("  AWVALID seen : %0b", obs_m00_awvalid);
    $display("  AWADDR       : %08h", obs_m00_awaddr);
    $display("  WVALID  seen : %0b", obs_m00_wvalid);
    $display("  WDATA        : %08h", obs_m00_wdata);

    $display("\nSlave 1 (m01_axi):");
    $display("  AWVALID seen : %0b", obs_m01_awvalid);
    $display("  AWADDR       : %08h", obs_m01_awaddr);
    $display("  WVALID  seen : %0b", obs_m01_wvalid);
    $display("  WDATA        : %08h", obs_m01_wdata);

    $display("\nSlave 2 (m02_axi):");
    $display("  AWVALID seen : %0b", obs_m02_awvalid);
    $display("  AWADDR       : %08h", obs_m02_awaddr);
    $display("  WVALID  seen : %0b", obs_m02_wvalid);
    $display("  WDATA        : %08h", obs_m02_wdata);

    $display("\nSlave 3 (m03_axi):");
    $display("  AWVALID seen : %0b", obs_m03_awvalid);
    $display("  AWADDR       : %08h", obs_m03_awaddr);
    $display("  WVALID  seen : %0b", obs_m03_wvalid);
    $display("  WDATA        : %08h", obs_m03_wdata);

    $display("\nSlave 4 (m04_axi):");
    $display("  AWVALID seen : %0b", obs_m04_awvalid);
    $display("  AWADDR       : %08h", obs_m04_awaddr);
    $display("  WVALID  seen : %0b", obs_m04_wvalid);
    $display("  WDATA        : %08h", obs_m04_wdata);

    $display("\nSlave 5 (m05_axi):");
    $display("  AWVALID seen : %0b", obs_m05_awvalid);
    $display("  AWADDR       : %08h", obs_m05_awaddr);
    $display("  WVALID  seen : %0b", obs_m05_wvalid);
    $display("  WDATA        : %08h", obs_m05_wdata);

    $display("\nSlave 6 (m06_axi):");
    $display("  AWVALID seen : %0b", obs_m06_awvalid);
    $display("  AWADDR       : %08h", obs_m06_awaddr);
    $display("  WVALID  seen : %0b", obs_m06_wvalid);
    $display("  WDATA        : %08h", obs_m06_wdata);

    $display("\nSlave 7 (m07_axi):");
    $display("  AWVALID seen : %0b", obs_m07_awvalid);
    $display("  AWADDR       : %08h", obs_m07_awaddr);
    $display("  WVALID  seen : %0b", obs_m07_wvalid);
    $display("  WDATA        : %08h", obs_m07_wdata);

    // ------------------------------------------------------------------
    // Count which slaves actually received the transaction
    // ------------------------------------------------------------------
    begin : count_block
        integer count;
        integer winner;
        count  = 0;
        winner = -1;
        if (obs_m00_awvalid && obs_m00_wvalid) begin count = count+1; winner = 0; end
        if (obs_m01_awvalid && obs_m01_wvalid) begin count = count+1; winner = 1; end
        if (obs_m02_awvalid && obs_m02_wvalid) begin count = count+1; winner = 2; end
        if (obs_m03_awvalid && obs_m03_wvalid) begin count = count+1; winner = 3; end
        if (obs_m04_awvalid && obs_m04_wvalid) begin count = count+1; winner = 4; end
        if (obs_m05_awvalid && obs_m05_wvalid) begin count = count+1; winner = 5; end
        if (obs_m06_awvalid && obs_m06_wvalid) begin count = count+1; winner = 6; end
        if (obs_m07_awvalid && obs_m07_wvalid) begin count = count+1; winner = 7; end

        $display("\n--- Routing Decision ---");
        if (count == 8)
            $display("ALL 8 SLAVES RECEIVED THE TRANSACTION");
        else if (count == 1)
            $display("ONLY SLAVE %0d RECEIVED THE TRANSACTION", winner);
        else if (count == 0)
            $display("NO SLAVE RECEIVED THE TRANSACTION (decode error / drop)");
        else begin
            $display("MULTIPLE SLAVES RECEIVED THE TRANSACTION (%0d slaves):", count);
            if (obs_m00_awvalid && obs_m00_wvalid) $display("  -> Slave 0");
            if (obs_m01_awvalid && obs_m01_wvalid) $display("  -> Slave 1");
            if (obs_m02_awvalid && obs_m02_wvalid) $display("  -> Slave 2");
            if (obs_m03_awvalid && obs_m03_wvalid) $display("  -> Slave 3");
            if (obs_m04_awvalid && obs_m04_wvalid) $display("  -> Slave 4");
            if (obs_m05_awvalid && obs_m05_wvalid) $display("  -> Slave 5");
            if (obs_m06_awvalid && obs_m06_wvalid) $display("  -> Slave 6");
            if (obs_m07_awvalid && obs_m07_wvalid) $display("  -> Slave 7");
        end
    end

    // ------------------------------------------------------------------
    // Final summary
    // ------------------------------------------------------------------
    $display("\n===== FINAL RESULT =====");
    $display("Single write transaction sent    : PASS");
    $display("Common base address used         : %08h", COMMON_BASE_ADDR);
    $display("Slave 0 received                 : %s",
        (obs_m00_awvalid && obs_m00_wvalid) ? "YES" : "NO");
    $display("Slave 1 received                 : %s",
        (obs_m01_awvalid && obs_m01_wvalid) ? "YES" : "NO");
    $display("Slave 2 received                 : %s",
        (obs_m02_awvalid && obs_m02_wvalid) ? "YES" : "NO");
    $display("Slave 3 received                 : %s",
        (obs_m03_awvalid && obs_m03_wvalid) ? "YES" : "NO");
    $display("Slave 4 received                 : %s",
        (obs_m04_awvalid && obs_m04_wvalid) ? "YES" : "NO");
    $display("Slave 5 received                 : %s",
        (obs_m05_awvalid && obs_m05_wvalid) ? "YES" : "NO");
    $display("Slave 6 received                 : %s",
        (obs_m06_awvalid && obs_m06_wvalid) ? "YES" : "NO");
    $display("Slave 7 received                 : %s",
        (obs_m07_awvalid && obs_m07_wvalid) ? "YES" : "NO");
    $display("Write response received          : %s",
        bresp_received ? "YES" : "NO");
    $display("BRESP                            : %02b (%s)",
        final_bresp,
        (final_bresp == 2'b00) ? "OKAY" :
        (final_bresp == 2'b10) ? "SLVERR" :
        (final_bresp == 2'b11) ? "DECERR" : "EXOKAY");
    $display("========================");

    $finish;
end

endmodule
