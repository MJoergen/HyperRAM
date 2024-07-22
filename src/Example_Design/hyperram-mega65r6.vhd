-- This is the top-level file for the MEGA65 platform (revision 6).
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity hyperram_mega65r6 is
   generic (
      G_FONT_PATH : string := ""
   );
   port (
      sys_clk_i      : in    std_logic; -- 100 MHz clock
      sys_rst_i      : in    std_logic; -- CPU reset button (active high)

      -- HyperRAM device interface
      hr_resetn_o    : out   std_logic;
      hr_csn_o       : out   std_logic;
      hr_ck_o        : out   std_logic;
      hr_rwds_io     : inout std_logic;
      hr_dq_io       : inout std_logic_vector(7 downto 0);

      -- MEGA65 keyboard
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic;

      -- UART
      uart_rx_i      : in    std_logic;
      uart_tx_o      : out   std_logic;

      -- VGA
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_psave_n_o : out   std_logic;
      vdac_sync_n_o  : out   std_logic;

      -- MEGA65 Digital Video (HDMI)
      hdmi_data_p_o  : out   std_logic_vector(2 downto 0);
      hdmi_data_n_o  : out   std_logic_vector(2 downto 0);
      hdmi_clk_p_o   : out   std_logic;
      hdmi_clk_n_o   : out   std_logic
   );
end entity hyperram_mega65r6;

architecture synthesis of hyperram_mega65r6 is

   constant C_SYS_ADDRESS_SIZE : integer := 17;
   constant C_ADDRESS_SIZE     : integer := 20;
   constant C_DATA_SIZE        : integer := 64;

   -- HyperRAM clocks and reset
   signal   ctrl_clk     : std_logic; -- HyperRAM clock
   signal   ctrl_rst     : std_logic;
   signal   ctrl_clk_del : std_logic; -- HyperRAM clock, phase shifted 90 degrees
   signal   delay_refclk : std_logic; -- 200 MHz, for IDELAYCTRL

   -- Interface to MEGA65 keyboard and UART
   signal   ctrl_key_valid     : std_logic;
   signal   ctrl_key_ready     : std_logic;
   signal   ctrl_key_data      : std_logic_vector(7 downto 0);
   signal   ctrl_uart_rx_valid : std_logic;
   signal   ctrl_uart_rx_ready : std_logic;
   signal   ctrl_uart_rx_data  : std_logic_vector(7 downto 0);
   signal   ctrl_uart_tx_valid : std_logic;
   signal   ctrl_uart_tx_ready : std_logic;
   signal   ctrl_uart_tx_data  : std_logic_vector(7 downto 0);

   -- Interface to MEGA65 video
   signal   video_clk    : std_logic;
   signal   video_rst    : std_logic;
   signal   video_pos_x  : std_logic_vector(7 downto 0);
   signal   video_pos_y  : std_logic_vector(7 downto 0);
   signal   video_char   : std_logic_vector(7 downto 0);
   signal   video_colors : std_logic_vector(15 downto 0);

   -- Control and Status for trafic generator
   signal   ctrl_start         : std_logic;
   signal   ctrl_active        : std_logic;
   signal   ctrl_stat_total    : std_logic_vector(31 downto 0);
   signal   ctrl_stat_error    : std_logic_vector(31 downto 0);
   signal   ctrl_stat_err_addr : std_logic_vector(31 downto 0);
   signal   ctrl_stat_err_exp  : std_logic_vector(63 downto 0);
   signal   ctrl_stat_err_read : std_logic_vector(63 downto 0);

   -- HyperRAM tri-state control signals
   signal   hr_rwds_in   : std_logic;
   signal   hr_dq_in     : std_logic_vector(7 downto 0);
   signal   hr_rwds_out  : std_logic;
   signal   hr_dq_out    : std_logic_vector(7 downto 0);
   signal   hr_rwds_oe_n : std_logic;
   signal   hr_dq_oe_n   : std_logic_vector(7 downto 0);

begin

   ----------------------------------------------------------
   -- Instantiate MEGA65 platform interface
   ----------------------------------------------------------

   mega65_wrapper_inst : entity work.mega65_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH
      )
      port map (
         -- MEGA65 I/O ports
         sys_clk_i            => sys_clk_i,
         sys_rst_i            => sys_rst_i,
         uart_rx_i            => uart_rx_i,
         uart_tx_o            => uart_tx_o,
         kb_io0_o             => kb_io0_o,
         kb_io1_o             => kb_io1_o,
         kb_io2_i             => kb_io2_i,
         vga_red_o            => vga_red_o,
         vga_green_o          => vga_green_o,
         vga_blue_o           => vga_blue_o,
         vga_hs_o             => vga_hs_o,
         vga_vs_o             => vga_vs_o,
         vdac_clk_o           => vdac_clk_o,
         vdac_blank_n_o       => vdac_blank_n_o,
         vdac_psave_n_o       => vdac_psave_n_o,
         vdac_sync_n_o        => vdac_sync_n_o,
         hdmi_data_p_o        => hdmi_data_p_o,
         hdmi_data_n_o        => hdmi_data_n_o,
         hdmi_clk_p_o         => hdmi_clk_p_o,
         hdmi_clk_n_o         => hdmi_clk_n_o,
         -- Connection to core
         ctrl_clk_o           => ctrl_clk,
         ctrl_rst_o           => ctrl_rst,
         ctrl_key_valid_o     => ctrl_key_valid,
         ctrl_key_ready_i     => ctrl_key_ready,
         ctrl_key_data_o      => ctrl_key_data,
         ctrl_led_active_i    => ctrl_active,
         ctrl_led_error_i     => or(ctrl_stat_error),
         ctrl_uart_rx_valid_o => ctrl_uart_rx_valid,
         ctrl_uart_rx_ready_i => ctrl_uart_rx_ready,
         ctrl_uart_rx_data_o  => ctrl_uart_rx_data,
         ctrl_uart_tx_valid_i => ctrl_uart_tx_valid,
         ctrl_uart_tx_ready_o => ctrl_uart_tx_ready,
         ctrl_uart_tx_data_i  => ctrl_uart_tx_data,
         video_clk_o          => video_clk,
         video_rst_o          => video_rst,
         video_pos_x_o        => video_pos_x,
         video_pos_y_o        => video_pos_y,
         video_char_i         => video_char,
         video_colors_i       => video_colors
      ); -- mega65_wrapper_inst


   --------------------------------------------------------
   -- Generate clocks for HyperRAM controller
   --------------------------------------------------------

   clk_controller_inst : entity work.clk_controller
      port map (
         sys_clk_i      => ctrl_clk,
         sys_rst_i      => ctrl_rst,
         clk_o          => open,
         rst_o          => open,
         clk_del_o      => ctrl_clk_del,
         delay_refclk_o => delay_refclk
      ); -- clk_controller_inst


   ----------------------------------------------------------
   -- Controller
   ----------------------------------------------------------

   controller_wrapper_inst : entity work.controller_wrapper
      port map (
         ctrl_clk_i           => ctrl_clk,
         ctrl_rst_i           => ctrl_rst,
         ctrl_key_valid_i     => ctrl_key_valid,
         ctrl_key_ready_o     => ctrl_key_ready,
         ctrl_key_data_i      => ctrl_key_data,
         ctrl_uart_rx_valid_i => ctrl_uart_rx_valid,
         ctrl_uart_rx_ready_o => ctrl_uart_rx_ready,
         ctrl_uart_rx_data_i  => ctrl_uart_rx_data,
         ctrl_uart_tx_valid_o => ctrl_uart_tx_valid,
         ctrl_uart_tx_ready_i => ctrl_uart_tx_ready,
         ctrl_uart_tx_data_o  => ctrl_uart_tx_data,
         ctrl_start_o         => ctrl_start,
         ctrl_active_i        => ctrl_active,
         ctrl_stat_total_i    => ctrl_stat_total,
         ctrl_stat_error_i    => ctrl_stat_error,
         ctrl_stat_err_addr_i => ctrl_stat_err_addr,
         ctrl_stat_err_exp_i  => ctrl_stat_err_exp,
         ctrl_stat_err_read_i => ctrl_stat_err_read,
         video_clk_i          => video_clk,
         video_rst_i          => video_rst,
         video_pos_x_i        => video_pos_x,
         video_pos_y_i        => video_pos_y,
         video_char_o         => video_char,
         video_colors_o       => video_colors
      ); -- controller_wrapper_inst


   --------------------------------------------------------
   -- Instantiate core test generator
   --------------------------------------------------------

   core_wrapper_inst : entity work.core_wrapper
      generic map (
         G_SYS_ADDRESS_SIZE => C_SYS_ADDRESS_SIZE,
         G_ADDRESS_SIZE     => C_ADDRESS_SIZE,
         G_DATA_SIZE        => C_DATA_SIZE
      )
      port map (
         clk_i           => ctrl_clk,
         clk_del_i       => ctrl_clk_del,
         delay_refclk_i  => delay_refclk,
         rst_i           => ctrl_rst,
         start_i         => ctrl_start,
         active_o        => ctrl_active,
         stat_total_o    => ctrl_stat_total,
         stat_error_o    => ctrl_stat_error,
         stat_err_addr_o => ctrl_stat_err_addr,
         stat_err_exp_o  => ctrl_stat_err_exp,
         stat_err_read_o => ctrl_stat_err_read,
         hr_resetn_o     => hr_resetn_o,
         hr_csn_o        => hr_csn_o,
         hr_ck_o         => hr_ck_o,
         hr_rwds_in_i    => hr_rwds_in,
         hr_rwds_out_o   => hr_rwds_out,
         hr_rwds_oe_n_o  => hr_rwds_oe_n,
         hr_dq_in_i      => hr_dq_in,
         hr_dq_out_o     => hr_dq_out,
         hr_dq_oe_n_o    => hr_dq_oe_n
      ); -- core_wrapper_inst


   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds_io <= hr_rwds_out when hr_rwds_oe_n = '0' else
                 'Z';

   hr_dq_gen : for i in 0 to 7 generate
      hr_dq_io(i) <= hr_dq_out(i) when hr_dq_oe_n(i) = '0' else
                     'Z';
   end generate hr_dq_gen;

   hr_rwds_in <= hr_rwds_io;
   hr_dq_in   <= hr_dq_io;

end architecture synthesis;

