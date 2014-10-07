/*
This file is part of gamelib-x64.

Copyright (C) 2014 Otto Visser

gamelib-x64 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

gamelib-x64 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with gamelib-x64. If not, see <http://www.gnu.org/licenses/>.
*/

################################################################################
# The absolute beginning...
################################################################################

.include "src/bootloader/00_boot_vars.s"

# TODO cache is disabled; see 2:431
# TODO mtrr is disabeld? 2:431
.code16
.file "src/bootloader/10_boot_real_mode_16bit.s"

.section .bootstrap16.data
GDT32info:
			.word	(gdt32_end - gdt32 - 1)	# n * 8 - 1
			.long	gdt32					# to get the lineair address
gdt32:
			.quad	0x0						# entry 0: unused
			.quad	0x00CF9A000000FFFF		# entry 1: all 4 GB is kernel code
			.quad	0x00CF92000000FFFF		# entry 2: all 4 GB is kernel data
			# TODO: a stack segment?
gdt32_end:
boot_disk:	.byte	0x42

booting_str:		.asciz "OtviOS booting...\r\n"
bit_str:			.asciz "In %u bit code now...\r\n"
disk_str:			.asciz "Booted from disk: %u\r\n"
sectors_str:		.asciz "sectors/track: %u\r\n"
heads_str:			.asciz "heads: %u\r\n"
disk_read_fail:		.asciz "Failure reading disk\r\n"

.section .bootstrap16
.code16
.global _start

_start:
	cli							# turn off interrupts; not in shape yet to handle anything
	ljmp	$0x0, $_start_cont	# far jump to ensure %cs is correct
_start_cont:
	cld							# string ops are forwards
	mov		%cs, %bx			# copy the code segment to 
	mov		%bx, %ds			# ...data segment register
	mov		$bootaddr, %ebx		# stack downwards from where we start with code TODO Stack ends at 0x0500 (~30KB); how to check?
	lss		(%ebx), %sp			# load ss:sp

# TODO %eax contains result of BIST; save and inspect later? see page 2:428
	push	%eax				# 43605 0 ??
# %dl is the bootdrive
	mov		%dl, boot_disk		# 128 == 0x80 == hard disk 0

	push	$booting_str
	#call	bios_printf
	pop		%ax

	push	$16
	push	$bit_str
	#call	bios_printf
	pop		%ax
	pop		%ax

	movzb	boot_disk, %ax
	push	%ax
	push	$disk_str
	#call	bios_printf
	pop		%ax
	pop		%ax

# get disk info
	mov		$8, %ah			# bios function to get CHS
	mov		boot_disk, %dl	# disk number from bios
	int		$0x13
	mov		%dh, %al		# dh is heads -1
	and		$0xFF, %ax
	inc		%ax
	push	%ax
	push	$heads_str
	#call	bios_printf
	pop		%ax
	pop		%ax

	and		$0x3F, %cx		#cl is sectors/track
	push	%cx
	push	$sectors_str
	#call	bios_printf
	pop		%ax
	pop		%ax

	# read next sector(s)
	# reads go to es:bx, so set those first:
	mov		$bootaddr2, %ax
	mov		%ax, %es
	mov		$0, %bx
	mov		$2, %ah			# 2 == read
	mov		$4, %al			# sectors to read	TODO; bootloader sectors -1
	mov		$0, %ch			# cylinder 0
	mov		$2, %cl			# sector 2
	mov		$0, %dh			# head 0
	mov		boot_disk, %dl	# from the boot_disk
	int		$0x13			# do it
	cmp		$0, %ah			# check result code

	# read kernel sector(s)
	# reads go to es:bx, so set those first:
	mov		$kernel_addr, %ax
	mov		%ax, %es
	mov		$0, %bx
	mov		$2, %ah			# 2 == read
	mov		$128, %al		# sectors to read	TODO
	mov		$0, %ch			# cylinder 0
	mov		$18, %cl		# sector 18 where kernel starts
	mov		$0, %dh			# head 0
	mov		boot_disk, %dl	# from the boot_disk
	int		$0x13			# do it
	cmp		$0, %ah			# check result code
	jz		parttwo16

	push	$disk_read_fail
	#call	bios_printf
	pop		%ax
	jmp		halt16			# can't read the next of our code, so just stop...

halt16:
	hlt
	jmp		halt16

#.org 0x1fe
#	.byte	0x55
#	.byte	0xAA

#.org 0x200
# TODO attn: only 512 bytes loaded, so nothing below this line unless read of next sector(s) was successful

.section .bootstrap17.data
true_str:				.asciz "true"
false_str:				.asciz "false"
part2_str:				.asciz "Part two loaded from disk\r\n"
has_a20_str:			.asciz "Has A20 line active: %s\r\n"
mem_read_fail_str:		.asciz "Error reading low memory size\r\n"
mem_count_found_str:	.asciz "Memory map entries found: %u\r\n"
lowmem_size_str:		.asciz "Low memory size: %u KB\r\n"

.section .bootstrap17
parttwo16:
# print to show we're still alive
	push	$part2_str
	#call	bios_printf
	pop		%ax

	call	check_a20
	cmp		$0, %ax
	je		1f
	push	$true_str
	jmp		2f
1:
	# enable A20 if needed
	mov		$0x2401, %ax
	int		$0x15
	push	$false_str
2:	
	push	$has_a20_str
	#call	bios_printf
	pop		%ax
	pop		%ax
	
# time to get the available memory
	call	check_mem

	# load the GDT
	lgdt	GDT32info

	#enable protected mode
	mov		%cr0, %eax
	or		$1, %eax
	mov		%eax, %cr0

	# TODO
	# far jump to protected code
	ljmp	$gdt_code_segment, $_cont32prot
	jmp		halt16

/**
 * retrieves the memory map
 * first the low mem part, then the complete map
 */
check_mem:
	mov		$0, %ax
	int		$0x12	# request low memory size
	jc		7f
	test	%ax, %ax
	jz		7f
	push	%ax
	push	$lowmem_size_str
	#call	bios_printf
	pop		%ax
	pop		%ax

	# start of E820 calls
	mov		$0, %ebx
	mov		%bx, %es
	mov		$0x502, %di			# store mem map at the beginning of usable ram, first 2 bytes will be count
	mov		$0, %bp				# entry count
	mov		$0x0534D4150, %edx	# "SMAP"
	mov		$0xE820, %eax
	mov		$24, %ecx			# ask for 24 bytes
	int		$0x15
	jc		7f
	mov		$0x0534D4150, %edx	# "SMAP"; restore TODO needed?
	cmp		%edx, %eax			# eax should be SMAP now
	jne		7f
	test	%ebx, %ebx			# no entries? Something failed
	je		7f
	jmp		3f
2:
	mov		$0xE820, %eax		# gets trashed on every int 0x15 call; put it back
	mov		$24, %ecx			# is this needed? TODO
	int		$0x15
	jc		6f
	mov		$0x0534D4150, %edx	# "SMAP"; restore edx
3:
	jcxz	5f					# skip 0 byte entries
	cmp		$20, %cl			# got a 24 byte ACPI 3.X response?
	jbe		4f
	testb	$1, %es:20(%di)			# is the ignore bit clear?
	je		5f
4:
	mov		%es:8(%di), %ecx	# lower word of memory region length
	or		%es:12(%di), %ecx	# upper part
	jz		5f					# if both or-ed is zero, length is zero
	inc		%bp					# count++
	add		$24, %di			# next entry 24 bytes futher
5:
	test	%ebx, %ebx
	jne		2b					# if ebx is zero, we're done
6:
	mov		$0x500, %di
	mov		%bp, (%di)			# store the count before the content
	push	%bp
	push	$mem_count_found_str
	#call	bios_printf
	pop		%ax
	pop		%ax
	clc							# TODO
	jmp		8f
7:
	stc							# TODO
	push	$mem_read_fail_str
	#call	bios_printf
	pop		%ax
8:
	ret


/**
 * Function: check_a20
 *
 * Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
 *          The function can be modified as necessary by removing push's at the beginning and their
 *          respective pop's at the end if complete self-containment is not required.
 *
 * Returns: 0 in ax if the a20 line is disabled (memory wraps around)
 *          1 in ax if the a20 line is enabled (memory does not wrap around)
 */ 
check_a20:
	enter	$0, $0
	push	%ds
	pushf

	mov		$0xFFFF, %ax	# can be removed?

	mov		$0x0500, %di
	mov		$0x0510, %si

	mov		$0, %bx
	mov		%bx, %es
	mov		$0xFFFF, %bx
	mov		%bx, %ds
	mov		%es:(%di), %al
	push	%ax

	mov		%ds:(%si), %al
	push	%ax

	movb	$0x00, %es:(%di)
	movb	$0xFF, %ds:(%si)

	cmpb	$0xFF, %es:(%di)

	pop		%ax
	mov		%al, %ds:(%si)

	pop		%ax
	mov		%al, %es:(%di)

	mov		$0, %ax
	je		check_a20__exit

	mov		$1, %ax

check_a20__exit:
	popf
	pop		%ds
	
	leave
	ret

