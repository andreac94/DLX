library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity CARRY_SELECT_SUM_GENERATOR is
	generic(
		NBIT:	integer:=	NumBit;
		WIDTH:	integer:=	RCA_width
	);
	port(
		A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic_vector(NBIT/WIDTH-1 downto 0);
		S:	Out	std_logic_vector(NBIT-1 downto 0)
	);

end CARRY_SELECT_SUM_GENERATOR;


architecture STRUCTURAL of CARRY_SELECT_SUM_GENERATOR is

	component CARRY_SELECT_BLOCK is
		generic(
			WIDTH:	integer:=	4
		);
		port(
			A:	In	std_logic_vector(WIDTH-1 downto 0);
			B:	In	std_logic_vector(WIDTH-1 downto 0);
			Ci:	In	std_logic;
			S:	Out	std_logic_vector(WIDTH-1 downto 0)
		);

	end component CARRY_SELECT_BLOCK;

begin

	GENERATE_BLOCKS: for I in NBIT/WIDTH-1 downto 0 generate
		GENERATE_LAST:	if I=(NBIT/WIDTH)-1 generate
			CSBI:	CARRY_SELECT_BLOCK
				generic map(
					WIDTH => WIDTH
				)
				port map(
					A	=>	A((I+1)*WIDTH-1 downto I*WIDTH),
					B	=>	B((I+1)*WIDTH-1 downto I*WIDTH),
					Ci	=>	Ci(I),
					S	=>	S((I+1)*WIDTH-1 downto I*WIDTH)
				);
		end generate GENERATE_LAST;
		GENERATE_OTHERS:	if I/=(NBIT/WIDTH)-1 generate
			CSBI:	CARRY_SELECT_BLOCK
				generic map(
					WIDTH => WIDTH
				)
				port map(
					A	=>	A((I+1)*WIDTH-1 downto I*WIDTH),
					B	=>	B((I+1)*WIDTH-1 downto I*WIDTH),
					Ci	=>	Ci(I),
					S	=>	S((I+1)*WIDTH-1 downto I*WIDTH)
				);
		end generate GENERATE_OTHERS;
	end generate GENERATE_BLOCKS;

end STRUCTURAL;


configuration CFG_CSSG_STRUC of CARRY_SELECT_SUM_GENERATOR is
	for structural
		for GENERATE_BLOCKS
			for GENERATE_LAST
				for all: CARRY_SELECT_BLOCK
					use configuration WORK.CFG_CSB_STRUC;
				end for;
			end for;
			for GENERATE_OTHERS
				for all: CARRY_SELECT_BLOCK
					use configuration WORK.CFG_CSB_STRUC;
				end for;
			end for;
		end for;
	end for;
end CFG_CSSG_STRUC;
