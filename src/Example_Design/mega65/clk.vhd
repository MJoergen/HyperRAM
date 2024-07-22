-- This is the MEGA65 clock synthesis.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;

library unisim;
   use unisim.vcomponents.all;

library xpm;
   use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i   : in    std_logic; -- expects 100 MHz
      sys_rst_i   : in    std_logic; -- Asynchronous, asserted high
      ctrl_clk_o  : out   std_logic; -- 100 MHz
      ctrl_rst_o  : out   std_logic; -- Synchronous, asserted high
      video_clk_o : out   std_logic; -- 74.25 MHz
      video_rst_o : out   std_logic; -- Synchronous, asserted high
      hdmi_clk_o  : out   std_logic  -- 371.25 MHz
   );
end entity clk;

architecture synthesis of clk is

   signal ctrl_clk_fb      : std_logic;
   signal ctrl_clk_mmcm    : std_logic;
   signal ctrl_clk_locked  : std_logic;
   signal video_clk_fb     : std_logic;
   signal video_clk_mmcm   : std_logic;
   signal hdmi_clk_mmcm    : std_logic;
   signal video_clk_locked : std_logic;

begin

   -------------------------------------
   -- Generate controller clock
   -------------------------------------

   plle2_base_inst : component plle2_base
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => 10,   -- 1000 MHz
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => 10.0, -- INPUT @ 100 MHz
         CLKOUT0_DIVIDE     => 10,   -- OUTPUT @ 100 MHz
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => 0.000,
         DIVCLK_DIVIDE      => 1,
         REF_JITTER1        => 0.010,
         STARTUP_WAIT       => "FALSE"
      )
      port map (
         clkfbin  => ctrl_clk_fb,
         clkfbout => ctrl_clk_fb,
         clkin1   => sys_clk_i,
         clkout0  => ctrl_clk_mmcm,
         locked   => ctrl_clk_locked,
         pwrdwn   => '0',
         rst      => sys_rst_i
      ); -- plle2_base_inst


   -------------------------------------
   -- Generate video clock
   -------------------------------------

   mmcme2_base_inst : component mmcme2_base
      generic map (
         BANDWIDTH           => "OPTIMIZED",
         CLKOUT4_CASCADE     => FALSE,
         STARTUP_WAIT        => FALSE,
         CLKIN1_PERIOD       => 10.0,   -- INPUT @ 100 MHz
         REF_JITTER1         => 0.010,
         DIVCLK_DIVIDE       => 5,
         CLKFBOUT_MULT_F     => 37.125, -- f_VCO = (100 MHz / 5) x 37.125 = 742.5 MHz
         CLKFBOUT_PHASE      => 0.000,
         CLKOUT0_DIVIDE_F    => 10.000, -- 74.25 MHz
         CLKOUT0_PHASE       => 0.000,
         CLKOUT0_DUTY_CYCLE  => 0.500,
         CLKOUT1_DIVIDE      => 2,      -- 371.25 MHz
         CLKOUT1_PHASE       => 0.000,
         CLKOUT1_DUTY_CYCLE  => 0.500
      )
      port map (
         clkfbin  => video_clk_fb,
         clkfbout => video_clk_fb,
         clkin1   => sys_clk_i,
         clkout0  => video_clk_mmcm,
         clkout1  => hdmi_clk_mmcm,
         locked   => video_clk_locked,
         pwrdwn   => '0',
         rst      => sys_rst_i
      ); -- mmcme2_base_inst


   -------------------------------------
   -- Output buffering
   -------------------------------------

   bufg_ctrl_inst : component bufg
      port map (
         i => ctrl_clk_mmcm,
         o => ctrl_clk_o
      ); -- bufg_ctrl_inst

   bufg_video_inst : component bufg
      port map (
         i => video_clk_mmcm,
         o => video_clk_o
      ); -- bufg_video_inst

   bufg_hdmi_inst : component bufg
      port map (
         i => hdmi_clk_mmcm,
         o => hdmi_clk_o
      ); -- bufg_hdmi_inst


   -------------------------------------
   -- Reset generation
   -------------------------------------

   xpm_cdc_sync_rst_ctrl_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not ctrl_clk_locked,
         dest_clk => ctrl_clk_o,
         dest_rst => ctrl_rst_o
      ); -- xpm_cdc_sync_rst_ctrl_inst

   xpm_cdc_sync_rst_video_inst : component xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not video_clk_locked,
         dest_clk => video_clk_o,
         dest_rst => video_rst_o
      ); -- xpm_cdc_sync_rst_video_inst

end architecture synthesis;

