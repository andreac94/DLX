library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dlx_config.all;
use work.microcode_memory.all;

entity DecodeStage is
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
end entity DecodeStage;

architecture dlx_cu_pu of DecodeStage is

  ------------------------------ MICROCODE CONTROL UNIT ------------------------------

    signal  reloc_mem:  reloc_mem_array:=   reloc_mem_content;      -- Defined in 001-microcode_memory.vhd

    signal  microcode:  mem_array:=         microcode_mem_content;  -- Defined in 001-microcode_memory.vhd

    signal  cw:                 std_logic_vector(CW_SIZE - 1 downto 0);

    signal  uPC:                integer range 0 to 127;
    signal  OpCode:             std_logic_vector(OP_CODE_SIZE - 1 downto 0);
    signal  OpCode_Reloc:       std_logic_vector(OP_CODE_SIZE + 1 downto 0);
    
    constant    R_OPCODE:       std_logic_vector(OP_CODE_SIZE -1 downto 0):=    "000000";
    constant    F_OPCODE:       std_logic_vector(OP_CODE_SIZE -1 downto 0):=    "000001";
                                                            
    signal  func:               unsigned(FUNC_SIZE - 1 downto 0);
    
  ------------------------------ REGISTER FILE ------------------------------
  
    component RegisterFile is
        generic(
            address_bits:   natural:=   5   -- 32 general-purpose registers and 32 floating-point registers, for a total of 64
        );
        port(
            clk:            in  std_logic;  -- clock
            rst:            in  std_logic;  -- reset, active low
            enable:         in  std_logic;  -- enable, active high
            write_ctrl:     in  std_logic;  -- control signal, when high RF writes from port write_data to proper register
            read1_ctrl:     in  std_logic;  -- control signal, when high RF reads from proper register to port read1_data
            read2_ctrl:     in  std_logic;  -- control signal, when high RF reads from proper register to port read2_data
            write_address:  in  RF_addr_type;   -- address in which memory output or ALU result will be written
            read1_address:  in  RF_addr_type;   -- address in which data to be output on port read1_data resides
            read2_address:  in  RF_addr_type;   -- address in which data to be output on port read2_data resides
            write_data:     in  word;   -- data from memory or ALU here
            read1_data:     out word;   -- data to register_A here
            read2_data:     out word    -- data to register_B here
        );
    end component RegisterFile;
    
    -- Controls
    signal  RF_WR_ctrl:             std_logic;  -- read control for port write, active high
    
    -- Address busses
    signal  RF_RD1_addr_bus:        RF_addr_type;
    signal  RF_RD2_addr_bus:        RF_addr_type;
    signal  RF_WR_addr:             RF_addr_vector(3 downto 0);
    
    -- Data from RF
    signal  RF_read1_data:          word;
    signal  RF_read2_data:          word;
    
  ------------------------------ OPERAND SELECTION ------------------------------
  
    -- Data from instruction
    signal  offset:                 word;
    signal  immediate:              word;
    
    -- Operand selection
    signal  is_jump:                std_logic_vector(1 downto 0);  -- when (0) is high use offset field (lower 26 bits of instruction) as second operand
    signal  is_immediate:           std_logic;  -- when high use immediate field (lower 16 bits of instruction) as second operand
    
    -- Operands latches enable
    signal  Decode_enable:          std_logic;
    
  ------------------------------ OPERATION TYPE ------------------------------
  
    signal  is_float:               std_logic;

  ------------------------------ STAGE CONTROLS ------------------------------
    
    signal  enable_fetch_stage:     std_logic_vector(1 downto 0);
    signal  RF_WR_vector:           std_logic_vector(3 downto 0);
    signal  enable_execute_stage:   std_logic_vector(1 downto 0);
    signal  enable_memory_stage:    std_logic_vector(2 downto 0);
    signal  enable_DRAM_wr:         std_logic_vector(2 downto 0);
    signal  select_MEM_out:         std_logic_vector(2 downto 0);
    
begin  -- dlx_cu_rtl

    RF: RegisterFile
        port map(
            clk             =>  clk,
            rst             =>  rst,
            enable          =>  '1',                -- RF always enabled
            write_ctrl      =>  RF_WR_ctrl,
            read1_ctrl      =>  '1',                -- RF always reads, output might be ignored later on
            read2_ctrl      =>  '1',                -- RF always reads, output might be ignored later on
            write_address   =>  RF_WR_addr(3),
            read1_address   =>  RF_RD1_addr_bus,
            read2_address   =>  RF_RD1_addr_bus,
            write_data      =>  RF_write_data,
            read1_data      =>  RF_read1_data,
            read2_data      =>  RF_read2_data
        );

    -- Purpose:         generation of source and destination addresses for RF
    -- Type:            combinational
    -- Inputs:          instruction
    -- Outputs:         RF_WR_addr_bus_ID (connected to RF WR_addr port after register skew),
    --                  RF_RD1_addr_bus (connected to RF RD1_addr port),
    --                  RF_RD2_addr_bus (connected to RF RD2_addr port)
    -- Implementation:  multiplexers
    RF_P: process(instruction)
    begin
        if (opcode = R_OPCODE) or (opcode = F_OPCODE) then  -- R-type and F-type, 3 registers
            RF_RD1_addr_bus.addr    <=  instruction(25 downto 21);
            RF_RD2_addr_bus.addr    <=  instruction(20 downto 16);
            RF_WR_addr(0).addr  <=  instruction(15 downto 11);
        else    -- I-type or J-type, J-type ignores this anyway
            RF_RD1_addr_bus.addr    <=  instruction(25 downto 21);
            RF_RD2_addr_bus.addr    <=  instruction(20 downto 16);  -- unused
            RF_WR_addr(0).addr  <=  instruction(20 downto 16);
        end if;
        if opcode = F_OPCODE then
            RF_RD1_addr_bus.is_float    <=  '1';
            RF_RD2_addr_bus.is_float    <=  '1';
            RF_WR_addr(0).is_float      <=  '1';
        else
            RF_RD1_addr_bus.is_float    <=  '0';
            RF_RD2_addr_bus.is_float    <=  '0';
            RF_WR_addr(0).is_float      <=  '0';
        end if;
    end process RF_P;
    
    -- Purpose:         delaying RF_WR_addr to use it when data to write is ready
    -- Type:            sequential
    -- Inputs:          clk, rst, RF_WR_addr_bus_ID, RF_WR_addr_ID_latch_en
    -- Outputs:         RF_WR_addr_ID (connected to later stages of pipeline)
    -- Implementation:  latch
    WR_ADDR_P: process(rst, clk)
    begin
        if rst = '0' then           -- asynchronous reset (active low)
            RF_WR_addr      <=  (others => (is_float => '0', addr => (others => '0')));
        elsif rising_edge(clk) then -- rising clock edge
            RF_WR_addr(1)   <=  RF_WR_addr(0);
            RF_WR_addr(2)   <=  RF_WR_addr(1);
            RF_WR_addr(3)   <=  RF_WR_addr(2);
        end if;
    end process WR_ADDR_P;
    
    -- Extend immediate values to comply to 32-bit format
    offset      <= "000000" & instruction(offset_bits-1 downto 0);
    immediate   <= X"0000" & instruction(immediate_bits-1 downto 0);
    
    -- Purpose:         selection of appropriate operands for ALU
    -- Type:            sequential
    -- Inputs:          clk, rst, instruction_PC, RF_read1_data, RF_read2_data, immediate, offset
    -- Outputs:         RA, RB, off, imm,
    -- Implementation:  multiplexers and registers
    OS_P: process(clk, rst)
    begin
        if rst = '0' then
            RA  <=  (others => '0');
            RB  <=  (others => '0');
            off <=  (others => '0');
            imm <=  (others => '0');
            use_offset      <=  '0';
            use_immediate   <=  '0';
        elsif rising_edge(clk) then
            -- operand A always comes from register file, as PC is passed in parallel for jumps and branches anyway
            RA  <=  RF_read1_data;
            RB  <=  RF_read2_data;
            off <=  offset;
            imm <=  immediate;
            if is_jump(0) = '1' then        -- J and JAL only
                use_offset      <=  '1';
                use_immediate   <=  '0';
            elsif is_immediate = '1' then   -- Includes all conditional branches
                use_offset      <=  '0';
                use_immediate   <=  '1';
            else                            -- R-type or F-type operation
                use_offset      <=  '0';
                use_immediate   <=  '0';
            end if;
        end if;
    end process OS_P;
    
    -- Purpose:         send EX stage the PC of the instruction it is executing
    -- Type:            sequential
    -- Inputs:          clk, rst, instruction_PC
    -- Outputs:         operation_PC
    -- Implementation:  register
    PC_P: process(clk, rst)
    begin
        if rst = '0' then
            operation_PC    <=  (others => '0');
        elsif rising_edge(clk) then
            operation_PC    <=  instruction_PC;
        end if;
    end process PC_P;

    cw <= microcode(uPC);

    -- Fetch stage controls
    -- These controls are only used for jumps and control flow stuff.
    -- As such, they ALWAYS span over two instructions while waiting for
    -- address calculation and condition evaluation. The enable signal
    -- has to be recessive if it conflicts with a disable from the previous
    -- instruction. For clarification check examples on top of fetch stage
    -- definition (a.a-Fetch.vhd).
    enable_fetch_stage(0)   <=  cw(cw'high);
    DELAY_FETCH_EN: process(rst, clk)
    begin
        if rst = '0' then
            enable_fetch_stage(1)   <=  '0';
        elsif rising_edge(clk) then
            enable_fetch_stage(1)   <=  enable_fetch_stage(0);
        end if;
    end process DELAY_FETCH_EN;
    -- Fetch stage is enabled only if neither current instruction nor the
    -- previous one is a control flow instruction
    Fetch_enable    <=  enable_fetch_stage(0) and enable_fetch_stage(1);
    -- PC from jump is used if previous instruction was a jump or
    -- ALU said branch of previous instruction is taken.
    -- is_jump(0) is used in ID and it is directly mapped on control word.
    DELAY_IS_JUMP: process(rst, clk)
    begin
        if rst = '0' then
            is_jump(1)  <=  '0';
        elsif rising_edge(clk) then
            is_jump(1)  <=  is_jump(0);
        end if;
    end process DELAY_IS_JUMP;
    -- both is_jump and branch_taken refer to previous instruction as former
    -- is delayed by a register and latter comes from subsequent stage.
    use_jump_PC     <=  is_jump(1) or branch_taken;
    -- Decode stage controls
    is_jump(0)      <=  cw(cw'high);
    is_immediate    <=  cw(cw'high - 1);
    RF_WR_vector(0) <=  cw(cw'high - 2);
    DELAY_RF_WR: process(rst, clk)
    begin
        if rst = '0' then
            RF_WR_vector(3 downto 1)    <=  "000";
        elsif rising_edge(clk) then
            RF_WR_vector(1) <=  RF_WR_vector(0);
            RF_WR_vector(2) <=  RF_WR_vector(1);
            RF_WR_vector(3) <=  RF_WR_vector(2);
        end if;
    end process DELAY_RF_WR;
    RF_WR_ctrl      <=  RF_WR_vector(3);
    -- Execute stage controls
    enable_execute_stage(0) <=  cw(cw'high - 3);
    DELAY_EX_EN: process(rst, clk)
    begin
        if rst = '0' then
            enable_execute_stage(1) <=  '0';
        elsif rising_edge(clk) then
            enable_execute_stage(1) <=  enable_execute_stage(0);
        end if;
    end process DELAY_EX_EN;
    Execute_enable  <=  enable_execute_stage(1);
    DELAY_ALU_OP: process(rst, clk)
    begin
        if rst = '0' then
            ALU_op  <=  (others => '0');
        else
            ALU_op  <=  cw(cw'high - 4 downto cw'high - 13);
        end if;
    end process DELAY_ALU_OP;
    -- Memory stage controls
    enable_memory_stage(0)  <=  cw(cw'high - 14);
    DELAY_MEM_EN: process(rst, clk)
    begin
        if rst = '0' then
            enable_memory_stage(2 downto 1) <=  "00";
        else
            enable_memory_stage(1)  <=  enable_memory_stage(0);
            enable_memory_stage(2)  <=  enable_memory_stage(1);
        end if;
    end process DELAY_MEM_EN;
    Memory_enable       <=  enable_memory_stage(2);
    enable_DRAM_wr(0)   <=  cw(cw'high - 15);
    DELAY_DRAM_WR: process(rst, clk)
    begin
        if rst = '0' then
            enable_DRAM_wr(2 downto 1)  <= "00";
        else
            enable_DRAM_wr(1)   <=  enable_DRAM_wr(0);
            enable_DRAM_wr(2)   <=  enable_DRAM_wr(1);
        end if;
    end process DELAY_DRAM_WR;
    DRAM_write  <=  enable_DRAM_wr(2);
    select_MEM_out(0)   <=  cw(cw'high - 16);
    DELAY_MO_SEL: process(rst, clk)
    begin
        if rst = '0' then
            select_MEM_out(2 downto 1)  <= "00";
        else
            select_MEM_out(1)   <=  select_MEM_out(0);
            select_MEM_out(2)   <=  select_MEM_out(1);
        end if;
    end process DELAY_MO_SEL;
    MEM_out_select  <=  select_MEM_out(2);
    
    opcode  <= instruction(instruction'high downto instruction_size-operation_bits);
    OpCode_Reloc <= reloc_mem(to_integer(unsigned(OpCode)));
    func <= unsigned(instruction(FUNC_SIZE - 1 downto 0));  

    -- purpose: Update the uPC value depending on the instruction Op Code
    -- type   : sequential
    -- inputs : Clk, Rst, IR_IN
    -- outputs: CW Control Signals
    uPC_Proc: process (Clk, Rst)
    begin  -- process uPC_Proc
        if Rst = '0' then                   -- asynchronous reset (active low)
        uPC <= 0;
        is_float <= '0';
        elsif (OpCode = R_OPCODE) then
            uPC         <=  to_integer("00" & func);
            is_float    <=  '0';
        elsif (OpCode = F_OPCODE) then
            uPC         <=  to_integer("01" & func);
            is_float    <=  '1';
        else
            uPC <= to_integer(unsigned(OpCode_Reloc));
            is_float    <=  '0';
        end if;
    end process uPC_Proc;
    

  

end dlx_cu_pu;
