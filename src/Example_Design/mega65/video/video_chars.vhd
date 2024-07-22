library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity video_chars is
   generic (
      G_FONT_FILE  : string;
      G_VIDEO_MODE : video_modes_type
   );
   port (
      video_clk_i    : in    std_logic;
      video_hcount_i : in    std_logic_vector(10 downto 0);
      video_vcount_i : in    std_logic_vector(10 downto 0);
      video_blank_i  : in    std_logic;
      video_rgb_o    : out   std_logic_vector(7 downto 0);
      video_x_o      : out   std_logic_vector(7 downto 0);
      video_y_o      : out   std_logic_vector(7 downto 0);
      video_char_i   : in    std_logic_vector(7 downto 0);
      video_colors_i : in    std_logic_vector(15 downto 0)
   );
end entity video_chars;

architecture synthesis of video_chars is

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype  BITMAP_TYPE is std_logic_vector(63 downto 0);

   -- Stage 0
   signal   black_0    : std_logic;
   signal   char_col_0 : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_0 : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_0  : integer range 0 to 7;
   signal   pix_row_0  : integer range 0 to 7;

   -- Stage 1
   signal   black_1       : std_logic;
   signal   char_col_1    : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_1    : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_1     : integer range 0 to 7;
   signal   pix_row_1     : integer range 0 to 7;
   signal   nibble_1      : std_logic_vector(3 downto 0);
   signal   char_nibble_1 : std_logic_vector(7 downto 0);
   signal   char_txt_1    : std_logic_vector(7 downto 0);
   signal   char_1        : std_logic_vector(7 downto 0);
   signal   colors_1      : std_logic_vector(15 downto 0);

   -- Stage 2
   signal   black_2        : std_logic;
   signal   bitmap_2       : BITMAP_TYPE;
   signal   char_col_2     : integer range 0 to G_VIDEO_MODE.H_MAX / 16 - 1;
   signal   char_row_2     : integer range 0 to G_VIDEO_MODE.V_MAX / 16 - 1;
   signal   pix_col_2      : integer range 0 to 7;
   signal   pix_row_2      : integer range 0 to 7;
   signal   bitmap_index_2 : integer range 0 to 63;
   signal   pix_2          : std_logic;
   signal   colors_2       : std_logic_vector(15 downto 0);

   -- Stage 3
   signal   pixel_3 : std_logic_vector(7 downto 0);

begin

   --------------------------------------------------
   -- Stage 0
   --------------------------------------------------

   -- Calculate character coordinates, within 40x30
   black_0    <= '1' when video_hcount_i >= G_VIDEO_MODE.H_PIXELS or video_vcount_i >= G_VIDEO_MODE.V_PIXELS else
                 '0';
   char_col_0 <= to_integer(video_hcount_i(10 downto 5));
   char_row_0 <= to_integer(video_vcount_i(10 downto 5));
   pix_col_0  <= to_integer(video_hcount_i(4 downto 2));
   pix_row_0  <= 7 - to_integer(video_vcount_i(4 downto 2));

   video_x_o    <= "00" & video_hcount_i(10 downto 5);
   video_y_o    <= "00" & video_vcount_i(10 downto 5);


   --------------------------------------------------
   -- Stage 1
   --------------------------------------------------

   stage1_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         black_1    <= black_0;
         char_col_1 <= char_col_0;
         char_row_1 <= char_row_0;
         pix_col_1  <= pix_col_0;
         pix_row_1  <= pix_row_0;
      end if;
   end process stage1_proc;

   -- Calculate character to display at current position
   char_1     <= video_char_i;
   colors_1   <= video_colors_i;


   --------------------------------------------------
   -- Stage 2
   --------------------------------------------------

   -- Calculate bitmap (64 bits) of digit at current position
   font_inst : entity work.font
      generic map (
         G_FONT_FILE => G_FONT_FILE
      )
      port map (
         clk_i    => video_clk_i,
         char_i   => char_1,
         bitmap_o => bitmap_2
      ); -- font_inst

   stage2_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         black_2    <= black_1;
         char_col_2 <= char_col_1;
         char_row_2 <= char_row_1;
         pix_col_2  <= pix_col_1;
         pix_row_2  <= pix_row_1;
         colors_2   <= colors_1;
      end if;
   end process stage2_proc;

   -- Calculate pixel at current position ('0' or '1')
   bitmap_index_2 <= pix_row_2 * 8 + pix_col_2;
   pix_2          <= bitmap_2(bitmap_index_2);


   --------------------------------------------------
   -- Stage 3
   --------------------------------------------------

   -- Generate pixel colour
   stage3_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         if pix_2 = '1' then
            pixel_3 <= colors_2(7 downto 0);
         else
            pixel_3 <= colors_2(15 downto 8);
         end if;

         -- Make sure colour is black outside visible screen
         if black_2 = '1' then
            pixel_3 <= (others => '0');
         end if;
      end if;
   end process stage3_proc;

   video_rgb_o      <= pixel_3;

end architecture synthesis;

