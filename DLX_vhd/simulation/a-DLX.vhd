library ieee;
use ieee.std_logic_1164.all;
use work.dlx_config.all;

entity DLX is
    port (
        clk:    in  std_logic;  -- Processor clock
        rst:    in  std_logic   -- Active low reset
    );
end DLX;


architecture dlx_structural of DLX is

 --------------------------------------------------------------------
 -- Components Declaration
 --------------------------------------------------------------------
 
    -- Fetch stage
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

    -- Decode stage
    component DecodeStage is
        generic (
            OP_CODE_SIZE : integer := operation_bits;   -- Op Code Size
            ALU_OPC_SIZE : integer := alu_opc_size;     -- ALU Op Code Word Size
            IR_SIZE      : integer := instruction_size; -- Instruction Register Size
            FUNC_SIZE    : integer := function_bits;    -- Func Field Size for R-Type Ops
            CW_SIZE      : integer := 17);              -- Control Word Size
        port (
            clk:                in  std_logic;  -- clock
            rst:                in  std_logic;  -- reset: active low
            -- Data from fetch stage
            instruction:        in  instruction_type;   -- instruction to be decoded
            instruction_PC:     in  PC_type;    -- PC of the instruction to be decoded, to be used in case of jumps
            -- Controls to fetch stage
            Fetch_enable:       out std_logic;  -- Enable latches and IRAM in fetch stage
            use_jump_PC:        out std_logic;  -- Use PC coming from ALU instead of next PC
            -- Data to execute stage
            RA:                 out word;       -- first operand for ALU, unless a jump/branch occurs
            RB:                 out word;       -- second operand for ALU, in R-type operations
            off:                out word;       -- second operand for ALU, in J-type operations
            imm:                out word;       -- second operand for ALU, in I-type operations
            operation_PC:       out PC_type;    -- first operand for ALU, in case a jump/branch occurs
            -- Data from execute stage
            branch_taken:       in  std_logic;  -- '1' if previous instruction was a taken branch, '0' otherwise
            -- Controls to execute stage
            Execute_enable:     out std_logic;  -- Enable output latch of execute stage
            use_offset:         out std_logic;  -- use offset as second operand (J-type operation)
            use_immediate:      out std_logic;  -- use immediate as second operand (I-type operation)
            ALU_op:             out std_logic_vector(ALU_OPC_SIZE-1 downto 0);
            -- Controls to memory stage
            Memory_enable:      out std_logic;  -- Enable output latch and DRAM in memory stage
            DRAM_write:         out std_logic;  -- '0' to read from DRAM, '1' to write to DRAM
            MEM_out_select:     out std_logic;  -- '0' to output ALU result, '1' to output data from DRAM
            -- Data from memory stage (WB is embedded in register file itself)
            RF_write_data:      in  word        -- Data to be written in register file
        );
    end component DecodeStage;
    
    -- Execute stage
    component ExecuteStage is
        port(
            clk:                    in  std_logic;  -- clock
            rst:                    in  std_logic;  -- reset, active low
            PC:                     in  word;       -- program counter of instruction in execution
            A:                      in  word;       -- first operand from register file
            B:                      in  word;       -- second operand from register file
            off:                    in  word;       -- second operand from offset field
            imm:                    in  word;       -- second operand from immediate field
            use_offset:             in  std_logic;  -- if '1' use off as second operand
            use_immediate:          in  std_logic;  -- if '1' use imm as second operand
            ALU_operation:          in  std_logic_vector(9 downto 0); -- sub & is_signed & use_pc & comp_0 & logic_op(2 downto 0) & output_sel(2 downto 0)
            EX_latch_en:            in  std_logic;  -- enable for output of stage
            branch_taken:           out std_logic;  -- branch was taken
            new_PC:                 out word;       -- PC after branch or jump
            EX_out:                 out word;       -- output of execute stage, going either in address of data memory or to writeback
            MEM_data:               out word        -- directly from input B delayed by one cycle, data to be stored in memory in store operations
        );
    end component ExecuteStage;
    
    -- Memory stage
    component MemoryStage is
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
    end component MemoryStage;
    
    -- Writeback stage
    -- WB is directly implemented in the write portion of the register file, instantiated in ID
    -- as it is needed to output the operands for EX.
    
    ------------------------------ SIGNALS ------------------------------
    -- Controls to IF
    signal  Fetch_enable:   std_logic;  -- Fetch stage is disabled if a jump or branch is detected, waiting for next PC to be resolved
    signal  use_jump_PC:    std_logic;  -- Use target PC instead of next one, high if a jump occurs or a branch is taken
    -- Data to IF
    signal  jump_PC:        PC_type;    -- Coming from EX stage, 1 cycle after jump or branch has been decoded
    -- Controls to ID
    signal  branch_taken:   std_logic;  -- Coming from EX stage, 1 if branch was taken
    -- Data from IF to ID
    signal  instruction:    instruction_type;
    signal  instruction_PC: PC_type;    -- PC corresponding to instruction, needed for jumps
    -- Controls to EX:
    signal  Execute_enable: std_logic;  -- Here for compliance to drawing, since NOPs are inserted in stall cycles there is no reason to disable stages
    signal  use_offset:     std_logic;  -- Use offset as second operand for ALU
    signal  use_immediate:  std_logic;  -- Use immediate as second operand for ALU
    signal  ALU_op:         std_logic_vector(alu_opc_size-1 downto 0);
    -- Data from ID to EX
    signal  operand_A:      word;       -- Operand from RF port read1
    signal  operand_B:      word;       -- Operand from RF port read2
    signal  offset:         word;       -- Operand from offset field in instruction
    signal  immediate:      word;       -- Operand from immediate field in instruction
    signal  operation_PC:   PC_type;    -- PC corresponding to operation, needed for jumps
    -- Controls to MEM:
    signal  Memory_enable:  std_logic;  -- Here for compliance to drawing, since NOPs are inserted in stall cycles there is no reason to disable stages
    signal  DRAM_write:     std_logic;  -- When high, write output of EX stage to DRAM
    signal  MEM_out_select: std_logic;  -- When low use EX output as MEM output, when high use DRAM output as MEM output
    -- Data from EX to MEM
    signal  result:         word;
    signal  MEM_data:       word;
    -- Data from MEM to WB
    signal  RF_write_data:  word;   -- Notice this is plugged into DecodeStage even if it occurs during WB, this is because the component is also active in ID in read mode
    


begin  -- DLX

    FS: FetchStage
        port map(
            clk             =>  clk,
            rst             =>  rst,
            stage_enable    =>  Fetch_enable,
            use_jump_PC     =>  use_jump_PC,
            jump_PC         =>  jump_PC,
            instruction     =>  instruction,
            old_PC          =>  instruction_PC
        );
    
    DS: DecodeStage
        port map(
            clk             =>  clk,
            rst             =>  rst,
            instruction     =>  instruction,
            instruction_PC  =>  instruction_PC,
            Fetch_enable    =>  Fetch_enable,
            use_jump_PC     =>  use_jump_PC,
            RA              =>  operand_A,
            RB              =>  operand_B,
            off             =>  offset,
            imm             =>  immediate,
            operation_PC    =>  operation_PC,
            branch_taken    =>  branch_taken,
            Execute_enable  =>  Execute_enable,
            use_offset      =>  use_offset,
            use_immediate   =>  use_immediate,
            ALU_op          =>  ALU_op,
            Memory_enable   =>  Memory_enable,
            DRAM_write      =>  DRAM_write,
            MEM_out_select  =>  MEM_out_select,
            RF_write_data   =>  RF_write_data
        );
    
    ES: ExecuteStage
        port map(
            clk             =>  clk,
            rst             =>  rst,
            PC              =>  operation_PC,
            A               =>  operand_A,
            B               =>  operand_B,
            off             =>  offset,
            imm             =>  immediate,
            use_offset      =>  use_offset,
            use_immediate   =>  use_immediate,
            ALU_operation   =>  ALU_op,
            EX_latch_en     =>  Execute_enable,
            branch_taken    =>  branch_taken,
            new_PC          =>  jump_PC,
            EX_out          =>  result,
            MEM_data        =>  MEM_data
        );
    
    MS: MemoryStage
        port map(
            clk             =>  clk,
            rst             =>  rst,
            enable          =>  Memory_enable,
            DRAM_ctrl       =>  DRAM_write,
            out_sel         =>  MEM_out_select,
            EX_out          =>  result,
            MEM_data        =>  MEM_data,
            MEM_out         =>  RF_write_data
        );
    

end dlx_structural;
