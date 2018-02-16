library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package complement is

    function complement(X: std_logic_vector) return std_logic_vector;

end package complement;

package body complement is

    function complement(X: std_logic_vector) return std_logic_vector is
        variable    X0: std_logic_vector(X'high downto X'low);
        variable    Y:  std_logic_vector(X'high downto X'low);
    begin
        X0  :=  not(X);
        Y   :=  std_logic_vector(unsigned(X0) + 1);
        return Y;
    end function complement;

end package body complement;
