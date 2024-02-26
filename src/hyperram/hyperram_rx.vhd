-- This is part of the HyperRAM I/O connections
-- It handles signals from HyperRAM to FPGA.
-- The additional clock delay_refclk_i is used to drive IDELAY_CTRL.
--
-- Created by Michael Jørgensen in 2023 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library unisim;
   use unisim.vcomponents.all;

library xpm;
   use xpm.vcomponents.all;

entity hyperram_rx is
   port (
      clk_x1_i         : in    std_logic;
      delay_refclk_i   : in    std_logic; -- 200 MHz
      rst_i            : in    std_logic;

      -- Connect to HyperRAM controller
      ctrl_dq_ddr_in_o : out   std_logic_vector(15 downto 0);
      ctrl_dq_ie_o     : out   std_logic;
      ctrl_rwds_in_o   : out   std_logic;

      -- Connect to HyperRAM device
      hr_rwds_in_i     : in    std_logic;
      hr_dq_in_i       : in    std_logic_vector(7 downto 0)
   );
end entity hyperram_rx;

architecture synthesis of hyperram_rx is

   -- Synchronuous to RWDS
   signal rwds_dq_in    : std_logic_vector(15 downto 0);
   signal rwds_in_delay : std_logic;
   signal rwds_toggle   : std_logic := '0';

   -- Synchronuous to hr_clk_x1
   signal ctrl_dq_ddr_in : std_logic_vector(15 downto 0);
   signal ctrl_dq_ie     : std_logic;
   signal ctrl_rwds_in   : std_logic;
   signal ctrl_toggle    : std_logic;
   signal ctrl_toggle_d  : std_logic;

begin

   delay_ctrl_inst : component idelayctrl
      port map (
         rst    => rst_i,
         refclk => delay_refclk_i,
         rdy    => open
      ); -- delay_ctrl_inst

   delay_rwds_inst : component idelaye2
      generic map (
         IDELAY_TYPE           => "FIXED",
         DELAY_SRC             => "IDATAIN",
         IDELAY_VALUE          => 21,
         HIGH_PERFORMANCE_MODE => "TRUE",
         SIGNAL_PATTERN        => "CLOCK",
         REFCLK_FREQUENCY      => 200.0,
         CINVCTRL_SEL          => "FALSE",
         PIPE_SEL              => "FALSE"
      )
      port map (
         c           => '0',
         regrst      => '0',
         ld          => '0',
         ce          => '0',
         inc         => '0',
         cinvctrl    => '0',
         cntvaluein  => B"10101", -- 21
         idatain     => hr_rwds_in_i,
         datain      => '0',
         ldpipeen    => '0',
         dataout     => rwds_in_delay,
         cntvalueout => open
      ); -- delay_rwds_inst

   iddr_dq_gen : for i in 0 to 7 generate

      iddr_dq_inst : component iddr
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            d  => hr_dq_in_i(i),
            ce => '1',
            q1 => rwds_dq_in(i),
            q2 => rwds_dq_in(i + 8),
            c  => not rwds_in_delay
         ); -- iddr_dq_inst

   end generate iddr_dq_gen;

   -- This Clock Domain Crossing block is to synchronize the input signal to the
   -- clk_x1_i clock domain. It's not possible to use an ordinary async fifo, because
   -- the input clock RWDS is not free-running.

   rwds_toggle_proc : process (rwds_in_delay)
   begin
      if falling_edge(rwds_in_delay) then
         rwds_toggle <= not rwds_toggle;
      end if;
   end process rwds_toggle_proc;

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         DEST_SYNC_FF   => 2,
         INIT_SYNC_FF   => 0,
         SIM_ASSERT_CHK => 0,
         SRC_INPUT_REG  => 0,
         WIDTH          => 18
      )
      port map (
         src_clk               => '0',
         src_in(15 downto 0)   => rwds_dq_in,
         src_in(16)            => rwds_in_delay,
         src_in(17)            => rwds_toggle,
         dest_clk              => clk_x1_i,
         dest_out(15 downto 0) => ctrl_dq_ddr_in,
         dest_out(16)          => ctrl_rwds_in,
         dest_out(17)          => ctrl_toggle
      );

   ctrl_dq_ie       <= ctrl_toggle_d xor ctrl_toggle;

   ctrl_dq_ddr_in_o <= ctrl_dq_ddr_in;
   ctrl_dq_ie_o     <= ctrl_dq_ie;
   ctrl_rwds_in_o   <= ctrl_rwds_in;

   ctrl_dq_ie_proc : process (clk_x1_i)
   begin
      if rising_edge(clk_x1_i) then
         ctrl_toggle_d <= ctrl_toggle;
      end if;
   end process ctrl_dq_ie_proc;

end architecture synthesis;

