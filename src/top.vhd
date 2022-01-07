library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk       : in    std_logic;                  -- 100 MHz clock
      reset_n   : in    std_logic;                  -- CPU reset button

      -- HyperRAM device interface
      hr_resetn : out   std_logic;
      hr_csn    : out   std_logic;
      hr_ck     : out   std_logic;
      hr_rwds   : inout std_logic;
      hr_dq     : inout std_logic_vector(7 downto 0);

      -- LED output
      uled      : out   std_logic
   );
end entity top;

architecture synthesis of top is

   -- clocks
   signal clk_90 : std_logic;
   signal clk_x4 : std_logic;

   -- resets
   signal rst    : std_logic;

begin

   i_clk : entity work.clk
      port map
      (
         sys_clk_i  => clk,
         sys_rstn_i => reset_n,
         clk_x4_o   => clk_x4,
         clk_90_o   => clk_90,
         rst_o      => rst
      ); -- i_clk

   i_system : entity work.system
      port map (
         clk_i        => clk,
         clk_90_i     => clk_90,
         clk_x4_i     => clk_x4,
         rst_i        => rst,
         hr_resetn_o  => hr_resetn,
         hr_csn_o     => hr_csn,
         hr_ck_o      => hr_ck,
         hr_rwds_io   => hr_rwds,
         hr_dq_io     => hr_dq,
         uled_o       => uled
      ); -- i_system

end architecture synthesis;

