library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity uart is
   generic (
      G_DIVISOR : natural
   );
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      tx_valid_i : in    std_logic;
      tx_ready_o : out   std_logic;
      tx_data_i  : in    std_logic_vector(7 downto 0);
      rx_valid_o : out   std_logic;
      rx_ready_i : in    std_logic;
      rx_data_o  : out   std_logic_vector(7 downto 0);
      uart_tx_o  : out   std_logic := '1';
      uart_rx_i  : in    std_logic
   );
end entity uart;

architecture synthesis of uart is

   type   state_type is (
      IDLE_ST,
      BUSY_ST
   );

   signal tx_data    : std_logic_vector(9 downto 0);
   signal tx_state   : state_type := IDLE_ST;
   signal tx_counter : natural range 0 to G_DIVISOR;

   signal rx_data    : std_logic_vector(9 downto 0);
   signal rx_state   : state_type := IDLE_ST;
   signal rx_counter : natural range 0 to G_DIVISOR;

   signal uart_tx : std_logic;

begin

   tx_ready_o <= '1' when tx_state = IDLE_ST else
                 '0';

   uart_tx    <= tx_data(0);

   tx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         uart_tx_o <= uart_tx;

         case tx_state is

            when IDLE_ST =>
               if tx_valid_i = '1' then
                  tx_data    <= "1" & tx_data_i & "0";
                  tx_counter <= G_DIVISOR;
                  tx_state   <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if tx_counter > 0 then
                  tx_counter <= tx_counter - 1;
               else
                  if or (tx_data(9 downto 1)) = '1' then
                     tx_counter <= G_DIVISOR;
                     tx_data    <= "0" & tx_data(9 downto 1);
                  else
                     tx_data  <= (others => '1');
                     tx_state <= IDLE_ST;
                  end if;
               end if;

         end case;


         if rst_i = '1' then
            tx_data    <= (others => '1');
            tx_state   <= IDLE_ST;
            tx_counter <= 0;
            uart_tx_o  <= '1';
         end if;
      end if;
   end process tx_proc;

   rx_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if rx_ready_i = '1' then
            rx_valid_o <= '0';
         end if;

         case rx_state is

            when IDLE_ST =>
               if uart_rx_i = '0' then
                  rx_data    <= uart_rx_i & rx_data(9 downto 1);
                  rx_counter <= G_DIVISOR / 2;
                  rx_state   <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if rx_counter > 0 then
                  rx_counter <= rx_counter - 1;
               else
                  rx_counter <= G_DIVISOR;
                  rx_data    <= uart_rx_i & rx_data(9 downto 1);
               end if;

         end case;

         if rx_data(0) = '0' and rx_data(9) = '1' then
            rx_data_o  <= rx_data(8 downto 1);
            rx_valid_o <= '1';
            rx_data    <= (others => '1');
            rx_state   <= IDLE_ST;
            rx_counter <= 0;
         end if;

         if rst_i = '1' then
            rx_valid_o <= '0';
            rx_data    <= (others => '1');
            rx_state   <= IDLE_ST;
            rx_counter <= 0;
         end if;
      end if;
   end process rx_proc;

end architecture synthesis;

