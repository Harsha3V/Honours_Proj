// ============================================================
// run_interconnect_uart.f
// VCS filelist — Full 6-IP integration simulation
//
// Design hierarchy:
//   axi_interconnect_uart_top (top)
//     M00 → axi_to_axilite_aes_bridge → AES_AXI   (0x0000_0000)
//     M01 → tied off (DMA CSR — flat wrapper pending)
//     M02 → spi_axi_top                            (0x0200_0000)
//     M03 → axi_to_axilite_uart_bridge → axi_uart_top (0x0300_0000)
//     M04 → axi_to_axilite_timer_bridge → EF_TCC32_axi (0x0400_0000)
//     M05 → axi_to_axilite_gpio_bridge → EF_GPIO8_axi  (0x0500_0000)
//
// Usage (run from the 'sim/' directory):
//   vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
//       +incdir+../rtl/uart/include                                  \
//       -f run_interconnect_uart.f                                   \
//       -top tb_axi_interconnect_uart_top                            \
//       -o simv_integration && ./simv_integration
// ============================================================

// ---- Interconnect fabric ----
../rtl/interconnect/axi_interconnect_wrap_2x8.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// ---- AES-128 Engine (M00 — 0x0000_0000) ----
../rtl/aes/aes_rcon.v
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v
../rtl/aes/aes_axi_slave.v
../rtl/bridge/axi_to_axilite_aes_bridge.v

// ---- SPI Master (M02 — 0x0200_0000) ----
../rtl/spi/SPI_Master.v
../rtl/spi/SPI_Master_With_Single_CS.v
../rtl/spi/spi_axi_top.v

// ---- UART (M03 — 0x0300_0000) ----
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v
../rtl/bridge/axi_to_axilite_uart_bridge.v

// ---- Timer EF_TCC32 (M04 — 0x0400_0000) ----
../rtl/timer/EF_TCC32.v
../rtl/timer/EF_TCC32_axi.v
../rtl/bridge/axi_to_axilite_timer_bridge.v

// ---- GPIO EF_GPIO8 (M05 — 0x0500_0000) ----
../rtl/gpio/ef_util_sync.v
../rtl/gpio/EF_GPIO8.v
../rtl/gpio/EF_GPIO8_axi.v
../rtl/bridge/axi_to_axilite_gpio_bridge.v

// ---- Integration top ----
../rtl/top/axi_interconnect_uart_top.v

// ---- Testbench ----
../tb/tb_axi_interconnect_uart_top.v
