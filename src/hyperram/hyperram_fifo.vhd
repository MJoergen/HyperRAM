-- This is part of the HyperRAM I/O connections
-- It is a shallow (two-element) CDC FIFO
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
      src_valid_i : in    std_logic;
      src_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      dst_clk_i   : in    std_logic;
      dst_valid_o : out   std_logic;
      dst_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity hyperram_fifo;

architecture synthesis of hyperram_fifo is

   signal src_ram     : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal src_gray_wr : std_logic_vector(1 downto 0) := "00";

   attribute fsm_encoding : string;
   attribute fsm_encoding of src_gray_wr : signal is "none";

   signal dst_ram     : std_logic_vector(2 * G_DATA_SIZE - 1 downto 0);
   signal dst_gray_wr : std_logic_vector(1 downto 0) := "00";

   signal dst_gray_rd : std_logic_vector(1 downto 0) := "00";

begin

   src_proc : process (src_clk_i)
   begin
      if rising_edge(src_clk_i) then
         if src_valid_i = '1' then

            case src_gray_wr is

               when "00" =>
                  src_gray_wr                       <= "01";
                  src_ram(G_DATA_SIZE - 1 downto 0) <= src_data_i;

               when "01" =>
                  src_gray_wr                                     <= "11";
                  src_ram(2 * G_DATA_SIZE - 1 downto G_DATA_SIZE) <= src_data_i;

               when "10" =>
                  src_gray_wr                                     <= "00";
                  src_ram(2 * G_DATA_SIZE - 1 downto G_DATA_SIZE) <= src_data_i;

               when "11" =>
                  src_gray_wr                       <= "10";
                  src_ram(G_DATA_SIZE - 1 downto 0) <= src_data_i;

               when others =>
                  null;

            end case;

         end if;
      end if;
   end process src_proc;

   xpm_cdc_array_single_ram_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF   => 2,
         INIT_SYNC_FF   => 0,
         SIM_ASSERT_CHK => 0,
         SRC_INPUT_REG  => 0,
         WIDTH          => 2 * G_DATA_SIZE
      )
      port map (
         src_clk  => '0',
         src_in   => src_ram,
         dest_clk => dst_clk_i,
         dest_out => dst_ram
      );

   xpm_cdc_array_single_gray_wr_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF   => 3,
         INIT_SYNC_FF   => 0,
         SIM_ASSERT_CHK => 0,
         SRC_INPUT_REG  => 0,
         WIDTH          => 2
      )
      port map (
         src_clk  => '0',
         src_in   => src_gray_wr,
         dest_clk => dst_clk_i,
         dest_out => dst_gray_wr
      );

   dst_proc : process (dst_clk_i)
   begin
      if rising_edge(dst_clk_i) then
         dst_valid_o <= '0';

         if dst_gray_wr /= dst_gray_rd then

            case dst_gray_rd is

               when "00" =>
                  dst_data_o  <= dst_ram(G_DATA_SIZE - 1 downto 0);
                  dst_gray_rd <= "01";

               when "01" =>
                  dst_data_o  <= dst_ram(2 * G_DATA_SIZE - 1 downto G_DATA_SIZE);
                  dst_gray_rd <= "11";

               when "10" =>
                  dst_data_o  <= dst_ram(2 * G_DATA_SIZE - 1 downto G_DATA_SIZE);
                  dst_gray_rd <= "00";

               when "11" =>
                  dst_data_o  <= dst_ram(G_DATA_SIZE - 1 downto 0);
                  dst_gray_rd <= "10";

               when others =>
                  null;

            end case;

            dst_valid_o <= '1';
         end if;
      end if;
   end process dst_proc;

end architecture synthesis;

