library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity exponent_subtractor is
    generic(
        exponent_bits:  natural:=   8;  -- Single Precision floating point by IEEE-754
    );
    port(
        exponent_A:         in  std_logic_vector(exponent_bits-1 downto 0);
        exponent_B:         in  std_logic_vector(exponent_bits-1 downto 0);
        exp_B_gt_exp_A: in  std_logic;
        difference:         out std_logic_vector(exponent_bits-1 downto 0)
    );
end entity exponent_subtractor;

architecture behavioural of exponent_subtractor is
    -- A lot of freedom left to synthetiser to choose implementation of adder, probably RCA.
    -- This adder is small (even if Double Precision is used in hardware support) and no pipeline is likely needed.
    signal  X:  std_logic_vector(exponent_bits-1 downto 0);
    signal  Y:  std_logic_vector(exponent_bits-1 downto 0);
begin
    
    -- If the exponent of A is not smaller than the exponent of B we are subtracting A-B, else we are subtracting B-A.
    -- This means the difference will always be positive and ready to be fed to the shifter.
    X           <=  exponent_A when exp_B_gt_exp_A='0' else exponent_B;
    Y           <=  exponent_B when exp_B_gt_exp_A='0' else exponent_A;
    difference  <=  std_logic_vector(unsigned(X)-unsigned(Y));

end architecture behavioural;
