library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FP_D_TB is
    generic(
        nbit:       natural:=   32;
        exponent:   natural:=   8;
        mantissa:   natural:=   23;
        bias:       integer:=   127
    );
end entity FP_D_TB;

architecture test of FP_D_TB is

    component FP_divider is
    generic(
        nbit:       natural:=   32;
        exponent:   natural:=   8;
        mantissa:   natural:=   23;
        bias:       integer:=   127
    );
    port(
        clk:    in          std_logic;
        A:      in          std_logic_vector(nbit-1 downto 0);
        B:      in          std_logic_vector(nbit-1 downto 0);
        D:      out         std_logic_vector(nbit-1 downto 0)
    );
    end component FP_divider;
    
    signal  clk:    std_logic:= '0';
    signal  A:      std_logic_vector(nbit-1 downto 0);
    signal  B:      std_logic_vector(nbit-1 downto 0);
    signal  D:      std_logic_vector(nbit-1 downto 0);

begin

    FPD: FP_divider
        generic map(
            nbit        =>  nbit,
            exponent    =>  exponent,
            mantissa    =>  mantissa
        )
        port map(
            clk         =>  clk,
            A           =>  A,
            B           =>  B,
            D           =>  D
        );
    
    clk <=  not clk after 0.5 ns;
    A   <=  "0" & "11111111" & "00000000000000000000000";   -- inf
    B   <=  "1" & "01111111" & "00000000000000000000000";   -- -1

end architecture test;
