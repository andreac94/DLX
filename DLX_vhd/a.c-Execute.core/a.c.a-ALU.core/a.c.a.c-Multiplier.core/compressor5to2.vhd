library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;


entity comp5to2 is
  port (
    x1 , x2, x3, x4, x5: IN  std_logic;
    ci1, ci2           : IN  std_logic;
    co1, co2           : OUT std_logic;
    S  , C             : OUT std_logic
  );
end entity; -- comp5to2


architecture behavioral of comp5to2 is

  component mux2to1 is -- when sel=1  out <= in_a
    generic ( N : integer := 1 ); --putting 1 is a simple bitwise mux
    port (
      in_a, in_b : in    std_logic_vector ( N-1 downto 0);
      sel        : in    std_logic;
      output     : out   std_logic_vector ( N-1 downto 0)
    );
  end component; -- mux2to1

  signal s1, s2, s3, s4, s5 : std_logic ;

begin

  s1  <= x1 xor x2;
  s2  <= x4 xor x5;
  
  MUX0: mux2to1
    generic map (1)
    port map (
      in_a(0)   => x3,
      in_b(0)   => x1,
      sel       => s1,
      output(0) => co1
    );
  
  s3 <= s1  xor x3;
  s4 <= s2  xor s3;
  MUX1: mux2to1
    generic map (1)
    port map (
      in_a(0)    => s3,
      in_b(0)    => x4,
      sel        => s2,
      output(0)  => co2
    );
  s5 <= s4 xor ci1;
  S  <= s5 xor ci2;
  
  MUX2: mux2to1
    generic map (1)
    port map (
      in_a(0)    => ci2,
      in_b(0)    => ci1,
      sel        => s5,
      output(0)  => C
    );
end architecture; -- comp5to2
