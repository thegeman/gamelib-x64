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

.file "src/kernel/pic.s"

.section .kernel.data
PIC_init_str:				.asciz "* Initializing PIC subsystem...\n"
PIC_init_done_str:			.asciz "* Initializing PIC subsystem: done\n"
old_mask_str:				.asciz "old masks: %x, %x\n"
pic_irq_occured:				.asciz "*** IRQ %u occured ***\n"

MASTER_COMMAND	= 0x20
MASTER_DATA		= 0x21
SLAVE_COMMAND	= 0xA0
SLAVE_DATA		= 0xA1

.section .kernel

init_PIC:
	enter	$0, $0

	mov		$PIC_init_str, %r8
	#call	printf

# IMCR clear: TODO needed? depends on MP table info it seems...
	mov		$0x70, %al
	out		%al, $0x22
	mov		$0x00, %al
	out		%al, $0x23	# now signals should flow in old fashioned pic style

# remap the PICs (thanks IBM...)
	mov		$0, %rax
	in		$MASTER_DATA, %al		# save mask
	mov		%rax, %r9
	in		$SLAVE_DATA, %al		# save mask
	mov		%rax, %r10

	push	%r10
	push	%r9
	mov		$old_mask_str, %r8
	#call	printf

	mov		$0x11, %al				# start init; expect a ICW4
	out		%al, $MASTER_COMMAND
	out		%al, $SLAVE_COMMAND
	mov		$0x20, %al				# new vector offset; behind the exceptions
	out		%al, $MASTER_DATA
	mov		$0x28, %al
	out		%al, $SLAVE_DATA
	mov		$4, %al					# There is a slave
	out		%al, $MASTER_DATA
	mov		$2, %al					# cascade via master
	out		%al, $SLAVE_DATA
	mov		$0x01, %al				# 8086 mode
	out		%al, $MASTER_DATA
	out		%al, $SLAVE_DATA

	mov		%r9, %rax
	out		%al, $MASTER_DATA		# restore mask
	mov		%r10, %rax
	out		%al, $SLAVE_DATA		# restore mask

# now map the vector to handlers:
	mov		$0x20, %r8
	mov		$pic_irq_0_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_1_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_2_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_3_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_4_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_5_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_6_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_7_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_8_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_9_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_10_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_11_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_12_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_13_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_14_handler, %r9
	call	setIRQHandler

	inc		%r8
	mov		$pic_irq_15_handler, %r9
	call	setIRQHandler

	mov		$PIC_init_done_str, %r8
	#call	printf

	leave
	ret

# timer; goes often; so no printing :P
pic_irq_0_handler:
	enter	$0, $0
#	push	%r8

	#push	$0
	#mov		$pic_irq_occured, %r8
	#call	warning
	#pop		%r8

	#call	gui_mainloop
	call	gameLoop

	call	master_eoi
#	pop		%r8
	leave
	iretq

pic_irq_1_handler:
	enter	$0, $0
#	push	%r8

#	push	$1
#	mov		$pic_irq_occured, %r8
#	call	warning
#	pop		%r8

	call	ps2_bottom_half

	call	master_eoi
#	pop		%r8
	leave
	iretq

pic_irq_2_handler:
	enter	$0, $0
	push	%r8

	push	$2
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_3_handler:
	enter	$0, $0
	push	%r8

	push	$3
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_4_handler:
	enter	$0, $0
	push	%r8

	push	$4
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_5_handler:
	enter	$0, $0
	push	%r8

	push	$5
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_6_handler:
	enter	$0, $0
	push	%r8

	push	$6
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_7_handler:
	enter	$0, $0
	push	%r8

	push	$7
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	master_eoi

	pop		%r8
	leave
	iretq

pic_irq_8_handler:
	enter	$0, $0
	push	%r8

	push	$8
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_9_handler:
	enter	$0, $0
	push	%r8

	push	$9
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_10_handler:
	enter	$0, $0
	push	%r8

	push	$10
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_11_handler:
	enter	$0, $0
	push	%r8

	push	$11
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_12_handler:
	enter	$0, $0
	push	%r8

	push	$12
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_13_handler:
	enter	$0, $0
	push	%r8

	push	$13
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_14_handler:
	enter	$0, $0
	push	%r8

	push	$14
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

pic_irq_15_handler:
	enter	$0, $0
	push	%r8

	push	$15
	mov		$pic_irq_occured, %r8
	#call	warning
	pop		%r8

	call	slave_eoi

	pop		%r8
	leave
	iretq

master_eoi:
	enter	$0, $0
	push	%rax

	mov		$0x20, %al
	out		%al, $MASTER_COMMAND

	pop		%rax
	leave
	ret

slave_eoi:
	enter	$0, $0
	push	%rax

	mov		$0x20, %al
	out		%al, $MASTER_COMMAND
	out		%al, $SLAVE_COMMAND

	pop		%rax
	leave
	ret

