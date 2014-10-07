/*
This file is part of gamelib-x64.

Copyright (C) 2014 Tim Hegeman

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

.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

.section .game.text

gameInit:
	ret

gameLoop:
	# Check if a key has been pressed
	call	readKeyCode
	cmpq	$0, %rax
	je		1f
	# If so, print a 'Y'
	movb	$'Y', %dl
	jmp		2f

1:
	# Otherwise, print a 'N'
	movb	$'N', %dl

2:
	movq	$0, %rdi
	movq	$0, %rsi
	movb	$0x0f, %cl
	call	putChar

	ret
