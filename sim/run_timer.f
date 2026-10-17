// ============================================================
// run_timer.f
// VCS filelist — Timer (EF_TCC32) AXI standalone simulation
//
// Usage (from sim/ directory):
//   vcs -full64 -debug_access+all -kdb -sverilog \
//       -timescale=1ns/1ps \
//       -f run_timer.f -top tb_EF_TCC32_axi \
//       -P $VERDI_PLI/novas.tab \
//       -LDFLAGS "-Wl,-rpath,$VERDI_PLI" \
//       $VERDI_PLI/pli.a \
//       -o simv_timer && ./simv_timer
// ============================================================

// ---- Timer core RTL ----
../rtl/timer/EF_TCC32.v

// ---- AXI Wrapper ----
../rtl/timer/EF_TCC32_axi.v

// ---- Testbench ----
../tb/timer/tb_EF_TCC32_axi.v
