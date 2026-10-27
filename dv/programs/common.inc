# Included by every test program and by crt0.s. The core has no branch delay
# slots and no immediate instructions, so programs keep the assembler from
# reordering and load constants from the table in crt0.s. Register $31 is
# reserved for reporting the verdict.

        .set    noreorder
        .set    noat

        # the constants shared with the chip and tb_mips_top, written from the
        # SystemVerilog packages by dv/export_package_constants.sv
        .include "package_constants.inc"

        # the byte at constant_table + n holds n
        .equ    CONSTANT_COUNT, 32

        .macro  load_constant reg, value
        lb      \reg, %lo(constant_table + (\value))($0)
        .endm

        .macro  report code
        load_constant $31, \code
        sb      $31, IO_PORT_ADDR($0)
99:     j       99b
        .endm

        .macro  pass
        report  PASS_CODE
        .endm

        # failure codes are check numbers above PASS_CODE, below CONSTANT_COUNT
        .macro  check_equal rs, rt, code
        beq     \rs, \rt, 98f
        report  \code
98:
        .endm
