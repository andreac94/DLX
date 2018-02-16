library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.constants.all;
 
entity mux31_unit is
    Port ( S   : in  STD_LOGIC_VECTOR (1 DOWNTO 0);
           A   : in  STD_LOGIC;
           B   : in  STD_LOGIC;
	   C   : in  STD_LOGIC;
	   Y   : out STD_LOGIC);
end mux31_unit;

architecture Behavioral of mux31_unit is
	begin
		Y <= (A and (not S(1)) and (not S(0))) or (B and (not S(1)) and S(0)) or (C and S(1) and (not S(0)));	 
end Behavioral;
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.constants.all;
 
entity mux31 is 
	generic(NBIT:	integer:=  NumBit	);
    Port ( SEL    : in  STD_LOGIC_VECTOR (1 DOWNTO 0);
           in_1   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
           in_2   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
	         in_3   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
	         out_1  : out STD_LOGIC_VECTOR (NBIT-1 downto 0));
end mux31;

architecture Behavioral of mux31 is
	component mux31_unit is    
	Port ( S   : in  STD_LOGIC_VECTOR (1 DOWNTO 0);
               A   : in  STD_LOGIC;
               B   : in  STD_LOGIC;
	       C   : in  STD_LOGIC;
	       Y   : out STD_LOGIC);
	end component;

	begin

	   GEN: for i in 0 to NBIT-1 generate	
		MUX_bit_x  :  mux31_unit 
			Port map ( S   => SEL (1 DOWNTO 0),
               	 A   => in_1(i),
                 B   => in_2(i),
	     			     C   => in_3(i),
	     			     Y   => out_1(i));
	   end generate GEN;

end Behavioral;
