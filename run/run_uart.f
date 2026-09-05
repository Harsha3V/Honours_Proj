// ============================================================
// run_uart.f  -  VCS filelist for AXI-Lite UART IP Core
//
// Usage (run from the 'run/' directory):
//   Compile + simulate a specific testbench:
//     vcs -full64 -sverilog -f run_uart.f -top tb_axi_uart_top      -o simv_uart_top      && ./simv_uart_top
//     vcs -full64 -sverilog -f run_uart.f -top tb_uart_controller    -o simv_uart_ctrl     && ./simv_uart_ctrl
//     vcs -full64 -sverilog -f run_uart.f -top tb_uart_transmitter   -o simv_uart_tx       && ./simv_uart_tx
//     vcs -full64 -sverilog -f run_uart.f -top tb_uart_receiver      -o simv_uart_rx       && ./simv_uart_rx
//     vcs -full64 -sverilog -f run_uart.f -top tb_axi_internal_fifo  -o simv_uart_fifo     && ./simv_uart_fifo
//     vcs -full64 -sverilog -f run_uart.f -top tb_uart_parity_bit_compute -o simv_uart_par && ./simv_uart_par
// ============================================================

// ---------- Include paths ----------
// Headers needed by axi_uart_top.v  (axi_uart.vh, axi_uart_defines.vh)
+incdir+../rtl/uart/include

// ---------- RTL source files ----------
// Compile leaf modules first (no sub-instances), then top-level
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_receiver.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// ---------- Testbench files ----------
// All six testbenches are listed; pick the desired -top on the vcs command line
../tb/uart_tb/tb_uart_parity_bit_compute.v
../tb/uart_tb/tb_axi_internal_fifo.v
../tb/uart_tb/tb_uart_transmitter.v
../tb/uart_tb/tb_uart_receiver.v
../tb/uart_tb/tb_uart_controller.v
../tb/uart_tb/tb_axi_uart_top.v
