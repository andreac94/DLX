library ieee; 
use ieee.std_logic_1164.all; 
use work.constants.all;

entity HA is 
	Port(
		In_1:	In	std_logic;
		In_2:	In	std_logic;
		Sum :	Out	std_logic;
		Cout:	Out	std_logic	);
end entity; 

architecture BEHAVIORAL of HA is

begin
	Sum  <=In_1 xor In_2;
	Cout <=In_1 and In_2;
  
end BEHAVIORAL;
