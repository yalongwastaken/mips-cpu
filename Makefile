VERILATOR      ?= verilator
VERIBLE_FORMAT ?= verible-verilog-format
VERIBLE_LINT   ?= verible-verilog-lint
MIPS_AS        ?= mips-linux-gnu-as
MIPS_LD        ?= mips-linux-gnu-ld
MIPS_OBJCOPY   ?= mips-linux-gnu-objcopy
PDK_ROOT       ?= $(HOME)/.ciel

SRAM_MODEL := $(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v

RTL := rtl/mips_pkg.sv \
       rtl/mips_alu.sv \
       rtl/mips_decoder.sv \
       rtl/mips_register_file.sv \
       rtl/mips_controller.sv \
       rtl/mips_datapath.sv \
       rtl/mips_top.sv

UNIT_TESTS := tb_mips_alu tb_mips_decoder tb_mips_register_file
TESTBENCHES := $(addprefix dv/,$(addsuffix .sv,$(UNIT_TESTS) tb_mips_top))
PROGRAMS := $(filter-out dv/programs/crt0.s,$(wildcard dv/programs/*.s))

BUILD := build
VERILATOR_FLAGS := --binary --timing --timescale 1ns/1ps --assert -Wall dv/verilator.vlt

.PHONY: test run lint format clean

test: $(UNIT_TESTS:%=$(BUILD)/%/sim) $(BUILD)/tb_mips_top/sim $(PROGRAMS:dv/programs/%.s=$(BUILD)/programs/%.hex)
	@failed=0; \
	for t in $(UNIT_TESTS); do $(BUILD)/$$t/sim || failed=1; done; \
	for p in $(PROGRAMS:dv/programs/%.s=$(BUILD)/programs/%.hex); do \
	  $(BUILD)/tb_mips_top/sim +program=$$p || failed=1; \
	done; \
	exit $$failed

run: $(BUILD)/tb_mips_top/sim $(PROG:dv/programs/%.s=$(BUILD)/programs/%.hex)
	@test -n "$(PROG)" || { echo "usage: make run PROG=dv/programs/<name>.s" >&2; exit 2; }
	$(BUILD)/tb_mips_top/sim +program=$(PROG:dv/programs/%.s=$(BUILD)/programs/%.hex)

lint:
	$(VERIBLE_LINT) --rules_config=lint/lowrisc-styleguide.rules.verible_lint $(RTL) $(TESTBENCHES)
	$(VERILATOR) --lint-only --timing -Wall dv/verilator.vlt --top-module mips_top $(RTL) $(SRAM_MODEL)

format:
	$(VERIBLE_FORMAT) --flagfile=lint/lowrisc-styleguide.verible_format --inplace $(RTL) $(TESTBENCHES)

clean:
	rm -rf $(BUILD)

$(BUILD)/%/sim: dv/%.sv $(RTL) $(SRAM_MODEL) dv/verilator.vlt
	@mkdir -p $(@D)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $* -Mdir $(BUILD)/$* -o sim $(RTL) $(SRAM_MODEL) $< >/dev/null

$(BUILD)/programs/crt0.o: dv/programs/crt0.s
	@mkdir -p $(@D)
	$(MIPS_AS) -EB -march=mips1 -mno-shared -call_nonpic -o $@ $<

$(BUILD)/programs/%.o: dv/programs/%.s dv/programs/common.inc
	@mkdir -p $(@D)
	$(MIPS_AS) -EB -march=mips1 -mno-shared -call_nonpic -I dv/programs -o $@ $<

$(BUILD)/programs/%.elf: $(BUILD)/programs/%.o $(BUILD)/programs/crt0.o dv/programs/link.ld
	$(MIPS_LD) -EB --no-warn-rwx-segments -T dv/programs/link.ld -o $@ $(BUILD)/programs/crt0.o $<

# 32-bit words addressed by word, the layout the SRAM model's array takes
$(BUILD)/programs/%.hex: $(BUILD)/programs/%.elf
	$(MIPS_OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(SRAM_MODEL):
	@echo "no SkyWater 130 PDK at PDK_ROOT=$(PDK_ROOT): install it with ciel (see README) or set PDK_ROOT" >&2; exit 1
