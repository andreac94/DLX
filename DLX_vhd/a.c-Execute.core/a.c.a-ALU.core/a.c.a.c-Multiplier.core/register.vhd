LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
use work.constants.all;

ENTITY REG IS
generic (N_BIT       : integer := NumBit );
PORT(
     input_reg  : IN  STD_LOGIC_VECTOR(N_BIT-1 DOWNTO 0); -- input.
     clock      : IN  STD_LOGIC; -- clock.
     output_reg : OUT STD_LOGIC_VECTOR(N_BIT-1 DOWNTO 0)  -- output.
     );
END entity;

ARCHITECTURE REG OF REG IS
BEGIN
 process(clock)
   begin
      if (clock'event and clock='1') then
        output_reg <= input_reg;
      end if;
   end process;
END ARCHITECTURE;
