/*
 * Data must sit in the first 256 bytes, where the core's 8-bit data addresses
 * reach, so code starts above it. Reset begins at address 0, which only jumps
 * to the program.
 */
OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x000, LENGTH = 1K
}

SECTIONS
{
  .text.reset 0x000 : { *(.text.reset) } > RAM
  .data       0x0C0 : { *(.data.constants) *(.data) } > RAM
  .text       0x100 : { *(.text) } > RAM
  /DISCARD/ : { *(.reginfo) *(.MIPS.*) *(.gnu.attributes) *(.pdr) *(.bss) }
}
