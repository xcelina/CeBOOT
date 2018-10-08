.section .text
.code16

  # disable interrupts
  cli

  # canonicalize %CS:%EIP to a known value
  ljmp $0, $start
start:

  # setup segments
  movw $0x0000, %ax
  movw %ax, %ss
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs

  # setup stack
  movw $0x9000, %sp
  movw %sp, %bp

  # select display page 0
  movb $0, %al
  movb $0x05, %ah
  int $0x10

  # check if A20 gate is enabled
  mov $a20_msg, %si
  call print
  call checkA20
  je disabled
enabled:
  call print_done
  jmp resume
disabled:
  call print_fail
  jmp rmloop

  # TODO: activate A20 gate

resume:
  # reset bootdrive
  mov $10, %cx
reset:
  push %cx
  movw $reset_msg, %si
  call print
  movw $bootdrive_msg, %si
  call print

  movb $0x00, %ah
  int $0x13
  pop %cx
  jnc reset_end
  loop reset
  jc error
reset_end:

  movw $done_msg, %si
  call print

  # load second stage into memory starting at adress 0x10000
  #   (NOTE: this code can only be jumped to after loading the global descriptor table
  #          because it uses absolute adresses larger than 16 bit)
  #   (NOTE2: this routine only loads 0x48 sectors of the second stage into memory
  #          and is in general pretty whacky. should be replaced with sth more serious)
  mov $10, %cx
load:
  push %cx
  movw $load_msg, %si
  call print

  movw $0x0000, %bx   # buffer address
  movw $0x1000, %ax
  movw %ax, %es       # buffer address (segment)
  movb $0x02, %ah     # function 0x02: read a sector
  movb $0x048, %al     # sectors to read count
  movb $0x00, %ch     # cylinder
  movb $0x02, %cl     # sector
  movb $0x00, %dh     # head
  # dl (drive) keep as is
  int $0x13
  pop %cx
  jnc load_end
  loop load
  jc error
load_end:

  movw $done_msg, %si
  call print

  movw $gdt_msg, %si
  call print

  # - load global descriptor table and far jump into protected mode
  lgdt (GDT_DESCRIPTOR)

  movw $done_msg, %si
  call print

  lidt (IDT_DESCRIPTOR)

  mov %cr0, %eax
  or $1, %eax
  mov %eax, %cr0

  ljmp $0x8, $protected

.code32
protected:
  # setup registers with appropriate GDT values
  mov $0x10, %eax
  mov %eax, %ds
  mov %eax, %es
  mov %eax, %fs
  mov %eax, %gs
  mov %eax, %ss

  # jump to second stage code
  ljmp $0x08, $ss_start

.code16
error:
  movw $fail_msg, %si
  call print
error_loop:
  jmp error_loop

  # ############################################
  # print
  #   prints out a string on the screen
  #   %si: points to the message to be printed
  # ############################################
print:
  movw $0x0000, %bx
  movb $0x0E, %ah

print_loop:
  lodsb
  or %al, %al
  jz print_end
  int $0x10
  jmp print_loop
print_end:
  ret

print_done:
  mov $done_msg, %si
  jmp print

print_fail:
  mov $fail_msg, %si
  jmp print

  # ############################################
  # checkA20
  #   checks if A20 line is enabled
  #   equal flag: * clear, if A20 is enabled
  #               * set, if A20 is disabled
  # ############################################
checkA20:
  push %ds
  push %es
  push %si
  push %di

  mov $0x0000, %ax
  mov %ax, %ds
  mov $0xFFFF, %ax
  mov %ax, %es

  mov $0x7DFE, %si
  mov $0x7E0E, %di

  movw %ds:(%si), %cx
  movw %es:(%di), %dx
  cmp %cx, %dx

  pop %di
  pop %si
  pop %es
  pop %ds
  ret

rmloop:
  jmp rmloop

a20_msg:
  .ascii "Enabling A20..."
  .byte 0

reset_msg: 
  .ascii "Resett"
  .byte 0

load_msg: 
  .ascii "Load"

bootdrive_msg:
  .ascii "ing bootdrive..."
  .byte 0

gdt_msg:
  .ascii "Setting GDT..."
  .byte 0

done_msg:
  .ascii "done"
  .byte 13
  .byte 10
  .byte 0

fail_msg:
  .ascii "fail"
  .byte 13
  .byte 10
  .byte 0

IDT_DESCRIPTOR:
  .word 0
  .int 0

GDT_DESCRIPTOR:
	.word 0x23
	.int GDT
