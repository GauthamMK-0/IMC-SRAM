# ============================================================================
# IMC-SRAM Research Design — Verilator Build
# ============================================================================
#
# Usage:
#   make          — Build and run simulation
#   make build    — Build only
#   make run      — Run simulation (must build first)
#   make wave     — Open waveform viewer (if gtkwave installed)
#   make clean    — Remove build artifacts
# ============================================================================

TOP_MODULE  = imc_top
TB_CPP      = tb/imc_tb.cpp
RTL_DIR     = rtl
OBJ_DIR     = obj_dir

RTL_SRCS    = $(RTL_DIR)/imc_top.v        \
              $(RTL_DIR)/imc_controller.v  \
              $(RTL_DIR)/imc_sram_array.v  \
              $(RTL_DIR)/imc_bitcell.v     \
              $(RTL_DIR)/imc_dac.v         \
              $(RTL_DIR)/imc_mac_engine.v  \
              $(RTL_DIR)/imc_adc.v

VERILATOR_FLAGS = --cc --exe --trace --build \
                  -Wall -Wno-fatal           \
                  -I$(RTL_DIR)               \
                  --top-module $(TOP_MODULE)

.PHONY: all build run wave clean

all: build run

build:
	@echo "═══ Building IMC-SRAM with Verilator ═══"
	verilator $(VERILATOR_FLAGS) $(RTL_SRCS) $(TB_CPP)
	@echo "═══ Build complete ═══"

run: $(OBJ_DIR)/V$(TOP_MODULE)
	@echo ""
	@echo "═══ Running IMC-SRAM Simulation ═══"
	@./$(OBJ_DIR)/V$(TOP_MODULE)

wave: imc_sram_wave.vcd
	gtkwave imc_sram_wave.vcd &

clean:
	rm -rf $(OBJ_DIR) imc_sram_wave.vcd
	@echo "Cleaned."
