library work;
use work.dlx_config.all;

package CONSTANTS is
	constant	NumBit:			integer:=	architecture_bits;
	constant	NumBit_adder:			integer:=	64;
	constant	RCA_width:		integer:=	4;
	constant	tree_depth:		integer:=	5;	-- HAS TO BE LOG2(NumBit)
	constant	tree_decimate_levels:	integer:=	2;	-- HAS TO BE LOG2(RCA_width)
	constant	tree_mantain_levels:		integer:=	3;	-- HAS TO BE tree_levels-decimate_levels
	constant	FA_S_delay:		time:=		1 ns;
	constant	FA_C_delay:		time:=		2 ns;
	constant	AND_delay:		time:=		0.2 ns;
	constant	OR_delay:		time:=		0.2 ns;
	constant	XOR_delay:		time:=		0.3 ns;
end package CONSTANTS;
