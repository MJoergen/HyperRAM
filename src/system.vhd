library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system is
   generic (
      G_ADDRESS_SIZE : integer  -- Number of bits
   );
   port (
      clk_i         : in  std_logic;
      clk_x2_i      : in  std_logic;
      rst_i         : in  std_logic;
      start_i       : in  std_logic;

      -- HyperRAM device interface
      hr_resetn_o   : out std_logic;
      hr_csn_o      : out std_logic;
      hr_ck_o       : out std_logic;
      hr_rwds_in_i  : in  std_logic;
      hr_dq_in_i    : in  std_logic_vector(7 downto 0);
      hr_rwds_out_o : out std_logic;
      hr_dq_out_o   : out std_logic_vector(7 downto 0);
      hr_rwds_oe_o  : out std_logic;
      hr_dq_oe_o    : out std_logic;

      active_o      : out std_logic;
      error_o       : out std_logic
   );
end entity system;

architecture synthesis of system is

   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(31 downto 0);
   signal avm_writedata     : std_logic_vector(15 downto 0);
   signal avm_byteenable    : std_logic_vector(1 downto 0);
   signal avm_burstcount    : std_logic_vector(7 downto 0);
   signal avm_readdata      : std_logic_vector(15 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate trafic generator
   --------------------------------------------------------

   i_trafic_gen : entity work.trafic_gen
      generic map (
         G_ADDRESS_SIZE => G_ADDRESS_SIZE
      )
      port map (
         clk_i               => clk_i,
         rst_i               => rst_i,
         start_i             => start_i,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_byteenable_o    => avm_byteenable,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest,
         active_o            => active_o,
         error_o             => error_o
      ); -- i_trafic_gen


   --------------------------------------------------------
   -- Instantiate HyperRAM interface
   --------------------------------------------------------

   i_hyperram : entity work.hyperram
      port map (
         clk_x1_i            => clk_i,
         clk_x2_i            => clk_x2_i,
         rst_i               => rst_i,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address,
         avm_writedata_i     => avm_writedata,
         avm_byteenable_i    => avm_byteenable,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_o      => avm_readdata,
         avm_readdatavalid_o => avm_readdatavalid,
         avm_waitrequest_o   => avm_waitrequest,
         hr_resetn_o         => hr_resetn_o,
         hr_csn_o            => hr_csn_o,
         hr_ck_o             => hr_ck_o,
         hr_rwds_in_i        => hr_rwds_in_i,
         hr_dq_in_i          => hr_dq_in_i,
         hr_rwds_out_o       => hr_rwds_out_o,
         hr_dq_out_o         => hr_dq_out_o,
         hr_rwds_oe_o        => hr_rwds_oe_o,
         hr_dq_oe_o          => hr_dq_oe_o
      ); -- i_hyperram

end architecture synthesis;

