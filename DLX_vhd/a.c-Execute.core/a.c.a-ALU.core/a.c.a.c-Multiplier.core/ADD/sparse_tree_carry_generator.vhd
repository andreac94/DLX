library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity SPARSE_TREE_CARRY_GENERATOR is
	generic(
		NBIT:	integer:=	NumBit;
		WIDTH:	integer:=	RCA_width
	);
	port(
		A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		Co:	Out	std_logic_vector(NBIT/WIDTH-1 downto 0)
	);

end SPARSE_TREE_CARRY_GENERATOR;


architecture STRUCTURAL of SPARSE_TREE_CARRY_GENERATOR is

	-- For NBIT=32; WIDTH=4:
	-- DEPTH		=	5
	-- PG_NETWORK_LEVELS	=	1		always 1 level deriving P and G from A and B
	-- DECIMATION_LEVELS	=	2		for each level get the general P and G, halving the number of bits
	-- MANTAIN_LEVELS	=	3		keep the number of bits while calculating general P and G
	-- mid_tree_P'range	=	7 downto 0
	-- mid_tree_G'range	=	7 downto 0

	constant	DEPTH:			integer:=	tree_depth;
	constant	DECIMATION_LEVELS:	integer:=	tree_decimate_levels;
	constant	MANTAIN_LEVELS:		integer:=	tree_mantain_levels;

	signal	prop:		std_logic_vector(NBIT-1 downto 0);
	signal	gen:		std_logic_vector(NBIT-1 downto 0);
	signal	mid_tree_P:	std_logic_vector(NBIT/(2**DECIMATION_LEVELS)-1 downto 0);
	signal	mid_tree_G:	std_logic_vector(NBIT/(2**DECIMATION_LEVELS)-1 downto 0);

	component PG_NETWORK
		generic(
			NBIT:	integer:=	NumBit
		);
		port(
			A:	In	std_logic_vector(NBIT-1 downto 0);
			B:	In	std_logic_vector(NBIT-1 downto 0);
			Ci:	In	std_logic;
			P:	Out	std_logic_vector(NBIT-1 downto 0);
			G:	Out	std_logic_vector(NBIT-1 downto 0)
		);

	end component PG_NETWORK;

	component TREE_DECIMATE
		generic(
			NBIT:	integer:=	NumBit;
			LEVELS:	integer:=	tree_decimate_levels
		);
		port(
			Pi:	In	std_logic_vector(NBIT-1 downto 0);
			Gi:	In	std_logic_vector(NBIT-1 downto 0);
			Po:	Out	std_logic_vector(NBIT/(2**LEVELS)-1 downto 0);
			Go:	Out	std_logic_vector(NBIT/(2**LEVELS)-1 downto 0)
		);
	end component TREE_DECIMATE;

	component TREE_MANTAIN
		generic(
			NBIT:	integer:=	NumBit;
			WIDTH:	integer:=	RCA_width;
			LEVELS:	integer:=	tree_mantain_levels
		);
		port(
			Pi:	In	std_logic_vector((NBIT/WIDTH)-1 downto 0);
			Gi:	In	std_logic_vector((NBIT/WIDTH)-1 downto 0);
			Co:	Out	std_logic_vector((NBIT/WIDTH)-1 downto 0)
		);
	end component TREE_MANTAIN;

begin

	PGN:	PG_NETWORK
		generic map(
			NBIT	=>	NBIT
		)
		port map(
			A	=>	A,
			B	=>	B,
			Ci	=>	Ci,
			P	=>	prop,
			G	=>	gen
		);

	DEC_TREE:	TREE_DECIMATE
		generic map(
			NBIT	=>	NBIT,
			LEVELS	=>	DECIMATION_LEVELS
		)
		port map(
			Pi	=>	prop,
			Gi	=>	gen,
			Po	=>	mid_tree_P,
			Go	=>	mid_tree_G
		);

	MAN_TREE:	TREE_MANTAIN
		generic map(
			NBIT	=>	NBIT,
			WIDTH	=>	WIDTH,
			LEVELS	=>	MANTAIN_LEVELS
		)
		port map(
			Pi	=>	mid_tree_P,
			Gi	=>	mid_tree_G,
			Co	=>	Co
		);

end STRUCTURAL;


configuration CFG_STCG_STRUC of SPARSE_TREE_CARRY_GENERATOR is
	for STRUCTURAL
		for all: PG_NETWORK
			use configuration WORK.CFG_PGN_BEHAV;
		end for;
		for all: TREE_DECIMATE
			use configuration WORK.CFG_TREE_DEC_STRUC;
		end for;
		for all: TREE_MANTAIN
			use configuration WORK.CFG_TREE_MANTAIN_STRUC;
		end for;
	end for;
end configuration CFG_STCG_STRUC;
