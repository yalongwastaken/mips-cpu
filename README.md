# MIPS CPU

An 8-bit multicycle MIPS processor and its memory in SystemVerilog, built from
the SkyWater 130 nm standard cells and carried from RTL to a signed-off GDS with
open-source tools.

> **Status: in progress.**

## What It Does

The core runs a subset of the MIPS I instruction set with standard encodings:
`lb`, `sb`, `add`, `sub`, `and`, `or`, `slt`, `beq`, and `j`, with `$0` fixed at
zero. The data width, register count, PC width, and memory sizes are parameters
in `rtl/mips_pkg.sv`. Instructions are fetched as whole words from memory in
big-endian order, and each runs over several cycles of the state machine in
`rtl/mips_controller.sv`.

The memory, `rtl/mips_ram.sv`, behaves like a single-port SRAM: one read or
write per cycle, a write enable per byte, and read data on the next clock edge.
It is built from flip-flops because no open SRAM block for this process passes
the sign-off checks cleanly.

The program counter is wider than the data path, so code can fill the whole
memory; loads and stores compute their addresses with the data-width ALU, so
data lives in the part of memory those addresses reach. A store to the I/O port
address, `IoPortAddr` in `rtl/mips_pkg.sv`, also drives the chip's output port.

## Writing Programs

Programs are MIPS assembly, built with GNU binutils. The core has no branch
delay slots and no immediate arithmetic, so programs turn off the assembler's
reordering and load constants from memory, and immediates use only their low 8
bits. `dv/programs/common.inc` sets this up and provides the pass and fail
reporting the tests use. `dv/programs/link.ld` is the memory map.

## Results

`make syn` runs LibreLane through synthesis at the clock target in
`pnr/config.yaml` and prints the cell count and area; the full reports are under
`pnr/runs/syn/`.

`make pnr` runs the whole flow to a GDS at the same clock target and fails
unless the layout signs off clean at every timing corner: no DRC, LVS, XOR,
antenna, slew, load, fanout, setup, or hold violations. It then prints those
counts and the worst setup and hold slack, and renders the routing and power
grid to `pnr/runs/pnr/layout.png`. CI runs it on every pull request and
publishes the image from `main`:

![The chip's signal routing under its power grid](https://yalongwastaken.github.io/mips-cpu/layout.png)

## Repository Structure

```
mips-cpu/
├── rtl/              # the core, its memory, and the chip top
├── dv/               # unit testbenches and the whole-chip testbench
│   └── programs/     # MIPS test programs, memory map, shared macros
├── lint/             # lowRISC lint rules and formatter settings
├── pnr/              # the LibreLane flow, its sign-off report, and the render
├── .github/          # CI: lint, tests, layout, and the published image
└── Makefile
```

## Usage

### Requirements

- Verilator 5.032
- GNU binutils for `mips-linux-gnu`, 2.45.90
- verible v0.0-4296-g0f262651
- GNU Make

Synthesis and layout also need Docker, with LibreLane's image
`ghcr.io/librelane/librelane:3.0.16`. The first `make syn` or `make pnr`
downloads the SkyWater 130 PDK version LibreLane pins, a few gigabytes, into
`PDK_ROOT`, which defaults to `~/.ciel`.

### Running

```bash
make test                          # every unit test and test program
make run PROG=dv/programs/alu.s    # one program on the whole chip
make lint                          # verible with lowRISC's rules, then Verilator
make format                        # verible with lowRISC's settings
make syn                           # LibreLane through synthesis
make pnr                           # LibreLane through layout, sign-off, and the image
```

## Authors

**Anthony Yalong**

- Email: yalong.anthony123@gmail.com
- GitHub: [@yalongwastaken](https://github.com/yalongwastaken)

**Ben Sirota**

## License

MIT. See [LICENSE](LICENSE).
