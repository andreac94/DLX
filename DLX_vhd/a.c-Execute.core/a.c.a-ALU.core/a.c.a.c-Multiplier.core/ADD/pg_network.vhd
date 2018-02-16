library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity PG_NETWORK is
	generic(
		NBIT:	integer:=	NumBit
	);
	port(
		A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		G:	Out	std_logic_vector(NBIT-1 downto 0);
		P:	Out	std_logic_vector(NBIT-1 downto 0)
	);
end PG_NETWORK;

architecture BEHAVIOURAL of PG_NETWORK is
begin

	G(0)			<=	(A(0) and B(0)) or ((A(0) or B(0)) and Ci);
	G(NBIT-1 downto 1)	<=	A(NBIT-1 downto 1) and B(NBIT-1 downto 1);
	P			<=	A or B;

end BEHAVIOURAL;


configuration CFG_PGN_BEHAV of PG_NETWORK is
	for BEHAVIOURAL
	end for;
end configuration CFG_PGN_BEHAV;
