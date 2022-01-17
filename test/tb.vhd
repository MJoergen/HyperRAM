library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity tb is
end entity tb;

architecture simulation of tb is

   -- Testbench signals
   constant CLK_PERIOD : time := 5 ns;     -- 200 MHz
   signal stop_test    : std_logic := '0';

   signal clk          : std_logic;
   signal clk_90       : std_logic;
   signal clk_x2       : std_logic;
   signal rst          : std_logic;
   signal led_active   : std_logic;
   signal led_error    : std_logic;

   -- HyperRAM simulation device interface
   signal hr_resetn    : std_logic;
   signal hr_csn       : std_logic;
   signal hr_ck        : std_logic;
   signal hr_rwds      : std_logic;
   signal hr_dq        : std_logic_vector(7 downto 0);

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
   -- Controller clock and reset
   ---------------------------------------------------------

   p_clk_90 : process
   begin
      wait for CLK_PERIOD/4;

      while stop_test = '0' loop
         clk_90 <= '1';
         wait for CLK_PERIOD/2;
         clk_90 <= '0';
         wait for CLK_PERIOD/2;
      end loop;
      wait;
   end process p_clk_90;

   p_clk : process
   begin
      while stop_test = '0' loop
         clk <= '1';
         wait for CLK_PERIOD/2;
         clk <= '0';
         wait for CLK_PERIOD/2;
      end loop;
      wait;
   end process p_clk;

   p_clk_x2 : process
   begin
      while stop_test = '0' loop
         clk_x2 <= '1';
         wait for CLK_PERIOD/4;
         clk_x2 <= '0';
         wait for CLK_PERIOD/4;
      end loop;
      wait;
   end process p_clk_x2;

   p_rst : process
   begin
      rst <= '1';
      wait for 10*CLK_PERIOD;
      wait until clk = '1';
      rst <= '0';
      wait;
   end process p_rst;


   ---------------------------------------------------------
   -- Instantiate DUT
   ---------------------------------------------------------

   i_system : entity work.system
      port map (
         clk_i       => clk,
         clk_90_i    => clk_90,
         clk_x2_i    => clk_x2,
         rst_i       => rst,
         start_i     => '1',
         hr_resetn_o => hr_resetn,
         hr_csn_o    => hr_csn,
         hr_ck_o     => hr_ck,
         hr_rwds_io  => hr_rwds,
         hr_dq_io    => hr_dq,
         active_o    => led_active,
         error_o     => led_error
      ); -- i_system


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

