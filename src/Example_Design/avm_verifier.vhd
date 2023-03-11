-- This module is a RAM test.
--
-- It generates a random sequence of WRITE and READ operations.
-- Burstcount is always 1, but byteenable varies randomly as well.
-- The module keeps a shadow copy of the memory, and uses that
-- to verify the values received during READ operations.
--
-- Created by Michael Jørgensen in 2023

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity avm_verifier is
   generic (
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      avm_writedata_i     : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      avm_byteenable_i    : in  std_logic_vector(G_DATA_SIZE/8-1 downto 0);
      avm_burstcount_i    : in  std_logic_vector(7 downto 0);
      avm_readdata_i      : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;
      -- Debug output
      error_o             : out std_logic;
      address_o           : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0) := (others => '0');
      data_exp_o          : out std_logic_vector(G_DATA_SIZE-1 downto 0) := (others => '0');
      data_read_o         : out std_logic_vector(G_DATA_SIZE-1 downto 0) := (others => '0')
   );
end entity avm_verifier;

architecture synthesis of avm_verifier is

   signal wr_en    : std_logic_vector(G_DATA_SIZE/8-1 downto 0);
   signal mem_data : std_logic_vector(G_DATA_SIZE-1 downto 0);

begin

   wr_en <= avm_byteenable_i when avm_write_i = '1' and avm_waitrequest_i = '0'
            else (others => '0');

   i_bytewrite_tdp_ram_wf : entity work.bytewrite_tdp_ram_wf
      generic map (
         SIZE       => 2**G_ADDRESS_SIZE,
         ADDR_WIDTH => G_ADDRESS_SIZE,
         COL_WIDTH  => 8,
         NB_COL     => G_DATA_SIZE/8
      )
      port map (
         clka  => clk_i,
         ena   => '1',
         wea   => wr_en,
         addra => avm_address_i,
         dia   => avm_writedata_i,
         doa   => mem_data,
         clkb  => '0',
         enb   => '0',
         web   => (others => '0'),
         addrb => (others => '0'),
         dib   => (others => '0'),
         dob   => open
      ); -- i_bytewrite_tdp_ram_wf

   p_verifier : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_readdatavalid_i = '1' then
            address_o   <= avm_address_i;
            data_exp_o  <= mem_data;
            data_read_o <= avm_readdata_i;
            if avm_readdata_i /= mem_data then
               assert false
                  report "ERROR at Address " & to_hstring(avm_address_i) &
                  ". Expected " & to_hstring(mem_data) &
                  ", read " & to_hstring(avm_readdata_i)
                  severity failure;

               error_o <= '1';
            end if;
         end if;
         if rst_i = '1' then
            error_o <= '0';
         end if;
      end if;
   end process p_verifier;

end architecture synthesis;

