gamelib-x64
===========

Bootable game library for the Computer Organization course at Delft University of Technology. Designed to help students write a bootable game using x64 assembly. Inspired by the 32-bit [bootlib](https://github.com/m-ou-se/bootlib) project used for previous iterations of the Computer Organization course.

Requirements
===========

_These requirements have already been fulfilled if you are using the virtual machine provided for the lab. We will not provide support for compilation or linking errors if you are not using this virtual machine._

To build your game based on gamelib-x64, you need to ensure you are using a Linux distribution on a x86-64 architecture (i.e., 64-bit Linux on any modern Intel/AMD processor) with a recent version of GNU binutils to compile. In addition, you will need Qemu or Bochs (both emulators for a.o. the x86-64 platforrm) to test your game.

Getting started
===========

To get started on developing your game, execute the following steps:

 1.  Download a copy of gamelib-x64, using either `git clone` or the "Download ZIP" button to the right of this page.
 2.  Open a terminal and navigate to the root of the gamelib-x64 folder.
 3.  Execute `make` to compile gamelib-x64 against the default (empty) game.
 4.  Execute `make qemu` to launch the compiled game in the Qemu emulator.
 5.  If your machine is set up correctly, and you followed the steps closely, you should see a screen that reads "Booting from Hard Disk...".
 6.  Start development of your game by editing the `src/game/game.s` file.

To test your code, repeat steps 3 and 4  to compile and run your game.

API
===========

gamelib-x64 provides a restricted set of functions to its users to handle common IO operations. In your game you will be able to use the following functions (more information can be found in the `src/kernel/interface.s` file):

 -  `void setTimer(int16 reloadValue)`: Changes the interrupt rate of the timer, and thus the frequency of the game loop.
 -   `void putChar(int8 x, int8 y, int8 char, int8 color)`: Prints a single character to the screen with a specified color at a specified location.
 -  `int8 readKeyCode()`: Reads and returns a single byte from the keyboard buffer.

In addition, your game should provide the following functions to hook into the gamelib-x64 framework:

 -  `void gameInit()`: Called before the main event loop starts to allow for initialization of your game state.
 -  `void gameLoop()`: Called at every timer interrupt to allow your game to read input, update its state, and show output on the screen.

Limitations
===========

gamelib-x64 currently has the following limitations:

 -  The standard C library is unavailable, so there are no functions available other than our API and the functions you write.
 -  There is no memory management, i.e. no variant of `malloc`. You will have to reserve space for all necessary variables in a data section.
 -  The size of your executable (including code and data) is limited to about 58 KB.

Copyright
===========

Copyright (C) 2014 Otto Visser, Tim Hegeman

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

