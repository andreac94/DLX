library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity comparator is
    generic(
        nbit:   natural:=   32;
    );
    port(
        A:      in  std_logic_vector(nbit-1 downto 0);
        B:      in  std_logic_vector(nbit-1 downto 0);
        A_gt_B: out std_logic;
        A_eq_B: out std_logic;
        B_gt_A: out std_logic
    );
end entity comparator;

architecture behavioural of comparator is
begin

    A_gt_B  <=  '1' when unsigned(A)>unsigned(B) else '0';
    A_eq_B  <=  '1' when A=B else '0';
    B_gt_A  <=  '1' when unsigned(A)<unsigned(B) else '0';
    
end architecture behavioural;
