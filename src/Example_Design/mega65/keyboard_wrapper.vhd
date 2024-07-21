-- This is a wrapper for the MEGA65 keyboard.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

library work;
   use work.video_modes_pkg.all;

library xpm;
   use xpm.vcomponents.all;

entity keyboard_wrapper is
   generic (
      G_CTRL_HZ : natural
   );
   port (
      ctrl_clk_i        : in    std_logic;
      ctrl_rst_i        : in    std_logic;
      ctrl_key_ready_i  : in    std_logic;
      ctrl_key_valid_o  : out   std_logic;
      ctrl_key_data_o   : out   std_logic_vector(7 downto 0);
      ctrl_led_active_i : in    std_logic;
      ctrl_led_error_i  : in    std_logic;

      -- Interface for physical keyboard
      kb_io0_o          : out   std_logic;
      kb_io1_o          : out   std_logic;
      kb_io2_i          : in    std_logic
   );
end entity keyboard_wrapper;

architecture synthesis of keyboard_wrapper is

   signal   key_num       : integer range 0 to 79; -- cycles through all keys with G_SCAN_FREQUENCY
   signal   key_pressed_n : std_logic;             -- low active: debounced feedback: is kb_key_num_o pressed right now?

   signal   key_pressed_n_d : std_logic;
   signal   key_data_s      : std_logic_vector(7 downto 0);

   constant C_KEYCODE_TO_ASCII : string(1 to 80) := "........3W" &
                                                    "A4ZSE.5RD6" &
                                                    "CFTX7YG8BH" &
                                                    "UV9IJ0MKON" &
                                                    "+PL-.:@,.*" &
                                                    ";..=./1..2" &
                                                    " .Q......." &
                                                    "..........";

begin

   m2m_keyb_inst : entity work.m2m_keyb
      port map (
         clk_main_i       => ctrl_clk_i,
         clk_main_speed_i => G_CTRL_HZ,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         powerled_i       => ctrl_led_active_i,
         flopled_i        => ctrl_led_error_i,
         enable_core_i    => '1',
         key_num_o        => key_num,
         key_pressed_n_o  => key_pressed_n,
         qnice_keys_n_o   => open
      ); -- m2m_keyb_inst

   key_data_s <= X"0D" when key_num = 77 else -- special case for ENTER key
                to_stdlogicvector(character'pos(C_KEYCODE_TO_ASCII(key_num + 1)), 8);

   key_proc : process (ctrl_clk_i)
   begin
      if rising_edge(ctrl_clk_i) then
         key_pressed_n_d <= key_pressed_n;

         if ctrl_key_ready_i = '1' then
            ctrl_key_valid_o <= '0';
         end if;

         if ctrl_key_data_o = key_data_s then
            if key_pressed_n = '1' then
               ctrl_key_data_o <= (others => '0');
            end if;
         elsif key_pressed_n_d = '1' and key_pressed_n = '0' then
            ctrl_key_data_o  <= key_data_s;
            ctrl_key_valid_o <= '1';
         end if;

         if ctrl_rst_i = '1' then
            ctrl_key_valid_o <= '0';
            ctrl_key_data_o  <= (others => '0');
         end if;
      end if;
   end process key_proc;

end architecture synthesis;

