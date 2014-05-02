README
======

_Brightness Control_ is an utility that can save the current brightness level of
an OS X machine and restore it at a later time.  This is particularly useful in
the case in which a user relies on a specific brightness value of his displays,
for example because it was set during a monitor calibration process, but he
does not want to give up the possibility of changing it at his own will under
some circumstances.

Usage
-----

When the application is launched a bulb icon is added to the status bar.  The
colour of the bulb tells the user at a glance the status of its display(s):

  * If the bulb is empty (black and white), the users has not saved yet a
    brightness value.
  * If the bulb is green, the current brightness value equals the saved one.
  * If the bulb is yellow, the current brightness value does not equal the
    saved one.

When the status bar icon is clicked, a contextual menu is presented to the
user.  The following items are shown:

  * A slider control, used to adjust the brightness.
  * _Show percentage_, used to display the current brightness value as a
    percentage in the status bar.
  * _Save_, used to save the current brightness value.
  * _Restore_, used to restore a previously saved brightness value.

Installation
------------

Users should get the binary distribution of the latest release from the
[Brightness Control Github repository][repo].  Developers or advanced users may
want to compile the program from the sources, in which case XCode 5 is the
only requirement.

[repo]: https://github.com/emcrisostomo/brightness-setter

Bug Reports
-----------

Bug reports can be sent directly to the authors.

-----

Copyright (C) 2014 Enrico M. Crisostomo

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
