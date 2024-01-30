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

entity clk is
   generic (
      G_HYPERRAM_FREQ_MHZ : integer;
      G_HYPERRAM_PHASE    : real      -- Must be a multiple of 45/5 = 9
   );
   port (
      sys_clk_i      : in  std_logic;   -- expects 100 MHz
      sys_rstn_i     : in  std_logic;   -- Asynchronous, asserted low
      clk_x1_o       : out std_logic;   -- 100 MHz
      clk_x1_del_o   : out std_logic;   -- 100 MHz phase shifted
      delay_refclk_o : out std_logic;   -- 200 MHz
      ps_clk_i       : in  std_logic;
      ps_en_i        : in  std_logic;
      ps_incdec_i    : in  std_logic;
      ps_done_o      : out std_logic;
      ps_count_o     : out std_logic_vector(9 downto 0); -- Phase shift in units of 17.86 ps
      ps_degrees_o   : out std_logic_vector(9 downto 0); -- Phase shift in degrees
      rst_o          : out std_logic
   );
end entity clk;

architecture synthesis of clk is

   signal clkfb             : std_logic;
   signal clkfb_mmcm        : std_logic;
   signal delay_refclk_mmcm : std_logic;
   signal clk_x1_del_mmcm   : std_logic;
   signal clk_x1_mmcm       : std_logic;
   signal locked            : std_logic;

   -- Set the initial value based in the generic
   signal ps_count          : integer range 0 to 279 := integer(G_HYPERRAM_PHASE / 360.0 * 280.0);

   signal ps_count_9        : integer range 0 to 279*9;
   signal ps_degrees_8_2    : integer range 0 to 359*8*8;
   signal ps_degrees_8_4    : integer range 0 to 359*8*8*8*8;
   signal phase_degrees     : integer range 0 to 359;

begin

   -- The following calculation calculates phase_degrees = ps_count*9/7
   ps_count_9     <= ps_count*8 + ps_count;
   ps_degrees_8_2 <= ps_count_9*(8) +
                     ps_count_9;
   ps_degrees_8_4 <= ps_degrees_8_2*(8*8) +
                     ps_degrees_8_2;
   phase_degrees  <= (ps_degrees_8_4 + (8*8*8*8)/2) / (8*8*8*8);

   p_output_regs : process (ps_clk_i)
   begin
      if rising_edge(ps_clk_i) then
         ps_degrees_o  <= std_logic_vector(to_unsigned(phase_degrees, 10));
         ps_count_o    <= std_logic_vector(to_unsigned(ps_count, 10));
      end if;
   end process p_output_regs;


   -- generate HyperRAM clock.
   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_hyperram : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 12.000,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT1_DIVIDE       => 6,          -- 200 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 12,         -- 100 MHz
         CLKOUT2_PHASE        => G_HYPERRAM_PHASE,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => TRUE,
         CLKOUT3_DIVIDE       => 12,         -- 100 MHz
         CLKOUT3_PHASE        => 0.000,
         CLKOUT3_DUTY_CYCLE   => 0.500,
         CLKOUT3_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_mmcm,
         CLKOUT1             => delay_refclk_mmcm,
         CLKOUT2             => clk_x1_del_mmcm,
         CLKOUT3             => clk_x1_mmcm,
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
         PSCLK               => ps_clk_i,
         PSEN                => ps_en_i,
         PSINCDEC            => ps_incdec_i,
         PSDONE              => ps_done_o,
         -- Other control and status signals
         LOCKED              => locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_hyperram

   p_phase_shift : process (ps_clk_i)
   begin
      if rising_edge(ps_clk_i) then
         if ps_en_i = '1' then
            if ps_incdec_i = '1' then
               if ps_count < 279 then
                  ps_count <= ps_count + 1;
               else
                  ps_count <= 0;
               end if;
            else
               if ps_count > 0 then
                  ps_count <= ps_count - 1;
               else
                  ps_count <= 279;
               end if;
            end if;
         end if;
      end if;
   end process p_phase_shift;


   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfb_mmcm,
         O => clkfb
      ); -- i_bufg_clkfb

   i_bufg_clk_x1 : BUFG
      port map (
         I => clk_x1_mmcm,
         O => clk_x1_o
      ); -- i_bufg_clk_x1

   i_bufg_clk_x1_del : BUFG
      port map (
         I => clk_x1_del_mmcm,
         O => clk_x1_del_o
      ); -- i_bufg_clk_x1_del

   i_bufg_delay_refclk : BUFG
      port map (
         I => delay_refclk_mmcm,
         O => delay_refclk_o
      ); -- i_bufg_delay_refclk


   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_sync_rst_pixel : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),  -- 1-bit input: Source reset signal.
         dest_clk => clk_x1_o,                     -- 1-bit input: Destination clock.
         dest_rst => rst_o                         -- 1-bit output: src_rst synchronized to the destination clock domain.
                                                   -- This output is registered.
      ); -- i_xpm_cdc_sync_rst_pixel

end architecture synthesis;

