# HyperRAM

This repository is my attempt at a (reasonably) portable HyperRAM controller.
I'm writing my own implementation because I've looked at several other
implementations, and they all seemed lacking in various regards (features,
stability, portability, etc.)

The HyperRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

## Features

This implementation has support for:

* Maximum HyperRAM clock speed of 100 MHz.
* burst mode.
* variable latency.
* configuration registers read and write.
* identification registers read.
* 16-bit Avalon Memory Map interface including burst mode.

All the source files for the HyperRAM controller are in the
[src/hyperram](src/hyperram) directory, and all files needed for simulation are
in the [simulation](simulation) directory.

Porting to another platform may require hand-tuning of some clock parameters,
see the section on [porting](PORTING.md).


## Development platform

I'm testing my HyperRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (revision 3).  It contains the 8 MB HyperRAM chip ([link to
datasheet](doc/66-67WVH8M8ALL-BLL-938852.pdf)) from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the HyperRAM device is
`IS66WVH8M8BLL-100B1LI`, which indicates a 64 Mbit, 100 MHz version with 3.0 V
supply and a single-ended clock.

The additional source files needed for the MEGA65 platform are placed in the
[src/MEGA65](src/MEGA65) directory.

## Getting started
The HyperRAM controller has just two interface, one for the HyperRAM and one
for the client (user) of the HyperRAM. For the client interface I've chosen the
[Avalon Memory Map](doc/Avalon_Interface_Specifications.pdf) protocol.
This is an industry standard and is eady to use. The interface width is 16 bits
corresponding to one word of the HyperRAM. The addressing is in units of words,
not bytes.
The Avalon interface supports burst mode, where you can write multiple words in
a single HyperRAM transaction. Section 3.5.5 in the above document describes
burst mode in detail.


## Further reading
The following links provide additional information:

* [Porting guideline](PORTING.md)
* [Detailed design description](src/hyperram/README.md)
* [MEGA 65 specific support files](src/MEGA65/README.md)
* [Simulation](simulation/README.md)