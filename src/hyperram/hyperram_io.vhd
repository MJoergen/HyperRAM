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
      clk_x1_i            : in  std_logic;
      clk_x1_del_i        : in  std_logic; -- phase shifted.
      delay_refclk_i      : in  std_logic; -- 200 MHz
      rst_i               : in  std_logic;

      -- Connect to HyperRAM controller
      ctrl_rstn_i         : in  std_logic;
      ctrl_ck_ddr_i       : in  std_logic_vector(1 downto 0);
      ctrl_csn_i          : in  std_logic;
      ctrl_dq_ddr_in_o    : out std_logic_vector(15 downto 0);
      ctrl_dq_ddr_out_i   : in  std_logic_vector(15 downto 0);
      ctrl_dq_oe_i        : in  std_logic;
      ctrl_dq_ie_o        : out std_logic;
      ctrl_rwds_ddr_out_i : in  std_logic_vector(1 downto 0);
      ctrl_rwds_oe_i      : in  std_logic;
      ctrl_rwds_in_o      : out std_logic;

      -- Connect to HyperRAM device
      hr_resetn_o         : out std_logic;
      hr_csn_o            : out std_logic;
      hr_ck_o             : out std_logic;
      hr_rwds_in_i        : in  std_logic;
      hr_dq_in_i          : in  std_logic_vector(7 downto 0);
      hr_rwds_out_o       : out std_logic;
      hr_dq_out_o         : out std_logic_vector(7 downto 0);
      hr_rwds_oe_n_o      : out std_logic;
      hr_dq_oe_n_o        : out std_logic
   );
end entity hyperram_io;

architecture synthesis of hyperram_io is

begin

   hr_csn_o       <= ctrl_csn_i;
   hr_resetn_o    <= ctrl_rstn_i;


   ------------------------------------------------
   -- OUTPUT BUFFERS
   ------------------------------------------------

   b_output : block
      signal hr_dq_oe_n   : std_logic;
      signal hr_rwds_oe_n : std_logic;
   begin

      i_oddr_clk : ODDR
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            D1 => ctrl_ck_ddr_i(1),
            D2 => ctrl_ck_ddr_i(0),
            CE => '1',
            Q  => hr_ck_o,
            C  => clk_x1_del_i
         ); -- i_oddr_clk

      i_oddr_rwds : ODDR
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            D1 => ctrl_rwds_ddr_out_i(1),
            D2 => ctrl_rwds_ddr_out_i(0),
            CE => '1',
            Q  => hr_rwds_out_o,
            C  => clk_x1_i
         ); -- i_oddr_rwds

      gen_oddr_dq : for i in 0 to 7 generate
         i_oddr_dq : ODDR
            generic map (
               DDR_CLK_EDGE => "SAME_EDGE"
            )
            port map (
               D1 => ctrl_dq_ddr_out_i(i+8),
               D2 => ctrl_dq_ddr_out_i(i),
               CE => '1',
               Q  => hr_dq_out_o(i),
               C  => clk_x1_i
            ); -- i_oddr_dq
      end generate gen_oddr_dq;

      -- The Output Enable signals are active low, because that maps
      -- directly into the TriState pin of an IOBUFT primitive.
      p_output : process (clk_x1_i)
      begin
         if rising_edge(clk_x1_i) then
            hr_dq_oe_n   <= not ctrl_dq_oe_i;
            hr_rwds_oe_n <= not ctrl_rwds_oe_i;
         end if;
      end process p_output;

      -- This assert the OE a clock cycle earlier for better timing.
      -- See also the set_multicycle_path constraints in the XDC file.
      hr_dq_oe_n_o   <= hr_dq_oe_n   and not ctrl_dq_oe_i;
      hr_rwds_oe_n_o <= hr_rwds_oe_n and not ctrl_rwds_oe_i;

   end block b_output;


   ------------------------------------------------
   -- INPUT BUFFERS
   --
   -- Here we treat RWDS as a clock, because the relationship
   -- between RWDS and DQ is well-defined (within +/- 0.6 ns).
   -- The RWDS is delayed by approximately 90 degrees using
   -- an IDELAYE2 primitive, to ensure that RWDS transitions while DQ is stable.
   -- The actual delay is, according to Vivado's timing report, 2.474 ns.
   ------------------------------------------------

   b_input : block
      signal hr_dq_in         : std_logic_vector(15 downto 0);
      signal hr_rwds_in_delay : std_logic;
      signal hr_toggle        : std_logic := '0';

      signal ctrl_toggle      : std_logic;
      signal ctrl_dq_ddr_in   : std_logic_vector(15 downto 0);
      signal ctrl_dq_ie       : std_logic;
      signal ctrl_rwds_in     : std_logic;

      attribute ASYNC_REG : string;
      attribute ASYNC_REG of ctrl_toggle    : signal is "TRUE";
      attribute ASYNC_REG of ctrl_dq_ddr_in : signal is "TRUE";
      attribute ASYNC_REG of ctrl_dq_ie     : signal is "TRUE";
      attribute ASYNC_REG of ctrl_rwds_in   : signal is "TRUE";
   begin

      i_delay_ctrl : IDELAYCTRL
         port map (
            RST    => rst_i,
            REFCLK => delay_refclk_i,
            RDY    => open
         ); -- i_delay_ctrl

      i_delay_rwds : IDELAYE2
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
            DATAOUT     => hr_rwds_in_delay,
            CNTVALUEOUT => open
         ); -- i_delay_rwds

      gen_iddr_dq : for i in 0 to 7 generate
         i_iddr_dq : IDDR
            generic map (
               DDR_CLK_EDGE => "SAME_EDGE"
            )
            port map (
               D  => hr_dq_in_i(i),
               CE => '1',
               Q1 => hr_dq_in(i),
               Q2 => hr_dq_in(i+8),
               C  => not hr_rwds_in_delay
            ); -- i_iddr_dq
      end generate gen_iddr_dq;

      -- This Clock Domain Crossing block is to synchronize the input signal to the
      -- clk_x1_i clock domain. It's not possible to use an ordinary async fifo, because
      -- the input clock RWDS is not free-running.
      p_hr : process (hr_rwds_in_delay)
      begin
         if falling_edge(hr_rwds_in_delay) then
            hr_toggle <= not hr_toggle;
         end if;
      end process p_hr;

      -- Clock domain crossing
      p_async : process (clk_x1_i)
      begin
         if rising_edge(clk_x1_i) then
            ctrl_toggle    <= hr_toggle;
            ctrl_dq_ddr_in <= hr_dq_in;
            ctrl_dq_ie     <= hr_toggle xor ctrl_toggle;
            ctrl_rwds_in   <= hr_rwds_in_delay;
         end if;
      end process p_async;

      ctrl_dq_ddr_in_o <= ctrl_dq_ddr_in;
      ctrl_dq_ie_o     <= ctrl_dq_ie;
      ctrl_rwds_in_o   <= ctrl_rwds_in;

   end block b_input;

end architecture synthesis;

