-- This is the HyperRAM clock synthesis.
--
-- The current phase shift is in units of 1000/56 = 17.86 ps (assuming a fVCO period of
-- 1000 ps, i.e. 1000 MHz).  For a complete 200 MHz clock cycle (period of 5 ns), a total
-- of 5000/17.86 = 280 shifts are required.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library unisim;
   use unisim.vcomponents.all;

library xpm;
   use xpm.vcomponents.all;

entity clk_controller is
   port (
      sys_clk_i      : in    std_logic; -- expects 100 MHz
      sys_rst_i      : in    std_logic; -- Asynchronous, asserted high
      clk_o          : out   std_logic; -- 100 MHz
      clk_del_o      : out   std_logic; -- 100 MHz phase shifted 90 degrees
      delay_refclk_o : out   std_logic; -- 200 MHz, for IDELAYCTRL
      rst_o          : out   std_logic
   );
end entity clk_controller;

architecture synthesis of clk_controller is

   signal clkfb             : std_logic;
   signal clkfb_mmcm        : std_logic;
   signal delay_refclk_mmcm : std_logic;
   signal clk_del_mmcm      : std_logic;
   signal clk_mmcm          : std_logic;
   signal locked            : std_logic;

begin

   -- generate HyperRAM clock.
   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE
   clk_hyperram_inst : component mmcme2_adv
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0, -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 12.000,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT1_DIVIDE       => 6,    -- 200 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 12,   -- 100 MHz
         CLKOUT2_PHASE        => 90.000,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE,
         CLKOUT3_DIVIDE       => 12,   -- 100 MHz
         CLKOUT3_PHASE        => 0.000,
         CLKOUT3_DUTY_CYCLE   => 0.500,
         CLKOUT3_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         clkfbout     => clkfb_mmcm,
         clkout1      => delay_refclk_mmcm,
         clkout2      => clk_del_mmcm,
         clkout3      => clk_mmcm,
         -- Input clock control
         clkfbin      => clkfb,
         clkin1       => sys_clk_i,
         clkin2       => '0',
         -- Tied to always select the primary input clock
         clkinsel     => '1',
         -- Ports for dynamic reconfiguration
         daddr        => (others => '0'),
         dclk         => '0',
         den          => '0',
         di           => (others => '0'),
         do           => open,
         drdy         => open,
         dwe          => '0',
         -- Ports for dynamic phase shift
         psclk        => '0',
         psen         => '0',
         psincdec     => '0',
         psdone       => open,
         -- Other control and status signals
         locked       => locked,
         clkinstopped => open,
         clkfbstopped => open,
         pwrdwn       => '0',
         rst          => sys_rst_i
      ); -- clk_hyperram_inst


   -------------------------------------
   -- Output buffering
   -------------------------------------

   bufg_clkfb_inst : component bufg
      port map (
         i => clkfb_mmcm,
         o => clkfb
      ); -- bufg_clkfb_inst

   bufg_clk_inst : component bufg
      port map (
         i => clk_mmcm,
         o => clk_o
      ); -- bufg_clk_inst

   bufg_clk_del_inst : component bufg
      port map (
         i => clk_del_mmcm,
         o => clk_del_o
      ); -- bufg_clk_del_inst

   bufg_delay_refclk_inst : component bufg
      port map (
         i => delay_refclk_mmcm,
         o => delay_refclk_o
      ); -- bufg_delay_refclk_inst


   -------------------------------------
   -- Reset generation
   -------------------------------------

   xpm_cdc_sync_rst_pixel_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not locked,
         dest_clk => clk_o,
         dest_rst => rst_o
      ); -- xpm_cdc_sync_rst_pixel_inst

end architecture synthesis;

