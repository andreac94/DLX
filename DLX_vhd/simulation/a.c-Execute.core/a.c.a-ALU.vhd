library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

------------------------------ INSTRUCTION-SPECIFIC DESCRIPTION ------------------------------
--  J       (jump):
--      A           <=  -
--      B           <=  offset
--      O           <=  PC+B
--      use_pc      <=  '1' (use PC as first operand of ADDSUB)
--      output_sel  <=  "000" (select adder)
--
--  JAL     (jump and link):
--      A           <=  -
--      B           <=  offset
--      O           <=  PC+B
--      use_pc      <=  '1' (use PC as first operand of ADDSUB)
--      output_sel  <=  "000" (select adder)
--      RRET        <=  PC+1 (DECODE STAGE TAKES CARE OF THIS, REGISTER NOT IN STANDARD RF TO AVOID CONFLICTS ON WRITING)
--
--  SLL     (shift left logical):
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A SLL B
--      logic_op    <=  "111"
--      output_sel  <=  "110" (select shifter)
--
--  BEQZ    (branch if equal to zero):
--      A           <=  from register file
--      B           <=  immediate (comparator needs a "compare to zero" control)
--      O           <=  PC+B (use PC as first operand of ADDSUB)
--      use_pc      <=  '1'
--      comp_0      <=  '1'
--      logic_op    <=  "001"
--      output_sel  <=  "000" (select adder)
--
--  SRL     (shift right logical):
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A SRL B
--      logic_op    <=  "110"
--      output_sel  <=  "110" (select shifter)
--
--  SRA     (shift right arithmetic):
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A SRA B
--      logic_op    <=  "100"
--      output_sel  <=  "110" (select shifter)
--
--  BNEZ    (branch if not equal to zero):
--      A           <=  from register file
--      B           <=  immediate (comparator needs a "compare to zero" control)
--      O           <=  PC+B (use PC as first operand of ADDSUB)
--      use_pc      <=  '1'
--      comp_0      <=  '1'
--      logic_op    <=  "101"
--      output_sel  <=  "000" (select adder)
--
--  BFPT    (branch if floating point status bit is set):
--      NOT IMPLEMENTED
--
--  BFPF    (branch if floating point status bit is not set):
--      NOT IMPLEMENTED
--
--  ADDI    (add immediate):
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A+B 
--      output_sel  <=  "000" (select adder)
--
--  ADDUI   (add unsigned immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A+B
--      is_signed   <=  '0'
--      output_sel  <=  "000" (select adder)
--
--  SUBI    (subtract immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A-B
--      sub         <=  '1'
--      output_sel  <=  "000" (select adder)
--
--  SUBUI   (subtract unsigned immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A-B
--      sub         <=  '1'
--      is_signed   <=  '0'
--      output_sel  <=  "000" (select adder)
--
--  ANDI    (and immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A and B
--      logic_op    <=  "000"
--      output_sel  <=  "100" (select logic unit)
--
--  ORI     (or immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A or B
--      logic_op    <=  "001"
--      output_sel  <=  "100" (select logic unit)
--
--  XORI    (or immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A xor B
--      logic_op    <=  "010"
--      output_sel  <=  "100" (select logic unit)
--
--  LHI     (load half word immediate)
--      A           <=  -
--      B           <=  immediate
--      O           <=  B
--      output_sel  <=  "111" (select B input)
--
--  RFE     (???)
--      NOT IMPLEMENTED
--
--  TRAP
--      NOT IMPLEMENTED
--
--  JR      (jump register)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A+B
--      output_sel  <=  "000" (select adder)
--
--  JALR    (jump and link register)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A+B
--      output_sel  <=  "000" (select adder)
--      RRET        <=  PC+1 (DECODE STAGE TAKES CARE OF THIS, REGISTER NOT IN STANDARD RF TO AVOID CONFLICTS ON WRITING)
--
--  SLLI    (shift left logical immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A SLL B
--      logic_op    <=  "111"
--      output_sel  <=  "100" (select logic unit)
--
--  NOP     (no operation)
--      A           <=  from register file (R0)
--      B           <=  from register file (R0)
--      O           <=  A SLL B (destination is R0)
--      logic_op    <=  "111"
--      output_sel  <=  "100" (select logic unit)
--
--  SRLI    (shift right logical immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A SRL B
--      logic_op    <=  "110"
--      output_sel  <=  "100" (select logic unit)
--
--  SRAI    (shift right arithmetic immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A SRL B
--      logic_op    <=  "100"
--      output_sel  <=  "100" (select logic unit)
--
--  SEQI    (set if equal to immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A == B
--      logic_op    <=  "001"
--      output_sel  <=  "101" (select comparator)
--
--  SNEI    (set if not equal to immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A != B
--      logic_op    <=  "101"
--      output_sel  <=  "101" (select comparator)
--
--  SLTI    (set if less than immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A < B
--      logic_op    <=  "010"
--      output_sel  <=  "101" (select comparator)
--
--  SGTI    (set if greater than immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A > B
--      logic_op    <=  "000"
--      output_sel  <=  "101" (select comparator)
--
--  SLEI    (set if less than or equal to immediate)
--      A           <=  from register file
--      B           <=  immediate
--      O           <=  A <= B
--      logic_op    <=  "100"
--      output_sel  <=  "101" (select comparator)
--
--  ADD     (add)
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A+B
--      output_sel  <=  "000" (select adder)
--
--  ADDU    (add unsigned)
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A+B
--      is_signed   <=  '0'
--      output_sel  <=  "000" (select adder)
--
--  SUB     (subtract)
--      A           <=  from register file
--      B           <=  from register file
--      O           <=  A-B
--      sub         <=  '1'
--      output_sel  <=  "000" (select adder)
--

entity ALU is
    port(
        PC:             in  word;   -- Program counter, used instead of A in case a branch occurs
        A:              in  word;   -- First operand
        B:              in  word;   -- Second operand
        sub:            in  std_logic;  -- '0' to add, '1' to subtract. Only applies to adder and FP adder
        is_signed:      in  std_logic;  -- '0' to treat operands as unsigned, '1' to treat as signed (only impacts on overflow)
        use_pc:         in  std_logic;  -- '0' to perform A+B, '1' to perform PC+B
        comp_0:         in  std_logic;  -- '0' to compare A to B, '1' to compare A to 0
        -- Recycled for LogicUnit, Comparator and Shifter
        logic_op:       in  std_logic_vector(2 downto 0);   -- AND<="000", NAND<="100", OR<="001", NOR<="101", XOR<="010", XNOR<="110"
                                                        -- A>B<="000", A>=B<="110", A==B<="001", A!=B<="101", A<B<="010", A<=B<="100"
                                                        -- SLL<="111", SRL<="110", SLA<="101", SRA<="100", ROL<="001, ROR<="000"
        output_sel:     in  std_logic_vector(2 downto 0);   -- ADD=>"000", FP_ADD=>"001", MULT=>"010", FP_MULT=>"011", LOGIC=>"100", COMP=>"101", SHIFTER=>"110", B=>"111"
        overflow:       out std_logic;  -- '1' if things have gone south, unused at the moment
        branch_taken:   out std_logic;  -- '1' if branch is taken, all branches require comp_0 to be set
        O:              out word;   -- Output
        new_PC:         out word    -- New Program Counter (corresponds to AS_output, but it gets rerouted directly to IF instead of going to MEM and WB)
    );
end entity ALU;

architecture structural of ALU is

    component AdderSubtractor is
        port(
            A:          in  word;
            B:          in  word;
            sub:        in  std_logic;
            is_signed:  in  std_logic;
            O:          out word;
            overflow:   out std_logic
        );
    end component AdderSubtractor;
    
    signal  AS_X:       word;
    signal  AS_output:  word;
    signal  AS_ovf:     std_logic;
    
    component FP_AdderSubtractor is
        generic(
            nbit:       natural:=   architecture_bits;
            exponent:   natural:=   8;
            mantissa:   natural:=   23
        );
        port(
            A:      in          std_logic_vector(nbit-1 downto 0);
            B:      in          std_logic_vector(nbit-1 downto 0);
            sub:    in          std_logic;
            S:      out         std_logic_vector(nbit-1 downto 0)
        );
    end component FP_AdderSubtractor;
    
    signal  FPAS_output:    word;
    
    component Multiplier is
        generic(
            NBIT:   integer:=   architecture_bits;
            WIDTH:  integer:=   4
        );
        port(
          Mul_A       : In  std_logic_vector(NBIT-1 downto 0);
          Mul_B       : In  std_logic_vector(NBIT-1 downto 0);
          mul_overflow: out STD_LOGIC;
          Product     : Out std_logic_vector(NBIT-1 downto 0)
        );
    end component Multiplier;
    
    signal  MUL_ovf:        std_logic;
    signal  MUL_output:     word;
    
    component FP_Multiplier is
        port(
            A:      in          std_logic_vector(architecture_bits-1 downto 0);
            B:      in          std_logic_vector(architecture_bits-1 downto 0);
            M:      out         std_logic_vector(architecture_bits-1 downto 0)
        );
    end component FP_Multiplier;
    
    signal  FPM_output:     word;
    
    component LogicUnit is
        port(
            A:      in  word;                           -- First operand
            B:      in  word;                           -- Second operand
            op:     in  std_logic_vector(2 downto 0);   -- AND<="000", NAND<="100", OR<="001", NOR<="101", XOR<="010", XNOR<="110"
            O:      out word                            -- Output
        );
    end component LogicUnit;
    
    signal  LU_output:      word;
    
    component Comparator is
        port(
            A:      in  word;       -- First operand
            B:      in  word;       -- Second operand
            comp_0: in  std_logic;  -- Use 0x00000000 instead of B
            -- coding of op lets us use fewer signals and less logic
            op:     in  std_logic_vector(2 downto 0);   -- A>B=>"000", A>=B=>"110", A==B=>"001", A!=B=>"101", A<B=>"010", A<=B=>"100"
            O:      out word
        );
    end component Comparator;
    
    signal  COM_output:     word;
    
    component Shifter is
        generic(
            N:  natural:=   architecture_bits
        );
        port(
            A: in std_logic_vector(N-1 downto 0);
            B: in std_logic_vector(4 downto 0);
            LOGIC_ARITH: in std_logic;  -- 1 = logic, 0 = arith
            LEFT_RIGHT: in std_logic;   -- 1 = left, 0 = right
            SHIFT_ROTATE: in std_logic; -- 1 = shift, 0 = rotate
            OUTPUT: out std_logic_vector(N-1 downto 0)
        );
    end component Shifter;
    
    signal SH_output:       word;

begin

    -- In case a branch occurs first operand of ADDSUB is PC
    AS_X    <=  A when use_pc='0' else
                PC;

    ADDSUB: AdderSubtractor
        port map(
            A           =>  AS_X,
            B           =>  B,
            sub         =>  sub,
            is_signed   =>  is_signed,
            O           =>  AS_output,
            overflow    =>  AS_ovf
        );
        
    FP_AS:  FP_AdderSubtractor
        port map(
            A           =>  A,
            B           =>  B,
            sub         =>  sub,
            S           =>  FPAS_output
        );
        
    MUL:    Multiplier
        port map(
            Mul_A        =>  A,
            Mul_B        =>  B,
            mul_overflow =>  MUL_ovf,
            Product      =>  MUL_output
        );
    
    FP_M:   FP_Multiplier
        port map(
            A           =>  A,
            B           =>  B,
            M           =>  FPM_output
        );
    
    LU: LogicUnit
        port map(
            A           =>  A,
            B           =>  B,
            op          =>  logic_op,
            O           =>  LU_output
        );
    
    COM: Comparator
        port map(
            A           =>  A,
            B           =>  B,
            comp_0      =>  comp_0,
            op          =>  logic_op,
            O           =>  COM_output
        );
    
    SH: Shifter
        port map(
            A           =>  A,
            B           =>  B(4 downto 0),
            LOGIC_ARITH =>  logic_op(1),
            LEFT_RIGHT  =>  logic_op(0),
            SHIFT_ROTATE=>  logic_op(2),
            OUTPUT      =>  SH_output
        );
    
    overflow        <=  AS_ovf  when output_sel="000" else   -- signal overflow only if the operation can produce it
                        MUL_ovf when output_sel="010" else   -- signal overflow only if the operation can produce it
                        '0';
    
    branch_taken    <=  comp_0 and COM_output(0);
    
    O               <=  AS_output when output_sel="000" else
                        FPAS_output when output_sel="001" else
                        MUL_output when output_sel="010" else
                        FPM_output when output_sel="011" else
                        LU_output when output_sel="100" else
                        COM_output when output_sel="101" else
                        SH_output;

    new_PC          <=  AS_output;
                    
end architecture structural;
