pcf_file = sim/io.pcf
HDL_PATH = src/$(DESIGN)
BUILD_DIR = build

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

sim:
	mkdir $(BUILD_DIR)
	iverilog $(HDL_PATH).v $(HDL_PATH)_tb.v -o $(BUILD_DIR)/a.out
	vvp  $(BUILD_DIR)/a.out

clean:
	rm -rf $(BUILD_DIR)