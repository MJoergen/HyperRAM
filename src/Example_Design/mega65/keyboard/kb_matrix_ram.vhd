-- Original MEGA65 keyboard driver file by Paul Gardner-Stephen
-- see AUTHORS details and license
--
-- Modified for gbc4mega65 by sy2002 in January 2021
-- Added to MiSTer2MEGA65 based on the modified gbc4mega65 form by sy2002 in July 2021

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity kb_matrix_ram is
   port (
      clka_i     : in    std_logic;
      addressa_i : in    integer range 0 to 15;
      dia_i      : in    std_logic_vector(7 downto 0);
      wea_i      : in    std_logic_vector(7 downto 0);
      addressb_i : in    integer range 0 to 15;
      dob_o      : out   std_logic_vector(7 downto 0)
   );
end entity kb_matrix_ram;

architecture synthesis of kb_matrix_ram is

   type   ram_type is array (0 to 15) of std_logic_vector(7 downto 0);
   signal ram : ram_type := (others => x"FF");

begin

   write_proc : process (clka_i)
   begin
      if rising_edge(clka_i) then

         for i in 0 to 7 loop
            if wea_i(i) = '1' then
               ram(addressa_i)(i) <= dia_i(i);
            end if;
         end loop;

      end if;
   end process write_proc;

   read_proc : process (all)
   begin
      dob_o <= ram(addressb_i);
   end process read_proc;

end architecture synthesis;

