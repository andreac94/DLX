-- S0 S1 S2 S3 Logic_out
-- 0  0  0  1  AND
-- 1  1  1  0  NAND
-- 0  1  1  1  OR
-- 1  0  0  0  NOR
-- 0  1  1  0  XOR
-- 1  0  0  1  XNOR

library IEEE;
use IEEE.std_logic_1164.all;
use work.dlx_config.all;

entity BitLogic is
  port (
   R1, R2         : in    std_logic;
   S0, S1, S2, S3 : in    std_logic;
   L_out          : out   std_logic
  );
end entity; -- BitLogic

architecture structural of BitLogic  is
  signal L0, L1, L2, L3 : std_logic;
begin

   L0    <= not (S0 and (not R1) and (not R2));
   L1    <= not (S1 and (not R1) and      R2);
   L2    <= not (S2 and      R1  and (not R2));
   L3    <= not (S3 and      R1  and      R2);
   L_out <= not (L0 and L1 and L2 and L3);

end architecture; -- structural

-----------------------------------------------------------
-----------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.dlx_config.all;

entity T2_Logic is
  generic(NBIT : integer := architecture_bits );
  port (
   in_1, in_2             : in    std_logic_vector (NBIT-1 downto 0);
   Sel0, Sel1, Sel2, Sel3 : in    std_logic;
   Logic_out              : out   std_logic_vector (NBIT-1 downto 0)
  );
end entity; -- T2_Logic

architecture structural of T2_Logic  is

  component BitLogic is
    port (
      R1, R2         : in    std_logic;
      S0, S1, S2, S3 : in    std_logic;
      L_out          : out   std_logic
    );
  end component; -- BitLogic

begin

  GEN_LOGIC: for I in 0 to (NBIT-1) generate
    COMP_I : BitLogic
        port map(
        R1 => in_1(I),
        R2 => in_2(I),
        S0 => Sel0,
        S1 => Sel1,
        S2 => Sel2,
        S3 => Sel3,
        L_out => Logic_out(I) );
  end generate GEN_LOGIC;

end architecture; -- structural
