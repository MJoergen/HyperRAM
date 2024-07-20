library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;
   use std.textio.all;

entity font is
   generic (
      G_FONT_FILE : string
   );
   port (
      clk_i    : in    std_logic;
      char_i   : in    std_logic_vector(7 downto 0);
      bitmap_o : out   std_logic_vector(63 downto 0)
   );
end entity font;

architecture synthesis of font is

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype  BITMAP_TYPE is std_logic_vector(63 downto 0);

   -- The entire font is defined by an array bitmaps, one for each character.
   type     bitmap_vector_type is array (0 to 255) of BITMAP_TYPE;


   -- This reads the ROM contents from a text file

   impure function init_ram_from_file (
      ram_file_name : in string
   ) return bitmap_vector_type is
      file     ram_file        : text;
      variable ram_file_line_v : line;
      variable ram_v           : bitmap_vector_type := (others => (others => '0'));
   begin
      file_open(ram_file, ram_file_name, read_mode);

      for i in bitmap_vector_type'range loop
         readline (ram_file, ram_file_line_v);
         hread (ram_file_line_v, ram_v(i));
         if endfile(ram_file) then
            return ram_v;
         end if;
      end loop;

      return ram_v;
   end function init_ram_from_file;

   constant C_BITMAPS : bitmap_vector_type := init_ram_from_file(G_FONT_FILE);

begin

   read_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         bitmap_o <= C_BITMAPS(to_integer(char_i));
      end if;
   end process read_proc;

end architecture synthesis;

