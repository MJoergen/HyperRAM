## Portable OpenSource HyperRAM controller for FPGAs written in VHDL

HyperRAM is quite a beast! On the one hand, it offers advantages to hardware designers such as
low pin count, low power consumption and easy control. At least compared to modern DDR alternatives.
On the other hand, there are tons of nitty gritty details you need to know and take care of to
create a stable and realiable HyperRAM controller. Complex constraints and nasty phase shifts
just to name two of them.

![HyperRAM image](hyperram_img.jpg)

Therefore you do not want to reinvent the wheel and go through the joy and pain of implementing
a HyperRAM controller from scratch. Search no longer! You have found what you are looking
for: The [MJoergen/HyperRAM](https://github.com/MJoergen/HyperRAM) controller has the following
advantages:

* Easy to use
* Well documented
* Field proven stability
* Portable
* OpenSource: Very permissive [MIT license](https://github.com/MJoergen/HyperRAM/blob/main/LICENSE) that also allows commercial use

The controller is written in modern **VHDL-2008** and you can of course use it without
any modifications in your **Verilog** Designs.

It has been written and tested on a Xilinx Artix-7 FPGA using Vivado. Due to the portable
nature of the controller in conjunction with the well documented code and constraints file
you can easily port it to other environments such as Intel and Quartus.

### Features

* Maximum HyperRAM clock speed of 100 MHz
* Variable latency
* Configuration registers read and write
* Identification registers read
* Automatic configuration of latency mode upon reset
* 16-bit Avalon Memory Map interface including burst mode

### Getting started


### Interface

```vhdl
entity hyperram is
   port (
      clk_x1_i            : in  std_logic; -- Main clock
      clk_x2_i            : in  std_logic; -- Physical I/O only
      clk_x2_del_i        : in  std_logic; -- Double frequency, phase shifted
      rst_i               : in  std_logic; -- Synchronous reset

      -- Avalon Memory Map
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(31 downto 0);
      avm_writedata_i     : in  std_logic_vector(15 downto 0);
      avm_byteenable_i    : in  std_logic_vector(1 downto 0);
      avm_burstcount_i    : in  std_logic_vector(7 downto 0);
      avm_readdata_o      : out std_logic_vector(15 downto 0);
      avm_readdatavalid_o : out std_logic;
      avm_waitrequest_o   : out std_logic;

      -- HyperRAM device interface
      hr_resetn_o         : out std_logic;
      hr_csn_o            : out std_logic;
      hr_ck_o             : out std_logic;
      hr_rwds_in_i        : in  std_logic;
      hr_rwds_out_o       : out std_logic;
      hr_rwds_oe_o        : out std_logic;   -- Output enable for RWDS
      hr_dq_in_i          : in  std_logic_vector(7 downto 0);
      hr_dq_out_o         : out std_logic_vector(7 downto 0);
      hr_dq_oe_o          : out std_logic    -- Output enable for DQ
   );
end entity hyperram;
```
### About me & contact

I am Michael Jørgensen ([LinkedIn](https://www.linkedin.com/in/michaeljoergensen/)), an experienced hardware, software
and firmware developer from Denmark. My primary professional focus is with embedded applications in telecommunications.
In my spare time I like to contribute to the OpenSource community,
[help people to get started in FPGA development](https://github.com/MJoergen/nexys4ddr/tree/master/dyoc)
and engage in Retro Computing by contributing to various [MEGA65](https://www.mega65.org)
[cores and frameworks](https://sy2002.github.io/m65cores/)

If you have questions about the HyperRAM controller, want to share suggestions or need some help, please
[open a GitHub Issue in the main repo](https://github.com/MJoergen/HyperRAM/issues) or contact me at
`michael.finn.jorgensen at gmail.com`.
