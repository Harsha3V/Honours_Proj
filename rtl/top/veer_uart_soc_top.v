/* =============================================================================
 * Project        : Honours Project
 * File           : veer_uart_soc_top.v
 * Description    : SoC integration top-level.
 *
 *   Connects VeeR EL2 RISC-V core (LSU AXI master) to the existing
 *   axi_interconnect_uart_top (AXI interconnect + AXI4-Lite UART slave).
 *
 *  Block diagram:
 *
 *   ┌─────────────────────────────────────────────────────────────────┐
 *   │                      veer_uart_soc_top                          │
 *   │                                                                 │
 *   │  ┌──────────────────┐    LSU AXI (64-bit)   ┌──────────────┐   │
 *   │  │  el2_veer_wrapper│ ───────────────────→  │  width adapt │   │
 *   │  │  (VeeR EL2 core) │  lsu_axi_aw/w/b/ar/r  │  64→32 bit   │   │
 *   │  │                  │                        └──────┬───────┘   │
 *   │  │  IFU AXI ────────────────────────────→  ifu_rom_stub        │
 *   │  │  (instr fetch)   │                               │           │
 *   │  └──────────────────┘                       32-bit AXI s00      │
 *   │                                                     ↓           │
 *   │                                      ┌─────────────────────┐    │
 *   │                                      │ axi_interconnect_   │    │
 *   │                                      │ uart_top            │    │
 *   │                                      └──────────┬──────────┘    │
 *   │                                                 │               │
 *   │                                         uart_tx_o / uart_rx_i   │
 *   └─────────────────────────────────────────────────────────────────┘
 *
 * Key notes:
 *   1. VeeR LSU AXI data = 64-bit; interconnect = 32-bit → lower 32 used.
 *   2. VeeR LSU ID = LSU_BUS_TAG bits; IC ID = 8 bits → zero-extended.
 *   3. SB and DMA buses (AHB in this version) are tied off.
 *   4. Lockstep / DMI / shadow ports tied off — not used.
 *   5. +define+RV_BUILD_AXI4 required for AXI4 LSU/IFU bus selection.
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module veer_uart_soc_top #(
    // VeeR bus tag widths — keep in sync with veer.config
    parameter LSU_BUS_TAG  = 3,
    parameter IFU_BUS_TAG  = 3,
    parameter SB_BUS_TAG   = 1,
    parameter DMA_BUS_TAG  = 1,

    // AXI interconnect parameters
    parameter IC_ID_WIDTH   = 8,
    parameter IC_ADDR_WIDTH = 32,
    parameter IC_DATA_WIDTH = 32,

    // ROM stub word count (32-bit words)
    parameter ROM_DEPTH     = 1024
)(
    input  wire         clk,
    input  wire         rst_l,      // active-high reset for VeeR
    input  wire         rstn,       // active-low  reset for IC/UART

    input  wire [31:1]  rst_vec,
    input  wire         nmi_int,
    input  wire [31:1]  nmi_vec,
    input  wire [31:1]  jtag_id,

    input  wire         jtag_tck,
    input  wire         jtag_tms,
    input  wire         jtag_tdi,
    output wire         jtag_tdo,

    input  wire         uart_rx_i,
    output wire         uart_tx_o,
    output wire         uart_interrupt_o
);

// ===================================================================
// 1. VeeR LSU AXI wires (64-bit data, LSU_BUS_TAG-bit ID)
// ===================================================================

wire                    lsu_axi_awvalid;
wire                    lsu_axi_awready;
wire [LSU_BUS_TAG-1:0]  lsu_axi_awid;
wire [31:0]             lsu_axi_awaddr;
wire [3:0]              lsu_axi_awregion;
wire [7:0]              lsu_axi_awlen;
wire [2:0]              lsu_axi_awsize;
wire [1:0]              lsu_axi_awburst;
wire                    lsu_axi_awlock;
wire [3:0]              lsu_axi_awcache;
wire [2:0]              lsu_axi_awprot;
wire [3:0]              lsu_axi_awqos;

wire                    lsu_axi_wvalid;
wire                    lsu_axi_wready;
wire [63:0]             lsu_axi_wdata;
wire [7:0]              lsu_axi_wstrb;
wire                    lsu_axi_wlast;

wire                    lsu_axi_bvalid;
wire                    lsu_axi_bready;
wire [1:0]              lsu_axi_bresp;
wire [LSU_BUS_TAG-1:0]  lsu_axi_bid;

wire                    lsu_axi_arvalid;
wire                    lsu_axi_arready;
wire [LSU_BUS_TAG-1:0]  lsu_axi_arid;
wire [31:0]             lsu_axi_araddr;
wire [3:0]              lsu_axi_arregion;
wire [7:0]              lsu_axi_arlen;
wire [2:0]              lsu_axi_arsize;
wire [1:0]              lsu_axi_arburst;
wire                    lsu_axi_arlock;
wire [3:0]              lsu_axi_arcache;
wire [2:0]              lsu_axi_arprot;
wire [3:0]              lsu_axi_arqos;

wire                    lsu_axi_rvalid;
wire                    lsu_axi_rready;
wire [LSU_BUS_TAG-1:0]  lsu_axi_rid;
wire [63:0]             lsu_axi_rdata;
wire [1:0]              lsu_axi_rresp;
wire                    lsu_axi_rlast;

// ===================================================================
// 2. VeeR IFU AXI wires
// ===================================================================

wire                    ifu_axi_awvalid;
wire                    ifu_axi_awready;
wire [IFU_BUS_TAG-1:0]  ifu_axi_awid;
wire [31:0]             ifu_axi_awaddr;
wire [3:0]              ifu_axi_awregion;
wire [7:0]              ifu_axi_awlen;
wire [2:0]              ifu_axi_awsize;
wire [1:0]              ifu_axi_awburst;
wire                    ifu_axi_awlock;
wire [3:0]              ifu_axi_awcache;
wire [2:0]              ifu_axi_awprot;
wire [3:0]              ifu_axi_awqos;

wire                    ifu_axi_wvalid;
wire                    ifu_axi_wready;
wire [63:0]             ifu_axi_wdata;
wire [7:0]              ifu_axi_wstrb;
wire                    ifu_axi_wlast;

wire                    ifu_axi_bvalid;
wire                    ifu_axi_bready;
wire [1:0]              ifu_axi_bresp;
wire [IFU_BUS_TAG-1:0]  ifu_axi_bid;

wire                    ifu_axi_arvalid;
wire                    ifu_axi_arready;
wire [IFU_BUS_TAG-1:0]  ifu_axi_arid;
wire [31:0]             ifu_axi_araddr;
wire [3:0]              ifu_axi_arregion;
wire [7:0]              ifu_axi_arlen;
wire [2:0]              ifu_axi_arsize;
wire [1:0]              ifu_axi_arburst;
wire                    ifu_axi_arlock;
wire [3:0]              ifu_axi_arcache;
wire [2:0]              ifu_axi_arprot;
wire [3:0]              ifu_axi_arqos;

wire                    ifu_axi_rvalid;
wire                    ifu_axi_rready;
wire [IFU_BUS_TAG-1:0]  ifu_axi_rid;
wire [63:0]             ifu_axi_rdata;
wire [1:0]              ifu_axi_rresp;
wire                    ifu_axi_rlast;

// ===================================================================
// 2b. SB AXI wires (debug bus — outputs collected, inputs tied off)
// ===================================================================

wire                    sb_axi_awvalid;
wire [SB_BUS_TAG-1:0]   sb_axi_awid;
wire [31:0]             sb_axi_awaddr;
wire [3:0]              sb_axi_awregion;
wire [7:0]              sb_axi_awlen;
wire [2:0]              sb_axi_awsize;
wire [1:0]              sb_axi_awburst;
wire                    sb_axi_awlock;
wire [3:0]              sb_axi_awcache;
wire [2:0]              sb_axi_awprot;
wire [3:0]              sb_axi_awqos;
wire                    sb_axi_wvalid;
wire [63:0]             sb_axi_wdata;
wire [7:0]              sb_axi_wstrb;
wire                    sb_axi_wlast;
wire                    sb_axi_bready;
wire                    sb_axi_arvalid;
wire [SB_BUS_TAG-1:0]   sb_axi_arid;
wire [31:0]             sb_axi_araddr;
wire [3:0]              sb_axi_arregion;
wire [7:0]              sb_axi_arlen;
wire [2:0]              sb_axi_arsize;
wire [1:0]              sb_axi_arburst;
wire                    sb_axi_arlock;
wire [3:0]              sb_axi_arcache;
wire [2:0]              sb_axi_arprot;
wire [3:0]              sb_axi_arqos;
wire                    sb_axi_rready;

// ===================================================================
// 3. 32-bit adapted AXI wires (LSU 64-bit → IC 32-bit)
// ===================================================================

wire [IC_ID_WIDTH-1:0]    s00_awid    = {{(IC_ID_WIDTH-LSU_BUS_TAG){1'b0}}, lsu_axi_awid};
wire [IC_ADDR_WIDTH-1:0]  s00_awaddr  = lsu_axi_awaddr;
wire [7:0]                s00_awlen   = lsu_axi_awlen;
wire [2:0]                s00_awsize  = lsu_axi_awsize;
wire [1:0]                s00_awburst = lsu_axi_awburst;
wire                      s00_awlock  = lsu_axi_awlock;
wire [3:0]                s00_awcache = lsu_axi_awcache;
wire [2:0]                s00_awprot  = lsu_axi_awprot;
wire [3:0]                s00_awqos   = lsu_axi_awqos;
wire                      s00_awvalid = lsu_axi_awvalid;
wire                      s00_awready;

wire [IC_DATA_WIDTH-1:0]    s00_wdata  = lsu_axi_wdata[IC_DATA_WIDTH-1:0];
wire [IC_DATA_WIDTH/8-1:0]  s00_wstrb  = lsu_axi_wstrb[IC_DATA_WIDTH/8-1:0];
wire                         s00_wlast  = lsu_axi_wlast;
wire                         s00_wvalid = lsu_axi_wvalid;
wire                         s00_wready;

wire [IC_ID_WIDTH-1:0]  s00_bid;
wire [1:0]              s00_bresp;
wire                    s00_bvalid;
wire                    s00_bready = lsu_axi_bready;

wire [IC_ID_WIDTH-1:0]   s00_arid    = {{(IC_ID_WIDTH-LSU_BUS_TAG){1'b0}}, lsu_axi_arid};
wire [IC_ADDR_WIDTH-1:0] s00_araddr  = lsu_axi_araddr;
wire [7:0]               s00_arlen   = lsu_axi_arlen;
wire [2:0]               s00_arsize  = lsu_axi_arsize;
wire [1:0]               s00_arburst = lsu_axi_arburst;
wire                     s00_arlock  = lsu_axi_arlock;
wire [3:0]               s00_arcache = lsu_axi_arcache;
wire [2:0]               s00_arprot  = lsu_axi_arprot;
wire [3:0]               s00_arqos   = lsu_axi_arqos;
wire                     s00_arvalid = lsu_axi_arvalid;
wire                     s00_arready;

wire [IC_ID_WIDTH-1:0]   s00_rid;
wire [IC_DATA_WIDTH-1:0] s00_rdata;
wire [1:0]               s00_rresp;
wire                     s00_rlast;
wire                     s00_rvalid;
wire                     s00_rready = lsu_axi_rready;

// Feed back to VeeR LSU
assign lsu_axi_awready = s00_awready;
assign lsu_axi_wready  = s00_wready;
assign lsu_axi_bvalid  = s00_bvalid;
assign lsu_axi_bresp   = s00_bresp;
assign lsu_axi_bid     = s00_bid[LSU_BUS_TAG-1:0];
assign lsu_axi_arready = s00_arready;
assign lsu_axi_rvalid  = s00_rvalid;
assign lsu_axi_rid     = s00_rid[LSU_BUS_TAG-1:0];
assign lsu_axi_rdata   = {{32{1'b0}}, s00_rdata};
assign lsu_axi_rresp   = s00_rresp;
assign lsu_axi_rlast   = s00_rlast;

// ===================================================================
// 4. Memory interface instance (required by el2_veer_wrapper)
// ===================================================================

el2_mem_if mem_export_iface ();

// ===================================================================
// 5. VeeR EL2 Core instance
// ===================================================================

el2_veer_wrapper u_veer (
    .clk            (clk),
    .rst_l          (rst_l),
    .dbg_rst_l      (rst_l),
    .rst_vec        (rst_vec),
    .nmi_int        (nmi_int),
    .nmi_vec        (nmi_vec),
    .jtag_id        (jtag_id),

    // ---- Trace (unused) ----
    .trace_rv_i_insn_ip     (),
    .trace_rv_i_address_ip  (),
    .trace_rv_i_valid_ip    (),
    .trace_rv_i_exception_ip(),
    .trace_rv_i_ecause_ip   (),
    .trace_rv_i_interrupt_ip(),
    .trace_rv_i_tval_ip     (),

    // ---- LSU AXI ----
    .lsu_axi_awvalid  (lsu_axi_awvalid),
    .lsu_axi_awready  (lsu_axi_awready),
    .lsu_axi_awid     (lsu_axi_awid),
    .lsu_axi_awaddr   (lsu_axi_awaddr),
    .lsu_axi_awregion (lsu_axi_awregion),
    .lsu_axi_awlen    (lsu_axi_awlen),
    .lsu_axi_awsize   (lsu_axi_awsize),
    .lsu_axi_awburst  (lsu_axi_awburst),
    .lsu_axi_awlock   (lsu_axi_awlock),
    .lsu_axi_awcache  (lsu_axi_awcache),
    .lsu_axi_awprot   (lsu_axi_awprot),
    .lsu_axi_awqos    (lsu_axi_awqos),
    .lsu_axi_wvalid   (lsu_axi_wvalid),
    .lsu_axi_wready   (lsu_axi_wready),
    .lsu_axi_wdata    (lsu_axi_wdata),
    .lsu_axi_wstrb    (lsu_axi_wstrb),
    .lsu_axi_wlast    (lsu_axi_wlast),
    .lsu_axi_bvalid   (lsu_axi_bvalid),
    .lsu_axi_bready   (lsu_axi_bready),
    .lsu_axi_bresp    (lsu_axi_bresp),
    .lsu_axi_bid      (lsu_axi_bid),
    .lsu_axi_arvalid  (lsu_axi_arvalid),
    .lsu_axi_arready  (lsu_axi_arready),
    .lsu_axi_arid     (lsu_axi_arid),
    .lsu_axi_araddr   (lsu_axi_araddr),
    .lsu_axi_arregion (lsu_axi_arregion),
    .lsu_axi_arlen    (lsu_axi_arlen),
    .lsu_axi_arsize   (lsu_axi_arsize),
    .lsu_axi_arburst  (lsu_axi_arburst),
    .lsu_axi_arlock   (lsu_axi_arlock),
    .lsu_axi_arcache  (lsu_axi_arcache),
    .lsu_axi_arprot   (lsu_axi_arprot),
    .lsu_axi_arqos    (lsu_axi_arqos),
    .lsu_axi_rvalid   (lsu_axi_rvalid),
    .lsu_axi_rready   (lsu_axi_rready),
    .lsu_axi_rid      (lsu_axi_rid),
    .lsu_axi_rdata    (lsu_axi_rdata),
    .lsu_axi_rresp    (lsu_axi_rresp),
    .lsu_axi_rlast    (lsu_axi_rlast),

    // ---- IFU AXI ----
    .ifu_axi_awvalid  (ifu_axi_awvalid),
    .ifu_axi_awready  (ifu_axi_awready),
    .ifu_axi_awid     (ifu_axi_awid),
    .ifu_axi_awaddr   (ifu_axi_awaddr),
    .ifu_axi_awregion (ifu_axi_awregion),
    .ifu_axi_awlen    (ifu_axi_awlen),
    .ifu_axi_awsize   (ifu_axi_awsize),
    .ifu_axi_awburst  (ifu_axi_awburst),
    .ifu_axi_awlock   (ifu_axi_awlock),
    .ifu_axi_awcache  (ifu_axi_awcache),
    .ifu_axi_awprot   (ifu_axi_awprot),
    .ifu_axi_awqos    (ifu_axi_awqos),
    .ifu_axi_wvalid   (ifu_axi_wvalid),
    .ifu_axi_wready   (ifu_axi_wready),
    .ifu_axi_wdata    (ifu_axi_wdata),
    .ifu_axi_wstrb    (ifu_axi_wstrb),
    .ifu_axi_wlast    (ifu_axi_wlast),
    .ifu_axi_bvalid   (ifu_axi_bvalid),
    .ifu_axi_bready   (ifu_axi_bready),
    .ifu_axi_bresp    (ifu_axi_bresp),
    .ifu_axi_bid      (ifu_axi_bid),
    .ifu_axi_arvalid  (ifu_axi_arvalid),
    .ifu_axi_arready  (ifu_axi_arready),
    .ifu_axi_arid     (ifu_axi_arid),
    .ifu_axi_araddr   (ifu_axi_araddr),
    .ifu_axi_arregion (ifu_axi_arregion),
    .ifu_axi_arlen    (ifu_axi_arlen),
    .ifu_axi_arsize   (ifu_axi_arsize),
    .ifu_axi_arburst  (ifu_axi_arburst),
    .ifu_axi_arlock   (ifu_axi_arlock),
    .ifu_axi_arcache  (ifu_axi_arcache),
    .ifu_axi_arprot   (ifu_axi_arprot),
    .ifu_axi_arqos    (ifu_axi_arqos),
    .ifu_axi_rvalid   (ifu_axi_rvalid),
    .ifu_axi_rready   (ifu_axi_rready),
    .ifu_axi_rid      (ifu_axi_rid),
    .ifu_axi_rdata    (ifu_axi_rdata),
    .ifu_axi_rresp    (ifu_axi_rresp),
    .ifu_axi_rlast    (ifu_axi_rlast),

    // ---- SB AXI (debug system bus — tied off) ----
    .sb_axi_awvalid   (sb_axi_awvalid),
    .sb_axi_awready   (1'b1),
    .sb_axi_awid      (sb_axi_awid),
    .sb_axi_awaddr    (sb_axi_awaddr),
    .sb_axi_awregion  (sb_axi_awregion),
    .sb_axi_awlen     (sb_axi_awlen),
    .sb_axi_awsize    (sb_axi_awsize),
    .sb_axi_awburst   (sb_axi_awburst),
    .sb_axi_awlock    (sb_axi_awlock),
    .sb_axi_awcache   (sb_axi_awcache),
    .sb_axi_awprot    (sb_axi_awprot),
    .sb_axi_awqos     (sb_axi_awqos),
    .sb_axi_wvalid    (sb_axi_wvalid),
    .sb_axi_wready    (1'b1),
    .sb_axi_wdata     (sb_axi_wdata),
    .sb_axi_wstrb     (sb_axi_wstrb),
    .sb_axi_wlast     (sb_axi_wlast),
    .sb_axi_bvalid    (1'b0),
    .sb_axi_bready    (sb_axi_bready),
    .sb_axi_bresp     (2'b00),
    .sb_axi_bid       ({SB_BUS_TAG{1'b0}}),
    .sb_axi_arvalid   (sb_axi_arvalid),
    .sb_axi_arready   (1'b1),
    .sb_axi_arid      (sb_axi_arid),
    .sb_axi_araddr    (sb_axi_araddr),
    .sb_axi_arregion  (sb_axi_arregion),
    .sb_axi_arlen     (sb_axi_arlen),
    .sb_axi_arsize    (sb_axi_arsize),
    .sb_axi_arburst   (sb_axi_arburst),
    .sb_axi_arlock    (sb_axi_arlock),
    .sb_axi_arcache   (sb_axi_arcache),
    .sb_axi_arprot    (sb_axi_arprot),
    .sb_axi_arqos     (sb_axi_arqos),
    .sb_axi_rvalid    (1'b0),
    .sb_axi_rready    (sb_axi_rready),
    .sb_axi_rid       ({SB_BUS_TAG{1'b0}}),
    .sb_axi_rdata     (64'h0),
    .sb_axi_rresp     (2'b00),
    .sb_axi_rlast     (1'b1),

    // ---- DMA AXI slave (tied off) ----
    .dma_axi_awvalid  (1'b0),
    .dma_axi_awready  (),
    .dma_axi_awid     ({DMA_BUS_TAG{1'b0}}),
    .dma_axi_awaddr   (32'h0),
    .dma_axi_awsize   (3'b010),
    .dma_axi_awprot   (3'b000),
    .dma_axi_awlen    (8'h0),
    .dma_axi_awburst  (2'b01),
    .dma_axi_wvalid   (1'b0),
    .dma_axi_wready   (),
    .dma_axi_wdata    (64'h0),
    .dma_axi_wstrb    (8'h0),
    .dma_axi_wlast    (1'b1),
    .dma_axi_bvalid   (),
    .dma_axi_bready   (1'b1),
    .dma_axi_bresp    (),
    .dma_axi_bid      (),
    .dma_axi_arvalid  (1'b0),
    .dma_axi_arready  (),
    .dma_axi_arid     ({DMA_BUS_TAG{1'b0}}),
    .dma_axi_araddr   (32'h0),
    .dma_axi_arsize   (3'b010),
    .dma_axi_arprot   (3'b000),
    .dma_axi_arlen    (8'h0),
    .dma_axi_arburst  (2'b01),
    .dma_axi_rvalid   (),
    .dma_axi_rready   (1'b1),
    .dma_axi_rid      (),
    .dma_axi_rdata    (),
    .dma_axi_rresp    (),
    .dma_axi_rlast    (),

    // ---- IFU AHB (not present with RV_BUILD_AXI4 — do not connect) ----
    // ---- LSU AHB (not present with RV_BUILD_AXI4 — do not connect) ----
    // ---- SB AHB  (not present with RV_BUILD_AXI4 — do not connect) ----
    // ---- DMA AHB (not present with RV_BUILD_AXI4 — do not connect) ----

    // ---- ECC error outputs (unused) ----
    .iccm_ecc_single_error  (),
    .iccm_ecc_double_error  (),
    .dccm_ecc_single_error  (),
    .dccm_ecc_double_error  (),
    .dccm_write_readback_error(),

    // ---- Memory interfaces ----
    .el2_mem_export   (mem_export_iface.veer_sram_src),
    .el2_icache_export(mem_export_iface.veer_icache_src),

    // ---- Interrupts ----
    .extintsrc_req    ({31{1'b0}}),
    .timer_int        (1'b0),
    .soft_int         (1'b0),
    .core_id          (28'h0),

    // ---- Performance counters (unused) ----
    .dec_tlu_perfcnt1 (),
    .dec_tlu_perfcnt2 (),
    .dec_tlu_perfcnt3 (),

    // ---- Shadow/lockstep (not present — RV_LOCKSTEP_ENABLE not defined) ----

    // ---- DMI (tied off) ----
    .dmi_core_enable  (1'b0),
    .dmi_uncore_enable(1'b0),
    .dmi_uncore_en    (),
    .dmi_uncore_wr_en (),
    .dmi_uncore_addr  (),
    .dmi_uncore_wdata (),
    .dmi_uncore_rdata (32'h0),
    .dmi_active       (),

    // ---- JTAG ----
    .jtag_tck         (jtag_tck),
    .jtag_tms         (jtag_tms),
    .jtag_tdi         (jtag_tdi),
    .jtag_tdo         (jtag_tdo),
    .jtag_trst_n      (1'b1),

    // ---- Scan / MBIST ----
    .scan_mode        (1'b0),
    .mbist_mode       (1'b0)
);

// ===================================================================
// 6. IFU ROM stub (instruction memory for VeeR IFU AXI fetch)
// ===================================================================

ifu_rom_stub #(
    .ID_WIDTH  (IFU_BUS_TAG),
    .ROM_WORDS (ROM_DEPTH)
) u_ifu_rom (
    .clk        (clk),
    .rstn       (rstn),

    .axi_arid_i    (ifu_axi_arid),
    .axi_araddr_i  (ifu_axi_araddr),
    .axi_arlen_i   (ifu_axi_arlen),
    .axi_arsize_i  (ifu_axi_arsize),
    .axi_arburst_i (ifu_axi_arburst),
    .axi_arvalid_i (ifu_axi_arvalid),
    .axi_arready_o (ifu_axi_arready),

    .axi_rid_o    (ifu_axi_rid),
    .axi_rdata_o  (ifu_axi_rdata),
    .axi_rresp_o  (ifu_axi_rresp),
    .axi_rlast_o  (ifu_axi_rlast),
    .axi_rvalid_o (ifu_axi_rvalid),
    .axi_rready_i (ifu_axi_rready),

    .axi_awready_o (ifu_axi_awready),
    .axi_wready_o  (ifu_axi_wready),
    .axi_bvalid_o  (ifu_axi_bvalid),
    .axi_bresp_o   (ifu_axi_bresp),
    .axi_bid_o     (ifu_axi_bid)
);

// ===================================================================
// 7. AXI Interconnect + UART top
// ===================================================================

axi_interconnect_uart_top #(
    .DATA_WIDTH      (IC_DATA_WIDTH),
    .ADDR_WIDTH      (IC_ADDR_WIDTH),
    .ID_WIDTH        (IC_ID_WIDTH),
    .UART_BASE_ADDR  (32'h0000_0000),
    .UART_ADDR_WIDTH (24)
) u_ic_uart (
    .clk             (clk),
    .rstn            (rstn),

    .s00_axi_awid    (s00_awid),
    .s00_axi_awaddr  (s00_awaddr),
    .s00_axi_awlen   (s00_awlen),
    .s00_axi_awsize  (s00_awsize),
    .s00_axi_awburst (s00_awburst),
    .s00_axi_awlock  (s00_awlock),
    .s00_axi_awcache (s00_awcache),
    .s00_axi_awprot  (s00_awprot),
    .s00_axi_awqos   (s00_awqos),
    .s00_axi_awvalid (s00_awvalid),
    .s00_axi_awready (s00_awready),

    .s00_axi_wdata   (s00_wdata),
    .s00_axi_wstrb   (s00_wstrb),
    .s00_axi_wlast   (s00_wlast),
    .s00_axi_wvalid  (s00_wvalid),
    .s00_axi_wready  (s00_wready),

    .s00_axi_bid     (s00_bid),
    .s00_axi_bresp   (s00_bresp),
    .s00_axi_bvalid  (s00_bvalid),
    .s00_axi_bready  (s00_bready),

    .s00_axi_arid    (s00_arid),
    .s00_axi_araddr  (s00_araddr),
    .s00_axi_arlen   (s00_arlen),
    .s00_axi_arsize  (s00_arsize),
    .s00_axi_arburst (s00_arburst),
    .s00_axi_arlock  (s00_arlock),
    .s00_axi_arcache (s00_arcache),
    .s00_axi_arprot  (s00_arprot),
    .s00_axi_arqos   (s00_arqos),
    .s00_axi_arvalid (s00_arvalid),
    .s00_axi_arready (s00_arready),

    .s00_axi_rid     (s00_rid),
    .s00_axi_rdata   (s00_rdata),
    .s00_axi_rresp   (s00_rresp),
    .s00_axi_rlast   (s00_rlast),
    .s00_axi_rvalid  (s00_rvalid),
    .s00_axi_rready  (s00_rready),

    .uart_rx_i       (uart_rx_i),
    .uart_tx_o       (uart_tx_o),
    .uart_interrupt_o(uart_interrupt_o)
);

endmodule

`default_nettype wire
