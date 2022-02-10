# Overview of HyperRAM controller

I've split the HyperRAM controller implementation into three parts:

* The state machine ([hyperram\_ctrl.vhd](hyperram_ctrl.vhd)), running in a
  single clock domain, same as HyperRAM device, i.e. 100 MHz.
* The I/O ports ([hyperram\_io.vhd](hyperram_io.vhd)), using two additional
  clocks (one phase shifted) at double-speed (200 MHz) for correct timing of
  the HyperRAM I/O signals.
* The initial configuration of the HyperRAM
  ([hyperram\_config.vhd](hyperram_config.vhd)), running at the HyperRAM clock
  speed, i.e. 100 MHz.

The above three entities are described in more detail further down in this
file.

The three entities are instantiated and connected in a wrapper
file ([hyperram.vhd](hyperram.vhd)).

## `hyperram_config.vhd`

This is the HyperRAM "configurator".
It performs two functions:

* Wait until the HyperRAM device is operational after reset.
* Perform a write to configuration register 0 to set latency mode.

I've chosen to implement it as an Avalon MM "sandwich" to be connected
directly between the client and the main state machine.

## `hyperram_ctrl.vhd`

This is the main state machine of the HyperRAM controller.
The purpose is to implement the HyperBus protocol, i.e.
to decode the Avalon MM requests and generate the control
signals for the HyperRAM device.

The user interface to the HyperRAM controller is a 16-bit [Avalon Memory
Map](../../doc/Avalon_Interface_Specifications.pdf) interface with support for burst
operations.  This is a very common bus interface, and quite easy to use.

## `hyperram_io.vhd`

This is the HyperRAM I/O connections.  The additional clock `clk_x2_i` is used
to drive the `DQ`/`RWDS` output and to sample the `DQ`/`RWDS` input.  The
additional clock `clk_x2_del_i` is used to drive the `CK` output.

The phase shifted clock is used to delay the HyperRAM clock signal `CK`
relative to the transitions on the output `DQ` signal. This ensures correct
values of the timing parameters `t_IS` and `t_IH` during WRITE operation, see
below.

The non-phase shifted clock is used to sample the `DQ` input signal during READ
operation.

From the above it follows that the HyperRAM device is phase shifted relative to
the FPGA. This is done to satisfy the `t_CKD` timing parameter.  The actual
amount of phase shift required is likely both board and device dependent. On
the MEGA65 a phase shift of 180 degrees is seen to work, and in such case we
could alternatively just use the falling edge of `clk_x2_i`.  However, I've
chosen to keep the general phase shifted clock for greater flexibility and to
make [porting](../../PORTING.md) to other platforms easier.

In the above it is assumed that the timing parameter `t_CKD` is constant for
any given specific HyperRAM device, even though the datasheet allows for great
variation.

### Timing parameters

The timing parameters are given in the table below (taken from the
[documentation](../../doc/66-67WVH8M8ALL-BLL-938852.pdf)):

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

The symbol names refer to the following figure (taken from the [Cypress HyperRAM datasheet](../../doc/s27kl0642.pdf)):
![timing diagram](../../doc/Timing_Diagram.png)


