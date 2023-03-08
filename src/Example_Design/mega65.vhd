-- This is a wrapper for all the MEGA65 related files (keyboard and video).
-- Its purpose is to simplify the top-level MEGA65 file by wrapping away
-- anything that is not directly related to the HyperRAM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;
use work.types_pkg.all;

library xpm;
use xpm.vcomponents.all;

entity mega65 is
   port (
      sys_clk      : in  std_logic;                  -- 100 MHz clock
      sys_reset_n  : in  std_logic;                  -- CPU reset button

      -- From HyperRAM trafic generator
      sys_start_o  : out std_logic;
      sys_active_i : in  std_logic;
      sys_error_i  : in  std_logic;
      sys_digits_i : in  std_logic_vector(127 downto 0);

      -- Interface for physical keyboard
      kb_io0       : out std_logic;
      kb_io1       : out std_logic;
      kb_io2       : in  std_logic;

      -- Digital Video
      hdmi_data_p  : out std_logic_vector(2 downto 0);
      hdmi_data_n  : out std_logic_vector(2 downto 0);
      hdmi_clk_p   : out std_logic;
      hdmi_clk_n   : out std_logic
   );
end entity mega65;

architecture synthesis of mega65 is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_t := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string := "font8x8.txt";

   -- MEGA65 clocks
   signal kbd_clk        : std_logic;
   signal video_clk      : std_logic;
   signal hdmi_clk       : std_logic;

   -- resets
   signal rst            : std_logic;
   signal video_rst      : std_logic;

   signal kbd_return_out : std_logic;
   signal kbd_active     : std_logic;
   signal kbd_error      : std_logic;

   signal video_vs       : std_logic;
   signal video_hs       : std_logic;
   signal video_de       : std_logic;
   signal video_red      : std_logic_vector(7 downto 0);
   signal video_green    : std_logic_vector(7 downto 0);
   signal video_blue     : std_logic_vector(7 downto 0);
   signal video_digits   : std_logic_vector(127 downto 0);
   signal video_data     : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

begin

   --------------------------------------------------------
   -- Generate clocks for MEGA65 platform (keyboard and video)
   --------------------------------------------------------

   i_clk_mega65 : entity work.clk_mega65
      port map
      (
         sys_clk_i    => sys_clk,
         sys_rstn_i   => sys_reset_n,
         kbd_clk_o    => kbd_clk,
         pixel_clk_o  => video_clk,
         pixel_rst_o  => video_rst,
         pixel_clk5_o => hdmi_clk
      ); -- i_clk_mega65


   --------------------------------------------------------------------------
   -- keyboard
   --------------------------------------------------------------------------

   i_keyboard : entity work.keyboard
      port map (
         cpuclock       => kbd_clk,
         kio8           => kb_io0,
         kio9           => kb_io1,
         kio10          => kb_io2,
         return_out     => kbd_return_out, -- Active low
         flopled        => kbd_error,
         powerled       => kbd_active
      ); -- i_keyboard


   i_cdc_start: xpm_cdc_array_single
      generic map (
         WIDTH => 1
      )
      port map (
         src_clk     => kbd_clk,
         src_in(0)   => not kbd_return_out,
         dest_clk    => sys_clk,
         dest_out(0) => sys_start_o
      ); -- i_cdc_start


   i_cdc_keyboard: xpm_cdc_array_single
      generic map (
         WIDTH => 2
      )
      port map (
         src_clk      => sys_clk,
         src_in(0)    => sys_active_i,
         src_in(1)    => sys_error_i,
         dest_clk     => kbd_clk,
         dest_out(0)  => kbd_active,
         dest_out(1)  => kbd_error
      ); -- i_cdc_keyboard


   --------------------------------------------------------------------------
   -- video
   --------------------------------------------------------------------------

   i_cdc_video: xpm_cdc_array_single
      generic map (
         WIDTH => 128
      )
      port map (
         src_clk  => sys_clk,
         src_in   => sys_digits_i,
         dest_clk => video_clk,
         dest_out => video_digits
      ); -- i_cdc_video


   i_video : entity work.video
      generic map
      (
         G_FONT_FILE   => C_FONT_FILE,
         G_DIGITS_SIZE => 128,
         G_VIDEO_MODE  => C_VIDEO_MODE
      )
      port map
      (
         rst_i         => video_rst,
         clk_i         => video_clk,
         digits_i      => video_digits,   -- From HyperRAM trafic generator
         video_vs_o    => video_vs,
         video_hs_o    => video_hs,
         video_de_o    => video_de,
         video_red_o   => video_red,
         video_green_o => video_green,
         video_blue_o  => video_blue
      ); -- i_video


   i_audio_video_to_hdmi : entity work.audio_video_to_hdmi
      port map (
      select_44100 => '0',
      dvi          => '0',
      vic          => std_logic_vector(to_unsigned(4,8)),  -- CEA/CTA VIC 4=720p @ 60 Hz
      aspect       => "10",                                -- 01=4:3, 10=16:9
      pix_rep      => '0',                                 -- no pixel repetition
      vs_pol       => C_VIDEO_MODE.V_POL,                  -- horizontal polarity: positive
      hs_pol       => C_VIDEO_MODE.H_POL,                  -- vertaical polarity: positive

      vga_rst      => video_rst,                           -- active high reset
      vga_clk      => video_clk,                           -- video pixel clock
      vga_vs       => video_vs,
      vga_hs       => video_hs,
      vga_de       => video_de,
      vga_r        => video_red,
      vga_g        => video_green,
      vga_b        => video_blue,

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
   ); -- i_audio_video_to_hdmi


   -- serialiser: in this design we use HDMI SelectIO outputs
   gen_hdmi_data: for i in 0 to 2 generate
   begin
      i_serialiser_10to1_selectio_data: entity work.serialiser_10to1_selectio
      port map (
         rst_i    => video_rst,
         clk_i    => video_clk,
         d_i      => video_data(i),
         clk_x5_i => hdmi_clk,
         out_p_o  => hdmi_data_p(i),
         out_n_o  => hdmi_data_n(i)
      ); -- i_serialiser_10to1_selectio_data
   end generate gen_hdmi_data;


   i_serialiser_10to1_selectio_clk : entity work.serialiser_10to1_selectio
   port map (
         rst_i    => video_rst,
         clk_i    => video_clk,
         clk_x5_i => hdmi_clk,
         d_i      => "0000011111",
         out_p_o  => hdmi_clk_p,
         out_n_o  => hdmi_clk_n
      ); -- i_serialiser_10to1_selectio_clk

end architecture synthesis;

