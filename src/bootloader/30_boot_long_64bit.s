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

.file "src/bootloader/30_boot_long_64bit.s"

.section .bootstrap64.data

.section .bootstrap64
.code64
.global _cont64long

_cont64long:
	cli								# Clear the interrupt flag. TODO superfluos?
	mov		$gdt_data_segment, %ax	# Set the A-register to the data descriptor.
	mov		%ax, %fs				# Set the F-segment to the data descriptor
	mov		%ax, %gs				# Set the G-segment to the data descriptor
									# NB: ds, es, not used in 64 bit mode; setting them anyway to all be the same:

	mov		%ax, %ds				# Set the D-segment to the data descriptor
	mov		%ax, %es				# Set the E-segment to the data descriptor

	mov		%ax, %ss				# setting SS; said to be unused, but seems used with interrupt handling anyway
	and		$-16, %rsp				# ands RSP with 0xFFF...FFF0, aligning the stack with the next lowest 16-byte boundary. TODO needed?

	push	$64
	mov		$bit_str, %r8
	# call	printf64
	pop		%rax

# load the kernel from disk

# Time to start loading a kernel or something
	jmp		0x10000;				# that's where we hard code our kernel starts

# The end
halt:
	hlt								# Halt the processor.
	jmp	halt

