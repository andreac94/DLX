library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FP_divider is
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
        D:      out         std_logic_vector(nbit-1 downto 0)
    );
end entity FP_divider;

architecture behavioural of FP_divider is

    signal  sign_A:         std_logic;
    signal  sign_B:         std_logic;
    signal  exponent_A:     std_logic_vector(exponent-1 downto 0);
    signal  exponent_B:     std_logic_vector(exponent-1 downto 0);
    signal  mantissa_A:     std_logic_vector(2*mantissa downto 0); -- 23 additional bits set to 0 after lsb so that integer magnitude division is not always 1.
    signal  mantissa_B:     std_logic_vector(2*mantissa downto 0); -- 23 additional bits set to 0 before msb.
                            
    signal  sign_D0:        std_logic;
    signal  exponent_D0:    std_logic_vector(exponent-1 downto 0);
    signal  mantissa_D0:    std_logic_vector(mantissa downto 0);
                            
    signal  sign_D:         std_logic;
    signal  exponent_D:     std_logic_vector(exponent-1 downto 0);
    signal  mantissa_D:     std_logic_vector(mantissa-1 downto 0);

begin

    sign_A      <=  A(nbit-1);
    sign_B      <=  B(nbit-1);
    
    exponent_A  <=  A(exponent+mantissa-1 downto mantissa);
    exponent_B  <=  B(exponent+mantissa-1 downto mantissa);
    
    
    -- TODO: take care of dimensins and figure out shifting for unsigned division of mantissas 
    mantissa_A  <=  '1' & A(mantissa-1 downto 0) & (mantissa-1 downto 0 => '0');
    mantissa_B  <=  (mantissa-1 downto 0 => '0') & '1' & B(mantissa-1 downto 0);
    
    main: process(clk)
        variable    exp_A_int:      integer;
        variable    exp_B_int:      integer;
        variable    exp_D0_int:     integer;
        variable    div_res:        std_logic_vector(2*mantissa downto 0);
        constant    zero_exp:       std_logic_vector(exponent-1 downto 0):= (others => '0');
        constant    inf_exp:        std_logic_vector(exponent-1 downto 0):= (others => '1');
        constant    zero:           std_logic_vector(mantissa-1 downto 0):= (others => '0');
        constant    inf:            std_logic_vector(mantissa-1 downto 0):= (others => '0');
        constant    NaN:            std_logic_vector(mantissa-1 downto 0):= (others => '1');
    begin
    
        sign:
            -- Sign is negative iff one and only one of the operands is negative.
            sign_D0 <=  sign_A xor sign_B;
            sign_D  <=  sign_D0;
        
        div:
            if (exponent_A = inf_exp) then
                -- We are dividing inf or NaN by something.
                if (exponent_B = inf_exp) then
                    -- We are dividing inf or NaN by inf or NaN: result is NaN.
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '1');
                elsif (exponent_B = zero_exp) then
                    -- We are dividing inf or NaN by zero: result is NaN.
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '1');
                elsif (mantissa_A = (mantissa_A'range => '1')) then
                    -- We are dividing NaN by something different from zero, inf or NaN: result is NaN.
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '1');
                else
                    -- We are dividing inf by something different from zero, inf or NaN: result is inf (with either sign).
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '0');
                end if;
                exponent_D  <=  exponent_D0;
                mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);
            elsif (exponent_B = inf_exp) then
                -- We are dividing a finite quantity by inf or NaN
                if (mantissa_B = (mantissa_A'range => '1')) then
                    -- We are dividing something by NaN: result is NaN.
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '1');
                else
                    -- We are dividing a finite number by inf: result is zero.
                    exponent_D0 <=  zero_exp;
                    mantissa_D0 <=  (others => '0');
                end if;
                exponent_D  <=  exponent_D0;
                mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);
            elsif (exponent_B = zero) then
                -- We are dividing a finite number by zero: result is NaN.
                exponent_D0 <=  inf_exp;
                mantissa_D0 <=  (others => '1');
                exponent_D  <=  exponent_D0;
                mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);
            else
                -- STANDARD CASE
                -- Operands in normal range.
                -- Exponents are biased: get the unbiased value to work with.
                exp_A_int   :=  to_integer(unsigned(exponent_A)) - bias;
                exp_B_int   :=  to_integer(unsigned(exponent_B)) - bias;
                exp_D0_int  :=  exp_A_int - exp_B_int;
                if (exp_D0_int <= -bias) then
                    -- If exponent is too small or corresponding to subnormal product is 0 with correct sign.
                    exponent_D0 <=  zero_exp;
                    mantissa_D0 <=  (others => '0');
                    exponent_D  <=  exponent_D0;
                    mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);   -- Discard hidden bit.
                elsif (exp_D0_int >= bias+1) then
                    -- If exponent is too big or corresponding to special value product is inf with correct sign.
                    exponent_D0 <=  inf_exp;
                    mantissa_D0 <=  (others => '0');
                    exponent_D  <=  exponent_D0;
                    mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);   -- Discard hidden bit.
                else
                    -- Everything is in normal range.
                    -- Re-bias and convert to std_logic_vector.
                    exponent_D0 <=  std_logic_vector(to_unsigned(exp_D0_int + bias, exponent));
                    div_res     :=  std_logic_vector(unsigned(mantissa_A) / unsigned(mantissa_B));
                    mantissa_D0 <=  div_res(mantissa downto 0);
                    if (mantissa_D0(mantissa_D0'high) = '0') then
                        -- We have a leading zero and we need to normalize. Extreme cases are 2/1=2 and 1/2=0.5.
                        if (exponent_D0 = std_logic_vector(unsigned(zero)+1)) then
                            -- If decreasing exponent leads to zero assign zero
                            exponent_D  <=  zero_exp;
                            mantissa_D  <=  zero;
                        else
                            -- We can decrease exponent and shift mantissa.
                            exponent_D  <=  std_logic_vector(unsigned(exponent_D0) - 1);
                            mantissa_D  <=  std_logic_vector(unsigned(mantissa_D0(mantissa-1 downto 0)) sll 1);
                        end if;
                    else
                        -- We don't need to normalize.
                        exponent_D  <=  exponent_D0;
                        mantissa_D  <=  mantissa_D0(mantissa-1 downto 0);
                    end if;
                end if;
            end if;
    end process main;
    
    D   <=  sign_D & exponent_D & mantissa_D;

end architecture behavioural;
