// ============================================================
// run_integration.f - VCS filelist for Integration simulation
//
// Design:
//   Interconnect (wrap_2x8) → Bridge (AXI4→AXI4-Lite) → UART
//
// Usage (run from the 'run/' directory):
//   vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
//       -f run_integration.f -top tb_axi_interconnect_uart_top \
//       -o simv_integration && ./simv_integration
// ============================================================

// ---------- Include paths ----------
+incdir+../rtl/uart/include

// ---------- Interconnect RTL ----------
../rtl/interconnect/priority_encoder(1).v
../rtl/interconnect/arbiter(1).v
../rtl/interconnect/axi_interconnect(1).v
../rtl/interconnect/axi_interconnect_wrap_2x8.v

// ---------- UART RTL ----------
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_receiver.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// ---------- Bridge + Top ----------
../rtl/axi_to_axilite_uart_bridge.v
../rtl/axi_interconnect_uart_top.v

// ---------- Testbench ----------
../tb/tb_axi_interconnect_uart_top.v
