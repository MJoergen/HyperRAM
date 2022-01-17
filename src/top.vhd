library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

   -- clocks
   signal clk_90 : std_logic; -- 90 degrees phase shift
   signal clk_x2 : std_logic; -- Double speed clock
   signal clk_40 : std_logic; -- Keyboard clock

   -- resets
   signal rst    : std_logic;

   signal return_out  : std_logic;
   signal start       : std_logic;

   signal led_active  : std_logic;
   signal led_error   : std_logic;

begin

   i_clk : entity work.clk
      port map
      (
         sys_clk_i  => clk,
         sys_rstn_i => reset_n,
         clk_x2_o   => clk_x2,
         clk_90_o   => clk_90,
         clk_40_o   => clk_40,
         rst_o      => rst
      ); -- i_clk

   i_system : entity work.system
      generic map (
         G_ADDRESS_SIZE => 22       -- 4M entries of 16 bits each.
      )
      port map (
         clk_i        => clk,
         clk_90_i     => clk_90,
         clk_x2_i     => clk_x2,
         rst_i        => rst,
         start_i      => start,
         hr_resetn_o  => hr_resetn,
         hr_csn_o     => hr_csn,
         hr_ck_o      => hr_ck,
         hr_rwds_io   => hr_rwds,
         hr_dq_io     => hr_dq,
         active_o     => led_active,
         error_o      => led_error
      ); -- i_system

   i_mega65kbd_to_matrix : entity work.mega65kbd_to_matrix
      port map (
         cpuclock       => clk_40,
         flopmotor      => '0',
         flopled        => led_error,
         powerled       => led_active,
         kbd_datestamp  => open,
         kbd_commit     => open,
         disco_led_id   => X"00",
         disco_led_val  => X"00",
         disco_led_en   => '0',
         kio8           => kb_io0,
         kio9           => kb_io1,
         kio10          => kb_io2,
         matrix_col     => open,
         matrix_col_idx => 0,
         delete_out     => open,
         return_out     => return_out, -- Active low
         fastkey_out    => open,
         restore        => open,
         capslock_out   => open,
         leftkey        => open,
         upkey          => open
      ); -- i_mega65kbd_to_matrix

   p_start : process (clk)
   begin
      if rising_edge(clk) then
         start <= not return_out;
      end if;
   end process p_start;

end architecture synthesis;

