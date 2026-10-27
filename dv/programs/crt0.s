# Linked into every test program: the reset jump and the constant table.

        .include "common.inc"

        .section .text.reset, "ax"
        j       _start

        .section .data.constants, "aw"
        .globl  constant_table
constant_table:
        .set    constant_value, 0
        .rept   CONSTANT_COUNT
        .byte   constant_value
        .set    constant_value, constant_value + 1
        .endr
