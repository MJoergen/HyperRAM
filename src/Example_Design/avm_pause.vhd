library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module inserts empty wait cycles into an Avalon Memory Map stream.
-- The frequency of empty wait cycles is controlled by G_PAUSE:
-- * Setting it to 0 disables the empty cycles.
-- * Setting it to 10 inserts empty cycles every tenth cycle, i.e. 90 % throughput.
-- * Setting it to -10 inserts empty cycles except every tenth cycle, i.e. 10 % throughput.

entity avm_pause is
   generic (
      G_PAUSE        : integer;
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i                 : in  std_logic;
      rst_i                 : in  std_logic;
      s_avm_write_i         : in  std_logic;
      s_avm_read_i          : in  std_logic;
      s_avm_address_i       : in  std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      s_avm_writedata_i     : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      s_avm_byteenable_i    : in  std_logic_vector(G_DATA_SIZE/8-1 downto 0);
      s_avm_burstcount_i    : in  std_logic_vector(7 downto 0);
      s_avm_readdata_o      : out std_logic_vector(G_DATA_SIZE-1 downto 0);
      s_avm_readdatavalid_o : out std_logic;
      s_avm_waitrequest_o   : out std_logic;
      m_avm_write_o         : out std_logic;
      m_avm_read_o          : out std_logic;
      m_avm_address_o       : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      m_avm_writedata_o     : out std_logic_vector(G_DATA_SIZE-1 downto 0);
      m_avm_byteenable_o    : out std_logic_vector(G_DATA_SIZE/8-1 downto 0);
      m_avm_burstcount_o    : out std_logic_vector(7 downto 0);
      m_avm_readdata_i      : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      m_avm_readdatavalid_i : in  std_logic;
      m_avm_waitrequest_i   : in  std_logic
   );
end entity avm_pause;

architecture simulation of avm_pause is

   signal cnt : integer range 0 to G_PAUSE;
   signal allow : std_logic;

begin

   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_avm_waitrequest_i = '0' then
            cnt <= (cnt + 1) mod G_PAUSE;
         end if;

         if rst_i = '1' then
            cnt <= 0;
         end if;
      end if;
   end process p_cnt;

   allow <= '1' when cnt /= 0 else '0';

   m_avm_write_o         <= s_avm_write_i and allow;
   m_avm_read_o          <= s_avm_read_i and allow;
   m_avm_address_o       <= s_avm_address_i;
   m_avm_writedata_o     <= s_avm_writedata_i;
   m_avm_byteenable_o    <= s_avm_byteenable_i;
   m_avm_burstcount_o    <= s_avm_burstcount_i;
   s_avm_readdata_o      <= m_avm_readdata_i;
   s_avm_readdatavalid_o <= m_avm_readdatavalid_i;
   s_avm_waitrequest_o   <= m_avm_waitrequest_i or not allow;

end architecture simulation;

