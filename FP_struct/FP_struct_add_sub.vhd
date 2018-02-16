library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity FP_struct_add_sub is
    generic(
        -- Default is Single Precision floating point standard as in IEEE-754.
        nbit:           natural:=   32;
        mantissa_bits:  natural:=   23;
        exponent_bits:  natural:=   8
    );
    port(
        A:      in  std_logic_vector(nbit-1 downto 0);
        B:      in  std_logic_vector(nbit-1 downto 0);
        sub:    in  std_logic;
        S:      out std_logic_vector(nbit-1 downto 0);
    );
end entity FP_struct_add_sub;

architecture structural of FP_struct_add_sub is

    -- SIGNALS
    -- Splitting input numbers into sign, exponent and mantissa components.
    signal  sign_A:     std_logic;
    signal  exponent_A: std_logic_vector(exponent_bits-1 downto 0);
    signal  mantissa_A: std_logic_vector(mantissa_bits-1 downto 0);
    signal  sign_B:     std_logic;
    signal  exponent_B: std_logic_vector(exponent_bits-1 downto 0);
    signal  mantissa_B: std_logic_vector(mantissa_bits-1 downto 0);
    

    -- COMPONENTS
    component comparator is
        generic(
            nbit:   natural:=   32;
        );
        port(
            A:      in  std_logic_vector(nbit-1 downto 0);
            B:      in  std_logic_vector(nbit-1 downto 0);
            A_gt_B: out std_logic;
            A_eq_B: out std_logic;
            B_gt_A: out std_logic
        );
    end component comparator;
    
    component exponent_subtractor is
        generic(
            exponent_bits:  natural:=   8;  -- Single Precision floating point by IEEE-754.
        );
        port(
            exponent_A:     in  std_logic_vector(exponent_bits-1 downto 0);
            exponent_B:     in  std_logic_vector(exponent_bits-1 downto 0);
            exp_B_gt_exp_A: in  std_logic;
            difference:     out std_logic_vector(exponent_bits-1 downto 0)
        );
    end component exponent_subtractor;
    
begin

    -- Splitting input numbers into sign, exponent and mantissa components.
    sign_A      <=  A(nbit-1);
    exponent_A  <=  A(nbit-2 downto mantissa_bits);
    mantissa_A  <=  A(mantissa_bits-1 downto 0);
    sign_B      <=  B(nbit-1);
    exponent_B  <=  B(nbit-2 downto mantissa_bits);
    mantissa_B  <=  B(mantissa_bits-1 downto 0);
    
    
    -- SIGN PATH
    -- Adjust by inserting pipeline stages if needed.
    
    -- A is bigger (in magnitude) than B if either the exponent is bigger
    -- or the exponent is equal and the mantissa is bigger.
    -- Otherwise, A is not bigger (in magnitude) than B.
    A_gt_B      <=  '1' when exp_A_gt_exp_B='1' else
                    '1' when exp_A_eq_exp_B='1' and man_A_gt_man_B='1' else
                    '0';
    -- A is equal (in magnitude) to B if the exponent is equal and the mantissa is equal.
    -- Otherwise, A is not equal (in magnitude) to B.
    A_eq_B      <=  '1' when exp_A_eq_exp_B='1' and man_A_eq_man_B='1' else
                    '0';
    -- B is bigger (in magnitude) than A if either the exponent is bigger
    -- or the exponent is equal and the mantissa is bigger.
    -- Otherwise, B is not bigger (in magnitude) than A.
    B_gt_A      <=  '1' when exp_B_gt_exp_A='1' else
                    '1' when exp_A_eq_exp_B='1' and man_B_gt_man_A='1' else
                    '0';
    
    -- Result is negative when we are summing/subtracting a number from a bigger (in magnitude) negative number.
    -- Result is still negative when we are subtracting from a number a bigger (in magnitude) positive number,
    -- or we are summing to a number a bigger (in magnitude) negative number.
    -- All other cases yield positive results.
    sign_S      <=  '1' when A_gt_B='1' and sign_A='1' else
                    '1' when B_gt_A='1' and sign_B='1' and sub='0' else
                    '1' when B_gt_A='1' and sign_B='0' and sub='1' else
                    '0';
    
    
    -- EXPONENT PATH
    -- Adjust by inserting pipeline stages if needed.
    
    -- The bigger exponent is the exponent of the result (might need later adjustment).
    EXP_COMP:   comparator
        generic map(
            nbit    =>  exponent_bits
        )
        port map(
            A       =>  exponent_A,
            B       =>  exponent_B,
            A_gt_B  =>  exp_A_gt_exp_B,
            A_eq_B  =>  exp_A_eq_exp_B,
            B_gt_A  =>  exp_B_gt_exp_A
        );
    
    EXP_SUB:    exponent_subtractor
        generic map(
            exponent_bits   =>  exponent_bits
        )
        port map(
            exponent_A      =>  exponent_A,
            exponent_B      =>  exponent_B,
            exp_B_gt_exp_A  =>  exp_B_gt_exp_A,
            difference      =>  exponent_difference
        );
        
end architecture structural;
