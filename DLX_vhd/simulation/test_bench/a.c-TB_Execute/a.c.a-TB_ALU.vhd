library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.dlx_config.all;

entity TB_ALU is
end entity TB_ALU;

architecture test of TB_ALU is

    component ALU is
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
    end component ALU;

    signal  PC:             word;
    signal  A:              word;
    signal  B:              word;
    signal  sub:            std_logic;
    signal  is_signed:      std_logic;
    signal  use_pc:         std_logic;
    signal  comp_0:         std_logic;
    signal  logic_op:       std_logic_vector(2 downto 0);
    signal  output_sel:     std_logic_vector(2 downto 0);
    signal  overflow:       std_logic;
    signal  branch_taken:   std_logic;
    signal  O:              word;
    signal  new_PC:         word;
    
begin

    UUT:    ALU
        port map(
            PC              =>  PC,
            A               =>  A,
            B               =>  B,
            sub             =>  sub,
            is_signed       =>  is_signed,
            use_pc          =>  use_pc,
            comp_0          =>  comp_0,
            logic_op        =>  logic_op,
            output_sel      =>  output_sel,
            overflow        =>  overflow,
            branch_taken    =>  branch_taken,
            O               =>  O,
            new_PC          =>  new_PC
        );
    
    stim: process
    begin
        -- A + B
        PC          <=  X"00000100";
        A           <=  X"00000010";
        B           <=  X"00000001";
        sub         <=  '0';
        is_signed   <=  '1';
        use_pc      <=  '0';
        comp_0      <=  '0';
        logic_op    <=  "000";
        output_sel  <=  "000";
        wait for 10 ns;
        -- A - B
        sub         <=  '1';
        wait for 10 ns;
        -- A * B
        sub         <=  '0';
        output_sel  <=  "010";
        wait for 10 ns;
        -- A and B
        output_sel  <=  "100";
        wait for 10 ns;
        -- A > B
        output_sel  <=  "101";
        wait for 10 ns;
        -- A SLL B
        output_sel  <=  "110";
        wait for 10 ns;
        -- B
        output_sel  <=  "111";
        wait for 10 ns;
        -- BNEZ
        use_pc      <=  '1';
        comp_0      <=  '1';
        output_sel  <=  "000";
        wait;
    end process stim;

end architecture test;
