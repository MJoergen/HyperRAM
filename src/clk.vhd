library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i    : in  std_logic;   -- expects 100 MHz
      sys_rstn_i   : in  std_logic;   -- Asynchronous, asserted low
      clk_x2_o     : out std_logic;   -- 200 MHz
      clk_90_o     : out std_logic;   -- 100 MHz delayed 90 degrees
      rst_o        : out std_logic
   );
end entity clk;

architecture synthesis of clk is

   signal clkfb       : std_logic;
   signal clkfb_mmcm  : std_logic;
   signal clk_90_mmcm : std_logic;
   signal clk_x2_mmcm : std_logic;
   signal locked      : std_logic;

begin

   -- generate 200 MHz and 100 MHz @ 90 degrees phase shift.
   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_x2_90 : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 8.000,      -- f_VCO = (100 MHz / 1) x 8.000 = 800 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 4.000,      -- 200 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 8,          -- 100 MHz
         CLKOUT1_PHASE        => 90.000,     -- 90 degrees delayed
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_mmcm,
         CLKOUT0             => clk_x2_mmcm,
         CLKOUT1             => clk_90_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_x2_90


   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfb_mmcm,
         O => clkfb
      ); -- i_bufg_clkfb

   i_bufg_clk_x2 : BUFG
      port map (
         I => clk_x2_mmcm,
         O => clk_x2_o
      ); -- i_bufg_clk_x2

   i_bufg_clk_90 : BUFG
      port map (
         I => clk_90_mmcm,
         O => clk_90_o
      ); -- i_bufg_clk_90


   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_sync_rst_pixel : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),  -- 1-bit input: Source reset signal.
         dest_clk => sys_clk_i,                    -- 1-bit input: Destination clock.
         dest_rst => rst_o                         -- 1-bit output: src_rst synchronized to the destination clock domain.
                                                   -- This output is registered.
      ); -- i_xpm_cdc_sync_rst_pixel

end architecture synthesis;

