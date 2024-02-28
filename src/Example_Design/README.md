# Example Design

This folder contains a complete example design written for the MEGA65 platform.
It consists of:

* Clock synthesis
* Core example design (used for both synthesis and simulation)
* MEGA65 support module (UART, keyboard, and video)
* Top-level file connecting all the above

## Clock synthesis

Controlling the physical I/O to the HyperRAM device requires a total of three clocks:

* `clk`          : This is the HyperRAM clock @ 100 Mhz.
* `clk_del`      : This is the 90 degrees phase-delayed clock
* `delay_refclk` : This is a 200 MHz clock for IDELAYCTRL.

These clocks are generated using a single MMCM. This is done in the file
[clk.vhd](clk.vhd).  Even though `clk` is running at the same frequency as
the FPGA clock input, it is important that the HyperRAM controller is connected
to the clock output (`clk`) of the MMCM, rather than the FPGA clock, in
order to ensure correct relative phase shifts.


## Core example design (used for both synthesis and simulation)

This consists of
* Traffic generator
* HyperRAM controller

### Traffic generator

The traffic generator's sole purpose is to test the HyperRAM controller. It
does this by generating first a sequence of WRITE operations (writing
pseudo-random data to the entire HyperRAM device), and then a corresponding
sequence of READ operations, verifying that the correct values are read back
again.

The traffic generator has a single control input (`start_i`) that starts the
above mentioned process. There are a number of output signals indicating progress:

* `active_o`      : indicates the test is in progress.
* `count_error_o` : indicates number of errors seen so far.
* `address_o`     : in case of error, last address read from.
* `data_read_o`   : in case of error, last value read.
* `data_exp_o`    : in case of error, expected value read.

### HyperRAM controller
This is the Device-Under-Test, and is described more detailed in
[src/hyperram](../hyperram/README.md).


## MEGA65 support module (UART, keyboard, and video)

The purpose of this module is to provide support for keyboard input and video
output.  It's all encapsulated in a single module to keep the top-level file
simple.


## Top-level file

The top-level file contains no logic of its own, and only instantiates other modules.

