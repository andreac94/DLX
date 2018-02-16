library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.dlx_config.all;

-- Type 'word' is defined in 000-globals.vhd, 32-bit standard word. Can be changed there if fit.
entity RegisterFile is
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
end entity RegisterFile;


architecture simple of RegisterFile is

    subtype reg_addr is natural range 0 to 2**address_bits-1; -- using natural type
    type reg_array is array(reg_addr) of word;
    
    signal GP_register_bank:    reg_array;
    signal FP_register_bank:    reg_array;

begin

    main: process(clk)
    begin
        if rst='0' then -- active low asynchronous reset
                reset_GP_registers: GP_register_bank    <=  (others => (others => '0'));
                reset_FP_registers: FP_register_bank    <=  (others => (others => '0'));
                read1_data  <=  (others => '0');
                read2_data  <=  (others => '0');
        elsif rising_edge(clk) then
            if enable='1' then  -- if register file is enabled
                if read1_ctrl='1' then
                    if read1_address.is_float = '0' then
                        read1_data  <=  GP_register_bank(to_integer(unsigned(read1_address.addr)));
                    else
                        read1_data  <=  FP_register_bank(to_integer(unsigned(read1_address.addr)));
                    end if;
                end if;
                if read2_ctrl='1' then
                    if read2_address.is_float = '0' then
                        read2_data  <=  GP_register_bank(to_integer(unsigned(read2_address.addr)));
                    else
                        read2_data  <=  FP_register_bank(to_integer(unsigned(read2_address.addr)));
                    end if;
                end if;
                if write_ctrl='1' and (to_integer(unsigned(write_address.addr)) /= 0 or write_address.is_float='1') then   -- ignore write attempts on R0
                    if write_address.is_float = '0' then
                        GP_register_bank(to_integer(unsigned(write_address.addr)))  <=  write_data;
                    else
                        FP_register_bank(to_integer(unsigned(write_address.addr)))  <=  write_data;
                    end if;
                end if;
            end if;
        end if;
    end process main;
    
    GP_register_bank(0)    <=  (others => '0');

end architecture simple;
