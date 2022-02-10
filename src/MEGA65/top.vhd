library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;
use work.types_pkg.all;

library xpm;
use xpm.vcomponents.all;

entity top is
   port (
      clk         : in    std_logic;                  -- 100 MHz clock
      reset_n     : in    std_logic;                  -- CPU reset button

      -- Digital Video
      hdmi_data_p : out std_logic_vector(2 downto 0);
      hdmi_data_n : out std_logic_vector(2 downto 0);
      hdmi_clk_p  : out std_logic;
      hdmi_clk_n  : out std_logic;

      -- HyperRAM device interface
      hr_resetn   : out   std_logic;
      hr_csn      : out   std_logic;
      hr_ck       : out   std_logic;
      hr_rwds     : inout std_logic;
      hr_dq       : inout std_logic_vector(7 downto 0);

      -- Interface for physical keyboard
      kb_io0      : out   std_logic;
      kb_io1      : out   std_logic;
      kb_io2      : in    std_logic
   );
end entity top;

architecture synthesis of top is

   constant C_HYPERRAM_FREQ_MHZ : integer := 100;
   constant C_HYPERRAM_PHASE    : real := 162.000;

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_t := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string := "font8x8.txt";

   ---------------------------------------------------------------------------------------------
   -- video_clk
   ---------------------------------------------------------------------------------------------

   signal hdmi_data   : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels
   signal video_vs    : std_logic;
   signal video_hs    : std_logic;
   signal video_de    : std_logic;
   signal video_red   : std_logic_vector(7 downto 0);
   signal video_green : std_logic_vector(7 downto 0);
   signal video_blue  : std_logic_vector(7 downto 0);

   -- HyperRAM clocks
   signal clk_x1      : std_logic; -- HyperRAM clock
   signal clk_x2      : std_logic; -- Double speed clock
   signal clk_x2_del  : std_logic; -- Double speed clock, phase shifted

   -- MEGA65 clocks
   signal kbd_clk     : std_logic; -- Keyboard clock
   signal video_clk   : std_logic;
   signal hdmi_clk    : std_logic;

   -- resets
   signal rst         : std_logic;
   signal video_rst   : std_logic;

   signal return_out  : std_logic;
   signal start       : std_logic;

   signal sys_active  : std_logic;
   signal sys_error   : std_logic;

   signal led_active  : std_logic;
   signal led_error   : std_logic;

   signal address     : std_logic_vector(21 downto 0);
   signal data_exp    : std_logic_vector(15 downto 0);
   signal data_read   : std_logic_vector(15 downto 0);

   signal freq_str    : std_logic_vector(11 downto 0);
   signal phase_str   : std_logic_vector(11 downto 0);
   signal digits      : std_logic_vector(95 downto 0);

   signal hr_rwds_out : std_logic;
   signal hr_dq_out   : std_logic_vector(7 downto 0);
   signal hr_rwds_oe  : std_logic;
   signal hr_dq_oe    : std_logic;

begin

   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
   hr_dq   <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');


   i_clk_mega65 : entity work.clk_mega65
      port map
      (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         kbd_clk_o    => kbd_clk,
         pixel_clk_o  => video_clk,
         pixel_rst_o  => video_rst,
         pixel_clk5_o => hdmi_clk
      ); -- i_clk_mega65

   i_clk : entity work.clk
      generic map
      (
         G_HYPERRAM_FREQ_MHZ => C_HYPERRAM_FREQ_MHZ,
         G_HYPERRAM_PHASE    => C_HYPERRAM_PHASE
      )
      port map
      (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         clk_x1_o     => clk_x1,
         clk_x2_o     => clk_x2,
         clk_x2_del_o => clk_x2_del,
         rst_o        => rst
      ); -- i_clk

   i_system : entity work.system
      generic map (
         G_ADDRESS_SIZE => 22       -- 4M entries of 16 bits each.
      )
      port map (
         clk_i         => clk_x1,
         clk_x2_i      => clk_x2,
         clk_x2_del_i  => clk_x2_del,
         rst_i         => rst,
         start_i       => start,
         hr_resetn_o   => hr_resetn,
         hr_csn_o      => hr_csn,
         hr_ck_o       => hr_ck,
         hr_rwds_in_i  => hr_rwds,
         hr_dq_in_i    => hr_dq,
         hr_rwds_out_o => hr_rwds_out,
         hr_dq_out_o   => hr_dq_out,
         hr_rwds_oe_o  => hr_rwds_oe,
         hr_dq_oe_o    => hr_dq_oe,
         address_o     => address,
         data_exp_o    => data_exp,
         data_read_o   => data_read,
         active_o      => sys_active,
         error_o       => sys_error
      ); -- i_system

   i_cdc_video: xpm_cdc_array_single
      generic map (
         WIDTH => 96
      )
      port map (
         src_clk                => clk_x1,
         src_in( 15 downto   0) => data_read,
         src_in( 31 downto  16) => data_exp,
         src_in( 47 downto  32) => address(15 downto 0),
         src_in( 63 downto  48) => X"00" & "00" & address(21 downto 16),
         src_in( 79 downto  64) => "0000" & freq_str,
         src_in( 95 downto  80) => "0000" & phase_str,
         dest_clk               => video_clk,
         dest_out               => digits
      ); -- i_cdc

   freq_str(11 downto 8) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/100) mod 10, 4));
   freq_str( 7 downto 4) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/10)  mod 10, 4));
   freq_str( 3 downto 0) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/1)   mod 10, 4));

   phase_str(11 downto 8) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/100) mod 10, 4));
   phase_str( 7 downto 4) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/10)  mod 10, 4));
   phase_str( 3 downto 0) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/1)   mod 10, 4));

   i_cdc_keyboard: xpm_cdc_array_single
      generic map (
         WIDTH => 2
      )
      port map (
         src_clk      => clk_x1,
         src_in(0)    => sys_active,
         src_in(1)    => sys_error,
         dest_clk     => kbd_clk,
         dest_out(0)  => led_active,
         dest_out(1)  => led_error
      ); -- i_cdc_keyboard

   i_video : entity work.video
      generic map
      (
         G_FONT_FILE   => C_FONT_FILE,
         G_DIGITS_SIZE => 96,
         G_VIDEO_MODE  => C_VIDEO_MODE
      )
      port map
      (
         rst_i         => video_rst,
         clk_i         => video_clk,
         digits_i      => digits,
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
      tmds         => hdmi_data
   ); -- i_audio_video_to_hdmi


   -- serialiser: in this design we use HDMI SelectIO outputs
   gen_hdmi_data: for i in 0 to 2 generate
   begin
      i_serialiser_10to1_selectio_data: entity work.serialiser_10to1_selectio
      port map (
         rst_i    => video_rst,
         clk_i    => video_clk,
         clk_x5_i => hdmi_clk,
         d_i      => hdmi_data(i),
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


   i_mega65kbd_to_matrix : entity work.mega65kbd_to_matrix
      port map (
         cpuclock       => kbd_clk,
         flopled        => led_error,
         powerled       => led_active,
         kio8           => kb_io0,
         kio9           => kb_io1,
         kio10          => kb_io2,
         delete_out     => open,
         return_out     => return_out, -- Active low
         fastkey_out    => open
      ); -- i_mega65kbd_to_matrix

   i_cdc_start: xpm_cdc_array_single
      generic map (
         WIDTH => 1
      )
      port map (
         src_clk     => kbd_clk,
         src_in(0)   => not return_out,
         dest_clk    => clk_x1,
         dest_out(0) => start
      ); -- i_cdc_start

end architecture synthesis;

