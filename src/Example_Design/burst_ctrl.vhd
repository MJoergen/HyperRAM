library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity burst_ctrl is
   port (
      clk_i              : in  std_logic;
      rst_i              : in  std_logic;
      valid_i            : in  std_logic;
      ready_o            : out std_logic;
      valid_o            : out std_logic;
      ready_i            : in  std_logic;
      write_burstcount_o : out std_logic_vector(7 downto 0);
      read_burstcount_o  : out std_logic_vector(7 downto 0)
   );
end entity burst_ctrl;

architecture synthesis of burst_ctrl is

begin

   p_burst_ctrl : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if valid_o = '1' and ready_i = '1' then
            valid_o <= '0';

            if write_burstcount_o /= X"04" then
               write_burstcount_o <= write_burstcount_o(6 downto 0) & "0";
            else
               write_burstcount_o <= X"01";
               if read_burstcount_o /= X"04" then
                  read_burstcount_o <= write_burstcount_o(6 downto 0) & "0";
               else
                  read_burstcount_o <= X"01";
                  valid_o <= '0';
               end if;
            end if;
         end if;

         if valid_i = '1' and ready_o = '1' then
            valid_o <= '1';
         end if;

         if rst_i = '1' then
            valid_o            <= '0';
            ready_o            <= '1';
            write_burstcount_o <= X"01";
            read_burstcount_o  <= X"01";
         end if;

      end if;
   end process p_burst_ctrl;

end architecture synthesis;
