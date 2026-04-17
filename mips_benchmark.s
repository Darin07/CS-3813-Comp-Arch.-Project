# ============================================================
# CS-3813 Final Project — MIPS Benchmark
# MIPS vs RISC Energy Efficiency
# Group: Darin, Fady & Tonye
#
# Tests: Addition, Subtraction, Multiplication, Division, Modulo
# Each operation runs ITERATIONS times in a loop.
# The program prints the result of each operation so the
# assembler actually executes all instructions (no dead code).
# Instruction counts are tracked manually via comments.
# ============================================================

.data
    ITERATIONS = 100            # loop count — change to scale test

    operandA:   .word  47       # test operand A
    operandB:   .word  6        # test operand B

    # ── Output strings ──
    sep:        .asciiz "-----------------------------\n"
    title:      .asciiz "CS-3813 MIPS Arithmetic Benchmark\n"
    lbl_add:    .asciiz "[ADD]  47 + 6 = "
    lbl_sub:    .asciiz "[SUB]  47 - 6 = "
    lbl_mul:    .asciiz "[MUL]  47 * 6 = "
    lbl_div:    .asciiz "[DIV]  47 / 6 = "
    lbl_mod:    .asciiz "[MOD]  47 % 6 = "
    lbl_iter:   .asciiz "Iterations per operation: "
    lbl_icnt:   .asciiz "\nInstruction analysis (1 iteration):\n"
    lbl_add_i:  .asciiz "  ADD  instructions: 1  | cycles: 1\n"
    lbl_sub_i:  .asciiz "  SUB  instructions: 1  | cycles: 1\n"
    lbl_mul_i:  .asciiz "  MUL  instructions: 2  | cycles: ~16 avg (HI/LO stall)\n"
    lbl_div_i:  .asciiz "  DIV  instructions: 2  | cycles: ~35 avg (pipeline stall)\n"
    lbl_mod_i:  .asciiz "  MOD  instructions: 2  | cycles: ~36 avg (DIV + MFHI)\n"
    newline:    .asciiz "\n"

.text
.globl main

# ============================================================
# MAIN
# ============================================================
main:
    # Print title
    li    $v0, 4
    la    $a0, title
    syscall
    li    $v0, 4
    la    $a0, sep
    syscall

    # Print iteration count
    li    $v0, 4
    la    $a0, lbl_iter
    syscall
    li    $v0, 1
    li    $a0, ITERATIONS
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall
    li    $v0, 4
    la    $a0, sep
    syscall

    # Load operands
    lw    $s0, operandA         # $s0 = 47
    lw    $s1, operandB         # $s1 = 6

    # ── Run each benchmark subroutine ──
    jal   bench_add
    jal   bench_sub
    jal   bench_mul
    jal   bench_div
    jal   bench_mod

    # Print instruction count analysis
    li    $v0, 4
    la    $a0, sep
    syscall
    li    $v0, 4
    la    $a0, lbl_icnt
    syscall
    li    $v0, 4
    la    $a0, lbl_add_i
    syscall
    li    $v0, 4
    la    $a0, lbl_sub_i
    syscall
    li    $v0, 4
    la    $a0, lbl_mul_i
    syscall
    li    $v0, 4
    la    $a0, lbl_div_i
    syscall
    li    $v0, 4
    la    $a0, lbl_mod_i
    syscall

    # Exit
    li    $v0, 10
    syscall


# ============================================================
# bench_add
# Operation: $t0 = $s0 + $s1  (ADD)
# MIPS instructions per iteration: 1 (ADD)
# Cycles per iteration: 1
# ============================================================
bench_add:
    li    $t9, ITERATIONS       # loop counter
add_loop:
    add   $t0, $s0, $s1         # ← THE OPERATION (1 instruction, 1 cycle)
    addi  $t9, $t9, -1
    bne   $t9, $zero, add_loop

    # Print label + result
    li    $v0, 4
    la    $a0, lbl_add
    syscall
    li    $v0, 1
    move  $a0, $t0
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall

    jr    $ra


# ============================================================
# bench_sub
# Operation: $t0 = $s0 - $s1  (SUB)
# MIPS instructions per iteration: 1 (SUB)
# Cycles per iteration: 1
# ============================================================
bench_sub:
    li    $t9, ITERATIONS
sub_loop:
    sub   $t0, $s0, $s1         # ← THE OPERATION (1 instruction, 1 cycle)
    addi  $t9, $t9, -1
    bne   $t9, $zero, sub_loop

    li    $v0, 4
    la    $a0, lbl_sub
    syscall
    li    $v0, 1
    move  $a0, $t0
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall

    jr    $ra


# ============================================================
# bench_mul
# Operation: $t0 = $s0 * $s1  (MULT → MFLO)
# MIPS instructions per iteration: 2  (MULT + MFLO)
# Cycles per iteration: ~2–32 for MULT + 1 for MFLO
#   Average stall: ~16 cycles (typical MIPS implementation)
# NOTE: MULT writes to HI/LO, NOT a GPR.
#       MFLO is mandatory to retrieve the lower 32 bits.
# ============================================================
bench_mul:
    li    $t9, ITERATIONS
mul_loop:
    mult  $s0, $s1              # ← instr 1: multiply, result → HI:LO (stall 2–32 cyc)
    mflo  $t0                   # ← instr 2: move LO (lower 32 bits) to $t0
    addi  $t9, $t9, -1
    bne   $t9, $zero, mul_loop

    li    $v0, 4
    la    $a0, lbl_mul
    syscall
    li    $v0, 1
    move  $a0, $t0
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall

    jr    $ra


# ============================================================
# bench_div
# Operation: $t0 = $s0 / $s1  (DIV → MFLO for quotient)
# MIPS instructions per iteration: 2  (DIV + MFLO)
# Cycles per iteration: 32–38 for DIV + 1 for MFLO
#   Average stall: ~35 cycles
# NOTE: DIV stalls the entire pipeline until complete.
#       Quotient in LO, Remainder in HI.
# ============================================================
bench_div:
    li    $t9, ITERATIONS
div_loop:
    div   $s0, $s1              # ← instr 1: divide, quotient→LO, remainder→HI (stall 32–38 cyc)
    mflo  $t0                   # ← instr 2: move quotient to $t0
    addi  $t9, $t9, -1
    bne   $t9, $zero, div_loop

    li    $v0, 4
    la    $a0, lbl_div
    syscall
    li    $v0, 1
    move  $a0, $t0
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall

    jr    $ra


# ============================================================
# bench_mod
# Operation: $t0 = $s0 % $s1  (DIV → MFHI for remainder)
# MIPS instructions per iteration: 2  (DIV + MFHI)
# Cycles per iteration: 32–38 for DIV + 1 for MFHI
#   Average stall: ~36 cycles
# NOTE: Same DIV stall as division.
#       Remainder retrieved via MFHI instead of MFLO.
#       This is the ONLY difference vs bench_div —
#       MIPS has no dedicated MOD/REM instruction.
# ============================================================
bench_mod:
    li    $t9, ITERATIONS
mod_loop:
    div   $s0, $s1              # ← instr 1: divide (same 32–38 cycle stall)
    mfhi  $t0                   # ← instr 2: move REMAINDER (HI) to $t0
    addi  $t9, $t9, -1
    bne   $t9, $zero, mod_loop

    li    $v0, 4
    la    $a0, lbl_mod
    syscall
    li    $v0, 1
    move  $a0, $t0
    syscall
    li    $v0, 4
    la    $a0, newline
    syscall

    jr    $ra
