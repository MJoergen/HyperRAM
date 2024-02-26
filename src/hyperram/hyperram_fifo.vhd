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
   port (
      src_clk_i   : in    std_logic;
      src_data_i  : in    std_logic_vector(15 downto 0);
      dst_clk_i   : in    std_logic;
      dst_data_o  : out   std_logic_vector(15 downto 0);
      dst_valid_o : out   std_logic
   );
end entity hyperram_fifo;

architecture synthesis of hyperram_fifo is

   signal src_toggle : std_logic := '0';

   signal dst_toggle   : std_logic;
   signal dst_toggle_d : std_logic;

begin

   -- This Clock Domain Crossing block is to synchronize the input signal to the
   -- dst_clk_i clock domain. It's not possible to use an ordinary async fifo, because
   -- the input clock RWDS is not free-running.

   rwds_toggle_proc : process (src_clk_i)
   begin
      if rising_edge(src_clk_i) then
         src_toggle <= not src_toggle;
      end if;
   end process rwds_toggle_proc;

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

   ctrl_dq_ie_proc : process (dst_clk_i)
   begin
      if rising_edge(dst_clk_i) then
         dst_toggle_d <= dst_toggle;
      end if;
   end process ctrl_dq_ie_proc;

end architecture synthesis;

