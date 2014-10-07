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

.include "src/bootloader/00_boot_vars.s"

.file "src/bootloader/20_boot_protected_mode_32bit.s"

.section .bootstrap32.data
has_cpuid_str:			.asciz "Has CPUID instruction: %s\n"
has_long_mode_str:		.asciz "Has long mode: %s\n"
bist_str:				.asciz "eax (BIST result): %u\n"
compat_str:				.asciz "Now in 32 bit long mode compatibility mode\n"
mem_entry_count_str:	.asciz "Displaying %u memory map entries:\n"
mem_entry_str:			.asciz "Start: %u, length: %u, type: %u, acpi 3: %u\n"
mem_total_found_str:	.asciz "Total usable high memory found: %u\n"
mem_PTs_needed_str:		.asciz "Page tables needed: %u\n"
mem_PDs_needed_str:		.asciz "Page directories needed: %u\n"
ident_map_end:			.asciz "Identity mapping till page: %u\n"

num_PDs:	.long 0				# 
num_PTs:	.long 0				# 
PT_start:	.quad 0				# depending on amount of PD's
PT_end:		.quad 0				# depending on amount of PT's
# num PDP's is 1; at 0x2000, gives 512GB space; should be enough for now (pml4 also 1 of course)
# 1 PDP means a page is indentified by 9 bits PD and 9 bits PT, 18 bits total.

.align 2
GDT64info:
			.word	(gdt64_end - gdt64 - 1)		# n * 8 - 1
			.quad	gdt64						# to get the lineair address
gdt64:
			.quad	0x0						# entry 0: unused
			.quad	0x002F98000000FFFF		# entry 1: kernel code; think about C bit TODO; verify: L = 1; D=0?
			.quad	0x000F92000000FFFF		# entry 2: kernel data
			.quad	0x000089000F982068		# entry 3: 64 bit TSS; the one and only; part 1; base = 0x80000; size 8kib+104
			.quad	0x0000000000000000		# entry 3: TSS; part 2
			#.quad	0x01CF92000000FFFF		# entry 3: stack; starting point: 16MB atm TODO reconsider: 15-16MB gap!
			#.quad	0x00CF92000000FFFF		# entry 3: stack; starting point: 16MB atm TODO reconsider: 15-16MB gap!
			# TODO: LDT?
gdt64_end:
video_current_line:	.byte	0
video_current_char:	.long	0

.section .bootstrap32
.code32
.global _cont32prot

_cont32prot:
	# select data descriptor from the GDT
	mov		$gdt_data_segment, %eax	# normal code starts past the 7c00 starting point
	mov		%ax, %ds
	mov		%ax, %es
	mov		%ax, %fs
	#mov		$gdt_bios_segment, %eax	# so gs starts at 0, for HW access
	mov		%ax, %gs	
#	mov		$gdt_stack_segment, %eax # stack gets it's own private space
	mov		%ax, %ss
#continue with old stack
#	mov		$0x00EFFFFF, %esp	# stack ending at 15MB; before potential hole
	mov		%esp, %ebp

	mov		$video_mem_start, %eax
	mov		%eax, video_current_char

	push	$32
	push	$bit_str
	#call	prot_printf
	pop		%eax
	pop		%eax

	push	$bist_str		# argument(s) got pushed before
	#call	prot_printf
	pop		%eax
	pop		%eax


	# test for cpuid
	call	cpuid_check
	cmp		$1, %al
	je		has_cpuid
	push	$false_str
	push	$has_cpuid_str
	#call	prot_printf
	pop		%eax
	pop		%eax
	jmp		9f

has_cpuid:
	push	$true_str
	push	$has_cpuid_str
	#call	prot_printf
	pop		%eax
	pop		%eax

	# test for long mode
	mov		$0x80000000, %eax	# Extended-function 8000000h.
	cpuid						# Is largest extended function
	cmp		$0x80000000, %eax	# any function > 80000000h?
	jbe		no_long_mode		# If not, no long mode.
	mov		$0x80000001, %eax	# Extended-function 8000001h.
	cpuid						# Now EDX = extended-features flags.
	bt		$29, %edx			# Test if long mode is supported.
	jc		has_long_mode		# Exit if not supported.
no_long_mode:
	push	$false_str
	push	$has_long_mode_str
	#call	prot_printf
	pop		%eax
	pop		%eax
	jmp		9f

has_long_mode:
	push	$true_str
	push	$has_long_mode_str
	#call	prot_printf
	pop		%eax
	pop		%eax
# TODO check NX bit before setting NXE bit in EFER

	call	paging_init

# enable PAE paging:
	mov		%cr4, %eax			# Set the A-register to control register 4.
	bts		$5, %eax			# Set the PAE-bit, which is the 6th bit (bit 5).
	mov		%eax, %cr4			# Set control register 4 to the A-register.

# enable long mode
	mov		$0xC0000080, %ecx	# Set the C-register to 0xC0000080, which is the EFER MSR.
	rdmsr						# Read from the model-specific register.
	bts		$8, %eax			# Set the LME-bit which is the 9th bit (bit 8).
	bts		$11, %eax			# Set the NXE-bit; enable NX bits on page tables
	wrmsr						# Write to the model-specific register.

# enable paging
	mov		%cr0, %eax			# Set the A-register to control register 0.
	bts		$31, %eax			# Set the PG-bit, which is the 32nd bit (bit 31).
	mov		%eax, %cr0			# Set control register 0 to the A-register.

	push	video_current_char
	push	$compat_str
	#call	prot_printf
	pop		%eax
	pop		%eax

# load 64 bit gdt
	lgdt	GDT64info
# and jump
	ljmp	$gdt_code_segment, $_cont64long

9:
	hlt
	jmp		9b

/**
 * cpuid check
 * returns 1 if CPUID is supported, 0 otherwise (ZF is also set accordingly)
 */
cpuid_check:
	enter	$0, $0

	pushfl					# get
	pop		%eax
	mov		%eax, %ecx		# save 
	xor		$0x200000, %eax	# flip ID bit
	push	%eax			# set
	popfl

	pushfl					# and test
	pop		%eax
	xor		%ecx, %eax		# mask changed bits
	shr		$21, %eax		# move bit 21 to bit 0
	and		$1, %eax		# and mask others
	push	%ecx
	popfl					# restore original flags

	leave
	ret

# set up all the paging tables we'll ever need... till we want to go past 4GB that is...
# TODO 
paging_init:
	enter	$0, $0
# time to set up paging for 64 bit long mode
	# find out how much memory I have (see earlier 16 bit found map)
	movw	0x500, %cx
	and		$0xFFFF, %ecx				# somehow I get more than 2 bytes with my movw?
	push	%ecx
	push	$mem_entry_count_str
	#call	prot_printf

	mov		$0, %eax					# zero them; acpi 3 holder
	mov		$0, %ebx					# type
	mov		$0, %edx					# total memory found
	mov		$0x502, %edi				# start of actual memory map

1:
	push	20(%edi)					# acpi 3
	push	16(%edi)					# type
	push	8(%edi)						# length (shouldn't be zero) TODO QUAD WORD
	push	(%edi)						# start TODO QUAD WORD

#	cmpl	$1, 16(%edi)				# for now, we're only interested in type 1: usable RAM
#	jne		2f
#	cmpl	$0x100000, (%edi)			# we don't care about the area below 2 MB; we're using that already
#	jl		2f
	mov		8(%edi), %eax
	and		$-4096, %eax				# we might not get it in pages, so round down to pages?
	add		%eax, %edx
2:
	push	$mem_entry_str
	#call	prot_printf
	add		$16, %esp					# clean up arguments
	add		$24, %edi					# next entry 24 bytes further
	loop	1b

	push	%edx
	push	$mem_total_found_str
	#call	prot_printf

	# - convert to pages, double it, that's the amount of PT's I'm willing to have for now
	shr		$20, %edx			# shr 12 to convert to 4096 pages, shl 1 to double it; shr 9 for 512 per table
	inc		%edx				# round up

	mov		%edx, num_PTs
	push	%edx
	push	$mem_PTs_needed_str
	#call	prot_printf

	shr		$9, %edx			# convert to PDs by dividing by 512
	inc		%edx				# round up
	cmp		$4, %edx
	jge		3f					# make sure there's at least 4 PD's to be able to address the last part of 4GB as well
	mov		$4, %edx
3:
	mov		%edx, num_PDs
	push	%edx
	push	$mem_PDs_needed_str
	#call	prot_printf

	mov		num_PDs, %edx
	shl		$9, %edx			# all PD's get all their PT's
	mov		%edx, num_PTs
	push	%edx
	push	$mem_PTs_needed_str
	#call	prot_printf

# create PML4
	mov		$PML4, %edi			# Set the destination index to address of PML4T; the table of tables
# TODO Think about PWT PCD bits (caching; page 131 amd vol 2)
	mov		%edi, %cr3			# Set control register 3 to contain the PML4T address
	mov		$0, %eax			# Nullify the A-register.
	mov		$4096, %ecx			# Set the C-register to 4096.
	rep		stosl				# Clear the memory. TODO is this needed?
	mov		%cr3, %edi			# reset edi to start of PML4T

# fill PML4
# the three indicates that the page is present and that it is readable as well as writable
	movl	$(PDP + 3), (%edi)		# Set the double word in the PML4 to PDP (+ p & r/w)

	call	fill_PDP

	call	fill_PDs

# fill up PT's; # identity map the whole thing till the end of PT_end
	mov		PT_end, %ecx		# end of identity map
	shr		$12, %ecx			# convert to pages
	push	%ecx
	push	$ident_map_end
	#call	prot_printf

	mov		PT_start, %edi		# Time to fill PTs
	mov		$0x03, %ebx			# Set the B-register to 0x00000003 (Present + r/w).
1:
	movl	%ebx, (%edi)		# Set the double word at the destination index to the B-register.
	add		$0x1000, %ebx		# Add 0x1000 to the B-register.
	add		$8, %edi			# next entry in the PT
	loop	1b					# Set the next entry.

9:
	leave
	ret

/**
 * num_PDs contains the amount needed
 */
fill_PDP:
	enter	$0, $0

	mov		num_PDs, %ecx
	cmp		$0, %ecx
	je		9f

	mov		$PD_start, %edi
	add		$3, %edi		# present and r/w
	mov		$PDP, %esi
1:
	mov		%edi, (%esi)	# set entry 
	add		$0x1000, %edi	# next table is one page further
	add		$8, %esi		# next entry in the PDP
	loop	1b

	sub		$3, %edi
	mov		%edi, PT_start	# PT's go after the PD's
9:
	leave
	ret

/**
 * num_PTs contains the amount needed
 */
fill_PDs:
	enter	$0, $0

	mov		num_PTs, %ecx
	cmp		$0, %ecx
	je		9f

	mov		PT_start, %edi
	add		$3, %edi		# present and r/w
	mov		$PD_start, %esi	# we start with PD 1
1:
	mov		%edi, (%esi)	# set entry 
	add		$0x1000, %edi	# next table is one page further
	add		$8, %esi		# next entry in the PD
	loop	1b

	sub		$3, %edi
	mov		%edi, PT_end	# so we know where the tables end
9:
	leave
	ret

