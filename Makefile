CC := $(HOME)/opt/cross/bin/i686-elf-gcc
LD := $(HOME)/opt/cross/bin/i686-elf-ld
AS := $(HOME)/opt/cross/bin/i686-elf-as
QEMU := /usr/bin/qemu-system-x86_64

CCFLAGS := -c -Wno-write-strings -Qn -Wall -Wextra -fno-exceptions -nostdlib -nostartfiles -ffreestanding -mgeneral-regs-only -mno-red-zone
ASFLAGS := 
LDFLAGS := -T link.txt -Map=map.txt


# local headers
INCLUDE += ./include


# add libraries and headers to flags
CCFLAGS += $(foreach dir,$(INCLUDE),-I$(dir))
ASFLAGS += $(foreach dir,$(INCLUDE),-I$(dir))
LDFLAGS += $(foreach dir,$(INCLUDE),-I$(dir)) 
LDFLAGS += $(foreach dir,$(LIBPATHS),-L$(dir))
LDFLAGS += $(foreach lib,$(LIBRARIES),-l$(lib))


# source and build directory
ifndef SRCDIR
	SRCDIR := ./src
endif

ifndef OBJDIR
	OBJDIR := ./obj
endif

ifndef PROG
	PROG := ./ceboot.bin
endif


# lists of source and object files
CSRC := $(wildcard $(SRCDIR)/*.c)
SSRC := $(wildcard $(SRCDIR)/*.s)
SRC := $(SSRC) $(CSRC)
COBJ := $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.c.o,$(CSRC))
SOBJ := $(patsubst $(SRCDIR)/%.s,$(OBJDIR)/%.s.o,$(SSRC))
OBJ := $(SOBJ) $(COBJ)


# targets
.PHONY: default verbose debug release clean run

default: debug

verbose: CCFLAGS += -v
verbose: LDFLAGS += -v
verbose: debug

debug: CCFLAGS += -DDEBUG -g -O0
debug: $(PROG)

release: CCFLAGS += -O2
release: $(PROG)

$(PROG): $(OBJ)
	$(LD) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.c.o: $(SRCDIR)/%.c
	$(CC) -o $@ $< $(CCFLAGS)

$(OBJDIR)/%.s.o: $(SRCDIR)/%.s
	$(AS) -o $@ $<

clean:
	$(EXEC) @rm $(OBJ) $(PROG) 2> /dev/null; true

run:
	$(EXEC) $(QEMU) -drive index=0,if=floppy,format=raw,file=ceboot.bin -m 64 -monitor stdio -no-reboot -d int,cpu_reset,in_asm 2> qemu.log

