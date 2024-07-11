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
   use ieee.numeric_std_unsigned.all;

entity avm_master3 is
   generic (
      G_SINGLE_REQUEST_ONLY : boolean                       := false;
      G_SEED                : std_logic_vector(63 downto 0) := (others => '0');
      G_INIT_FIRST          : boolean;
      G_ADDRESS_SIZE        : integer; -- Number of bits
      G_DATA_SIZE           : integer  -- Number of bits
   );
   port (
      clk_i                 : in    std_logic;
      rst_i                 : in    std_logic;
      start_i               : in    std_logic;
      wait_o                : out   std_logic;

      m_avm_waitrequest_i   : in    std_logic;
      m_avm_write_o         : out   std_logic;
      m_avm_read_o          : out   std_logic;
      m_avm_address_o       : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      m_avm_writedata_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_avm_byteenable_o    : out   std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      m_avm_burstcount_o    : out   std_logic_vector(7 downto 0);
      m_avm_readdata_i      : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      m_avm_readdatavalid_i : in    std_logic
   );
end entity avm_master3;

architecture synthesis of avm_master3 is

   constant C_WAIT_SIZE  : integer := 1;
   constant C_WRITE_SIZE : integer := 1;

   -- Combinatorial signals
   signal   random_s : std_logic_vector(63 downto 0);

   subtype  R_ADDRESS    is natural range G_ADDRESS_SIZE - 1 downto 0;
   subtype  R_DATA       is natural range G_DATA_SIZE + R_ADDRESS'left downto R_ADDRESS'left + 1;
   subtype  R_BYTEENABLE is natural range G_DATA_SIZE / 8 + R_DATA'left  downto R_DATA'left + 1;
   subtype  R_WRITE      is natural range C_WRITE_SIZE + R_BYTEENABLE'left  downto R_BYTEENABLE'left + 1;
   subtype  R_WAIT       is natural range C_WAIT_SIZE + R_WRITE'left  downto R_WRITE'left + 1;

   signal   address_s    : std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
   signal   data_s       : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   byteenable_s : std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
   signal   write_s      : std_logic;
   signal   wait_s       : std_logic;

   type     state_type is (IDLE_ST, INIT_ST, WORKING_ST, DONE_ST);

   signal   state : state_type     := IDLE_ST;
   signal   count : std_logic_vector(G_ADDRESS_SIZE + 3 downto 0);

   signal   outstanding_read : std_logic;

begin

   random_inst : entity work.random
      generic map (
         G_SEED => G_SEED
      )
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         update_i => '1',
         output_o => random_s
      ); -- random_inst

   address_s    <= random_s(R_ADDRESS);
   data_s       <= random_s(R_DATA);
   byteenable_s <= random_s(R_BYTEENABLE);
   write_s      <= and(random_s(R_WRITE));
   wait_s       <= or(random_s(R_WAIT));

   master_proc : process (clk_i)
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
                  wait_o <= '1';
                  count  <= (others => '0');
                  state  <= WORKING_ST;
                  if G_INIT_FIRST then
                     m_avm_write_o      <= '1';
                     m_avm_read_o       <= '0';
                     m_avm_address_o    <= (others => '0');
                     m_avm_writedata_o  <= (others => '1');
                     m_avm_byteenable_o <= (others => '1');
                     m_avm_burstcount_o <= X"01";
                     state              <= INIT_ST;
                  end if;
               end if;

            when INIT_ST =>
               if m_avm_waitrequest_i = '0' then
                  if and (m_avm_address_o) then
                     state <= WORKING_ST;
                  else
                     m_avm_write_o   <= '1';
                     m_avm_address_o <= m_avm_address_o + 1;
                  end if;
               end if;

            when WORKING_ST =>
               if m_avm_waitrequest_i = '0' or (m_avm_write_o = '0' and m_avm_read_o = '0') then
                  if G_SINGLE_REQUEST_ONLY and (outstanding_read = '1' or m_avm_read_o = '1') then
                     null;
                  elsif wait_s = '1' then
                     null;
                  elsif write_s = '1' then
                     m_avm_write_o      <= '1';
                     m_avm_read_o       <= '0';
                     m_avm_address_o    <= address_s;
                     m_avm_writedata_o  <= data_s;
                     m_avm_byteenable_o <= byteenable_s;
                     m_avm_burstcount_o <= X"01";
                     if byteenable_s = 0 then
                        m_avm_byteenable_o <= (others => '1');
                     end if;
                  else
                     m_avm_write_o      <= '0';
                     m_avm_read_o       <= '1';
                     m_avm_address_o    <= address_s;
                     m_avm_burstcount_o <= X"01";
                  end if;

                  count <= count + 1;
                  if count + 1 = 0 then
                     m_avm_write_o <= '0';
                     m_avm_read_o  <= '0';
                     state         <= DONE_ST;
                  end if;
               end if;

            when DONE_ST =>
               if start_i = '0' then
                  wait_o <= '0';
                  state  <= IDLE_ST;
                  report "Done";
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
   end process master_proc;

   outstanding_read_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if m_avm_readdatavalid_i = '1' then
            outstanding_read <= '0';
         end if;
         if m_avm_read_o = '1' and m_avm_waitrequest_i = '0' then
            outstanding_read <= '1';
         end if;
         if rst_i = '1' then
            outstanding_read <= '0';
         end if;
      end if;
   end process outstanding_read_proc;

end architecture synthesis;

