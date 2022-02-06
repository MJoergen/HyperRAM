library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity top is
   port (
      clk       : in    std_logic;                  -- 100 MHz clock
      reset_n   : in    std_logic;                  -- CPU reset button

      -- HyperRAM device interface
      hr_resetn : out   std_logic;
      hr_csn    : out   std_logic;
      hr_ck     : out   std_logic;
      hr_rwds   : inout std_logic;
      hr_dq     : inout std_logic_vector(7 downto 0);

      -- Interface for physical keyboard
      kb_io0    : out   std_logic;
      kb_io1    : out   std_logic;
      kb_io2    : in    std_logic
   );
end entity top;

architecture synthesis of top is

   constant C_HYPERRAM_FREQ_MHZ : integer := 100;

   -- HyperRAM clocks
   signal clk_x1      : std_logic; -- HyperRAM clock
   signal clk_x2      : std_logic; -- Double speed clock

   -- MEGA65 clocks
   signal kbd_clk     : std_logic; -- Keyboard clock

   -- resets
   signal rst         : std_logic;

   signal return_out  : std_logic;
   signal start       : std_logic;

   signal sys_active  : std_logic;
   signal sys_error   : std_logic;

   signal led_active  : std_logic;
   signal led_error   : std_logic;

   signal hr_rwds_out : std_logic;
   signal hr_dq_out   : std_logic_vector(7 downto 0);
   signal hr_rwds_oe  : std_logic;
   signal hr_dq_oe    : std_logic;

begin

   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
   hr_dq   <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');


   i_clk_mega65 : entity work.clk_mega65
      port map
      (
         sys_clk_i  => clk,
         sys_rstn_i => reset_n,
         kbd_clk_o  => kbd_clk
      ); -- i_clk_mega65

   i_clk : entity work.clk
      generic map
      (
         G_HYPERRAM_FREQ_MHZ => C_HYPERRAM_FREQ_MHZ
      )
      port map
      (
         sys_clk_i  => clk,
         sys_rstn_i => reset_n,
         clk_x1_o   => clk_x1,
         clk_x2_o   => clk_x2,
         rst_o      => rst
      ); -- i_clk

   i_system : entity work.system
      generic map (
         G_ADDRESS_SIZE => 22       -- 4M entries of 16 bits each.
      )
      port map (
         clk_i         => clk_x1,
         clk_x2_i      => clk_x2,
         rst_i         => rst,
         start_i       => start,
         hr_resetn_o   => hr_resetn,
         hr_csn_o      => hr_csn,
         hr_ck_o       => hr_ck,
         hr_rwds_in_i  => hr_rwds,
         hr_dq_in_i    => hr_dq,
         hr_rwds_out_o => hr_rwds_out,
         hr_dq_out_o   => hr_dq_out,
         hr_rwds_oe_o  => hr_rwds_oe,
         hr_dq_oe_o    => hr_dq_oe,
         active_o      => sys_active,
         error_o       => sys_error
      ); -- i_system

   i_cdc_keyboard: xpm_cdc_array_single
      generic map (
         WIDTH => 2
      )
      port map (
         src_clk      => clk_x1,
         src_in(0)    => sys_active,
         src_in(1)    => sys_error,
         dest_clk     => kbd_clk,
         dest_out(0)  => led_active,
         dest_out(1)  => led_error
      ); -- i_cdc_keyboard


   i_mega65kbd_to_matrix : entity work.mega65kbd_to_matrix
      port map (
         cpuclock       => kbd_clk,
         flopled        => led_error,
         powerled       => led_active,
         kio8           => kb_io0,
         kio9           => kb_io1,
         kio10          => kb_io2,
         delete_out     => open,
         return_out     => return_out, -- Active low
         fastkey_out    => open
      ); -- i_mega65kbd_to_matrix

   i_cdc_start: xpm_cdc_array_single
      generic map (
         WIDTH => 1
      )
      port map (
         src_clk     => kbd_clk,
         src_in(0)   => not return_out,
         dest_clk    => clk_x1,
         dest_out(0) => start
      ); -- i_cdc_start

end architecture synthesis;

