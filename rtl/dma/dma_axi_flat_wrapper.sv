/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : dma_axi_flat_wrapper.sv
 * Description    : Flat-wire wrapper around dma_axi_wrapper.
 *
 *   dma_axi_wrapper uses packed SystemVerilog structs for its AXI ports:
 *     - s_axil_mosi_t / s_axil_miso_t  (CSR AXI4-Lite slave  — M01)
 *     - s_axi_mosi_t  / s_axi_miso_t   (Data AXI4 master     — S01)
 *
 *   The axi_interconnect_wrap_2x8 uses flat wires.
 *   This wrapper bridges the two styles, exposing purely flat signals
 *   so the DMA can be instantiated directly in axi_interconnect_uart_top.v.
 *
 * Widths (from amba_axi_pkg.sv defaults):
 *   AXI_ADDR_WIDTH  = 32
 *   AXI_DATA_WIDTH  = 32
 *   AXI_STRB_WIDTH  = 4   (DATA/8)
 *   AXI_ID_WIDTH    = 8   (AXI_TXN_ID_WIDTH)
 *   AXI_ALEN_WIDTH  = 8
 *   AXI_USER_WIDTH  = 1
 *
 * ─── CSR SLAVE SIDE (connects to interconnect M01) ───────────────────────────
 *   axil_mosi fields present:  awid, awaddr, awprot, awvalid
 *                               wdata, wstrb, wvalid
 *                               bready
 *                               arid, araddr, arprot, arvalid
 *                               rready
 *   axil_miso fields present:  awready
 *                               wready
 *                               bid, bresp, bvalid
 *                               arready
 *                               rid, rdata, rresp, rvalid
 *
 * ─── MASTER SIDE (connects to interconnect S01) ──────────────────────────────
 *   axi_mosi fields present:   awid, awaddr, awlen, awsize, awburst,
 *                               awlock, awcache, awprot, awqos, awregion,
 *                               awuser, awvalid
 *                               wdata, wstrb, wlast, wuser, wvalid
 *                               bready
 *                               arid, araddr, arlen, arsize, arburst,
 *                               arlock, arcache, arprot, arqos, arregion,
 *                               aruser, arvalid
 *                               rready
 *   axi_miso fields present:   awready
 *                               wready
 *                               bid, bresp, buser, bvalid
 *                               arready
 *                               rid, rdata, rresp, rlast, ruser, rvalid
 * =============================================================================
 */

`default_nettype none

module dma_axi_flat_wrapper
  import amba_axi_pkg::*;
#(
  parameter int DMA_ID_VAL   = 1,
  parameter int ADDR_WIDTH   = 32,
  parameter int DATA_WIDTH   = 32,
  parameter int ID_WIDTH     = 8,
  parameter int STRB_WIDTH   = DATA_WIDTH / 8,
  parameter int ALEN_WIDTH   = 8
)(
  input  wire                   clk,
  input  wire                   rstn,    // active-low — inverted to rst inside

  // =========================================================================
  // CSR AXI4-Lite SLAVE (M01 — 0x0100_0000)
  // =========================================================================
  // Write Address
  input  wire [ID_WIDTH-1:0]    csr_awid,
  input  wire [ADDR_WIDTH-1:0]  csr_awaddr,
  input  wire [2:0]             csr_awprot,
  input  wire                   csr_awvalid,
  output wire                   csr_awready,
  // Write Data
  input  wire [DATA_WIDTH-1:0]  csr_wdata,
  input  wire [STRB_WIDTH-1:0]  csr_wstrb,
  input  wire                   csr_wvalid,
  output wire                   csr_wready,
  // Write Response
  output wire [ID_WIDTH-1:0]    csr_bid,
  output wire [1:0]             csr_bresp,
  output wire                   csr_bvalid,
  input  wire                   csr_bready,
  // Read Address
  input  wire [ID_WIDTH-1:0]    csr_arid,
  input  wire [ADDR_WIDTH-1:0]  csr_araddr,
  input  wire [2:0]             csr_arprot,
  input  wire                   csr_arvalid,
  output wire                   csr_arready,
  // Read Data
  output wire [ID_WIDTH-1:0]    csr_rid,
  output wire [DATA_WIDTH-1:0]  csr_rdata,
  output wire [1:0]             csr_rresp,
  output wire                   csr_rvalid,
  input  wire                   csr_rready,

  // =========================================================================
  // DATA AXI4 MASTER (S01)
  // =========================================================================
  // Write Address
  output wire [ID_WIDTH-1:0]    m_awid,
  output wire [ADDR_WIDTH-1:0]  m_awaddr,
  output wire [ALEN_WIDTH-1:0]  m_awlen,
  output wire [2:0]             m_awsize,
  output wire [1:0]             m_awburst,
  output wire                   m_awlock,
  output wire [3:0]             m_awcache,
  output wire [2:0]             m_awprot,
  output wire [3:0]             m_awqos,
  output wire [3:0]             m_awregion,
  output wire                   m_awvalid,
  input  wire                   m_awready,
  // Write Data
  output wire [DATA_WIDTH-1:0]  m_wdata,
  output wire [STRB_WIDTH-1:0]  m_wstrb,
  output wire                   m_wlast,
  output wire                   m_wvalid,
  input  wire                   m_wready,
  // Write Response
  input  wire [ID_WIDTH-1:0]    m_bid,
  input  wire [1:0]             m_bresp,
  input  wire                   m_bvalid,
  output wire                   m_bready,
  // Read Address
  output wire [ID_WIDTH-1:0]    m_arid,
  output wire [ADDR_WIDTH-1:0]  m_araddr,
  output wire [ALEN_WIDTH-1:0]  m_arlen,
  output wire [2:0]             m_arsize,
  output wire [1:0]             m_arburst,
  output wire                   m_arlock,
  output wire [3:0]             m_arcache,
  output wire [2:0]             m_arprot,
  output wire [3:0]             m_arqos,
  output wire [3:0]             m_arregion,
  output wire                   m_arvalid,
  input  wire                   m_arready,
  // Read Data
  input  wire [ID_WIDTH-1:0]    m_rid,
  input  wire [DATA_WIDTH-1:0]  m_rdata,
  input  wire [1:0]             m_rresp,
  input  wire                   m_rlast,
  input  wire                   m_rvalid,
  output wire                   m_rready,

  // =========================================================================
  // Interrupts
  // =========================================================================
  output wire                   dma_done_o,
  output wire                   dma_error_o
);

  // -------------------------------------------------------------------------
  // Pack flat wires → CSR struct  (s_axil_mosi_t)
  // -------------------------------------------------------------------------
  s_axil_mosi_t dma_csr_mosi;

  always_comb begin
    dma_csr_mosi          = '0;
    // Write Address
    dma_csr_mosi.awid     = axi_tid_t'(csr_awid);
    dma_csr_mosi.awaddr   = axi_addr_t'(csr_awaddr);
    dma_csr_mosi.awprot   = axi_prot_t'(csr_awprot);
    dma_csr_mosi.awvalid  = csr_awvalid;
    // Write Data
    dma_csr_mosi.wdata    = axi_data_t'(csr_wdata);
    dma_csr_mosi.wstrb    = axi_wr_strb_t'(csr_wstrb);
    dma_csr_mosi.wvalid   = csr_wvalid;
    // Write Response
    dma_csr_mosi.bready   = csr_bready;
    // Read Address
    dma_csr_mosi.arid     = axi_tid_t'(csr_arid);
    dma_csr_mosi.araddr   = axi_addr_t'(csr_araddr);
    dma_csr_mosi.arprot   = axi_prot_t'(csr_arprot);
    dma_csr_mosi.arvalid  = csr_arvalid;
    // Read Data
    dma_csr_mosi.rready   = csr_rready;
  end

  // -------------------------------------------------------------------------
  // Unpack CSR struct  (s_axil_miso_t) → flat wires
  // -------------------------------------------------------------------------
  s_axil_miso_t dma_csr_miso;

  assign csr_awready = dma_csr_miso.awready;
  assign csr_wready  = dma_csr_miso.wready;
  assign csr_bid     = ID_WIDTH'(dma_csr_miso.bid);
  assign csr_bresp   = dma_csr_miso.bresp;
  assign csr_bvalid  = dma_csr_miso.bvalid;
  assign csr_arready = dma_csr_miso.arready;
  assign csr_rid     = ID_WIDTH'(dma_csr_miso.rid);
  assign csr_rdata   = dma_csr_miso.rdata;
  assign csr_rresp   = dma_csr_miso.rresp;
  assign csr_rvalid  = dma_csr_miso.rvalid;

  // -------------------------------------------------------------------------
  // Unpack Master struct  (s_axi_mosi_t) → flat wires
  // -------------------------------------------------------------------------
  s_axi_mosi_t dma_m_mosi;

  assign m_awid     = ID_WIDTH'(dma_m_mosi.awid);
  assign m_awaddr   = dma_m_mosi.awaddr;
  assign m_awlen    = dma_m_mosi.awlen;
  assign m_awsize   = dma_m_mosi.awsize;
  assign m_awburst  = dma_m_mosi.awburst;
  assign m_awlock   = dma_m_mosi.awlock;
  assign m_awcache  = dma_m_mosi.awcache;
  assign m_awprot   = dma_m_mosi.awprot;
  assign m_awqos    = dma_m_mosi.awqos;
  assign m_awregion = dma_m_mosi.awregion;
  assign m_awvalid  = dma_m_mosi.awvalid;
  assign m_wdata    = dma_m_mosi.wdata;
  assign m_wstrb    = dma_m_mosi.wstrb;
  assign m_wlast    = dma_m_mosi.wlast;
  assign m_wvalid   = dma_m_mosi.wvalid;
  assign m_bready   = dma_m_mosi.bready;
  assign m_arid     = ID_WIDTH'(dma_m_mosi.arid);
  assign m_araddr   = dma_m_mosi.araddr;
  assign m_arlen    = dma_m_mosi.arlen;
  assign m_arsize   = dma_m_mosi.arsize;
  assign m_arburst  = dma_m_mosi.arburst;
  assign m_arlock   = dma_m_mosi.arlock;
  assign m_arcache  = dma_m_mosi.arcache;
  assign m_arprot   = dma_m_mosi.arprot;
  assign m_arqos    = dma_m_mosi.arqos;
  assign m_arregion = dma_m_mosi.arregion;
  assign m_arvalid  = dma_m_mosi.arvalid;
  assign m_rready   = dma_m_mosi.rready;

  // -------------------------------------------------------------------------
  // Pack flat wires → Master MISO struct  (s_axi_miso_t)
  // -------------------------------------------------------------------------
  s_axi_miso_t dma_m_miso;

  always_comb begin
    dma_m_miso          = '0;
    // Write
    dma_m_miso.awready  = m_awready;
    dma_m_miso.wready   = m_wready;
    dma_m_miso.bid      = axi_tid_t'(m_bid);
    dma_m_miso.bresp    = axi_resp_t'(m_bresp);
    dma_m_miso.bvalid   = m_bvalid;
    // Read
    dma_m_miso.arready  = m_arready;
    dma_m_miso.rid      = axi_tid_t'(m_rid);
    dma_m_miso.rdata    = axi_data_t'(m_rdata);
    dma_m_miso.rresp    = axi_resp_t'(m_rresp);
    dma_m_miso.rlast    = m_rlast;
    dma_m_miso.rvalid   = m_rvalid;
  end

  // -------------------------------------------------------------------------
  // DMA core instantiation
  // -------------------------------------------------------------------------
  dma_axi_wrapper #(
    .DMA_ID_VAL (DMA_ID_VAL)
  ) u_dma (
    .clk            (clk),
    .rst            (~rstn),         // DMA uses active-high rst
    .dma_csr_mosi_i (dma_csr_mosi),
    .dma_csr_miso_o (dma_csr_miso),
    .dma_m_mosi_o   (dma_m_mosi),
    .dma_m_miso_i   (dma_m_miso),
    .dma_done_o     (dma_done_o),
    .dma_error_o    (dma_error_o)
  );

endmodule

`default_nettype wire
