// ============================================================
// run_dma.f
// VCS filelist — DMA flat wrapper compile (used in full SoC)
//
// Usage (from sim/ directory):
//   +incdir+../rtl/dma/rtl/inc
//   +incdir+../rtl/dma/rggen-verilog-rtl
//   -f run_dma.f
// ============================================================

// ---- rggen register RTL ----
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

// ---- DMA CSR (pure Verilog — no rggen_rtl_pkg needed) ----
../rtl/dma/csr_out/csr_dma.v

// ---- DMA RTL core ----
../rtl/dma/rtl/inc/dma_utils_pkg.sv
../rtl/dma/rtl/dma_fifo.sv
../rtl/dma/rtl/dma_axi_if.sv
../rtl/dma/rtl/dma_streamer.sv
../rtl/dma/rtl/dma_fsm.sv
../rtl/dma/rtl/dma_func_wrapper.sv
../rtl/dma/rtl/dma_axi_wrapper.sv

// ---- Flat wrapper (custom — exposes flat AXI wires for interconnect) ----
../rtl/dma/dma_axi_flat_wrapper.sv
