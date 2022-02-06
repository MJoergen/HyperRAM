library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This is a HyperRAM controller.

-- Bit 31 of avm_address_i is used to indicate register space.

-- The datawidth is fixed at 16 bits.
-- The address is word-based, i.e. units of 2 bytes.

-- This module requires three clocks:
-- clk_i    : 100 MHz. This is the main clock used for the Avalon MM interface
--            as well as controlling the HyperRAM device.
-- clk_90_i : 100 MHz delayed 90 degrees (quarter cycle). Used for I/O to
--            HyperRAM device.
-- clk_x2_i :_200 MHz. Used for I/O to HyperRAM device.

entity hyperram is
   port (
      clk_i               : in  std_logic; -- Main clock
      clk_90_i            : in  std_logic; -- Physical I/O only
      clk_x2_i            : in  std_logic; -- Physical I/O only
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

      -- HyperRAM device interface
      hr_resetn_o         : out std_logic;
      hr_csn_o            : out std_logic;
      hr_ck_o             : out std_logic;
      hr_rwds_in_i        : in  std_logic;
      hr_dq_in_i          : in  std_logic_vector(7 downto 0);
      hr_rwds_out_o       : out std_logic;
      hr_dq_out_o         : out std_logic_vector(7 downto 0);
      hr_rwds_oe_o        : out std_logic;
      hr_dq_oe_o          : out std_logic
   );
end entity hyperram;

architecture synthesis of hyperram is

   signal ctrl_rstn         : std_logic;
   signal ctrl_ck_ddr       : std_logic_vector(1 downto 0);
   signal ctrl_csn          : std_logic;
   signal ctrl_dq_ddr_in    : std_logic_vector(15 downto 0);
   signal ctrl_dq_ddr_out   : std_logic_vector(15 downto 0);
   signal ctrl_dq_oe        : std_logic;
   signal ctrl_dq_ie        : std_logic;
   signal ctrl_rwds_ddr_out : std_logic_vector(1 downto 0);
   signal ctrl_rwds_oe      : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate HyperRAM controller
   --------------------------------------------------------

   i_hyperram_ctrl : entity work.hyperram_ctrl
      port map (
         clk_i                => clk_i,
         rst_i                => rst_i,
         avm_write_i          => avm_write_i,
         avm_read_i           => avm_read_i,
         avm_address_i        => avm_address_i,
         avm_writedata_i      => avm_writedata_i,
         avm_byteenable_i     => avm_byteenable_i,
         avm_burstcount_i     => avm_burstcount_i,
         avm_readdata_o       => avm_readdata_o,
         avm_readdatavalid_o  => avm_readdatavalid_o,
         avm_waitrequest_o    => avm_waitrequest_o,
         hb_rstn_o            => ctrl_rstn,
         hb_ck_ddr_o          => ctrl_ck_ddr,
         hb_csn_o             => ctrl_csn,
         hb_dq_ddr_in_i       => ctrl_dq_ddr_in,
         hb_dq_ddr_out_o      => ctrl_dq_ddr_out,
         hb_dq_oe_o           => ctrl_dq_oe,
         hb_dq_ie_i           => ctrl_dq_ie,
         hb_rwds_ddr_out_o    => ctrl_rwds_ddr_out,
         hb_rwds_oe_o         => ctrl_rwds_oe
      ); -- i_hyperram_ctrl


   --------------------------------------------------------
   -- Instantiate HyperRAM I/O
   --------------------------------------------------------

   i_hyperram_io : entity work.hyperram_io
      port map (
         clk_i               => clk_i,
         clk_90_i            => clk_90_i,
         clk_x2_i            => clk_x2_i,
         rst_i               => rst_i,
         ctrl_rstn_i         => ctrl_rstn,
         ctrl_ck_ddr_i       => ctrl_ck_ddr,
         ctrl_csn_i          => ctrl_csn,
         ctrl_dq_ddr_in_o    => ctrl_dq_ddr_in,
         ctrl_dq_ddr_out_i   => ctrl_dq_ddr_out,
         ctrl_dq_oe_i        => ctrl_dq_oe,
         ctrl_dq_ie_o        => ctrl_dq_ie,
         ctrl_rwds_ddr_out_i => ctrl_rwds_ddr_out,
         ctrl_rwds_oe_i      => ctrl_rwds_oe,
         hr_resetn_o         => hr_resetn_o,
         hr_csn_o            => hr_csn_o,
         hr_ck_o             => hr_ck_o,
         hr_rwds_in_i        => hr_rwds_in_i,
         hr_dq_in_i          => hr_dq_in_i,
         hr_rwds_out_o       => hr_rwds_out_o,
         hr_dq_out_o         => hr_dq_out_o,
         hr_rwds_oe_o        => hr_rwds_oe_o,
         hr_dq_oe_o          => hr_dq_oe_o
      ); -- i_hyperram_io

end architecture synthesis;

