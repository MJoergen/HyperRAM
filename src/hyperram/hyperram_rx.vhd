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
      ctrl_read_i      : in    std_logic;

      -- Connect to HyperRAM device
      hr_rwds_in_i     : in    std_logic;
      hr_dq_in_i       : in    std_logic_vector(7 downto 0)
   );
end entity hyperram_rx;

architecture synthesis of hyperram_rx is

   signal rwds_dq_in    : std_logic_vector(15 downto 0);
   signal rwds_in_delay : std_logic;

   signal ctrl_dq_ie   : std_logic;
   signal ctrl_dq_ie_d : std_logic;

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

   hyperram_fifo_inst : entity work.hyperram_fifo
      generic map (
         G_DATA_SIZE => 16
      )
      port map (
         src_clk_i   => not rwds_in_delay,
         src_valid_i => ctrl_read_i,
         src_data_i  => rwds_dq_in,
         dst_clk_i   => clk_x1_i,
         dst_data_o  => ctrl_dq_ddr_in_o,
         dst_valid_o => ctrl_dq_ie
      ); -- hyperram_fifo_inst

   ctrl_dq_ie_d_proc : process (clk_x1_i)
   begin
      if rising_edge(clk_x1_i) then
         ctrl_dq_ie_d <= ctrl_dq_ie;
      end if;
   end process ctrl_dq_ie_d_proc;

   ctrl_dq_ie_o <= ctrl_dq_ie_d and ctrl_dq_ie;

   xpm_cdc_single_inst : component xpm_cdc_single
      generic map (
         DEST_SYNC_FF   => 2,
         INIT_SYNC_FF   => 0,
         SIM_ASSERT_CHK => 0,
         SRC_INPUT_REG  => 0
      )
      port map (
         src_clk  => '0',
         src_in   => rwds_in_delay,
         dest_clk => clk_x1_i,
         dest_out => ctrl_rwds_in_o
      ); -- xpm_cdc_single_inst

end architecture synthesis;

