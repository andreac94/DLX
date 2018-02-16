library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity TB_AdderSubtractor is
end entity TB_AdderSubtractor;

architecture test of TB_AdderSubtractor is

    component AdderSubtractor is
        port(
            A:          in  word;
            B:          in  word;
            sub:        in  std_logic;
            is_signed:  in  std_logic;
            O:          out word;
            overflow:   out std_logic
        );
    end component AdderSubtractor;
    
    signal  A:          word;
    signal  B:          word;
    signal  sub:        std_logic;
    signal  is_signed:  std_logic;
    signal  O:          word;
    signal  overflow:   std_logic;
    
begin

    UUT:    AdderSubtractor
        port map(
            A           =>  A,
            B           =>  B,
            sub         =>  sub,
            is_signed   =>  is_signed,
            O           =>  O,
            overflow    =>  overflow
        );
    
    stim:   process
    begin
        -- Unsigned addition: (2+2)*10^9 = 4*10^9, no overflow
        A           <=  std_logic_vector(to_unsigned(2000000000, 32));
        B           <=  std_logic_vector(to_unsigned(2000000000, 32));
        sub         <=  '0';
        is_signed   <=  '0';
        wait for 10 ns;
        -- Signed addition: (2+2)*10^9 = 4*10^9, overflow (result interpreted as negative)
        is_signed   <=  '1';
        wait for 10 ns;
        -- Unsigned subtraction: (2-2)*10^9 = 0, no overflow
        sub         <=  '1';
        is_signed   <=  '0';
        wait for 10 ns;
        -- Signed subtraction: (2-2)*10^9 = 0, no overflow
        is_signed   <=  '1';
        wait;
    end process stim;

end architecture test;
