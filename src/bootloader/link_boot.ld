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
	. = 0x7C00;
	.bootloader : {
		*(.bootstrap16);
		*(.bootstrap16.data);
		. = 0x1fe;
		BYTE(0x55);
		BYTE(0xaa);
		_bootstrap_end = .;
		*(.bootstrap17);
		*(.bootstrap17*);
		*(.bootstrap32);
		*(.bootstrap32*);
		*(.bootstrap64);
		*(.bootstrap64*);
		_bootloader_end = .;
	}

	. = ASSERT(_bootstrap_end <= 0x7E00,"Bootstrap section too big! (>510 bytes)");
	. = ASSERT(_bootloader_end <= 0x9FFF,"Bootloader section too big! (>8.5 kilobytes)");
	. = ASSERT(_bootloader_end <= 0x8600,"Load more boot pages from disk (and then change this error)");

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

