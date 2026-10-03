// ============================================================
// run_veer_uart_soc.f  — VCS filelist for VeeR EL2 + UART SoC
//
// Design hierarchy:
//   tb_veer_uart_soc                        (testbench top)
//     └── veer_uart_soc_top                 (SoC top)
//           ├── el2_veer_wrapper            (VeeR EL2 RISC-V core, AXI4 mode)
//           ├── ifu_rom_stub                (instruction ROM for IFU AXI)
//           └── axi_interconnect_uart_top
//                 ├── axi_interconnect_wrap_2x8
//                 ├── axi_to_axilite_uart_bridge
//                 └── axi_uart_top  (UART + FIFOs)
//
// Usage (run from the 'run/' directory):
//
//   export RV_ROOT=../rtl/Cores-VeeR-EL2
//
//   vcs -full64 -debug_access+all -kdb               \
//       -sverilog +define+RV_BUILD_AXI4              \
//       +incdir+$RV_ROOT/design/include              \
//       +incdir+$RV_ROOT/configs                     \
//       +incdir+../rtl/uart/include                  \
//       -timescale=1ns/1ps                           \
//       -f run_veer_uart_soc.f                       \
//       -top tb_veer_uart_soc                        \
//       -o simv_veer_uart &&                         \
//   ./simv_veer_uart
//
//   Optional: add +define+FSDB to enable Verdi FSDB waveform dump.
//   Optional: add +define+VCD  to enable VCD waveform dump.
//
// Notes:
//   1. RV_ROOT must be set before running.
//   2. el2_param.vh / common_defines.vh / el2_pdef.vh are pre-generated
//      defaults in $RV_ROOT/configs/ — ensure they are present.
//   3. +define+RV_BUILD_AXI4 selects AXI4 bus mode in VeeR.
// ============================================================

// ---------- VeeR EL2 Include paths ----------
+incdir+$RV_ROOT/design/include
+incdir+$RV_ROOT/configs

// ---------- Project UART include path ----------
+incdir+../rtl/uart/include

// ============================================================
// VeeR EL2 RTL  (SystemVerilog)
// ============================================================

// -- Assert macros MUST come first (used by packages below) --
$RV_ROOT/design/lib/el2_assert.sv

// -- el2_pkg (defines el2_param_t) MUST come before el2_lockstep_pkg --
$RV_ROOT/design/include/el2_def.sv

// -- Packages --
$RV_ROOT/design/el2_mubi_pkg.sv
$RV_ROOT/design/el2_lockstep_pkg.sv
$RV_ROOT/design/lib/el2_lib.sv
$RV_ROOT/design/lib/el2_mem_if.sv
$RV_ROOT/design/lib/el2_prim_buf.sv
$RV_ROOT/design/lib/el2_prim_generic_buf.sv
$RV_ROOT/design/lib/el2_regfile_if.sv
-v $RV_ROOT/design/lib/beh_lib.sv
-v $RV_ROOT/design/lib/mem_lib.sv
$RV_ROOT/design/lib/ahb_to_axi4.sv
$RV_ROOT/design/lib/axi4_to_ahb.sv

// -- IFU --
$RV_ROOT/design/ifu/el2_ifu_aln_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_compress_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_ifc_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_bp_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_ic_mem.sv
$RV_ROOT/design/ifu/el2_ifu_mem_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_iccm_mem.sv
$RV_ROOT/design/ifu/el2_ifu.sv

// -- DEC --
$RV_ROOT/design/dec/el2_dec_decode_ctl.sv
$RV_ROOT/design/dec/el2_dec_gpr_ctl.sv
$RV_ROOT/design/dec/el2_dec_ib_ctl.sv
$RV_ROOT/design/dec/el2_dec_pmp_ctl.sv
$RV_ROOT/design/dec/el2_dec_tlu_ctl.sv
$RV_ROOT/design/dec/el2_dec_trigger.sv
$RV_ROOT/design/dec/el2_dec.sv

// -- EXU --
$RV_ROOT/design/exu/el2_exu_alu_ctl.sv
$RV_ROOT/design/exu/el2_exu_mul_ctl.sv
$RV_ROOT/design/exu/el2_exu_div_ctl.sv
$RV_ROOT/design/exu/el2_exu.sv

// -- LSU --
$RV_ROOT/design/lsu/el2_lsu.sv
$RV_ROOT/design/lsu/el2_lsu_clkdomain.sv
$RV_ROOT/design/lsu/el2_lsu_addrcheck.sv
$RV_ROOT/design/lsu/el2_lsu_lsc_ctl.sv
$RV_ROOT/design/lsu/el2_lsu_stbuf.sv
$RV_ROOT/design/lsu/el2_lsu_bus_buffer.sv
$RV_ROOT/design/lsu/el2_lsu_bus_intf.sv
$RV_ROOT/design/lsu/el2_lsu_ecc.sv
$RV_ROOT/design/lsu/el2_lsu_dccm_mem.sv
$RV_ROOT/design/lsu/el2_lsu_dccm_ctl.sv
$RV_ROOT/design/lsu/el2_lsu_trigger.sv

// -- DBG / DMI --
$RV_ROOT/design/dbg/el2_dbg.sv
$RV_ROOT/design/dmi/dmi_mux.v
$RV_ROOT/design/dmi/dmi_wrapper.v
$RV_ROOT/design/dmi/dmi_jtag_to_core_sync.v
$RV_ROOT/design/dmi/rvjtag_tap.v

// -- Top-level core + wrapper --
$RV_ROOT/design/el2_pmp.sv
$RV_ROOT/design/el2_pic_ctrl.sv
$RV_ROOT/design/el2_dma_ctrl.sv
$RV_ROOT/design/el2_mem.sv
$RV_ROOT/design/el2_veer.sv
$RV_ROOT/design/el2_veer_lockstep.sv
$RV_ROOT/design/el2_veer_wrapper.sv

// ============================================================
// Honours Project RTL  (Verilog)
// ============================================================

// -- Interconnect --
../rtl/interconnect/priority_encoder(1).v
../rtl/interconnect/arbiter(1).v
../rtl/interconnect/axi_interconnect(1).v
../rtl/interconnect/axi_interconnect_wrap_2x8.v

// -- UART --
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_receiver.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// -- Bridge --
../rtl/bridge/axi_to_axilite_uart_bridge.v

// -- Top modules --
../rtl/top/axi_interconnect_uart_top.v
../rtl/top/veer_uart_soc_top.v

// -- IFU ROM stub --
../rtl/memory/ifu_rom_stub.v

// ============================================================
// Testbench
// ============================================================
../tb/tb_veer_uart_soc.v
