# Every R-type operation, including signed slt across the overflow boundary
# and 8-bit wraparound.

        .include "common.inc"

        .data
minus_one:
        .byte   0xFF
most_negative:
        .byte   0x80
most_positive:
        .byte   0x7F

        .text
        .globl  _start
_start:
        load_constant $1, 5
        load_constant $2, 3

        load_constant $9, 8
        add     $3, $1, $2
        check_equal $3, $9, 2

        load_constant $9, 2
        sub     $3, $1, $2
        check_equal $3, $9, 3

        load_constant $9, 1
        and     $3, $1, $2
        check_equal $3, $9, 4

        load_constant $9, 7
        or      $3, $1, $2
        check_equal $3, $9, 5

        slt     $3, $1, $2
        check_equal $3, $0, 6

        load_constant $9, 1
        slt     $3, $2, $1
        check_equal $3, $9, 7

        lb      $4, %lo(minus_one)($0)
        load_constant $5, 1
        slt     $3, $4, $5
        check_equal $3, $9, 8

        # -128 - 127 wraps to a positive difference, but -128 is still less
        lb      $6, %lo(most_negative)($0)
        lb      $7, %lo(most_positive)($0)
        slt     $3, $6, $7
        check_equal $3, $9, 9

        add     $3, $4, $5
        check_equal $3, $0, 10

        pass
