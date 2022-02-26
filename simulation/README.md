# Simulation

This folder contains files necessary to run an RTL simulation of the HyperRAM
implementation. The testbench [tb.vhd](tb.vhd) instantiates the [HyperRAM
controller](../src/hyperram) and the [trafic generator](../src/Example_Design/trafic_gen.vhd).
The memory size (and hence the number of writes and reads) is limited in the
test bench to reduce simulation time.

In the [testbench top level file](tb.vhd#L10) the constants `C_HYPERRAM_FREQ_MHZ`
and `C_HYPERRAM_PHASE` can be defined, just as in the [hardware top level
file](../src/Example_Design/top.vhd#L40). In this way, the testbench provides the same
tuning parameters as the hardware version.
Read more [here](../src/hyperram#hyperram_iovhd) about the necessity to phase shift
HyperRAM device relative to the FPGA.

One extra feature of the testbench is the artificial insertion of board delay.
It is expected that the physical hardware will introduce a non-trivial amount
of propagation delay between the FPGA and the HyperRAM device. Since the
HyperRAM timing is very delicate, I chose to include this propagation delay in
the testbench.  This is done by the constant `C_DELAY`, which for now I've set
to `1 ns` in each direction.

The actual validation of the HyperRAM controller is carried out by the [trafic
generator](../src/Example_Design/trafic_gen.vhd).

## HyperRAM simulation model

In order to test my HyperRAM controller I've found a [simulation
model](../HyperRAM_Simulation_Model) (downloaded from
[Cypress](https://www.cypress.com/documentation/models/verilog/verilog-model-hyperbus-interface))
of a real [Cypress HyperRAM device](../doc/s27kl0642.pdf).

Using a (presumably correct) simulation model is vital when developing, because
this allows testing the implementation in simulation, and thus finding and
fixing bugs much faster. However, since I'm targetting the MEGA65 board I need
a model of that particular HyperRAM device. I decided to manually [edit the
simulation model](../HyperRAM_Simulation_Model/s27kl0642.v#L219) and insert the
correct timing parameters.

## Running simulation

To perform the simulation test just start up Vivado, load the project file
[src/Example_Design/top.xpr](src/Example_Design/top.xpr), and select "Run
Simulation". Then in the "Tcl Console" type "`run 200us`".  This will complete
the entire simulation and display the waveform. The interesting part happens
between times `150us` and `200us`.

This generates the following waveform:
![waveform](../doc/waveform.png)

In simulation mode, only 8 writes and 8 reads are performed, to keep the
simulation time reasonable. The above waveform shows these 16 transactions.
Specifically, at the top we see `led_active` being first asserted and then
de-asserted, while `led_error` remains de-asserted all the time.

