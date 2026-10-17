// ============================================================
// run_soc.f — VCS filelist for Full SoC Top (soc_top.v)
//
// Design hierarchy:
//   soc_top                                 (Full SoC top)
//     ├── el2_veer_wrapper                  (VeeR EL2 RV32IMC core, AXI4)
//     ├── ifu_rom_stub                      (Boot ROM @ 0x8000_0000)
//     └── axi_interconnect_uart_top         (2x8 Crossbar Subsystem)
//           ├── M00: AES-128 Engine         (0x0000_0000)
//           ├── M01: DMA Controller         (0x0100_0000)
//           ├── M02: SPI Master             (0x0200_0000)
//           ├── M03: UART                   (0x0300_0000)
//           ├── M04: Timer EF_TCC32         (0x0400_0000)
//           ├── M05: GPIO EF_GPIO8          (0x0500_0000)
//           └── M06: AXI SRAM 64KB          (0x0600_0000)
// ============================================================

// ============================================================
// 1. VeeR EL2 RISC-V Core RTL
// ============================================================
$RV_ROOT/design/lib/el2_assert.sv
$RV_ROOT/design/include/el2_def.sv
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

$RV_ROOT/design/ifu/el2_ifu_aln_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_compress_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_ifc_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_bp_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_ic_mem.sv
$RV_ROOT/design/ifu/el2_ifu_mem_ctl.sv
$RV_ROOT/design/ifu/el2_ifu_iccm_mem.sv
$RV_ROOT/design/ifu/el2_ifu.sv

$RV_ROOT/design/dec/el2_dec_decode_ctl.sv
$RV_ROOT/design/dec/el2_dec_gpr_ctl.sv
$RV_ROOT/design/dec/el2_dec_ib_ctl.sv
$RV_ROOT/design/dec/el2_dec_pmp_ctl.sv
$RV_ROOT/design/dec/el2_dec_tlu_ctl.sv
$RV_ROOT/design/dec/el2_dec_trigger.sv
$RV_ROOT/design/dec/el2_dec.sv

$RV_ROOT/design/exu/el2_exu_alu_ctl.sv
$RV_ROOT/design/exu/el2_exu_mul_ctl.sv
$RV_ROOT/design/exu/el2_exu_div_ctl.sv
$RV_ROOT/design/exu/el2_exu.sv

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

$RV_ROOT/design/dbg/el2_dbg.sv
$RV_ROOT/design/dmi/dmi_mux.v
$RV_ROOT/design/dmi/dmi_wrapper.v
$RV_ROOT/design/dmi/dmi_jtag_to_core_sync.v
$RV_ROOT/design/dmi/rvjtag_tap.v

$RV_ROOT/design/el2_pmp.sv
$RV_ROOT/design/el2_pic_ctrl.sv
$RV_ROOT/design/el2_dma_ctrl.sv
$RV_ROOT/design/el2_mem.sv
$RV_ROOT/design/el2_veer.sv
$RV_ROOT/design/el2_veer_lockstep.sv
$RV_ROOT/design/el2_veer_wrapper.sv

// ============================================================
// 2. AXI Interconnect Fabric
// ============================================================
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x8.v

// ============================================================
// 3. Peripheral IP Blocks & Bridges
// ============================================================
// ---- M00: AES-128 Engine ----
../rtl/aes/aes_rcon.v
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v
../rtl/aes/aes_axi_slave.v
../rtl/bridge/axi_to_axilite_aes_bridge.v

// ---- M01: DMA Controller (CSR + Master) ----
../rtl/dma/bus_arch_sv_pkg/amba_axi_pkg.sv
../rtl/dma/bus_arch_sv_pkg/amba_ahb_pkg.sv
../rtl/dma/rggen-verilog-rtl/rggen_adapter_common.v
../rtl/dma/rggen-verilog-rtl/rggen_mux.v
../rtl/dma/rggen-verilog-rtl/rggen_or_reducer.v
../rtl/dma/rggen-verilog-rtl/rggen_address_decoder.v
../rtl/dma/rggen-verilog-rtl/rggen_bit_field.v
../rtl/dma/rggen-verilog-rtl/rggen_bit_field_w01trg.v
../rtl/dma/rggen-verilog-rtl/rggen_register_common.v
../rtl/dma/rggen-verilog-rtl/rggen_default_register.v
../rtl/dma/rggen-verilog-rtl/rggen_indirect_register.v
../rtl/dma/rggen-verilog-rtl/rggen_external_register.v
../rtl/dma/rggen-verilog-rtl/rggen_axi4lite_adapter.v
../rtl/dma/rggen-verilog-rtl/rggen_axi4lite_bridge.v
../rtl/dma/rggen-verilog-rtl/rggen_axi4lite_skid_buffer.v
../rtl/dma/csr_out/csr_dma.v
../rtl/dma/rtl/inc/dma_utils_pkg.sv
../rtl/dma/rtl/dma_fifo.sv
../rtl/dma/rtl/dma_axi_if.sv
../rtl/dma/rtl/dma_streamer.sv
../rtl/dma/rtl/dma_fsm.sv
../rtl/dma/rtl/dma_func_wrapper.sv
../rtl/dma/rtl/dma_axi_wrapper.sv
../rtl/dma/dma_axi_flat_wrapper.sv

// ---- M02: SPI Master ----
../rtl/spi/SPI_Master.v
../rtl/spi/SPI_Master_With_Single_CS.v
../rtl/spi/spi_axi_top.v

// ---- M03: UART ----
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v
../rtl/bridge/axi_to_axilite_uart_bridge.v

// ---- M04: Timer EF_TCC32 ----
../rtl/timer/EF_TCC32.v
../rtl/timer/EF_TCC32_axi.v
../rtl/bridge/axi_to_axilite_timer_bridge.v

// ---- M05: GPIO EF_GPIO8 ----
../rtl/gpio/ef_util_sync.v
../rtl/gpio/EF_GPIO8.v
../rtl/gpio/EF_GPIO8_axi.v
../rtl/bridge/axi_to_axilite_gpio_bridge.v

// ---- M06: AXI SRAM 64KB ----
../rtl/memory/axi_sram.v

// ============================================================
// 4. Memory & Top Modules
// ============================================================
../rtl/memory/ifu_rom_stub.v
../rtl/top/axi_interconnect_uart_top.v
../rtl/soc_top/soc_top.v

// ============================================================
// 5. Testbench
// ============================================================
../tb/soc/tb_soc_top.v
