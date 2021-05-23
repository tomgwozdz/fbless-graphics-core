# FPGA variables
PROJECT = fpga/vga
SOURCES= src/vga_timing.v src/fpga_top.v
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = fpga/icebreaker.pcf
ICEBREAKER_PACKAGE = sg48
SEED = 1


all: test_vga_timing test_vga_background test_vga_sprite test_vga_core

test_vga_timing:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s vga_timing -s dump -g2012 src/vga_timing.v test/dump_vga_timing.v src/
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_vga_timing vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

test_vga_background:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s vga_background -s dump -g2012 src/vga_background.v src/vga_pixel_selector.v test/dump_vga_background.v src/
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_vga_background vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

test_vga_sprite:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s vga_sprite -s dump -g2012 src/vga_sprite.v src/vga_pixel_selector.v test/dump_vga_sprite.v src/
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_vga_sprite vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

test_vga_core:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s vga_core -s dump -g2012 src/vga_core.v src/vga_timing.v src/vga_background.v src/vga_pixel_selector.v src/vga_sprite.v test/dump_vga_core.v src/
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_vga_core vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp

show_%: %.vcd %.gtkw
	gtkwave $^


# FPGA recipes

show_synth_%: src/%.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed"

%.json: $(SOURCES)
	yosys -l fpga/yosys.log -p 'synth_ice40 -top fpga_top -json $(PROJECT).json' $(SOURCES)

%.asc: %.json $(ICEBREAKER_PIN_DEF) 
	nextpnr-ice40 -l fpga/nextpnr.log --seed $(SEED) --freq 12 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<

%.bin: %.asc
	icepack $< $@

prog: $(PROJECT).bin
	sudo `which iceprog` $<


clean:
	rm -rf *vcd sim_build fpga/*log fpga/*bin test/__pycache__

.PHONY: clean
