-- Original MEGA65 keyboard driver file by Paul Gardner-Stephen
-- see AUTHORS details and license
--
-- Modified for gbc4mega65 by sy2002 in January 2021
-- Added to MiSTer2MEGA65 based on the modified gbc4mega65 form by sy2002 in July 2021

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity matrix_to_keynum is
   generic (
      G_SCAN_FREQUENCY : integer := 1000
   );
   port (
      clk_i                    : in    std_logic;
      clock_frequency_i        : in    natural;
      reset_in_i               : in    std_logic;

      matrix_col_i             : in    std_logic_vector(7 downto 0);
      matrix_col_idx_i         : in    integer range 0 to 15;

      m65_key_num_o            : out   integer range 0 to 79;
      m65_key_status_n_o       : out   std_logic;

      suppress_key_glitches_i  : in    std_logic;
      suppress_key_retrigger_i : in    std_logic;

      -- Bucky key list:
      -- 0 = left shift
      -- 1 = right shift
      -- 2 = control
      -- 3 = C=
      -- 4 = ALT
      -- 5 = NO SCROLL
      -- 6 = ASC/DIN/CAPS LOCK (XXX - Has a separate line. Not currently monitored)
      bucky_key_o              : out   std_logic_vector(6 downto 0)
   );
end entity matrix_to_keynum;

architecture synthesis of matrix_to_keynum is

   -- Number of the highest key to read from the hardware controller's matrix RAM
   constant C_MAXKEY : integer                                       := 79;

   -- Number of CPU cycles between each key scan event
   signal   keyscan_delay   : natural;
   signal   keyscan_counter : integer                                := 0;

   -- Automatic key repeat (just repeats ascii_key_valid strobe periodically)
   -- (As key repeat is checked on each of the 72 key tests, we don't need to
   -- divide the maximum repeat counters by 72.)
   signal   repeat_key         : integer range 0 to C_MAXKEY         := 0;
   -- signal repeat_start_timer : integer;
   signal   repeat_again_timer : integer;

   signal   ascii_key_valid_countdown : integer range 0 to 65535     := 0;

   signal   repeat_key_timer : integer                               := 0;

   -- This one snoops the input and gets atomically snapshotted at each keyscan interval
   signal   matrix_in : std_logic_vector(C_MAXKEY downto 0);

   signal   matrix             : std_logic_vector(C_MAXKEY downto 0) := (others => '1');
   signal   bucky_key_internal : std_logic_vector(6 downto 0)        := (others => '0');
   signal   matrix_internal    : std_logic_vector(C_MAXKEY downto 0) := (others => '1');

   -- These are the current single output bits from the debounce and last matrix rams
   signal   debounce_key_state : std_logic;
   signal   last_key_state     : std_logic;

   -- This is the current index we are reading from both RAMs (and writing to last)
   signal   ram_read_index      : integer range 0 to 15;
   signal   debounce_write_mask : std_logic_vector(7 downto 0);
   signal   last_write_mask     : std_logic_vector(7 downto 0);

   signal   debounce_in      : std_logic_vector(7 downto 0);
   signal   current_col_out  : std_logic_vector(7 downto 0);
   signal   debounce_col_out : std_logic_vector(7 downto 0);
   signal   last_col_out     : std_logic_vector(7 downto 0);

   signal   repeat_timer_expired : std_logic;

   signal   reset : std_logic                                        := '1';

   signal   key_num : integer range 0 to C_MAXKEY                    := 0;

begin

   -- The clock_frequency of the system is not changing very often. At some cores that switch between
   -- PAL and NTSC, it is for example changing. Therefore we can do the following math combinatorially
   -- as long as we constrain it correctly in the XDC file (for example using False Paths)
   keyscan_delay      <= clock_frequency_i / (72 * G_SCAN_FREQUENCY);
   repeat_again_timer <= clock_frequency_i / G_SCAN_FREQUENCY / 10; -- 0.1 sec

   -- This is our first local copy that gets updated continuously by snooping
   -- the incoming column state from the keymapper.  It exists mostly so we have
   -- an updated copy of the current matrix state we can sample from at our own
   -- pace.
   kb_matrix_ram_current_inst : entity work.kb_matrix_ram
      port map (
         clka_i     => clk_i,
         addressa_i => matrix_col_idx_i,
         dia_i      => matrix_col_i,
         wea_i      => x"FF",
         addressb_i => ram_read_index,
         dob_o      => current_col_out
      ); -- kb_matrix_ram_current_inst

   -- This is a second copy we use for debouncing the input.  It's input is either
   -- the current_col_out (if we're sampling) or the logical and of current_col_out
   -- and debounce_col_out (if we're debouncing)
   kb_matrix_ram_debouce_inst : entity work.kb_matrix_ram
      port map (
         clka_i     => clk_i,
         addressa_i => ram_read_index,
         dia_i      => debounce_in,
         wea_i      => debounce_write_mask,
         addressb_i => ram_read_index,
         dob_o      => debounce_col_out
      ); -- kb_matrix_ram_debouce_inst

   -- This is our third local copy which we use for detecting edges.  It gets
   -- updated as we do the key scan and always remembers the last state of whatever
   -- key we're currently looking at.
   kb_matrix_ram_last_inst : entity work.kb_matrix_ram
      port map (
         clka_i     => clk_i,
         addressa_i => ram_read_index,
         dia_i      => current_col_out,
         wea_i      => last_write_mask,
         addressb_i => ram_read_index,
         dob_o      => last_col_out
      ); -- kb_matrix_ram_last_inst

   -- combinatorial processes
   comb_proc : process (all)
      variable read_index_v       : integer range 0 to 15;
      variable key_num_vec_v      : std_logic_vector(6 downto 0);
      variable key_num_bit_v      : integer range 0 to 7;
      variable key_num_bit_chop_v : unsigned(2 downto 0);
      variable debounce_mask_v    : std_logic_vector(7 downto 0);
      variable last_mask_v        : std_logic_vector(7 downto 0);
      variable dks_v              : std_logic;
      variable lks_v              : std_logic;
   begin
      read_index_v    := 0;
      debounce_mask_v := x"00";
      last_mask_v     := x"00";
      key_num_vec_v   := "0000000";
      key_num_bit_v   := 0;
      dks_v           := '1';
      lks_v           := '1';

      if keyscan_counter /= 0 then
         if keyscan_counter < 11 then
            read_index_v    := keyscan_counter - 1;
            debounce_mask_v := x"FF";
         end if;
         if suppress_key_glitches_i='1' then
            debounce_in <= current_col_out and debounce_col_out;
         else
            debounce_in <= current_col_out;
         end if;
      else
         debounce_in        <= current_col_out;
         key_num_vec_v      := std_logic_vector(to_unsigned(key_num, 7));
         read_index_v       := to_integer(unsigned(key_num_vec_v(6 downto 3)));
         key_num_bit_v      := to_integer(unsigned(key_num_vec_v(2 downto 0)));
         key_num_bit_chop_v := to_unsigned(key_num_bit_v, 7)(2 downto 0);

         case key_num_bit_chop_v is

            when "000" =>
               last_mask_v := "00000001";

            when "001" =>
               last_mask_v := "00000010";

            when "010" =>
               last_mask_v := "00000100";

            when "011" =>
               last_mask_v := "00001000";

            when "100" =>
               last_mask_v := "00010000";

            when "101" =>
               last_mask_v := "00100000";

            when "110" =>
               last_mask_v := "01000000";

            when "111" =>
               last_mask_v := "10000000";

            when others =>
               last_mask_v := x"00";

         end case;

         debounce_mask_v := last_mask_v;
         dks_v           := debounce_col_out(key_num_bit_v);
         lks_v           := last_col_out(key_num_bit_v);
      end if;

      -- update debounce and last bits
      debounce_key_state  <= dks_v;
      last_key_state      <= lks_v;

      -- update other ram input signals
      ram_read_index      <= read_index_v;
      debounce_write_mask <= debounce_mask_v;
      last_write_mask     <= last_mask_v;
   end process comb_proc;

   kbd_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         bucky_key_o <= bucky_key_internal;

         -- Check for key press events
         if keyscan_counter /= 0 then
            keyscan_counter <= keyscan_counter - 1;
         else
            -- Update modifiers
            case key_num is

               when 15 =>
                  bucky_key_internal(0) <= not debounce_key_state; -- LEFT/LOCK_SHIFT

               when 52 =>
                  bucky_key_internal(1) <= not debounce_key_state; -- RIGHT_SHIFT

               when 58 =>
                  bucky_key_internal(2) <= not debounce_key_state; -- CTRL

               when 61 =>
                  bucky_key_internal(3) <= not debounce_key_state; -- MEGA

               when 66 =>
                  bucky_key_internal(4) <= not debounce_key_state; -- ALT

               when 64 =>
                  bucky_key_internal(5) <= not debounce_key_state; -- NO_SCROLL

               -- XXX CAPS LOCK has its own separate line, so is set elsewhere
               when others =>
                  null;

            end case;

            m65_key_num_o      <= key_num;
            m65_key_status_n_o <= debounce_key_state;

            keyscan_counter    <= keyscan_delay;

            if key_num /= C_MAXKEY then
               key_num <= key_num + 1;
            else
               key_num <= 0;
               -- If we hit key_num C_MAXKEY and the repeat key has expired then reset it.
               -- otherwise we set it so we do the repeat check on the next pass and
               -- then reset it.
               if repeat_timer_expired = '1' then
                  repeat_key_timer     <= repeat_again_timer;
                  repeat_timer_expired <= '0';
               elsif repeat_key_timer = 0 then
                  repeat_timer_expired <= '1';
               end if;
            end if;
         end if;
      end if;
   end process kbd_proc;

end architecture synthesis;

