# HyperRAM

This repository is my attempt at a HyperRAM controller for the Xilinx Artix 7
FPGA.

I've looked at several other implementations, and they all seemed lacking in
various regards.

So this is a complete rewrite from scratch, and it's provided with a
[MIT license](LICENSE).


## Testing in simulation

In order to test my HyperRAM controller I've found a [simulation
model](HyperRAM_Simulation_Model) (downloaded from
[Cypress](https://www.cypress.com/documentation/models/verilog/verilog-model-hyperbus-interface)).

Using a (presumably correct) simulation model is vital when developing. Because
this allows testing the implementation in simulation, and thus finding and
fixing bugs much faster.


## Testing on hardware

I'm testing my HyperRAM controller on the [MEGA65](https://mega65.org/)
hardware platform.  It contains the [8 MB HyperRAM
chip](doc/66-67WVH8M8ALL-BLL-938852.pdf) from ISSI (Integrated Silicon Solution
Inc.).  Specifically, the part number is `IS66WVH8M8BLL-100B1LI`, which
indicates a 3.0 V 100 MHz version.

Note that this device is different from the simulation model. So I need to
update the simulation with the timing characteristice of this particular
device.

## Design notes

I've split the controller implementation into two parts:

* The state machine, running in a single clock domain.
* The I/O ports, using multiple additional clocks for correct timing.

The most complicated part is when to sample the DQ signal upon read.  Since
RWDS and DQ change synchronously, the solution I've decided on is to delay the
RWDS signal by a quarter clock cycle, and then use that as a clock to sample
the DQ signal. It remains to be seed, whether this is a stable solution.

