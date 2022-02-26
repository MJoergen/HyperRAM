# Example Design

This folder contains a complete example design written for the MEGA65 platform.
It consists of:

* Clock synthesis
* Trafic generator
* HyperRAM controller
* MEGA65 support module (keyboard and video)
* Top-level file connecting all the above


## Clock synthesis

Controlling the physical I/O to the HyperRAM device requires a total of three clocks:

* `clk_x1` : This is the HyperRAM clock @ 100 Mhz.
* `clk_x2` : This is a double speed clock @ 200 MHz.
* `clk_x2_del` : this is a phase-delayed double speed clock @ 200 MHz.

These clocks are generated using a single MMCM. This is done in the file
[clk.vhd](clk.vhd).  Even though `clk_x1` is running at the same frequency as
the FPGA clock input, it is important that the HyperRAM controller is connected
to the clock output (`clk_x1`) of the MMCM, rather than the FPGA clock, in
order to ensure correct relative phase shifts.


## Trafic generator

The trafic generator's sole purpose is to test the HyperRAM controller. It
does this by generating first a sequence of WRITE operations (writing
pseudo-random data to the entire HyperRAM device), and then a corresponding
sequence of READ operations, verifying that the correct values are read back
again.

The trafic generator has a single control input (`start_i`) that starts the
above mentioned process. There are two output signals indicating progress:

* `active_o`: indicates the test is in progress.
* `error_o`: indicates at least one error has occurred.


## HyperRAM controller
This is the Device-Under-Test, and is described more detailed in
[src/hyperram](../hyperram/README.md).


## MEGA65 support module (keyboard and video)

The purpose of this module is to provide support for keyboard input and video
output.  It's all encapsulated in a single module to keep the top-level file
simple.


## Top-level file

The top-level file contains no logic of its own, and only instantiates other modules.

One thing to note is that the top-level contains the two constants:

* `C_HYPERRAM_FREQ_MHZ` : This controls the HyperRAM device clock speed. The
  maximum value supported by the MEGA65 platform is 100 MHz.
* `C_HYPERRAM_PHASE`    : This is used to fine-tune the phase of the
  double-speed clock `clk_x2_del` used to control the HyperRAM I/O ports. The
  value chosen here is obtained by trial-and-error, where empirically an
  interval of working values was determined and the centre of this interval was
  chosen.

These two parameters are used to control the clock synthesis in
[clk.vhd](clk.vhd). You can just leave them at their default values.

