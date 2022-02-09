library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   -- Testbench signals
   constant C_HYPERRAM_FREQ_MHZ : integer := 100;
   constant C_HYPERRAM_PHASE    : real := 162.000;
   constant C_DELAY      : time := 1 ns;

   constant C_CLK_PERIOD : time := (1000/C_HYPERRAM_FREQ_MHZ) * 1 ns;
   signal stop_test      : std_logic := '0';

   signal clk            : std_logic;
   signal clk_x2         : std_logic;
   signal clk_x2_del     : std_logic;
   signal rst            : std_logic;
   signal led_active     : std_logic;
   signal led_error      : std_logic;
   signal start          : std_logic;
   signal start_ready    : std_logic;

   signal sys_resetn     : std_logic;
   signal sys_csn        : std_logic;
   signal sys_ck         : std_logic;
   signal sys_rwds       : std_logic;
   signal sys_dq         : std_logic_vector(7 downto 0);
   signal sys_rwds_out   : std_logic;
   signal sys_dq_out     : std_logic_vector(7 downto 0);
   signal sys_rwds_oe    : std_logic;
   signal sys_dq_oe      : std_logic;

   -- HyperRAM simulation device interface
   signal hr_resetn      : std_logic;
   signal hr_csn         : std_logic;
   signal hr_ck          : std_logic;
   signal hr_rwds        : std_logic;
   signal hr_dq          : std_logic_vector(7 downto 0);


   component s27kl0642 is
      port (
         DQ7      : inout std_logic;
         DQ6      : inout std_logic;
         DQ5      : inout std_logic;
         DQ4      : inout std_logic;
         DQ3      : inout std_logic;
         DQ2      : inout std_logic;
         DQ1      : inout std_logic;
         DQ0      : inout std_logic;
         RWDS     : inout std_logic;
         CSNeg    : in    std_logic;
         CK       : in    std_logic;
         CKn      : in    std_logic;
         RESETNeg : in    std_logic
      );
   end component s27kl0642;

begin

   ---------------------------------------------------------
   -- Controller clock and reset
   ---------------------------------------------------------

   p_clk : process
   begin
      while stop_test = '0' loop
         clk <= '1';
         wait for C_CLK_PERIOD/2;
         clk <= '0';
         wait for C_CLK_PERIOD/2;
      end loop;
      wait;
   end process p_clk;

   p_clk_x2 : process
   begin
      while stop_test = '0' loop
         clk_x2 <= '1';
         wait for C_CLK_PERIOD/4;
         clk_x2 <= '0';
         wait for C_CLK_PERIOD/4;
      end loop;
      wait;
   end process p_clk_x2;

   p_clk_x2_del : process
   begin
      wait for C_CLK_PERIOD/2*(C_HYPERRAM_PHASE/360.0);
      while stop_test = '0' loop
         clk_x2_del <= '1';
         wait for C_CLK_PERIOD/4;
         clk_x2_del <= '0';
         wait for C_CLK_PERIOD/4;
      end loop;
      wait;
   end process p_clk_x2_del;

   p_rst : process
   begin
      rst <= '1';
      wait for 10*C_CLK_PERIOD;
      wait until clk = '1';
      rst <= '0';
      wait;
   end process p_rst;

   p_start_ready : process
   begin
      start_ready <= '0';
      wait for 160 us;
      start_ready <= '1';
      wait until led_active = '1';
      start_ready <= '0';
      wait;
   end process p_start_ready;

   p_start : process (clk)
   begin
      if rising_edge(clk) then
         start <= start_ready;
         if led_active = '1' then
            start <= '0';
         end if;
      end if;
   end process p_start;


   ---------------------------------------------------------
   -- Instantiate DUT
   ---------------------------------------------------------

   i_system : entity work.system
      generic map (
         G_ADDRESS_SIZE => 3
      )
      port map (
         clk_i         => clk,
         clk_x2_i      => clk_x2,
         clk_x2_del_i  => clk_x2_del,
         rst_i         => rst,
         start_i       => start,
         hr_resetn_o   => sys_resetn,
         hr_csn_o      => sys_csn,
         hr_ck_o       => sys_ck,
         hr_rwds_in_i  => sys_rwds,
         hr_dq_in_i    => sys_dq,
         hr_rwds_out_o => sys_rwds_out,
         hr_dq_out_o   => sys_dq_out,
         hr_rwds_oe_o  => sys_rwds_oe,
         hr_dq_oe_o    => sys_dq_oe,
         active_o      => led_active,
         error_o       => led_error
      ); -- i_system

   -- Tri-state buffers
   sys_rwds <= sys_rwds_out when sys_rwds_oe = '1' else 'Z';
   sys_dq   <= sys_dq_out   when sys_dq_oe   = '1' else (others => 'Z');


   ---------------------------------------------------------
   -- Connect controller to device (with delay)
   ---------------------------------------------------------

   hr_resetn <= sys_resetn after C_DELAY;
   hr_csn    <= sys_csn    after C_DELAY;
   hr_ck     <= sys_ck     after C_DELAY;

   i_wiredelay2_rwds : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         A => sys_rwds,
         B => hr_rwds
      );

   gen_dq_delay : for i in 0 to 7 generate
   i_wiredelay2_rwds : entity work.wiredelay2
      generic map (
         G_DELAY => C_DELAY
      )
      port map (
         A => sys_dq(i),
         B => hr_dq(i)
      );
   end generate gen_dq_delay;


   ---------------------------------------------------------
   -- Instantiate HyperRAM simulation model
   ---------------------------------------------------------

   i_s27kl0642 : s27kl0642
      port map (
         DQ7      => hr_dq(7),
         DQ6      => hr_dq(6),
         DQ5      => hr_dq(5),
         DQ4      => hr_dq(4),
         DQ3      => hr_dq(3),
         DQ2      => hr_dq(2),
         DQ1      => hr_dq(1),
         DQ0      => hr_dq(0),
         RWDS     => hr_rwds,
         CSNeg    => hr_csn,
         CK       => hr_ck,
         CKn      => not hr_ck,
         RESETNeg => hr_resetn
      ); -- i_s27kl0642

end architecture simulation;

