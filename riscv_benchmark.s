# ============================================================
# CS-3813 Final Project — RISC-V Benchmark (RV32IM)
# MIPS vs RISC Energy Efficiency
# Group: Darin, Fady & Tonye
#
# Equivalent of mips_benchmark.asm for RISC-V (RV32I + M ext.)
# Run in: Ripes simulator (https://github.com/mortbopet/Ripes)
#         or RISC-V online simulator (https://rvcodec.js.org/)
#
# Key differences from MIPS highlighted in comments.
# ============================================================

.data
    operandA:   .word  47
    operandB:   .word  6

    title:      .string "CS-3813 RISC-V Arithmetic Benchmark\n"
    sep:        .string "-----------------------------\n"
    lbl_add:    .string "[ADD]  47 + 6 = "
    lbl_sub:    .string "[SUB]  47 - 6 = "
    lbl_mul:    .string "[MUL]  47 * 6 = "
    lbl_div:    .string "[DIV]  47 / 6 = "
    lbl_mod:    .string "[MOD]  47 % 6 = "
    lbl_iter:   .string "Iterations per operation: "
    lbl_icnt:   .string "\nInstruction analysis (1 iteration):\n"
    lbl_add_i:  .string "  ADD  instructions: 1 | cycles: 1\n"
    lbl_sub_i:  .string "  SUB  instructions: 1 | cycles: 1\n"
    lbl_mul_i:  .string "  MUL  instructions: 1 | cycles: ~4 avg (M-ext, no stall)\n"
    lbl_div_i:  .string "  DIV  instructions: 1 | cycles: ~12 avg (M-ext hardware divider)\n"
    lbl_mod_i:  .string "  REM  instructions: 1 | cycles: ~12 avg (dedicated REM instruction)\n"
    newline:    .string "\n"

.equ ITERATIONS, 100

.text
.globl _start

_start:
    # Load operands into saved registers
    lw    x18, operandA         # x18 = 47  (s2 in ABI)
    lw    x19, operandB         # x19 = 6   (s3 in ABI)

    # Print title
    li    a7, 4
    la    a0, title
    ecall
    li    a7, 4
    la    a0, sep
    ecall

    # Print iteration count
    li    a7, 4
    la    a0, lbl_iter
    ecall
    li    a7, 1
    li    a0, ITERATIONS
    ecall
    li    a7, 4
    la    a0, newline
    ecall
    li    a7, 4
    la    a0, sep
    ecall

    # Run benchmarks
    jal   ra, bench_add
    jal   ra, bench_sub
    jal   ra, bench_mul
    jal   ra, bench_div
    jal   ra, bench_mod

    # Print instruction analysis
    li    a7, 4
    la    a0, sep
    ecall
    li    a7, 4
    la    a0, lbl_icnt
    ecall
    li    a7, 4
    la    a0, lbl_add_i
    ecall
    li    a7, 4
    la    a0, lbl_sub_i
    ecall
    li    a7, 4
    la    a0, lbl_mul_i
    ecall
    li    a7, 4
    la    a0, lbl_div_i
    ecall
    li    a7, 4
    la    a0, lbl_mod_i
    ecall

    # Exit
    li    a7, 10
    ecall


# ============================================================
# bench_add — ADD x5, x18, x19
# RISC-V: 1 instruction, 1 cycle
# MIPS:   1 instruction, 1 cycle  → NO DIFFERENCE
# ============================================================
bench_add:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    li    t4, ITERATIONS
add_loop:
    add   t0, x18, x19          # ← THE OPERATION: 1 instr, 1 cycle
    addi  t4, t4, -1
    bne   t4, x0, add_loop

    li    a7, 4
    la    a0, lbl_add
    ecall
    li    a7, 1
    mv    a0, t0
    ecall
    li    a7, 4
    la    a0, newline
    ecall

    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret


# ============================================================
# bench_sub — SUB x5, x18, x19
# RISC-V: 1 instruction, 1 cycle
# MIPS:   1 instruction, 1 cycle  → NO DIFFERENCE
# ============================================================
bench_sub:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    li    t4, ITERATIONS
sub_loop:
    sub   t0, x18, x19          # ← THE OPERATION: 1 instr, 1 cycle
    addi  t4, t4, -1
    bne   t4, x0, sub_loop

    li    a7, 4
    la    a0, lbl_sub
    ecall
    li    a7, 1
    mv    a0, t0
    ecall
    li    a7, 4
    la    a0, newline
    ecall

    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret


# ============================================================
# bench_mul — MUL x5, x18, x19
# RISC-V M-ext: 1 instruction, ~4 cycles, writes directly to GPR
# MIPS:         2 instructions (MULT + MFLO), ~16 cycles avg
# DIFFERENCE:   ~4x fewer cycles, 1 fewer instruction per operation
# ============================================================
bench_mul:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    li    t4, ITERATIONS
mul_loop:
    mul   t0, x18, x19          # ← 1 instr: result directly in t0, no HI/LO needed
    addi  t4, t4, -1
    bne   t4, x0, mul_loop

    li    a7, 4
    la    a0, lbl_mul
    ecall
    li    a7, 1
    mv    a0, t0
    ecall
    li    a7, 4
    la    a0, newline
    ecall

    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret


# ============================================================
# bench_div — DIV x5, x18, x19
# RISC-V M-ext: 1 instruction, ~12 cycles, writes directly to GPR
# MIPS:         2 instructions (DIV + MFLO), ~35 cycles avg (stall)
# DIFFERENCE:   ~2.9x fewer cycles, 1 fewer instruction per operation
# ============================================================
bench_div:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    li    t4, ITERATIONS
div_loop:
    div   t0, x18, x19          # ← 1 instr: quotient directly in t0
    addi  t4, t4, -1
    bne   t4, x0, div_loop

    li    a7, 4
    la    a0, lbl_div
    ecall
    li    a7, 1
    mv    a0, t0
    ecall
    li    a7, 4
    la    a0, newline
    ecall

    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret


# ============================================================
# bench_mod — REM x5, x18, x19
# RISC-V M-ext: 1 instruction, ~12 cycles, writes directly to GPR
# MIPS:         2 instructions (DIV + MFHI), ~36 cycles avg
# KEY INSIGHT:  RISC-V has a DEDICATED REM instruction.
#               MIPS reuses DIV and reads the HI register as a
#               side effect — no dedicated modulo operation exists.
# DIFFERENCE:   ~3x fewer cycles, 1 fewer instruction per operation
# ============================================================
bench_mod:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    li    t4, ITERATIONS
mod_loop:
    rem   t0, x18, x19          # ← 1 instr: remainder directly in t0 (no MFHI needed!)
    addi  t4, t4, -1
    bne   t4, x0, mod_loop

    li    a7, 4
    la    a0, lbl_mod
    ecall
    li    a7, 1
    mv    a0, t0
    ecall
    li    a7, 4
    la    a0, newline
    ecall

    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret
