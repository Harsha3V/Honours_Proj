# =============================================================================
# Makefile — SystemVerilog Simulation Test for VeeR EL2 SoC
# =============================================================================

.PHONY: all run dump verdi clean

all: run

run:
	@./run_sv_test.sh

dump:
	@./run_sv_test.sh +dump

verdi:
	@verdi -sv -f ../sim/run_soc.f -top tb_soc_top -ssf simv_soc_top.vcd &

clean:
	@rm -rf simv_soc_tb simv_soc_tb.daidir csrc ucli.key *.vcd *.fsdb
	@echo "Cleaned SV simulation artifacts."
