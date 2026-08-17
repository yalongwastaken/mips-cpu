# MIPS CPU

A multicycle processor implementing a subset of the MIPS instruction set, written in
Verilog and carried through a full ASIC flow — RTL, simulation, synthesis, scan
insertion, test pattern generation, and physical layout to GDS against the OSU/AMI 0.5 µm
standard cell library.

> **Status: complete.**

## What It Does

The design is a classic multicycle MIPS core: a datapath of muxes, flops, a register
file, an ALU, and a shared instruction/data memory, sequenced by an FSM controller that
drives one instruction across several clock cycles.

Two top-level variants are built from the same blocks:

- **`mini_mips_full_design`** — the functional core, used for RTL simulation and synthesis.
- **`mini_mips_test_design`** — the scan-inserted variant, used for ATPG and layout.

The flow is what makes this more than an RTL exercise. The design is simulated in
Xcelium, synthesized in Design Compiler against timing constraints, scan-stitched with
OSU scan cells, run through TetraMAX for test patterns and fault coverage, and placed and
routed to a GDS.

## Repository Structure

```
mips-cpu/
├── src/              # RTL — datapath, controller, ALU, ALU control, register
│                     # file, muxes, flops, instruction/data memory
├── tb/               # Testbenches — ALU, controller, datapath, register file,
│                     # and the full test design
├── syn/              # Synopsys Design Compiler
│   ├── synthesis.tcl # Synthesis script
│   ├── constraints_*.tcl
│   ├── netlists/     # Gate-level output
│   └── reports/      # Area, timing, and power reports
├── atpg/             # Synopsys TetraMAX — scan tb/src, patterns, coverage reports
├── layout/           # Physical design — run script, view file, and the GDS
├── utils/            # OSU 0.5 µm standard cells, scan cells, TetraMAX script
├── work/             # Simulation build directory
├── compile           # Compile RTL, testbenches, ATPG sources, and cells
├── run               # Run a simulation
└── synthesize        # Run synthesis
```

## Usage

The three scripts wrap the Cadence and Synopsys tools and expect them on `PATH`.

```bash
./compile                    # compile RTL, testbenches, ATPG sources, and cell models
./run <top_module>           # simulate a testbench
./run -atpg <top_module>     # simulate against the scan-inserted design
./synthesize <top_module>    # synthesize; add -gui for the Design Compiler GUI
```

Physical design is driven separately from `layout/run_layout`.

## Author

**Anthony Yalong**
- Email: yalong.anthony123@gmail.com
- GitHub: [@yalongwastaken](https://github.com/yalongwastaken)
