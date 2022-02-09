# Simulation

This folder contains files necessary to run an RTL simulation of the HyperRAM
implementation. The testbench [tb.vhd](tb.vhd) instantiates the HyperRAM
controller and the trafic generator. The memory size (and hence the number of
writes and reads) is limited in the test bench to reduce simulation time.

