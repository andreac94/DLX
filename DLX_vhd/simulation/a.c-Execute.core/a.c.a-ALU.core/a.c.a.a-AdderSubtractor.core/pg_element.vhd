library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity PG_ELEMENT is
	port(
		Ga:	In	std_logic;
		Gb:	In	std_logic;
		Pa:	In	std_logic;
		Pb:	In	std_logic;
		Go:	Out	std_logic;
		Po:	Out	std_logic
	);

end PG_ELEMENT;


architecture BEHAVIOURAL of PG_ELEMENT is
begin
	Go <= Ga or (Pa and Gb) ;
	Po <= Pa and Pb ;

end BEHAVIOURAL;


configuration CFG_PGEL_BEHAV of PG_ELEMENT is
	for BEHAVIOURAL
	end for;
end CFG_PGEL_BEHAV;
