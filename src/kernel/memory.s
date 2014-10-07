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

.include "src/kernel/00_boot_vars.s"

.file "src/kernel/memory.s"

.section .kernel.data

memory_init_str:		.asciz "* Initializing memory management subsystem...\n"
memory_init_done_str:	.asciz "* Initializing memory management subsystem: done\n"
mem_entry_count_str:	.asciz "Displaying %u memory map entries:\n"
mem_entry_str:			.asciz "Start: %x, length: %x, type: %u, acpi 3: %u\n"
mem_total_found_str:	.asciz "Total memory found: %u\n"
mem_total_usable_str:	.asciz "Total usable memory found: %u\n"
mem_PTs_needed_str:		.asciz "Page tables needed: %u\n"
mem_PDs_needed_str:		.asciz "Page directories needed: %u\n"
virtualIndices_str:		.asciz "Virt addr: %x: PML4: %u, PDP: %u, PD: %u, PT: %u, offset: %u\n"
PDPEntry_str:			.asciz "PDP entry @ address: %x = %x\n"
PDEntry_str:			.asciz "PD entry @ address: %x = %x\n"
PTEntry_str:			.asciz "PT entry @ address: %x = %x\n"
pageTableFail:			.asciz "Failed to create PT for address %x @ %x\n"
pageTableCreate:		.asciz "Creating PT for address %x @ %x\n"
PT_end_str:				.asciz "Calculated end of PT's: %x\n"
identMapping_str:		.asciz "Ident mapping: %x till %x\n"
no_mtrr_sup_str:		.asciz "CPU lacks MTRR support\n"
mtrr_cap_str:			.asciz "MTRR capabilities: %x\n"
mtrr_str:				.asciz "MTRR content: %x:%x\n"

num_PDs:	.quad 0				# 
num_PTs:	.quad 0				# 
PT_end:		.quad 0
total_mem:	.quad 0				# usable; so excluding type 2 memory; only type 1 atm

MTRRcap				= 0x0FE	# 0x508 = WC, FIX, 8 var range
MTRRphysBase0		= 0x200
MTRRphysMask0		= 0x201
MTRRphysBase1		= 0x202
MTRRphysMask1		= 0x203
MTRRphysBase2		= 0x204
MTRRphysMask2		= 0x205
MTRRphysBase3		= 0x206
MTRRphysMask3		= 0x207
MTRRphysBase4		= 0x208
MTRRphysMask4		= 0x209
MTRRphysBase5		= 0x20A
MTRRphysMask5		= 0x20B
MTRRphysBase6		= 0x20C
MTRRphysMask6		= 0x20D
MTRRphysBase7		= 0x20E
MTRRphysMask7		= 0x20F
MTRRfix64K_00000	= 0x250	# 0x06060606; aka: WB; read/write to mem mapped I/O
MTRRfix16K_80000	= 0x258 
MTRRfix16K_A0000	= 0x259 
MTRRfix4K_C0000		= 0x268 
MTRRfix4K_C8000		= 0x269 
MTRRfix4K_D0000		= 0x26A 
MTRRfix4K_D8000		= 0x26B 
MTRRfix4K_E0000		= 0x26C 
MTRRfix4K_E8000		= 0x26D 
MTRRfix4K_F0000		= 0x26E 
MTRRfix4K_F8000		= 0x26F 
PAT					= 0x277
MTRRdef				= 0x2FF	# 0xC06 = WB, fixed range enabled, mtrr enable
IORRBase0			= 0xC0010016
IORRMask0			= 0xC0010017
IORRBase1			= 0xC0010018
IORRMask1			= 0xC0010019
SYSCFG				= 0xC0010010
TOP_MEM				= 0xC001001A
TOP_MEM2			= 0xC001001D

# TODO: think about r/w, u/s, caching (see page 139), G, AVL, NX; bsd idea: writable? --> NX
# TODO	global pages: the identity mapped first 2 MB and the PD's?
# TODO ROM areas: wrmem=1, rdmem=0, copy, then reversie wrmem/rdmem bits
# TODO IORR
# TODO PAT
# TODO set TOP_MEMs
# use invlpg instruction?
.global init_memory

.section .kernel

init_memory:
	enter	$0, $0

	mov		$memory_init_str, %r8
	#call	printf

	mov		$0x800000001, %rax
	cpuid
	bt		$12, %rdx
	jc		1f
	mov		$no_mtrr_sup_str, %r8
	#call	printf
	jmp		no_mtrr	
1:
	mov		$MTRRcap, %rcx
	rdmsr
	push	%rax				# 0x508 = WC, FIX, 8 var range
	mov		$mtrr_cap_str, %r8
	#call	printf

	bt		$8, %rax
	jnc		no_fix_mtrr
#setup fixed range MTRRs here
	mov		$MTRRdef, %rcx
	rdmsr
	push	%rax
	mov		$mtrr_cap_str, %r8
	#call	printf

	mov		$MTRRfix4K_F8000, %rcx
	rdmsr
	push	%rax
	push	%rdx
	mov		$mtrr_str, %r8
	#call	printf

no_fix_mtrr:

no_mtrr:

# steps to take:
	/**
	 * - find out how much memory I have (see earlier 16 bit found map)
	 * - convert to pages, double it, that's the amount of PT's I'm willing to have for now
	 *   32 GB would then give 64 PD's (and one PT to store them), that's 260KB of RAM I need to store that info
	 * - 260KB = 65 entries in a PT, which will have to be there as well
	 * - point to these PD's in the PDP
	 * - add all of these pages to a free memory map?
	 * - add PD & PT pages to full memory map?
	 */

	# this is a copy of the code in the 32 bit mode bootloader, but with printing
	# find out how much memory I have (see earlier 16 bit found map)
	movw	0x500, %cx
	and		$0xFFFF, %rcx				# somehow I get more than 2 bytes with my movw?
	push	%rcx
	mov		$mem_entry_count_str, %r8
	#call	printf

	mov		$0, %rdx					# zero them; acpi 3 holder
	mov		$0, %rbx					# type
	mov		$0, %r9						# total memory found
	mov		$0x502, %rdi				# start of actual memory map

1:
	movl	20(%rdi), %edx				# acpi 3
	movl	16(%rdi), %ebx				# type
	mov		8(%rdi), %r11				# length (shouldn't be zero)
	mov		(%rdi), %r10				# start

	push	%rdx
	push	%rbx
	push	%r11
	push	%r10
	mov		$mem_entry_str, %r8
	#call	printf
	add		$32, %rsp					# clean up arguments

#	add		$4095, %r11
#	and		$-4096, %r11				# we might not get it in pages, so round up to pages
	add		%r11, %r9					# add to total
	add		$24, %rdi					# next entry 24 bytes further
	loop	1b

	push	%r9
	mov		$mem_total_found_str, %r8
	#call	printf

	# - convert to pages, double it, that's the amount of PT's I'm willing to have for now
	shr		$20, %r9				# shr 12 to convert to 4096 pages, shl 1 to double it; shr 9 for 512 per table
	inc		%r9						# round up

	mov		%r9, num_PTs
	push	%r9
	mov		$mem_PTs_needed_str, %r8
	#call	printf

	shr		$9, %r9				# convert to PDs by dividing by 512
	inc		%r9					# round up
	cmp		$4, %r9	
	jge		8f					# make sure there's at least 4 PD's to be able to address the last part of 4GB as well
	mov		$4, %r9	
8:
	mov		%r9, num_PDs
	push	%r9	
	mov		$mem_PDs_needed_str, %r8
	#call	printf

	mov		num_PDs, %r9
	shl		$9, %r9				# all PD's get all their PT's
	mov		%r9, num_PTs
	push	%r9
	mov		$mem_PTs_needed_str, %r8
	#call	printf

	add		num_PTs, %r9
	add		$3, %r9				# add PML4, PDP and add 1 because it points to the end, not the start of the end
	shl		$12, %r9			# every table occupies 4KiB
	add		$0x100000, %r9
	mov		%r9, PT_end

	push	PT_end
	mov		$PT_end_str, %r8
	#call	printf

	# Go over the list again, now fill PT's where needed
	movw	0x500, %cx
	and		$0xFFFF, %rcx		# somehow I get more than 2 bytes with my movw?
	mov		$0x502, %rdi		# start of actual memory map

1:
	movl	20(%rdi), %edx		# acpi 3
	movl	16(%rdi), %ebx		# type
	mov		8(%rdi), %r11		# length (shouldn't be zero)
	mov		(%rdi), %r10		# start

	cmp		$1, %rbx
	je		2f
	cmp		$2, %rbx
	je		3f
	cmp		$3, %rbx
	je		4f
	cmp		$4, %rbx
	je		5f
	cmp		$5, %rbx
	je		6f

2:									# normal memory
	and		$-4096, %r11			# round down to pages? TODO Needed? TODO: is the start aligned??
	add		%r11, total_mem
	jmp		7f
3:									# reserved/unusable memory
	mov		%r10, %r8
	mov		%r11, %r9
	call	identityMapMemory
	jmp		7f
4:									# ACPI reclaimable
	mov		%r10, %r8
	mov		%r11, %r9
	call	identityMapMemory
	jmp		7f
5:									# ACPI NVS memory TODO
6:									# Area containing bad memory TODO
7:
	add		$24, %rdi				# next entry 24 bytes further
	loop	1b

	push	total_mem
	mov		$mem_total_usable_str, %r8
	#call	printf

# time to reload the maps
	mov		%cr3, %rax
	mov		%rax, %cr3

# TEST: display status of random pages by memory address:
#	mov		$0xFEE00000, %r8
#	call	displayPage
#	mov		$0x1ff1111, %r8
#	call	displayPage
#	mov		$0x7ffe111, %r8
#	call	displayPage
#	mov		$0xFFFFFFFF, %r8
#	call	displayPage
	#mov		$0xB00B5, %r8
	#call	displayPage

# and done
	mov		$memory_init_done_str, %r8
	#call	printf

	leave
	ret

# Functions I'm going to need:
/**
 * get_total_mem
 * get_free_mem

 */

/**
 * This converts a virtual memory address to the indices in all the tables
 * r8 : remains the virtual address
 * r10: PML4 offset
 * r11: PDP offset
 * r12: PD offset
 * r13: PT offset
 * r14: offset in the page
 */
virtualToIndices:
#	enter	$0, $0

	mov		%r8, %r10
	mov		%r8, %r11
	mov		%r8, %r12
	mov		%r8, %r13
	mov		%r8, %r14

	shr		$12, %r13
	shr		$21, %r12
	shr		$30, %r11
	shr		$39, %r10

	and		$0xFFF, %r14
	and		$0x1FF, %r13
	and		$0x1FF, %r12
	and		$0x1FF, %r11
	and		$0x1FF, %r10

#	leave
	ret

/*
 * %r8 contains an adress on call, answer on return
 */
getPageTableEntry:
	enter	$0, $0

	call	virtualToIndices

# we ignore the PML4 thing for now; we know there's only 1 PDP
	shl		$3, %r11		# every entry is 8 bytes
	add		$PDP, %r11		# this is where our PD should be mentioned

	mov		(%r11), %r9
	and		$-4096, %r9		# strip the informative bits to get the address
	shl		$3, %r12
	add		%r9, %r12		# this is where our PT should be mentioned

	mov		(%r12), %r9
	and		$-4096, %r9
	shl		$3, %r13
	add		%r9, %r13		# this is the entry we are looking for

	mov		%r13, %r8

	leave
	ret

displayPage:
	enter	$0, $0

	call	virtualToIndices

	push	%r14
	push	%r13
	push	%r12
	push	%r11
	push	%r10
	push	%r8
	mov		$virtualIndices_str, %r8
	#call	printf

# we ignore the PML4 thing for now; we know there's only 1 PDP
	shl		$3, %r11			# every entry is 8 bytes
	add		$PDP, %r11			# this is where our PD should be mentioned
	push	(%r11)
	push	%r11
	mov		$PDPEntry_str, %r8
	#call	printf

	mov		(%r11), %r9
	and		$-4096, %r9	# strip the informative bits to get the address
	shl		$3, %r12
	add		%r9, %r12		# this is where our PT should be mentioned
	push	(%r12)
	push	%r12
	mov		$PDEntry_str, %r8
	#call	printf

	mov		(%r12), %r9
	and		$-4096, %r9
	shl		$3, %r13
	add		%r9, %r13		# this is the entry we are looking for
	push	(%r13)
	push	%r13
	mov		$PTEntry_str, %r8
	#call	printf

	leave
	ret

/**
 * start in %r8
 * length in %r9
 */
identityMapMemory:
	enter	$0, $0

# they do not always start on page boundaries!!
	add		%r8, %r9
	add		$4095, %r9
	and		$-4096, %r9		# rounded up end
	and		$-4096, %r8		# rounded down start

#	push	%r9
#	push	%r8
#	mov		$identMapping_str, %r8
#	call	printf
#	pop		%r8
#	pop		%r9

0:
	call	virtualToIndices	# ignoring PML4 offset in %r10; there's only one anyway

	shl		$3, %r11		# every entry is 8 bytes
	add		$PDP, %r11		# this is where our PD should be mentioned
	mov		(%r11), %r10
	and		$-4096, %r10	# strip the informative bits to get the address
	shl		$3, %r12
	add		%r12, %r10		# this is where our PT should be mentioned
1:
	cmp		$0, (%r10)		# check whether the table actually exists already
	jne		2f
#make it
	push	%r10
	push	%r8
	mov		$pageTableCreate, %r8
	#call	printf
	pop		%r8
	pop		%r10
	
	push	%r13
	push	%r10
	push	%r9
	push	%r8
	mov		PT_end, %r8
	mov		$42, %r9
	call	identityMapMemory	# first map the area where the table will come
	#mov		PT_end, %r8
	#invlpg	(%r8)
	pop		%r8
	pop		%r9
	pop		%r10
	pop		%r13

	mov		PT_end, %r11
	invlpg	(%r11)				# invalidate the cache for that one
	add		$3, %r11			# present and r/w
	mov		%r11, (%r10)
	addq	$4093, %r11			# TODO make better
	mov		%r11, PT_end

	cmp		$0, (%r10)		# check again whether the table actually exists
	jne		2f

	push	%r10
	push	%r11
	mov		$pageTableFail, %r8
	#call	printf
	pop		%r11
	pop		%r10

	jmp		9f
2:
	mov		(%r10), %r10
	and		$-4096, %r10
	shl		$3, %r13
	add		%r13, %r10		# this is the entry we are looking for

	add		$3, %r8
	mov		%r8, (%r10)		# store identity mapping
#	invlpg	(%r8)
	add		$4093, %r8		# add a page minus the 3
	cmp		%r9, %r8
	jl		0b

9:
	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean cacheable
 */
setPagePresent:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	bts		$0, %rbx
	jmp		2f
1:
	btc		$0, %rbx		# bit 0 set means present
2:
	mov		%rbx, (%r8)

	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean cacheable
 */
setPageCacheable:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	btc		$4, %rbx
	jmp		2f
1:
	bts		$4, %rbx		# bit 4 set means not cacheable
2:
	mov		%rbx, (%r8)

	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean writable
 */
setPageWritable:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	bts		$1, %rbx
	jmp		2f
1:
	btc		$1, %rbx		# bit 1 means writable
2:
	mov		%rbx, (%r8)

	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean 
 * supervisor means levels 0, 1 and 2
 */
setPageSupervisorOnly:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	btc		$2, %rbx
	jmp		2f
1:
	bts		$2, %rbx		# bit 2 means user/supervisor
2:
	mov		%rbx, (%r8)

	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean 
 */
setPageGlobal:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	bts		$8, %rbx
	jmp		2f
1:
	btc		$8, %rbx		# bit 8 means global
2:
	mov		%rbx, (%r8)

	leave
	ret

/**
 * %r8 an address; the whole page will be affected
 * %r9 boolean 
 */
setPageExecutable:
	enter	$0, $0

	mov		%r9, %rax
	call	getPageTableEntry
	mov		(%r8), %rbx

	cmp		$0, %rax
	je		1f
	btc		$63, %rbx
	jmp		2f
1:
	bts		$63, %rbx		# bit 63 is the NX bit
2:
	mov		%rbx, (%r8)

	leave
	ret

