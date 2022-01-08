library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a HyperRAM controller

-- This module operates in a single clock domain. The input clock
-- is the same as the HyperRAM clock.

-- Bit 31 of avm_address_i is used to indicate register space

entity hyperram_ctrl is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;

      -- Avalon Memory Map
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(31 downto 0);
      avm_writedata_i     : in  std_logic_vector(15 downto 0);
      avm_byteenable_i    : in  std_logic_vector(1 downto 0);
      avm_burstcount_i    : in  std_logic_vector(7 downto 0);
      avm_readdata_o      : out std_logic_vector(15 downto 0);
      avm_readdatavalid_o : out std_logic;
      avm_waitrequest_o   : out std_logic;

      -- HyperBus
      hb_rstn_o           : out std_logic;
      hb_ck_ddr_o         : out std_logic_vector(1 downto 0);
      hb_csn_o            : out std_logic;
      hb_dq_ddr_in_i      : in  std_logic_vector(15 downto 0);
      hb_dq_ddr_out_o     : out std_logic_vector(15 downto 0);
      hb_dq_oe_o          : out std_logic;
      hb_rwds_ddr_in_i    : in  std_logic_vector(1 downto 0);
      hb_rwds_ddr_out_o   : out std_logic_vector(1 downto 0);
      hb_rwds_oe_o        : out std_logic
   );
end entity hyperram_ctrl;

architecture synthesis of hyperram_ctrl is

   type state_t is (
      INIT_ST,
      COMMAND_ADDRESS_ST,
      LATENCY_ST,
      READ_ST,
      WRITE_ST,
      RECOVERY_ST
   );

   signal state : state_t;

   signal writedata         : std_logic_vector(15 downto 0);
   signal byteenable        : std_logic_vector(1 downto 0);
   signal read              : std_logic;
   signal burst_count       : integer range 0 to 255;
   signal command_address   : std_logic_vector(47 downto 0);
   signal ca_count          : integer range 0 to 3;
   signal latency_count     : integer range 0 to 15;
   signal read_clk_count    : integer range 0 to 255;
   signal read_return_count : integer range 0 to 255;
   signal write_clk_count   : integer range 0 to 255;
   signal recovery_count    : integer range 0 to 255;

begin

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         hb_rstn_o           <= '1';
         avm_readdatavalid_o <= '0';
         hb_rwds_oe_o        <= '0';
         hb_dq_oe_o          <= '0';

         case state is
            when INIT_ST =>
               if avm_write_i = '1' then
                  avm_waitrequest_o <= '1';
                  state <= WRITE_ST;
               end if;
               if avm_read_i = '1' or avm_write_i = '1' then
                  read            <= avm_read_i;
                  writedata       <= avm_writedata_i;
                  byteenable      <= avm_byteenable_i;
                  burst_count     <= to_integer(unsigned(avm_burstcount_i));

                  command_address <= avm_read_i &                          -- Read
                                     avm_address_i(31) &                   -- Register space
                                     '1' &                                 -- Linear Burst
                                     '0' & avm_address_i(30 downto 3) &    -- Row & Upper Column
                                     "0000000000000" &                     -- Reserved
                                     avm_address_i(2 downto 0);            -- Lower Column
                  avm_waitrequest_o <= '1';
                  hb_csn_o          <= '0';
                  hb_dq_oe_o        <= '1';
                  ca_count          <= 2;
                  state             <= COMMAND_ADDRESS_ST;
               end if;

            when COMMAND_ADDRESS_ST =>
               command_address <= command_address(31 downto 0) & command_address(15 downto 0);

               if ca_count > 0 then
                  hb_dq_oe_o  <= '1';
                  hb_ck_ddr_o <= "10";
                  ca_count    <= ca_count - 1;
               else
                  latency_count <= 12;
                  state         <= LATENCY_ST;
               end if;


            when LATENCY_ST =>
               if latency_count > 0 then
                  latency_count <= latency_count - 1;
               else
                  if read = '1' then
                     read_clk_count    <= burst_count;
                     read_return_count <= burst_count;
                     state             <= READ_ST;
                  else
                     write_clk_count <= burst_count;
                     hb_dq_oe_o      <= '1';
                     hb_rwds_oe_o    <= '1';
                     state           <= WRITE_ST;
                  end if;
               end if;

            when READ_ST =>
               if read_clk_count > 0 then
                  read_clk_count <= read_clk_count - 1;
               else
                  hb_ck_ddr_o <= "00";
               end if;

               if hb_rwds_ddr_in_i = "10" then
                  avm_readdata_o      <= hb_dq_ddr_in_i;
                  avm_readdatavalid_o <= '1';
                  read_return_count <= read_return_count - 1;
                  if read_return_count = 1 then
                     hb_csn_o       <= '1';
                     hb_ck_ddr_o    <= "00";
                     recovery_count <= 3;
                     state          <= RECOVERY_ST;
                  end if;
               end if;

            when WRITE_ST =>
               if write_clk_count > 0 then
                  write_clk_count <= write_clk_count - 1;
                  if write_clk_count = 1 then
                     recovery_count <= 4;
                     state          <= RECOVERY_ST;
                  end if;
               end if;

            when RECOVERY_ST =>
               hb_csn_o    <= '1';
               hb_ck_ddr_o <= "00";
               if recovery_count > 0 then
                  recovery_count <= recovery_count - 1;
               else
                  avm_waitrequest_o <= '0';
                  state             <= INIT_ST;
               end if;
         end case;

         if rst_i = '1' then
            avm_waitrequest_o   <= '0';
            avm_readdatavalid_o <= '0';
            state        <= INIT_ST;
            hb_rstn_o    <= '0';
            hb_ck_ddr_o  <= (others => '0');
            hb_csn_o     <= '1';
            hb_dq_oe_o   <= '0';
            hb_rwds_oe_o <= '0';
         end if;
      end if;
   end process p_fsm;

   hb_dq_ddr_out_o <= writedata when state = WRITE_ST else
                      command_address(47 downto 32);
   hb_rwds_ddr_out_o <= not byteenable when state = WRITE_ST else
                      "00";

end architecture synthesis;

