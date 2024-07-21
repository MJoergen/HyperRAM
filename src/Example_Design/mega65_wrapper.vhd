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

entity mega65_wrapper is
   generic (
      G_DIGITS_SIZE : natural
   );
   port (
      -- MEGA65 I/O ports
      sys_clk_i     : in    std_logic; -- 100 MHz clock
      sys_rst_i     : in    std_logic; -- CPU reset button
      uart_rx_i     : in    std_logic;
      uart_tx_o     : out   std_logic;
      kb_io0_o      : out   std_logic;
      kb_io1_o      : out   std_logic;
      kb_io2_i      : in    std_logic;
      hdmi_data_p_o : out   std_logic_vector(2 downto 0);
      hdmi_data_n_o : out   std_logic_vector(2 downto 0);
      hdmi_clk_p_o  : out   std_logic;
      hdmi_clk_n_o  : out   std_logic;
      -- Connection to design
      sys_up_o      : out   std_logic;
      sys_left_o    : out   std_logic;
      sys_start_o   : out   std_logic;
      sys_active_i  : in    std_logic;
      sys_error_i   : in    std_logic;
      sys_digits_i  : in    std_logic_vector(G_DIGITS_SIZE - 1 downto 0)
   );
end entity mega65_wrapper;

architecture synthesis of mega65_wrapper is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := "font8x8.txt";

   -- MEGA65 clocks
   signal   video_clk : std_logic;
   signal   hdmi_clk  : std_logic;

   -- resets
   signal   sys_rst   : std_logic;
   signal   sys_rst_d : std_logic;
   signal   video_rst : std_logic;

   signal   sys_active_d   : std_logic;
   signal   sys_digits_hex : std_logic_vector(2 * G_DIGITS_SIZE - 1 downto 0);
   signal   sys_result_hex : std_logic_vector(9 * G_DIGITS_SIZE / 2 - 1 downto 0);

   signal   sys_start       : std_logic;
   signal   sys_start_valid : std_logic;
   signal   sys_start_ready : std_logic;
   signal   sys_start_data  : std_logic_vector(7 downto 0);

   signal   sys_result_valid : std_logic;
   signal   sys_result_ready : std_logic;
   signal   sys_result_data  : std_logic_vector(7 downto 0);

   signal   sys_uart_tx_valid : std_logic;
   signal   sys_uart_tx_ready : std_logic;
   signal   sys_uart_tx_data  : std_logic_vector(7 downto 0);
   signal   sys_uart_rx_valid : std_logic;
   signal   sys_uart_rx_ready : std_logic;
   signal   sys_uart_rx_data  : std_logic_vector(7 downto 0);

   signal   sys_key_valid : std_logic;
   signal   sys_key_ready : std_logic;
   signal   sys_key_data  : std_logic_vector(7 downto 0);

   signal   sys_uart_start : std_logic;
   signal   sys_kbd_start  : std_logic;

   signal   video_vs     : std_logic;
   signal   video_hs     : std_logic;
   signal   video_de     : std_logic;
   signal   video_red    : std_logic_vector(7 downto 0);
   signal   video_green  : std_logic_vector(7 downto 0);
   signal   video_blue   : std_logic_vector(7 downto 0);
   signal   video_digits : std_logic_vector(G_DIGITS_SIZE - 1 downto 0);
   signal   video_data   : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

   pure function str2slv (
      str : string
   ) return std_logic_vector is
      variable res_v : std_logic_vector(str'length * 8 - 1 downto 0);
   begin
      --
      for i in 0 to str'length-1 loop
         res_v(8 * i + 7 downto 8 * i) := std_logic_vector(to_unsigned(character'pos(str(str'length - i)), 8));
      end loop;

      return res_v;
   end function str2slv;

begin

   --------------------------------------------------------
   -- Generate clocks and reset for MEGA65 platform (keyboard and video)
   --------------------------------------------------------

   clk_inst : entity work.clk
      port map (
         sys_clk_i    => sys_clk_i,
         sys_rstn_i   => not sys_rst_i,
         pixel_clk_o  => video_clk,
         pixel_rst_o  => video_rst,
         pixel_clk5_o => hdmi_clk
      ); -- clk_inst

   xpm_cdc_sync_rst_inst : component xpm_cdc_sync_rst
      port map (
         src_rst  => sys_rst_i,
         dest_clk => sys_clk_i,
         dest_rst => sys_rst
      ); -- xpm_cdc_sync_rst_inst


   --------------------------------------------------------------------------
   -- Keyboard
   --------------------------------------------------------------------------

   sys_key_ready <= '1';
   keyboard_wrapper_inst : entity work.keyboard_wrapper
      generic map (
         G_CTRL_HZ => 100_000_000
      )
      port map (
         ctrl_clk_i        => sys_clk_i,
         ctrl_rst_i        => sys_rst_i,
         ctrl_key_valid_o  => sys_key_valid,
         ctrl_key_ready_i  => sys_key_ready,
         ctrl_key_data_o   => sys_key_data,
         ctrl_led_active_i => sys_active_i,
         ctrl_led_error_i  => sys_error_i,
         kb_io0_o          => kb_io0_o,
         kb_io1_o          => kb_io1_o,
         kb_io2_i          => kb_io2_i
      ); -- keyboard_wrapper_inst

   sys_kbd_start <= sys_key_valid when sys_key_data = X"0D" else '0';


   --------------------------------------------------------------------------
   -- video
   --------------------------------------------------------------------------

   cdc_video_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_DIGITS_SIZE
      )
      port map (
         src_clk  => sys_clk_i,
         src_in   => sys_digits_i,
         dest_clk => video_clk,
         dest_out => video_digits
      ); -- cdc_video_inst


   video_wrapper_inst : entity work.video_wrapper
      generic map (

         G_FONT_FILE   => C_FONT_FILE,
         G_DIGITS_SIZE => G_DIGITS_SIZE,
         G_VIDEO_MODE  => C_VIDEO_MODE
      )
      port map (
         rst_i         => video_rst,
         clk_i         => video_clk,
         digits_i      => video_digits,   -- From HyperRAM trafic generator
         video_vs_o    => video_vs,
         video_hs_o    => video_hs,
         video_de_o    => video_de,
         video_red_o   => video_red,
         video_green_o => video_green,
         video_blue_o  => video_blue
      ); -- video_wrapper_inst


   audio_video_to_hdmi_inst : entity work.audio_video_to_hdmi
      port map (
         select_44100 => '0',
         dvi          => '0',
         vic          => std_logic_vector(to_unsigned(4,8)), -- CEA/CTA VIC 4=720p @ 60 Hz
         aspect       => "10",                               -- 01=4:3, 10=16:9
         pix_rep      => '0',                                -- no pixel repetition
         vs_pol       => C_VIDEO_MODE.V_POL,                 -- horizontal polarity: positive
         hs_pol       => C_VIDEO_MODE.H_POL,                 -- vertaical polarity: positive

         vga_rst      => video_rst,                          -- active high reset
         vga_clk      => video_clk,                          -- video pixel clock
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
      ); -- audio_video_to_hdmi_inst


   -- serialiser: in this design we use HDMI SelectIO outputs

   hdmi_data_gen : for i in 0 to 2 generate
   begin

      serialiser_10to1_selectio_data_inst : entity work.serialiser_10to1_selectio
         port map (
            rst_i    => video_rst,
            clk_i    => video_clk,
            d_i      => video_data(i),
            clk_x5_i => hdmi_clk,
            out_p_o  => hdmi_data_p_o(i),
            out_n_o  => hdmi_data_n_o(i)
         ); -- serialiser_10to1_selectio_data_inst

   end generate hdmi_data_gen;


   serialiser_10to1_selectio_clk_inst : entity work.serialiser_10to1_selectio
      port map (
         rst_i    => video_rst,
         clk_i    => video_clk,
         clk_x5_i => hdmi_clk,
         d_i      => "0000011111",
         out_p_o  => hdmi_clk_p_o,
         out_n_o  => hdmi_clk_n_o
      ); -- serialiser_10to1_selectio_clk_inst


   --------------------------------------------------------------------------
   -- UART
   --------------------------------------------------------------------------

   hexifier_inst : entity work.hexifier
      generic map (
         G_DATA_NIBBLES => G_DIGITS_SIZE / 4
      )
      port map (
         s_data_i => sys_digits_i,
         m_data_o => sys_digits_hex
      ); -- hexifier_inst

   sys_result_hex <= str2slv("ERRORS: ") & sys_digits_hex(383 downto 320) & X"0D0A" &
                     str2slv("FAST:   ") & sys_digits_hex(319 downto 256) & X"0D0A" &
                     str2slv("SLOW:   ") & sys_digits_hex(255 downto 192) & X"0D0A" &
                     str2slv("EXPECT: ") & sys_digits_hex(191 downto 128) & X"0D0A" &
                     str2slv("ADDR:   ") & sys_digits_hex(127 downto  64) & X"0D0A" &
                     str2slv("READ:   ") & sys_digits_hex( 63 downto   0) & X"0D0A";

   sys_proc : process (sys_clk_i)
   begin
      if rising_edge(sys_clk_i) then
         sys_rst_d    <= sys_rst;
         sys_active_d <= sys_active_i;

         sys_start    <= sys_rst_d and not sys_rst;

         if sys_rst = '1' then
            sys_start <= '0';
         end if;
      end if;
   end process sys_proc;

   serializer_start_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 232,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => sys_clk_i,
         rst_i     => sys_rst,
         s_valid_i => sys_start,
         s_ready_o => open,
         s_data_i  => X"0D0A" & str2slv("HyperRAM Example Design") & X"0D0A" & X"0D0A",
         m_valid_o => sys_start_valid,
         m_ready_i => sys_start_ready,
         m_data_o  => sys_start_data
      ); -- serializer_start_inst

   serializer_result_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 9 * G_DIGITS_SIZE / 2 + 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => sys_clk_i,
         rst_i     => sys_rst,
         s_valid_i => sys_active_d and not sys_active_i, -- falling edge
         s_ready_o => open,
         s_data_i  => sys_result_hex & X"0D0A",
         m_valid_o => sys_result_valid,
         m_ready_i => sys_result_ready,
         m_data_o  => sys_result_data
      ); -- serializer_result_inst

   merginator_inst : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => sys_clk_i,
         rst_i      => sys_rst,
         s1_valid_i => sys_start_valid,
         s1_ready_o => sys_start_ready,
         s1_data_i  => sys_start_data,
         s2_valid_i => sys_result_valid,
         s2_ready_o => sys_result_ready,
         s2_data_i  => sys_result_data,
         m_valid_o  => sys_uart_tx_valid,
         m_ready_i  => sys_uart_tx_ready,
         m_data_o   => sys_uart_tx_data
      ); -- merginator_inst

   sys_uart_rx_ready <= '1';

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => 100000000 / 115200
      )
      port map (
         clk_i      => sys_clk_i,
         rst_i      => sys_rst,
         tx_valid_i => sys_uart_tx_valid,
         tx_ready_o => sys_uart_tx_ready,
         tx_data_i  => sys_uart_tx_data,
         rx_valid_o => sys_uart_rx_valid,
         rx_ready_i => sys_uart_rx_ready,
         rx_data_o  => sys_uart_rx_data,
         uart_tx_o  => uart_tx_o,
         uart_rx_i  => uart_rx_i
      ); -- uart_inst

   sys_uart_start <= sys_uart_rx_valid when sys_uart_rx_data = X"0D" else
                     '0';

   sys_start_o    <= sys_uart_start or sys_kbd_start;

end architecture synthesis;

