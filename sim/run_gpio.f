// ============================================================
// run_gpio.f
// VCS filelist — GPIO (EF_GPIO8) AXI standalone simulation
//
// Usage (from sim/ directory):
//   vcs -full64 -debug_access+all -kdb -sverilog \
//       -timescale=1ns/1ps \
//       -f run_gpio.f -top tb_EF_GPIO8_axi \
//       -P $VERDI_PLI/novas.tab \
//       -LDFLAGS "-Wl,-rpath,$VERDI_PLI" \
//       $VERDI_PLI/pli.a \
//       -o simv_gpio && ./simv_gpio
// ============================================================

// ---- GPIO synchronizer utility ----
../rtl/gpio/ef_util_sync.v

// ---- GPIO core RTL ----
../rtl/gpio/EF_GPIO8.v

// ---- AXI Wrapper ----
../rtl/gpio/EF_GPIO8_axi.v

// ---- Testbench ----
../tb/gpio/tb_EF_GPIO8_axi.v
