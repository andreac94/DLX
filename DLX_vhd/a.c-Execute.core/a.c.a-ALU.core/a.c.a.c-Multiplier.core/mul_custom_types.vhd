library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

package mul_custom_types is
    -- matrices
    type pg_matrix is array (natural range <>) of std_logic_vector(NumBit-1 downto 0);
    type carry_matrix is array (natural range <>) of std_logic_vector(Numbit/RCA_width-1 downto 0);
    type Matrix_64 is array (natural range <>) of std_logic_vector(63 downto 0);

    -- enumerations
    type tree_mantain_level_template is array (natural range <>) of character;
end package mul_custom_types;
