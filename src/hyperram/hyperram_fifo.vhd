-- This is part of the HyperRAM Rx connections.
-- It is a general-purpose shallow asynchronuous FIFO.
--
-- Created by Michael Jørgensen in 2023 (mjoergen.github.io/HyperRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity hyperram_fifo is
   generic (
      G_DATA_SIZE : natural
   );
   port (
      src_clk_i   : in    std_logic;
      src_valid_i : in    std_logic;
      src_data_i  : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      dst_clk_i   : in    std_logic;
      dst_valid_o : out   std_logic;
      dst_data_o  : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity hyperram_fifo;

architecture synthesis of hyperram_fifo is

   -- Number of bits in gray-code counters
   constant C_GRAY_SIZE : natural                                         := 3;

   -- Number of words in FIFO
   constant C_FIFO_SIZE : natural                                         := 2 ** (C_GRAY_SIZE - 1);

   -- Dual-port LUTRAM memory to contain the FIFO data
   -- We use LUTRAM instead of registers to save space in the FPGA.
   -- We could use BRAM, but there is a higher delay writing to BRAM than to LUTRAM.
   type     ram_type is array (natural range <>) of std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal   dpram : ram_type(0 to C_FIFO_SIZE - 1);
   attribute ram_style : string;
   attribute ram_style of dpram            : signal is "distributed";

   -- We're using gray codes to avoid glitches when transferring between clock domains.

   -- Write pointer (gray code) in source clock domain
   signal   src_gray_wr : std_logic_vector(C_GRAY_SIZE - 1 downto 0)      := (others => '0');

   -- Write pointer (gray code) in destination clock domain
   signal   dst_gray_wr : std_logic_vector(C_GRAY_SIZE - 1 downto 0)      := (others => '0');

   -- Read pointer (gray code) in destination clock domain
   signal   dst_gray_rd : std_logic_vector(C_GRAY_SIZE - 1 downto 0)      := (others => '0');

   -- Handle CDC
   -- There must additionally be an explicit set_max_delay in the constraint file.
   signal   dst_gray_wr_meta : std_logic_vector(C_GRAY_SIZE - 1 downto 0) := (others => '0');
   attribute async_reg : string;
   attribute async_reg of dst_gray_wr_meta : signal is "true";
   attribute async_reg of dst_gray_wr      : signal is "true";

   -- Convert binary to gray code

   pure function bin2gray (
      b : std_logic_vector
   ) return std_logic_vector is
      variable g_v : std_logic_vector(b'range);
   begin
      g_v(b'left) := b(b'left);

      for i in b'left-1 downto b'right loop
         g_v(i) := b(i + 1) xor b(i);
      end loop;

      return g_v;
   end function bin2gray;

   -- Convert gray code to binary

   pure function gray2bin (
      g : std_logic_vector
   ) return std_logic_vector is
      variable b_v : std_logic_vector(g'range);
   begin
      b_v(g'left) := g(g'left);

      for i in g'left-1 downto g'right loop
         b_v(i) := b_v(i + 1) xor g(i);
      end loop;

      return b_v;
   end function gray2bin;

begin

   -- Dual port memory: One write port, and one read port.
   -- The memory is implemented with LUTRAM. There is no
   -- need for a complete CDC circuit on the output of the LUTRAM, a simple
   -- flip-flop is sufficient. This is because the contents being read from the LUTRAM is
   -- not changing at the time it is sampled. This is due to the CDC causing a (usually) two-cycle
   -- delay between writing to and reading from a given memory location.
   dpram_proc : process (src_clk_i, dst_clk_i)
      variable index_v : natural range 0 to C_FIFO_SIZE - 1;
   begin
      -- Write to memory
      if rising_edge(src_clk_i) then
         if src_valid_i = '1' then
            index_v        := to_integer(gray2bin(src_gray_wr)) mod C_FIFO_SIZE;
            dpram(index_v) <= src_data_i;
         end if;
      end if;

      -- Read from memory
      if rising_edge(dst_clk_i) then
         if dst_gray_wr /= dst_gray_rd then
            index_v    := to_integer(gray2bin(dst_gray_rd)) mod C_FIFO_SIZE;
            dst_data_o <= dpram(index_v);
         end if;
      end if;
   end process dpram_proc;

   -- Update write pointer
   src_proc : process (src_clk_i)
      variable index_v : natural range 0 to C_FIFO_SIZE - 1;
   begin
      if rising_edge(src_clk_i) then
         if src_valid_i = '1' then
            src_gray_wr <= bin2gray(gray2bin(src_gray_wr) + 1);
         end if;
      end if;
   end process src_proc;

   -- Handle CDC explicitly.
   -- We won't use the Xilinx XPM primitive, because that includes a set_false_path.
   -- Instead, we use a set_max_delay in the constraints.
   async_proc : process (dst_clk_i)
   begin
      if rising_edge(dst_clk_i) then
         dst_gray_wr_meta <= src_gray_wr;
         dst_gray_wr      <= dst_gray_wr_meta;
      end if;
   end process async_proc;

   -- Forward data, one word at a time, as soon as the write pointer is different from
   -- the read pointer.
   dst_proc : process (dst_clk_i)
      variable index_v : natural range 0 to C_FIFO_SIZE - 1;
   begin
      if rising_edge(dst_clk_i) then
         dst_valid_o <= '0';

         if dst_gray_wr /= dst_gray_rd then
            dst_gray_rd <= bin2gray(gray2bin(dst_gray_rd) + 1);
            dst_valid_o <= '1';
         end if;
      end if;
   end process dst_proc;

end architecture synthesis;

