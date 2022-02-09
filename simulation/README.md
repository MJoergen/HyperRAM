# Simulation

This folder contains files necessary to run an RTL simulation of the HyperRAM
implementation. The testbench [tb.vhd](tb.vhd) instantiates the HyperRAM
controller and the trafic generator. The memory size (and hence the number of
writes and reads) is limited in the test bench to reduce simulation time.

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


