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


## Traffic generator

The traffic generator's sole purpose is to test the HyperRAM controller. It
does this by generating first a sequence of WRITE operations (writing
pseudo-random data to the entire HyperRAM device), and then a corresponding
sequence of READ operations, verifying that the correct values are read back
again.

The traffic generator has a single control input (`start_i`) that starts the
above mentioned process. There are two output signals indicating progress:

* `led_active`: indicates the test is in progress.
* `led_error`: indicates at least one error has occurred.


