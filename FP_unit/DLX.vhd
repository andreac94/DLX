library IEEE;
use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity DLX is
    generic(
        D_SIZE:     integer:=   DataSize;           -- data size, default is 32 bits
        I_SIZE:     integer:=   InstructionSize     -- instruction size
    );
    port(
        MEM_BUS:    inout   std_logic_vector(D_SIZE-1 downto 0)
        
    );
end entity DLX;

architecture CUSTOM_STRUCTURAL of DLX is
begin

end architecture CUSTOM_STRUCTURAL;

configuration CFG_CUST_DLX of DLX is
    for CUSTOM_STRUCTURAL
    end for;
end configuration CFG_CUST_DLX;
