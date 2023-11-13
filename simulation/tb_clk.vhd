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

   signal sys_clk  : std_logic := '1';
   signal sys_rstn : std_logic := '0';

begin

   sys_clk  <= not sys_clk after C_CLK_PERIOD/2;
   sys_rstn <= '0', '1' after 100 * C_CLK_PERIOD;

   clk_inst : entity work.clk
      generic map (
         G_HYPERRAM_FREQ_MHZ => G_HYPERRAM_FREQ_MHZ,
         G_HYPERRAM_PHASE    => G_HYPERRAM_PHASE
      )
      port map (
         sys_clk_i    => sys_clk,
         sys_rstn_i   => sys_rstn,
         clk_x1_o     => clk_x1_o,
         clk_x2_o     => clk_x2_o,
         clk_x2_del_o => clk_x2_del_o,
         rst_o        => rst_o
      );

end architecture simulation;

