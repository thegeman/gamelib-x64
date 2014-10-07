TARGET = amd64-elf-

# include local Makefile. Copy local.mk.template and adapt
include local.mk

PREFIX=/usr
COMPPATH=$(PREFIX)/bin
CC = $(COMPPATH)/$(TARGET)gcc
CXX = $(COMPPATH)/$(TARGET)g++
AS = $(COMPPATH)/$(TARGET)as
AR = $(COMPPATH)/$(TARGET)ar
NM = $(COMPPATH)/$(TARGET)nm
LD = $(COMPPATH)/$(TARGET)ld
OBJDUMP = $(COMPPATH)/$(TARGET)objdump
OBJCOPY = $(COMPPATH)/$(TARGET)objcopy
RANLIB = $(COMPPATH)/$(TARGET)ranlib
STRIP = $(COMPPATH)/$(TARGET)strip
CFLAGS = -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -O3 -Wall -Wextra -W -g

all: out/bootloader out/kernel Makefile
	
out/bootloader: out/boot.o src/bootloader/link_boot.ld | HD_img
	$(LD) -nostdlib -T src/bootloader/link_boot.ld -o $@ out/boot.o
	dd if=out/bootloader of=HD_img conv=notrunc

out/kernel: out/kernel.o src/kernel/link_kernel.ld | HD_img
	$(LD) -nostdlib -T src/kernel/link_kernel.ld -o $@ out/kernel.o
	dd if=out/kernel of=HD_img bs=512 seek=17 conv=notrunc

out/boot.o: src/bootloader/*.s | out
	$(AS) src/bootloader/*.s -o $@

out/kernel.o: src/kernel/*.s src/game/*.s | out
	$(AS) src/kernel/*.s src/game/*.s -o $@

HD_img:
	dd if=/dev/zero of=$@ count=512

qemu: all
	qemu-system-x86_64 HD_img

kvm: all
	qemu-system-x86_64 -enable-kvm -cpu host HD_img

bochs: all
	bochs

out:
	mkdir out

clean:
	rm -f HD_img
	rm -rf out

.PHONY: clean all kvm qemu 

