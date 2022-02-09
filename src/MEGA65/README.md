# MEGA65 support files

This folder contains all the additional files needed to test the HyperRAM
controller on the MEGA65 platform.

The features provided by these files are:

* Top level file connecting everything together
* Clock synthesis
* HDMI output
* Limited keyboard support

### Testing on the MEGA65 hardware platform

In order to make use of the MEGA65 hardware platform we need to generate the
necessary clocks, and some way to start the test and see the result.

This section discusses the following:

* Clock synthesis
* MEGA65-specific support files

### Clock synthesis

As mentioned previously, controlling the physical I/O to the HyperRAM device
requires an additional clock (at twice the frequency) to get the correct timing.

This double-speed clock is generated using a single MMCM. This is done in the file
[src/MEGA65/clk.vhd](src/MEGA65/clk.vhd).

This file also generates a 40 MHz clock, but this is only used by the support files
needed for the MEGA65.

### MEGA65-specific support files

The MEGA65 comes with a keyboard and two visible LED's. In order to make use of
these I've copied the file `mega65kbd_to_matrix.vhdl` from the [MEGA65
project](https://github.com/MEGA65/mega65-core) and removed stuff I didn't need.

In this way, I can start the test by pressing the `RETURN` key, and I can watch
the progress of the test on the `POWER` LED and look for any errors on the
`Floppy` LED. The entire test runs for approximately 2 seconds.


