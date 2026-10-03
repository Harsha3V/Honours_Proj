/* =============================================================================
 * Project        : Honours Project
 * File           : spi_axi_top.v
 * Description    : AXI4-Lite wrapper for SPI_Master_With_Single_CS
 *
 * Connects to AXI Interconnect at Slave M02 (0x0200_0000).
 *
 * Register Map (offsets from 0x0200_0000):
 * ┌────────┬────────────┬─────┬────────────────────────────────────────────┐
 * │ Offset │ Name       │ R/W │ Description                                │
 * ├────────┼────────────┼─────┼────────────────────────────────────────────┤
 * │ 0x00   │ TX_DATA    │ WO  │ [7:0]=byte to send. Write triggers TX      │
 * │ 0x04   │ RX_DATA    │ RO  │ [7:0]=last received byte                   │
 * │ 0x08   │ STATUS     │ RO  │ bit0=TX_READY, bit1=RX_DV                  │
 * │ 0x0C   │ TX_COUNT   │ RW  │ number of bytes in this CS transaction     │
 * └────────┴────────────┴─────┴────────────────────────────────────────────┘
 *
 * SPI external pins: spi_clk, spi_mosi, spi_miso, spi_cs_n
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module spi_axi_top #(
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_DATA_WIDTH    = 32,
    parameter AXI_ID_WIDTH      = 8,
    parameter AXI_STRB_WIDTH    = AXI_DATA_WIDTH/8,
    // SPI parameters
    parameter SPI_MODE          = 0,
    parameter CLKS_PER_HALF_BIT = 2,
    parameter MAX_BYTES_PER_CS  = 2,
    parameter CS_INACTIVE_CLKS  = 1
)(
    input  wire                      clk,
    input  wire                      rstn,

    // ----------------------------------------------------------------
    // AXI4-Lite Slave Interface
    // ----------------------------------------------------------------
    input  wire [AXI_ID_WIDTH-1:0]   s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [AXI_STRB_WIDTH-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [AXI_ID_WIDTH-1:0]   s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [AXI_ID_WIDTH-1:0]   s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [AXI_ID_WIDTH-1:0]   s_axi_rid,
    output reg  [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // ----------------------------------------------------------------
    // SPI physical pins
    // ----------------------------------------------------------------
    output wire                      spi_clk,
    output wire                      spi_mosi,
    input  wire                      spi_miso,
    output wire                      spi_cs_n
);

// ====================================================================
// Register addresses (5-bit offset)
// ====================================================================
localparam TX_DATA_ADDR  = 5'h00;
localparam RX_DATA_ADDR  = 5'h04;
localparam STATUS_ADDR   = 5'h08;
localparam TX_COUNT_ADDR = 5'h0C;

// ====================================================================
// Internal registers
// ====================================================================
reg  [7:0]  tx_data_reg;
reg  [7:0]  rx_data_reg;
reg         spi_tx_dv;      // one-cycle pulse to SPI master
reg  [$clog2(MAX_BYTES_PER_CS+1)-1:0] tx_count_reg;

wire        spi_tx_ready;
wire        spi_rx_dv;
wire [7:0]  spi_rx_byte;
wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] spi_rx_count;

// Latch received byte
always @(posedge clk or negedge rstn) begin
    if (!rstn)          rx_data_reg <= 8'h0;
    else if (spi_rx_dv) rx_data_reg <= spi_rx_byte;
end

// ====================================================================
// SPI Master instance
// ====================================================================
SPI_Master_With_Single_CS #(
    .SPI_MODE          (SPI_MODE),
    .CLKS_PER_HALF_BIT (CLKS_PER_HALF_BIT),
    .MAX_BYTES_PER_CS  (MAX_BYTES_PER_CS),
    .CS_INACTIVE_CLKS  (CS_INACTIVE_CLKS)
) u_spi (
    .i_Rst_L    (rstn),
    .i_Clk      (clk),
    .i_TX_Count (tx_count_reg),
    .i_TX_Byte  (tx_data_reg),
    .i_TX_DV    (spi_tx_dv),
    .o_TX_Ready (spi_tx_ready),
    .o_RX_Count (spi_rx_count),
    .o_RX_DV    (spi_rx_dv),
    .o_RX_Byte  (spi_rx_byte),
    .o_SPI_Clk  (spi_clk),
    .i_SPI_MISO (spi_miso),
    .o_SPI_MOSI (spi_mosi),
    .o_SPI_CS_n (spi_cs_n)
);

// ====================================================================
// AXI4-Lite Write Path
// ====================================================================
reg [AXI_ADDR_WIDTH-1:0] wr_addr;
reg [AXI_ID_WIDTH-1:0]   wr_id;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= 2'b0;
        s_axi_bid     <= {AXI_ID_WIDTH{1'b0}};
        wr_addr       <= {AXI_ADDR_WIDTH{1'b0}};
        wr_id         <= {AXI_ID_WIDTH{1'b0}};
        tx_data_reg   <= 8'h0;
        tx_count_reg  <= {$clog2(MAX_BYTES_PER_CS+1){1'b0}};
        spi_tx_dv     <= 1'b0;
    end else begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        spi_tx_dv     <= 1'b0;  // default: clear every cycle

        if (s_axi_awvalid && !s_axi_awready) begin
            s_axi_awready <= 1'b1;
            wr_addr       <= s_axi_awaddr;
            wr_id         <= s_axi_awid;
        end

        if (s_axi_wvalid && !s_axi_wready) begin
            s_axi_wready <= 1'b1;
            case (wr_addr[4:0])
                TX_DATA_ADDR: begin
                    if (s_axi_wstrb[0]) begin
                        tx_data_reg <= s_axi_wdata[7:0];
                        spi_tx_dv   <= 1'b1;  // trigger SPI transfer
                    end
                end
                TX_COUNT_ADDR: begin
                    if (s_axi_wstrb[0])
                        tx_count_reg <= s_axi_wdata[$clog2(MAX_BYTES_PER_CS+1)-1:0];
                end
                default: ;
            endcase

            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
            s_axi_bid    <= wr_id;
        end

        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
    end
end

// ====================================================================
// AXI4-Lite Read Path
// ====================================================================
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= 32'h0;
        s_axi_rresp   <= 2'b0;
        s_axi_rid     <= {AXI_ID_WIDTH{1'b0}};
    end else begin
        s_axi_arready <= 1'b0;

        if (s_axi_arvalid && !s_axi_arready) begin
            s_axi_arready <= 1'b1;
            s_axi_rid     <= s_axi_arid;
            s_axi_rresp   <= 2'b00;
            s_axi_rvalid  <= 1'b1;

            case (s_axi_araddr[4:0])
                TX_DATA_ADDR:  s_axi_rdata <= {24'b0, tx_data_reg};
                RX_DATA_ADDR:  s_axi_rdata <= {24'b0, rx_data_reg};
                STATUS_ADDR:   s_axi_rdata <= {30'b0, spi_rx_dv, spi_tx_ready};
                TX_COUNT_ADDR: s_axi_rdata <= {{(32-$clog2(MAX_BYTES_PER_CS+1)){1'b0}},
                                               tx_count_reg};
                default:       s_axi_rdata <= 32'hDEAD_BEEF;
            endcase
        end

        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;
    end
end

endmodule

`default_nettype wire
