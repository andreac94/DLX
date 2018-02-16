library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FP_M_TB is
    generic(
        nbit:       natural:=   32;
        exponent:   natural:=   8;
        mantissa:   natural:=   23
    );
end entity FP_M_TB;

architecture test of FP_M_TB is
    component FP_multiplier is
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
            M:      out         std_logic_vector(nbit-1 downto 0)
        );
    end component FP_multiplier;
    
    signal  clk:    std_logic   :=  '0';
    signal  A:      std_logic_vector(nbit-1 downto 0);
    signal  B:      std_logic_vector(nbit-1 downto 0);
    signal  M:      std_logic_vector(nbit-1 downto 0);

begin

    FPM: FP_multiplier
        generic map(
            nbit        =>  nbit,
            exponent    =>  exponent,
            mantissa    =>  mantissa
        )
        port map(
            clk         =>  clk,
            A           =>  A,
            B           =>  B,
            M           =>  M
        );
    
    clk <=  not clk after 0.5 ns;
    A   <=  "0" & "10000000" & "00000000000000000000000";   -- 2
    B   <=  "1" & "01111111" & "10000000000000000000000";   -- -1.5
        
end architecture test;
