// ============================================================
// run_interconnect_uart.f
// VCS filelist — Interconnect + UART + AES integration
//
// Design:
//   axi_interconnect_wrap_2x8
//     M02 → UART bridge → axi_uart_top        (0x0200_0000)
//     M03 → AES  bridge → AES_AXI             (0x0300_0000)
//
// Usage (run from the 'run/' directory):
//   vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
//       +incdir+../rtl/uart/include \
//       -f run_interconnect_uart.f \
//       -top tb_axi_interconnect_uart_top \
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

// ---------- AES RTL ----------
../rtl/aes/aes_rcon.v
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v
../rtl/aes/aes_axi_slave.v

// ---------- Bridges ----------
../rtl/bridge/axi_to_axilite_uart_bridge.v
../rtl/bridge/axi_to_axilite_aes_bridge.v

// ---------- SoC Integration Top ----------
../rtl/top/axi_interconnect_uart_top.v

// ---------- Testbench ----------
../tb/tb_axi_interconnect_uart_top.v
