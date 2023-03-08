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

entity avm_master3 is
   generic (
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i                 : in  std_logic;
      rst_i                 : in  std_logic;
      start_i               : in  std_logic;
      wait_o                : out std_logic;
      error_o               : out std_logic;

      m_avm_write_o         : out std_logic;
      m_avm_read_o          : out std_logic;
      m_avm_address_o       : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      m_avm_writedata_o     : out std_logic_vector(G_DATA_SIZE-1 downto 0);
      m_avm_byteenable_o    : out std_logic_vector(G_DATA_SIZE/8-1 downto 0);
      m_avm_burstcount_o    : out std_logic_vector(7 downto 0);
      m_avm_readdata_i      : in  std_logic_vector(G_DATA_SIZE-1 downto 0);
      m_avm_readdatavalid_i : in  std_logic;
      m_avm_waitrequest_i   : in  std_logic;
      -- Debug output
      address_o             : out std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      data_exp_o            : out std_logic_vector(G_DATA_SIZE-1 downto 0);
      data_read_o           : out std_logic_vector(G_DATA_SIZE-1 downto 0)
   );
end entity avm_master3;

architecture synthesis of avm_master3 is

   constant C_WRITE_SIZE : integer := 1;

   -- Combinatorial signals
   signal rand_update_s : std_logic;
   signal random_s      : std_logic_vector(63 downto 0);

   subtype R_ADDRESS    is natural range G_ADDRESS_SIZE-1 downto 0;
   subtype R_DATA       is natural range G_DATA_SIZE + R_ADDRESS'left downto R_ADDRESS'left + 1;
   subtype R_BYTEENABLE is natural range G_DATA_SIZE/8 + R_DATA'left  downto R_DATA'left + 1;
   subtype R_WRITE      is natural range C_WRITE_SIZE + R_BYTEENABLE'left  downto R_BYTEENABLE'left + 1;

   signal address_s     : std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
   signal data_s        : std_logic_vector(G_DATA_SIZE-1 downto 0);
   signal byteenable_s  : std_logic_vector(G_DATA_SIZE/8-1 downto 0);
   signal write_s       : std_logic_vector(C_WRITE_SIZE-1 downto 0);

   type t_state is (IDLE_ST, INIT_ST, WORKING_ST, READING_ST);

   signal state         : t_state := IDLE_ST;
   signal count         : std_logic_vector(G_ADDRESS_SIZE+2 downto 0);
   signal mem_data      : std_logic_vector(G_DATA_SIZE-1 downto 0);

   signal wr_en         : std_logic_vector(G_DATA_SIZE/8-1 downto 0);

begin

   i_random : entity work.random
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         update_i => rand_update_s,
         output_o => random_s
      );

   address_s    <= random_s(R_ADDRESS);
   data_s       <= random_s(R_DATA);
   byteenable_s <= random_s(R_BYTEENABLE);
   write_s      <= random_s(R_WRITE);

   rand_update_s <= (m_avm_write_o or m_avm_read_o) and not m_avm_waitrequest_i;

   p_master : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_avm_waitrequest_i = '0' then
            m_avm_write_o <= '0';
            m_avm_read_o  <= '0';
         end if;

         case state is
            when IDLE_ST =>
               if start_i = '1' then
                  report "Starting";
                  wait_o             <= '1';
                  m_avm_write_o      <= '1';
                  m_avm_read_o       <= '0';
                  m_avm_address_o    <= (others => '0');
                  m_avm_writedata_o  <= (others => '1');
                  m_avm_byteenable_o <= (others => '1');
                  m_avm_burstcount_o <= X"01";
                  state              <= INIT_ST;
               end if;

            when INIT_ST =>
               if m_avm_waitrequest_i = '0' then
                  if and(m_avm_address_o) then
                     state <= WORKING_ST;
                  else
                     m_avm_write_o   <= '1';
                     m_avm_address_o <= m_avm_address_o + 1;
                  end if;
               end if;

            when WORKING_ST | READING_ST =>
               if (m_avm_waitrequest_i = '0' or (m_avm_write_o = '0' and m_avm_read_o = '0')) and
                  (state = WORKING_ST or m_avm_readdatavalid_i = '1') then
                  if and(write_s) = '1' or byteenable_s = 0 then
                     m_avm_write_o      <= '1';
                     m_avm_read_o       <= '0';
                     m_avm_address_o    <= address_s;
                     m_avm_writedata_o  <= data_s;
                     m_avm_byteenable_o <= byteenable_s;
                     m_avm_burstcount_o <= X"01";
                     if byteenable_s = 0 then
                        m_avm_byteenable_o <= (others => '1');
                     end if;
                     state              <= WORKING_ST;
                  else
                     m_avm_write_o      <= '0';
                     m_avm_read_o       <= '1';
                     m_avm_address_o    <= address_s;
                     m_avm_burstcount_o <= X"01";
                     state              <= READING_ST;
                  end if;

                  count <= count + 1;
                  if count + 1 = 0 then
                     m_avm_write_o <= '0';
                     m_avm_read_o  <= '0';
                     wait_o        <= '0';
                     state         <= IDLE_ST;
                     report "Done";
                  end if;
               end if;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            wait_o             <= '0';
            m_avm_write_o      <= '0';
            m_avm_read_o       <= '0';
            m_avm_address_o    <= (others => '0');
            m_avm_writedata_o  <= (others => '0');
            m_avm_byteenable_o <= (others => '0');
            m_avm_burstcount_o <= (others => '0');
            count              <= (others => '0');
            state              <= IDLE_ST;
         end if;

      end if;
   end process p_master;

   wr_en <= m_avm_byteenable_o when m_avm_write_o = '1' and m_avm_waitrequest_i = '0'
            else (others => '0');

   i_blockram_with_byte_enable : entity work.blockram_with_byte_enable
      generic map (
         G_ADDR_SIZE   => G_ADDRESS_SIZE,
         G_COLUMN_SIZE => 8,
         G_NUM_COLUMNS => G_DATA_SIZE/8
      )
      port map (
         a_clk_i     => clk_i,
         a_addr_i    => m_avm_address_o,
         a_wr_data_i => m_avm_writedata_o,
         a_wr_en_i   => wr_en,
         a_rd_data_o => mem_data,
         b_clk_i     => '0',
         b_addr_i    => (others => '0'),
         b_wr_data_i => (others => '0'),
         b_wr_en_i   => (others => '0'),
         b_rd_data_o => open
      ); -- i_blockram_with_byte_enable

   p_verifier : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_avm_readdatavalid_i = '1' then
            address_o   <= m_avm_address_o;
            data_exp_o  <= mem_data;
            data_read_o <= m_avm_readdata_i;
            if m_avm_readdata_i /= mem_data then
               assert false
                  report "ERROR at Address " & to_hstring(m_avm_address_o) &
                  ". Expected " & to_hstring(mem_data) &
                  ", read " & to_hstring(m_avm_readdata_i)
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

