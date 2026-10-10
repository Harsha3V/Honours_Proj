// ============================================================
// run_aes.f
// VCS filelist — AES-128 standalone simulation
//
// Design hierarchy:
//   tb_aes_axi_slave (top)
//     AES_AXI (aes_axi_slave)
//       aes_cipher_top
//         aes_sbox, aes_key_expand_128, aes_rcon
//       aes_inv_cipher_top
//         aes_inv_sbox, aes_key_expand_128, aes_rcon
//
// Usage (run from the 'sim/' directory):
//   vcs -full64 -debug_access+all -kdb -sverilog -timescale=1ns/1ps \
//       -f run_aes.f                                                  \
//       -top tb_aes_axi_slave                                         \
//       -o simv_aes && ./simv_aes
// ============================================================

// ---- Include path (needed for `include "timescale.v" inside AES files) ----
+incdir+../rtl/aes

// ---- AES sub-blocks ----
../rtl/aes/timescale.v
../rtl/aes/aes_rcon.v
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v

// ---- AES AXI slave wrapper ----
../rtl/aes/aes_axi_slave.v

// ---- Testbench ----
../tb/aes/tb_aes_axi_slave.v
