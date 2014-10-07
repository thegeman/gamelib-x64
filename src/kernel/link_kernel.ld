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

OUTPUT_FORMAT("binary","binary","binary")

SECTIONS {
	. = 0x10000;
	.kern : {
		*(.kernel);
		*(.kernel*);
		*(.game*);
		BYTE(0x42);
		_system_end = .;
	}

	. = ASSERT(_system_end <= 0x20000,"Load more kernel pages from disk (and then change this error)");
	. = ASSERT(_system_end <= 0x78400,"System initialization section too big! (>480 KB)");

	/DISCARD/ : {
		*(.debug_*)
		*(.note*)
		*(.indent)
		*(.comment)
		*(.stab)
		*(.stabstr)
		*(.eh_frame)
		*(.eh_frame_hdr)
	}
}

