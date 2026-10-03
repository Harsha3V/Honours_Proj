/*
 * File    : ef_util_sync.v
 * Project : Honours Project
 * Brief   : 2-stage synchronizer for metastability resolution.
 *           Used by EF_GPIO8 to synchronize external GPIO inputs to clk domain.
 *           Instantiated as an array: ef_util_sync synchronizer[7:0] (...)
 */

`timescale 1ns/1ps
`default_nettype none

module ef_util_sync (
    input  wire clk,
    input  wire in,
    output wire out
);
    reg stage1, stage2;

    always @(posedge clk) begin
        stage1 <= in;
        stage2 <= stage1;
    end

    assign out = stage2;

endmodule

`default_nettype wire
