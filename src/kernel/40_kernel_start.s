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

.file "src/kernel/40_kernel_start.s"

.section .kernel.data
largest_cpuid_str:	.asciz "Largest basic cpuid function number supported: %d\n"
vendor_str:			.asciz "Vendor ID: %s\n"
cpu_info_str:		.asciz "CPU type: %d, family: %d, model: %d, stepping: %d\n"
cpu_extended_str:	.asciz "CPU Extended: a:%x, b:%x, c:%x, d:%x\n"
flags_str:			.asciz "CPU info: %x, flags: d: %x, c: %x\n"
kernel_str:			.asciz "Kernel starting...\n"
halt_str:			.asciz "--- System ready ---\n"
cr0_str:			.asciz "cr0: %x\n"
osvw_count_str:		.asciz "Hardware eratum known count: %u\n"

OSVW_MSR0 = 0xC0010140

.section .kernel
	call _kernel_entry_point

_kernel_entry_point:
	# To set up a stack, we simply set the rsp register to point to the top of
	# our stack (as it grows downwards).
	mov		$kernel_stack_top, %rsp		# kernel gets different stack than the bootloader
	mov		%rsp, %rbp					# not sure whether it's needed, but it's cleaner :P

	#movl	$0x07690748,0xb8000
	#mov		$video_mem_start, %eax
	#mov		%eax, video_current_char

	mov		$kernel_str, %r8
	#call	printf

# IO Permission Map and the one and only TSS:
	movw	$(IOPB-TSS), TSS_IOPB_addr	# TODO zero the map and fill meaningfuly?
	movb	$7, (IOPB+8000)				# it needs to end with 3 1's
	movq	$rsp0_stack_top, RSP0		# load the stack for interrupts
	mov		$gdt_tss_segment, %rax		# load the tss descriptor number
	ltr		%ax							# load the tss

# do some checks
	call	cpuid_test

# now initialize all our subsystems one by one; think of dependencies!
	call	init_interrupts		# we need to get some basic interrupts going
	call	init_memory			# almost everything else appreciates working memory management
	call	init_PIC			# PIC before APIC
	call	init_ps2

	# TODO set CR4.OSXMMEXCPT to 1; cr4, fsgsbase?
# TODO cr4.tsd? cr4.pge? pce?
	mov		%cr4, %rax
	push	%rax
	mov		$cr0_str, %r8
	#call	printf
	bts		$6, %rax			# enable MCE
	mov		%rax, %cr4

# enable caches (cr0.cd -> 0); not needed for qemu/kvm, but bochs needs it
# TODO: cr0.MP? cr0.wp?
	mov		%cr0, %rax
	push	%rax
	mov		$cr0_str, %r8
	#call	printf
	btr		$29, %rax			# AMD book says ignored; Bochs disagrees
	btr		$30, %rax			# cache disable to zero means cache enable
	mov		%rax, %cr0


# TODO:
# enable SSE (cr4.osfxsr -> 1 also: cr4.osxmm.xcpt -> 1)?
# EFER.SCE, nxe, lmsle? ffxsr? tce?
# lldt ?

# this is the point where we should kinda sorta be ready for interrupts...
# TODO mask and enable
	sti

	# Now that everything is up and running, we enable the watchdog and let the scheduler take over
# TODO check whether there is a watchdog
#	mov		$0xC0010074, %rcx
#	mov		$0x42424242, %rax
#	wrmsr

	# start the periodic timer
	mov		$19886, %rdi
	call	setTimer

	#call	init_gui			# last but not least: a text gui :)
	call	gameInit

# The end (for now)
halt:
#	cli
	mov		$halt_str, %r8
	#call	info
9:
	hlt								# Halt the processor.
	jmp		9b

# displays the vendor ID string as well as the highest calling parameter that the CPU supports.
cpuid_test:
	enter	$16, $0

	mov		$0, %rax		# get highest supported function and vendor ID
	cpuid

	mov		%ebx, -16(%rbp)
	mov		%edx, -12(%rbp)
	mov		%ecx, -8(%rbp)	# the name
	movb	$0, -4(%rbp)	# the name
	mov		%rax, %r11		# highest supported basic function

	lea		-16(%rbp), %rax
	push	%rax
	mov		$vendor_str, %r8
	#call	printf

	push	%r11
	mov		$largest_cpuid_str, %r8
	#call	printf

# obey result of previous call; check if we can call this function
	cmp		$1, %r11
	jl		9f

	mov		$1, %rax
	cpuid

	mov		%rax, %r15	# keep backup
	mov		%rbx, %r14	# keep backup
	mov		%rcx, %r13	# keep backup
	mov		%rdx, %r12	# keep backup

	push	%rcx
	push	%rdx
	push	%rbx
	mov		$flags_str, %r8
	#call	printf

# TODO check bit 9 of rdx, indicates APIC

	mov		%r15, %rax
	and		$0x0F, %rax
	push	%rax		# stepping

	mov		%r15, %rax
	mov		%r15, %rbx
	and		$0xF0, %rax
	and		$0x0F0000, %rbx
	shr		$4, %rax
	shr		$12, %rbx	# shr 16, shl 4
	add		%rbx, %rax	# TODO for amd only when family is 15...
	push	%rax		# model

	mov		%r15, %rax
	mov		%r15, %rbx
	and		$0x0F00, %rax
	and		$0x0FF00000, %rbx
	shr		$8, %rax
	add		%rbx, %rax	# TODO for amd only when family is 15...
	push	%rax		# family

	mov		%r15, %rax
	and		$0x3000, %rax
	shr		$12, %rax
	push	%rax		# type

	mov		$cpu_info_str, %r8
	#call	printf

	mov		$0x80000001, %rax	# Extended-function 8000001h.
	cpuid						# Now EDX = extended-features flags.
	push	%rdx
	push	%rcx
	push	%rbx
	push	%rax
	mov		$cpu_extended_str, %r8
	#call	printf

# check for hardware eratums
	bt		$9, %ecx
	jnc		9f
	mov		$OSVW_MSR0, %rcx
	rdmsr
	push	%rax
	mov		$osvw_count_str, %r8
	#call	printf


9:
	leave
	ret

