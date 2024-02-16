-- This is the HyperRAM I/O connections
-- The additional clock clk_x1_del_i is used to drive the CK output.
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

-- This is the HyperRAM I/O connections

entity hyperram_io is
   port (
      clk_x1_i            : in    std_logic;
      clk_x1_del_i        : in    std_logic; -- phase shifted.
      delay_refclk_i      : in    std_logic; -- 200 MHz
      rst_i               : in    std_logic;

      -- Connect to HyperRAM controller
      ctrl_rstn_i         : in    std_logic;
      ctrl_ck_ddr_i       : in    std_logic_vector(1 downto 0);
      ctrl_csn_i          : in    std_logic;
      ctrl_dq_ddr_in_o    : out   std_logic_vector(15 downto 0);
      ctrl_dq_ddr_out_i   : in    std_logic_vector(15 downto 0);
      ctrl_dq_oe_i        : in    std_logic;
      ctrl_dq_ie_o        : out   std_logic;
      ctrl_rwds_ddr_out_i : in    std_logic_vector(1 downto 0);
      ctrl_rwds_oe_i      : in    std_logic;
      ctrl_rwds_in_o      : out   std_logic;

      -- Connect to HyperRAM device
      hr_resetn_o         : out   std_logic;
      hr_csn_o            : out   std_logic;
      hr_ck_o             : out   std_logic;
      hr_rwds_in_i        : in    std_logic;
      hr_dq_in_i          : in    std_logic_vector(7 downto 0);
      hr_rwds_out_o       : out   std_logic;
      hr_dq_out_o         : out   std_logic_vector(7 downto 0);
      hr_rwds_oe_n_o      : out   std_logic;
      hr_dq_oe_n_o        : out   std_logic_vector(7 downto 0)
   );
end entity hyperram_io;

architecture synthesis of hyperram_io is

begin

   hr_csn_o    <= ctrl_csn_i;
   hr_resetn_o <= ctrl_rstn_i;


   ------------------------------------------------
   -- OUTPUT BUFFERS
   ------------------------------------------------

   output_block : block is

      signal hr_dq_oe_n   : std_logic_vector(7 downto 0);
      signal hr_rwds_oe_n : std_logic;

      -- Make sure all eight flip-flops are preserved, even though
      -- they have identical inputs. This is necessary for the
      -- set_property IOB TRUE constraint to have effect.
      attribute dont_touch : string;
      attribute dont_touch of hr_dq_oe_n : signal is "true";

   begin

      oddr_clk_inst : component ODDR
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            D1 => ctrl_ck_ddr_i(1),
            D2 => ctrl_ck_ddr_i(0),
            CE => '1',
            Q  => hr_ck_o,
            C  => clk_x1_del_i
         ); -- oddr_clk_inst

      oddr_rwds_inst : component ODDR
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            D1 => ctrl_rwds_ddr_out_i(1),
            D2 => ctrl_rwds_ddr_out_i(0),
            CE => '1',
            Q  => hr_rwds_out_o,
            C  => clk_x1_i
         ); -- oddr_rwds_inst

      oddr_dq_gen : for i in 0 to 7 generate
         oddr_dq_inst : component ODDR
            generic map (
               DDR_CLK_EDGE => "SAME_EDGE"
            )
            port map (
               D1 => ctrl_dq_ddr_out_i(i+8),
               D2 => ctrl_dq_ddr_out_i(i),
               CE => '1',
               Q  => hr_dq_out_o(i),
               C  => clk_x1_i
            ); -- oddr_dq_inst
      end generate oddr_dq_gen;

      -- The Output Enable signals are active low, because that maps
      -- directly into the TriState pin of an IOBUFT primitive.
      output_proc : process (clk_x1_i)
      begin
         if rising_edge(clk_x1_i) then
            hr_dq_oe_n   <= (others => not ctrl_dq_oe_i);
            hr_rwds_oe_n <= not ctrl_rwds_oe_i;
         end if;
      end process output_proc;

      hr_dq_oe_n_o   <= hr_dq_oe_n;
      hr_rwds_oe_n_o <= hr_rwds_oe_n;

   end block output_block;


   ------------------------------------------------
   -- INPUT BUFFERS
   --
   -- Here we treat RWDS as a clock, because the relationship
   -- between RWDS and DQ is well-defined (within +/- 0.6 ns).
   -- The RWDS is delayed by approximately 90 degrees using
   -- an IDELAYE2 primitive, to ensure that RWDS transitions while DQ is stable.
   -- The actual delay is, according to Vivado's timing report, 2.474 ns.
   ------------------------------------------------

   input_block : block is

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

      delay_ctrl_inst : component IDELAYCTRL
         port map (
            RST    => rst_i,
            REFCLK => delay_refclk_i,
            RDY    => open
         ); -- delay_ctrl_inst

      delay_rwds_inst : component IDELAYE2
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
            C           => '0',
            REGRST      => '0',
            LD          => '0',
            CE          => '0',
            INC         => '0',
            CINVCTRL    => '0',
            CNTVALUEIN  => B"10101", -- 21
            IDATAIN     => hr_rwds_in_i,
            DATAIN      => '0',
            LDPIPEEN    => '0',
            DATAOUT     => rwds_in_delay,
            CNTVALUEOUT => open
         ); -- delay_rwds_inst

      iddr_dq_gen : for i in 0 to 7 generate
         iddr_dq_inst : component IDDR
            generic map (
               DDR_CLK_EDGE => "SAME_EDGE"
            )
            port map (
               D  => hr_dq_in_i(i),
               CE => '1',
               Q1 => rwds_dq_in(i),
               Q2 => rwds_dq_in(i+8),
               C  => not rwds_in_delay
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

   end block input_block;

end architecture synthesis;

