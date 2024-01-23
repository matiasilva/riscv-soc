pcf_file = sim/io.pcf
DESIGN ?= core
HDL_PATH := src/$(DESIGN)
TESTS_PATH := tests/tb/$(DESIGN)
SIM_PATH := sim/$(DESIGN)
BUILD_DIR = build

IVERILOG_WARNINGS := -Wanachronisms -Wimplicit -Wimplicit-dimensions -Wmacro-replacement -Wportbind -Wselect-range -Wsensitivity-entire-array

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
	mkdir -p $(BUILD_DIR)
	iverilog $(IVERILOG_WARNINGS) -f $(SIM_PATH).f -s $(DESIGN)_tb -o $(BUILD_DIR)/a.out
	vvp  $(BUILD_DIR)/a.out -fst

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)