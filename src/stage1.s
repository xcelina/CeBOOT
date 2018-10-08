.section .text

.global ss_start
.global GDT

.code32

ss_start:
loop:
  jmp loop

