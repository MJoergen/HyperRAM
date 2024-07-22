-- Main testbench for the HyperRAM controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_top is
end entity tb_top;

architecture simulation of tb_top is

   constant C_DELAY : time := 1 ns;

   signal sys_clk : std_logic := '1';
   signal sys_rst : std_logic := '1';

   signal sys_resetn   : std_logic;
   signal sys_csn      : std_logic;
   signal sys_ck       : std_logic;
   signal sys_rwds     : std_logic;
   signal sys_dq       : std_logic_vector(7 downto 0);
   signal sys_rwds_in  : std_logic;
   signal sys_dq_in    : std_logic_vector(7 downto 0);
   signal sys_rwds_out : std_logic;
   signal sys_dq_out   : std_logic_vector(7 downto 0);
   signal sys_rwds_oe  : std_logic;
   signal sys_dq_oe    : std_logic;

   -- HyperRAM simulation device interface
   signal hr_resetn : std_logic;
   signal hr_csn    : std_logic;
   signal hr_ck     : std_logic;
   signal hr_rwds   : std_logic;
   signal hr_dq     : std_logic_vector(7 downto 0);


   component s27kl0642 is
      port (
         dq7      : inout std_logic;
         dq6      : inout std_logic;
         dq5      : inout std_logic;
         dq4      : inout std_logic;
         dq3      : inout std_logic;
         dq2      : inout std_logic;
         dq1      : inout std_logic;
         dq0      : inout std_logic;
         rwds     : inout std_logic;
         csneg    : in    std_logic;
         ck       : in    std_logic;
         ckn      : in    std_logic;
         resetneg : in    std_logic
      );
   end component s27kl0642;

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   sys_clk <= not sys_clk after 5 ns;
   sys_rst <= '1', '0' after 1000 ns;


   --------------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------------

   hyperram_mega65r6_inst : entity work.hyperram_mega65r6
      port map (
         sys_clk_i      => sys_clk,
         sys_rst_i      => sys_rst,
         hr_resetn_o    => sys_resetn,
         hr_csn_o       => sys_csn,
         hr_ck_o        => sys_ck,
         hr_rwds_io     => sys_rwds,
         hr_dq_io       => sys_dq,
         kb_io0_o       => open,
         kb_io1_o       => open,
         kb_io2_i       => '0',
         uart_rx_i      => '1',
         uart_tx_o      => open,
         vga_red_o      => open,
         vga_green_o    => open,
         vga_blue_o     => open,
         vga_hs_o       => open,
         vga_vs_o       => open,
         vdac_clk_o     => open,
         vdac_blank_n_o => open,
         vdac_psave_n_o => open,
         vdac_sync_n_o  => open,
         hdmi_data_p_o  => open,
         hdmi_data_n_o  => open,
         hdmi_clk_p_o   => open,
         hdmi_clk_n_o   => open
      ); -- hyperram_mega65r6_inst


   ---------------------------------------------------------
   -- Connect controller to device (with delay)
   ---------------------------------------------------------

   hr_resetn <= sys_resetn after C_DELAY;
   hr_csn    <= sys_csn    after C_DELAY;
   hr_ck     <= sys_ck     after C_DELAY;

   wiredelay2_rwds_inst : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         a => sys_rwds,
         b => hr_rwds
      ); -- wiredelay2_rwds_inst

   dq_delay_gen : for i in 0 to 7 generate

      wiredelay2_dq_inst : entity work.wiredelay2
         generic map (
            G_DELAY => C_DELAY
         )
         port map (
            a => sys_dq(i),
            b => hr_dq(i)
         ); -- wiredelay2_dq_inst

   end generate dq_delay_gen;


   ---------------------------------------------------------
   -- Instantiate HyperRAM simulation model
   ---------------------------------------------------------

   s27kl0642_inst : component s27kl0642
      port map (
         dq7      => hr_dq(7),
         dq6      => hr_dq(6),
         dq5      => hr_dq(5),
         dq4      => hr_dq(4),
         dq3      => hr_dq(3),
         dq2      => hr_dq(2),
         dq1      => hr_dq(1),
         dq0      => hr_dq(0),
         rwds     => hr_rwds,
         csneg    => hr_csn,
         ck       => hr_ck,
         ckn      => not hr_ck,
         resetneg => hr_resetn
      ); -- s27kl0642_inst

end architecture simulation;

