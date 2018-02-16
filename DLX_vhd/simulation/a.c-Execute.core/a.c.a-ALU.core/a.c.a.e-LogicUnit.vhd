library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.dlx_config.all;


entity LogicUnit is
    port(
        A:      in  word;                           -- First operand
        B:      in  word;                           -- Second operand
        op:     in  std_logic_vector(2 downto 0);   -- AND<="000", NAND<="100", OR<="001", NOR<="101", XOR<="010", XNOR<="110"
        O:      out word                            -- Output
    );
end entity LogicUnit;


architecture structural of LogicUnit is

    component T2_Logic is
        generic(
            NBIT : integer := architecture_bits
        );
        port(
            in_1, in_2             : in    std_logic_vector (NBIT-1 downto 0);
            Sel0, Sel1, Sel2, Sel3 : in    std_logic;
            Logic_out              : out   std_logic_vector (NBIT-1 downto 0)
        );
    end component T2_Logic;

    signal  Sel:    std_logic_vector(3 downto 0);
    
begin

    T2L:    T2_Logic
        port map(
            in_1        =>  A,
            in_2        =>  B,
            Sel0        =>  Sel(0),
            Sel1        =>  Sel(1),
            Sel2        =>  Sel(2),
            Sel3        =>  Sel(3),
            Logic_out   =>  O
        );
    
    -- Purpose:         generation of T2_Logic inputs
    -- Type:            combinational
    -- Inputs:          op
    -- Outputs:         Sel
    -- Implementation:  logic network
    sel_gen: process(op)
    begin
        if op = "000" then
            Sel <= "1000";
        elsif op = "100" then
            Sel <=  "0111";
        elsif op = "001" then
            Sel <= "1110";
        elsif op = "101" then
            Sel <= "0001";
        elsif op = "010" then
            Sel <= "0110";
        elsif op = "110" then
            Sel <= "1001";
        end if;
    end process sel_gen;
    
    
end architecture structural;
