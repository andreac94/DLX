library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity Comparator is
    port(
        A:      in  word;       -- First operand
        B:      in  word;       -- Second operand
        comp_0: in  std_logic;  -- Use 0x00000000 instead of B
        -- coding of op lets us use fewer signals and less logic
        op:     in  std_logic_vector(2 downto 0);   -- A>B=>"000", A>=B=>"110", A==B=>"001", A!=B=>"101", A<B=>"010", A<=B=>"100"
        O:      out word
    );
end entity Comparator;

architecture behavioural of Comparator is

    -- first and second operands
    signal  X:          word;
    signal  Y:          word;

    signal  X_gt_Y:     std_logic;  -- '1' if X > Y
    signal  X_eq_Y:     std_logic;  -- '1' if X = Y
    signal  X_lt_Y:     std_logic;  -- '1' if X < Y
    
    signal  raw_sel:    std_logic;  -- output of MUX, selects among previous three

begin
    -- Comparator outputs word to be compliant with register format.
    -- It is first computed the strict relation between X and Y
    -- and it is then negated if needed to get all possible non-strict
    -- relations: coding of op matters, please don't change it.
    
    -- First operand is always A.
    -- Second operand can be selected among B and zero, needed for conditional branches.
    X       <=  A;
    Y       <=  B when comp_0='0' else
                (others => '0');

    O(O'high downto 1)  <= (others => '0');
    
    X_gt_Y  <=  '1' when X>Y else '0';
    X_eq_Y  <=  '1' when X=Y else '0';
    X_lt_Y  <=  '1' when X<Y else '0';
    
    raw_sel <=  X_gt_Y when op(1 downto 0)="00" else
                X_eq_Y when op(1 downto 0)="01" else
                X_lt_Y;
    
    O(0)    <=  raw_sel when op(2)='0' else
                not raw_sel;

end architecture behavioural;
