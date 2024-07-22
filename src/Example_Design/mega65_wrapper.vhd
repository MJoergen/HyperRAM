-- This is a wrapper for all the MEGA65 related files (keyboard and video).
-- Its purpose is to simplify the top-level MEGA65 file by wrapping away
-- anything that is not directly related to the HyperRAM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

library xpm;
   use xpm.vcomponents.all;

entity mega65_wrapper is
   generic (
      G_DIGITS_SIZE : natural;
      G_FONT_PATH   : string
   );
   port (
      -- MEGA65 I/O ports
      sys_clk_i      : in    std_logic; -- 100 MHz clock
      sys_rst_i      : in    std_logic; -- CPU reset button
      uart_rx_i      : in    std_logic;
      uart_tx_o      : out   std_logic;
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic;
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_psave_n_o : out   std_logic;
      vdac_sync_n_o  : out   std_logic;
      hdmi_data_p_o  : out   std_logic_vector(2 downto 0);
      hdmi_data_n_o  : out   std_logic_vector(2 downto 0);
      hdmi_clk_p_o   : out   std_logic;
      hdmi_clk_n_o   : out   std_logic;
      -- Connection to design
      ctrl_clk_o     : out   std_logic;
      ctrl_rst_o     : out   std_logic;
      ctrl_start_o   : out   std_logic;
      ctrl_active_i  : in    std_logic;
      ctrl_error_i   : in    std_logic;
      ctrl_digits_i  : in    std_logic_vector(G_DIGITS_SIZE - 1 downto 0)
   );
end entity mega65_wrapper;

architecture synthesis of mega65_wrapper is

   constant C_CTRL_HZ : natural             := 100_000_000;
   constant C_UART_HZ : natural             := 115_200;

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string           := "font8x8.txt";

   -- MEGA65 clocks
   signal   video_clk : std_logic;
   signal   hdmi_clk  : std_logic;

   -- resets
   signal   ctrl_rst_d : std_logic;
   signal   video_rst  : std_logic;

   signal   ctrl_active_d   : std_logic;
   signal   ctrl_digits_hex : std_logic_vector(2 * G_DIGITS_SIZE - 1 downto 0);
   signal   ctrl_result_hex : std_logic_vector(9 * G_DIGITS_SIZE / 2 - 1 downto 0);

   signal   ctrl_start       : std_logic;
   signal   ctrl_start_valid : std_logic;
   signal   ctrl_start_ready : std_logic;
   signal   ctrl_start_data  : std_logic_vector(7 downto 0);

   signal   ctrl_result_valid : std_logic;
   signal   ctrl_result_ready : std_logic;
   signal   ctrl_result_data  : std_logic_vector(7 downto 0);

   signal   ctrl_uart_tx_valid : std_logic;
   signal   ctrl_uart_tx_ready : std_logic;
   signal   ctrl_uart_tx_data  : std_logic_vector(7 downto 0);
   signal   ctrl_uart_rx_valid : std_logic;
   signal   ctrl_uart_rx_ready : std_logic;
   signal   ctrl_uart_rx_data  : std_logic_vector(7 downto 0);

   signal   ctrl_key_valid : std_logic;
   signal   ctrl_key_ready : std_logic;
   signal   ctrl_key_data  : std_logic_vector(7 downto 0);

   signal   ctrl_uart_start : std_logic;
   signal   ctrl_kbd_start  : std_logic;

   signal   video_vs     : std_logic;
   signal   video_hs     : std_logic;
   signal   video_de     : std_logic;
   signal   video_red    : std_logic_vector(7 downto 0);
   signal   video_green  : std_logic_vector(7 downto 0);
   signal   video_blue   : std_logic_vector(7 downto 0);
   signal   video_digits : std_logic_vector(G_DIGITS_SIZE - 1 downto 0);

   signal   video_stat_total    : std_logic_vector(31 downto 0);
   signal   video_stat_error    : std_logic_vector(31 downto 0);
   signal   video_stat_err_addr : std_logic_vector(31 downto 0);
   signal   video_stat_err_exp  : std_logic_vector(63 downto 0);
   signal   video_stat_err_read : std_logic_vector(63 downto 0);

   signal   video_pos_x  : std_logic_vector(7 downto 0);
   signal   video_pos_y  : std_logic_vector(7 downto 0);
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

   --------------------------------------------------------------------------
   -- Generate clocks and reset
   --------------------------------------------------------------------------

   clk_inst : entity work.clk
      port map (
         sys_clk_i   => sys_clk_i,
         sys_rst_i   => sys_rst_i,
         ctrl_clk_o  => ctrl_clk_o,
         ctrl_rst_o  => ctrl_rst_o,
         video_clk_o => video_clk,
         video_rst_o => video_rst,
         hdmi_clk_o  => hdmi_clk
      ); -- clk_inst


   --------------------------------------------------------------------------
   -- Keyboard
   --------------------------------------------------------------------------

   ctrl_key_ready <= '1';

   keyboard_wrapper_inst : entity work.keyboard_wrapper
      generic map (
         G_CTRL_HZ => C_CTRL_HZ
      )
      port map (
         ctrl_clk_i        => ctrl_clk_o,
         ctrl_rst_i        => ctrl_rst_o,
         ctrl_key_valid_o  => ctrl_key_valid,
         ctrl_key_ready_i  => ctrl_key_ready,
         ctrl_key_data_o   => ctrl_key_data,
         ctrl_led_active_i => ctrl_active_i,
         ctrl_led_error_i  => ctrl_error_i,
         kb_io0_o          => kb_io0_o,
         kb_io1_o          => kb_io1_o,
         kb_io2_i          => kb_io2_i
      ); -- keyboard_wrapper_inst

   ctrl_kbd_start <= ctrl_key_valid when ctrl_key_data = X"0D" else
                     '0';


   --------------------------------------------------------------------------
   -- UART
   --------------------------------------------------------------------------

   hexifier_inst : entity work.hexifier
      generic map (
         G_DATA_NIBBLES => G_DIGITS_SIZE / 4
      )
      port map (
         s_data_i => ctrl_digits_i,
         m_data_o => ctrl_digits_hex
      ); -- hexifier_inst

   ctrl_result_hex <= str2slv("ERRORS: ") & ctrl_digits_hex(383 downto 320) & X"0D0A" &
                      str2slv("FAST:   ") & ctrl_digits_hex(319 downto 256) & X"0D0A" &
                      str2slv("SLOW:   ") & ctrl_digits_hex(255 downto 192) & X"0D0A" &
                      str2slv("EXPECT: ") & ctrl_digits_hex(191 downto 128) & X"0D0A" &
                      str2slv("ADDR:   ") & ctrl_digits_hex(127 downto  64) & X"0D0A" &
                      str2slv("READ:   ") & ctrl_digits_hex( 63 downto   0) & X"0D0A";

   ctrl_proc : process (ctrl_clk_o)
   begin
      if rising_edge(ctrl_clk_o) then
         ctrl_rst_d    <= ctrl_rst_o;
         ctrl_active_d <= ctrl_active_i;

         ctrl_start    <= ctrl_rst_d and not ctrl_rst_o;

         if ctrl_rst_o = '1' then
            ctrl_start <= '0';
         end if;
      end if;
   end process ctrl_proc;

   serializer_start_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 232,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => ctrl_clk_o,
         rst_i     => ctrl_rst_o,
         s_valid_i => ctrl_start,
         s_ready_o => open,
         s_data_i  => X"0D0A" & str2slv("HyperRAM Example Design") & X"0D0A" & X"0D0A",
         m_valid_o => ctrl_start_valid,
         m_ready_i => ctrl_start_ready,
         m_data_o  => ctrl_start_data
      ); -- serializer_start_inst

   serializer_result_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 9 * G_DIGITS_SIZE / 2 + 16,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => ctrl_clk_o,
         rst_i     => ctrl_rst_o,
         s_valid_i => ctrl_active_d and not ctrl_active_i, -- falling edge
         s_ready_o => open,
         s_data_i  => ctrl_result_hex & X"0D0A",
         m_valid_o => ctrl_result_valid,
         m_ready_i => ctrl_result_ready,
         m_data_o  => ctrl_result_data
      ); -- serializer_result_inst

   merginator_inst : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => ctrl_clk_o,
         rst_i      => ctrl_rst_o,
         s1_valid_i => ctrl_start_valid,
         s1_ready_o => ctrl_start_ready,
         s1_data_i  => ctrl_start_data,
         s2_valid_i => ctrl_result_valid,
         s2_ready_o => ctrl_result_ready,
         s2_data_i  => ctrl_result_data,
         m_valid_o  => ctrl_uart_tx_valid,
         m_ready_i  => ctrl_uart_tx_ready,
         m_data_o   => ctrl_uart_tx_data
      ); -- merginator_inst

   ctrl_uart_rx_ready <= '1';

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => C_CTRL_HZ / C_UART_HZ
      )
      port map (
         clk_i      => ctrl_clk_o,
         rst_i      => ctrl_rst_o,
         tx_valid_i => ctrl_uart_tx_valid,
         tx_ready_o => ctrl_uart_tx_ready,
         tx_data_i  => ctrl_uart_tx_data,
         rx_valid_o => ctrl_uart_rx_valid,
         rx_ready_i => ctrl_uart_rx_ready,
         rx_data_o  => ctrl_uart_rx_data,
         uart_tx_o  => uart_tx_o,
         uart_rx_i  => uart_rx_i
      ); -- uart_inst

   ctrl_uart_start <= ctrl_uart_rx_valid when ctrl_uart_rx_data = X"0D" else
                      '0';

   ctrl_start_o    <= ctrl_uart_start or ctrl_kbd_start;


   --------------------------------------------------------------------------
   -- Video
   --------------------------------------------------------------------------

   cdc_video_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => G_DIGITS_SIZE
      )
      port map (
         src_clk  => ctrl_clk_o,
         src_in   => ctrl_digits_i,
         dest_clk => video_clk,
         dest_out => video_digits
      ); -- cdc_video_inst

   video_stat_total    <= video_digits(127 downto  96) +
                          video_digits(159 downto 128);
   video_stat_error    <= video_digits(191 downto 160);
   video_stat_err_addr <= video_digits( 63 downto  32);
   video_stat_err_exp  <= X"00000000" & video_digits( 95 downto  64);
   video_stat_err_read <= X"00000000" & video_digits( 31 downto   0);

   video_result_data   <= str2slv("TOTAL:  ") & hexify(video_stat_total) & X"0D0A" &
                          str2slv("ERRORS: ") & hexify(video_stat_error) & X"0D0A" &
                          str2slv("ADDR:   ") & hexify(video_stat_err_addr) & X"0D0A" &
                          str2slv("EXP_HI: ") & hexify(video_stat_err_exp(63 downto 32)) & X"0D0A" &
                          str2slv("EXP_LO: ") & hexify(video_stat_err_exp(31 downto 0)) & X"0D0A" &
                          str2slv("READ_HI:") & hexify(video_stat_err_read(63 downto 32)) & X"0D0A" &
                          str2slv("READ_LO:") & hexify(video_stat_err_read(31 downto 0)) & X"0D0A" &
                          X"0D0A";

   video_proc : process (video_clk)
      variable col_v   : natural range 0 to 15;
      variable row_v   : natural range 0 to 6;
      variable index_v : natural range 0 to video_result_data'length / 8 - 1;
   begin
      if rising_edge(video_clk) then
         video_char   <= X"20";
         video_colors <= X"55BB";
         if video_pos_x >= C_POS_X and video_pos_x < C_POS_X + 16 and
            video_pos_y >= C_POS_Y and video_pos_y < C_POS_Y + 7 then
            col_v      := 15 - to_integer(video_pos_x - C_POS_X);
            row_v      := 6 - to_integer(video_pos_y - C_POS_Y);
            index_v    := row_v * 18 + col_v + 4;
            video_char <= video_result_data(index_v * 8 + 7 downto index_v * 8);
         end if;
      end if;
   end process video_proc;

   video_wrapper_inst : entity work.video_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH
      )
      port map (
         video_clk_i    => video_clk,
         video_rst_i    => video_rst,
         video_pos_x_o  => video_pos_x,
         video_pos_y_o  => video_pos_y,
         video_char_i   => video_char,
         video_colors_i => video_colors,
         hdmi_clk_i     => hdmi_clk,
         vga_red_o      => video_red,
         vga_green_o    => video_green,
         vga_blue_o     => video_blue,
         vga_hs_o       => video_hs,
         vga_vs_o       => video_vs,
         vga_de_o       => video_de,
         vdac_clk_o     => vdac_clk_o,
         vdac_blank_n_o => vdac_blank_n_o,
         vdac_psave_n_o => vdac_psave_n_o,
         vdac_sync_n_o  => vdac_sync_n_o,
         hdmi_data_p_o  => hdmi_data_p_o,
         hdmi_data_n_o  => hdmi_data_n_o,
         hdmi_clk_p_o   => hdmi_clk_p_o,
         hdmi_clk_n_o   => hdmi_clk_n_o
      ); -- video_wrapper_inst

   vga_red_o   <= video_red;
   vga_green_o <= video_green;
   vga_blue_o  <= video_blue;
   vga_hs_o    <= video_hs;
   vga_vs_o    <= video_vs;

end architecture synthesis;

