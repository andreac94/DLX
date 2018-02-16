library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;
use work.leading_zero_detection.all;
use work.complement.all;

entity FP_AdderSubtractor is
    generic(
        nbit:       natural:=   architecture_bits;
        exponent:   natural:=   8;
        mantissa:   natural:=   23
    );
    port(
        A:      in          std_logic_vector(nbit-1 downto 0);
        B:      in          std_logic_vector(nbit-1 downto 0);
        sub:    in          std_logic;
        S:      out         std_logic_vector(nbit-1 downto 0)
    );
end entity FP_AdderSubtractor;


architecture behavioural of FP_AdderSubtractor is

begin

    main: process(A, B, sub)
    
        -- Hidden bit needs to be represented explicitly. A, B are input to the block.
        variable    mantissa_A: std_logic_vector(mantissa downto 0);
        variable    mantissa_B: std_logic_vector(mantissa downto 0);

        variable    exponent_A: std_logic_vector(exponent-1 downto 0);
        variable    exponent_B: std_logic_vector(exponent-1 downto 0);
        
        variable    sign_A:     std_logic;
        variable    sign_B:     std_logic;
        
        -- X, Y are input to adder.
        variable    mantissa_X: std_logic_vector(mantissa downto 0);
        variable    mantissa_Y: std_logic_vector(mantissa downto 0);
        variable    exponent_X: std_logic_vector(exponent-1 downto 0);
        variable    exponent_Y: std_logic_vector(exponent-1 downto 0);
        
        -- X0, Y0 are input to RCA (or equivalent). 1 bit is added as numbers are now in 2's complement,
        -- Y0 could be negated to implement subtraction.
        variable    mantissa_X0:    std_logic_vector(mantissa+1 downto 0);
        variable    mantissa_Y0:    std_logic_vector(mantissa+1 downto 0);
        variable    exponent_X0:    std_logic_vector(exponent-1 downto 0);
        variable    exponent_Y0:    std_logic_vector(exponent-1 downto 0);

        variable    mantissa_S0:    std_logic_vector(mantissa+1 downto 0);
        variable    exponent_S0:    std_logic_vector(exponent-1 downto 0);

        variable    mantissa_S1:    std_logic_vector(mantissa+1 downto 0);
        variable    exponent_S1:    std_logic_vector(exponent-1 downto 0);

        variable    result_negative:    std_logic;

        variable    mantissa_S: std_logic_vector(mantissa-1 downto 0);
        variable    exponent_S: std_logic_vector(exponent-1 downto 0);
        variable    sign_S:     std_logic;
        
        variable    expA_gt_expB:   std_logic;
        variable    shift:          natural;
        -- '0' for effective addition, '1' for effective subtraction. See table below for explanation.
        variable    eop:        std_logic;
        -- '0' for X := A, Y := B; '1' for X := B, Y := A.
        variable    swap:       std_logic;
        -- '0' to use result as is, '1' to negate.
        variable    negate:     std_logic;
    begin
    
        assign_sign:
            sign_A          :=  A(nbit-1);
            if (sub='0') then
                sign_B      :=  B(nbit-1);
            else
                sign_B      :=  not(B(nbit-1));
            end if;
        
        assign_exponent:
            exponent_A  :=  A(exponent+mantissa-1 downto mantissa);
            exponent_B  :=  B(exponent+mantissa-1 downto mantissa);
    
        assign_mantissa:
            -- Floating point assumes numbers are normalized in the range [1.0,2.0) * 2^exponent.
            -- This means the first bit of the mantissa is always '1' and it is not represented to save space.
            -- The only exception is when exponent is (others => '0'): hidden bit is assumed '0' to allow representation of 0.
            -- Incidentally this would allow subnormal values (very close to 0) to be represented as well, but operations are very slow.
            if (exponent_A=(exponent_A'range => '0')) then
                mantissa_A  :=  (others => '0');
            else
                mantissa_A  :=  '1' & A(mantissa-1 downto 0);
            end if;
            if (exponent_B=(exponent_B'range => '0')) then
                mantissa_B  :=  (others => '0');
            else
                mantissa_B  :=  '1' & B(mantissa-1 downto 0);
            end if;
    
        compare_exponents:
            if (exponent_A > exponent_B) then
                expA_gt_expB    :=  '1';
            else
                expA_gt_expB    :=  '0';
            end if;
        
        determine_op:
            -- This procedure allows us to work with positive numbers (up to the sum result)
            if (sign_A='0') and (sign_B='0') and (expA_gt_expB = '0') then
                -- A+B = B+A        or      A-(-B) = B+A
                eop     :=  '0';
                swap    :=  '1';
                negate  :=  '0';
            elsif (sign_A='0') and (sign_B='0') and (expA_gt_expB = '1') then
                -- A+B = A+B        or      A-(-B) = A+B
                eop     :=  '0';
                swap    :=  '0';
                negate  :=  '0';
            elsif (sign_A='0') and (sign_B='1') and (expA_gt_expB = '0') then
                -- A-B = -(B-A)     or      A+(-B) = -(B-A)
                eop     :=  '1';
                swap    :=  '1';
                negate  :=  '1';
            elsif (sign_A='0') and (sign_B='1') and (expA_gt_expB = '1') then
                -- A-B = A-B        or      A+(-B) = A-B
                eop     :=  '1';
                swap    :=  '0';
                negate  :=  '0';
            elsif (sign_A='1') and (sign_B='0') and (expA_gt_expB = '0') then
                -- (-A)+B = B-A     or      (-A)-(-B) = B-A
                eop     :=  '1';
                swap    :=  '1';
                negate  :=  '0';
            elsif (sign_A='1') and (sign_B='0') and (expA_gt_expB = '1') then
                -- (-A)+B = -(A-B)  or      (-A)-(-B) = -(A-B)
                eop     :=  '1';
                swap    :=  '0';
                negate  :=  '1';
            elsif (sign_A='1') and (sign_B='1') and (expA_gt_expB = '0') then
                -- (-A)-B = -(B+A)  or      (-A)+(-B) = -(B+A)
                eop     :=  '0';
                swap    :=  '1';
                negate  :=  '1';
            elsif (sign_A='1') and (sign_B='1') and (expA_gt_expB = '1') then
                -- (-A)-B = -(A+B)  or      (-A)+(-B) = -(A+B)
                eop     :=  '0';
                swap    :=  '0';
                negate  :=  '1';
            end if;
        
        swap_operands:
            -- Assigning as X operand the one with greater exponent allows for always shifting operand Y
            if (swap='0') then
                mantissa_X  :=  mantissa_A;
                mantissa_Y  :=  mantissa_B;
                exponent_X  :=  exponent_A;
                exponent_Y  :=  exponent_B;
            else
                mantissa_X  :=  mantissa_B;
                mantissa_Y  :=  mantissa_A;
                exponent_X  :=  exponent_B;
                exponent_Y  :=  exponent_A;
            end if;
        
        determine_shift:
            shift:= to_integer(unsigned(exponent_X)) - to_integer(unsigned(exponent_Y));
        
        align:
            -- Adding a leading '0' to comply with 2's complement format for positive numbers.
            -- Needed by 2's complement adder to detect overflow.
            -- The fancy bits added after the LSB are Guard, Rounding and Sticky bits, needed for subtractions.
            -- They are not implemented here as logic truncates and does not support rounding up, down or to closest.
            mantissa_X0     :=  '0' & mantissa_X;
            mantissa_Y0     :=  std_logic_vector(unsigned('0' & mantissa_Y) srl shift);
            exponent_X0     :=  exponent_X;
            exponent_Y0     :=  exponent_Y;
            
        add_sub:
            -- fancy adder here if wanted, probably just pipelined RCA
            if eop='0' then
                -- ADDING
                -- Use greater exponent and sum of mantissas, we'll normalize and check exceptions later.
                mantissa_S0 :=  std_logic_vector(signed(mantissa_X0) + signed(mantissa_Y0));
                exponent_S0 :=  exponent_X0;
                if (exponent_X0 = (exponent_X0'range => '1')) then
                    -- We are summing: if one number is infinity (or NaN) we get infinity (or NaN) of same sign.
                    exponent_S1 :=  (others => '1');
                    if (mantissa_X0(mantissa-1 downto 0) /= (mantissa_S'range => '0')) then   -- 2's comp and hidden bit present even in inf, all rest must be '0'.
                        -- We are summing a NaN: always NaN
                        mantissa_S1 :=  (others => '1');
                    elsif (exponent_Y0 = (exponent_Y0'range => '1')) and (mantissa_Y0 /= "01" & (mantissa_A'range => '0')) then
                        -- We are summing infinity and a NaN: NaN
                        mantissa_S1 :=  (others => '1');
                    else
                        -- We are summing infinity and something which is not NaN: always infinity of same sign.
                    end if;
                elsif mantissa_S0(mantissa_S0'high) /= '0' then
                    -- Since we are adding positive non-infinite numbers, if result is not positive we overflowed.
                    -- Result is correct if interpreted as unsigned, we just need to normalize it.
                    mantissa_S1 :=  std_logic_vector(unsigned(mantissa_S0) srl 1);
                    exponent_S1 :=  std_logic_vector(unsigned(exponent_S0) + 1);
                else
                    mantissa_S1 :=  mantissa_S0;
                    exponent_S1 :=  exponent_S0;
                end if;
                result_negative :=  '0';
            else
                -- SUBTRACTING
                -- Use greater exponent and difference of mantissas, we'll normalize and check exceptions later.
                mantissa_S0 :=  std_logic_vector(signed(mantissa_X0) - signed(mantissa_Y0));
                exponent_S0 :=  exponent_X0;
                if (exponent_X0 = (exponent_X0'range => '1')) then
                    -- We are subtracting and the greater number is infinity or NaN: result is infinity or NaN of same sign.
                    exponent_S1 :=  (others => '1');
                    result_negative :=  '0';
                    if (mantissa_X0(mantissa-1 downto 0) /= (mantissa_S'range => '0')) then   -- 2's comp and hidden bit present even in inf, all rest must be '0'.
                        -- We are subtracting from a NaN: always NaN
                        mantissa_S1 :=  (others => '1');
                    elsif (exponent_Y0 = (exponent_Y0'range => '1')) then
                        -- We are subtracting infinity or NaN from infinity: NaN
                        mantissa_S1 :=  (others => '1');
                    else
                        -- We are subtracting a finite value from infinity: always infinity of same sign
                        mantissa_S1 :=  (others => '0');
                    end if;
                elsif (mantissa_S0(mantissa_S0'high) = '1') then
                    -- We are subtracting positive non-infinite numbers, result might be negative.
                    -- If it is, take absolute value before checking for leading zeroes and note we changed sign.
                    -- Shift is by leading_zeroes-1 as the MSB is just there for 2's complement's sake, we want a '1' in 2nd position (corresponding to hidden bit).
                    -- Notice 0 is supported as all '0's is shifted left leading still to all '0's.
                    -- Underflow does however require care in setting exponent to all '0's, as standard procedure leads to negative exponent.
                    -- This requires a comparison between the number of leading zeroes and the exponent.
                    if (unsigned(exponent_S0) <= leading_zeroes(complement(mantissa_S0))-1) then
                        exponent_S1 :=  (others => '0');
                        mantissa_S1 :=  (others => '0');
                    else
                        mantissa_S1     :=  std_logic_vector(signed(complement(mantissa_S0)) sll (leading_zeroes(complement(mantissa_S0))-1));
                        if (mantissa_S0 /= (mantissa_S0'range => '0')) then
                            exponent_S1     :=  std_logic_vector(unsigned(exponent_S0) - (leading_zeroes(complement(mantissa_S0))-1));
                        else
                            exponent_S1 :=  (others => '0');
                        end if;
                    end if;
                    result_negative :=  '1';
                else
                    -- If result is positive, normalize shifting by leading_zeroes-1 (complement_sign & hidden_bit & mantissa, we want '1' in hidden bit).
                    -- Notice 0 is supported as all '0's is shifted left leading still to all '0's. See above for explanation.
                    if (unsigned(exponent_S0) <= leading_zeroes(complement(mantissa_S0))-1) then
                        exponent_S1 :=  (others => '0');
                        mantissa_S1 :=  (others => '0');
                    else
                        mantissa_S1     :=  std_logic_vector(signed(mantissa_S0) sll (leading_zeroes(mantissa_S0)-1));
                        if (mantissa_S0 /= (mantissa_S0'range => '0')) then
                            exponent_S1     :=  std_logic_vector(unsigned(exponent_S0) - (leading_zeroes(mantissa_S0)-1));
                        else
                            exponent_S1 :=  (others => '0');
                        end if;
                    end if;
                    result_negative :=  '0';
                end if;
            end if;
        
        adjust_sign:
            -- If we had a negative number from subtraction we have a positive mantissa already, possibilities are:
            -- result positive, negate does not require sign change, output is positive;
            -- result positive, negate does require sign change, output is negative;
            -- result negative, negate does not require sign change, output is negative;
            -- result negative, negate does require sign change, output is positive.
            -- It is evident that the sign of the final result is negate XOR result_negative.
            -- Mantissa is obtained by discarding the MSB, giving the sign (ensured at this point to be '0'), and the hidden bit,
            -- ensured to be '1' unless the result is '0'.
            mantissa_S  :=  mantissa_S1(mantissa-1 downto 0);
            exponent_S  :=  exponent_S1;
            sign_S      :=  negate xor result_negative;
        
        assign_output:
            -- Put all pieces back together in a 32-bit vector.
            S   <=  sign_S & exponent_S & mantissa_S(mantissa-1 downto 0);
        
        
    
    end process main;
    
end architecture behavioural;
