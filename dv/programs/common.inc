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
        .if     ((\value) < 0) || ((\value) >= CONSTANT_COUNT)
        .error  "load_constant \value is outside the constant table"
        .endif
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

        # code numbers the failed check; dv/mips_test_pkg.sv says which values
        # tb_mips_top reads as no verdict and as a pass
        .macro  fail code
        .if     ((\code) == 0) || ((\code) == PASS_CODE)
        .error  "fail \code: 0 and PASS_CODE are not failure codes"
        .endif
        report  \code
        .endm

        .macro  check_equal rs, rt, code
        beq     \rs, \rt, 98f
        fail    \code
98:
        .endm
