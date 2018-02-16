library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

package microcode_memory is
    type mem_array is array (integer range 0 to microcode_mem_size - 1) of std_logic_vector(16 downto 0);
    type reloc_mem_array is array (0 to reloc_mem_size - 1) of std_logic_vector(7 downto 0);
    
    constant    reloc_mem_content:  reloc_mem_array:=  (X"00",  -- All R-type instructions are not relocated
                                                        X"00",  -- All F-type instructions are not relocated (additional external bit to select FP part of memory)
                                                        X"02",  -- J(0x02)     -> 0x02
                                                        X"03",  -- JAL(0X03)   -> 0x03
                                                        X"05",  -- BEQZ(0x04)  -> 0x05
                                                        X"08",  -- BNEZ(0x05)  -> 0X08
                                                        X"09",  -- BFPT(0x06)  -> 0x09
                                                        X"0a",  -- BFPF(0x07)  -> 0x0a
                                                        X"0b",  -- ADDI(0x08)  -> 0x0b
                                                        X"0c",  -- ADDUI(0x09) -> 0x0c
                                                        X"0d",  -- SUBI(0x0a)  -> 0x0d
                                                        X"0e",  -- SUBUI(0x0b) -> 0x0e
                                                        X"0f",  -- ANDI(0x0c)  -> 0x0f
                                                        X"10",  -- ORI(0x0d)   -> 0x10
                                                        X"11",  -- XORI(0x0e)  -> 0x11
                                                        X"12",  -- LHI(0x0f)   -> 0x12
                                                        X"13",  -- RFE(0x10)   -> 0x13
                                                        X"14",  -- TRAP(0x11)  -> 0x14
                                                        X"15",  -- JR(0x12)    -> 0x15
                                                        X"16",  -- JALR(0x13)  -> 0x16
                                                        X"17",  -- SLLI(0x14)  -> 0x17
                                                        X"18",  -- NOP(0x15)   -> 0x18
                                                        X"19",  -- SRLI(0x16)  -> 0x19
                                                        X"1a",  -- SRAI(0x17)  -> 0x1a
                                                        X"1b",  -- SEQI(0x18)  -> 0x1b
                                                        X"1c",  -- SNEI(0x19)  -> 0x1c
                                                        X"1d",  -- SLTI(0x1a)  -> 0x1d
                                                        X"1e",  -- SGTI(0x1b)  -> 0x1e
                                                        X"1f",  -- SLEI(0x1c)  -> 0x1f
                                                        X"27",  -- SGEI(0x1d)  -> 0x27
                                                        X"00",
                                                        X"00",
                                                        X"2e",  -- LB(0x20)    -> 0x2e
                                                        X"2f",  -- LH(0x21)    -> 0x2f
                                                        X"00",
                                                        X"68",  -- LW(0x23)    -> 0x68
                                                        X"38",  -- LBU(0x24)   -> 0x38
                                                        X"39",  -- LHU(0x25)   -> 0x39
                                                        X"3e",  -- LF(0x26)    -> 0x3e
                                                        X"3f",  -- LD(0x27)    -> 0x3f
                                                        X"5e",  -- SB(0x28)    -> 0x5e
                                                        X"5f",  -- SH(0x29)    -> 0x5f
                                                        X"00",
                                                        X"60",  -- SW(0x2b)    -> 0x60
                                                        X"00",
                                                        X"00",
                                                        X"61",  -- SF(0x2e)    -> 0x120
                                                        X"62",  -- SD(0x2f)    -> 0x121
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"00",
                                                        X"63",  -- ITLB(0x38)  -> 0x122
                                                        X"00",
                                                        X"64",  -- SLTUI(0x3a) -> 0x123
                                                        X"65",  -- SGTUI(0x3b) -> 0x124
                                                        X"66",  -- SLEUI(0x3c) -> 0x125
                                                        X"67",  -- SGEUI(0x3d) -> 0x126
                                                        X"00",
                                                        X"00");

-- Just a counter of memory position to test for the time being.
-- Template:
-- is_jump & is_immediate & writes_to_RF & enable_execute_stage (always 1? Let's not take it out) &
-- ALU_OP(9 downto 0) & enable_memory_stage (always 1 again?) & writes_to_DRAM & output_select
--
--      is_jump set iff it's a jump or branch
--      is_immediate set for all I-type instructions (anything but jump, R-type and F-type)
--      writes_to_RF set if result goes back to Register File (boh, always but jumps?)
--      enable_execute_stage set if execute stage has to propagate result (d'uh, always true for our simple architecture)
--      ALU_OP: sub & is_signed & use_pc & comp_0 & logic_op(2 downto 0) & output_sel(2 downto 0)
--          sub set if it is a subtraction (either integer or FP)
--          is_signed set if op is not unsigned
--          use_pc set if a new pc has to be calculated from current one (all jumps and branches)
--          comp_0 set if it is a branch (PC gets summed to B which is immediate, A gets compared to 0 for condition evaluation)
--          logic_op: see a.c.a-ALU.vhd for descritpion in port
--          output_sel: "000" for AddSub, "001" for FP_AS, "010" for Mul, "011" for FP_Mul, "100" for LogicUnit, "101" for comparator, "110" for shifter, "111" for B input
--              B input needs to be selected in stores from RF to DRAM
--      enable_memory_stage set if memory stage has to update output (always true? Maybe not for jumps since result gets rerouted to IF directly)
--      writes_to_DRAM if result goes into DRAM (stores only?)
--      output_select unset if result comes from ALU (operations etc.), set if result comes from DRAM (loads)
--
--  EXAMPLE
--  NOP
--      is_jump: no, it is not
--      is_immediate: no
--      writes_to_RF: no
--      enable_execute_stage: yeah, why not?
--      ALU_OP: "0100000000" (A+B signed, supposedly R0 = R0+R0 doing nothing)
--      enable_memory_stage: let's go with yes
--      writes_to_DRAM: no
--      output_sel: from ALU
--  NOP: "00010100000000100"
    constant    microcode_mem_content:  mem_array:=    (
        "00000000000000000",  -- RESET        0x00
        "00000000000000000",  --              0x01
        "10010010000000000",  -- "J"          0x02
        "10010010000000000",  -- "JAL"        0x03
        "00110000111110100",  -- "SLL"        0x04
        "10010011001000000",  -- "BEQZ"       0x05
        "00110000110110100",  -- "SRL"        0x06
        "00110000100110100",  -- "SRA"        0x07
        "10010011101000000",  -- "BNEZ"       0x08
        "00000000000000000",  -- "BFPT"       0x09 --
        "00000000000000000",  -- "BFPF"       0x0a --
        "01110100000000100",  -- "ADDI"       0x0b
        "01110000000000100",  -- "ADDUI"      0x0c
        "01111100000000100",  -- "SUBI"       0x0d
        "01111000000000100",  -- "SUBUI"      0x0e
        "01110000000100100",  -- "ANDI"       0x0f
        "01110000001100100",  -- "ORI"        0x10
        "01110000010100100",  -- "XORI"       0x11
        "01110000000111100",  -- "LHI"        0x12
        "00000000000000000",  -- "RFE"        0x13--
        "00000000000000000",  -- "TRAP"       0x14--
        "10010000000000000",  -- "JR"         0x15
        "10010000000000000",  -- "JALR"       0x16
        "01110000111100100",  -- "SLLI"       0x17
        "00110000000000100",  -- "NOP"        0x18
        "01110000110100100",  -- "SRLI"       0x19
        "01110000100100100",  -- "SRAI"       0x1a
        "01110000001101100",  -- "SEQI"       0x1b
        "01110000101101100",  -- "SNEI"       0x1c
        "01110000010101100",  -- "SLTI"       0x1d
        "01110000000101100",  -- "SGTI"       0x1e
        "01110000100101100",  -- "SLEI"       0x1f
        "00110100000000100",  -- "ADD"        0x20
        "00110000000000100",  -- "ADDU"       0x21
        "00111100000000100",  -- "SUB"        0x22
        "00111000000000100",  -- "SUBU"       0x23
        "00110000000100100",  -- "AND"        0x24
        "00110000001100100",  -- "OR"         0x25
        "00110000010100100",  -- "XOR"        0x26
        "01110000110101100",  -- "SGEI"       0x27
        "00110000001101100",  -- "SEQ"        0x28
        "00110000101101100",  -- "SNE"        0x29
        "00110000010101100",  -- "SLT"        0x2a
        "00110000000101100",  -- "SGT"        0x2b
        "00110000100101100",  -- "SLE"        0x2c
        "00110000110101100",  -- "SGE"        0x2d
        "00000000000000000",  -- "LB"         0x2e----load byte
        "00000000000000000",  -- "LH"         0x2f----load halfword
        "00000000000000000",  -- "MOVI2S"     0x30-- --
        "00000000000000000",  -- "MOVS2I"     0x31--
        "00000000000000000",  -- "MOVF"       0x32--
        "00000000000000000",  -- "MOVD"       0x33--
        "00000000000000000",  -- "MOVFP2I"    0x34--
        "00000000000000000",  -- "MOVI2FP     0x35--
        "00000000000000000",  -- "MOVI2T"     0x36--
        "00000000000000000",  -- "MOVT2I"     0x37--
        "00000000000000000",  -- "LBU"        0x38--
        "00000000000000000",  -- "LHU"        0x39--
        "00000000000000000",  -- "SLTU"       0x3a--
        "00000000000000000",  -- "SGTU"       0x3b--
        "00000000000000000",  -- "SLEU"       0x3c--
        "00000000000000000",  -- "SGEU"       0x3d--
        "00000000000000000",  -- "LF"         0x3e-- -- load floating
        "00000000000000000",  -- "LD"         0x3f-- -- load double
--------FLOATNG PINTFRO HERE ON -------------------------------------------------------
        "00110100000001000",  -- "ADDF"       0x40
        "00111100000001000",  -- "SUBF"       0x41
        "00110100000011000",  -- "MULTF"      0x42
        "00000100000000000",  -- "DIVF"       0x43--
        "00000000000000000",  -- "ADDD"       0x44--
        "00000000000000000",  -- "SUBD"       0x45--
        "00000000000000000",  -- "MULTD"      0x46--
        "00000000000000000",  -- "DIVD"       0x47--
        "00000000000000000",  -- "CVTF2D"     0x48--
        "00000000000000000",  -- "CVTF2I"     0x49--
        "00000000000000000",  -- "CVTD2F"     0x4a--
        "00000000000000000",  -- "CVTD2I"     0x4b--
        "00000000000000000",  -- "CVTI2F"     0x4c--
        "00000000000000000",  -- "CVTI2D"     0x4d--
        "00110000000010000",  -- "MULT"       0x4e
        "00000000000000000",  -- "DIV"        0x4f--
        "00000000000000000",  -- "EQF"        0x50--
        "00000000000000000",  -- "NEF"        0x51--
        "00000000000000000",  -- "LTF"        0x52--
        "00000000000000000",  -- "GTF"        0x53--
        "00000000000000000",  -- "LEF"        0x54--
        "00000000000000000",  -- "GEF"        0x55--
        "00000000000000000",  -- "MULTU"      0x56--
        "00000000000000000",  -- "DIVU"       0x57--
        "00000000000000000",  -- "EQD"        0x58--
        "00000000000000000",  -- "NED"        0x59--
        "00000000000000000",  -- "LTD"        0x5a--
        "00000000000000000",  -- "GTD"        0x5b--
        "00000000000000000",  -- "LED"        0x5c--
        "00000000000000000",  -- "GED"        0x5d--
        "00000000000000000",  -- "SB"         0x5e-- -- store byte
        "00000000000000000",  -- "SH"         0x5f-- -- store half word
        "00110000000000110",  -- "SW"         0x60   -- store word
        "00000000000000000",  -- "SF"         0x61-- -- store floating
        "00000000000000000",  -- "SD"         0x62-- -- store double
        "00000000000000000",  -- "ITLB"       0x63--
        "00000000000000000",  -- "SLTUI"      0x64--
        "00000000000000000",  -- "SGTUI"      0x65--
        "00000000000000000",  -- "SLEUI"      0x66--
        "00000000000000000",  -- "SGEUI"      0x67--
        "00110000000000101",  -- "LW"         0x68   --load word
        "00000000000000000",  --              0x69
        "00000000000000000",  --              0x6a
        "00000000000000000",  --              0x6b
        "00000000000000000",  --              0x6c
        "00000000000000000",  --              0x6d
        "00000000000000000",  --              0x6e
        "00000000000000000",  --              0x6f
        "00000000000000000",  --              0x70
        "00000000000000000",  --              0x71
        "00000000000000000",  --              0x72
        "00000000000000000",  --              0x73
        "00000000000000000",  --              0x74
        "00000000000000000",  --              0x75
        "00000000000000000",  --              0x76
        "00000000000000000",  --              0x77
        "00000000000000000",  --              0x78
        "00000000000000000",  --              0x79
        "00000000000000000",  --              0x7a
        "00000000000000000",  --              0x7b
        "00000000000000000",  --              0x7c
        "00000000000000000",  --              0x7d
        "00000000000000000",  --              0x7e
        "00000000000000000"   --              0x7f
        );
end package microcode_memory;
