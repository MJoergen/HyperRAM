library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity trafic_gen is
   generic (
      G_DATA_SIZE    : natural;
      G_ADDRESS_SIZE : natural
   );
   port (
      clk_i               : in    std_logic;
      rst_i               : in    std_logic;
      start_i             : in    std_logic;
      wait_o              : out   std_logic;
      stat_total_o        : out   std_logic_vector(31 downto 0);
      stat_error_o        : out   std_logic_vector(31 downto 0);
      stat_err_addr_o     : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      stat_err_exp_o      : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      stat_err_read_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      stat_err_read_2nd_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_waitrequest_i   : in    std_logic;
      avm_write_o         : out   std_logic;
      avm_read_o          : out   std_logic;
      avm_address_o       : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      avm_writedata_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_byteenable_o    : out   std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      avm_burstcount_o    : out   std_logic_vector(7 downto 0);
      avm_readdata_i      : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_readdatavalid_i : in    std_logic
   );
end entity trafic_gen;

architecture synthesis of trafic_gen is

   type   state_type is (
      IDLE_ST,
      START_ST,
      WRITE_ST,
      READ_ST,
      READING_ST,
      READING_SECOND_ST,
      ERROR_ST
   );

   signal state : state_type := IDLE_ST;

   signal seed      : std_logic_vector(31 downto 0);
   signal counter   : std_logic_vector(47 downto 0);

   signal exp_addr : std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
   signal exp_data : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   attribute mark_debug : string;
   attribute mark_debug of state        : signal is "true";
   attribute mark_debug of seed         : signal is "true";
   attribute mark_debug of counter      : signal is "true";
   attribute mark_debug of exp_addr     : signal is "true";
   attribute mark_debug of exp_data     : signal is "true";
   attribute mark_debug of stat_error_o : signal is "true";

begin

   avm_burstcount_o <= X"01";

   stat_total_o     <= counter(47 downto 16);

   fsm_proc : process (clk_i)
      --

      pure function get_random (
         seed_v    : std_logic_vector;
         counter_v : std_logic_vector;
         size_v    : natural
      ) return std_logic_vector is
         variable res_v : std_logic_vector(95 downto 0);
      begin
         -- Shuffle the bits in a deterministic but pseudo-random way
         res_v := counter_v * (counter_v + seed_v);
         return res_v(size_v - 1 downto 0);
      end function get_random;

   --
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         case state is

            when IDLE_ST =>
               seed <= seed + 1;

            when START_ST =>
               if avm_waitrequest_i = '0' then
                  -- Write first word
                  avm_address_o    <= get_random(seed,     counter, G_ADDRESS_SIZE);
                  avm_writedata_o  <= get_random(seed + 1, counter, G_DATA_SIZE);
                  avm_write_o      <= '1';
                  avm_byteenable_o <= (others => '1');
                  counter          <= counter + 1;
                  state            <= WRITE_ST;
               end if;

            when WRITE_ST =>
               if avm_waitrequest_i = '0' then
                  -- Write second word
                  avm_address_o    <= get_random(seed,     counter, G_ADDRESS_SIZE);
                  avm_writedata_o  <= get_random(seed + 1, counter, G_DATA_SIZE);
                  avm_write_o      <= '1';
                  avm_byteenable_o <= (others => '1');
                  counter          <= counter + 1;
                  state            <= READ_ST;
               end if;

            when READ_ST =>
               if avm_waitrequest_i = '0' then
                  -- Initiate read
                  avm_address_o <= get_random(seed,     counter - 2, G_ADDRESS_SIZE);
                  avm_read_o    <= '1';

                  exp_addr      <= get_random(seed,     counter - 2, G_ADDRESS_SIZE);
                  exp_data      <= get_random(seed + 1, counter - 2, G_DATA_SIZE);

                  state         <= READING_ST;
               end if;

            when READING_ST =>
               if avm_readdatavalid_i = '1' then
                  if avm_readdata_i /= exp_data then
                     stat_err_addr_o <= exp_addr;
                     stat_err_exp_o  <= exp_data;
                     stat_err_read_o <= avm_readdata_i;
                     report "First read error at address=" & to_hstring(exp_addr)
                            & ". Got=" & to_hstring(avm_readdata_i)
                            & ", expected=" & to_hstring(exp_data);
                     stat_error_o <= stat_error_o + 1;

                     -- Read again
                     avm_read_o   <= '1';
                     state        <= READING_SECOND_ST;
                  else
                     -- Write next word
                     avm_address_o    <= get_random(seed, counter, G_ADDRESS_SIZE);
                     avm_writedata_o  <= get_random(seed + 1, counter, G_DATA_SIZE);
                     avm_write_o      <= '1';
                     avm_byteenable_o <= (others => '1');
                     counter          <= counter + 1;
                     state            <= READ_ST;
                  end if;
               end if;

            when READING_SECOND_ST =>
               if avm_readdatavalid_i = '1' then
                  if avm_readdata_i /= exp_data then
                     stat_err_addr_o     <= exp_addr;
                     stat_err_exp_o      <= exp_data;
                     stat_err_read_2nd_o <= avm_readdata_i;
                     report "Second read error at address=" & to_hstring(exp_addr)
                            & ". Got=" & to_hstring(avm_readdata_i)
                            & ", expected=" & to_hstring(exp_data);
                     stat_error_o <= stat_error_o + X"10000";
                  end if;

                  -- Write next word
                  avm_address_o    <= get_random(seed, counter, G_ADDRESS_SIZE);
                  avm_writedata_o  <= get_random(seed + 1, counter, G_DATA_SIZE);
                  avm_write_o      <= '1';
                  avm_byteenable_o <= (others => '1');
                  counter          <= counter + 1;
                  state            <= READ_ST;
               end if;

            when ERROR_ST =>
               null;

         end case;

         if start_i = '1' then
            counter      <= (others => '0');
            wait_o       <= '1';
            stat_error_o <= (others => '0');
            state        <= START_ST;
         end if;

         if rst_i = '1' then
            wait_o      <= '0';
            avm_write_o <= '0';
            avm_read_o  <= '0';
            seed        <= (others => '0');
            state       <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

