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
bootaddr = 0x7C00
bootaddr2 = 0x7E0		# times 16
kernel_addr = 0x1000	# times 16

video_mem_start = 0xB8000

PML4		= 0x100000		# paging tables; the one and only master
PDP			= 0x101000		# paging tables; the one and only PDP
PD_start	= 0x102000		# paging tables

# indexes:
gdt_code_segment = 0x8
gdt_data_segment = 0x10
gdt_tss_segment = 0x18	# NB: twice as big

# misc constants:
video_background = 0x2a	# green monochrome

