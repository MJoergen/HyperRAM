library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity font is
   generic (
      G_FONT_FILE : string
   );
   port (
      clk_i    : in  std_logic;
      char_i   : in  std_logic_vector(7 downto 0);
      bitmap_o : out std_logic_vector(63 downto 0)
   );
end entity font;

architecture synthesis of font is

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype bitmap_t is std_logic_vector(63 downto 0);

   -- The entire font is defined by an array bitmaps, one for each character.
   type bitmap_vector_t is array (0 to 255) of bitmap_t;


   -- This reads the ROM contents from a text file
   impure function InitRamFromFile(RamFileName : in string) return bitmap_vector_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : bitmap_vector_t := (others => (others => '0'));
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in bitmap_vector_t'range loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, RAM(i));
         if endfile(RamFile) then
            return RAM;
         end if;
      end loop;
      return RAM;
   end function;

   constant bitmaps : bitmap_vector_t := InitRamFromFile(G_FONT_FILE);

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         bitmap_o <= bitmaps(to_integer(char_i));
      end if;
   end process p_read;

end architecture synthesis;

