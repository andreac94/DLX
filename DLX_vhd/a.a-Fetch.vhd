library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dlx_config.all;

-- Fetch stage behaviour:
-- 3 registers:
--      PC acts as address of IRAM, autoincrements unless disabled
--      IR outputs the instruction fetched at previous clock cycle
--      old_PC outputs the address of the instruction fetched at previous clock cycle
--
-- Standard behaviour:
-- RESET
-- PC=0;    IR=NOP;     old_PC=0;
-- PC=1;    IR=I_0;     old_PC=0;
-- PC=2;    IR=I_1;     old_PC=1;
-- ...
--
-- Jump behaviour:
-- RESET
-- PC=0;    IR=NOP;     old_PC=0;
-- PC=1;    IR=I_0;     old_PC=0;
-- PC=2;    IR=I_1;     old_PC=1;
-- PC=3;    IR=JUMP;    old_PC=2;   -> ID now disables IF while waiting for jump address
-- PC=3;    IR=NOP;     old_PC=0;   -> EX now outputs address J, ID instructs fetch to use address J
-- PC=J;    IR=NOP;     old_PC=0;
-- PC=J+1;  IR=I_J;     old_PC=J;
-- ...
--
-- Taken branch:
-- RESET
-- PC=0;    IR=NOP;     old_PC=0;
-- PC=1;    IR=I_0;     old_PC=0;
-- PC=2;    IR=I_1;     old_PC=1;
-- PC=3;    IR=BRANCH;  old_PC=2;   -> ID now disables IF while waiting for target address
-- PC=3;    IR=NOP;     old_PC=0;   -> EX now outputs address J and says branch is taken, ID instructs fetch to use address J
-- PC=J;    IR=NOP;     old_PC=0;
-- PC=J+1;  IR=I_J;     old_PC=J;
-- ...
--
-- Not taken branch:
-- RESET
-- PC=0;    IR=NOP;     old_PC=0;
-- PC=1;    IR=I_0;     old_PC=0;
-- PC=2;    IR=I_1;     old_PC=1;
-- PC=3;    IR=BRANCH;  old_PC=2;   -> ID now disables IF while waiting for jump address
-- PC=3;    IR=NOP;     old_PC=0;   -> EX now outputs address J and says branch is not taken, ID instructs fetch to use next PC
-- PC=3;    IR=NOP;     old_PC=0;   <- We could have a ready operation here but this would require ID to issue different controls depending on branch result
-- PC=4;    IR=I_3;     old_PC=3;
-- ...
--
-- This requires:
--      PC stays constants if not enabled (latch)
--      IR is NOP if not enabled (reset IR)
--      old_PC is 0 if not enabled (reset old_PC)


entity FetchStage is
    port(
        clk:            in  std_logic;          -- Processor clock
        rst:            in  std_logic;          -- Active low reset
        stage_enable:   in  std_logic;          -- Enable for fetch stage
        use_jump_PC:    in  std_logic;          -- Select wether new PC should be next one or ALU-computed one
        jump_PC:        in  PC_type;            -- New PC coming from ALU (execute stage), used only in case of jumps and branches
        instruction:    out instruction_type;   -- Instruction to be decoded by next stage
        old_PC:         out PC_type             -- PC of instruction being on output, needed by ID stage for jumps
    );
end entity FetchStage;


architecture fetch_rtl of FetchStage is

    --Instruction Ram
    component IRAM
        port(
            Rst:    in  std_logic;
            Addr:   in  std_logic_vector(PC_size - 1 downto 0);
            Dout:   out std_logic_vector(instruction_size - 1 downto 0)
        );
    end component;
    
    -- Instruction Register
    signal  IR: instruction_type;
    
    -- Program Counter
    signal  PC: PC_type;
    
    -- Next Program Counter, equal to PC+1
    signal  next_PC:    PC_type;
    
    -- Bus connecting IRAM and IR
    signal  IRAM_D_out: instruction_type;
    
    -- Bus containing the value of the program counter to be used in next clock cycle (either next_PC or jump_PC)
    signal  PC_bus:     PC_type;

begin

    -- Instruction RAM instantiation
    IRAM_1: IRAM
        port map(
            Rst     =>  rst,        -- On processor reset, reset IRAM too
            Addr    =>  PC,         -- PC is used as address to get instruction
            Dout    =>  IRAM_D_out  -- IRAM writes instruction on bus going to IR
        );
    
    -- Purpose:         calculate next PC to be used by default (no jumps)
    -- Type:            combinational
    -- Inputs:          PC
    -- Ouptuts:         next_PC
    -- Implementation:  counter
    NPC_P: process(PC)
    begin
        next_PC <=  std_logic_vector(unsigned(PC) + 1);
    end process NPC_P;
    
    -- Purpose:         assign value to PC_bus
    -- Type:            combinational
    -- Inputs:          next_PC, jump_PC, use_jump_PC
    -- Ouptuts:         PC_bus
    -- Implementation:  2-to-1 multiplexer
    PCB_P: process(next_PC, jump_PC, use_jump_PC)
    begin
        if use_jump_PC = '0' then
            PC_bus  <=  next_PC;
        else
            PC_bus  <=  jump_PC;
        end if;
    end process PCB_P;
    
    -- Purpose:         update Program Counter
    -- Type   :         sequential
    -- Inputs :         clk, rst, PC_bus, PC_latch_en
    -- Outputs:         PC (connected to IRAM address port)
    -- Implementation:  latch
    PC_P: process (clk, rst)
    begin
        if rst = '0' then           -- asynchronous reset (active low)
            PC  <=  (others => '0');
        elsif rising_edge(clk) then -- rising clock edge
            -- if a jump happens we have to override the enable JUST FOR PC
            -- in order to have the jump instruction
            if (stage_enable = '1') or (use_jump_PC = '1') then
                PC  <=  PC_bus;
            end if;
        end if;
    end process PC_P;
    
    -- Purpose:         update Instruction Register
    -- Type   :         sequential
    -- Inputs :         clk, rst, IRAM_D_out, IR_latch_en
    -- Outputs:         IR (connected to decode stage instruction port) 
    -- Implementation:  latch
    IR_P: process (clk, rst)
    begin
        if rst = '0' then   -- asynchronous reset (active low)
            IR <= X"54000000";
        elsif rising_edge(clk) then -- rising clock edge
            if (stage_enable = '1') and (use_jump_PC = '0') then
                IR  <=  IRAM_D_out;
            else
                IR  <=  X"54000000";    -- Set to NOP on stage disabled and on jumps
            end if;
        end if;
    end process IR_P;
    
    -- Purpose:         provide PC of instruction on output to ID stage
    -- Type   :         sequential
    -- Inputs :         clk, rst, PC
    -- Outputs:         old_PC (connected to decode stage instruction_PC port) 
    -- Implementation:  register
    OPC_P: process (clk, rst)
    begin
        if rst = '0' then           -- asynchronous reset (active low)
            old_PC <= (others => '0');
        elsif rising_edge(clk) then -- rising clock edge
            if (stage_enable = '1') and (use_jump_PC = '0') then
                old_PC  <=  PC;
            else
                old_PC  <=  (others => '0');    -- Set to 0 on stage disabled and on jumps
            end if;
        end if;
    end process OPC_P;
    
    instruction <=  IR;
end architecture fetch_rtl;
