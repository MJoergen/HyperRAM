-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.video_modes_pkg.all;

entity video_wrapper is
   generic (
      G_FONT_PATH : string
   );
   port (
      video_clk_i    : in    std_logic;
      video_rst_i    : in    std_logic;
      video_pos_x_o  : out   std_logic_vector(7 downto 0);
      video_pos_y_o  : out   std_logic_vector(7 downto 0);
      video_char_i   : in    std_logic_vector(7 downto 0);
      video_colors_i : in    std_logic_vector(15 downto 0);
      -- MEGA65 I/O ports
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vga_de_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_psave_n_o : out   std_logic;
      vdac_sync_n_o  : out   std_logic
   );
end entity video_wrapper;

architecture synthesis of video_wrapper is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := G_FONT_PATH & "font8x8.txt";

   signal   video_hcount : std_logic_vector(10 downto 0);
   signal   video_vcount : std_logic_vector(10 downto 0);
   signal   video_rgb    : std_logic_vector(7 downto 0);

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
         video_x_o      => video_pos_x_o,
         video_y_o      => video_pos_y_o,
         video_char_i   => video_char_i,
         video_colors_i => video_colors_i
      ); -- video_chars_inst

   vga_red_o      <= video_rgb;
   vga_green_o    <= video_rgb;
   vga_blue_o     <= video_rgb;

   vdac_clk_o     <= video_clk_i;
   vdac_blank_n_o <= '1';
   vdac_psave_n_o <= '1';
   vdac_sync_n_o  <= '0';

end architecture synthesis;

