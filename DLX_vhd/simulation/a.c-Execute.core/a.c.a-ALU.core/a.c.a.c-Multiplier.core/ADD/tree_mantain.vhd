library IEEE;
use IEEE.std_logic_1164.all;
use work.custom_types.all;
use work.constants.all;

entity TREE_MANTAIN is
	generic(
		NBIT:	integer:=	NumBit;
		WIDTH:	integer:=	RCA_width;
		LEVELS:	integer:=	tree_mantain_levels
	);
	port(
		Pi:	In	std_logic_vector(NBIT/WIDTH-1 downto 0);
		Gi:	In	std_logic_vector(NBIT/WIDTH-1 downto 0);
		Co:	Out	std_logic_vector(NBIT/WIDTH-1 downto 0)
	);
end entity TREE_MANTAIN;


architecture STRUCTURAL of TREE_MANTAIN is

	-- for NBIT=32; WIDTH=4:
	-- BITS			=	8
	-- LEVELS		=	3
	-- P_matrix'size	=	3 downto 0, 7 downto 0
	constant	BITS:		integer:=	NBIT/WIDTH;	-- size of input and output

	signal		P_matrix:	carry_matrix(LEVELS downto 0);
	signal		G_matrix:	carry_matrix(LEVELS downto 0);

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

	map_P_input:	P_matrix(LEVELS)	<=	Pi;
	map_G_input:	G_matrix(LEVELS)	<=	Gi;

	-- I=0		=>	lowest level, output
	-- I=LEVELS-1	=>	highest level, just below tree_decimate

	generate_levels: for I in LEVELS-1 downto 0 generate
		-- Each level, from bottom up, is made of an increasing number of smaller and smaller basic blocks repeating themselves.
		-- n_blocks is the number of such blocks
		-- block_size is, quite intuitively, the size of each block
		-- basic_block is a template of the kind ('1','1','0','0') that describes the block: '1' is an element (either PG or G) while '0' is a simple wire
		-- going straight down to the next level
		constant	n_blocks:	integer:=	2**I;
		constant	block_size:	integer:=	BITS/n_blocks;
		-- shared variable	basic_block:	bit_vector(block_size-1 downto 0);	-- UNUSED: CAN'T CONVINCE VHDL TO CALCULATE IT BEFORE GENERATE
	begin

		-- KILLED: LOOK ABOVE.
		-- LEFT AS REFERENCE, FUNCTIONALITY MOVED DIRECTLY IN IF...GENERATE CLAUSES
		-- Procedurally decide the shape of the block.
		-- It can be noticed that each block of size 2N will be made up of N '0's in the lowest significant bits and N '1's in the most significant bits
		-- define_block: process
		--	variable	s:	line;
		-- begin
		--	for L in block_size-1 downto block_size/2 loop
		--		basic_block(L)	:=	'1';
		--	end loop;
		--	for L in (block_size/2)-1 downto 0 loop
		--		basic_block(L)	:=	'0';
		--	end loop;
		--	wait;
		-- end process define_block;

		-- We generate n_blocks blocks, putting G_ELEMENT instead of '1' if the block is the least significant portion.
		-- If it is not such, '1' will generate a PG_ELEMENT instead.
		-- It can also be noticed that Gb and Pb come from directly above the most significant '0' in the block, which
		-- will be placed at index:
		-- (J*block_size)+(block_size/2)-1
		-- with:
		-- J*block_size		base index of the block
		-- block_size/2		index of least significant '1' from base index
		-- -1			to get to the most significant '0'
		generate_blocks: for J in n_blocks-1 downto 0 generate
			-- Check if least significant block
			generate_last_block: if (J=0) generate
				generate_elements: for element in block_size-1 downto 0 generate
					-- Check if '1'
					gen: if (element >= block_size/2) generate
						G: G_ELEMENT
							port map(
								Ga	=>	G_matrix(I+1)(J*block_size+element),
								Gb	=>	G_matrix(I+1)((J*block_size)+(block_size/2)-1),
								Pa	=>	P_matrix(I+1)(J*block_size+element),
								Go	=>	G_matrix(I)(J*block_size+element)
							);
					end generate gen;
					-- Check if '0'
					no_gen: if (element < block_size/2) generate
						G_matrix(I)(J*block_size+element)	<=	G_matrix(I+1)(J*block_size+element);
						P_matrix(I)(J*block_size+element)	<=	P_matrix(I+1)(J*block_size+element);
					end generate no_gen;
				end generate generate_elements;
			end generate generate_last_block;

			-- If not least significant block
			generate_other_blocks: if (J/=0) generate
				generate_elements: for element in block_size-1 downto 0 generate
					-- Check if '1'
					gen: if (element >= block_size/2) generate
						PG: PG_ELEMENT
							port map(
								Ga	=>	G_matrix(I+1)(J*block_size+element),
								Gb	=>	G_matrix(I+1)((J*block_size)+(block_size/2)-1),
								Pa	=>	P_matrix(I+1)(J*block_size+element),
								Pb	=>	P_matrix(I+1)((J*block_size)+(block_size/2)-1),
								Go	=>	G_matrix(I)(J*block_size+element),
								Po	=>	P_matrix(I)(J*block_size+element)
							);
					end generate gen;
					-- Check if '0'
					no_gen: if (element < block_size/2) generate
						G_matrix(I)(J*block_size+element)	<=	G_matrix(I+1)(J*block_size+element);
						P_matrix(I)(J*block_size+element)	<=	P_matrix(I+1)(J*block_size+element);
					end generate no_gen;
				end generate generate_elements;
			end generate generate_other_blocks;
		end generate generate_blocks;
	end generate generate_levels;
		
	map_output: Co	<=	G_matrix(0);

end STRUCTURAL;


-- Appreciate Halo's Energy Sword in all its might, here in a delightful VHDL artwork

configuration CFG_TREE_MANTAIN_STRUC of TREE_MANTAIN is
	for STRUCTURAL
		for generate_levels
			for generate_blocks
				for generate_last_block
					for generate_elements
						for gen
							for all: G_ELEMENT
								use configuration WORK.CFG_GEL_BEHAV;
							end for;
						end for;
					end for;
				end for;
				for generate_other_blocks
					for generate_elements
						for gen
							for all:PG_ELEMENT
								use configuration WORK.CFG_PGEL_BEHAV;
							end for;
						end for;
					end for;
				end for;
			end for;
		end for;
	end for;
end configuration CFG_TREE_MANTAIN_STRUC;
