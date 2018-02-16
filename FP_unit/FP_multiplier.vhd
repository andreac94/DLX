library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FP_multiplier is
    generic(
        nbit:       natural:=   32;
        exponent:   natural:=   8;
        mantissa:   natural:=   23;
        bias:       integer:=   127
    );
    port(
        clk:    in          std_logic;
        A:      in          std_logic_vector(nbit-1 downto 0);
        B:      in          std_logic_vector(nbit-1 downto 0);
        M:      out         std_logic_vector(nbit-1 downto 0)
    );
end entity FP_multiplier;


architecture behavioural of FP_multiplier is

    signal  sign_A:         std_logic;
    signal  sign_B:         std_logic;
    signal  exponent_A:     std_logic_vector(exponent-1 downto 0);
    signal  exponent_B:     std_logic_vector(exponent-1 downto 0);
    signal  mantissa_A:     std_logic_vector(mantissa downto 0);
    signal  mantissa_B:     std_logic_vector(mantissa downto 0);
                            
    signal  sign_M0:        std_logic;
    signal  exponent_M0:    std_logic_vector(exponent-1 downto 0);
    signal  mantissa_M0:    std_logic_vector(2*mantissa+1 downto 0);
                            
    signal  sign_M:         std_logic;
    signal  exponent_M:     std_logic_vector(exponent-1 downto 0);
    signal  mantissa_M:     std_logic_vector(mantissa-1 downto 0);

begin

    sign_A      <=  A(nbit-1);
    sign_B      <=  B(nbit-1);
    
    exponent_A  <=  A(exponent+mantissa-1 downto mantissa);
    exponent_B  <=  B(exponent+mantissa-1 downto mantissa);
    
    mantissa_A  <=  '1' & A(mantissa-1 downto 0);
    mantissa_B  <=  '1' & B(mantissa-1 downto 0);

    main: process(clk)
        variable    exp_A_int:      integer;
        variable    exp_B_int:      integer;
        variable    exp_M0_int:     integer;
        constant    zero_exp:       std_logic_vector(exponent-1 downto 0):= (others => '0');
        constant    inf_exp:        std_logic_vector(exponent-1 downto 0):= (others => '1');
        constant    zero:           std_logic_vector(mantissa-1 downto 0):= (others => '0');
        constant    inf:            std_logic_vector(mantissa-1 downto 0):= (others => '0');
        constant    NaN:            std_logic_vector(mantissa-1 downto 0):= (others => '1');
    begin
        sign:
            -- Sign of multiplication is negative if multiplicands are different.
            sign_M0     <=  sign_A xor sign_B;
            sign_M      <=  sign_M0;    -- good to implement pipelines.

        mul:
            if (exponent_A = zero_exp) then
                -- If multplicand is 0 we need to check for exceptions.
                if (exponent_B = inf_exp) then
                    -- We are multiplying 0 by either inf or NaN: result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                else
                    -- We are multiplying 0 by a non-infinite quantity, result is 0.
                    exponent_M0 <=  zero_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                end if;
            elsif (exponent_B = zero_exp) then
                -- If multiplier is 0 we need to check for exceptions.
                if (exponent_A = inf_exp) then
                    -- We are multiplying either inf or NaN by 0, result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                else
                    -- We are multiplying a non-infinite quantity by 0, result is 0.
                    exponent_M0 <=  zero_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                end if;
            elsif (exponent_A = inf_exp) then
                -- If multiplicand is either inf or NaN we need to check for exceptions.
                -- The case of B being a 0 has already been covered above by a previous check.
                if (exponent_B = inf_exp) and (mantissa_B /= inf) then
                    -- We are multiplying inf or NaN by NaN, result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                elsif (mantissa_A /= inf) then
                    -- We are multiplying NaN by something, result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                else
                    -- We are multiplying inf by something different from NaN and 0, result is inf.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                end if;
            elsif (exponent_B = inf_exp) then
                -- If multiplyer is either inf or NaN we need to check for exceptions.
                -- The case of A being a 0 has already been covered above by a previous check.
                if (exponent_A = inf_exp) and (mantissa_A /= inf) then
                    -- We are multiplying NaN by inf or NaN, result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                elsif (mantissa_B /= inf) then
                    -- We are multiplying something by NaN, result is NaN.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '1');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                else
                    -- We are multiplying something different from NaN and 0 by inf, result is inf.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                end if;
            else
                -- STANDARD CASE
                -- Operands in normal range.
                -- Exponents are biased: get the unbiased value to work with.
                exp_A_int   :=  to_integer(unsigned(exponent_A)) - bias;
                exp_B_int   :=  to_integer(unsigned(exponent_B)) - bias;
                exp_M0_int  :=  exp_A_int + exp_B_int;
                if (exp_M0_int <= -bias) then
                    -- If exponent is too small or corresponding to subnormal product is 0 with correct sign.
                    exponent_M0 <=  zero_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                elsif (exp_M0_int >= bias+1) then
                    -- If exponent is too big or corresponding to special value product is inf with correct sign.
                    exponent_M0 <=  inf_exp;
                    mantissa_M0 <=  (others => '0');
                    exponent_M  <=  exponent_M0;
                    mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);   -- we use the same bits as in standard case to simplify.
                else
                    -- Everything is in normal range.
                    -- Re-bias and convert to std_logic_vector.
                    exponent_M0 <=  std_logic_vector(to_unsigned(exp_M0_int + bias, exponent));
                    mantissa_M0 <=  std_logic_vector(unsigned(mantissa_A) * unsigned(mantissa_B));
                    if (mantissa_M0(mantissa_M0'high) = '1') then
                        -- If multiplication is not normalized we shift right and adjust exponent, we need to check if we go to inf.
                        if (exponent_M0 = std_logic_vector(unsigned(inf_exp)-1)) then
                            -- If increasing exponent leads to inf assign inf.
                            exponent_M  <=  inf_exp;
                            mantissa_M  <=  (others => '0');
                        else
                            -- If exponent can be increased increase it and shift right.
                            exponent_M  <=  std_logic_vector(unsigned(exponent_M0) + 1);
                            -- Shifting right is equivalent to taking from MSB down and discarding the first bit as hidden bit.
                            mantissa_M  <=  mantissa_M0(mantissa_M0'high - 1 downto mantissa_M0'high - mantissa);
                        end if;
                    else
                        -- If multiplication is normalized we discard the first bit containing a 0, then the second as hidden bit.
                        exponent_M  <=  exponent_M0;
                        mantissa_M  <=  mantissa_M0(mantissa_M0'high - 2 downto mantissa_M0'high - 1 - mantissa);
                    end if;
                end if;
            end if;
    end process main;
    
    M   <=  sign_M & exponent_M & mantissa_M;
    
end architecture behavioural;
