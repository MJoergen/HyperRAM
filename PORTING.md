# Porting guidelines

This page describes steps you need to take in order to incorporate this
HyperRAM controller into your design.

The Example Design uses the Artix 7 FPGA from Xilinx.  However, the controller
has been written in pure RTL (i.e. as portable as possible), making use of only
rising edge flip flops and no other IP blocks. It should therefore be a
relatively easy task to port this project to other FPGAs, even other vendors as
well, e.g. Lattice or Intel.

When porting the HyperRAM controller to your own project, there are three key
points to consider:

* Tri-state buffering
* Clocking
* Constraints


## Tri-state buffering

The HyperRAM device uses bidirectional ports, and this requires I/O buffers
with tri-state capability for the wires `RWDS` and `DQ`. Vivado can
automatically infer tri-state buffers when assigning `'Z'` to a port declared
as `inout`.  It is good design practice to infer the tri-state buffers from the
top-level file. Therefore, this HyperRAM controller does not itself infer any
tri-state buffers. Instead, it contains three signals for each of the `RWDS` and
`DQ` wires: One for input, one for output, and one for output enable.

In the top-level file of your own project you should include the following lines:

```
hr_rwds_io <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
hr_dq_io   <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');
hr_rwds_in <= hr_rwds_io;
hr_dq_in   <= hr_dq_io;
```

Here `hr_rwds_io` and `hr_dq_io` are the external ports connected to the HyperRAM
device.


## Clocking

The HyperRAM implementation requires a total of three clocks:

* `clk_i`          : This runs at 100 MHz, and drives the Avalon MM interface as well as the
  HyperRAM speed.
* `clk_del_i`      : This must be synchronous to `clk_i` with a 90 degree phase shift.
* `delay_refclk_i` : This runs at 200 Mhz

All three clocks should be generated from the same MMCM/PLL.

See the file [src/Example_Design/clk.vhd](src/Example_Design/clk.vhd) for how
clock synthesis is done on the MEGA65.


## Constraints

A number of constraints are needed by the HyperRAM controller in order to function
properly.

On the TX side (from FPGA to HyperRAM) we set the IOB property to TRUE on all the output
ports (`RSTN`, `CSN`, `RWDS`, and `DQ`). This ensures the output registers are part of the
output buffer, which minimizes the delay inside the FPGA. Note the `CK` signal is already
controlled directly by an ODDR buffer.

```
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_tx_inst/hr_rwds_oe_n_reg ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_tx_inst/hr_dq_oe_n_reg[*] ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_csn_o_reg ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_rstn_o_reg ]
```

On the Rx side (from HyperRAM to FPGA) we need several extra constraints. First, we want
to avoid having an extra BUFG on the `RWDS_DELAY`. This will happen automatically, because
Vivado recognizes this signal is used as a clock. However, with the IDELAY block we are
manually controlling the delay of this signal, and any extra inserted BUFG will increase
the delay many times.

```
set_property CLOCK_BUFFER_TYPE NONE [get_nets -of [get_pins i_core/i_hyperram/hyperram_rx_inst/delay_rwds_inst/DATAOUT]]
```

Secondly, the data path into the Rx FIFO must be as short as possible, so extra
constraints are needed for that.

```
set_max_delay 2 -datapath_only -from [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_read_o_reg]
set_max_delay 2 -datapath_only -from [get_cells i_core/i_hyperram/hyperram_rx_inst/iddr_dq_gen[*].iddr_dq_inst]
```

See the file [src/Example_Design/top.xdc](src/Example_Design/top.xdc) for the full set of
constraints needed.

