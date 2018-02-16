library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

entity TB_RegisterFile is
end entity TB_RegisterFile;

architecture test of TB_RegisterFile is

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
            write_address:  in  RF_addr_type;  -- address in which memory output or ALU result will be written
            read1_address:  in  RF_addr_type;  -- address in which data to be output on port read1_data resides
            read2_address:  in  RF_addr_type;  -- address in which data to be output on port read2_data resides
            write_data:     in  word;   -- data from memory or ALU here
            read1_data:     out word;   -- data to register_A here
            read2_data:     out word    -- data to register_B here
        );
    end component RegisterFile;
    
    signal  clk:            std_logic:= '0';
    signal  rst:            std_logic;
    signal  enable:         std_logic;
    signal  write_ctrl:     std_logic;
    signal  read1_ctrl:     std_logic;
    signal  read2_ctrl:     std_logic;
    signal  write_address:  RF_addr_type;
    signal  read1_address:  RF_addr_type;
    signal  read2_address:  RF_addr_type;
    signal  write_data:     word;
    signal  read1_data:     word;
    signal  read2_data:     word;

begin

    UUT:    RegisterFile
        port map(
            clk             =>  clk,
            rst             =>  rst,
            enable          =>  enable,
            write_ctrl      =>  write_ctrl,
            read1_ctrl      =>  read1_ctrl,
            read2_ctrl      =>  read2_ctrl,
            write_address   =>  write_address,
            read1_address   =>  read1_address,
            read2_address   =>  read2_address,
            write_data      =>  write_data,
            read1_data      =>  read1_data,
            read2_data      =>  read2_data
        );

    clock_P: process
    begin
        wait for 5 ns;
        clk   <=  not clk;
    end process clock_P;

    stim: process
    begin
        -- initialize
        rst             <=  '0';
        enable          <=  '1';
        write_ctrl      <=  '0';
        read1_ctrl      <=  '0';
        read2_ctrl      <=  '0';
        write_address   <=  (is_float => '0', addr => (others => '0'));
        read1_address   <=  (is_float => '0', addr => (others => '0'));
        read2_address   <=  (is_float => '0', addr => (others => '0'));
        write_data      <=  (others => '0');
        wait for 20 ns;
        -- write 0x00000001 in R1 and read it
        rst             <=  '1';
        write_ctrl      <=  '1';
        write_address   <=  (is_float => '0', addr => "00001");
        write_data      <=  (0 => '1', others => '0');
        read1_ctrl      <=  '1';
        read1_address   <=  (is_float => '0', addr => "00001");
        wait for 10 ns;
        -- keep reading, it should appear now
        write_ctrl      <=  '0';
        wait for 10 ns;
        -- write 0x00000001 in F0 and read it
        write_ctrl      <=  '1';
        write_address   <=  (is_float => '1', addr => "00000");
        write_data      <=  (0 => '1', others => '0');
        read1_ctrl      <=  '1';
        read1_address   <=  (is_float => '1', addr => "00000");
        wait for 10 ns;
        -- keep reading, it should appear now
        write_ctrl      <=  '0';
        wait for 10 ns;
        -- read on port 2 for 3 clock cycles
        read1_ctrl      <=  '0';
        read2_ctrl      <=  '1';
        read2_address   <=  (is_float => '1', addr => "00000");
        wait for 30 ns;
        -- don't read for 3 clock cycles and change location
        read1_ctrl      <=  '0';
        read2_ctrl      <=  '0';
        read1_address   <=  (is_float => '0', addr => (others => '0'));
        read2_address   <=  (is_float => '0', addr => (others => '0'));
        wait for 30 ns;
        -- write 0xffffffff in R0 and it should not appear
        write_ctrl      <=  '1';
        write_address   <=  (is_float => '0', addr => (others => '0'));
        write_data      <=  (others => '1');
        read1_ctrl      <=  '1';
        read1_address   <=  (is_float => '0', addr => (others => '0'));
        wait;
    end process stim;

end architecture test;
