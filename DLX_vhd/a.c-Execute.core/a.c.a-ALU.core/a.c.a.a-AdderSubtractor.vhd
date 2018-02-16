library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity AdderSubtractor is
    port(
        A:          in  word;
        B:          in  word;
        sub:        in  std_logic;
        is_signed:  in  std_logic;
        O:          out word;
        overflow:   out std_logic
    );
end entity AdderSubtractor;

architecture structural of AdderSubtractor is
    
    component Adder is
        generic(
            NBIT:   integer:=   architecture_bits;
            WIDTH:  integer:=   4
        );
        port(
            A:  In  std_logic_vector(NBIT-1 downto 0);
            B:  In  std_logic_vector(NBIT-1 downto 0);
            Ci: In  std_logic;
            S:  Out std_logic_vector(NBIT-1 downto 0);
            Co: Out std_logic
        );
    end component Adder;
    
    signal  B_neg:  word;       -- Negation of B, used as input in subtractions (A + not(B) + 1 = A + (-B))
    signal  B_in:   word;       -- Selected B operand, either B or B_neg
    signal  res:    word;       -- Result, internal usage to detect overflow requires a new signal
    signal  Co:     std_logic;  -- Carry out from adder, used to detect overflow
    
begin

    ADD:    Adder
        port map(
            A   =>  A,
            B   =>  B_in,
            Ci  =>  sub,
            S   =>  res,
            Co  =>  Co
        );
    
    B_neg   <=  not(B);
    B_in    <=  B when sub = '0' else
                B_neg;
    
    O       <=  res;
    
    -- Purpose:         detecting overflow
    -- Type:            combinational
    -- Input:           sub, is_signed, res
    -- Output:          overflow
    -- Implementation:  logic
    OVF_P: process(sub, is_signed, res)
    begin
        -- signed addition
        if (is_signed = '1') and (sub = '0') then
            -- both operands have same sign, sum yielding different sign
            if (A(A'high) = B(B'high)) and (res(res'high) /= A(A'high)) then
                overflow    <=  '1';
            -- operands have different sign (no overflow possible) or sum has correct sign
            else
                overflow    <=  '0';
            end if;
        -- signed subtraction
        elsif (is_signed = '1') and (sub = '1') then
            -- operands have different sign, difference not yielding sign of first
            if (A(A'high) /= B(B'high)) and (res(res'high) /= A(A'high)) then
                overflow    <=  '1';
            -- operands have same sign (no overflow possible) or difference has correct sign
            else
                overflow    <=  '0';
            end if;
        -- unsigned addition
        elsif (is_signed = '0') and (sub = '0') then
            -- if carry out is set overflow occurred, if not no overflow occurred
            overflow    <=  Co;
        -- unsigned subtraction
        else
            -- if carry out is not set no wrap occurred and result is greater than first operand
            if Co = '0' then
                overflow    <=  '1';
            -- if carry out is set wrap occurred and result is correct
            else
                overflow    <=  '0';
            end if;
        end if;
    end process OVF_P;

end architecture structural;
