`timescale 1ns/1ps
//==============================================================================
// Testbench : tb_aes_axi_slave
// DUT       : AES_AXI
//==============================================================================

module tb_aes_axi_slave;

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter CLK_PERIOD = 10;
parameter TIMEOUT    = 5000;

//------------------------------------------------------------------------------
// AXI signals
//------------------------------------------------------------------------------
reg         S_AXI_ACLK;
reg         S_AXI_ARESETN;

reg  [6:0]  S_AXI_AWADDR;
reg         S_AXI_AWVALID;
wire        S_AXI_AWREADY;

reg  [31:0] S_AXI_WDATA;
reg  [3:0]  S_AXI_WSTRB;
reg         S_AXI_WVALID;
wire        S_AXI_WREADY;

wire [1:0]  S_AXI_BRESP;
wire        S_AXI_BVALID;
reg         S_AXI_BREADY;

reg  [6:0]  S_AXI_ARADDR;
reg         S_AXI_ARVALID;
wire        S_AXI_ARREADY;

wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;
wire        S_AXI_RVALID;
reg         S_AXI_RREADY;

//------------------------------------------------------------------------------
// Testbench variables
//------------------------------------------------------------------------------
integer error_cnt;
integer test_num;
integer timeout_cnt;
reg [31:0] rd_data;

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
AES_AXI dut (
    .S_AXI_ACLK    (S_AXI_ACLK),
    .S_AXI_ARESETN (S_AXI_ARESETN),
    .S_AXI_AWADDR  (S_AXI_AWADDR),
    .S_AXI_AWVALID (S_AXI_AWVALID),
    .S_AXI_AWREADY (S_AXI_AWREADY),
    .S_AXI_WDATA   (S_AXI_WDATA),
    .S_AXI_WSTRB   (S_AXI_WSTRB),
    .S_AXI_WVALID  (S_AXI_WVALID),
    .S_AXI_WREADY  (S_AXI_WREADY),
    .S_AXI_BRESP   (S_AXI_BRESP),
    .S_AXI_BVALID  (S_AXI_BVALID),
    .S_AXI_BREADY  (S_AXI_BREADY),
    .S_AXI_ARADDR  (S_AXI_ARADDR),
    .S_AXI_ARVALID (S_AXI_ARVALID),
    .S_AXI_ARREADY (S_AXI_ARREADY),
    .S_AXI_RDATA   (S_AXI_RDATA),
    .S_AXI_RRESP   (S_AXI_RRESP),
    .S_AXI_RVALID  (S_AXI_RVALID),
    .S_AXI_RREADY  (S_AXI_RREADY)
);

//------------------------------------------------------------------------------
// Clock
//------------------------------------------------------------------------------
initial S_AXI_ACLK = 1'b0;
always #(CLK_PERIOD/2) S_AXI_ACLK = ~S_AXI_ACLK;

//------------------------------------------------------------------------------
// AXI Write Task  (sequential: addr first, then data)
//------------------------------------------------------------------------------
task axi_write;
    input [6:0]  addr;
    input [31:0] data;
    integer i;
    begin
        // --- Drive write address ---
        @(negedge S_AXI_ACLK);
        S_AXI_AWADDR  = addr;
        S_AXI_AWVALID = 1'b1;
        S_AXI_WDATA   = 32'h0;
        S_AXI_WVALID  = 1'b0;
        S_AXI_BREADY  = 1'b1;

        // Wait for AWREADY
        i = 0;
        @(posedge S_AXI_ACLK);
        while (!S_AXI_AWREADY && i < TIMEOUT) begin
            @(posedge S_AXI_ACLK);
            i = i + 1;
        end
        @(negedge S_AXI_ACLK);
        S_AXI_AWVALID = 1'b0;

        // --- Drive write data ---
        S_AXI_WDATA  = data;
        S_AXI_WSTRB  = 4'hF;
        S_AXI_WVALID = 1'b1;

        // Wait for WREADY
        i = 0;
        @(posedge S_AXI_ACLK);
        while (!S_AXI_WREADY && i < TIMEOUT) begin
            @(posedge S_AXI_ACLK);
            i = i + 1;
        end
        @(negedge S_AXI_ACLK);
        S_AXI_WVALID = 1'b0;

        // Wait for BVALID
        i = 0;
        @(posedge S_AXI_ACLK);
        while (!S_AXI_BVALID && i < TIMEOUT) begin
            @(posedge S_AXI_ACLK);
            i = i + 1;
        end
        @(negedge S_AXI_ACLK);
        S_AXI_BREADY = 1'b0;
        @(posedge S_AXI_ACLK);
    end
endtask

//------------------------------------------------------------------------------
// AXI Read Task
//------------------------------------------------------------------------------
task axi_read;
    input  [6:0]  addr;
    output [31:0] data;
    integer i;
    begin
        @(negedge S_AXI_ACLK);
        S_AXI_ARADDR  = addr;
        S_AXI_ARVALID = 1'b1;
        S_AXI_RREADY  = 1'b1;

        // Wait for ARREADY
        i = 0;
        @(posedge S_AXI_ACLK);
        while (!S_AXI_ARREADY && i < TIMEOUT) begin
            @(posedge S_AXI_ACLK);
            i = i + 1;
        end
        @(negedge S_AXI_ACLK);
        S_AXI_ARVALID = 1'b0;

        // Wait for RVALID
        i = 0;
        @(posedge S_AXI_ACLK);
        while (!S_AXI_RVALID && i < TIMEOUT) begin
            @(posedge S_AXI_ACLK);
            i = i + 1;
        end
        data = S_AXI_RDATA;
        @(negedge S_AXI_ACLK);
        S_AXI_RREADY = 1'b0;
        @(posedge S_AXI_ACLK);
    end
endtask

//------------------------------------------------------------------------------
// Write 128-bit across 4 registers
//------------------------------------------------------------------------------
task write128;
    input [6:0]   base;
    input [127:0] val;
    begin
        axi_write(base,          val[127:96]);
        axi_write(base + 7'h4,   val[95:64]);
        axi_write(base + 7'h8,   val[63:32]);
        axi_write(base + 7'hC,   val[31:0]);
    end
endtask

//------------------------------------------------------------------------------
// Read 128-bit from 4 registers
//------------------------------------------------------------------------------
task read128;
    input  [6:0]   base;
    output [127:0] val;
    reg [31:0] w0, w1, w2, w3;
    begin
        axi_read(base,          w0);
        axi_read(base + 7'h4,   w1);
        axi_read(base + 7'h8,   w2);
        axi_read(base + 7'hC,   w3);
        val = {w0, w1, w2, w3};
    end
endtask

//------------------------------------------------------------------------------
// Poll bit with timeout
//------------------------------------------------------------------------------
task poll_bit;
    input  [6:0]   addr;
    input  integer bit_pos;
    output integer timed_out;
    integer cnt;
    reg [31:0] val;
    begin
        timed_out = 0;
        cnt = 0;
        val = 32'h0;
        while (!val[bit_pos] && cnt < TIMEOUT) begin
            axi_read(addr, val);
            cnt = cnt + 1;
        end
        if (cnt >= TIMEOUT) begin
            $display("  TIMEOUT addr=0x%02X bit[%0d]", addr, bit_pos);
            timed_out = 1;
        end
    end
endtask

//------------------------------------------------------------------------------
// Check
//------------------------------------------------------------------------------
task check;
    input [31:0]   actual;
    input [31:0]   expected;
    input [8*40:1] label;
    begin
        if (actual !== expected) begin
            $display("  FAIL [TC%0d] %0s : exp=0x%08X got=0x%08X",
                     test_num, label, expected, actual);
            error_cnt = error_cnt + 1;
        end else
            $display("  PASS [TC%0d] %0s = 0x%08X", test_num, label, actual);
    end
endtask

//==============================================================================
// Main Test
//==============================================================================
initial begin
    // Init
    S_AXI_ARESETN = 1'b0;
    S_AXI_AWADDR  = 7'h0;  S_AXI_AWVALID = 1'b0;
    S_AXI_WDATA   = 32'h0; S_AXI_WSTRB = 4'hF; S_AXI_WVALID = 1'b0;
    S_AXI_BREADY  = 1'b0;
    S_AXI_ARADDR  = 7'h0;  S_AXI_ARVALID = 1'b0;
    S_AXI_RREADY  = 1'b0;
    error_cnt = 0;

    $display("");
    $display("==========================================================");
    $display("  AES AXI Slave Testbench  (DUT: AES_AXI)");
    $display("==========================================================");

    repeat(10) @(posedge S_AXI_ACLK);
    S_AXI_ARESETN = 1'b1;
    repeat(5)  @(posedge S_AXI_ACLK);

    //==========================================================================
    // TC1: Reset check
    //==========================================================================
    test_num = 1;
    $display("\n[TC1] Reset check");
    axi_read(7'h00, rd_data);
    check(rd_data[0], 1'b0, "CIPHER_CSR.DONE  after reset");
    check(rd_data[1], 1'b0, "CIPHER_CSR.BUSY  after reset");
    axi_read(7'h40, rd_data);
    check(rd_data[0], 1'b0, "INV_CSR.DONE     after reset");
    check(rd_data[1], 1'b0, "INV_CSR.KDONE    after reset");
    check(rd_data[2], 1'b0, "INV_CSR.BUSY     after reset");

    //==========================================================================
    // TC2: Register read-back
    //==========================================================================
    test_num = 2;
    $display("\n[TC2] Register read-back");
    axi_write(7'h04, 32'hDEADBEEF); axi_read(7'h04, rd_data); check(rd_data, 32'hDEADBEEF, "CIPHER_KEY0");
    axi_write(7'h08, 32'hCAFEBABE); axi_read(7'h08, rd_data); check(rd_data, 32'hCAFEBABE, "CIPHER_KEY1");
    axi_write(7'h0C, 32'h01234567); axi_read(7'h0C, rd_data); check(rd_data, 32'h01234567, "CIPHER_KEY2");
    axi_write(7'h10, 32'h89ABCDEF); axi_read(7'h10, rd_data); check(rd_data, 32'h89ABCDEF, "CIPHER_KEY3");
    axi_write(7'h14, 32'h11111111); axi_read(7'h14, rd_data); check(rd_data, 32'h11111111, "CIPHER_TIN0");
    axi_write(7'h18, 32'h22222222); axi_read(7'h18, rd_data); check(rd_data, 32'h22222222, "CIPHER_TIN1");
    axi_write(7'h1C, 32'h33333333); axi_read(7'h1C, rd_data); check(rd_data, 32'h33333333, "CIPHER_TIN2");
    axi_write(7'h20, 32'h44444444); axi_read(7'h20, rd_data); check(rd_data, 32'h44444444, "CIPHER_TIN3");
    axi_write(7'h44, 32'hAABBCCDD); axi_read(7'h44, rd_data); check(rd_data, 32'hAABBCCDD, "INV_KEY0");
    axi_write(7'h48, 32'hEEFF0011); axi_read(7'h48, rd_data); check(rd_data, 32'hEEFF0011, "INV_KEY1");
    axi_write(7'h4C, 32'h22334455); axi_read(7'h4C, rd_data); check(rd_data, 32'h22334455, "INV_KEY2");
    axi_write(7'h50, 32'h66778899); axi_read(7'h50, rd_data); check(rd_data, 32'h66778899, "INV_KEY3");

    //==========================================================================
    // TC3: Encryption  (NIST FIPS-197 Appendix B)
    //   key       = 2b7e151628aed2a6abf7158809cf4f3c
    //   plaintext = 3243f6a8885a308d313198a2e0370734
    //   expected  = 3925841d02dc09fbdc118597196a0b32
    //==========================================================================
    test_num = 3;
    $display("\n[TC3] Encryption (NIST FIPS-197 Appendix B)");
    begin : tc3
        reg [127:0] got_ciph;
        integer     tout;
        write128(7'h04, 128'h2b7e151628aed2a6abf7158809cf4f3c);
        write128(7'h14, 128'h3243f6a8885a308d313198a2e0370734);
        axi_write(7'h00, 32'h00010000);
        poll_bit(7'h00, 0, tout);
        if (!tout) begin
            read128(7'h24, got_ciph);
            if (got_ciph !== 128'h3925841d02dc09fbdc118597196a0b32) begin
                $display("  FAIL [TC3] exp=3925841d02dc09fbdc118597196a0b32");
                $display("             got=%032h", got_ciph);
                error_cnt = error_cnt + 1;
            end else
                $display("  PASS [TC3] ciphertext=%032h", got_ciph);
        end else begin
            $display("  FAIL [TC3] Encryption timed out");
            error_cnt = error_cnt + 1;
        end
        axi_read(7'h00, rd_data);
        check(rd_data[1], 1'b0, "CIPHER_CSR.BUSY cleared");
    end

    //==========================================================================
    // TC4: Decryption round-trip (NIST FIPS-197 Appendix B)
    //==========================================================================
    test_num = 4;
    $display("\n[TC4] Decryption round-trip");
    begin : tc4
        reg [127:0] got_plain;
        integer     tout;
        write128(7'h44, 128'h2b7e151628aed2a6abf7158809cf4f3c);
        axi_write(7'h40, 32'h00010000);         // KEY_LOAD
        poll_bit(7'h40, 1, tout);               // wait KDONE
        if (tout) begin
            $display("  FAIL [TC4] KDONE timed out");
            error_cnt = error_cnt + 1;
        end else begin
            $display("  INFO [TC4] Key expansion complete");
            write128(7'h54, 128'h3925841d02dc09fbdc118597196a0b32);
            axi_write(7'h40, 32'h00020000);     // START
            poll_bit(7'h40, 0, tout);           // wait DONE
            if (!tout) begin
                read128(7'h64, got_plain);
                if (got_plain !== 128'h3243f6a8885a308d313198a2e0370734) begin
                    $display("  FAIL [TC4] exp=3243f6a8885a308d313198a2e0370734");
                    $display("             got=%032h", got_plain);
                    error_cnt = error_cnt + 1;
                end else
                    $display("  PASS [TC4] plaintext=%032h", got_plain);
            end else begin
                $display("  FAIL [TC4] Decryption timed out");
                error_cnt = error_cnt + 1;
            end
        end
    end

    //==========================================================================
    // TC5: Encrypt/Decrypt round-trip (5 vectors from original testbench)
    //==========================================================================
    test_num = 5;
    $display("\n[TC5] Encrypt/Decrypt round-trip (5 vectors)");
    begin : tc5
        reg [383:0] vec [0:4];
        reg [127:0] key_v, plain_v, enc_out, dec_out;
        integer     tout, v;

        vec[0]=384'h112e4b6885a2bfdcf91633506d8aa7c4_234e79a4cffa25507ba6d1fc27527da8_be76b7d46ecf1afdcb3ed6942ba3deec;
        vec[1]=384'h223f5c7996b3d0ed0a2744617e9bb8d5_426d98c3ee19446f9ac5f01b46719cc7_4ffca1d0c2ebe89892a72dbc098ff37c;
        vec[2]=384'h33506d8aa7c4e1fe1b3855728facc9e6_618cb7e20d38638eb9e40f3a6590bbe6_a420c61b91d2754380f186a8cc018f3e;
        vec[3]=384'h44617e9bb8d5f20f2c496683a0bddaf7_80abd6012c5782add8032e5984afda05_35a986cbce1862f1e02a82e045a9f827;
        vec[4]=384'h55728facc9e603203d5a7794b1ceeb08_9fcaf5204b76a1ccf7224d78a3cef924_e00bb2d7558ca82d03b8774215b226a1;

        for (v = 0; v < 5; v = v + 1) begin
            key_v   = vec[v][383:256];
            plain_v = vec[v][255:128];
            $display("  [v%0d] key=%032h plain=%032h", v, key_v, plain_v);

            // Encrypt
            write128(7'h04, key_v);
            write128(7'h14, plain_v);
            axi_write(7'h00, 32'h00010000);
            poll_bit(7'h00, 0, tout);
            if (tout) begin
                $display("  FAIL [TC5] v%0d enc timeout", v);
                error_cnt = error_cnt + 1;
            end else begin
                read128(7'h24, enc_out);
                $display("         enc=%032h exp=%032h", enc_out, vec[v][127:0]);
                if (enc_out !== vec[v][127:0]) begin
                    $display("  FAIL [TC5] v%0d cipher mismatch", v);
                    error_cnt = error_cnt + 1;
                end

                // Decrypt
                write128(7'h44, key_v);
                axi_write(7'h40, 32'h00010000);
                poll_bit(7'h40, 1, tout);
                if (tout) begin
                    $display("  FAIL [TC5] v%0d KDONE timeout", v);
                    error_cnt = error_cnt + 1;
                end else begin
                    write128(7'h54, enc_out);
                    axi_write(7'h40, 32'h00020000);
                    poll_bit(7'h40, 0, tout);
                    if (tout) begin
                        $display("  FAIL [TC5] v%0d dec timeout", v);
                        error_cnt = error_cnt + 1;
                    end else begin
                        read128(7'h64, dec_out);
                        if (dec_out !== plain_v) begin
                            $display("  FAIL [TC5] v%0d dec mismatch", v);
                            $display("         exp=%032h got=%032h", plain_v, dec_out);
                            error_cnt = error_cnt + 1;
                        end else
                            $display("  PASS [TC5] v%0d round-trip OK", v);
                    end
                end
            end
        end
    end

    //==========================================================================
    // TC6: RO register write protection
    //==========================================================================
    test_num = 6;
    $display("\n[TC6] RO register write protection");
    begin : tc6
        reg [31:0] b0, b1, a0, a1;
        axi_read(7'h24, b0); axi_read(7'h28, b1);
        axi_write(7'h24, 32'hFFFFFFFF);
        axi_write(7'h28, 32'hFFFFFFFF);
        axi_read(7'h24, a0); axi_read(7'h28, a1);
        check(a0, b0, "CIPHER_TOUT0 unchanged after write");
        check(a1, b1, "CIPHER_TOUT1 unchanged after write");
    end

    //==========================================================================
    // TC7: Undefined address returns 0xDEADBEEF
    //==========================================================================
    test_num = 7;
    $display("\n[TC7] Undefined address");
    axi_read(7'h7C, rd_data); check(rd_data, 32'hDEADBEEF, "addr 0x7C");
    axi_read(7'h38, rd_data); check(rd_data, 32'hDEADBEEF, "addr 0x38");

    //==========================================================================
    // Summary
    //==========================================================================
    repeat(10) @(posedge S_AXI_ACLK);
    $display("");
    $display("==========================================================");
    if (error_cnt == 0)
        $display("  ALL TESTS PASSED  (0 errors)");
    else
        $display("  COMPLETED WITH %0d ERROR(S)", error_cnt);
    $display("==========================================================");
    $display("");
    $finish;
end

//------------------------------------------------------------------------------
// Waveform dump
//------------------------------------------------------------------------------
initial begin
    $fsdbDumpfile("dump_axi_slave.fsdb");
    $fsdbDumpvars("+all");
end

//------------------------------------------------------------------------------
// Watchdog  (200 ms sim time @ 10ns clock = 20M cycles — plenty)
//------------------------------------------------------------------------------
initial begin
    #200000000;
    $display("WATCHDOG: timeout at %0t", $time);
    $finish;
end

endmodule
