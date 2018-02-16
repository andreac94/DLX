library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use work.mul_constants.all;
use work.mul_custom_types.all;

--ENTITY DECLARATION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
entity Multiplier is
  generic(  NBIT: integer:= NumBit;
           WIDTH: integer:= RCA_width );
  port(
    Mul_A       : In  std_logic_vector(NBIT-1 downto 0);
    Mul_B       : In  std_logic_vector(NBIT-1 downto 0);
    Product     : Out std_logic_vector(2*NBIT-1 downto 0)
  );
end Multiplier;
------------------------------------------------------------------------------

architecture STRUCTURAL of Multiplier is
-- COMPONENT DECLARATION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
component comp5to2_block is
  generic(NBIT : integer := 2*NumBit );
  port (
    in1 , in2, in3, in4, in5 : IN  std_logic_vector( NBIT-1 downto 0);
    sign1, sign2             : In  std_logic;
    Sum, Cout                : OUT std_logic_vector( NBIT-1 downto 0)  );
end component; -- comp5to2_block
-------------------------------------------------------------------------------
component HA is 
	Port(
		In_1:	In	std_logic;
		In_2:	In	std_logic;
		Sum :	Out	std_logic;
		Cout:	Out	std_logic	);
end component; 
-------------------------------------------------------------------------------
component ENC_BOOTH IS
  generic(NBIT : integer:=  NumBit );
  Port(   IN_B : In  std_logic_vector(NBIT-1 downto 0);
          SEL  : Out   Std_logic_vector((3*NBIT/2)-1 downto 0));
end component;
-------------------------------------------------------------------------------
component XOR_block IS
  generic(NBIT : integer:=  2*NumBit );
  Port(   In_vec : In  std_logic_vector(NBIT-1 downto 0);
          sign   : In  std_logic;
          result : Out std_logic_vector(NBIT-1 downto 0));
end component;
-------------------------------------------------------------------------------
component REG IS
generic (N_BIT       : integer := 2*NumBit );
PORT(
     input_reg  : IN  STD_LOGIC_VECTOR(N_BIT-1 DOWNTO 0); -- input.
     clock      : IN  STD_LOGIC; -- clock.
     output_reg : OUT STD_LOGIC_VECTOR(N_BIT-1 DOWNTO 0)  -- output.
     );
END component;
-------------------------------------------------------------------------------
component mux31 is
  generic(NBIT: integer:=  2*NumBit );
    Port ( SEL    : in  STD_LOGIC_VECTOR (1 DOWNTO 0);
           in_1   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
           in_2   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
           in_3   : in  STD_LOGIC_VECTOR (NBIT-1 downto 0);
           out_1  : out STD_LOGIC_VECTOR (NBIT-1 downto 0));
end component;
-------------------------------------------------------------------------------
component Adder is
  generic(NBIT:  integer:= NumBit;
          WIDTH: integer:= RCA_width);
  port(
    A:  In  std_logic_vector(NBIT-1 downto 0);
    B:  In  std_logic_vector(NBIT-1 downto 0);
    Ci: In  std_logic;
    S:  Out std_logic_vector(NBIT-1 downto 0);
    Co: Out std_logic
  );
END component;


--SIGNALS
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
signal signA, signB, signC, signD  : std_logic_vector(2*NumBit-1 downto 0);
signal Zero_sig, in_a_ext : std_logic_vector(2*NumBit-1 downto 0);
--signal in_b_ext     : std_logic_vector(NumBit downto 0);
signal select_s     : std_logic_vector((3*NBIT/2)-1 downto 0);

signal mux_in_1, mux_in_2, mux_out        : Matrix_64 (15 downto 0);
signal sign                               : Matrix_64 (3  downto 0);
signal PIPE1_in, PIPE1_out                : Matrix_64 (15 downto 0);
signal p_sum_1, p_carry_1, PIPE2_in       : Matrix_64 (3  downto 0);
signal PIPE2_out                          : Matrix_64 (7  downto 0);
signal p_sum_2, p_carry_2, PIPE3_in       : std_logic_vector (63 downto 0);
signal PIPE3_out                          : Matrix_64 (4  downto 0);
signal p_sum_3, p_carry_3, carry3_shifted : std_logic_vector (63 downto 0);
signal PIPE4_out                          : Matrix_64 (1  downto 0);
signal result       : std_logic_vector (63 downto 0);
signal PIPE5_in     : std_logic_vector (63 downto 0);
signal carry_report : std_logic ;
signal overflow : std_logic;



--BEGIN DESCRIPTION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
begin

  in_a_ext (NumBit-1 downto 0) <= Mul_A;
  in_a_ext (2*NumBit-1 downto NumBit) <=  (others => Mul_A(NumBit-1) );
--  in_b_ext (0) <=  '0';
--  in_b_ext (NumBit downto 1) <= Mul_B (NumBit-1 downto 0);

--CREATE SELECT signal for the MUX and sign
  BOOTH: ENC_BOOTH  
        port map(
          IN_B    => Mul_B,
          SEL     => select_s);

--CREATE SIGN SIGNALS
  HA1 : HA port map (select_s(26), select_s(29), sign(0)(0), sign(0)(1));
  HA2 : HA port map (select_s(32), select_s(35), sign(1)(0), sign(1)(1));
  HA3 : HA port map (select_s(38), select_s(41), sign(2)(0), sign(2)(1));
  HA4 : HA port map (select_s(44), select_s(47), sign(3)(0), sign(3)(1));
  sign(0)(63 downto 2) <= (others => '0');
  sign(1)(63 downto 2) <= (others => '0');
  sign(2)(63 downto 2) <= (others => '0');
  sign(3)(63 downto 2) <= (others => '0');

-- CREATE MUX chain
  Zero_sig <= (others => '0');

  mux_in_1 (0) (63 downto 0 ) <= in_a_ext (63   downto 0);
  mux_in_2 (0) (63 downto 1 ) <= in_a_ext (63-1 downto 0);
  mux_in_2 (0) (0) <= '0';

  MUX_0 : mux31
      port map(
        SEL     => select_s (3*0+1 downto 3*0),
        in_1    => Zero_sig,
        in_2    => mux_in_1(0),
        in_3    => mux_in_2(0),
        out_1   => mux_out(0));

  XOR_vector_0: XOR_block port map (mux_out(0), select_s(2), PIPE1_in(0));

  PIPE1_out(0) <= PIPE1_in(0);

-- The first has to be generated otside the for to prevent error

  GEN_MUX: for I in 1 to ((NBIT/2)-1) generate

    mux_in_1 (I) (63 downto (2*I))   <= in_a_ext (63-(2*I)   downto 0);
    mux_in_1 (I) (2*I-1 downto 0)    <= (others =>'0');
    mux_in_2 (I) (63 downto (2*I+1)) <= in_a_ext (63-(2*I+1) downto 0);
    mux_in_2 (I) (2*I downto 0)      <= (others =>'0');

    MUX_I : mux31
        port map(
          SEL     => select_s (3*I+1 downto 3*I),
          in_1    => Zero_sig,
          in_2    => mux_in_1(I),
          in_3    => mux_in_2(I),
          out_1   => mux_out(I));

    XOR_vector_I: XOR_block port map (mux_out(I), select_s(3*I+2), PIPE1_in(I));

    PIPE1_out(I) <= PIPE1_in(I);

    end generate GEN_MUX;

-- First Compressor stage
  Comp_1_1 : comp5to2_block port map (PIPE1_out(0),  PIPE1_out(1),  PIPE1_out(2),  PIPE1_out(3),  PIPE1_out(4),  select_s(2),  select_s(5),  p_sum_1(0), p_carry_1(0) );
  Comp_1_2 : comp5to2_block port map (PIPE1_out(5),  PIPE1_out(6),  PIPE1_out(7),  PIPE1_out(8),  PIPE1_out(9),  select_s(8),  select_s(11), p_sum_1(1), p_carry_1(1) );
  Comp_1_3 : comp5to2_block port map (PIPE1_out(10), PIPE1_out(11), PIPE1_out(12), PIPE1_out(13), PIPE1_out(14), select_s(14), select_s(17), p_sum_1(2), p_carry_1(2) );
  Comp_1_4 : comp5to2_block port map (PIPE1_out(15), sign(0), sign(1), sign(2), sign(3), select_s(20), select_s(23), p_sum_1(3), p_carry_1(3) );
  PIPE2_in(0) (63 downto 1) <= p_carry_1(0)(62 downto 0); PIPE2_in(0)(0) <= '0';
  PIPE2_in(1) (63 downto 1) <= p_carry_1(1)(62 downto 0); PIPE2_in(1)(0) <= '0';
  PIPE2_in(2) (63 downto 1) <= p_carry_1(2)(62 downto 0); PIPE2_in(2)(0) <= '0';
  PIPE2_in(3) (63 downto 1) <= p_carry_1(3)(62 downto 0); PIPE2_in(3)(0) <= '0';

-- PIPE 2
  GEN_PIPE_2: for I in 0 to 3 generate
    PIPE2_out(2*I) <= p_sum_1(I);
    PIPE2_out(2*I+1) <= PIPE2_in(I);
  end generate GEN_PIPE_2;

-- Second Compressor stage
  Comp_2_1 : comp5to2_block port map (PIPE2_out(0),  PIPE2_out(1),  PIPE2_out(2),  PIPE2_out(3),  PIPE2_out(4), '0', '0', p_sum_2, p_carry_2 );
  PIPE3_in (63 downto 1) <= p_carry_2(62 downto 0); PIPE3_in(0) <= '0';

-- PIPE 3
  PIPE3_out(0) <= PIPE2_out(5);
  PIPE3_out(1) <= PIPE2_out(6);
  PIPE3_out(2) <= PIPE2_out(7);
  PIPE3_out(3) <= p_sum_2;
  PIPE3_out(4) <= PIPE3_in;

-- Second Compressor stage
  Comp_3_1 : comp5to2_block port map (PIPE3_out(0),  PIPE3_out(1),  PIPE3_out(2),  PIPE3_out(3),  PIPE3_out(4), '0', '0', p_sum_3, p_carry_3 );
  carry3_shifted (63 downto 1) <= p_carry_3(62 downto 0); carry3_shifted(0) <= '0';

-- PIPE 4
  PIPE4_out(0) <= carry3_shifted;
  PIPE4_out(1) <= p_sum_3;



  RCA_lower : Adder   port map(
    A => PIPE4_out (0) (NumBit-1 downto 0),
    B => PIPE4_out (1) (NumBit-1 downto 0),
    Ci=> '0',
    S => PIPE5_in (NumBit-1 downto 0),
    Co=> carry_report );
  
  RCA_upper : Adder   port map(
    A => PIPE4_out (0) (2*NumBit-1 downto NumBit),
    B => PIPE4_out (1) (2*NumBit-1 downto NumBit),
    Ci=> carry_report,
    S => PIPE5_in (2*NumBit-1 downto NumBit),
    Co=> overflow );

  Product <= PIPE5_in;
end architecture;
