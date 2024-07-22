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

   -- Control and Status for trafic generator
   signal   ctrl_start       : std_logic;
   signal   ctrl_valid       : std_logic;
   signal   ctrl_active      : std_logic;
   signal   ctrl_error       : std_logic;
   signal   ctrl_address     : std_logic_vector(31 downto 0);
   signal   ctrl_data_exp    : std_logic_vector(63 downto 0);
   signal   ctrl_data_read   : std_logic_vector(63 downto 0);
   signal   ctrl_count_long  : unsigned(31 downto 0);
   signal   ctrl_count_short : unsigned(31 downto 0);
   signal   ctrl_count_error : std_logic_vector(31 downto 0);

   -- Interface to MEGA65 video
   signal   ctrl_digits : std_logic_vector(191 downto 0);

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
         G_DIGITS_SIZE => ctrl_digits'length,
         G_FONT_PATH   => G_FONT_PATH
      )
      port map (
         -- MEGA65 I/O ports
         sys_clk_i      => sys_clk_i,
         sys_rst_i      => sys_rst_i,
         uart_rx_i      => uart_rx_i,
         uart_tx_o      => uart_tx_o,
         kb_io0_o       => kb_io0_o,
         kb_io1_o       => kb_io1_o,
         kb_io2_i       => kb_io2_i,
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
         hdmi_clk_n_o   => hdmi_clk_n_o,
         -- Connection to core
         ctrl_clk_o     => ctrl_clk,
         ctrl_rst_o     => ctrl_rst,
         ctrl_start_o   => ctrl_start,
         ctrl_active_i  => ctrl_active,
         ctrl_error_i   => ctrl_error,
         ctrl_digits_i  => ctrl_digits
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
         clk_i          => ctrl_clk,
         clk_del_i      => ctrl_clk_del,
         delay_refclk_i => delay_refclk,
         rst_i          => ctrl_rst,
         start_i        => ctrl_start,
         active_o       => ctrl_active,
         address_o      => ctrl_address,
         data_exp_o     => ctrl_data_exp,
         data_read_o    => ctrl_data_read,
         count_long_o   => ctrl_count_long,
         count_short_o  => ctrl_count_short,
         count_error_o  => ctrl_count_error,
         hr_resetn_o    => hr_resetn_o,
         hr_csn_o       => hr_csn_o,
         hr_ck_o        => hr_ck_o,
         hr_rwds_in_i   => hr_rwds_in,
         hr_rwds_out_o  => hr_rwds_out,
         hr_rwds_oe_n_o => hr_rwds_oe_n,
         hr_dq_in_i     => hr_dq_in,
         hr_dq_out_o    => hr_dq_out,
         hr_dq_oe_n_o   => hr_dq_oe_n
      ); -- core_wrapper_inst


   ----------------------------------
   -- Generate debug output for video
   ----------------------------------

   ctrl_digits( 31 downto   0) <= ctrl_data_read(31 downto 0);
   ctrl_digits( 47 downto  32) <= ctrl_address(15 downto 0);
   ctrl_digits( 63 downto  48) <= X"00" & "000" & ctrl_address(20 downto 16);
   ctrl_digits( 95 downto  64) <= ctrl_data_exp(31 downto 0);
   ctrl_digits(127 downto  96) <= std_logic_vector(ctrl_count_long);
   ctrl_digits(159 downto 128) <= std_logic_vector(ctrl_count_short);
   ctrl_digits(191 downto 160) <= ctrl_count_error;

   ctrl_error                  <= or(ctrl_count_error);


   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds_io                  <= hr_rwds_out when hr_rwds_oe_n = '0' else
                                  'Z';

   hr_dq_gen : for i in 0 to 7 generate
      hr_dq_io(i) <= hr_dq_out(i) when hr_dq_oe_n(i) = '0' else
                     'Z';
   end generate hr_dq_gen;

   hr_rwds_in <= hr_rwds_io;
   hr_dq_in   <= hr_dq_io;

end architecture synthesis;

