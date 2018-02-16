library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity comp5to2_block is
  generic(NBIT : integer := NumBit );
  port (
    in1 , in2, in3, in4, in5 : IN  std_logic_vector( NBIT-1 downto 0);
    sign1, sign2             : IN  std_logic;
    Sum, Cout                : OUT std_logic_vector( NBIT-1 downto 0)
  );
end entity; -- comp5to2_block


architecture behavioral of comp5to2_block is

  component comp5to2 is
    port (
      x1 , x2, x3, x4, x5: IN  std_logic;
      ci1, ci2           : IN  std_logic;
      co1, co2           : OUT std_logic;
      S  , C             : OUT std_logic
   );
  end component; -- comp5to2

  signal  carry_out1, carry_out2 : std_logic_vector (NBIT-1 downto 0);
  signal  carry_in1 , carry_in2  : std_logic_vector (NBIT   downto 0);

  begin --------------------------------

    carry_in1 (0) <= sign1;
    carry_in2 (0) <= sign2;

    GEN_COMPR: for I in 0 to (NBIT-1) generate
      COMP_I : comp5to2
          port map(
          x1 => in1(I),
          x2 => in2(I),
          x3 => in3(I),
          x4 => in4(I),
          x5 => in5(I),
          ci1 => carry_in1(I),
          ci2 => carry_in2(I),
          co1 => carry_out1(I),
          co2 => carry_out2(I),
          S => Sum(I),
          C => Cout(I) );

      carry_in1(I+1) <= carry_out1(I);
      carry_in2(I+1) <= carry_out2(I);
    end generate GEN_COMPR;

end architecture; -- comp5to2_block


