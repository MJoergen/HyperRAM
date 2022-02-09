# HyperRAM

This repository is my attempt at a (reasonably) portable HyperRAM controller.
I'm writing my own implementation because I've looked at several other
implementations, and they all seemed lacking in various regards (features,
stability, portability, etc.)

The HyperRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

## Features

This implementation has support for:

* Maximum HyperRAM clock speed of 100 MHz
* burst mode
* variable latency
* configuration registers read and write
* identification registers read and write
* 16-bit Avalon Memory Map interface including burst mode

All the source files for the HyperRAM controller are in the
[src/hyperram](src/hyperram) directory, and all files needed for simulation are
in the [simulation](simulation) directory.


## Development platform

I'm testing my HyperRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (revision 3).  It contains the [8 MB
HyperRAM](doc/66-67WVH8M8ALL-BLL-938852.pdf) chip from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the HyperRAM device is
`IS66WVH8M8BLL-100B1LI`, which indicates a 64 Mbit, 100 MHz version with 3.0 V
supply and a single-ended clock.


## Further reading
The documentation for this HyperRAM controller is divided into
different files:

* [Porting guideline](PORTING.md)
* [Detailed design description](src/hyperram/README.md)


### Testing in simulation

In order to test my HyperRAM controller I've found a [simulation
model](HyperRAM_Simulation_Model) (downloaded from
[Cypress](https://www.cypress.com/documentation/models/verilog/verilog-model-hyperbus-interface))
of a real [Cypress HyperRAM device](doc/s27kl0642.pdf).

Using a (presumably correct) simulation model is vital when developing. Because
this allows testing the implementation in simulation, and thus finding and
fixing bugs much faster.

### Running simulation

To perform the simulation test just start up Vivado, load the project file
[top.xpr](top.xpr), and select "Run Simulation".

This generates the following waveform:
![waveform](doc/waveform.png)

In simulation mode, only 8 writes and 8 reads are performed, to keep the
simulation time reasonable. The above waveform shows these 16 transactions.
Specifically, at the top we see `led_active` being first asserted and then
de-asserted, while `led_error` remains de-asserted all the time.


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


