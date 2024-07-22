-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;
   use work.types_pkg.all;

library xpm;
   use xpm.vcomponents.all;

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
      hdmi_clk_i     : in    std_logic;
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
      vdac_sync_n_o  : out   std_logic;
      hdmi_data_p_o  : out   std_logic_vector(2 downto 0);
      hdmi_data_n_o  : out   std_logic_vector(2 downto 0);
      hdmi_clk_p_o   : out   std_logic;
      hdmi_clk_n_o   : out   std_logic
   );
end entity video_wrapper;

architecture synthesis of video_wrapper is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := G_FONT_PATH & "font8x8.txt";

   signal   video_hcount : std_logic_vector(10 downto 0);
   signal   video_vcount : std_logic_vector(10 downto 0);
   signal   video_rgb    : std_logic_vector(7 downto 0);

   signal   video_data   : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

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

   audio_video_to_hdmi_inst : entity work.audio_video_to_hdmi
      port map (
         select_44100 => '0',
         dvi          => '0',
         vic          => to_stdlogicvector(4,8), -- CEA/CTA VIC 4=720p @ 60 Hz
         aspect       => "10",                   -- 01=4:3, 10=16:9
         pix_rep      => '0',                    -- no pixel repetition
         vs_pol       => C_VIDEO_MODE.V_POL,     -- horizontal polarity: positive
         hs_pol       => C_VIDEO_MODE.H_POL,     -- vertaical polarity: positive

         vga_rst      => video_rst_i,            -- active high reset
         vga_clk      => video_clk_i,            -- video pixel clock
         vga_vs       => vga_vs_o,
         vga_hs       => vga_hs_o,
         vga_de       => vga_de_o,
         vga_r        => vga_red_o,
         vga_g        => vga_green_o,
         vga_b        => vga_blue_o,

         -- PCM audio
         pcm_rst      => '0',
         pcm_clk      => '0',
         pcm_clken    => '0',

         -- PCM audio is signed
         pcm_l        => X"0000",
         pcm_r        => X"0000",

         pcm_acr      => '0',
         pcm_n        => X"00000",
         pcm_cts      => X"00000",

         -- TMDS output (parallel)
         tmds         => video_data
      ); -- audio_video_to_hdmi_inst


   -- serialiser: in this design we use HDMI SelectIO outputs

   hdmi_data_gen : for i in 0 to 2 generate
   begin

      serialiser_10to1_selectio_data_inst : entity work.serialiser_10to1_selectio
         port map (
            rst_i    => video_rst_i,
            clk_i    => video_clk_i,
            d_i      => video_data(i),
            clk_x5_i => hdmi_clk_i,
            out_p_o  => hdmi_data_p_o(i),
            out_n_o  => hdmi_data_n_o(i)
         ); -- serialiser_10to1_selectio_data_inst

   end generate hdmi_data_gen;


   serialiser_10to1_selectio_clk_inst : entity work.serialiser_10to1_selectio
      port map (
         rst_i    => video_rst_i,
         clk_i    => video_clk_i,
         clk_x5_i => hdmi_clk_i,
         d_i      => "0000011111",
         out_p_o  => hdmi_clk_p_o,
         out_n_o  => hdmi_clk_n_o
      ); -- serialiser_10to1_selectio_clk_inst

end architecture synthesis;

