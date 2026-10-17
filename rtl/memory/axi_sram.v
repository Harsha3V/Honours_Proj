/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : axi_sram.v
 * Description    : Synchronous AXI4 On-Chip SRAM (64 KB).
 *
 * Mapped to M06 slot on the AXI Interconnect (0x0600_0000 - 0x0600_FFFF).
 * Accessible by both Master 0 (VeeR EL2 CPU LSU) and Master 1 (DMA Controller).
 * Used as packet staging buffer for UART frames, AES payload, and SPI transmission.
 *
 * Features:
 *   - 32-bit data width, 8-bit ID pass-through
 *   - Byte-level write strobes (wstrb[3:0])
 *   - Burst support (INCR and FIXED)
 *   - Single-cycle memory access
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module axi_sram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter STRB_WIDTH = DATA_WIDTH / 8,
    parameter DEPTH      = 16384   // 16384 words = 64 KB
)(
    input  wire                   clk,
    input  wire                   rstn,

    // ----------------------------------------------------------------
    // AXI4 Write Address Channel (AW)
    // ----------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire [3:0]             s_axi_awqos,
    input  wire [3:0]             s_axi_awregion,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // ----------------------------------------------------------------
    // AXI4 Write Data Channel (W)
    // ----------------------------------------------------------------
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // ----------------------------------------------------------------
    // AXI4 Write Response Channel (B)
    // ----------------------------------------------------------------
    output reg  [ID_WIDTH-1:0]    s_axi_bid,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // ----------------------------------------------------------------
    // AXI4 Read Address Channel (AR)
    // ----------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire [3:0]             s_axi_arqos,
    input  wire [3:0]             s_axi_arregion,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // ----------------------------------------------------------------
    // AXI4 Read Data Channel (R)
    // ----------------------------------------------------------------
    output reg  [ID_WIDTH-1:0]    s_axi_rid,
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rlast,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    localparam ADDR_BITS = $clog2(DEPTH);

    // 64 KB memory array (16384 x 32 bits)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ================================================================
    // Write State Machine
    // ================================================================
    localparam WR_IDLE = 2'd0;
    localparam WR_DATA = 2'd1;
    localparam WR_RESP = 2'd2;

    reg [1:0]           wr_state;
    reg [ADDR_BITS-1:0] wr_addr_cnt;
    reg [7:0]           wr_len_cnt;
    reg [1:0]           wr_burst_reg;
    reg [ID_WIDTH-1:0]  wr_id_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_state      <= WR_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            wr_addr_cnt   <= {ADDR_BITS{1'b0}};
            wr_len_cnt    <= 8'd0;
            wr_burst_reg  <= 2'b01;
            wr_id_reg     <= {ID_WIDTH{1'b0}};
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    if (s_axi_awvalid && s_axi_awready) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b1;
                        wr_addr_cnt   <= s_axi_awaddr[ADDR_BITS+1:2];
                        wr_len_cnt    <= s_axi_awlen;
                        wr_burst_reg  <= s_axi_awburst;
                        wr_id_reg     <= s_axi_awid;
                        wr_state      <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        // Byte-strobe writes
                        if (s_axi_wstrb[0]) mem[wr_addr_cnt][ 7: 0] <= s_axi_wdata[ 7: 0];
                        if (s_axi_wstrb[1]) mem[wr_addr_cnt][15: 8] <= s_axi_wdata[15: 8];
                        if (s_axi_wstrb[2]) mem[wr_addr_cnt][23:16] <= s_axi_wdata[23:16];
                        if (s_axi_wstrb[3]) mem[wr_addr_cnt][31:24] <= s_axi_wdata[31:24];

                        if (wr_burst_reg == 2'b01) // INCR
                            wr_addr_cnt <= wr_addr_cnt + 1'b1;

                        if (s_axi_wlast || wr_len_cnt == 8'd0) begin
                            s_axi_wready <= 1'b0;
                            s_axi_bvalid <= 1'b1;
                            s_axi_bresp  <= 2'b00;
                            s_axi_bid    <= wr_id_reg;
                            wr_state     <= WR_RESP;
                        end else begin
                            wr_len_cnt   <= wr_len_cnt - 1'b1;
                        end
                    end
                end

                WR_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        wr_state      <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // ================================================================
    // Read State Machine
    // ================================================================
    localparam RD_IDLE = 2'd0;
    localparam RD_PIPE = 2'd1;
    localparam RD_DATA = 2'd2;

    reg [1:0]           rd_state;
    reg [ADDR_BITS-1:0] rd_addr_cnt;
    reg [7:0]           rd_len_cnt;
    reg [1:0]           rd_burst_reg;
    reg [ID_WIDTH-1:0]  rd_id_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            rd_addr_cnt   <= {ADDR_BITS{1'b0}};
            rd_len_cnt    <= 8'd0;
            rd_burst_reg  <= 2'b01;
            rd_id_reg     <= {ID_WIDTH{1'b0}};
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;
                        rd_addr_cnt   <= s_axi_araddr[ADDR_BITS+1:2];
                        rd_len_cnt    <= s_axi_arlen;
                        rd_burst_reg  <= s_axi_arburst;
                        rd_id_reg     <= s_axi_arid;
                        rd_state      <= RD_PIPE;
                    end
                end

                RD_PIPE: begin
                    // 1 cycle pipeline for synchronous memory read
                    s_axi_rdata  <= mem[rd_addr_cnt];
                    s_axi_rid    <= rd_id_reg;
                    s_axi_rresp  <= 2'b00;
                    s_axi_rlast  <= (rd_len_cnt == 8'd0);
                    s_axi_rvalid <= 1'b1;

                    if (rd_burst_reg == 2'b01)
                        rd_addr_cnt <= rd_addr_cnt + 1'b1;

                    rd_state <= RD_DATA;
                end

                RD_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;
                            s_axi_arready <= 1'b1;
                            rd_state      <= RD_IDLE;
                        end else begin
                            rd_len_cnt   <= rd_len_cnt - 1'b1;
                            s_axi_rdata  <= mem[rd_addr_cnt];
                            s_axi_rlast  <= (rd_len_cnt == 8'd1);
                            s_axi_rvalid <= 1'b1;
                            if (rd_burst_reg == 2'b01)
                                rd_addr_cnt <= rd_addr_cnt + 1'b1;
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
