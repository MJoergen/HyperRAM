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

   signal return_out   : std_logic;
   signal start        : std_logic;

   signal led_active   : std_logic;
   signal led_error    : std_logic;

   signal hr_rwds_out  : std_logic;
   signal hr_dq_out    : std_logic_vector(7 downto 0);
   signal hr_rwds_oe   : std_logic;
   signal hr_dq_oe     : std_logic;

begin

   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
   hr_dq   <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');


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
         clk_i         => clk,
         clk_90_i      => clk_90,
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
         active_o      => led_active,
         error_o       => led_error
      ); -- i_system

   i_mega65kbd_to_matrix : entity work.mega65kbd_to_matrix
      port map (
         cpuclock       => clk_40,
         flopled        => led_error,
         powerled       => led_active,
         kio8           => kb_io0,
         kio9           => kb_io1,
         kio10          => kb_io2,
         delete_out     => open,
         return_out     => return_out, -- Active low
         fastkey_out    => open
      ); -- i_mega65kbd_to_matrix

   p_start : process (clk)
   begin
      if rising_edge(clk) then
         start <= not return_out;
      end if;
   end process p_start;

end architecture synthesis;

