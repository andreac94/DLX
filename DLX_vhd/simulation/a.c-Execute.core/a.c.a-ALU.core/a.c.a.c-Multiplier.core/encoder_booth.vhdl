library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.constants.all;

entity ENC_unit is
	Port(	INPUT	:	In	std_logic_vector(2 downto 0);
		OUTPUT	:	Out	std_logic_vector(2 downto 0));
end ENC_unit;

architecture BEHAVIORAL of ENC_unit is
 BEGIN
	OUTPUT(0) <= ( (not INPUT(1)) and INPUT(0))or(INPUT(1) and (not INPUT(0)));
	OUTPUT(1) <= ( (not INPUT(2)) and INPUT(1) and INPUT(0))or(INPUT(2) and (not INPUT(1)) and (not INPUT(0)));
	OUTPUT(2) <= INPUT(2); -- this will be the add/subtract signal
end BEHAVIORAL ;
-------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.constants.all;

entity ENC_BOOTH IS
	generic(NBIT:	integer:=  NumBit	);
	Port(	IN_B	:  In	std_logic_vector(NBIT-1 downto 0);
		SEL	:  Out	std_logic_vector((3*NBIT/2)-1 downto 0));
end ENC_BOOTH;

architecture STRUCTURAL of ENC_BOOTH is
	SIGNAL INPUT0 : STD_LOGIC_VECTOR(2 DOWNTO 0) ; 
	

	signal GND_s		: std_logic_vector (2*NBIT-1 downto 0) := (OTHERS => '0');

	COMPONENT ENC_unit IS
		Port (	INPUT	:	In	std_logic_vector(2 downto 0);
			OUTPUT	:	Out	std_logic_vector(2 downto 0));
	end COMPONENT;	
	
	begin
	  INPUT0  <= (IN_B(1 downto 0) & GND_s(0));

	  UNIT_0: ENC_unit
	  	port map (INPUT => INPUT0 , OUTPUT => SEL(2 downto 0));
	
	  GEN_ENC: for i in 1 to (NBIT/2-1) generate	
		UNIT_X:	ENC_unit
		  port map (INPUT => IN_B(((2*i)+1) downto ((2*i)-1)) , OUTPUT => SEL(((3*i)+2) downto (3*i)));	
	  end generate GEN_ENC;
		
end STRUCTURAL ;
