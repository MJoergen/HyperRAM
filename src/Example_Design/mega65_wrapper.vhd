-- This is a wrapper for all the MEGA65 related files (keyboard, video, and UART).
-- Its purpose is to simplify the top-level MEGA65 file by wrapping away
-- anything that is not directly related to the HyperRAM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity mega65_wrapper is
   generic (
      G_FONT_PATH : string
   );
   port (
      -- MEGA65 I/O ports
      sys_clk_i            : in    std_logic; -- 100 MHz clock
      sys_rst_i            : in    std_logic; -- CPU reset button
      uart_rx_i            : in    std_logic;
      uart_tx_o            : out   std_logic;
      kb_io0_o             : out   std_logic;
      kb_io1_o             : out   std_logic;
      kb_io2_i             : in    std_logic;
      vga_red_o            : out   std_logic_vector(7 downto 0);
      vga_green_o          : out   std_logic_vector(7 downto 0);
      vga_blue_o           : out   std_logic_vector(7 downto 0);
      vga_hs_o             : out   std_logic;
      vga_vs_o             : out   std_logic;
      vdac_clk_o           : out   std_logic;
      vdac_blank_n_o       : out   std_logic;
      vdac_psave_n_o       : out   std_logic;
      vdac_sync_n_o        : out   std_logic;
      hdmi_data_p_o        : out   std_logic_vector(2 downto 0);
      hdmi_data_n_o        : out   std_logic_vector(2 downto 0);
      hdmi_clk_p_o         : out   std_logic;
      hdmi_clk_n_o         : out   std_logic;
      -- Connection to design
      ctrl_clk_o           : out   std_logic;
      ctrl_rst_o           : out   std_logic;
      ctrl_key_valid_o     : out   std_logic;
      ctrl_key_ready_i     : in    std_logic;
      ctrl_key_data_o      : out   std_logic_vector(7 downto 0);
      ctrl_led_active_i    : in    std_logic;
      ctrl_led_error_i     : in    std_logic;
      ctrl_uart_rx_valid_o : out   std_logic;
      ctrl_uart_rx_ready_i : in    std_logic;
      ctrl_uart_rx_data_o  : out   std_logic_vector(7 downto 0);
      ctrl_uart_tx_valid_i : in    std_logic;
      ctrl_uart_tx_ready_o : out   std_logic;
      ctrl_uart_tx_data_i  : in    std_logic_vector(7 downto 0);
      video_clk_o          : out   std_logic;
      video_rst_o          : out   std_logic;
      video_pos_x_o        : out   std_logic_vector(7 downto 0);
      video_pos_y_o        : out   std_logic_vector(7 downto 0);
      video_char_i         : in    std_logic_vector(7 downto 0);
      video_colors_i       : in    std_logic_vector(15 downto 0)
   );
end entity mega65_wrapper;

architecture synthesis of mega65_wrapper is

   constant C_CTRL_HZ : natural := 100_000_000;
   constant C_UART_HZ : natural := 115_200;

   signal hdmi_clk : std_logic;

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
         video_clk_o => video_clk_o,
         video_rst_o => video_rst_o,
         hdmi_clk_o  => hdmi_clk
      ); -- clk_inst


   --------------------------------------------------------------------------
   -- Keyboard
   --------------------------------------------------------------------------

   keyboard_wrapper_inst : entity work.keyboard_wrapper
      generic map (
         G_CTRL_HZ => C_CTRL_HZ
      )
      port map (
         ctrl_clk_i        => ctrl_clk_o,
         ctrl_rst_i        => ctrl_rst_o,
         ctrl_key_valid_o  => ctrl_key_valid_o,
         ctrl_key_ready_i  => ctrl_key_ready_i,
         ctrl_key_data_o   => ctrl_key_data_o,
         ctrl_led_active_i => ctrl_led_active_i,
         ctrl_led_error_i  => ctrl_led_error_i,
         kb_io0_o          => kb_io0_o,
         kb_io1_o          => kb_io1_o,
         kb_io2_i          => kb_io2_i
      ); -- keyboard_wrapper_inst


   --------------------------------------------------------------------------
   -- UART
   --------------------------------------------------------------------------

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => C_CTRL_HZ / C_UART_HZ
      )
      port map (
         clk_i      => ctrl_clk_o,
         rst_i      => ctrl_rst_o,
         tx_valid_i => ctrl_uart_tx_valid_i,
         tx_ready_o => ctrl_uart_tx_ready_o,
         tx_data_i  => ctrl_uart_tx_data_i,
         rx_valid_o => ctrl_uart_rx_valid_o,
         rx_ready_i => ctrl_uart_rx_ready_i,
         rx_data_o  => ctrl_uart_rx_data_o,
         uart_tx_o  => uart_tx_o,
         uart_rx_i  => uart_rx_i
      ); -- uart_inst


   --------------------------------------------------------------------------
   -- Video
   --------------------------------------------------------------------------

   video_wrapper_inst : entity work.video_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH
      )
      port map (
         video_clk_i    => video_clk_o,
         video_rst_i    => video_rst_o,
         video_pos_x_o  => video_pos_x_o,
         video_pos_y_o  => video_pos_y_o,
         video_char_i   => video_char_i,
         video_colors_i => video_colors_i,
         hdmi_clk_i     => hdmi_clk,
         vga_red_o      => vga_red_o,
         vga_green_o    => vga_green_o,
         vga_blue_o     => vga_blue_o,
         vga_hs_o       => vga_hs_o,
         vga_vs_o       => vga_vs_o,
         vdac_clk_o     => vdac_clk_o,
         vdac_blank_n_o => vdac_blank_n_o,
         vdac_psave_n_o => vdac_psave_n_o,
         vdac_sync_n_o  => vdac_sync_n_o,
         hdmi_data_p_o  => hdmi_data_p_o,
         hdmi_data_n_o  => hdmi_data_n_o,
         hdmi_clk_p_o   => hdmi_clk_p_o,
         hdmi_clk_n_o   => hdmi_clk_n_o
      ); -- video_wrapper_inst

end architecture synthesis;

