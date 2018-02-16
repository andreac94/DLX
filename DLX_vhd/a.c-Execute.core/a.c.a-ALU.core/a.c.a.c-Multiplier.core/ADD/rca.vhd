library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RCA is
	generic(
		NBIT:	integer :=	16
	);
	Port(
		A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0);
		Co:	Out	std_logic
	);

end RCA;


architecture BEHAVIORAL of RCA is

signal	sum:	std_logic_vector(NBIT-1 downto 0);

begin

	sum	<=	(A+B) when (Ci = '0')
			else (A+B+1);
	S	<=	sum;
	Co	<=	'1' when (((A(NBIT-1) or B(NBIT-1)) = '1') and (sum(NBIT-1) = '0')) or	-- Overflow if either of the MSB is '1' and the MSB of the sum is '0'
			((A(NBIT-1) and B(NBIT-1)) = '1')					-- Overflow if both MSB are '1'
			else '0';

end BEHAVIORAL;


architecture STRUCTURAL of RCA is

	signal STMP: std_logic_vector(NBIT-1 downto 0);
	signal CTMP: std_logic_vector(NBIT downto 0);

	component FA
		Port(
			A:	In	std_logic;
			B:	In	std_logic;
			Ci:	In	std_logic;
			S:	Out	std_logic;
			Co:	Out	std_logic
		);

	end component;

begin

	CTMP(0) <= Ci;

	gen_rca: for I in 0 to NBIT-1 generate
		FAI: FA
			Port Map(A=>A(I), B=>B(I), Ci=>CTMP(I), S=>STMP(I), Co=>CTMP(I+1));

	end generate;

	Co <= CTMP(NBIT);
	S <= STMP;

end STRUCTURAL;


configuration CFG_RCA_STRUC of RCA is
	for STRUCTURAL
		for gen_rca
			for all: FA
				use configuration WORK.CFG_FA_BEHAVIORAL;
			end for;
		end for;
	end for;
end CFG_RCA_STRUC;

configuration CFG_RCA_BEHAV of RCA is
	for BEHAVIORAL
	end for;
end CFG_RCA_BEHAV;
