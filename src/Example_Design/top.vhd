-- This is the top-level file for the MEGA65 platform (revision 3).
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk         : in    std_logic;                  -- 100 MHz clock
      reset_n     : in    std_logic;                  -- CPU reset button (active low)

      -- HyperRAM device interface
      hr_resetn   : out   std_logic;
      hr_csn      : out   std_logic;
      hr_ck       : out   std_logic;
      hr_rwds     : inout std_logic;
      hr_dq       : inout std_logic_vector(7 downto 0);

      -- MEGA65 keyboard
      kb_io0      : out   std_logic;
      kb_io1      : out   std_logic;
      kb_io2      : in    std_logic;

      -- MEGA65 Digital Video (HDMI)
      hdmi_data_p : out   std_logic_vector(2 downto 0);
      hdmi_data_n : out   std_logic_vector(2 downto 0);
      hdmi_clk_p  : out   std_logic;
      hdmi_clk_n  : out   std_logic
   );
end entity top;

architecture synthesis of top is

   constant C_SYS_ADDRESS_SIZE : integer := 16;
   constant C_ADDRESS_SIZE     : integer := 22;
   constant C_DATA_SIZE        : integer := 16;

   -- HyperRAM clocks
   signal clk_x1               : std_logic; -- HyperRAM clock
   signal clk_x2               : std_logic; -- Double speed clock
   signal clk_x2_del           : std_logic; -- Double speed clock, phase shifted

   -- synchronized reset
   signal rst                  : std_logic;

   constant C_HYPERRAM_FREQ_MHZ    : integer := 100;
   constant C_HYPERRAM_PHASE       : real := 162.000;
   signal freq_str             : std_logic_vector(11 downto 0);
   signal phase_str            : std_logic_vector(11 downto 0);

   -- Control and Status for trafic generator
   signal sys_start            : std_logic;
   signal sys_valid            : std_logic;
   signal sys_active           : std_logic;
   signal sys_error            : std_logic;
   signal sys_address          : std_logic_vector(31 downto 0);
   signal sys_data_exp         : std_logic_vector(31 downto 0);
   signal sys_data_read        : std_logic_vector(31 downto 0);

   -- Interface to MEGA65 video
   signal sys_digits           : std_logic_vector(127 downto 0);

begin

   --------------------------------------------------------
   -- Generate clocks for HyperRAM controller
   --------------------------------------------------------

   i_clk : entity work.clk
      generic map
      (
         G_HYPERRAM_FREQ_MHZ => C_HYPERRAM_FREQ_MHZ,
         G_HYPERRAM_PHASE    => C_HYPERRAM_PHASE
      )
      port map
      (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         clk_x1_o     => clk_x1,
         clk_x2_o     => clk_x2,
         clk_x2_del_o => clk_x2_del,
         rst_o        => rst
      ); -- i_clk


   --------------------------------------------------------
   -- Instantiate core test generator
   --------------------------------------------------------

   i_core : entity work.core
      generic map (
         G_SYS_ADDRESS_SIZE => C_SYS_ADDRESS_SIZE,
         G_ADDRESS_SIZE     => C_ADDRESS_SIZE,
         G_DATA_SIZE        => C_DATA_SIZE
      )
      port map (
         clk_x1_i     => clk_x1,
         clk_x2_i     => clk_x2,
         clk_x2_del_i => clk_x2_del,
         rst_i        => rst,
         start_i      => sys_start,
         error_o      => sys_error,
         active_o     => sys_active,
         address_o    => sys_address,
         data_exp_o   => sys_data_exp,
         data_read_o  => sys_data_read,
         hr_resetn_o  => hr_resetn,
         hr_csn_o     => hr_csn,
         hr_ck_o      => hr_ck,
         hr_rwds_io   => hr_rwds,
         hr_dq_io     => hr_dq
      ); -- i_core

   ----------------------------------
   -- Generate debug output for video
   ----------------------------------

   freq_str(11 downto 8) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/100) mod 10, 4));
   freq_str( 7 downto 4) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/10)  mod 10, 4));
   freq_str( 3 downto 0) <= std_logic_vector(to_unsigned((C_HYPERRAM_FREQ_MHZ/1)   mod 10, 4));

   phase_str(11 downto 8) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/100) mod 10, 4));
   phase_str( 7 downto 4) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/10)  mod 10, 4));
   phase_str( 3 downto 0) <= std_logic_vector(to_unsigned((integer(C_HYPERRAM_PHASE)/1)   mod 10, 4));

   sys_digits( 31 downto  0) <= sys_data_read;
   sys_digits( 47 downto 32) <= sys_address(15 downto 0);
   sys_digits( 63 downto 48) <= X"00" & "000" & sys_address(20 downto 16);
   sys_digits( 79 downto 64) <= "0000" & freq_str;
   sys_digits( 95 downto 80) <= "0000" & phase_str;
   sys_digits(127 downto 96) <= sys_data_exp;


   ----------------------------------
   -- Instantiate MEGA65 platform interface
   ----------------------------------

   i_mega65 : entity work.mega65
      port map (
         sys_clk      => clk_x1,
         sys_reset_n  => not rst,
         sys_start_o  => sys_start,
         sys_active_i => sys_active,
         sys_error_i  => sys_error,
         sys_digits_i => sys_digits,
         kb_io0       => kb_io0,
         kb_io1       => kb_io1,
         kb_io2       => kb_io2,
         hdmi_data_p  => hdmi_data_p,
         hdmi_data_n  => hdmi_data_n,
         hdmi_clk_p   => hdmi_clk_p,
         hdmi_clk_n   => hdmi_clk_n
      ); -- i_mega65

end architecture synthesis;

