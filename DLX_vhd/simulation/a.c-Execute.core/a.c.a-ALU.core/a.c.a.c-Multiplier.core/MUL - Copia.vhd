library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use work.constants.all;
use work.custom_types.all;

--ENTITY DECLARATION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
entity MUL is
  generic(  NBIT: integer:= NumBit;
           WIDTH: integer:= RCA_width );
  port(
    Mul_A       : In  std_logic_vector(NBIT-1 downto 0);
    Mul_B       : In  std_logic_vector(NBIT-1 downto 0);
    clock_MUL   : IN  STD_LOGIC; -- clock.
    Product     : Out std_logic_vector(2*NBIT-1 downto 0)
  );
end MUL;
------------------------------------------------------------------------------

architecture STRUCTURAL of MUL is
-- COMPONENT DECLARATION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
component comp5to2_block is
  generic(NBIT : integer := 2*NumBit );
  port (
    in1 , in2, in3, in4, in5 : IN  std_logic_vector( NBIT-1 downto 0);
    Sum, Cout                : OUT std_logic_vector( NBIT-1 downto 0)
  );
end component; -- comp5to2_block
-------------------------------------------------------------------------------
component ENC_BOOTH IS
  generic(NBIT : integer:=  NumBit );
  Port(   IN_B : In  std_logic_vector(NBIT-1 downto 0);
          SEL  : Out   Std_logic_vector((3*NBIT/2)-1 downto 0));
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
component ADD is
  generic(NBIT:  integer:= 2*NumBit;
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
signal p_sum_1, p_carry_1, PIPE2_in, debug1       : Matrix_64 (3  downto 0);
signal PIPE2_out                          : Matrix_64 (7  downto 0);
signal p_sum_2, p_carry_2, PIPE3_in, debug2       : std_logic_vector (63 downto 0);
signal PIPE3_out                          : Matrix_64 (4  downto 0);
signal p_sum_3, p_carry_3, carry3_shifted : std_logic_vector (63 downto 0);



--BEGIN DESCRIPTION
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
begin

  in_a_ext (NumBit-1 downto 0) <= Mul_A;
  in_a_ext (2*NumBit-1 downto NumBit) <=  (others => '0');
--  in_b_ext (0) <=  '0';
--  in_b_ext (NumBit downto 1) <= Mul_B (NumBit-1 downto 0);

--CREATE SELECT signal for the MUX and sign
  BOOTH: ENC_BOOTH  
        port map(
          IN_B    => Mul_B,
          SEL     => select_s);

--CREATE SIGN SIGNALS
  signA(0) <= select_s(2);  signA(1) <= select_s(5);  signA(2) <= select_s(8);  signA(3) <= select_s(11);
  signB(0) <= select_s(11); signB(1) <= select_s(17); signB(2) <= select_s(20); signB(3) <= select_s(23);
  signC(0) <= select_s(26); signC(1) <= select_s(29); signC(2) <= select_s(32); signC(3) <= select_s(35);
  signD(0) <= select_s(38); signD(1) <= select_s(41); signD(2) <= select_s(44); signD(3) <= select_s(47);
  signA(63 downto 4) <= (others => '0');
  signB(63 downto 4) <= (others => '0');
  signC(63 downto 4) <= (others => '0');
  signD(63 downto 4) <= (others => '0');
  PIPE_signA : REG port map ( signA, clock_MUL, sign(0) );
  PIPE_signB : REG port map ( signB, clock_MUL, sign(1) );
  PIPE_signC : REG port map ( signC, clock_MUL, sign(2) );
  PIPE_signD : REG port map ( signD, clock_MUL, sign(3) );


-- CREATE MUX chain
  Zero_sig <= (others => '0');

  GEN_MUX: for I in 0 to ((NBIT/2)-1) generate

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

        XOR_gen : for j in 0 to 2*NBIT-1 generate
          PIPE1_in(I)(j) <= mux_out(I)(j) XOR select_s(3*I+2);
        end generate XOR_gen;

    PIPE_1_I : REG
        port map(
          input_reg  => PIPE1_in(I),
          clock      => clock_MUL,
          output_reg => PIPE1_out(I) );

    end generate GEN_MUX;

-- First Compressor stage
  Comp_1_1 : comp5to2_block port map (PIPE1_out(0),  PIPE1_out(1),  PIPE1_out(2),  PIPE1_out(3),  sign(0), p_sum_1(0), p_carry_1(0) );
  Comp_1_2 : comp5to2_block port map (PIPE1_out(4),  PIPE1_out(5),  PIPE1_out(6),  PIPE1_out(7),  sign(1), p_sum_1(1), p_carry_1(1) );
  Comp_1_3 : comp5to2_block port map (PIPE1_out(8),  PIPE1_out(9),  PIPE1_out(10), PIPE1_out(11), sign(2), p_sum_1(2), p_carry_1(2) );
  Comp_1_4 : comp5to2_block port map (PIPE1_out(12), PIPE1_out(13), PIPE1_out(14), PIPE1_out(15), sign(3), p_sum_1(3), p_carry_1(3) );
  PIPE2_in(0) (63 downto 1) <= p_carry_1(0)(62 downto 0); PIPE2_in(0)(0) <= '0';
  PIPE2_in(1) (63 downto 1) <= p_carry_1(1)(62 downto 0); PIPE2_in(1)(0) <= '0';
  PIPE2_in(2) (63 downto 1) <= p_carry_1(2)(62 downto 0); PIPE2_in(2)(0) <= '0';
  PIPE2_in(3) (63 downto 1) <= p_carry_1(3)(62 downto 0); PIPE2_in(3)(0) <= '0';
  --DEBUG
  debug1(0) <= PIPE2_in(0) + p_sum_1(0);
  debug1(1) <= PIPE2_in(1) + p_sum_1(1);
  debug1(2) <= PIPE2_in(2) + p_sum_1(2);
  debug1(3) <= PIPE2_in(3) + p_sum_1(3);

-- PIPE 2
  GEN_PIPE_2: for I in 0 to 3 generate
    PIPE_2s_I : REG port map ( p_sum_1(I) , clock_MUL, PIPE2_out(2*I));
    PIPE_2c_I : REG port map ( PIPE2_in(I), clock_MUL, PIPE2_out(2*I+1));
  end generate GEN_PIPE_2;

-- Second Compressor stage
  Comp_2_1 : comp5to2_block port map (PIPE2_out(0),  PIPE2_out(1),  PIPE2_out(2),  PIPE2_out(3),  PIPE2_out(4), p_sum_2, p_carry_2 );
  PIPE3_in (63 downto 1) <= p_carry_2(62 downto 0); PIPE3_in(0) <= '0';
  debug2 <= PIPE3_in + p_sum_2;

-- PIPE 3
  PIPE_3_0 : REG port map ( PIPE2_out(5), clock_MUL, PIPE3_out(0) );
  PIPE_3_1 : REG port map ( PIPE2_out(6), clock_MUL, PIPE3_out(1) );
  PIPE_3_2 : REG port map ( PIPE2_out(7), clock_MUL, PIPE3_out(2) );
  PIPE_3_3 : REG port map ( p_sum_2     , clock_MUL, PIPE3_out(3) );
  PIPE_3_4 : REG port map ( PIPE3_in    , clock_MUL, PIPE3_out(4) );

-- Second Compressor stage
  Comp_3_1 : comp5to2_block port map (PIPE3_out(0),  PIPE3_out(1),  PIPE3_out(2),  PIPE3_out(3),  PIPE3_out(4), p_sum_3, p_carry_3 );
  carry3_shifted (63 downto 1) <= p_carry_3(62 downto 0); carry3_shifted(0) <= '0';

-- Sum Stage
  Product <= carry3_shifted + p_sum_3 ;

end architecture;
