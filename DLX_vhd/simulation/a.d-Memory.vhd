library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity MemoryStage is
    port(
        clk:                in  std_logic;  -- clock
        rst:                in  std_logic;  -- reset, active low
        enable:             in  std_logic;  -- enable for DRAM and output latch, active high
        DRAM_ctrl:          in  std_logic;  -- read/write control for DRAM: '0' to read, '1' to write
        out_sel:            in  std_logic;  -- '0' to output ALU result, '1' to output the output of DRAM
        EX_out:             in  word;       -- output of execute stage used as address for memory or as stage output
        MEM_data:           in  word;       -- data coming from register file and properly delayed to be stored in memory
        MEM_out:            out word        -- output of memory stage
    );
end entity MemoryStage;

architecture structural of MemoryStage is

    component DRAM is
        port(
            clk:    in  std_logic;  -- clock
            res:    in  std_logic;  -- reset, active low
            enable: in  std_logic;  -- enable, active high
            ctrl:   in  std_logic;  -- '0' to read, '1' to write
            addr:   in  word;       -- address
            D_in:   in  word;       -- incoming data
            D_out:  out word        -- output data
        );
    end component DRAM;

    signal  DRAM_out:       word;
    
    signal  EX_del:         word;
    
begin

    DRAM_1: DRAM
        port map(
            clk     =>  clk,
            res     =>  rst,
            enable  =>  enable,
            ctrl    =>  DRAM_ctrl,
            addr    =>  EX_out,
            D_in    =>  MEM_data,
            D_out   =>  DRAM_out
        );
    
    -- Purpose:         delay input from execute stage to synch with output of DRAM
    -- Type:            sequential
    -- Inputs:          res, clk, enable, MEM_out_bus
    -- Outputs:         MEM_out
    -- Implementation:  latch
    D_P: process(rst, clk)
    begin
        if rst = '0' then
            EX_del <=  (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                EX_del <=  EX_out;
            end if;
        end if;
    end process D_P;
    
    -- Purpose:         select output of memory stage
    -- Type:            combinational
    -- Inputs:          out_sel, EX_del, DRAM_out
    -- Outputs:         MEM_out
    -- Implementation:  multiplexer
    OS_P: process(out_sel, EX_del, DRAM_out)
    begin
        if out_sel = '0' then
            MEM_out     <=  EX_del;
        else
            MEM_out     <=  DRAM_out;
        end if;
    end process OS_P;

end architecture structural;
