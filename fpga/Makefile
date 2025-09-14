pcf_file = sim/io.pcf
DESIGN ?= core
HDL_PATH := src/$(DESIGN)
TESTS_PATH := tests/tb/$(DESIGN)
SIM_PATH := sim/$(DESIGN)
SIM_DIR := sim/
BUILD_DIR = build

# tool defs
RESIZE_HEXFILE := tools/resize_hexfile.py

#IVERILOG_WARNINGS := -Wanachronisms -Wimplicit -Wimplicit-dimensions -Wmacro-replacement -Wportbind -Wselect-range -Wsensitivity-entire-array
IVERILOG_WARNINGS := -Wall -Wno-timescale

ICELINK_DIR=$(shell df | grep iCELink | awk '{print $$6}')
${warning iCELink path: $(ICELINK_DIR)}

build:
	yosys -p "synth_ice40 -json $(design).json" $(design).v
	nextpnr-ice40 \
		--up5k \
		--package sg48 \
		--json $(design).json \
		--pcf $(pcf_file) \
		--asc $(design).asc
	icepack $(design).asc $(design).bin

prog_flash:
	@if [ -d '$(ICELINK_DIR)' ]; \
     	then \
		cp $(design).bin $(ICELINK_DIR); \
     	else \
		echo "iCELink not found"; \
		exit 1; \
     	fi

vis:
	yosys -p "read_verilog leds.v; hierarchy -check; proc; opt; fsm; opt; memory; opt; show -prefix leds -format svg" leds.v

.PHONY: sim
sim:
	mkdir -p $(SIM_DIR)
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o $(BUILD_DIR)/$(DESIGN).elf $(SIM_DIR)/instrmem.S
	riscv64-unknown-elf-objcopy -S -O verilog $(BUILD_DIR)/$(DESIGN).elf $(BUILD_DIR)/$(DESIGN)_raw.hex
	$(RESIZE_HEXFILE) -w 4 -i $(BUILD_DIR)/$(DESIGN)_raw.hex -o $(BUILD_DIR)/$(DESIGN).hex -r
	iverilog $(IVERILOG_WARNINGS) -f "$(SIM_DIR)/$(DESIGN).f" -s '$(DESIGN)_tb' -o $(BUILD_DIR)/a.out
	vvp  $(BUILD_DIR)/a.out -fst

waves:
	gtkwave $(BUILD_DIR)/$(DESIGN)_tb.fst

format:
	verible-verilog-format $(SRC_FILES)

clean:
	rm -rf $(BUILD_DIR)
