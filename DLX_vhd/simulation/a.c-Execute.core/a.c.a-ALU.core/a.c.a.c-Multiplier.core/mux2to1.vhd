library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

entity mux2to1 is
  generic ( N : integer );
  port (
    in_a, in_b : in    std_logic_vector ( N-1 downto 0);
    sel        : in    std_logic;
    output     : out   std_logic_vector ( N-1 downto 0)
  );
end entity; -- mux2to1

architecture Behavioural of mux2to1 is
  begin
    output <= in_a when (sel = '1') else in_b;
    
end architecture; -- mux2to1
