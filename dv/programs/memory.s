# Byte loads and stores in all four lanes of a memory word, a store that must
# leave its neighbours alone, and base-plus-offset addressing.

        .include "common.inc"

        .data
        # one memory word, so its four bytes are the word's four lanes
        .balign 4
scratch_word:
        .space  4

        .text
        .globl  _start
_start:
        load_constant $1, 11
        load_constant $2, 22
        load_constant $3, 23
        load_constant $4, 24
        sb      $1, %lo(scratch_word + 0)($0)
        sb      $2, %lo(scratch_word + 1)($0)
        sb      $3, %lo(scratch_word + 2)($0)
        sb      $4, %lo(scratch_word + 3)($0)

        lb      $5, %lo(scratch_word + 0)($0)
        check_equal $5, $1, 2
        lb      $5, %lo(scratch_word + 1)($0)
        check_equal $5, $2, 3
        lb      $5, %lo(scratch_word + 2)($0)
        check_equal $5, $3, 4
        lb      $5, %lo(scratch_word + 3)($0)
        check_equal $5, $4, 5

        sb      $0, %lo(scratch_word + 1)($0)
        lb      $5, %lo(scratch_word + 0)($0)
        check_equal $5, $1, 6
        lb      $5, %lo(scratch_word + 1)($0)
        check_equal $5, $0, 7
        lb      $5, %lo(scratch_word + 2)($0)
        check_equal $5, $3, 8
        lb      $5, %lo(scratch_word + 3)($0)
        check_equal $5, $4, 9

        load_constant $6, 16
        lb      $5, %lo(scratch_word - 16)($6)
        check_equal $5, $1, 10

        pass
