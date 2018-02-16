library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library WORK;
use WORK.complement.all;

entity test_complement is
end entity test_complement;

architecture test of test_complement is
    signal  A       :   std_logic_vector(7 downto 0);
    signal  comp_A  :   std_logic_vector(7 downto 0);

begin

    A       <=  "00000001";     --  1
    comp_A  <=  complement(A);  --  -1: "11111111"

end test;
