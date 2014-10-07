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

.file "src/kernel/interrupts.s"

.section .kernel.data
interrupt_init_str:			.asciz "* Initializing interrupt handling subsystem...\n"
interrupt_init_done_str:	.asciz "* Initializing interrupt handling subsystem: done\n"

template_str:				.asciz "*** INTERRUPT (TODO) ***\n"
debug_str:					.asciz "*** DEBUG (TODO) ***\n"
breakpoint_str:				.asciz "*** BREAKPOINT (TODO) ***\n"
divZero_str:				.asciz "*** DIVIDE BY ZERO (TODO) ***\n"
nmi_str:					.asciz "*** NON MASKABLE INTERRUPT (TODO) ***\n"
overflow_str:				.asciz "*** OVERFLOW ON INTO CALL (TODO) ***\n"
OOB_str:					.asciz "*** OUT OF BOUNDS (TODO) ***\n"
security_exception_str:		.asciz "*** SECURITY EXCEPTION ***\n"
virt_fault_str:				.asciz "*** VIRTUALIZATION ERROR ***\n"
simd_fp_fault_str:			.asciz "*** SIMD FLOATING POINT ERROR ***\n"
mce_str:					.asciz "*** MACHINE CHECK EXCEPTION ***\n"
align_fault_str:			.asciz "*** ALIGNMENT FAULT ***\n"
fpu_exception_str:			.asciz "*** FPU EXCEPTION ***\n"
page_fault_str:				.asciz "*** PAGE FAULT: %x @ addr: %x ***\n"
gpf_str:					.asciz "*** GENERAL PROTECTION FAULT: %x @ %x ***\n"
ss_fault_str:				.asciz "*** STACK SEGMENT FAULT ***\n"
segment_not_present_str:	.asciz "*** SEGMENT NOT PRESENT ***\n"
inv_TSS_str:				.asciz "*** INVALID TSS ***\n"
coprocSegOverrun_str:		.asciz "*** CO PROCESSOR SEGMENT OVERRUN ***\n"
double_fault_str:			.asciz "*** DOUBLE FAULT ***\n"
dev_not_there_str:			.asciz "*** DEVICE NOT THERE ***\n"
invalid_opcode_str:			.asciz "*** INVALID OPCODE ***\n"

timer_rang_str:				.asciz "*** TIMER RANG ***\n"
spurious_str:				.asciz "*** SPURIOUS ***\n"

idtr:
	.word	4096	# full 256 interrupt table; 16 bytes per interrupt
	.quad	IDT

.section .kernel

init_interrupts:
	enter	$0, $0
	
	mov		$interrupt_init_str, %r8
	#call	printf

# fill the IDT:
	mov		$0, %r8					# start with vector 0: div/0
	mov		$divZero_handler, %r9	# load address of handler
	call	setExceptionHandler

	inc		%r8
	mov		$debug_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$nmi_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$breakpoint_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$overflow_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$oob_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$invalid_opcode_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$dev_na_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$doubleFault_handler, %r9
	call	setExceptionHandler

	inc		%r8			# number 9: Coprocessor Segment Overrun; doesn't seem to be in use?

	inc		%r8
	mov		$inv_TSS_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$segment_not_present_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$ss_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$gpf_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$page_fault_handler, %r9
	call	setExceptionHandler

	inc		%r8			# number 15: reserved

	inc		%r8
	mov		$fpu_exception_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$align_fault_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$mce_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$simd_fp_fault_handler, %r9
	call	setExceptionHandler

	inc		%r8
	mov		$virt_fault_handler, %r9
	call	setExceptionHandler

	mov		$30, %r8		# 21-29 are reserved
	mov		$security_exception_handler, %r9
	call	setExceptionHandler

# 31 is reserved as well; triple fault doesn't have a handler (at least not that we control)

# TODO software OS interrupts

	lidt	idtr	# load the IRQ table TODO: zero? and fill

# now test:
#	mov		$42, %rax
#	mov		$0, %r9
#	div		%r9

	mov		$interrupt_init_done_str, %r8
	#call	printf

	leave
	ret

/**
 * r8 = vector number
 * r9 = address of handler
 */
setExceptionHandler:
	enter	$0, $0
	push	%rax
	push	%rbx

	mov		$16, %rax					# 16 bytes per entry
	mul		%r8
	add		$IDT, %rax
	mov		%r9, %rbx					# use a register where you can address parts

	mov		%bx, (%rax)					# offset lower 2 bytes
	movb	$gdt_code_segment, 2(%rax)	# selector
	movb	$0, 3(%rax)					# selector, part 2
	movb	$0, 4(%rax)					# reserverd zero; useless op TODO?
	movb	$0b10001111, 5(%rax)		# type & attributes; present, 00 required privilege, trap gate
	shr		$16, %rbx					# next 2 bytes into bx
	mov		%bx, 6(%rax)				# offset middle 2 bytes
	shr		$16, %rbx					# next 4 btyes into ebx
	mov		%ebx, 8(%rax)				# offset high 4 bytes
	movl	$0, 12(%rax)				# reserverd zero; useless op TODO?

	pop		%rbx
	pop		%rax
	leave
	ret

/**
 * r8 = interrupt number
 * r9 = address of handler
 */
setIRQHandler:
	enter	$0, $0
	push	%rax
	push	%rbx

	mov		$16, %rax					# 16 bytes per entry
	mul		%r8
	add		$IDT, %rax
	mov		%r9, %rbx					# use a register where you can address parts

	mov		%bx, (%rax)					# offset lower 2 bytes
	movb	$gdt_code_segment, 2(%rax)	# selector
	movb	$0, 3(%rax)					# selector, part 2
	movb	$0, 4(%rax)					# reserverd zero; useless op TODO?
	movb	$0b10001110, 5(%rax)		# type & attributes; present, 00 required privilege, interrupt gate
	shr		$16, %rbx					# next 2 bytes into bx
	mov		%bx, 6(%rax)				# offset middle 2 bytes
	shr		$16, %rbx					# next 4 btyes into ebx
	mov		%ebx, 8(%rax)				# offset high 4 bytes
	movl	$0, 12(%rax)				# reserverd zero; useless op TODO?

	pop		%rbx
	pop		%rax
	leave
	ret

/**
 * Name		: TEMPLATE
 * Type		: Fault/Trap/Abort/IRQ
 * Errorcode: yes/no
 * RIP		: next instruction
 */
template_handler:
	cli		# needed? TODO
	push	%r8

	mov		$template_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: debug
 * Type		: Fault/Trap
 * Errorcode: no, but see debug registers
 * RIP		: fault? then faulty; for traps: the next
 */
debug_handler:
	cli		# needed? TODO
	push	%r8

	mov		$debug_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: breakpoint
 * Type		: Trap
 * Errorcode: no
 * RIP		: next instruction
 */
breakpoint_handler:
	cli		# needed? TODO
	push	%r8

	mov		$breakpoint_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Security Exception
 * Type		: ?
 * Errorcode: no
 * RIP		: ?
 */
security_exception_handler:
	cli		# needed? TODO
	push	%r8

	mov		$security_exception_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: virtualization exception
 * Type		: Fault
 * Errorcode: no
 * RIP		: ?
 */
virt_fault_handler:
	cli		# needed? TODO
	push	%r8

	mov		$virt_fault_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: SIMD floating point exception; TODO needs to be enabled
 * Type		: Fault
 * Errorcode: no; but see MXCSR register
 * RIP		: faulty instruction
 */
simd_fp_fault_handler:
	cli		# needed? TODO
	push	%r8

	mov		$simd_fp_fault_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: machine check; TODO needs to be enabled
 * Type		: Abort
 * Errorcode: no; but MSR can contain info
 * RIP		: depends...
 */
mce_handler:
	cli		# needed? TODO
	push	%r8

	mov		$mce_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: alignment check
 * Type		: Fault
 * Errorcode: yes: ?
 * RIP		: faulty instruction
 */
align_fault_handler:
	cli		# needed? TODO
	push	%r8

	mov		$align_fault_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: x87 floating point exception
 * Type		: Fault
 * Errorcode: no, but: exception information is available in the x87 status word register
 * RIP		: The saved instruction pointer points to the instruction which is
 * about to be executed when the exception occurred. The x87 instruction
 * pointer register contains the address of the last instruction which caused
 * the exception.
 */
fpu_exception_handler:
	cli		# needed? TODO
	push	%r8

	mov		$fpu_exception_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: page fault
 * Type		: Fault
 * Errorcode: yes; bits 0-4 to interpret, plus cr2 contains virtual address; see http://wiki.osdev.org/Page_fault
 * RIP		: faulty instruction
 */
page_fault_handler:
	cli		# needed? TODO
	enter	$0, $0

	push	%r8

	mov		%cr2, %r8
	push	%r8
	push	16(%rsp)
	mov		$page_fault_str, %r8
	#call	error

#	pop		%r8
#	pop		%r8
#	pop		%r8
	call	halt

#leave
#	iretq

/**
 * Name		: General Protection Fault
 * Type		: Fault
 * Errorcode: yes: segment selector index if applicable; otherwise 0
 * RIP		: faulty instruction
 */
gpf_handler:
	cli		# needed? TODO
	enter	$0, $0

	push	%r8

	push	16(%rbp)
	push	8(%rbp)
	mov		$gpf_str, %r8
	#call	error

#	pop		%r8
#	pop		%r8
#	pop		%r8

	call	halt

	# leave
#	iretq

/**
 * Name		: stack-segment fault
 * Type		: Fault
 * Errorcode: yes: stack segment selector index
 * RIP		: faulty instruction
 */
ss_handler:
	cli		# needed? TODO
	push	%r8

	mov		$ss_fault_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: segment not present
 * Type		: Fault
 * Errorcode: yes: segment selector index
 * RIP		: faulty instruction
 */
segment_not_present_handler:
	cli		# needed? TODO
	push	%r8

	mov		$segment_not_present_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Invalid TSS
 * Type		: Fault
 * Errorcode: yes: the selector index
 * RIP		: ?
 */
inv_TSS_handler:
	cli		# needed? TODO
	push	%r8

	mov		$inv_TSS_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: co-proc segment overrun
 * Type		: Fault
 * Errorcode: no
 * RIP		: ?
 */
coprocSegOverrun_handler:
	cli		# needed? TODO
	push	%r8

	mov		$coprocSegOverrun_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Double fault (or irq 0? )
 * Type		: Abort
 * Errorcode: yes: content?
 * RIP		: undefined !
 */
doubleFault_handler:
	cli		# needed? TODO
	push	%r8

	mov		$double_fault_str, %r8
	#call	error

	call	halt	# not much we can do at this point?
	#pop		%r8
	#iretq	# TODO does this make sense? Perhaps go somewhere else?

/**
 * Name		: Device not available; where device is FPU/MMX/SSE
 * Type		: Fault
 * Errorcode: no
 * RIP		: faulty instruction
 */
dev_na_handler:
	cli		# needed? TODO
	push	%r8

	mov		$dev_not_there_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Invalid opcode
 * Type		: Fault
 * Errorcode: no
 * RIP		: faulty instruction
 */
invalid_opcode_handler:
	cli		# needed? TODO
	push	%r8

	mov		$invalid_opcode_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Out of Bounds exception
 * Type		: Fault
 * Errorcode: no
 * RIP		: faulty instruction
 */
oob_handler:
	cli		# needed? TODO
	push	%r8

	mov		$OOB_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Divide by 0
 * Type		: Fault
 * Errorcode: no
 * RIP		: faulty instruction
 */
divZero_handler:
	cli
	push	%r8

	mov		$divZero_str, %r8
	#call	error 

	call	halt				# TODO	
	#pop		%r8
	#iretq

/**
 * Name		: Non Maskable Interrupt
 * Type		: IRQ
 * Errorcode: no
 * RIP		: next instruction
 */
nmi_handler:
	cli
	push	%r8

	mov		$nmi_str, %r8
	#call	error

	pop		%r8
	iretq

/**
 * Name		: Overflow on INTO call
 * Type		: Trap
 * Errorcode: no
 * RIP		: next instruction
 */
overflow_handler:
	cli
	push	%r8

	mov		$overflow_str, %r8
	#call	error

	pop		%r8
	iretq

spurious_handler:
	push	%r8

	mov		$spurious_str, %r8
	#call	info

	pop		%r8
	iretq
	
