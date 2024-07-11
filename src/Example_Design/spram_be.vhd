-- Single port RAM with byte-enable

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity spram_be is
   generic (
      G_INIT_ZEROS   : boolean := false;
      G_ADDRESS_SIZE : natural;
      G_DATA_SIZE    : natural
   );
   port (
      clk_i     : in    std_logic;
      addr_i    : in    std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      wr_en_i   : in    std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      wr_data_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      rd_en_i   : in    std_logic;
      rd_data_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity spram_be;

architecture synthesis of spram_be is

   type   ram_type is array (0 to 2 ** G_ADDRESS_SIZE - 1) of std_logic_vector(G_DATA_SIZE - 1 downto 0);

   pure function ram_init return ram_type is
      variable ram_v : ram_type;
   begin
      if G_INIT_ZEROS then
         ram_v := (others => (others => '0'));
      end if;
      return ram_v;
   end function ram_init;

   signal ram : ram_type := ram_init;

begin

   ram_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then

         for i in 0 to G_DATA_SIZE / 8 - 1 loop
            if wr_en_i(i) = '1' then
               ram(to_integer(addr_i))(8 * i + 7 downto 8 * i) <= wr_data_i(8 * i + 7 downto 8 * i);
            end if;
         end loop;

         if rd_en_i = '1' then
            rd_data_o <= ram(to_integer(addr_i));
         end if;
      end if;
   end process ram_proc;

end architecture synthesis;

