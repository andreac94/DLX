library IEEE;
use IEEE.std_logic_1164.all;
use work.custom_types.all;
use work.constants.all;

entity CARRY_SELECT_BLOCK is
	generic(
		WIDTH:	integer:=	RCA_width  -- size of individual RCA
	);
	port(
		A:	In	std_logic_vector(WIDTH-1 downto 0);
		B:	In	std_logic_vector(WIDTH-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(WIDTH-1 downto 0)
	);

end CARRY_SELECT_BLOCK;


architecture STRUCTURAL of CARRY_SELECT_BLOCK is

	signal	sum1:	std_logic_vector(WIDTH-1 downto 0);
	signal	sum2:	std_logic_vector(WIDTH-1 downto 0);

	signal	sel:	std_logic;

	component RCA is
		generic(
			NBIT:	integer:=	RCA_WIDTH
		);
		port(
			A:	In	std_logic_vector(NBIT-1 downto 0);
			B:	In	std_logic_vector(NBIT-1 downto 0);
			Ci:	In	std_logic;
			S:	Out	std_logic_vector(NBIT-1 downto 0);
			Co:	Out	std_logic
		);

	end component RCA;

	component MUX is
		generic(
			NBIT:		integer:=	RCA_width
		);
		port(
			A:		In	std_logic_vector(NBIT-1 downto 0);
			B:		In	std_logic_vector(NBIT-1 downto 0);
			sel:		In	std_logic;
			DATA_OUT:	Out	std_logic_vector(NBIT-1 downto 0)
		);

	end component MUX;

begin

	ADD1:	RCA
		generic map(
			NBIT	=>	WIDTH
		)
		port map(
			A	=>	A,
			B	=>	B,
			Ci	=>	'0',
			S	=>	sum1,
			Co	=>	open
		);

	ADD2:	RCA
		generic map(
			NBIT	=>	WIDTH
		)
		port map(
			A	=>	A,
			B	=>	B,
			Ci	=>	'1',
			S	=>	sum2,
			Co	=>	open
		);

	MUX1:	MUX
		generic map(
			NBIT		=>	WIDTH
		)
		port map(
			A		=>	sum1,
			B		=>	sum2,
			sel		=>	Ci,
			DATA_OUT	=>	S
		);

end STRUCTURAL;


configuration CFG_CSB_STRUC of CARRY_SELECT_BLOCK is
	for STRUCTURAL
		for all: RCA
			use configuration WORK.CFG_RCA_STRUC;
		end for;
		for all: MUX
			use configuration WORK.CFG_MUX_BEHAV;
		end for;
	end for;
end CFG_CSB_STRUC;
