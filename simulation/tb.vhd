-- Main testbench for the HyperRAM controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   constant C_DELAY      : time  := 1 ns;
   constant C_CLK_PERIOD : time  := 10 ns; -- 100 MHz

   signal   sys_clk  : std_logic := '1';
   signal   sys_rstn : std_logic := '0';

   signal   clk          : std_logic;
   signal   clk_del      : std_logic;
   signal   delay_refclk : std_logic;
   signal   rst          : std_logic;

   signal   tb_start : std_logic;

   signal   sys_resetn    : std_logic;
   signal   sys_csn       : std_logic;
   signal   sys_ck        : std_logic;
   signal   sys_rwds      : std_logic;
   signal   sys_dq        : std_logic_vector(7 downto 0);
   signal   sys_rwds_in   : std_logic;
   signal   sys_dq_in     : std_logic_vector(7 downto 0);
   signal   sys_rwds_out  : std_logic;
   signal   sys_dq_out    : std_logic_vector(7 downto 0);
   signal   sys_rwds_oe_n : std_logic;
   signal   sys_dq_oe_n   : std_logic_vector(7 downto 0);

   -- HyperRAM simulation device interface
   signal   hr_resetn : std_logic;
   signal   hr_csn    : std_logic;
   signal   hr_ck     : std_logic;
   signal   hr_rwds   : std_logic;
   signal   hr_dq     : std_logic_vector(7 downto 0);


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

   sys_clk  <= not sys_clk after C_CLK_PERIOD / 2;
   sys_rstn <= '0', '1' after 100 * C_CLK_PERIOD;

   clk_controller_inst : entity work.clk_controller
      port map (
         sys_clk_i      => sys_clk,
         sys_rst_i      => not sys_rstn,
         clk_o          => clk,
         rst_o          => rst,
         clk_del_o      => clk_del,
         delay_refclk_o => delay_refclk
      ); -- clk_controller_inst


   --------------------------------------------------------
   -- Generate start signal for trafic generator
   --------------------------------------------------------

   tb_start_proc : process
   begin
      tb_start <= '0';
      wait for 160 us;
      wait until clk = '1';
      tb_start <= '1';
      wait until clk = '1';
      tb_start <= '0';
      wait;
   end process tb_start_proc;


   --------------------------------------------------------
   -- Instantiate core test generator
   --------------------------------------------------------

   core_wrapper_inst : entity work.core_wrapper
      generic map (
         G_SYS_ADDRESS_SIZE => 6,
         G_ADDRESS_SIZE     => 20,
         G_DATA_SIZE        => 64
      )
      port map (
         clk_i           => clk,
         rst_i           => rst,
         clk_del_i       => clk_del,
         delay_refclk_i  => delay_refclk,
         start_i         => tb_start,
         active_o        => open,
         stat_total_o    => open,
         stat_error_o    => open,
         stat_err_addr_o => open,
         stat_err_exp_o  => open,
         stat_err_read_o => open,
         hr_resetn_o     => sys_resetn,
         hr_csn_o        => sys_csn,
         hr_ck_o         => sys_ck,
         hr_rwds_in_i    => sys_rwds_in,
         hr_rwds_out_o   => sys_rwds_out,
         hr_rwds_oe_n_o  => sys_rwds_oe_n,
         hr_dq_in_i      => sys_dq_in,
         hr_dq_out_o     => sys_dq_out,
         hr_dq_oe_n_o    => sys_dq_oe_n
      ); -- core_wrapper_inst

   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   sys_rwds <= sys_rwds_out when sys_rwds_oe_n = '0' else
               'Z';

   sys_dq_gen : for i in 0 to 7 generate
      sys_dq(i) <= sys_dq_out(i) when sys_dq_oe_n(i) = '0' else
                   'Z';
   end generate sys_dq_gen;

   sys_rwds_in <= sys_rwds;
   sys_dq_in   <= sys_dq;


   ---------------------------------------------------------
   -- Connect controller to device (with delay)
   ---------------------------------------------------------

   hr_resetn   <= sys_resetn after C_DELAY;
   hr_csn      <= sys_csn    after C_DELAY;
   hr_ck       <= sys_ck     after C_DELAY;

   wiredelay2_rwds_inst : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         a => sys_rwds,
         b => hr_rwds
      ); -- wiredelay2_rwds_inst

   dq_delay_gen : for i in 0 to 7 generate

      wiredelay2_rwds_inst : entity work.wiredelay2
         generic map (
            G_DELAY => C_DELAY
         )
         port map (
            a => sys_dq(i),
            b => hr_dq(i)
         ); -- wiredelay2_rwds_inst

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

