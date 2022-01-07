library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trafic_gen is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(31 downto 0);
      avm_writedata_o     : out std_logic_vector(15 downto 0);
      avm_byteenable_o    : out std_logic_vector(1 downto 0);
      avm_burstcount_o    : out std_logic_vector(7 downto 0);
      avm_readdata_i      : in  std_logic_vector(15 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;
      uled_o              : out std_logic
   );
end entity trafic_gen;

architecture synthesis of trafic_gen is

   -- constant C_ADDRESS_SIZE : integer := 23; -- 8 MB
   constant C_ADDRESS_SIZE : integer := 3; -- 8 B
   constant C_INIT_DELAY   : integer := 161*200; -- Wait for 161 us for device to initialize

   signal address : std_logic_vector(C_ADDRESS_SIZE-1 downto 0);
   signal data    : std_logic_vector(15 downto 0);

   type state_t is (
      INIT_ST,
      WRITING_ST,
      READING_ST,
      VERIFYING_ST,
      STOPPED_ST
   );

   signal state : state_t := INIT_ST;

   signal init_counter : integer range 0 to C_INIT_DELAY;

begin

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         case state is 
            when INIT_ST =>
               address <= (others => '0');
               data    <= (others => '1');
               if init_counter = 0 then
                  state   <= WRITING_ST;
               end if;
               init_counter <= init_counter - 1;

            when WRITING_ST =>

               avm_write_o      <= '1';
               avm_read_o       <= '0';
               avm_address_o    <= (others => '0');
               avm_address_o(C_ADDRESS_SIZE-1 downto 0) <= address;
               avm_writedata_o  <= data;
               avm_byteenable_o <= "11";
               avm_burstcount_o <= X"01";

               if avm_write_o = '1' and avm_waitrequest_i = '0' then
                  address <= std_logic_vector(unsigned(address) + 2);
                  if data(15) = '1' then
                     data <= (data(14 downto 0) & "0") xor X"002D";
                  else
                     data <= (data(14 downto 0) & "0");
                  end if;

                  if signed(address) = -2 then
                     data  <= (others => '1');
                     state <= READING_ST;
                  end if;
               end if;

            when READING_ST =>
               avm_write_o      <= '0';
               avm_read_o       <= '1';
               avm_address_o    <= (others => '0');
               avm_address_o(C_ADDRESS_SIZE-1 downto 0) <= address;
               avm_burstcount_o <= X"01";

               if avm_read_o = '1' and avm_waitrequest_i = '0' then
                  avm_read_o <= '0';
                  state <= VERIFYING_ST;
               end if;

            when VERIFYING_ST =>
               if avm_readdatavalid_i = '1' then
                  if avm_readdata_i /= data then
                     uled_o <= '1';
                  end if;

                  address <= std_logic_vector(unsigned(address) + 2);
                  if data(15) = '1' then
                     data <= (data(14 downto 0) & "0") xor X"002D";
                  else
                     data <= (data(14 downto 0) & "0");
                  end if;

                  if signed(address) = -2 then
                     data  <= (others => '1');
                     state <= STOPPED_ST;
                  else
                     state <= READING_ST;
                  end if;
               end if;

            when STOPPED_ST =>
               state <= STOPPED_ST;

         end case;

         if rst_i = '1' then
            init_counter <= C_INIT_DELAY;
            avm_write_o  <= '0';
            avm_read_o   <= '0';
            uled_o       <= '0';
            state        <= INIT_ST;
         end if;
      end if;
   end process p_fsm;


end architecture synthesis;

