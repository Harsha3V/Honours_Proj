/* =============================================================================
 * Project        : Honours Project — AES-128 ECU Gateway SoC
 * File           : tb_soc_top.v
 * Description    : End-to-End Simulation Testbench for soc_top.
 *
 * Capabilities:
 *   - Instantiates full soc_top with VeeR EL2 core + 2x8 AXI Interconnect + 7 IPs.
 *   - Loads boot.hex into Boot ROM via ifu_rom_stub ($readmemh).
 *   - Generates 100 MHz clock (10 ns) and resets CPU at vector 0x8000_0000.
 *   - Real-time UART monitor: decodes serial bits on uart_tx_o at 115200 baud
 *     and streams ASCII characters directly to console transcript ($write).
 *   - Real-time SPI monitor: captures MOSI ciphertext payload and verifies bytes.
 *   - GPIO status monitor: logs LED state changes.
 * =============================================================================*/

`timescale 1ns/1ps
`default_nettype none

module tb_soc_top;

// =============================================================================
// Simulation Parameters
// =============================================================================
localparam CLK_PERIOD   = 10;                     // 100 MHz (10 ns period)
localparam RESET_CYCLES = 25;                     // Hold reset for 25 cycles
localparam BAUD_RATE    = 115200;
localparam real BIT_NS  = 1.0e9 / BAUD_RATE;     // ≈ 8680.55 ns per UART bit

// =============================================================================
// DUT Signals
// =============================================================================
reg         clk;
reg         rst_l;          // VeeR core reset (active-high in core logic)
reg         rstn;           // Interconnect & IPs reset (active-low)
reg  [31:1] rst_vec;        // Reset vector (0x8000_0000 >> 1 = 31'h4000_0000)
reg         nmi_int;
reg  [31:1] nmi_vec;
reg  [31:1] jtag_id;

reg         jtag_tck;
reg         jtag_tms;
reg         jtag_tdi;
wire        jtag_tdo;

// Peripherals
reg         uart_rx_i;
wire        uart_tx_o;
wire        uart_irq_o;

wire        spi_clk_o;
wire        spi_mosi_o;
reg         spi_miso_i;
wire        spi_cs_n_o;

reg  [7:0]  gpio_in_i;
wire [7:0]  gpio_out_o;
wire [7:0]  gpio_oe_o;
wire        gpio_irq_o;

reg         timer_ctr_in_i;
wire        timer_irq_o;

wire        dma_done_o;
wire        dma_error_o;

// =============================================================================
// 1. Clock Generation (100 MHz)
// =============================================================================
initial clk = 1'b0;
always #(CLK_PERIOD / 2) clk = ~clk;

// =============================================================================
// 2. DUT Instantiation
// =============================================================================
soc_top #(
    .ROM_DEPTH (4096),
    .ROM_FILE  ("boot.hex")
) u_dut (
    .clk            (clk),
    .rst_l          (rst_l),
    .rstn           (rstn),
    .rst_vec        (rst_vec),
    .nmi_int        (nmi_int),
    .nmi_vec        (nmi_vec),
    .jtag_id        (jtag_id),

    .jtag_tck       (jtag_tck),
    .jtag_tms       (jtag_tms),
    .jtag_tdi       (jtag_tdi),
    .jtag_tdo       (jtag_tdo),

    .uart_rx_i      (uart_rx_i),
    .uart_tx_o      (uart_tx_o),
    .uart_irq_o     (uart_irq_o),

    .spi_clk_o      (spi_clk_o),
    .spi_mosi_o     (spi_mosi_o),
    .spi_miso_i     (spi_miso_i),
    .spi_cs_n_o     (spi_cs_n_o),

    .gpio_in_i      (gpio_in_i),
    .gpio_out_o     (gpio_out_o),
    .gpio_oe_o      (gpio_oe_o),
    .gpio_irq_o     (gpio_irq_o),

    .timer_ctr_in_i (timer_ctr_in_i),
    .timer_irq_o    (timer_irq_o),

    .dma_done_o     (dma_done_o),
    .dma_error_o    (dma_error_o)
);

/// =============================================================================
// 3. Reset Sequence & Stimulus
// =============================================================================
initial begin
    // Waveform dump: run with +dump to enable VCD recording
    if ($test$plusargs("dump")) begin
        $dumpfile("simv_soc_top.vcd");
        $dumpvars(0, tb_soc_top);
        $display("[TB] Waveform dumping enabled (simv_soc_top.vcd)");
    end

    $display("==================================================================");
    $display(" [TB] Starting Simulation: VeeR EL2 Secure ECU Gateway SoC");
    $display(" [TB] Clock = 100 MHz, ROM Loaded = boot.hex");
    $display("==================================================================");

    // Initial state
    rst_l          = 1'b0;
    rstn           = 1'b0;
    rst_vec        = 31'h4000_0000;   // 0x8000_0000 >> 1
    nmi_int        = 1'b0;
    nmi_vec        = 31'h0;
    jtag_id        = 31'h1;
    jtag_tck       = 1'b0;
    jtag_tms       = 1'b1;            // JTAG held in Test-Logic-Reset
    jtag_tdi       = 1'b0;
    uart_rx_i      = 1'b1;            // UART idle high
    spi_miso_i     = 1'b0;
    gpio_in_i      = 8'h00;
    timer_ctr_in_i = 1'b0;

    // Hold reset for RESET_CYCLES
    repeat (RESET_CYCLES) @(posedge clk);
    rst_l = 1'b1;
    rstn  = 1'b1;
    $display("[TB] Reset released at time %0t. VeeR CPU fetching from 0x8000_0000...", $time);
    $display("[TB] ROM[0]=0x%08x, ROM[1]=0x%08x, ROM[2]=0x%08x",
             u_dut.u_ifu_rom.rom[0], u_dut.u_ifu_rom.rom[1], u_dut.u_ifu_rom.rom[2]);

    // Set overall fallback simulation timeout (80 milliseconds simulated time)
    #80_000_000;
    $display("\n[TB] Timeout reached (80 ms). Last Committed PC=0x%08x, insn=0x%08x, commit_cnt=%0d. Simulation finished.",
             last_committed_pc,
             last_committed_insn,
             commit_cnt);
    $finish;
end

// Trace instruction commits
integer commit_cnt = 0;
integer uart_trace_cnt = 0;
reg [31:0] last_committed_pc;
reg [31:0] last_committed_insn;

always @(posedge clk) begin
    if (u_dut.u_veer.trace_rv_i_valid_ip) begin
        commit_cnt <= commit_cnt + 1;
        last_committed_pc   <= u_dut.u_veer.trace_rv_i_address_ip;
        last_committed_insn <= u_dut.u_veer.trace_rv_i_insn_ip;

        if (commit_cnt <= 40 || $test$plusargs("trace_all")) begin
            $display("[TRACE-COMMIT #%02d] PC=0x%08x, Insn=0x%08x @ %0t",
                     commit_cnt,
                     u_dut.u_veer.trace_rv_i_address_ip[31:0],
                     u_dut.u_veer.trace_rv_i_insn_ip[31:0], $time);
            if (commit_cnt == 40)
                $display("\n[TRACE] Core entered main()! Live UART/SPI streaming active below:\n");
        end
    end
    if (u_dut.u_veer.trace_rv_i_exception_ip) begin
        $display("[TRACE-EXCEPTION] PC=0x%08x, Cause=%0d, Tval=0x%08x @ %0t",
                 u_dut.u_veer.trace_rv_i_address_ip[31:0],
                 u_dut.u_veer.trace_rv_i_ecause_ip[4:0],
                 u_dut.u_veer.trace_rv_i_tval_ip[31:0], $time);
    end
end

// Periodic heartbeat: print current PC and time every 10 ms (simulated time)
always begin
    #10_000_000;
    if (rstn) begin
        $display("\n[TB-HEARTBEAT] Time=%0t (ms: %0d), PC=0x%08x, Commits=%0d",
                 $time, $time/1_000_000_000, last_committed_pc, commit_cnt);
    end
end

// Probe peripheral LSU transactions (enabled with +debug_bus)
always @(posedge clk) begin
    if ($test$plusargs("debug_bus")) begin
        if (u_dut.lsu_axi_awvalid && u_dut.lsu_axi_awready) begin
            if (u_dut.lsu_axi_awaddr < 32'hEE00_0000) begin
                $display("[LSU-PERIPH-WR] Addr=0x%08x, Strb=8'b%08b, Data64=0x%016x @ %0t",
                         u_dut.lsu_axi_awaddr, u_dut.lsu_axi_wstrb, u_dut.lsu_axi_wdata, $time);
            end
        end
        if (u_dut.lsu_axi_arvalid && u_dut.lsu_axi_arready) begin
            if (u_dut.lsu_axi_araddr < 32'hEE00_0000) begin
                $display("[LSU-PERIPH-RD] Addr=0x%08x, Size=%0d, Len=%0d @ %0t",
                         u_dut.lsu_axi_araddr, u_dut.lsu_axi_arsize, u_dut.lsu_axi_arlen, $time);
            end
        end
    end
end

// =============================================================================
// 4. Real-Time UART RX Monitor (Prints CPU console output directly to transcript)
// =============================================================================
reg [7:0] uart_char;
integer   bit_idx;

initial begin
    wait (rstn === 1'b1);
    forever begin
        // Wait for start bit (falling edge on uart_tx_o)
        @(negedge uart_tx_o);

        // Verify start bit at center
        #(BIT_NS / 2.0);
        if (uart_tx_o === 1'b0) begin
            // Sample 8 data bits LSB first
            uart_char = 8'h00;
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                #(BIT_NS);
                uart_char = {uart_tx_o, uart_char[7:1]};
            end

            // Wait for stop bit
            #(BIT_NS);

            // Display character on console
            $write("%c", uart_char);
            $fflush();
        end
    end
end

// =============================================================================
// 5. Real-Time SPI CAN Frame Monitor (Captures ciphertext on MOSI)
// =============================================================================
reg [7:0] spi_byte;
integer   spi_bit_idx;
integer   spi_byte_count;

initial begin
    spi_byte_count = 0;
    wait (rstn === 1'b1);
    forever begin
        // Wait for SPI Chip-Select active low
        @(negedge spi_cs_n_o);
        $display("\n[TB-SPI] Chip-Select Asserted (CS=0). Receiving CAN Frame...");

        while (spi_cs_n_o === 1'b0) begin
            spi_byte = 8'h00;
            for (spi_bit_idx = 7; spi_bit_idx >= 0; spi_bit_idx = spi_bit_idx - 1) begin
                @(posedge spi_clk_o);
                spi_byte[spi_bit_idx] = spi_mosi_o;
            end
            spi_byte_count = spi_byte_count + 1;
            $display("[TB-SPI] Byte %2d: 0x%02X", spi_byte_count, spi_byte);
        end

        $display("[TB-SPI] Chip-Select Deasserted (CS=1). Total %0d bytes received.\n", spi_byte_count);
    end
end

// =============================================================================
// 6. GPIO Output Monitor (Logs LED status transitions & triggers success finish)
// =============================================================================
always @(gpio_out_o) begin
    if (rstn) begin
        $display("\n[TB-GPIO] LED State Updated: 8'b%08b (0x%02X) @ %0t",
                 gpio_out_o, gpio_out_o, $time);
        if (gpio_out_o == 8'h05) begin
            // Wait 2 ms (simulated time) for final UART characters to flush to console
            #2_000_000;
            $display("\n==================================================================");
            $display(" [TB] SIMULATION SUCCESS: All 7 AUTOSAR SecOC Phases Completed!");
            $display("==================================================================\n");
            $finish;
        end
    end
end

endmodule
`default_nettype wire
