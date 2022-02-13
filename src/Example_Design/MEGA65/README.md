# MEGA65 support module (keyboard and video)

The purpose of this module is to provide support for keyboard input and video
output.  It's all encapsulated in a single module to keep the top-level file
simple.

## HDMI output

The HDMI code generates a 1280x720 @ 60 Hz image.
It shows a string of characters: `PPPFFFAAAAAAWWWWRRRR`,
where:

* `PPP` is the phase shift in angles.
* `FFF` is the frequency in MHz.
* `AAAAAÀ` is the hex address in units of words.
* `WWWW` is the hex value written.
* `RRRR` is the hex value read.

## Limited keyboard support

The MEGA65 comes with a keyboard and two visible LED's. In order to make use of
these I've copied the file `mega65kbd_to_matrix.vhdl` from the [MEGA65
project](https://github.com/MEGA65/mega65-core) and removed stuff I didn't need.

In this way, I can start the test by pressing the `RETURN` key, and I can watch
the progress of the test on the `POWER` LED and look for any errors on the
`Floppy` LED. The entire test runs for approximately 2 seconds.

A separate file [clk_mega65.vhd](clk_mega65.vhd) generates a 40 MHz keyboard
clock and a 74.25 MHz video clock for the HDMI output.


