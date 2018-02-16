library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.dlx_config.all;

entity TB_LogicUnit is
end entity TB_LogicUnit;

architecture test of TB_LogicUnit is

    component LogicUnit is
        port(
            A:      in  word;                           -- First operand
            B:      in  word;                           -- Second operand
            op:     in  std_logic_vector(2 downto 0);   -- AND<="000", NAND<="100", OR<="001", NOR<="101", XOR<="010", XNOR<="110"
            O:      out word                            -- Output
        );
    end component LogicUnit;
    
    signal  A:  word;
    signal  B:  word;
    signal  op: std_logic_vector(2 downto 0);
    signal  O:  word;

begin

    UUT:    LogicUnit
        port map(
            A   =>  A,
            B   =>  B,
            op  =>  op,
            O   =>  O
        );
    
    stim:   process
    begin
        A   <=  X"ffffffff";    -- All ones
        B   <=  X"00000000";    -- All zeroes
        -- AND  =>  X"00000000"
        op  <=  "000";
        wait for 10 ns;
        -- NAND =>  X"11111111"
        op  <=  "100";
        wait for 10 ns;
        -- OR   =>  X"11111111"
        op  <=  "001";
        wait for 10 ns;
        -- NOR  =>  X"00000000"
        op  <=  "101";
        wait for 10 ns;
        -- XOR  =>  X"11111111"
        op  <=  "010";
        wait for 10 ns;
        -- XNOR =>  X"00000000"
        op  <=  "110";
        wait;
    end process stim;

end architecture test;
