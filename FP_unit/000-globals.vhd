library ieee;
use ieee.std_logic_1164.all;

package dlx_config is
    -- CONFIG
    -- a:       Common
    -- a.a:     Clock
    constant    clk_period:         time:=  100 ns;     -- Processor clock period
    
    -- a.b:     Sizes
    constant    architecture_bits:  natural:=   32;     -- Number of bits used in all computations and as default data transfer
    constant    instruction_size:   natural:=   32;     -- Number of bits in instruction
    constant    PC_size:            natural:=   32;     -- Number of bits to address instruction memory

    
    -- b:       Decode stage
    -- b.a:     Instruction format
    -- b.a.a:   Common
    constant    operation_bits:     natural:=   6;      -- Number of bits expressing operation type
    constant    RF_address_bits:    natural:=   5;      -- Number of bits to address register file
    -- b.a.b:   R-type and F-type: operation & src1 & src2 & dest & shift & function
    constant    shift_amt_bits:     natural:=   5;      -- Number of bits expressing shift for shift/rotate operations
    constant    function_bits:      natural:=   6;      -- Additional function specifier for ALU operations.
    -- b.a.c:   I-type: operation & src1 & dest & immediate
    constant    immediate_bits:     natural:=   16;     -- Number of bits expressing immediate in I-type operations
    -- b.a.d:   J-type: operation & offset
    constant    offset_bits:        natural:=   26;     -- Number of bits expressing offset in relative jumps
    
    -- b.b:     Microcode memory
    constant    microcode_mem_size: natural:=   512;    -- Size of microcode memory of control unit
    constant    reloc_mem_size:     natural:=   64;     -- Size of relocation memory that maps opcodes to location in memory
    

    type aluOp is (
        NOP, ADDS, LLS, LRS --- to be completed
    );
    
    -- Standard sizes, useful for data management
    subtype byte is std_logic_vector(7 downto 0);
    subtype half_word is std_logic_vector(15 downto 0);
    subtype word is std_logic_vector(31 downto 0);
    
    -- Custom types, here in case the inspiration to mess around with instruction size and so on generates monsters
    subtype instruction_type is std_logic_vector(instruction_size-1 downto 0);
    subtype PC_type is std_logic_vector(PC_size-1 downto 0);
    type    RF_addr_type is record
        is_float:   std_logic;  -- '1' for floating point operations else '0'
        addr:       std_logic_vector(RF_address_bits-1 downto 0);
    end record RF_addr_type;

end dlx_config;

