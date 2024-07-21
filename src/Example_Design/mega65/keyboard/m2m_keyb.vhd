----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- MEGA65 keyboard controller
--
-- Runs in the clock domain of the core.
--
-- There are two purposes of this controller:
--
-- 1) Serve key_num and key_status to the core's keyboard.vhd, so that there the
--    core specific keyboard mapping can take place.
--
-- 2) Serve qnice_keys to QNICE and the firmware, so that the Shell can rely
--    on certain mappings (and behaviors) to be always available, independent
--    of the core specific way to handle the keyboard.
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity m2m_keyb is
   generic (
      G_SCAN_FREQUENCY : integer := 1000 -- keyboard scan frequency in Herz, default: 1 kHz
   );
   port (
      clk_main_i       : in    std_logic;             -- core clock
      clk_main_speed_i : in    natural;               -- speed of core clock in Hz

      -- interface to the MEGA65 keyboard controller
      kio8_o           : out   std_logic;             -- clock to keyboard
      kio9_o           : out   std_logic;             -- data output to keyboard
      kio10_i          : in    std_logic;             -- data input from keyboard

      -- interface to the core
      enable_core_i    : in    std_logic;             -- 0 = core is decoupled from the keyboard, 1 = standard operation
      key_num_o        : out   integer range 0 to 79; -- cycles through all keys with G_SCAN_FREQUENCY
      key_pressed_n_o  : out   std_logic;             -- low active: debounced feedback: is kb_key_num_o pressed right now?

      -- control the drive led on the MEGA65 keyboard
      flopled_i        : in    std_logic;
      powerled_i       : in    std_logic;

      -- interface to QNICE: used by the firmware and the Shell (see sysdef.asm for details)
      qnice_keys_n_o   : out   std_logic_vector(15 downto 0)
   );
end entity m2m_keyb;

architecture synthesis of m2m_keyb is

   signal matrix_col     : std_logic_vector(7 downto 0);
   signal matrix_col_idx : integer range 0 to 9          := 0;
   signal key_num        : integer range 0 to 79;
   signal key_status_n   : std_logic;
   signal keys_n         : std_logic_vector(15 downto 0) := x"FFFF"; -- low active, "no key pressed"

begin

   -- output the keyboard interface for the core
   key_num_o       <= key_num;
   key_pressed_n_o <= key_status_n when enable_core_i else
                      '1';

   -- output the keyboard interface for QNICE
   qnice_keys_n_o  <= keys_n;

   mega65kbd_to_matrix_inst : entity work.mega65kbd_to_matrix
      port map (
         ioclock_i         => clk_main_i,
         clock_frequency_i => clk_main_speed_i,

         flopmotor_i       => '0',
         flopled_i         => flopled_i,
         powerled_i        => powerled_i,

         kio8_o            => kio8_o,
         kio9_o            => kio9_o,
         kio10_i           => kio10_i,

         matrix_col_o      => matrix_col,
         matrix_col_idx_i  => matrix_col_idx,

         capslock_out_o    => open
      ); -- mega65kbd_to_matrix_inst

   matrix_to_keynum_inst : entity work.matrix_to_keynum
      generic map (
         G_SCAN_FREQUENCY => G_SCAN_FREQUENCY
      )
      port map (
         clk_i                    => clk_main_i,
         clock_frequency_i        => clk_main_speed_i,
         reset_in_i               => '0',

         matrix_col_i             => matrix_col,
         matrix_col_idx_i         => matrix_col_idx,

         m65_key_num_o            => key_num,
         m65_key_status_n_o       => key_status_n,

         suppress_key_glitches_i  => '1',
         suppress_key_retrigger_i => '0',

         bucky_key_o              => open
      ); -- matrix_to_keynum_inst

   matrix_col_idx_handler_proc : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         if matrix_col_idx < 9 then
            matrix_col_idx <= matrix_col_idx + 1;
         else
            matrix_col_idx <= 0;
         end if;
      end if;
   end process matrix_col_idx_handler_proc;

   -- make qnice_keys_o a register and fill it
   -- see sysdef.asm for the key-to-bit mapping
   handle_qnice_keys_proc : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then

         case key_num is

            when 73 =>
               keys_n(0) <= key_status_n;     -- Cursor up

            when 7 =>
               keys_n(1) <= key_status_n;     -- Cursor down

            when 74 =>
               keys_n(2) <= key_status_n;     -- Cursor left

            when 2 =>
               keys_n(3) <= key_status_n;     -- Cursor right

            when 1 =>
               keys_n(4) <= key_status_n;     -- Return

            when 60 =>
               keys_n(5) <= key_status_n;     -- Space

            when 63 =>
               keys_n(6) <= key_status_n;     -- Run/Stop

            when 67 =>
               keys_n(7) <= key_status_n;     -- Help

            when 4 =>
               keys_n(8) <= key_status_n;     -- F1

            when 5 =>
               keys_n(9) <= key_status_n;     -- F3

            when others =>
               null;

         end case;

      end if;
   end process handle_qnice_keys_proc;

end architecture synthesis;

