library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- This is the HyperRAM I/O connections

entity hyperram_io is
   port (
      clk_i               : in    std_logic;
      clk_90_i            : in    std_logic;
      clk_x2_i            : in    std_logic;
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

      -- Connect to HyperRAM device
      hr_resetn_o         : out   std_logic;
      hr_csn_o            : out   std_logic;
      hr_ck_o             : out   std_logic;
      hr_rwds_io          : inout std_logic;
      hr_dq_io            : inout std_logic_vector(7 downto 0)
   );
end entity hyperram_io;

architecture synthesis of hyperram_io is

   -- Output signals before tristate buffer
   signal rwds_out  : std_logic;
   signal dq_out    : std_logic_vector(7 downto 0);

   -- Delayed output enables
   signal rwds_oe_d : std_logic;
   signal dq_oe_d   : std_logic;

   -- Over-sampled RWDS signal
   signal rwds_in_x2   : std_logic;
   signal dq_in_x2     : std_logic_vector(7 downto 0);
   signal rwds_in_x2_d : std_logic;
   signal dq_in_x2_d   : std_logic_vector(7 downto 0);

   constant C_DEBUG_MODE              : boolean := false;
   attribute mark_debug               : boolean;
   attribute mark_debug of rwds_in_x2 : signal is C_DEBUG_MODE;
   attribute mark_debug of dq_in_x2   : signal is C_DEBUG_MODE;
   attribute mark_debug of hr_csn_o   : signal is C_DEBUG_MODE;

begin

   ------------------------------------------------
   -- Output buffers
   ------------------------------------------------

   i_oddr_clk : ODDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE"
      )
      port map (
         D1 => ctrl_ck_ddr_i(1),
         D2 => ctrl_ck_ddr_i(0),
         CE => '1',
         Q  => hr_ck_o,
         C  => clk_90_i
      ); -- i_oddr_clk

   i_oddr_rwds : ODDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE"
      )
      port map (
         D1 => ctrl_rwds_ddr_out_i(1),
         D2 => ctrl_rwds_ddr_out_i(0),
         CE => '1',
         Q  => rwds_out,
         C  => clk_i
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
            Q  => dq_out(i),
            C  => clk_i
         ); -- i_oddr_dq
   end generate gen_oddr_dq;


   ------------------------------------------------
   -- Input sampling
   ------------------------------------------------

   p_pipeline : process (clk_x2_i)
   begin
      if rising_edge(clk_x2_i) then
         rwds_in_x2   <= hr_rwds_io;
         dq_in_x2     <= hr_dq_io;
         rwds_in_x2_d <= rwds_in_x2;
         dq_in_x2_d   <= dq_in_x2;
      end if;
   end process p_pipeline;

   p_input : process (clk_i)
   begin
      if rising_edge(clk_i) then
         ctrl_dq_ie_o <= '0';
         if rwds_in_x2_d = '1' and rwds_in_x2 = '0' then
            ctrl_dq_ddr_in_o <= dq_in_x2_d & dq_in_x2;
            ctrl_dq_ie_o     <= '1';
         end if;
         if rwds_in_x2_d = '0' and rwds_in_x2 = '1' then
            ctrl_dq_ddr_in_o <= dq_in_x2 & hr_dq_io;
            ctrl_dq_ie_o     <= '1';
         end if;
      end if;
   end process p_input;


   ------------------------------------------------
   -- Tri-state buffers
   ------------------------------------------------

   p_delay : process (clk_i)
   begin
      if rising_edge(clk_i) then
         dq_oe_d   <= ctrl_dq_oe_i;
         rwds_oe_d <= ctrl_rwds_oe_i;
      end if;
   end process p_delay;

   hr_rwds_io <= rwds_out when rwds_oe_d = '1' else 'Z';
   hr_dq_io   <= dq_out   when dq_oe_d   = '1' else (others => 'Z');

   hr_csn_o    <= ctrl_csn_i;
   hr_resetn_o <= ctrl_rstn_i;

end architecture synthesis;

