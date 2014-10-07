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

.arch generic64

#memory addresses:
kernel_stack_top= 0x00010000	# ~28 KiB
rsp0_stack_top	= 0x00094000
rsp1_stack_top	= 0x00096000
rsp2_stack_top	= 0x00098000	# rsp stacks 8 KiB
IST1_stack_top	= 0x00099000
IST2_stack_top	= 0x0009A000
IST3_stack_top	= 0x0009B000
IST4_stack_top	= 0x0009C000
IST5_stack_top	= 0x0009D000
IST6_stack_top	= 0x0009E000
IST7_stack_top	= 0x0009F000	# IST stacks 4 KiB

video_mem_start	= 0xB8000

IDT				= 0x3000	# 4KiB large

TSS				= 0x00F98	# The 64 bit TSS
RSP0			= 0x00F9C	# 
RSP1			= 0x00FA4	#
RSP2			= 0x00FAC	#
IST1			= 0x00FBC	#
IST2			= 0x00FC4	#
IST3			= 0x00FCC	#
IST4			= 0x00FD4	#
IST5			= 0x00FDC	#
IST6			= 0x00FE4	#
IST7			= 0x00FEC	#
TSS_IOPB_addr	= 0x00FFE
IOPB			= 0x01000	# 8KiB of IO Permission Map

PML4			= 0x100000	# paging tables
PDP				= 0x101000	# paging tables
PD_0			= 0x102000	# paging tables

# indexes:
gdt_code_segment = 0x8
gdt_data_segment = 0x10
gdt_tss_segment	 = 0x18	# NB: twice as big

# misc constants:
normal_colour	= 0x0F	# white on black
error_colour	= 0x0C	# bright red on black
warning_colour	= 0x0E	# yellow on black
info_colour		= 0x0A	# light green on black
debug_colour	= 0x07	# light gray on black

# some macros:
.ifndef __PUSHAQ__
.set	__PUSHAQ__, 1
.macro pushaq
	push	%rax
	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi
	push	%rsi
.endm
.endif

.ifndef __POPAQ__
.set	__POPAQ__, 1
.macro popaq
	pop		%rsi
	pop		%rdi
	pop		%rdx
	pop		%rcx
	pop		%rbx
	pop		%rax
.endm
.endif

