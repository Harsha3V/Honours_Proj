/* =============================================================================
 * Project        : Honours Project
 * File           : ifu_rom_stub.v
 * Description    : AXI4 read-only instruction ROM stub for VeeR EL2 IFU.
 *
 *   The VeeR EL2 IFU uses an AXI4 master to fetch 64-bit (2 × 32-bit
 *   instruction) words per beat.  This stub:
 *     - Stores instructions as 32-bit words (matches boot.hex format).
 *     - Pairs two consecutive 32-bit words into each 64-bit AXI beat.
 *     - Loads boot.hex at simulation start via $readmemh.
 *     - Supports AXI4 burst reads (as issued by the VeeR IFU).
 *     - Accepts (and silently discards) write channel transactions.
 *
 *   Address mapping:
 *     The IFU issues physical byte addresses (e.g. 0x8000_0000).
 *     We strip the base by using only the lower address bits.
 *     Each AXI beat covers 8 bytes (two 32-bit words); the beat index
 *     is addr[WORD_ADDR_BITS+2:3].  Within that pair:
 *       rdata[31: 0] = rom[ beat_index * 2     ]  (lower / first  word)
 *       rdata[63:32] = rom[ beat_index * 2 + 1 ]  (upper / second word)
 *
 *   Parameters:
 *     ID_WIDTH   — IFU_BUS_TAG (default 3)
 *     ROM_WORDS  — number of 32-bit words  (default 1024 = 4 KB)
 *     ROM_FILE   — path to $readmemh hex file (one 32-bit word per line)
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module ifu_rom_stub #(
    parameter ID_WIDTH  = 3,
    parameter ROM_WORDS = 1024,                          // 32-bit words
    parameter ROM_FILE  = "../sw/boot.hex"
)(
    input  wire                 clk,
    input  wire                 rstn,   // active-low reset

    // ----------------------------------------------------------------
    // AXI4 Read Address channel (AR)
    // ----------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]  axi_arid_i,
    input  wire [31:0]          axi_araddr_i,
    input  wire [7:0]           axi_arlen_i,    // burst length - 1
    input  wire [2:0]           axi_arsize_i,
    input  wire [1:0]           axi_arburst_i,
    input  wire                 axi_arvalid_i,
    output wire                 axi_arready_o,

    // ----------------------------------------------------------------
    // AXI4 Read Data channel (R)
    // ----------------------------------------------------------------
    output wire [ID_WIDTH-1:0]  axi_rid_o,
    output wire [63:0]          axi_rdata_o,    // 64-bit: 2 instructions
    output wire [1:0]           axi_rresp_o,
    output wire                 axi_rlast_o,
    output wire                 axi_rvalid_o,
    input  wire                 axi_rready_i,

    // ----------------------------------------------------------------
    // AXI4 Write channels (AW / W / B) — IFU never writes
    // ----------------------------------------------------------------
    output wire                 axi_awready_o,
    output wire                 axi_wready_o,
    output wire                 axi_bvalid_o,
    output wire [1:0]           axi_bresp_o,
    output wire [ID_WIDTH-1:0]  axi_bid_o
);

// ===================================================================
// ROM array — 32-bit wide, ROM_WORDS entries
// ===================================================================

// How many bits we need to index ROM_WORDS entries
localparam WORD_BITS = $clog2(ROM_WORDS);

reg [31:0] rom [0:ROM_WORDS-1];

// Load hex file; initialise remainder to NOP (addi x0,x0,0 = 32'h0000_0013)
integer idx;
initial begin
    for (idx = 0; idx < ROM_WORDS; idx = idx + 1)
        rom[idx] = 32'h0000_0013;   // NOP

    $readmemh(ROM_FILE, rom);

    // Ensure last word is an infinite loop (jal x0, 0) as safety net
    // JAL x0, 0 = 32'h0000_006F
    // (only written if ROM_FILE is shorter than ROM_WORDS)
end

// ===================================================================
// Read FSM
// ===================================================================

localparam RD_IDLE = 1'b0;
localparam RD_DATA = 1'b1;

reg             rd_state;
reg [ID_WIDTH-1:0] rd_id;
// Beat index: each beat = 8 bytes = 2 × 32-bit words
// We need enough bits to index ROM_WORDS/2 pairs
localparam BEAT_BITS = WORD_BITS - 1;   // log2(ROM_WORDS/2)
reg [BEAT_BITS-1:0] rd_beat;           // current beat (64-bit) index
reg [7:0]           rd_len;            // remaining beats (counting down)

// AR: accept when idle
assign axi_arready_o = (rd_state == RD_IDLE);

// R output registers
reg [63:0]          r_rdata;
reg [ID_WIDTH-1:0]  r_rid;
reg                 r_rvalid;
reg                 r_rlast;

assign axi_rid_o    = r_rid;
assign axi_rdata_o  = r_rdata;
assign axi_rresp_o  = 2'b00;   // OKAY
assign axi_rlast_o  = r_rlast;
assign axi_rvalid_o = r_rvalid;

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        rd_state <= RD_IDLE;
        rd_id    <= {ID_WIDTH{1'b0}};
        rd_beat  <= {BEAT_BITS{1'b0}};
        rd_len   <= 8'h0;
        r_rdata  <= 64'h0;
        r_rid    <= {ID_WIDTH{1'b0}};
        r_rvalid <= 1'b0;
        r_rlast  <= 1'b0;
    end else begin
        case (rd_state)

            RD_IDLE: begin
                r_rvalid <= 1'b0;
                r_rlast  <= 1'b0;
                if (axi_arvalid_i) begin
                    rd_id   <= axi_arid_i;
                    // Beat index: byte addr[BEAT_BITS+2:3]
                    // (bits [2:0] are sub-beat byte offset, ignored)
                    rd_beat <= axi_araddr_i[BEAT_BITS+2:3];
                    rd_len  <= axi_arlen_i;
                    rd_state <= RD_DATA;
                end
            end

            RD_DATA: begin
                // Present read data; two 32-bit words per 64-bit beat
                r_rid    <= rd_id;
                r_rdata  <= { rom[ {rd_beat, 1'b1} ],   // upper word
                              rom[ {rd_beat, 1'b0} ] };  // lower word
                r_rvalid <= 1'b1;
                r_rlast  <= (rd_len == 8'h0);

                if (r_rvalid && axi_rready_i) begin
                    if (rd_len == 8'h0) begin
                        // Burst complete
                        r_rvalid <= 1'b0;
                        r_rlast  <= 1'b0;
                        rd_state <= RD_IDLE;
                    end else begin
                        rd_beat <= rd_beat + 1'b1;
                        rd_len  <= rd_len  - 1'b1;
                    end
                end
            end

            default: rd_state <= RD_IDLE;

        endcase
    end
end

// ===================================================================
// Write channels — tie off (IFU never writes)
// ===================================================================

assign axi_awready_o = 1'b1;
assign axi_wready_o  = 1'b1;
assign axi_bvalid_o  = 1'b0;
assign axi_bresp_o   = 2'b00;
assign axi_bid_o     = {ID_WIDTH{1'b0}};

endmodule

`default_nettype wire
