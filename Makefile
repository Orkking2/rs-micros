# / ___|  / ___|  / ___|
#| |  _  | |     | |    
#| |_| | | |___  | |___ 
# \____|  \____|  \____|

PREFIX=riscv64-linux-gnu-

CC=$(PREFIX)gcc
OBJDUMP=$(PREFIX)objdump
OBJCOPY=$(PREFIX)objcopy

CFLAGS=-Wall -Wextra -pedantic -Wextra -O0 -std=c++17 -g
CFLAGS+=-static -ffreestanding -nostdlib -fno-rtti -fno-exceptions
CFLAGS+=-march=rv64gc -mabi=lp64d

KHEAP_MALLOC = src/kheap_malloc

INCLUDES=
LINKER_SCRIPT=-Tsrc/lds/virt.lds
TYPE=debug
RUST_TARGET=./target/riscv64gc-unknown-none-elf/$(TYPE)
LIBS=-L$(RUST_TARGET)
SOURCES_ASM=$(wildcard src/asm/*.S)
KHEAP_MALLOC = src/kheap_malloc/
KHEAP_MALOC_OBJ = $(KHEAP_MALLOC)/kheap_malloc.o
LIB= -lgcc -lrs_micros
OUT=os.elf

BS_OUT=os.bin

# / _ \  | ____| |  \/  | | | | |
#| | | | |  _|   | |\/| | | | | |
#| |_| | | |___  | |  | | | |_| |
# \__\_\ |_____| |_|  |_|  \___/ 
                                
# use `ctrl+a c` to enter qemu monitor

QEMU=qemu-system-riscv64
MACH=virt
CPU=rv64
CPU_CNT=1
MEM=128M
DRIVE=hdd.dsk
SERIAL=mon:stdio
# SERIAL=pty
# pty can be used to do concurrent debug, it will blast data into uart

all: 
	cargo build
	make -C $(KHEAP_MALLOC) all
	$(CC) $(CFLAGS) $(LINKER_SCRIPT) $(INCLUDES) -o $(OUT) $(KHEAP_MALOC_OBJ) $(SOURCES_ASM) $(LIBS) $(LIB)
	
run: all dump
	$(QEMU) \
		-machine $(MACH)\
		-smp $(CPU_CNT)\
		-cpu $(CPU)\
		-m $(MEM)\
		-nographic\
		-serial $(SERIAL)\
		-bios none\
		-kernel $(OUT)\

debug: all dump
	$(QEMU) \
		-machine $(MACH)\
		-cpu $(CPU)\
		-smp $(CPU_CNT)\
		-m $(MEM)\
		-nographic\
		-serial $(SERIAL)\
		-bios none\
		-kernel $(OUT)\
		-s -S

record: all dump
	$(QEMU) \
		-machine $(MACH)\
		-cpu $(CPU)\
		-smp $(CPU_CNT)\
		-m $(MEM)\
		-nographic\
		-serial $(SERIAL)\
		-bios none\
		-kernel $(OUT)\
		-icount shift=auto,rr=record,rrfile=replay.bin

replay: all dump
	$(QEMU) \
		-machine $(MACH)\
		-cpu $(CPU)\
		-smp $(CPU_CNT)\
		-m $(MEM)\
		-nographic\
		-serial $(SERIAL)\
		-bios none\
		-kernel $(OUT)\
		-icount shift=auto,rr=replay,rrfile=replay.bin \
		-s -S

bitstream: all
	$(OBJCOPY) -I elf64-littleriscv -O binary $(OUT) $(BS_OUT)

dump: all
	$(OBJDUMP) -D $(OUT) > dump

.PHONY: clean
clean:
	cargo clean
	rm -f $(OUT) dump os.bin hdd.dsk replay.bin
	make -C $(KHEAP_MALLOC) clean
