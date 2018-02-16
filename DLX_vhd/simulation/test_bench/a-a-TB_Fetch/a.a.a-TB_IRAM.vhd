library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity TB_IRAM is
end entity TB_IRAM;

architecture test of TB_IRAM is

    component IRAM is
        port (
            Rst:    in  std_logic;
            Addr:   in  std_logic_vector(PC_size - 1 downto 0);
            Dout:   out std_logic_vector(instruction_size - 1 downto 0)
        );
    end component IRAM;
    
    signal  rst:    std_logic;
    signal  Addr:   std_logic_vector(instruction_size-1 downto 0);
    signal  Dout:   std_logic;

begin

    stim: process
    begin
        rst     <=  '0';
        Addr    <=  std_logic_vector(to_unsigned(0,instruction_size));
        wait for 10 ns;
        rst     <=  '1';
        for cycle in 0 to 1000 loop
            wait for 10 ns;
            Addr    <=  std_logic_vector(to_unsigned(cycle,instruction_size));
        end loop;
        wait;
    end process stim;

end architecture test;
