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
      clk_x4_i            : in    std_logic;
      rst_i               : in    std_logic;

      -- Connect to HyperRAM controller
      ctrl_rstn_i         : in    std_logic;
      ctrl_ck_ddr_i       : in    std_logic_vector(1 downto 0);
      ctrl_csn_i          : in    std_logic;
      ctrl_dq_ddr_in_o    : out   std_logic_vector(15 downto 0);
      ctrl_dq_ddr_out_i   : in    std_logic_vector(15 downto 0);
      ctrl_dq_oe_i        : in    std_logic;
      ctrl_rwds_ddr_in_o  : out   std_logic_vector(1 downto 0);
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
   signal rwds_x4_n : std_logic;

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
   -- Input buffers
   ------------------------------------------------

   p_input : process (clk_x4_i)
   begin
      if rising_edge(clk_x4_i) then
         -- Delay RWDS input
         rwds_x4_n <= not hr_rwds_io;
      end if;
   end process p_input;

   gen_iddr_dq : for i in 0 to 7 generate
      i_iddr_dq : IDDR
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE"
         )
         port map (
            D  => hr_dq_io(i),
            Q1 => ctrl_dq_ddr_in_o(i),
            Q2 => ctrl_dq_ddr_in_o(i+8),
            CE => '1',
            C  => rwds_x4_n
         ); -- i_iddr_dq
   end generate gen_iddr_dq;

   i_iddr_rwds : IDDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE"
      )
      port map (
         D  => hr_rwds_io,
         Q1 => ctrl_rwds_ddr_in_o(0),
         Q2 => ctrl_rwds_ddr_in_o(1),
         CE => '1',
         C  => clk_i
      ); -- i_oddr_rwds


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

