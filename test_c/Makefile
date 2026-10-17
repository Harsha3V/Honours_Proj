# =============================================================================
# Makefile — C Test for VeeR EL2 Secure Gateway SoC
# =============================================================================

.PHONY: all clean dump

all:
	@./run_c_test.sh

dump: all
	@cat boot.dump | less

clean:
	@rm -f boot.elf boot.dump boot.bin boot.hex
	@echo "Cleaned C test build artifacts."
