# beq taken and not taken, forward and backward, and j forward and backward.

        .include "common.inc"

        .text
        .globl  _start
_start:
        load_constant $1, 4
        load_constant $2, 4
        load_constant $3, 9
        load_constant $5, 1

        beq     $1, $2, 1f
        fail    2
1:
        beq     $1, $3, 2f
        j       3f
2:
        fail    3
3:
        # count up with a backward j
        add     $4, $0, $0
4:
        add     $4, $4, $5
        beq     $4, $1, 5f
        j       4b
5:
        check_equal $4, $1, 4

        # count up with a backward beq
        add     $6, $0, $0
6:
        add     $6, $6, $5
        slt     $7, $6, $1
        beq     $7, $5, 6b
        check_equal $6, $1, 5

        j       7f
        fail    6
7:
        pass
