library IEEE;
use IEEE.std_logic_1164.all;
use work.custom_types.all;
use work.constants.all;

entity TREE_DECIMATE is
	generic(
		NBIT:	integer:=	NumBit;
		LEVELS:	integer:=	tree_decimate_levels   -- the number of levels the decimate stage has
	);
	port(
		Pi:	In	std_logic_vector(NBIT-1 downto 0);
		Gi:	In	std_logic_vector(NBIT-1 downto 0);
		Po:	Out	std_logic_vector(NBIT/(2**LEVELS)-1 downto 0);
		Go:	Out	std_logic_vector(NBIT/(2**LEVELS)-1 downto 0)
	);

end TREE_DECIMATE;


architecture STRUCTURAL of TREE_DECIMATE is 

	signal	G_matrix:	pg_matrix(LEVELS downto 0);
	signal	P_matrix:	pg_matrix(LEVELS downto 0); 

	signal	Go_wide:	std_logic_vector(NBIT-1 downto 0);
	signal	Po_wide:	std_logic_vector(NBIT-1 downto 0);

	constant out_size:	integer:=	NBIT/(2**LEVELS);

	component G_ELEMENT is
		port(
			Ga:	In	std_logic;
			Gb:	In	std_logic;
			Pa:	In	std_logic;
			Go:	Out	std_logic
		);
	end component G_ELEMENT;

	component PG_ELEMENT is
		port(
			Ga:	In	std_logic;
			Gb:	In	std_logic;
			Pa:	In	std_logic;
			Pb:	In	std_logic;
			Go:	Out	std_logic;
			Po:	Out	std_logic
		);
	end component PG_ELEMENT;

begin

	G_matrix(0)	<=	Gi;
	P_matrix(0)	<=	Pi;

	generate_levels: for I in 1 to LEVELS generate
		generate_elements: for J in 0 to (NBIT/(2**I))-1 generate
			generate_lsb: if (J=0) generate
				G: G_ELEMENT
					port map(
						Ga	=>	G_matrix(I-1)(2*J+1),
						Gb	=>	G_matrix(I-1)(2*J),
						Pa	=>	P_matrix(I-1)(2*J+1),
						Go	=>	G_matrix(I)(J)
					);
			end generate generate_lsb;
			generate_others: if (J>0) generate
				PG: PG_ELEMENT
					port map(
						Ga	=>	G_matrix(I-1)(2*J+1),
						Gb	=>	G_matrix(I-1)(2*J),
						Pa	=>	P_matrix(I-1)(2*J+1),
						Pb	=>	P_matrix(I-1)(2*J),
						Go	=>	G_matrix(I)(J),
						Po	=>	P_matrix(I)(J)
					);
			end generate generate_others;
		end generate generate_elements;
	end generate generate_levels;

	Go_wide	<=	G_matrix(LEVELS);
	Po_wide	<=	P_matrix(LEVELS);

	Go	<=	Go_wide(out_size-1 downto 0);
	Po	<=	Po_wide(out_size-1 downto 0);

end STRUCTURAL;


configuration CFG_TREE_DEC_STRUC of TREE_DECIMATE is
	for STRUCTURAL
		for GENERATE_LEVELS
			for GENERATE_ELEMENTS
				for GENERATE_LSB
					for all: G_ELEMENT
						use configuration WORK.CFG_GEL_BEHAV;
					end for;
				end for;
				for GENERATE_OTHERS
					for all: PG_ELEMENT
						use configuration WORK.CFG_PGEL_BEHAV;
					end for;
				end for;
			end for;
		end for;
	end for;
end CFG_TREE_DEC_STRUC;
