library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity MUX is
	generic(
		NBIT:		integer:=	RCA_width
	);
	port(
		A:		In	std_logic_vector(NBIT-1 downto 0);
		B:		In	std_logic_vector(NBIT-1 downto 0);
		sel:		In	std_logic;
		DATA_OUT:	Out	std_logic_vector(NBIT-1 downto 0)
	);

end MUX;


architecture BEHAVIOURAL of MUX is
begin
		DATA_OUT	<=	A when (sel='0')
					else B;
end BEHAVIOURAL;


configuration CFG_MUX_BEHAV of MUX is
	for BEHAVIOURAL
	end for;
end CFG_MUX_BEHAV;
