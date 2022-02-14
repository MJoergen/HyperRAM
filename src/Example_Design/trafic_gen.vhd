library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module is a simple kind of RAM test.
-- It fills the HyperRAM with pseudo-random data,
-- and verifies the data can be read back again.

entity trafic_gen is
   generic (
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;
      start_i             : in  std_logic;
      wait_o              : out std_logic;

      -- Connect to HyperRAM controller
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      avm_writedata_o     : out std_logic_vector(G_DATA_SIZE-1 downto 0);
      avm_byteenable_o    : out std_logic_vector(G_DATA_SIZE/8-1 downto 0);
      avm_burstcount_o    : out std_logic_vector(7 downto 0);
      avm_readdata_i      : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;

      -- Debug output
      write_burstcount_o  : out std_logic_vector(7 downto 0);
      read_burstcount_o   : out std_logic_vector(7 downto 0);
      address_o           : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      data_exp_o          : out std_logic_vector(15 downto 0);
      data_read_o         : out std_logic_vector(15 downto 0);
      error_o             : out std_logic
   );
end entity trafic_gen;

architecture synthesis of trafic_gen is

   signal avm_start         : std_logic;
   signal avm_wait          : std_logic;
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
   signal avm_writedata     : std_logic_vector(G_DATA_SIZE-1 downto 0);
   signal avm_byteenable    : std_logic_vector(G_DATA_SIZE/8-1 downto 0);
   signal avm_burstcount    : std_logic_vector(7 downto 0);
   signal avm_readdata      : std_logic_vector(G_DATA_SIZE-1 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate burst control
   --------------------------------------------------------

   i_burst_ctrl : entity work.burst_ctrl
      port map (
         clk_i              => clk_i,
         rst_i              => rst_i,
         start_i            => start_i,
         wait_o             => wait_o,
         start_o            => avm_start,
         wait_i             => avm_wait,
         write_burstcount_o => write_burstcount_o,
         read_burstcount_o  => read_burstcount_o
      ); -- i_burst_ctrl


   --------------------------------------------------------
   -- Instantiate Avalon Master
   --------------------------------------------------------

   i_avm_master : entity work.avm_master
      generic map (
         G_DATA_SIZE    => G_DATA_SIZE,
         G_ADDRESS_SIZE => G_ADDRESS_SIZE
      )
      port map (
         clk_i               => clk_i,
         rst_i               => rst_i,
         start_i             => avm_start,
         wait_o              => avm_wait,
         write_burstcount_i  => write_burstcount_o,
         read_burstcount_i   => read_burstcount_o,
         error_o             => error_o,
         address_o           => address_o,
         data_exp_o          => data_exp_o,
         data_read_o         => data_read_o,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_byteenable_o    => avm_byteenable,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest
      ); -- i_avm_master


   i_avm_pause : entity work.avm_pause
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
      );

end architecture synthesis;

