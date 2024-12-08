--------------------------------------------------------------------------------
-- tyto_utils_pkg.vhd                                                         --
-- Useful functions and procedures etc.                                       --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package tyto_utils_pkg is

  type prng_t is protected
    procedure rand_seed(s1, s2 : in integer);
    impure function rand_real (min, max         : in real    ) return real;
    impure function rand_int  (min, max         : in integer ) return integer;
    impure function rand_slv  (min, max, length : in integer ) return std_ulogic_vector;
  end protected prng_t;

  function ternary (c : boolean; a, b : std_logic) return std_logic;
  function ternary (c : boolean; a, b : std_logic_vector) return std_logic_vector;
  function bool2sl( b : boolean ) return std_ulogic;
  function log2 (x : integer) return integer;
  function reverse(x : std_ulogic_vector) return std_ulogic_vector;
  function mirror(x : std_ulogic_vector) return std_ulogic_vector;
  function add(a,b : std_ulogic_vector) return std_ulogic_vector;
  function sub(a,b : std_ulogic_vector) return std_ulogic_vector;
  function incr(x : std_ulogic_vector) return std_ulogic_vector;
  function decr(x : std_ulogic_vector) return std_ulogic_vector;

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic;
    signal q : out std_ulogic
  );

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic_vector;
    signal q : out std_ulogic_vector
  );

end package tyto_utils_pkg;

library ieee;
  use ieee.math_real.all;

package body tyto_utils_pkg is

  type prng_t is protected body
    variable seed1, seed2 : integer := 0;
    procedure rand_seed(s1, s2 : in integer) is
    begin
      seed1 := s1;
      seed2 := s2;
    end procedure rand_seed;
    impure function rand_real(min, max : in real) return real is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return (r * (max - min)) + min;
    end function rand_real;
    impure function rand_int(min, max : in integer) return integer is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(r * real(max - min) + real(min));
    end function rand_int;
    impure function rand_slv(min, max, length : in integer) return std_ulogic_vector is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return std_ulogic_vector(to_unsigned(integer(r * real(max - min) + real(min)), length));
    end function rand_slv;
  end protected body prng_t;

  function ternary (c : boolean; a, b : std_logic) return std_logic is
  begin
    if c then
      return a;
    else
      return b;
    end if;
  end function ternary;

  function ternary (c : boolean; a, b : std_logic_vector) return std_logic_vector is
  begin
    if c then
      return a;
    else
      return b;
    end if;
  end function ternary;

  function bool2sl( b : boolean ) return std_ulogic is
  begin
    if b then return '1'; else return '0'; end if;
  end function bool2sl;

  function log2 (x : integer) return integer is
    variable i : integer := 0;
  begin
    while 2**i < x loop
      i := i + 1;
    end loop;
    return i;
  end function log2;

  function reverse(x : std_ulogic_vector) return std_ulogic_vector is
    variable y : std_ulogic_vector(x'reverse_range);
  begin
    for i in x'range loop
      y(i) := x(i);
    end loop;
    return y;
  end function reverse;

  function mirror(x : std_ulogic_vector) return std_ulogic_vector is
    variable y : std_ulogic_vector(x'range);
  begin
    for i in x'range loop
      y(i) := x(x'high-i);
    end loop;
    return y;
  end function mirror;

  function add(a,b : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(a)+unsigned(b));
  end function add;

  function sub(a,b : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(a)-unsigned(b));
  end function sub;

  function incr(x : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(x)+1);
  end function incr;

  function decr(x : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(x)-1);
  end function decr;

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic;
    signal q : out std_ulogic
  ) is
  begin
    wait until rising_edge(c);
    q <= d;
  end procedure fd;

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic_vector;
    signal q : out std_ulogic_vector
  ) is
  begin
    wait until rising_edge(c);
    q <= d;
  end procedure fd;

end package body tyto_utils_pkg;
