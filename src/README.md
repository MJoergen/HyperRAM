# HyperRAM controller

This folder contains all the source files needed for testing the HyperRAM
controller on the MEGA65 platform.

The sub-folder [hyperram](hyperram) contains all the files (sources and
constraints) specific for the HyperRAM controller. Only these files need to be
ported for another project.

The sub-folder [MEGA65](MEGA65) contains any additional files needed for
running on the MEGA65 platform.

The additional files are:
* `trafic_gen.vhd` : This is a small RAM test that generates a sequence of
  writes using pseudo-random values following by a sequence of reads, where the
  received values are compared to the same sequence of pseudo-random values.
* `system.vhd` : This just instantiates the trafic generator together with the
  HyperRAM controller.


