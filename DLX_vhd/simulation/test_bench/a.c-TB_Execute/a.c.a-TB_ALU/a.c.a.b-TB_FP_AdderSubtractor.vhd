library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TB_FP_AdderSubtractor is
    generic(
        nbit:       natural:=   32;
        exponent:   natural:=   8;
        mantissa:   natural:=   23
    );
end entity TB_FP_AdderSubtractor;

architecture test of TB_FP_AdderSubtractor is
    
    component FP_AdderSubtractor is
        generic(
            nbit:       natural:=   32;
            exponent:   natural:=   8;
            mantissa:   natural:=   23
        );
        port(
            A:      in          std_logic_vector(nbit-1 downto 0);
            B:      in          std_logic_vector(nbit-1 downto 0);
            sub:    in          std_logic;
            S:      out         std_logic_vector(nbit-1 downto 0)
        );
    end component FP_AdderSubtractor;
    
    signal  clk:    std_logic   :=  '0';
    signal  A:      std_logic_vector(nbit-1 downto 0);
    signal  B:      std_logic_vector(nbit-1 downto 0);
    signal  sub:    std_logic;
    signal  S:      std_logic_vector(nbit-1 downto 0);

begin

    FPAS: FP_AdderSubtractor
        generic map(
            nbit        =>  nbit,
            exponent    =>  exponent,
            mantissa    =>  mantissa
        )
        port map(
            A           =>  A,
            B           =>  B,
            sub         =>  sub,
            S           =>  S
        );
    
    clk <=  not clk after 0.5 ns;
    A   <=  "0" & "00001000" & "00000000000000000000000"; -- 1.0 * 2^8 
    B   <=  "0" & "11111111" & "00000000000000000000000"; -- Inf
    process
    begin
        sub <=  '1';
        wait for 5 ns;
        sub <=  '0';
        wait;
    end process;

end architecture test;
