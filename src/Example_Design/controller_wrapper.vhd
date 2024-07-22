-- This connects to core design (HyperRAM controller and RAM test) with the MEGA65 R6
-- platform.
-- Its purpose is to simplify the top-level file.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library xpm;
   use xpm.vcomponents.all;

entity controller_wrapper is
   port (
      ctrl_clk_i           : in    std_logic;
      ctrl_rst_i           : in    std_logic;
      -- Connect to core_wrapper
      ctrl_start_o         : out   std_logic;
      ctrl_active_i        : in    std_logic;
      ctrl_stat_total_i    : in    std_logic_vector(31 downto 0);
      ctrl_stat_error_i    : in    std_logic_vector(31 downto 0);
      ctrl_stat_err_addr_i : in    std_logic_vector(31 downto 0);
      ctrl_stat_err_exp_i  : in    std_logic_vector(63 downto 0);
      ctrl_stat_err_read_i : in    std_logic_vector(63 downto 0);
      -- Connect to mega65_wrapper
      ctrl_key_valid_i     : in    std_logic;
      ctrl_key_ready_o     : out   std_logic;
      ctrl_key_data_i      : in    std_logic_vector(7 downto 0);
      ctrl_uart_rx_valid_i : in    std_logic;
      ctrl_uart_rx_ready_o : out   std_logic;
      ctrl_uart_rx_data_i  : in    std_logic_vector(7 downto 0);
      ctrl_uart_tx_valid_o : out   std_logic;
      ctrl_uart_tx_ready_i : in    std_logic;
      ctrl_uart_tx_data_o  : out   std_logic_vector(7 downto 0);
      video_clk_i          : in    std_logic;
      video_rst_i          : in    std_logic;
      video_pos_x_i        : in    std_logic_vector(7 downto 0);
      video_pos_y_i        : in    std_logic_vector(7 downto 0);
      video_char_o         : out   std_logic_vector(7 downto 0);
      video_colors_o       : out   std_logic_vector(15 downto 0)
   );
end entity controller_wrapper;

architecture synthesis of controller_wrapper is

   signal   ctrl_rx_valid : std_logic;
   signal   ctrl_rx_ready : std_logic;
   signal   ctrl_rx_data  : std_logic_vector(7 downto 0);

   type     state_type is (IDLE_ST, BUSY_ST);
   signal   ctrl_state            : state_type := IDLE_ST;
   signal   ctrl_rst_d            : std_logic;
   signal   ctrl_start_valid      : std_logic;
   signal   ctrl_start_ready      : std_logic;
   signal   ctrl_start_data       : std_logic_vector(231 downto 0);
   signal   ctrl_active_d         : std_logic;
   signal   ctrl_result_valid     : std_logic;
   signal   ctrl_result_ready     : std_logic;
   signal   ctrl_result_data      : std_logic_vector(1023 downto 0);
   signal   ctrl_start_ser_valid  : std_logic;
   signal   ctrl_start_ser_ready  : std_logic;
   signal   ctrl_start_ser_data   : std_logic_vector(7 downto 0);
   signal   ctrl_result_ser_valid : std_logic;
   signal   ctrl_result_ser_ready : std_logic;
   signal   ctrl_result_ser_data  : std_logic_vector(7 downto 0);

   constant C_POS_X : natural                  := 10;
   constant C_POS_Y : natural                  := 10;

   signal   video_result_data : std_logic_vector(1023 downto 0);

   -- Convert ASCII string to std_logic_vector

   pure function str2slv (
      str : string
   ) return std_logic_vector is
      variable res_v : std_logic_vector(str'length * 8 - 1 downto 0);
   begin
      --
      for i in 0 to str'length-1 loop
         res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(character'pos(str(str'length - i)), 8);
      end loop;

      return res_v;
   end function str2slv;

   -- Convert std_logic_vector to ASCII

   pure function hexify (
      arg : std_logic_vector
   ) return std_logic_vector is
      variable val_v : integer range 0 to 15;
      variable res_v : std_logic_vector(arg'length * 2 - 1 downto 0);
   begin
      --
      for i in arg'length / 4 - 1 downto 0 loop
         val_v := to_integer(arg(arg'right + 4 * i + 3 downto arg'right + 4 * i));
         if val_v < 10 then
            res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(val_v + character'pos('0'), 8);
         else
            res_v(8 * i + 7 downto 8 * i) := to_stdlogicvector(val_v + character'pos('A') - 10, 8);
         end if;
      end loop;

      return res_v;
   end function hexify;

begin

   --------------------------------------------------------------------------
   -- Merge together Keyboard and UART
   --------------------------------------------------------------------------

   axi_merger_inst : entity work.axi_merger
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => ctrl_clk_i,
         rst_i      => ctrl_rst_i,
         s1_ready_o => ctrl_key_ready_o,
         s1_valid_i => ctrl_key_valid_i,
         s1_data_i  => ctrl_key_data_i,
         s2_ready_o => ctrl_uart_rx_ready_o,
         s2_valid_i => ctrl_uart_rx_valid_i,
         s2_data_i  => ctrl_uart_rx_data_i,
         m_ready_i  => ctrl_rx_ready,
         m_valid_o  => ctrl_rx_valid,
         m_data_o   => ctrl_rx_data
      ); -- axi_merger_inst


   --------------------------------------------------------------------------
   -- Determine start of test
   --------------------------------------------------------------------------

   ctrl_rx_ready    <= '1' when ctrl_state = IDLE_ST else
                       '0';

   uart_rx_proc : process (ctrl_clk_i)
   begin
      if rising_edge(ctrl_clk_i) then
         if ctrl_active_i = '1' then
            ctrl_start_o <= '0';
         end if;

         case ctrl_state is

            when IDLE_ST =>
               if ctrl_rx_valid = '1' then
                  ctrl_start_o <= '1';
                  ctrl_state   <= BUSY_ST;
               end if;

            when BUSY_ST =>
               if ctrl_active_i = '0' and ctrl_start_o = '0' then
                  ctrl_state <= IDLE_ST;
               end if;

         end case;

         if ctrl_rst_i = '1' then
            ctrl_start_o <= '0';
            ctrl_state   <= IDLE_ST;
         end if;
      end if;
   end process uart_rx_proc;


   --------------------------------------------------------------------------
   -- Generate output text after reset
   --------------------------------------------------------------------------

   ctrl_start_proc : process (ctrl_clk_i)
   begin
      if rising_edge(ctrl_clk_i) then
         ctrl_rst_d <= ctrl_rst_i;
         if ctrl_start_ready = '1' then
            ctrl_start_valid <= '0';
         end if;
         if ctrl_rst_d = '1' and ctrl_rst_i = '0' then
            ctrl_start_valid <= '1';
         end if;
      end if;
   end process ctrl_start_proc;

   ctrl_start_data  <= X"0D0A" & str2slv("HyperRAM Example Design") & X"0D0A" & X"0D0A";


   --------------------------------------------------------------------------
   -- Generate output text after test completion
   --------------------------------------------------------------------------

   ctrl_result_proc : process (ctrl_clk_i)
   begin
      if rising_edge(ctrl_clk_i) then
         ctrl_active_d <= ctrl_active_i;
         if ctrl_result_ready = '1' then
            ctrl_result_valid <= '0';
         end if;
         -- Trigger on falling edge
         if ctrl_active_d = '1' and ctrl_active_i = '0' then
            ctrl_result_valid <= '1';
         end if;
         if ctrl_rst_i = '1' then
            ctrl_result_valid <= '0';
         end if;
      end if;
   end process ctrl_result_proc;

   ctrl_result_data <= str2slv("TOTAL:  ") & hexify(ctrl_stat_total_i) & X"0D0A" &
                       str2slv("ERRORS: ") & hexify(ctrl_stat_error_i) & X"0D0A" &
                       str2slv("ADDR:   ") & hexify(ctrl_stat_err_addr_i) & X"0D0A" &
                       str2slv("EXP_HI: ") & hexify(ctrl_stat_err_exp_i(63 downto 32)) & X"0D0A" &
                       str2slv("EXP_LO: ") & hexify(ctrl_stat_err_exp_i(31 downto 0)) & X"0D0A" &
                       str2slv("READ_HI:") & hexify(ctrl_stat_err_read_i(63 downto 32)) & X"0D0A" &
                       str2slv("READ_LO:") & hexify(ctrl_stat_err_read_i(31 downto 0)) & X"0D0A" &
                       X"0D0A";


   --------------------------------------------------------------------------
   -- Serialize and merge output text to UART
   --------------------------------------------------------------------------

   serializer_start_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => ctrl_start_data'length,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => ctrl_clk_i,
         rst_i     => ctrl_rst_i,
         s_valid_i => ctrl_start_valid,
         s_ready_o => ctrl_start_ready,
         s_data_i  => ctrl_start_data,
         m_valid_o => ctrl_start_ser_valid,
         m_ready_i => ctrl_start_ser_ready,
         m_data_o  => ctrl_start_ser_data
      ); -- serializer_start_inst

   serializer_result_inst : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => ctrl_result_data'length,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => ctrl_clk_i,
         rst_i     => ctrl_rst_i,
         s_valid_i => ctrl_result_valid,
         s_ready_o => ctrl_result_ready,
         s_data_i  => ctrl_result_data,
         m_valid_o => ctrl_result_ser_valid,
         m_ready_i => ctrl_result_ser_ready,
         m_data_o  => ctrl_result_ser_data
      ); -- serializer_result_inst

   merginator_inst : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => ctrl_clk_i,
         rst_i      => ctrl_rst_i,
         s1_valid_i => ctrl_start_ser_valid,
         s1_ready_o => ctrl_start_ser_ready,
         s1_data_i  => ctrl_start_ser_data,
         s2_valid_i => ctrl_result_ser_valid,
         s2_ready_o => ctrl_result_ser_ready,
         s2_data_i  => ctrl_result_ser_data,
         m_valid_o  => ctrl_uart_tx_valid_o,
         m_ready_i  => ctrl_uart_tx_ready_i,
         m_data_o   => ctrl_uart_tx_data_o
      ); -- merginator_inst


   --------------------------------------------------------------------------
   -- Display result text on video output
   --------------------------------------------------------------------------

   xpm_cdc_array_single_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => ctrl_result_data'length
      )
      port map (
         src_clk  => ctrl_clk_i,
         src_in   => ctrl_result_data,
         dest_clk => video_clk_i,
         dest_out => video_result_data
      ); -- xpm_cdc_array_single_inst

   video_proc : process (video_clk_i)
      variable col_v   : natural range 0 to 15;
      variable row_v   : natural range 0 to 6;
      variable index_v : natural range 0 to ctrl_result_data'length / 8 - 1;
   begin
      if rising_edge(video_clk_i) then
         video_char_o   <= X"20";
         video_colors_o <= X"55BB";
         if video_pos_x_i >= C_POS_X and video_pos_x_i < C_POS_X + 16 and
            video_pos_y_i >= C_POS_Y and video_pos_y_i < C_POS_Y + 7 then
            col_v        := 15 - to_integer(video_pos_x_i - C_POS_X);
            row_v        := 6 - to_integer(video_pos_y_i - C_POS_Y);
            index_v      := row_v * 18 + col_v + 4;
            video_char_o <= video_result_data(index_v * 8 + 7 downto index_v * 8);
         end if;
      end if;
   end process video_proc;

end architecture synthesis;

