// ============================================================
// run_spi.f
// VCS filelist — SPI AXI standalone simulation
//
// Usage (from sim/ directory):
//   vcs -full64 -debug_access+all -kdb -sverilog \
//       -timescale=1ns/1ps \
//       -f run_spi.f -top tb_spi_axi_top \
//       -P $VERDI_PLI/novas.tab \
//       -LDFLAGS "-Wl,-rpath,$VERDI_PLI" \
//       $VERDI_PLI/pli.a \
//       -o simv_spi && ./simv_spi
// ============================================================

// ---- SPI Master RTL ----
../rtl/spi/SPI_Master.v
../rtl/spi/SPI_Master_With_Single_CS.v

// ---- AXI Wrapper ----
../rtl/spi/spi_axi_top.v

// ---- Testbench ----
../tb/spi/tb_spi_axi_top.v
