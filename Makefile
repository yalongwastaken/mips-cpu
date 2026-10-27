VERILATOR      ?= verilator
VERIBLE_FORMAT ?= verible-verilog-format
VERIBLE_LINT   ?= verible-verilog-lint
MIPS_AS        ?= mips-linux-gnu-as
MIPS_LD        ?= mips-linux-gnu-ld
MIPS_OBJCOPY   ?= mips-linux-gnu-objcopy
# LibreLane installs the SkyWater 130 PDK version it pins here on first use
PDK_ROOT       ?= $(HOME)/.ciel
LIBRELANE_IMAGE ?= ghcr.io/librelane/librelane:3.0.16

# Verilator needs the package before the modules that import it
RTL := rtl/mips_pkg.sv $(filter-out rtl/mips_pkg.sv,$(wildcard rtl/*.sv))

UNIT_TESTS := tb_mips_alu tb_mips_decoder tb_mips_ram tb_mips_register_file
TESTBENCHES := $(addprefix dv/,$(addsuffix .sv,$(UNIT_TESTS) tb_mips_top))
PROGRAMS := $(filter-out dv/programs/crt0.s,$(wildcard dv/programs/*.s))

BUILD := build
SYN_RUN := pnr/runs/syn
PNR_RUN := pnr/runs/pnr
VERILATOR_FLAGS := --binary --timing --timescale 1ns/1ps --assert -Wall dv/verilator.vlt

# LibreLane and its tools run from the image; the repository and the PDK are
# mounted at their own paths so the paths in its reports match the host's
IN_LIBRELANE := docker run --rm -u $$(id -u):$$(id -g) -e HOME=/tmp -v $(CURDIR):$(CURDIR) \
                -v $(PDK_ROOT):$(PDK_ROOT) -w $(CURDIR) $(LIBRELANE_IMAGE)

.PHONY: test run lint format syn pnr clean

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
	$(VERILATOR) --lint-only --timing -Wall dv/verilator.vlt --top-module mips_top $(RTL)

format:
	$(VERIBLE_FORMAT) --flagfile=lint/lowrisc-styleguide.verible_format --inplace $(RTL) $(TESTBENCHES)

syn: | $(PDK_ROOT)
	$(IN_LIBRELANE) librelane --pdk-root $(PDK_ROOT) --run-tag syn --overwrite --to Checker.NetlistAssignStatements pnr/config.yaml
	@grep -E 'cells$$|Chip area' $(SYN_RUN)/*-yosys-synthesis/reports/stat.rpt

pnr: | $(PDK_ROOT)
	$(IN_LIBRELANE) librelane --pdk-root $(PDK_ROOT) --run-tag pnr --overwrite pnr/config.yaml
	$(IN_LIBRELANE) python3 pnr/report_signoff.py $(PNR_RUN)/final/metrics.json
	$(IN_LIBRELANE) klayout -b -r pnr/render_layout.py -rd run=$(PNR_RUN) -rd png=$(PNR_RUN)/layout.png

clean:
	rm -rf $(BUILD) pnr/runs

$(BUILD)/%/sim: dv/%.sv $(RTL) dv/verilator.vlt
	@mkdir -p $(@D)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $* -Mdir $(BUILD)/$* -o sim $(RTL) $< >/dev/null

$(BUILD)/programs/crt0.o: dv/programs/crt0.s
	@mkdir -p $(@D)
	$(MIPS_AS) -EB -march=mips1 -mno-shared -call_nonpic -o $@ $<

$(BUILD)/programs/%.o: dv/programs/%.s dv/programs/common.inc
	@mkdir -p $(@D)
	$(MIPS_AS) -EB -march=mips1 -mno-shared -call_nonpic -I dv/programs -o $@ $<

$(BUILD)/programs/%.elf: $(BUILD)/programs/%.o $(BUILD)/programs/crt0.o dv/programs/link.ld
	$(MIPS_LD) -EB --no-warn-rwx-segments -T dv/programs/link.ld -o $@ $(BUILD)/programs/crt0.o $<

# 32-bit words addressed by word, the layout the memory's array takes
$(BUILD)/programs/%.hex: $(BUILD)/programs/%.elf
	$(MIPS_OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Docker would create a missing mount point owned by root, and LibreLane could
# not install the PDK into it
$(PDK_ROOT):
	mkdir -p $@
