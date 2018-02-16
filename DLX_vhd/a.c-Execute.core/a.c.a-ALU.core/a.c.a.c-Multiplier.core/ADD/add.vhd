library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity ADD is
	generic(
		NBIT:	integer:=	NumBit;
		WIDTH:	integer:=	RCA_width
	);
	port(
		A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0);
		Co:	Out	std_logic
	);

end ADD;

architecture STRUCTURAL of ADD is

	signal	carry:	std_logic_vector(NBIT/WIDTH downto 0);

	component SPARSE_TREE_CARRY_GENERATOR is
		generic(
			NBIT:	integer:=	NumBit;
			WIDTH:	integer:=	RCA_width
		);
		port(
			A:	In	std_logic_vector(NBIT-1 downto 0);
			B:	In	std_logic_vector(NBIT-1 downto 0);
			Ci:	In	std_logic;
			Co:	Out	std_logic_vector(NBIT/WIDTH downto 1)
		);

	end component SPARSE_TREE_CARRY_GENERATOR;

	component CARRY_SELECT_SUM_GENERATOR is
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

	end component CARRY_SELECT_SUM_GENERATOR;

begin

	carry(0)	<=	Ci;
	Co		<=	carry(NBIT/WIDTH);

	CGEN:	SPARSE_TREE_CARRY_GENERATOR
		generic map(
			NBIT	=>	NBIT,
			WIDTH	=>	WIDTH
		)
		port map(
			A	=>	A,
			B	=>	B,
			Ci	=>	Ci,
			Co	=>	carry(NBIT/WIDTH downto 1)
		);

	SGEN:	CARRY_SELECT_SUM_GENERATOR
		generic map(
                	NBIT	=>	NBIT,
                	WIDTH	=>	WIDTH
                )
                port map(
                	A	=>	A,
                	B	=>	B,
                	Ci	=>	carry(NBIT/WIDTH-1 downto 0),
                	S	=>	S
		);

end STRUCTURAL;

configuration CFG_ADD_STRUC of ADD is
	for STRUCTURAL
		for CGEN: SPARSE_TREE_CARRY_GENERATOR
			use configuration WORK.CFG_STCG_STRUC;
		end for;
		for SGEN: CARRY_SELECT_SUM_GENERATOR
			use configuration WORK.CFG_CSSG_STRUC;
		end for;
	end for;
end CFG_ADD_STRUC;
