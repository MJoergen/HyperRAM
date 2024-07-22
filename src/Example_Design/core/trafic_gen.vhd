-- This module is a simple kind of RAM test.
-- It fills the memory with pseudo-random data,
-- and verifies the data can be read back again.
-- It exercises the memory using various burst modes.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity trafic_gen is
   generic (
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i               : in    std_logic;
      rst_i               : in    std_logic;
      start_i             : in    std_logic;
      wait_o              : out   std_logic;

      -- Connect to memory controller
      avm_write_o         : out   std_logic;
      avm_read_o          : out   std_logic;
      avm_address_o       : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      avm_writedata_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_byteenable_o    : out   std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      avm_burstcount_o    : out   std_logic_vector(7 downto 0);
      avm_readdata_i      : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_readdatavalid_i : in    std_logic;
      avm_waitrequest_i   : in    std_logic;

      -- Statistics output
      stat_total_o        : out   std_logic_vector(31 downto 0);
      stat_error_o        : out   std_logic_vector(31 downto 0);
      stat_err_addr_o     : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      stat_err_exp_o      : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      stat_err_read_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity trafic_gen;

architecture synthesis of trafic_gen is

   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
   signal avm_writedata     : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal avm_byteenable    : std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
   signal avm_burstcount    : std_logic_vector(7 downto 0);
   signal avm_readdata      : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate Avalon Master
   --------------------------------------------------------

   avm_master3_inst : entity work.avm_master3
      generic map (
         G_INIT_FIRST   => true,
         G_DATA_SIZE    => G_DATA_SIZE,
         G_ADDRESS_SIZE => G_ADDRESS_SIZE
      )
      port map (
         clk_i                 => clk_i,
         rst_i                 => rst_i,
         start_i               => start_i,
         wait_o                => wait_o,
         m_avm_write_o         => avm_write,
         m_avm_read_o          => avm_read,
         m_avm_address_o       => avm_address,
         m_avm_writedata_o     => avm_writedata,
         m_avm_byteenable_o    => avm_byteenable,
         m_avm_burstcount_o    => avm_burstcount,
         m_avm_readdata_i      => avm_readdata,
         m_avm_readdatavalid_i => avm_readdatavalid,
         m_avm_waitrequest_i   => avm_waitrequest
      ); -- avm_master3_inst

   avm_verifier_inst : entity work.avm_verifier
      generic map (
         G_INIT_ZEROS   => false,
         G_DATA_SIZE    => G_DATA_SIZE,
         G_ADDRESS_SIZE => G_ADDRESS_SIZE
      )
      port map (
         clk_i               => clk_i,
         rst_i               => rst_i or start_i,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address,
         avm_writedata_i     => avm_writedata,
         avm_byteenable_i    => avm_byteenable,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest,
         stat_total_o        => stat_total_o,
         stat_error_o        => stat_error_o,
         stat_err_addr_o     => stat_err_addr_o,
         stat_err_exp_o      => stat_err_exp_o,
         stat_err_read_o     => stat_err_read_o
      ); -- avm_verifier_inst


   --------------------------------------------------------
   -- Insert occasional breaks into Avalon stream.
   -- This is OPTIONAL, and added only to increase test
   -- coverage of the HyperRAM controller.
   --------------------------------------------------------

   avm_pause_inst : entity work.avm_pause
      generic map (
         G_PAUSE        => 3,
         G_ADDRESS_SIZE => G_ADDRESS_SIZE,
         G_DATA_SIZE    => G_DATA_SIZE
      )
      port map (
         clk_i                 => clk_i,
         rst_i                 => rst_i,
         s_avm_write_i         => avm_write,
         s_avm_read_i          => avm_read,
         s_avm_address_i       => avm_address,
         s_avm_writedata_i     => avm_writedata,
         s_avm_byteenable_i    => avm_byteenable,
         s_avm_burstcount_i    => avm_burstcount,
         s_avm_readdata_o      => avm_readdata,
         s_avm_readdatavalid_o => avm_readdatavalid,
         s_avm_waitrequest_o   => avm_waitrequest,
         m_avm_write_o         => avm_write_o,
         m_avm_read_o          => avm_read_o,
         m_avm_address_o       => avm_address_o,
         m_avm_writedata_o     => avm_writedata_o,
         m_avm_byteenable_o    => avm_byteenable_o,
         m_avm_burstcount_o    => avm_burstcount_o,
         m_avm_readdata_i      => avm_readdata_i,
         m_avm_readdatavalid_i => avm_readdatavalid_i,
         m_avm_waitrequest_i   => avm_waitrequest_i
      ); -- avm_pause_inst

end architecture synthesis;

