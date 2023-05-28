-- Generate clocks needed for the HyperRAM controller.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
use ieee.std_logic_1164.all;

entity tb_clk is
   generic (
      G_HYPERRAM_FREQ_MHZ : integer;
      G_HYPERRAM_PHASE    : real
   );
   port (
      clk_x1_o     : out std_logic;
      clk_x2_o     : out std_logic;
      clk_x2_del_o : out std_logic;
      rst_o        : out std_logic
   );
end entity tb_clk;

architecture simulation of tb_clk is

   constant C_CLK_PERIOD : time := (1000/G_HYPERRAM_FREQ_MHZ) * 1 ns;

begin

   p_clk_x1 : process
   begin
      clk_x1_o <= '1';
      wait for C_CLK_PERIOD/2;
      clk_x1_o <= '0';
      wait for C_CLK_PERIOD/2;
   end process p_clk_x1;

   p_clk_x2 : process
   begin
      clk_x2_o <= '1';
      wait for C_CLK_PERIOD/4;
      clk_x2_o <= '0';
      wait for C_CLK_PERIOD/4;
   end process p_clk_x2;

   p_clk_x2_del : process
   begin
      wait for C_CLK_PERIOD/2*(G_HYPERRAM_PHASE/360.0);
      while true loop
         clk_x2_del_o <= '1';
         wait for C_CLK_PERIOD/4;
         clk_x2_del_o <= '0';
         wait for C_CLK_PERIOD/4;
      end loop;
      wait;
   end process p_clk_x2_del;

   p_rst : process
   begin
      rst_o <= '1';
      wait for 10*C_CLK_PERIOD;
      wait until clk_x1_o = '1';
      rst_o <= '0';
      wait;
   end process p_rst;

end architecture simulation;

