-- Original MEGA65 keyboard driver file by Paul Gardner-Stephen
-- see AUTHORS details and license
--
-- Modified for gbc4mega65 by sy2002 in January 2021
-- Added to MiSTer2MEGA65 based on the modified gbc4mega65 form by sy2002 in July 2021

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity mega65kbd_to_matrix is
   port (
      ioclock_i         : in    std_logic;
      clock_frequency_i : in    natural;

      flopmotor_i       : in    std_logic;
      flopled_i         : in    std_logic;
      powerled_i        : in    std_logic;

      kio8_o            : out   std_logic; -- clock to keyboard
      kio9_o            : out   std_logic; -- data output to keyboard
      kio10_i           : in    std_logic; -- data input from keyboard

      matrix_col_o      : out   std_logic_vector(7 downto 0);
      matrix_col_idx_i  : in    integer range 0 to 9;

      delete_out_o      : out   std_logic;
      return_out_o      : out   std_logic;
      fastkey_out_o     : out   std_logic;

      -- RESTORE and capslock are active low
      restore_o         : out   std_logic;
      capslock_out_o    : out   std_logic;

      -- LEFT and UP cursor keys are active HIGH
      leftkey_o         : out   std_logic;
      upkey_o           : out   std_logic
   );
end entity mega65kbd_to_matrix;

architecture synthesis of mega65kbd_to_matrix is

   signal matrix_col   : std_logic_vector(7 downto 0)     := (others => '1');
   signal restore      : std_logic                        := '1';
   signal capslock_out : std_logic                        := '1';
   signal leftkey      : std_logic                        := '0';
   signal upkey        : std_logic                        := '0';

   signal matrix_ram_offset : integer range 0 to 15       := 0;
   signal keyram_wea        : std_logic_vector(7 downto 0);
   signal keyram_dia        : std_logic_vector(7 downto 0);
   signal matrix_dia        : std_logic_vector(7 downto 0);

   signal enabled : std_logic                             := '0';

   signal clock_divider        : integer range 0 to 65535 := 0;
   signal clock_divider_target : integer range 0 to 65535;

   signal kbd_clock  : std_logic                          := '0';
   signal phase      : integer range 0 to 255             := 0;
   signal sync_pulse : std_logic                          := '0';

   signal counter : unsigned(26 downto 0)                 := to_unsigned(0, 27);

   signal output_vector : std_logic_vector(127 downto 0);

   signal deletekey : std_logic                           := '1';
   signal returnkey : std_logic                           := '1';
   signal fastkey   : std_logic                           := '1';

begin  -- behavioural

   -- @TODO as of December 2022 (by sy2002): We need to find a smarter solution. This only works well
   -- as long as we only have one constant core frequency; otherwise a large combinatorial net will be
   -- created and we would need to add false-paths to the XDC (see also lines 90+ in matrix_to_keynum.vhd)
   -- In the original MEGA65 code, the value is 64 for a 40 MHz clock, i.e. (40000000/64/2) 312.500 Hz.
   -- Let's make sure approximate this value well enough.
   clock_divider_target <= clock_frequency_i / 2 / 312500;

   matrix_col_o         <= matrix_col;
   restore_o            <= restore;
   capslock_out_o       <= capslock_out;
   leftkey_o            <= leftkey;
   upkey_o              <= upkey;

   kb_matrix_ram_inst : entity work.kb_matrix_ram
      port map (
         clka_i     => ioclock_i,
         addressa_i => matrix_ram_offset,
         dia_i      => matrix_dia,
         wea_i      => keyram_wea,
         addressb_i => matrix_col_idx_i,
         dob_o      => matrix_col
      ); -- kb_matrix_ram_inst

   kbd_proc : process (ioclock_i)
      variable keyram_write_enable_v : std_logic_vector(7 downto 0);
      variable keyram_offset_v       : integer range 0 to 15 := 0;
      variable keyram_offset_tmp_v   : std_logic_vector(2 downto 0);
   begin
      if rising_edge(ioclock_i) then
         ------------------------------------------------------------------------
         -- Read from MEGA65R2 keyboard
         ------------------------------------------------------------------------
         -- Process is to run a clock at a modest rate, and periodically send
         -- a sync pulse, and clock in the key states, while clocking out the
         -- LED states.

         delete_out_o          <= deletekey;
         return_out_o          <= returnkey;
         fastkey_out_o         <= fastkey;

         -- Counter is for working out drive LED blink phase
         counter               <= counter + 1;

         -- Default is no write nothing at offset zero into the matrix ram.
         keyram_write_enable_v := x"00";
         keyram_offset_v       := 0;

         -- modified by sy2002 in December 2022
         if clock_divider /= clock_divider_target then
            clock_divider <= clock_divider + 1;
         else
            clock_divider <= 0;

            kbd_clock     <= not kbd_clock;
            kio8_o        <= kbd_clock or sync_pulse;

            if kbd_clock='1' and phase < 128 then
               keyram_offset_v := phase / 8;

               -- Receive keys with dedicated lines
               if phase = 72 then
                  capslock_out <= kio10_i;
               end if;
               if phase = 73 then
                  upkey <= not kio10_i;
               end if;
               if phase = 74 then
                  leftkey <= not kio10_i;
               end if;
               if phase = 75 then
                  restore <= kio10_i;
               end if;
               if phase = 76 then
                  deletekey <= kio10_i;
               end if;
               if phase = 77 then
                  returnkey <= kio10_i;
               end if;
               if phase = 78 then
                  fastkey <= kio10_i;
               end if;

               -- Work around the data arriving 2 cycles late from the keyboard controller
               if phase = 0 then
                  matrix_dia <= (others => deletekey);
               elsif phase = 1 then
                  matrix_dia <= (others => returnkey);
               else
                  matrix_dia <= (others => kio10_i); -- present byte of input bits to
               -- ram for writing
               end if;


               -- report "Writing received bit " & std_logic'image(kio10) & " to bit position " & integer'image(phase);

               case (phase mod 8) is

                  when 0 =>
                     keyram_write_enable_v := x"01";

                  when 1 =>
                     keyram_write_enable_v := x"02";

                  when 2 =>
                     keyram_write_enable_v := x"04";

                  when 3 =>
                     keyram_write_enable_v := x"08";

                  when 4 =>
                     keyram_write_enable_v := x"10";

                  when 5 =>
                     keyram_write_enable_v := x"20";

                  when 6 =>
                     keyram_write_enable_v := x"40";

                  when 7 =>
                     keyram_write_enable_v := x"80";

                  when others =>
                     null;

               end case;

            end if;
            matrix_ram_offset <= keyram_offset_v;
            keyram_wea        <= keyram_write_enable_v;

            if kbd_clock='0' then
               -- report "phase = " & integer'image(phase) & ", sync=" & std_logic'image(sync_pulse);
               if phase /= 140 then
                  phase <= phase + 1;
               else
                  phase <= 0;
               end if;
               if phase = 127 then
                  -- Reset to start
                  sync_pulse    <= '1';
                  output_vector <= (others => '0');
                  if flopmotor_i='1' or flopled_i='1' then
                     output_vector(23 downto 0)  <= x"00FF00";
                     output_vector(47 downto 24) <= x"00FF00";
                  end if;
                  if powerled_i='1' then
                     output_vector(71 downto 48) <= x"00FF00";
                     output_vector(95 downto 72) <= x"00FF00";
                  end if;
               elsif phase = 140 then
                  sync_pulse <= '0';
               elsif phase < 127 then
                  -- Output next bit
                  kio9_o                      <= output_vector(127);
                  output_vector(127 downto 1) <= output_vector(126 downto 0);
                  output_vector(0)            <= '0';
               end if;
            end if;
         end if;
      end if;
   end process kbd_proc;

end architecture synthesis;

