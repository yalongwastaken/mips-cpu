# Included by every test program. The core has no branch delay slots and no
# immediate instructions, so programs keep the assembler from reordering and
# load constants from the table in crt0.s. Register $31 is reserved for
# reporting the verdict.

        .set    noreorder
        .set    noat

        .equ    CONSTANT_TABLE, 0xC0    # the byte at CONSTANT_TABLE + n holds n
        .equ    IO_PORT, 0xFF

        .macro  load_constant reg, value
        lb      \reg, (CONSTANT_TABLE + \value)($0)
        .endm

        .macro  report code
        load_constant $31, \code
        sb      $31, IO_PORT($0)
99:     j       99b
        .endm

        .macro  pass
        report  1
        .endm

        # failure codes run from 2 to 31, the size of the constant table
        .macro  check_equal rs, rt, code
        beq     \rs, \rt, 98f
        report  \code
98:
        .endm
