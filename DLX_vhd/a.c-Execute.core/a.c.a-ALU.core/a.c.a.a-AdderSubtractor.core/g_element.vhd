library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity G_ELEMENT is
	port(
		Ga:	In	std_logic;
		Gb:	In	std_logic;
		Pa:	In	std_logic;
		Go:	Out	std_logic
	);

end G_ELEMENT;


architecture BEHAVIOURAL of G_ELEMENT is
begin
	Go <= Ga or (Pa and Gb);

end BEHAVIOURAL;

configuration CFG_GEL_BEHAV of G_ELEMENT is
	for BEHAVIOURAL
	end for;
end CFG_GEL_BEHAV;
