# All 32 registers are distinct and $0 ignores writes. $31 is the reporting
# register, so the check covers $1 through $30.

        .include "common.inc"

        .text
        .globl  _start
_start:
        .irp    n, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30
        load_constant $\n, \n
        .endr

        add     $0, $1, $2
        load_constant $31, 0
        check_equal $0, $31, 2

        .irp    n, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30
        load_constant $31, \n
        check_equal $\n, $31, 3
        .endr

        pass
