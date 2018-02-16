library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use work.constants.all;
use work.custom_types.all;

--ENTITY DECLARATION
entity XOR_block is
  generic(NBIT : integer:=  NumBit );
  Port(   In_vec : In  std_logic_vector(NBIT-1 downto 0);
          sign   : In  std_logic;
          result : Out std_logic_vector(NBIT-1 downto 0));
end entity;

architecture STRUCTURAL of XOR_block IS
  BEGIN
      XOR_gen : for j in 0 to NBIT-1 generate  
         result(j) <= In_vec(j) XOR sign;
      end generate XOR_gen;
end architecture;
