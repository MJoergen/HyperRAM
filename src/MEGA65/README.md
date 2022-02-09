# MEGA65 support files

This folder contains all the additional files needed to test the HyperRAM
controller on the MEGA65 platform.

The features provided by these files are:

* Clock synthesis
* HDMI output
* Limited keyboard support

## Clock synthesis

As mentioned previously, controlling the physical I/O to the HyperRAM device
requires two additional clocks (at twice the frequency, but with non-zero phase
shift) to get the correct timing.

This double-speed clock is generated using a single MMCM. This is done in the file
[clk.vhd](clk.vhd). Note that all the HyperRAM clocks are
generated from this single MMCM. That includes the HyperRAM main clock (at 100 MHz),
which is the same speed as the board clock. It's important that the HyperRAM controller
is connected to a clock output of the MMCM, to ensure correct relative phase shifts.

A separate file [clk_mega65.vhd](clk_mega65.vhd) generates a 40 MHz keyboard
clock and a 74.25 MHz video clock for the HDMI output.

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


