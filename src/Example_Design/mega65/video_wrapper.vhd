library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

entity video_wrapper is
   generic (
      G_FONT_PATH : string
   );
   port (
      video_clk_i           : in    std_logic;
      video_rst_i           : in    std_logic;
      video_stat_total_i    : in    std_logic_vector(31 downto 0);
      video_stat_error_i    : in    std_logic_vector(31 downto 0);
      video_stat_err_addr_i : in    std_logic_vector(31 downto 0);
      video_stat_err_exp_i  : in    std_logic_vector(63 downto 0);
      video_stat_err_read_i : in    std_logic_vector(63 downto 0);
      vga_red_o             : out   std_logic_vector(7 downto 0);
      vga_green_o           : out   std_logic_vector(7 downto 0);
      vga_blue_o            : out   std_logic_vector(7 downto 0);
      vga_hs_o              : out   std_logic;
      vga_vs_o              : out   std_logic;
      vga_de_o              : out   std_logic;
      vdac_clk_o            : out   std_logic;
      vdac_blank_n_o        : out   std_logic;
      vdac_psave_n_o        : out   std_logic;
      vdac_sync_n_o         : out   std_logic
   );
end entity video_wrapper;

architecture synthesis of video_wrapper is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := G_FONT_PATH & "font8x8.txt";

   signal   video_hcount : std_logic_vector(10 downto 0);
   signal   video_vcount : std_logic_vector(10 downto 0);
   signal   video_rgb    : std_logic_vector(7 downto 0);
   signal   video_x      : std_logic_vector(7 downto 0);
   signal   video_y      : std_logic_vector(7 downto 0);
   signal   video_char   : std_logic_vector(7 downto 0);
   signal   video_colors : std_logic_vector(15 downto 0);

   constant C_POS_X : natural               := 10;
   constant C_POS_Y : natural               := 10;

   signal   video_result_data : std_logic_vector(1023 downto 0);

   -- Convert ASCII string to std_logic_vector

   pure function str2slv (
      str : string
   ) return std_logic_vector is
      variable res_v : std_logic_vector(str'length * 8 - 1 downto 0);
   begin
      --
      for i in 0 to str'length-1 loop
         res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(character'pos(str(str'length - i)), 8);
      end loop;

      return res_v;
   end function str2slv;

   -- Convert std_logic_vector to ASCII

   pure function hexify (
      arg : std_logic_vector
   ) return std_logic_vector is
      variable val_v : integer range 0 to 15;
      variable res_v : std_logic_vector(arg'length * 2 - 1 downto 0);
   begin
      --
      for i in arg'length / 4 - 1 downto 0 loop
         val_v := to_integer(arg(arg'right + 4 * i + 3 downto arg'right + 4 * i));
         if val_v < 10 then
            res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(val_v + character'pos('0'), 8);
         else
            res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(val_v + character'pos('A') - 10, 8);
         end if;
      end loop;

      return res_v;
   end function hexify;

begin

   video_sync_inst : entity work.video_sync
      generic map (
         G_VIDEO_MODE => C_VIDEO_MODE
      )
      port map (
         clk_i     => video_clk_i,
         rst_i     => video_rst_i,
         vs_o      => vga_vs_o,
         hs_o      => vga_hs_o,
         de_o      => vga_de_o,
         pixel_x_o => video_hcount,
         pixel_y_o => video_vcount
      ); -- video_sync_inst

   video_chars_inst : entity work.video_chars
      generic map (
         G_FONT_FILE  => C_FONT_FILE,
         G_VIDEO_MODE => C_VIDEO_MODE
      )
      port map (
         video_clk_i    => video_clk_i,
         video_hcount_i => video_hcount,
         video_vcount_i => video_vcount,
         video_blank_i  => not vga_de_o,
         video_rgb_o    => video_rgb,
         video_x_o      => video_x,
         video_y_o      => video_y,
         video_char_i   => video_char,
         video_colors_i => video_colors
      ); -- video_chars_inst

   video_result_data <= str2slv("TOTAL:  ") & hexify(video_stat_total_i) & X"0D0A" &
                        str2slv("ERRORS: ") & hexify(video_stat_error_i) & X"0D0A" &
                        str2slv("ADDR:   ") & hexify(video_stat_err_addr_i) & X"0D0A" &
                        str2slv("EXP_HI: ") & hexify(video_stat_err_exp_i(63 downto 32)) & X"0D0A" &
                        str2slv("EXP_LO: ") & hexify(video_stat_err_exp_i(31 downto 0)) & X"0D0A" &
                        str2slv("READ_HI:") & hexify(video_stat_err_read_i(63 downto 32)) & X"0D0A" &
                        str2slv("READ_LO:") & hexify(video_stat_err_read_i(31 downto 0)) & X"0D0A" &
                        X"0D0A";

   video_proc : process (video_clk_i)
      variable col_v   : natural range 0 to 15;
      variable row_v   : natural range 0 to 6;
      variable index_v : natural range 0 to video_result_data'length / 8 - 1;
   begin
      if rising_edge(video_clk_i) then
         video_char   <= X"20";
         video_colors <= X"55BB";
         if video_x >= C_POS_X and video_x < C_POS_X + 16 and
            video_y >= C_POS_Y and video_y < C_POS_Y + 7 then
            col_v        := 15 - to_integer(video_x - C_POS_X);
            row_v        := 6 - to_integer(video_y - C_POS_Y);
            index_v      := row_v * 18 + col_v + 4;
            video_char <= video_result_data(index_v * 8 + 7 downto index_v * 8);
         end if;
      end if;
   end process video_proc;

   vga_red_o         <= video_rgb;
   vga_green_o       <= video_rgb;
   vga_blue_o        <= video_rgb;

   vdac_clk_o        <= video_clk_i;
   vdac_blank_n_o    <= '1';
   vdac_psave_n_o    <= '1';
   vdac_sync_n_o     <= '0';

end architecture synthesis;

