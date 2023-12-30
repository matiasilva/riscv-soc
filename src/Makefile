pcf_file = io.pcf

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
	iverilog $(design).v $(design)_tb.v
	vvp  a.out

clean:
	rm -rf $(design).blif $(design).asc $(design).json $(design).bin $(design).out $(design)_tb.lxt2 $(design)_tb.vcd