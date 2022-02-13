# HyperRAM

This repository is my attempt at a portable HyperRAM controller.  I'm writing
my own implementation because I've looked at several other implementations, and
they all seemed lacking in various regards (features, stability, portability,
etc.)

The HyperRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

## Features

This implementation has support for:

* maximum HyperRAM clock speed of 100 MHz.
* variable latency.
* configuration registers read and write.
* identification registers read.
* automatic configuration of latency mode upon reset.
* 16-bit [Avalon Memory Map interface](doc/Avalon_Interface_Specifications.pdf) including burst mode.

All the source files for the HyperRAM controller are in the
[src/hyperram](src/hyperram) directory, and all files needed for simulation are
in the [simulation](simulation) directory.

Porting to another platform may require hand-tuning of some clock parameters,
see the section on [porting](PORTING.md).


## Example Design

I'm testing this HyperRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (revision 3).  It contains the 8 MB HyperRAM chip ([link to
datasheet](doc/66-67WVH8M8ALL-BLL-938852.pdf)) from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the HyperRAM device on the
MEGA65 is `IS66WVH8M8BLL-100B1LI`, which indicates a 64 Mbit, 100 MHz version
with 3.0 V supply and a single-ended clock.

I've written a complete Example Design to test the HyperRAM controller on this
MEGA65 platform.  The additional source files needed for this are placed in the
[src/Example_Design](src/Example_Design) directory.

## Getting started
The [HyperRAM controller](src/hyperram/hyperram.vhd) has just two interfaces,
one for the external HyperRAM device and one for the client (user) of the
HyperRAM. For the client interface I've chosen the [Avalon Memory
Map](doc/Avalon_Interface_Specifications.pdf) protocol.  This is an industry
standard and is easy to use. The interface width is 16 bits corresponding to
one word of the HyperRAM. The addressing is in units of words, not bytes.  The
Avalon interface supports burst mode, where you can read or write multiple
words in a single HyperRAM transaction. Section 3.5.5 in the Avalon Memory Map
specification describes burst mode in detail.

To see an example of how to use the HyperRAM controller and how to connect it
to the internal FPGA logic and to the external HyperRAM device. have a look at
the [Example_Design](src/Example_Design), specifically at the [top level
file](src/Example_Design/top.vhd).

The HyperRAM configuration and identification registers are memory mapped to the
following addresses:

* `0x80000000` : Identification Register 0
* `0x80000001` : Identification Register 1
* `0x80000800` : Configuration Register 0
* `0x80000801` : Configuration Register 1



## Further reading
The following links provide additional information:

* [Porting guideline](PORTING.md)
* [Detailed design description](src/hyperram/README.md)
* [Example Design](src/Example_Design/README.md)
* [Simulation](simulation/README.md)

