library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity ExecuteStage is
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
end entity ExecuteStage;


architecture structural of ExecuteStage is

    -- TODO
    component ALU is
        port(
            PC:         in  word;   -- Program counter, used instead of A in case a branch occurs
            A:          in  word;   -- First operand
            B:          in  word;   -- Second operand
            sub:        in  std_logic;  -- '0' to add, '1' to subtract. Only applies to adder and FP adder
            is_signed:  in  std_logic;  -- '0' to treat operands as unsigned, '1' to treat as signed (only impacts on overflow)
            use_pc:     in  std_logic;  -- '0' to perform A+B, '1' to perform PC+B
            comp_0:     in  std_logic;  -- '0' to compare A to B, '1' to compare A to 0
            -- Recycled for LogicUnit, Comparator and Shifter
            logic_op:   in  std_logic_vector(2 downto 0);   -- AND<="000", NAND<="100", OR<="001", NOR<="101", XOR<="010", XNOR<="110"
                                                            -- A>B<="000", A>=B<="110", A==B<="001", A!=B<="101", A<B<="010", A<=B<="100"
                                                            -- SLL<="111", SRL<="110", SLA<="101", SRA<="100", ROL<="001, ROR<="000"
            output_sel: in  std_logic_vector(2 downto 0);   -- ADD=>"000", FP_ADD=>"001", MULT=>"010", FP_MULT=>"011", LOGIC=>"100", COMP=>"101", SHIFTER=>"110", B=>"111"
            overflow:   out std_logic;  -- '1' if things have gone south
            O:          out word;   -- Output
            new_PC:     out word    -- New Program Counter (corresponds to O, but it gets rerouted directly to IF instead of going to MEM and WB
        );
    end component ALU;

    signal  op2:        word;
    signal  ALU_out:    word;
    signal  to_memory:  word;

begin

    op2 <=  off when use_offset='1' else
            imm when use_immediate='1' else
            B;
    
    branch_taken <= '1' when ALU_operation(6)='1' and ALU_out/=X"00000000" else   -- Whenever we are explicitly testing A to 0 we are evaluating
                    '0';                                                    -- a branch condition: if condition holds (O=0x00000001) branch is taken
    
    ALU0: ALU
        port map(
            PC          =>  PC,
            A           =>  A,
            B           =>  B,
            sub         =>  ALU_operation(9),
            is_signed   =>  ALU_operation(8),
            use_pc      =>  ALU_operation(7),
            comp_0      =>  ALU_operation(6),
            logic_op    =>  ALU_operation(5 downto 3),
            output_sel  =>  ALU_operation(2 downto 0),
            overflow    =>  open,                       -- open for the time being, this might return to CU or set some flag
            O           =>  ALU_out,
            new_PC      =>  new_PC
        );
    
    latch: process(clk)
    begin
        if rising_edge(clk) then
            if EX_latch_en='1' then
                EX_out              <=  ALU_out;
                to_memory           <=  B;  -- used for stores, RF writes on RF_out2, data gets latched two times before being sent to memory to synch with address
            end if;
        end if;
    end process latch;
    
end architecture structural;
