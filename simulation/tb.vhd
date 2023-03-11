-- Main testbench for the HyperRAM controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   constant C_HYPERRAM_FREQ_MHZ : integer := 100;
   constant C_HYPERRAM_PHASE    : real := 162.000;
   constant C_DELAY         : time := 1 ns;

   signal clk_x1            : std_logic;
   signal clk_x2            : std_logic;
   signal clk_x2_del        : std_logic;
   signal rst               : std_logic;

   signal tb_start          : std_logic;

   signal sys_resetn        : std_logic;
   signal sys_csn           : std_logic;
   signal sys_ck            : std_logic;
   signal sys_rwds          : std_logic;
   signal sys_dq            : std_logic_vector(7 downto 0);
   signal sys_rwds_in       : std_logic;
   signal sys_dq_in         : std_logic_vector(7 downto 0);
   signal sys_rwds_out      : std_logic;
   signal sys_dq_out        : std_logic_vector(7 downto 0);
   signal sys_rwds_oe       : std_logic;
   signal sys_dq_oe         : std_logic;

   -- HyperRAM simulation device interface
   signal hr_resetn         : std_logic;
   signal hr_csn            : std_logic;
   signal hr_ck             : std_logic;
   signal hr_rwds           : std_logic;
   signal hr_dq             : std_logic_vector(7 downto 0);


   component s27kl0642 is
      port (
         DQ7      : inout std_logic;
         DQ6      : inout std_logic;
         DQ5      : inout std_logic;
         DQ4      : inout std_logic;
         DQ3      : inout std_logic;
         DQ2      : inout std_logic;
         DQ1      : inout std_logic;
         DQ0      : inout std_logic;
         RWDS     : inout std_logic;
         CSNeg    : in    std_logic;
         CK       : in    std_logic;
         CKn      : in    std_logic;
         RESETNeg : in    std_logic
      );
   end component s27kl0642;

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   i_tb_clk : entity work.tb_clk
      generic map (
         G_HYPERRAM_FREQ_MHZ => C_HYPERRAM_FREQ_MHZ,
         G_HYPERRAM_PHASE    => C_HYPERRAM_PHASE
      )
      port map (
         clk_x1_o     => clk_x1,
         clk_x2_o     => clk_x2,
         clk_x2_del_o => clk_x2_del,
         rst_o        => rst
      ); -- i_tb_clk


   --------------------------------------------------------
   -- Generate start signal for trafic generator
   --------------------------------------------------------

   p_tb_start : process
   begin
      tb_start <= '0';
      wait for 160 us;
      wait until clk_x1 = '1';
      tb_start <= '1';
      wait until clk_x1 = '1';
      tb_start <= '0';
      wait;
   end process p_tb_start;


   --------------------------------------------------------
   -- Instantiate core test generator
   --------------------------------------------------------

   i_core : entity work.core
      generic map (
         G_SYS_ADDRESS_SIZE => 8,
         G_ADDRESS_SIZE     => 22,
         G_DATA_SIZE        => 16
      )
      port map (
         clk_x1_i     => clk_x1,
         clk_x2_i     => clk_x2,
         clk_x2_del_i => clk_x2_del,
         rst_i        => rst,
         start_i      => tb_start,
         hr_resetn_o  => sys_resetn,
         hr_csn_o     => sys_csn,
         hr_ck_o      => sys_ck,
         hr_rwds_io   => sys_rwds,
         hr_dq_io     => sys_dq
      ); -- i_core


   ---------------------------------------------------------
   -- Connect controller to device (with delay)
   ---------------------------------------------------------

   hr_resetn <= sys_resetn after C_DELAY;
   hr_csn    <= sys_csn    after C_DELAY;
   hr_ck     <= sys_ck     after C_DELAY;

   i_wiredelay2_rwds : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         A => sys_rwds,
         B => hr_rwds
      );

   gen_dq_delay : for i in 0 to 7 generate
   i_wiredelay2_rwds : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         A => sys_dq(i),
         B => hr_dq(i)
      );
   end generate gen_dq_delay;


   ---------------------------------------------------------
   -- Instantiate HyperRAM simulation model
   ---------------------------------------------------------

   i_s27kl0642 : s27kl0642
      port map (
         DQ7      => hr_dq(7),
         DQ6      => hr_dq(6),
         DQ5      => hr_dq(5),
         DQ4      => hr_dq(4),
         DQ3      => hr_dq(3),
         DQ2      => hr_dq(2),
         DQ1      => hr_dq(1),
         DQ0      => hr_dq(0),
         RWDS     => hr_rwds,
         CSNeg    => hr_csn,
         CK       => hr_ck,
         CKn      => not hr_ck,
         RESETNeg => hr_resetn
      ); -- i_s27kl0642

end architecture simulation;

