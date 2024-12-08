--------------------------------------------------------------------------------
-- model_hram.vhd                                                             --
-- Simulation model of a HyperRAM device.                                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------
-- assumption: simulator time resolution is 1 ps
-- TODO
--  add wrap and hybrid wrap burst support
--  support RWDS pauses during reads at page/row boundary
--  latch refresh during cycles
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package model_hram_pkg is

  subtype hram_cr_t is std_ulogic_vector(15 downto 0);

  -- HyperRAM parameter bundle type
  -- tXXX reals correspond to nanoseconds
  type hram_params_t is record
    idreg0   : std_ulogic_vector(15 downto 0); -- ID register 0 value
    idreg1   : std_ulogic_vector(15 downto 0); -- ID register 1 value
    cfgreg0  : std_ulogic_vector(15 downto 0); -- configuration register 0 default value
    cfgreg1  : std_ulogic_vector(15 downto 0); -- configuration register 1 default value
    abw      : integer;                        -- address boundary for writes (-1 = none)
    abr      : integer;                        -- address boundary for reads (-1 = none)
    tDRI     : real;                           -- distributed refresh interval
    tVCS     : real;                           -- power on and reset high to first access
    tRP      : real;                           -- reset pulse width, min
    tRH      : real;                           -- reset negation to chip select assertion, min
    tRPH     : real;                           -- reset assertion to chip select assertion, min
    tCK      : real;                           -- clock period, min
    CKHPmin  : real;                           -- half clock period, min
    CKHPmax  : real;                           -- half clock period, min
    tCSHI    : real;                           -- chip select high, min
    tRWR     : real;                           -- read-write recovery time, min
    tCSS     : real;                           -- chip select setup
    tDSVmin  : real;                           -- data strobe valid, min
    tDSVmax  : real;                           -- data strobe valid, max
    tIS      : real;                           -- input setup, min
    tIH      : real;                           -- input hold, min
    tACC     : real;                           -- access, max
    tDQLZmin : real;                           -- clock to DQ low Z, min
    tCKDmin  : real;                           -- clock to DQ valid, min
    tCKDmax  : real;                           -- clock to DQ valid, max
    tCKDImin : real;                           -- clock to DQ invalid, min
    tCKDImax : real;                           -- clock to DQ invalid, max
    tCKDSmin : real;                           -- clock to RDWS valid, min
    tCKDSmax : real;                           -- clock to RDWS valid, max
    tDSSmin  : real;                           -- RDWS to DQ valid, min
    tDSSmax  : real;                           -- RDWS to DQ valid, max
    tDSHmin  : real;                           -- RDWS to DQ hold, min
    tDSHmax  : real;                           -- RDWS to DQ hold, max
    tCSH     : real;                           -- chip select hold, min
    tDSZmin  : real;                           -- chip select inactive to RWDS hi Z, min
    tDSZmax  : real;                           -- chip select inactive to RWDS hi Z, max
    tOZmin   : real;                           -- chip select inactive to DQ hi Z, min
    tOZmax   : real;                           -- chip select inactive to DQ hi Z, max
    tCSM     : real;                           -- chip select, max
    tRFH     : real;                           -- refresh duration
  end record hram_params_t;

  -- timing violation severity bundle type
  type hram_sev_t is record
    tVCS     : severity_level;
    tRP      : severity_level;
    tRH      : severity_level;
    tRPH     : severity_level;
    tCK      : severity_level;
    tCKHPmin : severity_level;
    tCKHPmax : severity_level;
    tCSHI    : severity_level;
    tRWR     : severity_level;
    tCSS     : severity_level;
    tIS      : severity_level;
    tIH      : severity_level;
    tACC     : severity_level;
    tCSH     : severity_level;
    tCSM     : severity_level;
  end record hram_sev_t;

  constant IS66WVH8M8DBLL_100B1LI : hram_params_t := (
    idreg0   => x"0C83",  -- ID register 0 value
    idreg1   => x"0000",  -- ID register 1 value
    cfgreg0  => x"8F1F",  -- configuration register 0 default value
    cfgreg1  => x"0002",  -- configuration register 1 default value
    abw      => -1,       -- address boundary for writes = none
    abr      => -1,       -- address boundary for reads = none
    tDRI     => 4000.0,   -- distributed refresh interval (4 uS)
    tVCS     => 150000.0, -- power on and reset high to first access (150uS)
    tRP      => 200.0,    -- reset pulse width, min
    tRH      => 200.0,    -- reset negation to chip select assertion, min
    tRPH     => 400.0,    -- reset assertion to chip select assertion, min
    tCK      => 10.0,     -- clock period, min
    CKHPmin  => 0.45,     -- half clock period, min
    CKHPmax  => 0.55,     -- half clock period, min
    tCSHI    => 10.0,     -- chip select high, min
    tRWR     => 40.0,     -- read-write recovery time, min
    tCSS     => 3.0,      -- chip select setup
    tDSVmin  => 0.0,      -- data strobe valid, min
    tDSVmax  => 12.0,     -- data strobe valid, max
    tIS      => 1.0,      -- input setup, min
    tIH      => 1.0,      -- input hold, min
    tACC     => 40.0,     -- access, max
    tDQLZmin => 0.0,      -- clock to DQ low Z, min
    tCKDmin  => 1.0,      -- clock to DQ valid, min
    tCKDmax  => 7.0,      -- clock to DQ valid, max
    tCKDImin => 0.5,      -- clock to DQ invalid, min
    tCKDImax => 5.2,      -- clock to DQ invalid, max
    tCKDSmin => 1.0,      -- clock to RDWS valid, min
    tCKDSmax => 7.0,      -- clock to RDWS valid, max
    tDSSmin  => -0.8,     -- RDWS to DQ valid, min
    tDSSmax  => +0.8,     -- RDWS to DQ valid, max
    tDSHmin  => -0.8,     -- RDWS to DQ hold, min
    tDSHmax  => +0.8,     -- RDWS to DQ hold, max
    tCSH     => 3.0,      -- chip select hold, min
    tDSZmin  => 0.0,      -- chip select inactive to RWDS hi Z, min
    tDSZmax  => 7.0,      -- chip select inactive to RWDS hi Z, max
    tOZmin   => 0.0,      -- chip select inactive to DQ hi Z, min
    tOZmax   => 7.0,      -- chip select inactive to DQ hi Z, max
    tCSM     => 4000.0,   -- chip select, max
    tRFH     => 40.0      -- refresh
  );

  -- default severity bundle
  constant HRAM_SEV_DEFAULT : hram_sev_t := (
    tVCS     => failure,
    tRP      => error,
    tRH      => error,
    tRPH     => error,
    tCK      => warning,
    tCKHPmin => warning,
    tCKHPmax => warning,
    tCSHI    => failure,
    tRWR     => failure,
    tCSS     => failure,
    tIS      => failure,
    tIH      => failure,
    tACC     => failure,
    tCSH     => failure,
    tCSM     => failure
  );

  component model_hram is
    generic (
      SIM_MEM_SIZE : integer;
      OUTPUT_DELAY : string        := "MAX_MIN";
      CHECK_TIMING : boolean       := true;
      PARAMS       : hram_params_t;
      SEV          : hram_sev_t    := HRAM_SEV_DEFAULT;
      PREFIX       : string        := "model_hram: "
    );
    port (
      rst_n : inout std_logic;
      cs_n  : in    std_logic;
      clk   : in    std_logic;
      rwds  : inout std_logic;
      dq    : inout std_logic_vector(7 downto 0)
    );
  end component model_hram;

end package model_hram_pkg;

--------------------------------------------------------------------------------

use work.tyto_utils_pkg.all;
use work.model_hram_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity model_hram is
  generic (
    SIM_MEM_SIZE : integer;                           -- size of simulated memory in bytes
    OUTPUT_DELAY : string        := "MAX_MIN";        -- "MIN", "MAX", "MAX_MIN" or "UNIFORM"
    CHECK_TIMING : boolean       := true;
    PARAMS       : hram_params_t;
    SEV          : hram_sev_t    := HRAM_SEV_DEFAULT;
    PREFIX       : string        := "model_hram: "
  );
  port (
    rst_n : inout std_logic;
    cs_n  : in    std_logic;
    clk   : in    std_logic;
    rwds  : inout std_logic;
    dq    : inout std_logic_vector(7 downto 0)
  );
end entity model_hram;

architecture model of model_hram is

  --------------------------------------------------------------------------------

  subtype word_t is std_ulogic_vector(15 downto 0);

  --------------------------------------------------------------------------------

  function real_to_ns(r : real) return time is
  begin
    if r < 1000000.0 then
      return r * 1000.0 * 1 ps;
    else
      return r * 1 ns;
    end if;
  end function real_to_ns;

  --------------------------------------------------------------------------------
  -- build discrete constants from generics (better for linting)

  constant RA_BITS      : integer := to_integer(unsigned(PARAMS.idreg0(12 downto 8))+1);
  constant CA_BITS      : integer := to_integer(unsigned(PARAMS.idreg0( 7 downto 4))+1);
  constant tDRI         : time := real_to_ns( PARAMS.tDRI     );
  constant tVCS         : time := real_to_ns( PARAMS.tVCS     );
  constant tRP          : time := real_to_ns( PARAMS.tRP      );
  constant tRH          : time := real_to_ns( PARAMS.tRH      );
  constant tRPH         : time := real_to_ns( PARAMS.tRPH     );
  constant tCK          : time := real_to_ns( PARAMS.tCK      );
  constant CKHPmin      : real :=             PARAMS.CKHPmin   ;
  constant CKHPmax      : real :=             PARAMS.CKHPmax   ;
  constant tCSHI        : time := real_to_ns( PARAMS.tCSHI    );
  constant tRWR         : time := real_to_ns( PARAMS.tRWR     );
  constant tCSS         : time := real_to_ns( PARAMS.tCSS     );
  constant tDSVmin      : time := real_to_ns( PARAMS.tDSVmin  );
  constant tDSVmax      : time := real_to_ns( PARAMS.tDSVmax  );
  constant tIS          : time := real_to_ns( PARAMS.tIS      );
  constant tIH          : time := real_to_ns( PARAMS.tIH      );
  constant tACC         : time := real_to_ns( PARAMS.tACC     );
  constant tDQLZmin     : time := real_to_ns( PARAMS.tDQLZmin );
  constant tCKDmin      : time := real_to_ns( PARAMS.tCKDmin  );
  constant tCKDmax      : time := real_to_ns( PARAMS.tCKDmax  );
  constant tCKDImin     : time := real_to_ns( PARAMS.tCKDImin ); -- v4p ignore w-303
  constant tCKDImax     : time := real_to_ns( PARAMS.tCKDImax ); -- v4p ignore w-303
  constant tCKDSmin     : time := real_to_ns( PARAMS.tCKDSmin );
  constant tCKDSmax     : time := real_to_ns( PARAMS.tCKDSmax );
  constant tDSSmin      : time := real_to_ns( PARAMS.tDSSmin  );
  constant tDSSmax      : time := real_to_ns( PARAMS.tDSSmax  );
  constant tDSHmin      : time := real_to_ns( PARAMS.tDSHmin  ); -- v4p ignore w-303
  constant tDSHmax      : time := real_to_ns( PARAMS.tDSHmax  ); -- v4p ignore w-303
  constant tCSH         : time := real_to_ns( PARAMS.tCSH     );
  constant tDSZmin      : time := real_to_ns( PARAMS.tDSZmin  );
  constant tDSZmax      : time := real_to_ns( PARAMS.tDSZmax  );
  constant tOZmin       : time := real_to_ns( PARAMS.tOZmin   );
  constant tOZmax       : time := real_to_ns( PARAMS.tOZmax   );
  constant tCSM         : time := real_to_ns( PARAMS.tCSM     );
  constant tRFH         : time := real_to_ns( PARAMS.tRFH     );

  constant SEV_tVCS     : severity_level := SEV.tVCS     ;
  constant SEV_tRP      : severity_level := SEV.tRP      ;
  constant SEV_tRH      : severity_level := SEV.tRH      ;
  constant SEV_tRPH     : severity_level := SEV.tRPH     ;
  constant SEV_tCK      : severity_level := SEV.tCK      ;
  constant SEV_tCKHPmin : severity_level := SEV.tCKHPmin ;
  constant SEV_tCKHPmax : severity_level := SEV.tCKHPmax ;
  constant SEV_tCSHI    : severity_level := SEV.tCSHI    ;
  constant SEV_tRWR     : severity_level := SEV.tRWR     ;
  constant SEV_tCSS     : severity_level := SEV.tCSS     ;
  constant SEV_tIS      : severity_level := SEV.tIS      ;
  constant SEV_tIH      : severity_level := SEV.tIH      ;
  constant SEV_tACC     : severity_level := SEV.tACC     ;
  constant SEV_tCSH     : severity_level := SEV.tCSH     ;
  constant SEV_tCSM     : severity_level := SEV.tCSM     ;

  --------------------------------------------------------------------------------

  type state_por_t is (POR_STD, POR_EXT, POR_DONE);

  type state_t is (
    RESET,   -- reset
    IDLE,    -- idle (cs_n negated)
    CA1,     -- command/address, part 1
    CA2,     -- command/address, part 2
    CA3,     -- command/address, part 3
    LAT,     -- initial latency
    ALAT,    -- additional latency
    WR,      -- write data beat
    RD,      -- read data beat
    UNKNOWN  -- unknown/crazy
  );

  type mem_t is array(0 to (SIM_MEM_SIZE/2)-1) of word_t;

  --------------------------------------------------------------------------------

  -- internal counterparts of external signals
  signal rst_n_i    : std_ulogic;
  signal clk_i      : std_ulogic;
  signal cs_n_i     : std_ulogic;
  signal rwds_i     : std_ulogic;
  signal rwds_o     : std_ulogic;
  signal rwds_oe    : std_ulogic;
  signal dq_i       : std_ulogic_vector(7 downto 0);
  signal dq_o       : std_ulogic_vector(7 downto 0);
  signal dq_oe      : std_ulogic;

  -- internal state
  signal state_por  : state_por_t := POR_STD;
  signal count_hclk : integer := 0;
  signal state      : state_t;
  signal count      : integer := 0;
  signal ca         : std_ulogic_vector(47 downto 0);
  signal addr       : unsigned(31 downto 0);
  signal refresh    : std_ulogic;

  -- configuration registers
  signal cfgreg0 : hram_cr_t := PARAMS.cfgreg0;
  signal cfgreg1 : hram_cr_t := PARAMS.cfgreg1;

  -- simulation visibility
  signal sim_ref  : std_ulogic; -- v4p ignore w-303 | refresh on this cycle

  --------------------------------------------------------------------------------

  function res01x(x : std_ulogic) return std_ulogic is
  begin
    if    x = 'H' or x = '1' then return '1';
    elsif x = 'L' or x = '0' then return '0';
    else  return 'X';
    end if;
  end function res01x;

  function res01x(x : std_ulogic_vector) return std_ulogic_vector is
    variable r : std_ulogic_vector(x'range);
  begin
    for i in x'range loop
      r(i) := res01x(x(i));
    end loop;
    return r;
  end function res01x;

  -- get latency from cfgreg0
  impure function get_lat return integer is
    variable r : integer;
  begin
    r := (to_integer(unsigned(cfgreg0(7 downto 4))+5) mod 16);
    assert r >= 3 and r <= 8
      report PREFIX & "invalid latency value (" & to_string(cfgreg0(7 downto 4)) & ") in CFGREG0" severity failure;
    return r;
  end function get_lat;

  --------------------------------------------------------------------------------

  shared variable prng : prng_t;

  --------------------------------------------------------------------------------

begin

  -- reset pullup
  rst_n <= 'H';

  --------------------------------------------------------------------------------
  -- one-off actions and checks

  P_ONE_OFF: process
  begin
    prng.rand_seed(123,456);
    assert OUTPUT_DELAY = "MIN" or OUTPUT_DELAY = "MAX" or OUTPUT_DELAY = "MAX_MIN" or OUTPUT_DELAY = "UNIFORM"
      report PREFIX & "invalid OUTPUT_DELAY value (" & OUTPUT_DELAY & ")" severity failure;
    -- double check this constraint
    assert RA_BITS >= 12 and RA_BITS <= 16
      report PREFIX & "row address bits (" & integer'image(ra_bits) & ") must be in the range 12..16" severity failure;
    -- double check this constraint
    assert CA_BITS >= 8 and CA_BITS <= 10
      report PREFIX & "column address bits (" & integer'image(ra_bits) & ") must be in the range 8..10" severity failure;
    wait;
  end process P_ONE_OFF;

  --------------------------------------------------------------------------------
  -- external signals

  rst_n_i <= res01x(rst_n);
  clk_i   <= res01x(clk);
  cs_n_i  <= res01x(cs_n);
  rwds    <= 'U' when res01x(rwds_oe) = 'X' else rwds_o when res01x(rwds_oe) = '1' else 'Z';
  rwds_i  <= res01x(rwds);
  dq      <= (others => 'U') when res01x(dq_oe) = 'X' else dq_o when res01x(dq_oe) = '1' else (others => 'Z');
  dq_i    <= res01x(dq);

  --------------------------------------------------------------------------------
  -- POR timing

  P_POR: process
  begin
    if rst_n_i = '0' then
      state_por <= POR_EXT;
      wait until rst_n_i = '1';
      state_por <= POR_STD;
    end if;
    wait for tVCS;
    state_por <= POR_DONE;
    wait;
  end process P_POR;

  --------------------------------------------------------------------------------
  -- timing checks

  P_CHECK: process(all)

    -- timestamps
    variable ts_rst_a   : time := 0 ps; -- reset assertion
    variable ts_rst_n   : time := 0 ps; -- reset negation
    variable ts_cs      : time := 0 ps; -- chip select edge
    variable ts_cs_a    : time := 0 ps; -- chip select edge
    variable ts_cs_n    : time := 0 ps; -- chip select edge
    variable ts_clk     : time := 0 ps; -- most recent clock event
    variable ts_clk_1   : time := 0 ps; -- most recent clock event but one
    variable ts_clk_f   : time := 0 ps; -- clock falling edge
    variable ts_clk_w_m : time := 0 ps; -- clock event for mem write
    variable ts_clk_w_r : time := 0 ps; -- clock event for reg write
    variable ts_rwds    : time := 0 ps; -- rwds event
    variable ts_dq      : time := 0 ps; -- dq event
    variable ts_acc     : time := 0 ps; -- start of access time

    procedure proc_check(
      signal rst_n : in std_ulogic;
      signal clk   : in std_ulogic;
      signal cs_n  : in std_ulogic;
      signal rwds  : in std_ulogic;                   -- v4p ignore w-303
      signal dq    : in std_ulogic_vector(7 downto 0) -- v4p ignore w-303
    ) is
    begin
      --------------------------------------------------------------------------------

      if CHECK_TIMING and now > 0 ps then

        -- check tCK
        if rising_edge(clk) and count_hclk > 1 then
          if now-ts_clk_1 < tCK then
            report PREFIX & "tCK violation - clock period too short:" &
              " measured " & time'image(now-ts_clk_1) &
              " required " & time'image(tCK)
              severity SEV_tCK;
          end if;
        end if;

        -- check tCKHPmin and tCKHPmax
        if clk'event and count_hclk > 1 then
          if now-ts_clk < CKHPmin * (now-ts_clk_1) then
            report PREFIX & "tCK violation - half clock period too short:" &
              " measured " & time'image(now-ts_clk) &
              " required " & time'image(CKHPmin * (now-ts_clk_1))
              severity SEV_tCKHPmin;
          end if;
          if now-ts_clk > CKHPmax * (now-ts_clk_1) then
            report PREFIX & "tCK violation - half clock period too long:" &
              " measured " & time'image(now-ts_clk) &
              " required " & time'image(CKHPmax * (now-ts_clk_1))
              severity SEV_tCKHPmax;
          end if;
        end if;

        -- check tRP (reset pulse width)
        if rising_edge(rst_n) then
          if now-ts_rst_a < tRP then
            report PREFIX & "tRP violation - reset pulse width not met:"
              & " measured " & time'image(now-ts_rst_a)
              & " required " & time'image(tRP)
              severity SEV_tRP;
          end if;
        end if;

        -- check tRH (reset negation to chip select assertion)
        if falling_edge(cs_n) then
          if now-ts_rst_n < tRH then
            report PREFIX & "tRH violation - reset negation to chip select assertion not met:"
              & " measured " & time'image(now-ts_rst_n)
              & " required " & time'image(tRH)
              severity SEV_tRH;
          end if;
        end if;

        -- check tRPH (reset assertion to chip select assertion)
        if falling_edge(cs_n) then
          if now-ts_rst_a < tRPH then
            report PREFIX & "tRPH violation - reset assertion to chip select assertion not met:"
              & " measured " & time'image(now-ts_rst_a)
              & " required " & time'image(tRPH)
              severity SEV_tRPH;
          end if;
        end if;

        if rst_n = '1' then

          -- check tVCS (power on and reset high to first access)
          if falling_edge(cs_n) then
            if state_por /= POR_DONE then
              report PREFIX & "tVCS violation - power on and reset high to first access not met"
                severity SEV_tVCS;
            end if;
          end if;

          -- check tCSHI (CS high time)
          if falling_edge(cs_n) then
            if now-ts_cs_n < tCSHI then
              report PREFIX & "tCSHI violation - chip select high time not met:"
                & " measured " & time'image(now-ts_cs_n)
                & " required " & time'image(tCSHI)
                severity SEV_tCSHI;
            end if;
          end if;

          -- check tCSS (CS to clock setup time)
          if rising_edge(clk) then
            if now-ts_cs < tCSS then
              report PREFIX & "tCSS violation - chip select setup time not met:"
                & " measured " & time'image(now-ts_cs)
                & " required " & time'image(tCSS)
                severity SEV_tCSS;
            end if;
          end if;

          -- check tCSH (clock to CS hold time)
          if cs_n'event then
            if now-ts_clk_f < tCSH then
              report PREFIX & "tCSH violation - chip select hold time not met:"
                & " measured " & time'image(now-ts_clk_f)
                & " required " & time'image(tCSH)
                severity SEV_tCSH;
            end if;
          end if;

          -- check tCSM (CS active time)
          if rising_edge(cs_n) then
            if now-ts_cs_a > tCSM then
              report PREFIX & "tCSM violation - chip select active time exceeded:"
                & " measured " & time'image(now-ts_cs_a)
                & " required " & time'image(tCSM)
                severity SEV_tCSM;
            end if;
          end if;

          -- check tIS (RWDS and DQ to clock setup time)
          if clk'event then
            if state = WR and (now-ts_rwds < tIS) then
              report PREFIX & "tIS violation - RWDS to clock input setup time not met:"
                & " measured " & time'image(now-ts_rwds)
                & " required " & time'image(tIS)
                severity SEV_tIS;
            end if;
            if (count_hclk < 6 or state = WR) and (now-ts_dq < tIS) then
              report PREFIX & "tIS violation - DQ to clock input setup time not met:"
                & " measured " & time'image(now-ts_dq)
                & " required " & time'image(tIS)
                severity SEV_tIS;
            end if;
          end if;

          -- check tIH (clock to RWDS and DQ hold time)
          if rwds'event then
            if (state = WR and ca(46) = '0' and (now-ts_clk_w_m < tIH)) then
              report PREFIX & "tIH violation - clock to RWDS input hold time not met:"
                & " measured " & time'image(now-ts_clk_w_m)
                & " required " & time'image(tIH)
                severity SEV_tIH;
            end if;
            if (state = WR and ca(46) = '1' and (now-ts_clk_w_r < tIH)) then
              report PREFIX & "tIH violation - clock to RWDS input hold time not met:"
                & " measured " & time'image(now-ts_clk_w_r)
                & " required " & time'image(tIH)
                severity SEV_tIH;
            end if;
          end if;
          if dq'event then
            if (count_hclk < 7 or state = WR) and (now-ts_clk < tIH) then
              report PREFIX & "tIH violation - clock to DQ input hold time not met:"
                & " measured " & time'image(now-ts_clk)
                & " required " & time'image(tIH)
                severity SEV_tIH;
            end if;
          end if;

          -- check tRWR
          if falling_edge(clk) and state = CA2 then
            if now-ts_cs_n < tRWR then
              report PREFIX & "tRWR violation - read-write recovery time not met:"
                & " measured " & time'image(now-ts_cs_n)
                & " required " & time'image(tRWR)
                severity SEV_tRWR;
            end if;
          end if;

          -- check tACC (access time)
          if falling_edge(clk) and ca(46) = '0' and state = LAT and count = get_lat-1 then
            if now-ts_acc < tACC then
              report PREFIX & "tACC violation - access time violation:"
                & " measured " & time'image(now-ts_acc)
                & " required " & time'image(tACC)
                severity SEV_tACC;
            end if;
          end if;

        end if;

        -- update timestamps
        if falling_edge ( rst_n ) then  ts_rst_a := now; end if;
        if rising_edge  ( rst_n ) then  ts_rst_n := now; end if;
        if falling_edge ( cs_n  ) then  ts_cs_a  := now; end if;
        if rising_edge  ( cs_n  ) then  ts_cs_n  := now; end if;
        if falling_edge ( clk   ) then  ts_clk_f := now; end if;
        if clk'event  then
          ts_clk_1 := ts_clk;
          ts_clk   := now;
          if state = WR and ca(46) = '0' then ts_clk_w_m := now;  end if;
          if state = WR and ca(46) = '1' then ts_clk_w_r := now; end if;
        end if;
        if cs_n'event then  ts_cs   := now;  end if;
        if rwds'event then  ts_rwds := now;  end if;
        if dq'event   then  ts_dq   := now;  end if;
        if falling_edge(clk) and state = CA2 then
          ts_acc := now;
        end if;

      end if;

      --------------------------------------------------------------------------------
    end procedure proc_check;

  begin

    proc_check(rst_n_i, clk_i, cs_n_i, rwds_i, dq_i);

  end process P_CHECK;

  --------------------------------------------------------------------------------
  -- refresh

  P_REFRESH: process
  begin
    refresh <= '0';
    wait for tDRI-tRFH;
    refresh <= '1';
    wait for tRFH;
  end process P_REFRESH;

  --------------------------------------------------------------------------------

  P_MAIN: process(all)

    variable mem      : mem_t;
    variable alat_req : std_ulogic;
    variable max_min  : boolean := true;
    variable tDSV     : time;
    variable tCKDS    : time;
    variable tCKD     : time;
    variable tDSS     : time;
    variable wm       : std_ulogic_vector(1 downto 0);
    variable wdata    : word_t;
    variable rdata    : word_t;

    procedure handle_event is

      procedure abw_check is
        variable a  : std_ulogic_vector(31 downto 0);
        variable ok : boolean;
      begin
        if count /= 0 and PARAMS.abw /= -1 then
          a  := (ca(44 downto 16),ca(2 downto 0));
          ok := false;
          if PARAMS.abw > 0 then
            ok := unsigned(a(PARAMS.abw-1 downto 0)) /= 0;
          end if;
          assert ok
            report PREFIX & "write address boundary crossed" severity failure;
        end if;
      end procedure abw_check;

      procedure abr_check is
        variable a  : std_ulogic_vector(31 downto 0);
        variable ok : boolean;
      begin
        if count /= 0 and PARAMS.abr /= -1 then
          a  := (ca(44 downto 16),ca(2 downto 0));
          ok := false;
          if PARAMS.abr > 0 then
            ok := unsigned(a(PARAMS.abr-1 downto 0)) /= 0;
          end if;
          assert ok
            report PREFIX & "read address boundary crossed" severity failure;
        end if;
      end procedure abr_check;

    begin
      --------------------------------------------------------------------------------

      if rst_n_i = 'X' or clk_i = 'X' or cs_n_i = 'X' then

        rwds_o     <= 'U';
        rwds_oe    <= 'U';
        dq_o       <= (others => 'U');
        dq_oe      <= 'U';
        count_hclk <= 0;
        count      <= 0;
        ca         <= (others => 'U');
        state      <= UNKNOWN;
        cfgreg0    <= (others => 'U');
        cfgreg1    <= (others => 'U');
        sim_ref    <= 'U';

      elsif rst_n_i = '0' then

        rwds_o     <= 'U';
        rwds_oe    <= '0';
        dq_o       <= (others => 'U');
        dq_oe      <= '0';
        count_hclk <= 0;
        count      <= 0;
        ca         <= (others => 'U');
        state      <= RESET;
        cfgreg0    <= PARAMS.cfgreg0;
        cfgreg1    <= PARAMS.cfgreg1;
        sim_ref    <= '0';

      elsif falling_edge(cs_n_i) then -- start of access

        alat_req := refresh or cfgreg0(3); -- allow for fixed latency
        sim_ref <= alat_req;
        if (OUTPUT_DELAY = "MAX_MIN" and max_min)
        or OUTPUT_DELAY = "MAX"
        then
          tDSV  := tDSVmax  ;
          tCKDS := tCKDSmax ;
          tCKD  := tCKDmax  ;
          tDSS  := tDSSmax  ;
          if tCKD > (tCKDS + tDSS) then
            tCKD := tCKDS + tDSS;
            tCKDS := tCKD - tDSS;
          end if;
        elsif (OUTPUT_DELAY = "MAX_MIN" and not max_min)
        or OUTPUT_DELAY = "MIN"
        then
          tDSV  := tDSVmin  ;
          tCKDS := tCKDSmin ;
          tCKD  := tCKDmin  ;
          tDSS  := tDSSmin  ;
          if tCKD < (tCKDS + tDSS) then
            tCKD := tCKDS + tDSS;
            tCKDS := tCKD - tDSS;
          end if;
        elsif OUTPUT_DELAY = "UNIFORM" then
          tDSV  := real_to_ns(prng.rand_real( PARAMS.tDSVmin  , PARAMS.tDSVmax  ));
          tCKDS := real_to_ns(prng.rand_real( PARAMS.tCKDSmin , PARAMS.tCKDSmax ));
          tCKD  := real_to_ns(prng.rand_real( PARAMS.tCKDmin  , PARAMS.tCKDmax  ));
          tDSS  := real_to_ns(prng.rand_real( PARAMS.tDSSmin  , PARAMS.tDSSmax  ));
          if tCKD - tCKDS < tDSSmin then
            tCKD := tCKDS + tDSSmin;
          elsif tCKD - tCKDS > tDSSmax then
            tCKD := tCKDS + tDSSmax;
          end if;
        end if;
        max_min  := not max_min;
        if tDSV > tDSVmin then
          rwds_o  <= transport 'U' after tDSVmin, alat_req after tDSV;
          rwds_oe <= transport 'U' after tDSVmin, '1' after tDSV;
        else
          rwds_o  <= transport alat_req after tDSV;
          rwds_oe <= transport '1' after tDSV;
        end if;
        state <= CA1;

      elsif rising_edge(clk_i) and cs_n_i = '0' then

        count_hclk <= count_hclk + 1;
        case state is

          when RESET =>
            null;

          when IDLE =>
            null;

          when CA1 =>
            ca(47 downto 40) <= dq_i;

          when CA2 =>
            ca(31 downto 24) <= dq_i;

          when CA3 =>
            ca(15 downto  8) <= dq_i;

          when ALAT =>
            null;

          when LAT =>
            if count = get_lat-1 then
              dq_oe <= transport ca(47) after tDQLZmin; -- drive DQ for reads
              dq_o  <= (others => 'U');
            end if;

          when WR =>
            if rwds_i = '0' then
              abw_check;
            end if;
            wm(1) := rwds_i;
            wdata := (15 downto 8 => dq_i, others => 'U');

          when RD =>
            abr_check;
            rdata := (others => 'U');
            if ca(46) = '1' and unsigned(ca(44 downto 32)) = 0 then
              case ca(31 downto 0) is
                when x"00_00_00_00" => rdata := PARAMS.idreg0;
                when x"00_00_00_01" => rdata := PARAMS.idreg1;
                when x"01_00_00_00" => rdata := cfgreg0;
                when x"01_00_00_01" => rdata := cfgreg1;
                when others         => null;
              end case;
            else
              rdata := mem(to_integer(addr));
            end if;
            rwds_o <= transport '1' after tCKDS;
            dq_o   <= transport rdata(15 downto 8) after tCKD;

          when UNKNOWN =>
            rwds_o  <= 'U';
            rwds_oe <= 'U';
            dq_o    <= (others => 'U');
            dq_oe   <= 'U';

        end case;

      elsif falling_edge(clk_i) and cs_n_i = '0' then

        count_hclk <= count_hclk + 1;
        case state is

          when RESET =>
            null;

          when IDLE =>
            null;

          when CA1 =>
            ca(39 downto 32) <= dq_i;
            state <= CA2;

          when CA2 =>
            ca(23 downto 16) <= dq_i;
            state <= CA3;

          when CA3 =>
            ca( 7 downto  0) <= dq_i;
            if ca(47) = '1' then -- read
              rwds_o <= transport '0' after tCKDS;
            elsif ca(46) = '0' then -- memory write
              rwds_o  <= transport 'U' after tCKDS;
              rwds_oe <= transport 'U' after tDSZmin, '0' after tDSZmax;
            end if;
            if ca(47 downto 46) = "01" then -- register write
              count <= 0;
              state <= WR;
            elsif alat_req then -- additional latency required
              count <= 1;
              state <= ALAT;
            else
              count <= 1;
              state <= LAT;
            end if;

          when ALAT =>
            if count = get_lat-1 then
              count <= 0;
              state <= LAT;
            else
              count <= count + 1;
            end if;

          when LAT =>
            if count = get_lat-1 then
              count <= 0;
              if ca(47) = '1' then
                state <= RD;
              else
                state <= WR;
              end if;
            else
              count <= count + 1;
            end if;

          when WR =>
            if rwds_i = '0' then
              abw_check;
            end if;
            wm(0) := rwds_i;
            wdata(7 downto 0) := dq_i;
            if ca(46) = '1' then
              case ca is
                when x"60_00_01_00_00_00" => cfgreg0 <= wdata;
                when x"60_00_01_00_00_01" => cfgreg1 <= wdata;
                when others               => null;
              end case;
            else
              if wm(0) = '0' then
                mem(to_integer(addr))(7 downto 0) := wdata(7 downto 0);
              end if;
              if wm(1) = '0' then
                mem(to_integer(addr))(15 downto 8) := wdata(15 downto 8);
              end if;
            end if;
            (ca(44 downto 16),ca(2 downto 0)) <= incr((ca(44 downto 16),ca(2 downto 0)));
            count <= count + 1;

          when RD =>
            rwds_o <= transport '0' after tCKDS;
            dq_o   <= transport rdata(7 downto 0) after tCKD;
            (ca(44 downto 16),ca(2 downto 0)) <= incr((ca(44 downto 16),ca(2 downto 0)));
            count <= count + 1;

          when UNKNOWN =>
            rwds_o  <= 'U';
            rwds_oe <= 'U';
            dq_o    <= (others => 'U');
            dq_oe   <= 'U';

        end case;

      elsif rising_edge(cs_n_i) then -- end of access (or initial conditions)

        sim_ref <= '0';
        if rwds_oe = '1' then
          rwds_o  <= transport 'U' after tDSZmin;
          rwds_oe <= transport 'U' after tDSZmin, '0' after tDSZmax;
        end if;
        if dq_oe = '1' then
          dq_o  <= transport (others => 'U') after tOZmin;
          dq_oe <= transport 'U' after tOZmin, '0' after tOZmax;
        end if;
        count_hclk <= 0;
        count      <= 0;
        ca         <= (others => 'U');
        state      <= IDLE;

      end if;

      --------------------------------------------------------------------------------
    end procedure handle_event;

  begin

    handle_event;

  end process P_MAIN;

  addr <= unsigned(ca(44 downto 16)) & unsigned(ca(2 downto 0));

  --------------------------------------------------------------------------------


end architecture model;
