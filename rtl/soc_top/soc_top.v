/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : soc_top.v
 * Description    : Full System-on-Chip (SoC) Top-Level.
 *
 * Architecture:
 * ┌───────────────────────────────────────────────────────────────────────────┐
 * │                               soc_top                                     │
 * │                                                                           │
 * │  ┌───────────────────────┐    LSU AXI (64-bit)    ┌──────────────────┐    │
 * │  │  el2_veer_wrapper     │ ─────────────────────→ │ 64→32 Width      │    │
 * │  │  (VeeR EL2 RV32IMC)   │   lsu_axi_*            │ Adapter          │    │
 * │  │                       │                        └────────┬─────────┘    │
 * │  │  • ICCM (64KB code)   │                                 │ AXI S00      │
 * │  │  • DCCM (64KB data)   │                                 │ (CPU Master) │
 * │  │  • ICache (16KB)      │                                 ▼              │
 * │  │                       │               ┌──────────────────────────────┐ │
 * │  │  IFU AXI (64-bit)     │               │  axi_interconnect_uart_top   │ │
 * │  │   (Instruction Fetch) │               │  (2 Masters × 8 Slaves)      │ │
 * │  └───────────┬───────────┘               ├──────────────────────────────┤ │
 * │              │                           │ S00: CPU LSU Master          │ │
 * │              ▼                           │ S01: DMA Controller Master   │ │
 * │     ┌─────────────────┐                  ├──────────────────────────────┤ │
 * │     │  ifu_rom_stub   │                  │ M00: AES-128 Engine (0x00..) │ │
 * │     │  (Boot ROM)     │                  │ M01: DMA CSR        (0x01..) │ │
 * │     │  @ 0x8000_0000  │                  │ M02: SPI Master     (0x02..) │ │
 * │     └─────────────────┘                  │ M03: UART           (0x03..) │ │
 * │                                          │ M04: Timer EF_TCC32 (0x04..) │ │
 * │                                          │ M05: GPIO EF_GPIO8  (0x05..) │ │
 * │                                          │ M06: AXI SRAM 64KB  (0x06..) │ │
 * │                                          │ M07: Tied off                │ │
 * │                                          └──────────────┬───────────────┘ │
 * │                                                         │                 │
 * │                       Peripherals: UART, SPI, GPIO, Timer, DMA Interrupts │
 * └───────────────────────────────────────────────────────────────────────────┘
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module soc_top #(
    // VeeR bus tag widths — sync with veer.config
    parameter LSU_BUS_TAG   = 3,
    parameter IFU_BUS_TAG   = 3,
    parameter SB_BUS_TAG    = 1,
    parameter DMA_BUS_TAG   = 1,

    // AXI interconnect parameters
    parameter IC_ID_WIDTH   = 8,
    parameter IC_ADDR_WIDTH = 32,
    parameter IC_DATA_WIDTH = 32,

    // Instruction Boot ROM
    parameter ROM_DEPTH     = 4096,                 // 4096 x 32-bit words = 16 KB
    parameter ROM_FILE      = "boot.hex"
)(
    input  wire         clk,
    input  wire         rst_l,          // active-high reset for VeeR core
    input  wire         rstn,           // active-low  reset for interconnect & IPs

    // CPU Boot & Control
    input  wire [31:1]  rst_vec,        // Reset vector (e.g. 31'h4000_0000 for 0x8000_0000)
    input  wire         nmi_int,
    input  wire [31:1]  nmi_vec,
    input  wire [31:1]  jtag_id,

    // JTAG Interface
    input  wire         jtag_tck,
    input  wire         jtag_tms,
    input  wire         jtag_tdi,
    output wire         jtag_tdo,

    // UART External Pins
    input  wire         uart_rx_i,
    output wire         uart_tx_o,
    output wire         uart_irq_o,

    // SPI External Pins (Connects to external MCP2515 CAN controller)
    output wire         spi_clk_o,
    output wire         spi_mosi_o,
    input  wire         spi_miso_i,
    output wire         spi_cs_n_o,

    // GPIO External Pins
    input  wire [7:0]   gpio_in_i,
    output wire [7:0]   gpio_out_o,
    output wire [7:0]   gpio_oe_o,
    output wire         gpio_irq_o,

    // Timer External Input / Output
    input  wire         timer_ctr_in_i,
    output wire         timer_irq_o,

    // DMA Status Interrupts
    output wire         dma_done_o,
    output wire         dma_error_o
);

// ===================================================================
// 1. VeeR LSU AXI Wires (64-bit data, LSU_BUS_TAG-bit ID)
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
// 2. VeeR IFU AXI Wires (64-bit fetch, IFU_BUS_TAG-bit ID)
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
// 3. System Bus (SB) AXI Wires (debug bus — tied off)
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
// 4. Width Adaptation (VeeR LSU 64-bit ↔ Interconnect S00 32-bit)
// ===================================================================
wire [IC_ID_WIDTH-1:0]    s00_awid    = {{(IC_ID_WIDTH-LSU_BUS_TAG){1'b0}}, lsu_axi_awid};
wire                      lsu_wr_word1 = (lsu_axi_wstrb[7:4] != 4'b0000) || lsu_axi_awaddr[2];
wire [IC_ADDR_WIDTH-1:0]  s00_awaddr  = {lsu_axi_awaddr[IC_ADDR_WIDTH-1:3], lsu_wr_word1, lsu_axi_awaddr[1:0]};
wire [7:0]                s00_awlen   = lsu_axi_awlen;
wire [2:0]                s00_awsize  = lsu_axi_awsize;
wire [1:0]                s00_awburst = lsu_axi_awburst;
wire                      s00_awlock  = lsu_axi_awlock;
wire [3:0]                s00_awcache = lsu_axi_awcache;
wire [2:0]                s00_awprot  = lsu_axi_awprot;
wire [3:0]                s00_awqos   = lsu_axi_awqos;
wire                      s00_awvalid = lsu_axi_awvalid;
wire                      s00_awready;

wire [IC_DATA_WIDTH-1:0]    s00_wdata  = lsu_wr_word1 ? lsu_axi_wdata[63:32] : lsu_axi_wdata[31:0];
wire [IC_DATA_WIDTH/8-1:0]  s00_wstrb  = lsu_wr_word1 ? lsu_axi_wstrb[7:4]   : lsu_axi_wstrb[3:0];
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
wire                     s00_arvalid;
wire                     s00_arready;

wire [IC_ID_WIDTH-1:0]   s00_rid;
wire [IC_DATA_WIDTH-1:0] s00_rdata;
wire [1:0]               s00_rresp;
wire                     s00_rlast;
wire                     s00_rvalid;
wire                     s00_rready = lsu_axi_rready;

// LSU Read Steering (Boot ROM @ 0x8000_0000 vs AXI Interconnect)
wire lsu_ar_is_rom = (lsu_axi_araddr[31:28] == 4'h8);

wire [LSU_BUS_TAG-1:0] lsu_rom_arid    = lsu_axi_arid;
wire [31:0]            lsu_rom_araddr  = lsu_axi_araddr;
wire [7:0]             lsu_rom_arlen   = lsu_axi_arlen;
wire [2:0]             lsu_rom_arsize  = lsu_axi_arsize;
wire [1:0]             lsu_rom_arburst = lsu_axi_arburst;
wire                   lsu_rom_arvalid = lsu_axi_arvalid && lsu_ar_is_rom;
wire                   lsu_rom_arready;

wire [LSU_BUS_TAG-1:0] lsu_rom_rid;
wire [63:0]            lsu_rom_rdata;
wire [1:0]             lsu_rom_rresp;
wire                   lsu_rom_rlast;
wire                   lsu_rom_rvalid;
wire                   lsu_rom_rready  = lsu_axi_rready;

assign s00_arvalid     = lsu_axi_arvalid && !lsu_ar_is_rom;
assign lsu_axi_arready = lsu_ar_is_rom ? lsu_rom_arready : s00_arready;

reg lsu_rd_from_rom_q;
always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        lsu_rd_from_rom_q <= 1'b0;
    end else if (lsu_axi_arvalid && lsu_axi_arready) begin
        lsu_rd_from_rom_q <= lsu_ar_is_rom;
    end
end

wire lsu_sel_rom_r = lsu_rom_rvalid || lsu_rd_from_rom_q;

// LSU feedbacks
assign lsu_axi_awready = s00_awready;
assign lsu_axi_wready  = s00_wready;
assign lsu_axi_bvalid  = s00_bvalid;
assign lsu_axi_bresp   = s00_bresp;
assign lsu_axi_bid     = s00_bid[LSU_BUS_TAG-1:0];
assign lsu_axi_rvalid  = lsu_sel_rom_r ? lsu_rom_rvalid : s00_rvalid;
assign lsu_axi_rid     = lsu_sel_rom_r ? lsu_rom_rid    : s00_rid[LSU_BUS_TAG-1:0];
assign lsu_axi_rdata   = lsu_sel_rom_r ? lsu_rom_rdata  : {s00_rdata, s00_rdata};
assign lsu_axi_rresp   = lsu_sel_rom_r ? lsu_rom_rresp  : s00_rresp;
assign lsu_axi_rlast   = lsu_sel_rom_r ? lsu_rom_rlast  : s00_rlast;

// ===================================================================
// 5. Interrupt Vector Mapping to VeeR Core
// ===================================================================
// VeeR EL2 extintsrc_req has 31 external interrupt lines
wire [31:1] core_interrupts;
assign core_interrupts[1]  = timer_irq_o;   // Line 1: Timer Heartbeat IRQ
assign core_interrupts[2]  = uart_irq_o;    // Line 2: UART RX Data Ready IRQ
assign core_interrupts[3]  = gpio_irq_o;    // Line 3: GPIO Edge Detection IRQ
assign core_interrupts[4]  = dma_done_o;    // Line 4: DMA Transfer Done IRQ
assign core_interrupts[5]  = dma_error_o;   // Line 5: DMA Error IRQ
assign core_interrupts[31:6] = 26'b0;

// ===================================================================
// 6. Memory Interface Instance (VeeR EL2 SRAM requirement)
// ===================================================================
el2_mem_if mem_export_iface ();

// ===================================================================
// 7. VeeR EL2 RISC-V Core Instance
// ===================================================================
el2_veer_wrapper u_veer (
    .clk            (clk),
    .rst_l          (rst_l),
    .dbg_rst_l      (rst_l),
    .rst_vec        (rst_vec),
    .nmi_int        (nmi_int),
    .nmi_vec        (nmi_vec),
    .jtag_id        (jtag_id),

    // Trace
    .trace_rv_i_insn_ip     (),
    .trace_rv_i_address_ip  (),
    .trace_rv_i_valid_ip    (),
    .trace_rv_i_exception_ip(),
    .trace_rv_i_ecause_ip   (),
    .trace_rv_i_interrupt_ip(),
    .trace_rv_i_tval_ip     (),

    // LSU AXI Master (64-bit)
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

    // IFU AXI Master (64-bit)
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

    // SB AXI (tied off)
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

    // DMA AXI Slave (tied off)
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

    // SRAM Interfaces
    .el2_mem_export   (mem_export_iface.veer_sram_src),
    .el2_icache_export(mem_export_iface.veer_icache_src),

    // ECC & Diagnostics
    .iccm_ecc_single_error  (),
    .iccm_ecc_double_error  (),
    .dccm_ecc_single_error  (),
    .dccm_ecc_double_error  (),
    .dccm_write_readback_error(),

    // Interrupts
    .extintsrc_req    (core_interrupts),
    .timer_int        (1'b0),
    .soft_int         (1'b0),
    .core_id          (28'h0),

    // Performance counters
    .dec_tlu_perfcnt1 (),
    .dec_tlu_perfcnt2 (),
    .dec_tlu_perfcnt3 (),

    // DMI
    .dmi_core_enable  (1'b0),
    .dmi_uncore_enable(1'b0),
    .dmi_uncore_en    (),
    .dmi_uncore_wr_en (),
    .dmi_uncore_addr  (),
    .dmi_uncore_wdata (),
    .dmi_uncore_rdata (32'h0),
    .dmi_active       (),

    // Bus Clock Ratio Enables (1:1 with CPU core clk)
    .lsu_bus_clk_en   (1'b1),
    .ifu_bus_clk_en   (1'b1),
    .dbg_bus_clk_en   (1'b1),
    .dma_bus_clk_en   (1'b1),

    // JTAG
    .jtag_tck         (jtag_tck),
    .jtag_tms         (jtag_tms),
    .jtag_tdi         (jtag_tdi),
    .jtag_tdo         (jtag_tdo),
    .jtag_trst_n      (1'b1),

    // MPC Halt/Run Interface
    .mpc_debug_halt_ack     (),
    .mpc_debug_halt_req     (1'b0),
    .mpc_debug_run_ack      (),
    .mpc_debug_run_req      (1'b0),
    .mpc_reset_run_req      (1'b1),             // Start running immediately after reset
    .debug_brkpt_status     (),

    .i_cpu_halt_req         (1'b0),
    .o_cpu_halt_ack         (),
    .o_cpu_halt_status      (),
    .i_cpu_run_req          (1'b0),
    .o_debug_mode_status    (),
    .o_cpu_run_ack          (),

    // Scan
    .scan_mode        (1'b0),
    .mbist_mode       (1'b0)
);

// ===================================================================
// 8. Instruction Boot ROM Stub (VeeR IFU fetches from here)
// ===================================================================
ifu_rom_stub #(
    .ID_WIDTH     (IFU_BUS_TAG),
    .LSU_ID_WIDTH (LSU_BUS_TAG),
    .ROM_WORDS    (ROM_DEPTH),
    .ROM_FILE     (ROM_FILE)
) u_ifu_rom (
    .clk           (clk),
    .rstn          (rstn),

    // Port A: IFU (Instruction Fetch)
    .axi_arid_i    (ifu_axi_arid),
    .axi_araddr_i  (ifu_axi_araddr),
    .axi_arlen_i   (ifu_axi_arlen),
    .axi_arsize_i  (ifu_axi_arsize),
    .axi_arburst_i (ifu_axi_arburst),
    .axi_arvalid_i (ifu_axi_arvalid),
    .axi_arready_o (ifu_axi_arready),

    .axi_rid_o     (ifu_axi_rid),
    .axi_rdata_o   (ifu_axi_rdata),
    .axi_rresp_o   (ifu_axi_rresp),
    .axi_rlast_o   (ifu_axi_rlast),
    .axi_rvalid_o  (ifu_axi_rvalid),
    .axi_rready_i  (ifu_axi_rready),

    // Port B: LSU (Data Load from ROM)
    .lsu_arid_i    (lsu_rom_arid),
    .lsu_araddr_i  (lsu_rom_araddr),
    .lsu_arlen_i   (lsu_rom_arlen),
    .lsu_arsize_i  (lsu_rom_arsize),
    .lsu_arburst_i (lsu_rom_arburst),
    .lsu_arvalid_i (lsu_rom_arvalid),
    .lsu_arready_o (lsu_rom_arready),

    .lsu_rid_o     (lsu_rom_rid),
    .lsu_rdata_o   (lsu_rom_rdata),
    .lsu_rresp_o   (lsu_rom_rresp),
    .lsu_rlast_o   (lsu_rom_rlast),
    .lsu_rvalid_o  (lsu_rom_rvalid),
    .lsu_rready_i  (lsu_rom_rready),

    .axi_awready_o (ifu_axi_awready),
    .axi_wready_o  (ifu_axi_wready),
    .axi_bvalid_o  (ifu_axi_bvalid),
    .axi_bresp_o   (ifu_axi_bresp),
    .axi_bid_o     (ifu_axi_bid)
);

// ===================================================================
// 9. Interconnect Subsystem + All 6 IPs + DMA + SRAM
// ===================================================================
axi_interconnect_uart_top #(
    .DATA_WIDTH (IC_DATA_WIDTH),
    .ADDR_WIDTH (IC_ADDR_WIDTH),
    .ID_WIDTH   (IC_ID_WIDTH)
) u_periph_top (
    .clk              (clk),
    .rstn             (rstn),

    // CPU LSU Master port (S00)
    .s00_axi_awid     (s00_awid),
    .s00_axi_awaddr   (s00_awaddr),
    .s00_axi_awlen    (s00_awlen),
    .s00_axi_awsize   (s00_awsize),
    .s00_axi_awburst  (s00_awburst),
    .s00_axi_awlock   (s00_awlock),
    .s00_axi_awcache  (s00_awcache),
    .s00_axi_awprot   (s00_awprot),
    .s00_axi_awqos    (s00_awqos),
    .s00_axi_awvalid  (s00_awvalid),
    .s00_axi_awready  (s00_awready),

    .s00_axi_wdata    (s00_wdata),
    .s00_axi_wstrb    (s00_wstrb),
    .s00_axi_wlast    (s00_wlast),
    .s00_axi_wvalid   (s00_wvalid),
    .s00_axi_wready   (s00_wready),

    .s00_axi_bid      (s00_bid),
    .s00_axi_bresp    (s00_bresp),
    .s00_axi_bvalid   (s00_bvalid),
    .s00_axi_bready   (s00_bready),

    .s00_axi_arid     (s00_arid),
    .s00_axi_araddr   (s00_araddr),
    .s00_axi_arlen    (s00_arlen),
    .s00_axi_arsize   (s00_arsize),
    .s00_axi_arburst  (s00_arburst),
    .s00_axi_arlock   (s00_arlock),
    .s00_axi_arcache  (s00_arcache),
    .s00_axi_arprot   (s00_arprot),
    .s00_axi_arqos    (s00_arqos),
    .s00_axi_arvalid  (s00_arvalid),
    .s00_axi_arready  (s00_arready),

    .s00_axi_rid      (s00_rid),
    .s00_axi_rdata    (s00_rdata),
    .s00_axi_rresp    (s00_rresp),
    .s00_axi_rlast    (s00_rlast),
    .s00_axi_rvalid   (s00_rvalid),
    .s00_axi_rready   (s00_rready),

    // UART External Pins
    .uart_rx_i        (uart_rx_i),
    .uart_tx_o        (uart_tx_o),
    .uart_irq_o       (uart_irq_o),

    // SPI External Pins
    .spi_clk_o        (spi_clk_o),
    .spi_mosi_o       (spi_mosi_o),
    .spi_miso_i       (spi_miso_i),
    .spi_cs_n_o       (spi_cs_n_o),

    // GPIO External Pins
    .gpio_in_i        (gpio_in_i),
    .gpio_out_o       (gpio_out_o),
    .gpio_oe_o        (gpio_oe_o),
    .gpio_irq_o       (gpio_irq_o),

    // Timer External
    .timer_ctr_in_i   (timer_ctr_in_i),
    .timer_irq_o      (timer_irq_o),

    // DMA Status
    .dma_done_o       (dma_done_o),
    .dma_error_o      (dma_error_o)
);

endmodule
`default_nettype wire
