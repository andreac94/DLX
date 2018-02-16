library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.dlx_config.all;


entity TB_Fetch is
end entity TB_Fetch;


architecture test of TB_Fetch is

    component FetchStage is
        port(
            clk:            in  std_logic;          -- Processor clock
            rst:            in  std_logic;          -- Active low reset
            stage_enable:   in  std_logic;          -- Enable for fetch stage
            use_jump_PC:    in  std_logic;          -- Select wether new PC should be next one or ALU-computed one
            jump_PC:        in  PC_type;            -- New PC coming from ALU (execute stage), used only in case of jumps and branches
            instruction:    out instruction_type;   -- Instruction to be decoded by next stage
            old_PC:         out PC_type             -- PC of instruction being on output, needed by ID stage for jumps
        );
    end component FetchStage;
    
    signal  clk:            std_logic:= '0';
    signal  rst:            std_logic;
    signal  stage_enable:   std_logic;
    signal  use_jump_PC:    std_logic;
    signal  jump_PC:        PC_type;
    signal  instruction:    instruction_type;
    signal  old_PC:         PC_type;

begin

    clk <=  not clk after   clk_period/2;
    
    UUT: FetchStage
        port map(
            clk             =>  clk,
            rst             =>  rst,
            stage_enable    =>  stage_enable,
            use_jump_PC     =>  use_jump_PC,
            jump_PC         =>  jump_PC,
            instruction     =>  instruction,
            old_PC          =>  old_PC
        );
    
    stimuli: process
    begin
        rst             <=  '1';    -- System in undefined state
        stage_enable    <=  '0';
        use_jump_PC     <=  '0';
        jump_PC         <=  (others => '0');
        wait for 10 ns;
        rst             <=  '0';    -- Reset system
        wait for 90 ns;
        rst             <=  '1';    -- System working
        stage_enable    <=  '1';
        wait for 300 ns;
        use_jump_PC <=  '1';
        wait for 200 ns;
        use_jump_PC <=  '0';
        wait;
    end process stimuli;

end architecture test;
