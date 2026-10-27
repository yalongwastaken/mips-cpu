/*
 * Reset jumps from the chip's reset PC to the program. Data follows, below the
 * I/O port, where data addresses reach; code starts where they stop reaching,
 * so no load or store can touch it. The constants come from the SystemVerilog
 * packages, written to package_constants.inc by dv/export_package_constants.sv.
 */
INCLUDE package_constants.inc

OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0, LENGTH = MEMORY_BYTES
}

SECTIONS
{
  .text.reset RESET_PC : { *(.text.reset) } > RAM
  .data : { *(.data.constants) *(.data) } > RAM
  ASSERT(. <= IO_PORT_ADDR, "data must end below the I/O port")
  .text DATA_REACH_BYTES : { *(.text) } > RAM
  /DISCARD/ : { *(.reginfo) *(.MIPS.*) *(.gnu.attributes) *(.pdr) *(.bss) }
}
