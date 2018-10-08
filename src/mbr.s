.section .text

disk_sign:
  .long  0x00000000
  .word   0x0000

partition1:
  .fill 16

partition2:
  .fill 16

partition3:
  .fill 16

partition4:
  .fill 16

boot_sign:
  .byte 0x55
  .byte 0xAA

