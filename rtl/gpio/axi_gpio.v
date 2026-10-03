/* -----------------------------------------------------------------------------
 * Project     : Honours Project - RISC-V Hardware-Accelerated ECU Gateway
 * File        : axi_gpio.v
 * Description : AXI4-Lite 32-bit General Purpose I/O IP with Interrupt Support
 *
 * Register Map (offsets from GPIO Base Address):
 *   0x00 : GPIO_DATA_IN    - [31:0] External pin read data (RO)
 *   0x04 : GPIO_DATA_OUT   - [31:0] Pin output data drive (R/W)
 *   0x08 : GPIO_DIR        - [31:0] Direction mask: 1 = output, 0 = input (R/W)
 *   0x0C : GPIO_IRQ_EN     - [31:0] Per-pin interrupt enable mask (R/W)
 *   0x10 : GPIO_IRQ_STATUS - [31:0] Per-pin edge detected interrupt status (R/W1C)
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps
`default_nettype none

module axi_gpio #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter GPIO_PINS  = 32
)(
    input  wire                   clk,
    input  wire                   rstn,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire                   s_axil_awvalid,
    output reg                    s_axil_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output reg                    s_axil_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]             s_axil_bresp,
    output reg                    s_axil_bvalid,
    input  wire                   s_axil_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire                   s_axil_arvalid,
    output reg                    s_axil_arready,

    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output reg                    s_axil_rvalid,
    input  wire                   s_axil_rready,

    // GPIO External Interface
    input  wire [GPIO_PINS-1:0]   gpio_i,
    output wire [GPIO_PINS-1:0]   gpio_o,
    output wire [GPIO_PINS-1:0]   gpio_oe,
    output wire                   gpio_irq
);

    assign s_axil_bresp = 2'b00; // OKAY
    assign s_axil_rresp = 2'b00; // OKAY

    // Internal Registers
    reg [GPIO_PINS-1:0] r_gpio_out;
    reg [GPIO_PINS-1:0] r_gpio_dir;
    reg [GPIO_PINS-1:0] r_gpio_irq_en;
    reg [GPIO_PINS-1:0] r_gpio_irq_status;

    // Pin synchronizers & edge detection
    reg [GPIO_PINS-1:0] gpio_sync_0, gpio_sync_1, gpio_sync_prev;

    assign gpio_o   = r_gpio_out;
    assign gpio_oe  = r_gpio_dir;
    assign gpio_irq = |(r_gpio_irq_status & r_gpio_irq_en);

    // -------------------------------------------------------------------------
    // Input Synchronization and Edge Detection
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            gpio_sync_0       <= {GPIO_PINS{1'b0}};
            gpio_sync_1       <= {GPIO_PINS{1'b0}};
            gpio_sync_prev    <= {GPIO_PINS{1'b0}};
            r_gpio_irq_status <= {GPIO_PINS{1'b0}};
        end else begin
            gpio_sync_0    <= gpio_i;
            gpio_sync_1    <= gpio_sync_0;
            gpio_sync_prev <= gpio_sync_1;

            // Detect any edge (rising or falling) on input pins
            // Bitwise OR edge flags with pending flags
            r_gpio_irq_status <= (r_gpio_irq_status | 
                                 ((gpio_sync_1 ^ gpio_sync_prev) & ~r_gpio_dir & r_gpio_irq_en));

            // W1C for IRQ status register
            if (s_axil_awvalid && s_axil_awready && s_axil_wvalid && s_axil_wready &&
                (s_axil_awaddr[4:2] == 3'b100)) begin
                r_gpio_irq_status <= (r_gpio_irq_status & ~s_axil_wdata[GPIO_PINS-1:0]);
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel Logic
    // -------------------------------------------------------------------------
    localparam WR_IDLE = 1'b0;
    localparam WR_RESP = 1'b1;
    reg wr_state;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_state        <= WR_IDLE;
            s_axil_awready  <= 1'b0;
            s_axil_wready   <= 1'b0;
            s_axil_bvalid   <= 1'b0;
            r_gpio_out      <= {GPIO_PINS{1'b0}};
            r_gpio_dir      <= {GPIO_PINS{1'b0}};
            r_gpio_irq_en   <= {GPIO_PINS{1'b0}};
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        s_axil_awready <= 1'b1;
                        s_axil_wready  <= 1'b1;

                        case (s_axil_awaddr[4:2])
                            3'b000: begin // 0x00: GPIO_DATA_IN (RO)
                            end
                            3'b001: begin // 0x04: GPIO_DATA_OUT
                                r_gpio_out <= s_axil_wdata[GPIO_PINS-1:0];
                            end
                            3'b010: begin // 0x08: GPIO_DIR
                                r_gpio_dir <= s_axil_wdata[GPIO_PINS-1:0];
                            end
                            3'b011: begin // 0x0C: GPIO_IRQ_EN
                                r_gpio_irq_en <= s_axil_wdata[GPIO_PINS-1:0];
                            end
                            3'b100: begin // 0x10: GPIO_IRQ_STATUS (W1C handled in sync logic)
                            end
                        endcase
                        wr_state <= WR_RESP;
                    end else begin
                        s_axil_awready <= 1'b0;
                        s_axil_wready  <= 1'b0;
                    end
                end

                WR_RESP: begin
                    s_axil_awready <= 1'b0;
                    s_axil_wready  <= 1'b0;
                    s_axil_bvalid  <= 1'b1;
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        wr_state      <= WR_IDLE;
                    end
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Channel Logic
    // -------------------------------------------------------------------------
    localparam RD_IDLE = 1'b0;
    localparam RD_RESP = 1'b1;
    reg rd_state;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rd_state       <= RD_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rdata   <= 32'h0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        s_axil_rvalid  <= 1'b1;
                        case (s_axil_araddr[4:2])
                            3'b000: s_axil_rdata <= {{32-GPIO_PINS{1'b0}}, gpio_sync_1};
                            3'b001: s_axil_rdata <= {{32-GPIO_PINS{1'b0}}, r_gpio_out};
                            3'b010: s_axil_rdata <= {{32-GPIO_PINS{1'b0}}, r_gpio_dir};
                            3'b011: s_axil_rdata <= {{32-GPIO_PINS{1'b0}}, r_gpio_irq_en};
                            3'b100: s_axil_rdata <= {{32-GPIO_PINS{1'b0}}, r_gpio_irq_status};
                            default: s_axil_rdata <= 32'hDEADBEEF;
                        endcase
                        rd_state <= RD_RESP;
                    end else begin
                        s_axil_arready <= 1'b0;
                        s_axil_rvalid  <= 1'b0;
                    end
                end

                RD_RESP: begin
                    s_axil_arready <= 1'b0;
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        rd_state      <= RD_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
`default_nettype wire
