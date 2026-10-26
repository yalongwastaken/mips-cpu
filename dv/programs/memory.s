# Byte loads and stores in all four lanes of a memory word, a store that must
# leave its neighbours alone, and base-plus-offset addressing.

        .include "common.inc"

        .equ    SCRATCH, 0xF0

        .text
        .globl  _start
_start:
        load_constant $1, 11
        load_constant $2, 22
        load_constant $3, 23
        load_constant $4, 24
        sb      $1, SCRATCH + 0($0)
        sb      $2, SCRATCH + 1($0)
        sb      $3, SCRATCH + 2($0)
        sb      $4, SCRATCH + 3($0)

        lb      $5, SCRATCH + 0($0)
        check_equal $5, $1, 2
        lb      $5, SCRATCH + 1($0)
        check_equal $5, $2, 3
        lb      $5, SCRATCH + 2($0)
        check_equal $5, $3, 4
        lb      $5, SCRATCH + 3($0)
        check_equal $5, $4, 5

        sb      $0, SCRATCH + 1($0)
        lb      $5, SCRATCH + 0($0)
        check_equal $5, $1, 6
        lb      $5, SCRATCH + 1($0)
        check_equal $5, $0, 7
        lb      $5, SCRATCH + 2($0)
        check_equal $5, $3, 8

        load_constant $6, 16
        lb      $5, (SCRATCH - 16)($6)
        check_equal $5, $1, 9

        pass
