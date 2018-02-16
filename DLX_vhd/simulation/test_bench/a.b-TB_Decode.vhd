library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity TB_Decode is
end entity TB_Decode;

architecture test of TB_Decode is

    component DecodeStage is
        generic (
            OP_CODE_SIZE : integer := operation_bits;   -- Op Code Size
            ALU_OPC_SIZE : integer := 10;               -- ALU Op Code Word Size
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
            RF_WR_addr_ID_ext:  out RF_addr_type;
            operand_A:          out word;       -- first operand for ALU
            operand_B:          out word;       -- second operand for ALU
            operation_PC:       out PC_type;    -- PC of the operation going to ALU
            -- Data from execute stage
            branch_taken:       in  std_logic;  -- '1' if previous instruction was a taken branch, '0' otherwise
            -- Controls to execute stage
            Execute_enable:     out std_logic;  -- Enable output latch of execute stage
            ALU_op:             out std_logic_vector(ALU_OPC_SIZE-1 downto 0);
            -- Controls to memory stage
            Memory_enable:      out std_logic;  -- Enable output latch and DRAM in memory stage
            DRAM_write:         out std_logic;  -- '0' to read from DRAM, '1' to write to DRAM
            MEM_out_select:     out std_logic;  -- '0' to output ALU result, '1' to output data from DRAM
            -- Data from memory stage (WB is embedded in register file itself)
            RF_WR_addr_bus_WB:  in  RF_addr_type;   -- Address in which register file should write
            RF_write_data:      in  word        -- Data to be written in register file
        );
    end component DecodeStage;
    
    signal  clk:                std_logic:= '0';    -- Clock
    signal  rst:                std_logic;  -- Reset: active low
    -- Data from fetch stage
    signal  instruction:        instruction_type;   -- Instruction to be decoded
    signal  instruction_PC:     PC_type;    -- PC of the instruction to be decoded, to be used in case of jumps
    -- Controls to fetch stage
    signal  Fetch_enable:       std_logic;  -- Enable latches and IRAM in fetch stage
    signal  use_jump_PC:        std_logic;  -- Use PC coming from ALU instead of next PC
    -- Data to execute stage
    signal  RF_WR_addr_ID_ext:  RF_addr_type;
    signal  operand_A:          word;       -- first operand for ALU
    signal  operand_B:          word;       -- second operand for ALU
    signal  operation_PC:       PC_type;    -- PC of the operation going to ALU
    -- Data from execute stage
    signal  branch_taken:       std_logic;  -- '1' if previous instruction was a taken branch, '0' otherwise
    -- Controls to execute stage
    signal  Execute_enable:     std_logic;  -- Enable output latch of execute stage
    signal  ALU_op:             std_logic_vector(9 downto 0);
    -- Controls to memory stage
    signal  Memory_enable:      std_logic;  -- Enable output latch and DRAM in memory stage
    signal  DRAM_write:         std_logic;  -- '0' to read from DRAM, '1' to write to DRAM
    signal  MEM_out_select:     std_logic;  -- '0' to output ALU result, '1' to output data from DRAM
    -- Data from memory stage (WB is embedded in register file itself)
    signal  RF_WR_addr_bus_WB:  RF_addr_type;   -- Address in which register file should write
    signal  RF_write_data:      word;       -- Data to be written in register file

begin

    uut: DecodeStage
        port map(
            clk                 =>  clk,
            rst                 =>  rst,
            instruction         =>  instruction,
            instruction_PC      =>  instruction_PC,
            Fetch_enable        =>  Fetch_enable,
            use_jump_PC         =>  use_jump_PC,
            RF_WR_addr_ID_ext   =>  RF_WR_addr_ID_ext,
            operand_A           =>  operand_A,
            operand_B           =>  operand_B,
            operation_PC        =>  operation_PC,
            branch_taken        =>  branch_taken,
            Execute_enable      =>  Execute_enable,
            ALU_op              =>  ALU_op,
            Memory_enable       =>  Memory_enable,
            DRAM_write          =>  DRAM_write,
            MEM_out_select      =>  MEM_out_select,
            RF_WR_addr_bus_WB   =>  RF_WR_addr_bus_WB,
            RF_write_data       =>  RF_write_data
        );
    
    clk_P: process
    begin
        wait for 5 ns;
        clk <=  not clk;
    end process clk_P;
    
    stim: process
    begin
        -- Reset
        rst                 <=  '0';
        instruction         <=  (others => '0');
        instruction_PC      <=  (others => '0');
        branch_taken        <=  '0';
        RF_WR_addr_bus_WB   <=  (is_float => '0', addr => (others => '0'));
        RF_write_data       <=  (others => '0');
        wait for 100 ns;
        -- Start
        rst                 <=  '1';
        wait for 10 ns;
        -- Execute 0x01
        instruction         <=  X"04000000";
        instruction_PC      <=  X"00000001";
        wait for 10 ns;
        -- Execute 0x0f, pad with '1's
        instruction         <=  X"3fffffff";
        instruction_PC      <=  X"00000002";
        wait;
    end process stim;

end architecture test;
