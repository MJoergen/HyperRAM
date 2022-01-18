# HyperRAM

This repository is my attempt at a portable HyperRAM controller.  I've looked
at several other implementations, and they all seemed lacking in various
regards.

I'm testing my HyperRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (revision 3).  It contains the [8 MB
HyperRAM](doc/66-67WVH8M8ALL-BLL-938852.pdf) chip from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the HyperRAM device is
`IS66WVH8M8BLL-100B1LI`, which indicates a 64 Mbit, 100 MHz version with 3.0 V
supply and a single-ended clock.

The HyperRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).


## Testing in simulation

In order to test my HyperRAM controller I've found a [simulation
model](HyperRAM_Simulation_Model) (downloaded from
[Cypress](https://www.cypress.com/documentation/models/verilog/verilog-model-hyperbus-interface))
of a real [Cypress HyperRAM device](doc/s27kl0642.pdf).

Using a (presumably correct) simulation model is vital when developing. Because
this allows testing the implementation in simulation, and thus finding and
fixing bugs much faster.

However, since the HyperRAM in the MEGA65 is a different device (and with
different timings) than the above mentioned simulation model, I've modified the
simulation model by adding timing values (and default configuration values)
specific for the MEGA65 HyperRAM device, see lines 219-249 in
[HyperRAM\_Simulation\_Model/s27kl0642.v](HyperRAM_Simulation_Model/s27kl0642.v)

## Overview of project contents

The project consists of the following:

* Main HyperRAM controller
* Traffic generator
* Clock synthesis
* MEGA65-specific support files

These are all discussed below.

### Main HyperRAM controller

I've split the HyperRAM controller implementation into two parts:

* The state machine ([hyperram\_ctrl.vhd](hyperram_ctrl.vhd)), running in a
  single clock domain, same as HyperRAM device, i.e. 100 MHz.
* The I/O ports ([hyperram\_io.vhd](hyperram_io.vhd)), using two additional
  clocks for correct timing: A 100 MHz clock phase shifted 90 degrees. and a
  double-speed clock at 200 MHz.

The phase shifted clock is used to delay the HyperRAM clock signal `CK`
relative to the transitions on the `DQ` signal. This ensures correct timing of
`t_IS` and `t_IH` during WRITE operation.

The double-speed clock is used to manually sample the `DQ` signal during READ
operation.

The user interface to the HyperRAM controller is a 16-bit Avalon Memory Map
interface with support for burst operations, see
[doc/Avalon\_Interface\_Specifications.pdf](doc/Avalon_Interface_Specifications.pdf).
This is a very common bus interface, and quite easy to use.


### Traffic generator

The traffic generator's sole purpose is to test the interface between the
HyperRAM controller and the physical HyperRAM device. It does this by
generating first a sequence of WRITE operations (writing pseudo-random data to
the entire RAM), and then a corresponding sequence of READ operations,
verifying that the correct values are read back again.

The traffic generator has a single control input (`start_i`) that starts the above mentioned
process. There are two output signals indicating progress:

* `led_active`: indicates the test is in progress.
* `led_error`: indicates at least one error has occurred.


### Clock synthesis

As mentioned previously, controlling the physical I/O to the HyperRAM device
requires two additional clocks:
* A 100 MHz clock phase shifted 90 degrees.
* A 200 MHz clock.

Both are generated using a single MMCM. This is done in the file
[src/clk.vhd](src/clk.vhd).

This file also generates a 40 MHz clock, but this is only used by the support files
needed for the MEGA65.

### MEGA65-specific support files


### Running simulation

To perform the simulation test, just start up Vivado and load the project file [top.xpr](top.xpr).

In simulation I've generated the following waveform:
![waveform](waveform.png)



## Timing constraints

The timing parameters are given in the table below (taken from the
[documentation](doc/66-67WVH8M8ALL-BLL-938852.pdf)):

```
Parameter                                | Symbol | Min  | Max  | Unit
Chip Select High Between Transactions    | t_CSHI | 10.0 |  -   | ns
HyperRAM Read-Write Recovery Time        | t_RWR  | 40   |  -   | ns
Chip Select Setup to next CK Rising Edge | t_CSS  |  3   |  -   | ns
Data Strobe Valid                        | t_DSV  |  -   | 12   | ns
Input Setup                              | t_IS   |  1.0 |  -   | ns
Input Hold                               | t_IH   |  1.0 |  -   | ns
HyperRAM Read Initial Access Time        | t_ACC  | 40   |  -   | ns
Clock to DQs Low Z                       | t_DQLZ |  0   |  -   | ns
HyperRAM CK transition to DQ Valid       | t_CKD  |  1   |  7   | ns
HyperRAM CK transition to DQ Invalid     | t_CKDI |  0.5 |  5.2 | ns
Data Valid                               | t_DV   |  2.7 |  -   | ns
CK transition to RWDS valid              | t_CKDS |  1   |  7   | ns
RWDS transition to DQ Valid              | t_DSS  | -0.8 |  0.8 | ns
RWDS transition to DQ Invalid            | t_DSH  | -0.8 |  0.8 | ns
Chip Select Hold After CK Falling Edge   | t_CSH  | 0    |  -   | ns
Chip Select Inactive to RWDS High-Z      | t_DSZ  | -    |  7   | ns
Chip Select Inactive to DQ High-Z        | t_OZ   | -    |  7   | ns
HyperRAM Chip Select Maximum Low Time    | t_CSM  | -    |  4.0 | us
Refresh Time                             | t_RFH  | 40   |  -   | ns
```

The symbol names refer to the following figure (taken from the [Cypress HyperRAM datasheet](doc/s27kl0642.pdf)):
![timing diagram](Timing_Diagram.png)

