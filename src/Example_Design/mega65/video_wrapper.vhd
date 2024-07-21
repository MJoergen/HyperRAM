library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.video_modes_pkg.all;

entity video_wrapper is
   generic (
      G_DIGITS_SIZE : integer;
      G_FONT_PATH   : string
   );
   port (
      video_clk_i    : in    std_logic;
      video_rst_i    : in    std_logic;
      video_digits_i : in    std_logic_vector(G_DIGITS_SIZE - 1 downto 0);
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

   signal   pixel_x   : std_logic_vector(C_VIDEO_MODE.PIX_SIZE - 1 downto 0);
   signal   pixel_y   : std_logic_vector(C_VIDEO_MODE.PIX_SIZE - 1 downto 0);
   signal   vs        : std_logic;
   signal   hs        : std_logic;
   signal   de        : std_logic;
   signal   vs_d1     : std_logic;
   signal   hs_d1     : std_logic;
   signal   de_d1     : std_logic;
   signal   vs_d2     : std_logic;
   signal   hs_d2     : std_logic;
   signal   de_d2     : std_logic;
   signal   vs_d3     : std_logic;
   signal   hs_d3     : std_logic;
   signal   de_d3     : std_logic;
   signal   video_rgb : std_logic_vector(7 downto 0);

begin

   video_sync_inst : entity work.video_sync
      generic map (
         G_VIDEO_MODE => C_VIDEO_MODE
      )
      port map (
         clk_i     => video_clk_i,
         rst_i     => video_rst_i,
         vs_o      => vs,
         hs_o      => hs,
         de_o      => de,
         pixel_x_o => pixel_x,
         pixel_y_o => pixel_y
      ); -- video_sync_inst

   -- Latency 3 clock cycles
   digits_inst : entity work.digits
      generic map (
         G_FONT_FILE   => C_FONT_FILE,
         G_DIGITS_SIZE => G_DIGITS_SIZE,
         G_VIDEO_MODE  => C_VIDEO_MODE
      )
      port map (
         clk_i    => video_clk_i,
         digits_i => video_digits_i,
         pix_x_i  => pixel_x,
         pix_y_i  => pixel_y,
         pixel_o  => video_rgb
      ); -- digits_inst

   delay_proc : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         vs_d1 <= vs;
         hs_d1 <= hs;
         de_d1 <= de;

         vs_d2 <= vs_d1;
         hs_d2 <= hs_d1;
         de_d2 <= de_d1;

         vs_d3 <= vs_d2;
         hs_d3 <= hs_d2;
         de_d3 <= de_d2;
      end if;
   end process delay_proc;

   vga_vs_o       <= vs_d3;
   vga_hs_o       <= hs_d3;
   vga_de_o       <= de_d3;

   vga_red_o      <= video_rgb;
   vga_green_o    <= video_rgb;
   vga_blue_o     <= video_rgb;

   vdac_clk_o     <= video_clk_i;
   vdac_blank_n_o <= '1';
   vdac_psave_n_o <= '1';
   vdac_sync_n_o  <= '0';

end architecture synthesis;

