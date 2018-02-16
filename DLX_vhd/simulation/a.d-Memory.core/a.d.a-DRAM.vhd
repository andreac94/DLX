library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity DRAM is
    port(
        clk:    in  std_logic;  -- clock
        res:    in  std_logic;  -- reset, active low
        enable: in  std_logic;  -- enable, active high
        ctrl:   in  std_logic;  -- '0' to read, '1' to write
        addr:   in  word;       -- address
        D_in:   in  word;       -- incoming data
        D_out:  out word        -- output data
    );
end entity DRAM;

architecture behavioural of DRAM is

    type    memory_type is array (0 to DRAM_depth-1) of word;
    signal  memory: memory_type;

begin

    -- Purpose:         implement module
    -- Type:            sequential
    -- Inputs:          clk, res, enable, ctrl, addr, D_in
    -- Outputs:         D_out
    -- Implementation:  RAM
    main: process(clk, res)
    begin
        if res = '0' then   -- reset everything to '0' and output '0'
            memory  <=  (others => (others => '0'));
            D_out   <=  (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                if ctrl = '0' then
                    D_out   <=  memory(to_integer(unsigned(addr)));
                else
                    memory(to_integer(unsigned(addr)))  <=  D_in;
                end if;
            end if;
        end if;
    end process main;

end architecture behavioural;
