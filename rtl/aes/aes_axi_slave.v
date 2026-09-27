`timescale 1ns/1ps

module AES_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
)(
    input  wire                         S_AXI_ACLK,
    input  wire                         S_AXI_ARESETN,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                         S_AXI_AWVALID,
    output wire                         S_AXI_AWREADY,

    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                         S_AXI_WVALID,
    output wire                         S_AXI_WREADY,

    output wire [1:0]                   S_AXI_BRESP,
    output wire                         S_AXI_BVALID,
    input  wire                         S_AXI_BREADY,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                         S_AXI_ARVALID,
    output wire                         S_AXI_ARREADY,

    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                   S_AXI_RRESP,
    output wire                         S_AXI_RVALID,
    input  wire                         S_AXI_RREADY
);

    // ============================================================
    // Register Map
    // ============================================================
    //
    // AES CIPHER
    //
    // 0x00 : CIPHER_CSR
    //        [31:16] CONTROL
    //          bit16 = START
    //        [15:0] STATUS
    //          bit0  = DONE
    //          bit1  = BUSY
    //
    // 0x04 : CIPHER_KEY0  [127:96]
    // 0x08 : CIPHER_KEY1  [95:64]
    // 0x0C : CIPHER_KEY2  [63:32]
    // 0x10 : CIPHER_KEY3  [31:0]
    //
    // 0x14 : CIPHER_TEXTIN0 [127:96]
    // 0x18 : CIPHER_TEXTIN1 [95:64]
    // 0x1C : CIPHER_TEXTIN2 [63:32]
    // 0x20 : CIPHER_TEXTIN3 [31:0]
    //
    // 0x24 : CIPHER_TEXTOUT0 [127:96]
    // 0x28 : CIPHER_TEXTOUT1 [95:64]
    // 0x2C : CIPHER_TEXTOUT2 [63:32]
    // 0x30 : CIPHER_TEXTOUT3 [31:0]
    //
    //
    // AES INVERSE CIPHER
    //
    // 0x40 : INV_CSR
    //        [31:16] CONTROL
    //          bit16 = KEY_LOAD
    //          bit17 = START
    //        [15:0] STATUS
    //          bit0  = DONE
    //          bit1  = KDONE
    //          bit2  = BUSY
    //
    // 0x44 : INV_KEY0 [127:96]
    // 0x48 : INV_KEY1 [95:64]
    // 0x4C : INV_KEY2 [63:32]
    // 0x50 : INV_KEY3 [31:0]
    //
    // 0x54 : INV_TEXTIN0 [127:96]
    // 0x58 : INV_TEXTIN1 [95:64]
    // 0x5C : INV_TEXTIN2 [63:32]
    // 0x60 : INV_TEXTIN3 [31:0]
    //
    // 0x64 : INV_TEXTOUT0 [127:96]
    // 0x68 : INV_TEXTOUT1 [95:64]
    // 0x6C : INV_TEXTOUT2 [63:32]
    // 0x70 : INV_TEXTOUT3 [31:0]
    //
    // ============================================================


    // ============================================================
    // AXI INTERNAL SIGNALS
    // ============================================================

    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;

    reg arready_reg;
    reg rvalid_reg;

    reg [1:0] bresp_reg;
    reg [1:0] rresp_reg;
    reg [31:0] rdata_reg;

    assign S_AXI_AWREADY = awready_reg;
    assign S_AXI_WREADY  = wready_reg;
    assign S_AXI_BVALID  = bvalid_reg;
    assign S_AXI_BRESP   = bresp_reg;

    assign S_AXI_ARREADY = arready_reg;
    assign S_AXI_RVALID  = rvalid_reg;
    assign S_AXI_RDATA   = rdata_reg;
    assign S_AXI_RRESP   = rresp_reg;


    // ============================================================
    // AES CIPHER REGISTERS
    // ============================================================

    reg [31:0] cipher_key0;
    reg [31:0] cipher_key1;
    reg [31:0] cipher_key2;
    reg [31:0] cipher_key3;

    reg [31:0] cipher_tin0;
    reg [31:0] cipher_tin1;
    reg [31:0] cipher_tin2;
    reg [31:0] cipher_tin3;

    reg [31:0] cipher_tout0;
    reg [31:0] cipher_tout1;
    reg [31:0] cipher_tout2;
    reg [31:0] cipher_tout3;


    // ============================================================
    // AES INVERSE CIPHER REGISTERS
    // ============================================================

    reg [31:0] inv_key0;
    reg [31:0] inv_key1;
    reg [31:0] inv_key2;
    reg [31:0] inv_key3;

    reg [31:0] inv_tin0;
    reg [31:0] inv_tin1;
    reg [31:0] inv_tin2;
    reg [31:0] inv_tin3;

    reg [31:0] inv_tout0;
    reg [31:0] inv_tout1;
    reg [31:0] inv_tout2;
    reg [31:0] inv_tout3;


    // ============================================================
    // CONTROL PULSES
    // ============================================================

    reg cipher_start_reg;

    reg inv_key_load_reg;
    reg inv_start_reg;


    // ============================================================
    // STATUS
    // ============================================================

    reg cipher_done_reg;
    reg cipher_busy_reg;

    reg inv_done_reg;
    reg inv_kdone_reg;
    reg inv_busy_reg;
    reg [3:0] inv_kcnt;   // mirrors internal kcnt of aes_inv_cipher_top


    // ============================================================
    // AES CORE WIRES
    // ============================================================

    wire [127:0] cipher_key;
    wire [127:0] cipher_text_in;
    wire [127:0] cipher_text_out;

    wire cipher_done;

    wire [127:0] inv_key;
    wire [127:0] inv_text_in;
    wire [127:0] inv_text_out;

    wire inv_done;


    assign cipher_key =
        {cipher_key0,
         cipher_key1,
         cipher_key2,
         cipher_key3};

    assign cipher_text_in =
        {cipher_tin0,
         cipher_tin1,
         cipher_tin2,
         cipher_tin3};


    assign inv_key =
        {inv_key0,
         inv_key1,
         inv_key2,
         inv_key3};

    assign inv_text_in =
        {inv_tin0,
         inv_tin1,
         inv_tin2,
         inv_tin3};


    // ============================================================
    // AES CIPHER CORE
    // ============================================================

    aes_cipher_top u_cipher (
        .clk      (S_AXI_ACLK),
        .rst      (S_AXI_ARESETN),   // active-low: aresetn=0 resets, aresetn=1 runs
        .ld       (cipher_start_reg),
        .done     (cipher_done),
        .key      (cipher_key),
        .text_in  (cipher_text_in),
        .text_out (cipher_text_out)
    );


    // ============================================================
    // AES INVERSE CIPHER CORE
    // ============================================================

    aes_inv_cipher_top u_inv_cipher (
        .clk      (S_AXI_ACLK),
        .rst      (S_AXI_ARESETN),   // active-low: aresetn=0 resets, aresetn=1 runs
        .kld      (inv_key_load_reg),
        .ld       (inv_start_reg),
        .done     (inv_done),
        .key      (inv_key),
        .text_in  (inv_text_in),
        .text_out (inv_text_out)
    );


    // ============================================================
    // AXI WRITE ADDRESS REGISTER
    // ============================================================

    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg awaddr_valid;

    // ============================================================
    // AXI WRITE DATA REGISTER
    // ============================================================

    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;
    reg wdata_valid;


    // ============================================================
    // AXI WRITE LOGIC
    // ============================================================

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            bvalid_reg  <= 1'b0;

            awaddr_reg  <= 7'd0;
            awaddr_valid <= 1'b0;

            wdata_reg   <= 32'd0;
            wstrb_reg   <= 4'd0;
            wdata_valid <= 1'b0;

            bresp_reg   <= 2'b00;

            cipher_key0 <= 32'd0;
            cipher_key1 <= 32'd0;
            cipher_key2 <= 32'd0;
            cipher_key3 <= 32'd0;

            cipher_tin0 <= 32'd0;
            cipher_tin1 <= 32'd0;
            cipher_tin2 <= 32'd0;
            cipher_tin3 <= 32'd0;

            inv_key0 <= 32'd0;
            inv_key1 <= 32'd0;
            inv_key2 <= 32'd0;
            inv_key3 <= 32'd0;

            inv_tin0 <= 32'd0;
            inv_tin1 <= 32'd0;
            inv_tin2 <= 32'd0;
            inv_tin3 <= 32'd0;

            cipher_start_reg <= 1'b0;

            inv_key_load_reg <= 1'b0;
            inv_start_reg    <= 1'b0;

        end
        else begin

            // Default pulse signals
            cipher_start_reg <= 1'b0;
            inv_key_load_reg <= 1'b0;
            inv_start_reg    <= 1'b0;


            // ----------------------------------------------------
            // Accept AXI WRITE ADDRESS
            // ----------------------------------------------------

            if (!awaddr_valid && S_AXI_AWVALID) begin

                awaddr_reg  <= S_AXI_AWADDR;
                awaddr_valid <= 1'b1;
                awready_reg <= 1'b1;

            end
            else begin

                awready_reg <= 1'b0;

            end


            // ----------------------------------------------------
            // Accept AXI WRITE DATA
            // ----------------------------------------------------

            if (!wdata_valid && S_AXI_WVALID) begin

                wdata_reg   <= S_AXI_WDATA;
                wstrb_reg   <= S_AXI_WSTRB;
                wdata_valid <= 1'b1;
                wready_reg  <= 1'b1;

            end
            else begin

                wready_reg <= 1'b0;

            end


            // ----------------------------------------------------
            // Execute WRITE when both address and data exist
            // ----------------------------------------------------

            if (awaddr_valid && wdata_valid) begin

                case (awaddr_reg)

                    // --------------------------------------------
                    // Cipher Key
                    // --------------------------------------------

                    7'h04:
                        cipher_key0 <= wdata_reg;

                    7'h08:
                        cipher_key1 <= wdata_reg;

                    7'h0C:
                        cipher_key2 <= wdata_reg;

                    7'h10:
                        cipher_key3 <= wdata_reg;


                    // --------------------------------------------
                    // Cipher Plaintext
                    // --------------------------------------------

                    7'h14:
                        cipher_tin0 <= wdata_reg;

                    7'h18:
                        cipher_tin1 <= wdata_reg;

                    7'h1C:
                        cipher_tin2 <= wdata_reg;

                    7'h20:
                        cipher_tin3 <= wdata_reg;


                    // --------------------------------------------
                    // Cipher CSR
                    // --------------------------------------------

                    7'h00: begin

                        if (wdata_reg[16])
                            cipher_start_reg <= 1'b1;

                    end


                    // --------------------------------------------
                    // Inverse Key
                    // --------------------------------------------

                    7'h44:
                        inv_key0 <= wdata_reg;

                    7'h48:
                        inv_key1 <= wdata_reg;

                    7'h4C:
                        inv_key2 <= wdata_reg;

                    7'h50:
                        inv_key3 <= wdata_reg;


                    // --------------------------------------------
                    // Inverse Cipher Input
                    // --------------------------------------------

                    7'h54:
                        inv_tin0 <= wdata_reg;

                    7'h58:
                        inv_tin1 <= wdata_reg;

                    7'h5C:
                        inv_tin2 <= wdata_reg;

                    7'h60:
                        inv_tin3 <= wdata_reg;


                    // --------------------------------------------
                    // Inverse CSR
                    // --------------------------------------------

                    7'h40: begin

                        if (wdata_reg[16])
                            inv_key_load_reg <= 1'b1;

                        if (wdata_reg[17])
                            inv_start_reg <= 1'b1;

                    end


                    // --------------------------------------------
                    // Read-only / undefined registers
                    // --------------------------------------------

                    default: begin
                        // Ignore writes
                    end

                endcase


                awaddr_valid <= 1'b0;
                wdata_valid  <= 1'b0;

                bvalid_reg   <= 1'b1;
                bresp_reg    <= 2'b00;

            end


            // ----------------------------------------------------
            // AXI WRITE RESPONSE
            // ----------------------------------------------------

            if (bvalid_reg && S_AXI_BREADY)
                bvalid_reg <= 1'b0;

        end

    end


    // ============================================================
    // AES OUTPUT / STATUS UPDATE
    // ============================================================

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            cipher_tout0 <= 32'd0;
            cipher_tout1 <= 32'd0;
            cipher_tout2 <= 32'd0;
            cipher_tout3 <= 32'd0;

            cipher_done_reg <= 1'b0;
            cipher_busy_reg <= 1'b0;

            inv_tout0 <= 32'd0;
            inv_tout1 <= 32'd0;
            inv_tout2 <= 32'd0;
            inv_tout3 <= 32'd0;

            inv_done_reg  <= 1'b0;
            inv_kdone_reg <= 1'b0;
            inv_busy_reg  <= 1'b0;
            inv_kcnt      <= 4'h0;

        end
        else begin

            // ----------------------------------------------------
            // Cipher START
            // ----------------------------------------------------

            if (cipher_start_reg) begin

                cipher_busy_reg <= 1'b1;
                cipher_done_reg <= 1'b0;

            end


            // ----------------------------------------------------
            // Cipher DONE
            // ----------------------------------------------------

            if (cipher_done) begin

                cipher_tout0 <= cipher_text_out[127:96];
                cipher_tout1 <= cipher_text_out[95:64];
                cipher_tout2 <= cipher_text_out[63:32];
                cipher_tout3 <= cipher_text_out[31:0];

                cipher_busy_reg <= 1'b0;
                cipher_done_reg <= 1'b1;

            end


            // ----------------------------------------------------
            // Inverse KEY LOAD  — start 11-cycle countdown
            // ----------------------------------------------------

            if (inv_key_load_reg) begin

                inv_kdone_reg <= 1'b0;
                inv_busy_reg  <= 1'b1;
                inv_kcnt      <= 4'hB;  // 11 cycles to complete key expansion

            end
            else if (|inv_kcnt) begin

                inv_kcnt <= inv_kcnt - 4'h1;

                if (inv_kcnt == 4'h1) begin
                    inv_kdone_reg <= 1'b1;  // key expansion done
                    inv_busy_reg  <= 1'b0;
                end

            end


            // ----------------------------------------------------
            // START inverse cipher
            // ----------------------------------------------------

            if (inv_start_reg) begin

                inv_busy_reg <= 1'b1;
                inv_done_reg <= 1'b0;

            end


            // ----------------------------------------------------
            // Inverse DONE
            // ----------------------------------------------------

            if (inv_done) begin

                inv_tout0 <= inv_text_out[127:96];
                inv_tout1 <= inv_text_out[95:64];
                inv_tout2 <= inv_text_out[63:32];
                inv_tout3 <= inv_text_out[31:0];

                inv_busy_reg <= 1'b0;
                inv_done_reg <= 1'b1;

            end

        end

    end


    // ============================================================
    // AXI READ LOGIC
    // ============================================================

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            arready_reg <= 1'b0;
            rvalid_reg  <= 1'b0;
            rdata_reg   <= 32'd0;
            rresp_reg   <= 2'b00;

        end
        else begin

            arready_reg <= 1'b0;

            // ----------------------------------------------------
            // Accept READ ADDRESS
            // ----------------------------------------------------

            if (!rvalid_reg && S_AXI_ARVALID) begin

                arready_reg <= 1'b1;
                rvalid_reg  <= 1'b1;
                rresp_reg   <= 2'b00;

                case (S_AXI_ARADDR)

                    // --------------------------------------------
                    // Cipher CSR
                    // --------------------------------------------

                    7'h00: begin

                        rdata_reg = 32'd0;

                        rdata_reg[16] = 1'b0;
                        rdata_reg[17] = 1'b0;

                        rdata_reg[0] = cipher_done_reg;
                        rdata_reg[1] = cipher_busy_reg;

                    end


                    // --------------------------------------------
                    // Cipher Key
                    // --------------------------------------------

                    7'h04:
                        rdata_reg <= cipher_key0;

                    7'h08:
                        rdata_reg <= cipher_key1;

                    7'h0C:
                        rdata_reg <= cipher_key2;

                    7'h10:
                        rdata_reg <= cipher_key3;


                    // --------------------------------------------
                    // Cipher Text Input
                    // --------------------------------------------

                    7'h14:
                        rdata_reg <= cipher_tin0;

                    7'h18:
                        rdata_reg <= cipher_tin1;

                    7'h1C:
                        rdata_reg <= cipher_tin2;

                    7'h20:
                        rdata_reg <= cipher_tin3;


                    // --------------------------------------------
                    // Cipher Text Output
                    // --------------------------------------------

                    7'h24:
                        rdata_reg <= cipher_tout0;

                    7'h28:
                        rdata_reg <= cipher_tout1;

                    7'h2C:
                        rdata_reg <= cipher_tout2;

                    7'h30:
                        rdata_reg <= cipher_tout3;


                    // --------------------------------------------
                    // Inverse CSR
                    // --------------------------------------------

                    7'h40: begin

                        rdata_reg = 32'd0;

                        rdata_reg[0] = inv_done_reg;
                        rdata_reg[1] = inv_kdone_reg;
                        rdata_reg[2] = inv_busy_reg;

                    end


                    // --------------------------------------------
                    // Inverse Key
                    // --------------------------------------------

                    7'h44:
                        rdata_reg <= inv_key0;

                    7'h48:
                        rdata_reg <= inv_key1;

                    7'h4C:
                        rdata_reg <= inv_key2;

                    7'h50:
                        rdata_reg <= inv_key3;


                    // --------------------------------------------
                    // Inverse Text Input
                    // --------------------------------------------

                    7'h54:
                        rdata_reg <= inv_tin0;

                    7'h58:
                        rdata_reg <= inv_tin1;

                    7'h5C:
                        rdata_reg <= inv_tin2;

                    7'h60:
                        rdata_reg <= inv_tin3;


                    // --------------------------------------------
                    // Inverse Text Output
                    // --------------------------------------------

                    7'h64:
                        rdata_reg <= inv_tout0;

                    7'h68:
                        rdata_reg <= inv_tout1;

                    7'h6C:
                        rdata_reg <= inv_tout2;

                    7'h70:
                        rdata_reg <= inv_tout3;


                    // --------------------------------------------
                    // Undefined Address
                    // --------------------------------------------

                    default:
                        rdata_reg <= 32'hDEADBEEF;

                endcase

            end


            // ----------------------------------------------------
            // READ RESPONSE
            // ----------------------------------------------------

            if (rvalid_reg && S_AXI_RREADY)
                rvalid_reg <= 1'b0;

        end

    end

endmodule
