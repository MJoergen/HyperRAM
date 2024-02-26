-- This is part of the HyperRAM I/O connections
-- It is a shallow (one-element) CDC FIFO
--
-- Created by Michael Jørgensen in 2023 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library xpm;
   use xpm.vcomponents.all;

entity hyperram_fifo is
   generic (
      G_DATA_SIZE : natural
   );
   port (
      src_clk_i   : in    std_logic;
      src_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      dst_clk_i   : in    std_logic;
      dst_valid_o : out   std_logic;
      dst_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity hyperram_fifo;

architecture synthesis of hyperram_fifo is

   signal src_toggle : std_logic := '0';

   signal dst_toggle   : std_logic;
   signal dst_toggle_d : std_logic;

begin

   src_proc : process (src_clk_i)
   begin
      if rising_edge(src_clk_i) then
         src_toggle <= not src_toggle;
      end if;
   end process src_proc;

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF   => 2,
         INIT_SYNC_FF   => 0,
         SIM_ASSERT_CHK => 0,
         SRC_INPUT_REG  => 0,
         WIDTH          => 17
      )
      port map (
         src_clk               => '0',
         src_in(15 downto 0)   => src_data_i,
         src_in(16)            => src_toggle,
         dest_clk              => dst_clk_i,
         dest_out(15 downto 0) => dst_data_o,
         dest_out(16)          => dst_toggle
      );

   dst_valid_o <= dst_toggle_d xor dst_toggle;

   dst_proc : process (dst_clk_i)
   begin
      if rising_edge(dst_clk_i) then
         dst_toggle_d <= dst_toggle;
      end if;
   end process dst_proc;

end architecture synthesis;

