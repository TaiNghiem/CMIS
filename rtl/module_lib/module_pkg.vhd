library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

package module_pkg is
    constant c_SDA_hold_time        : time := 100 ns;
    constant c_number_of_bank       : integer := 4;
    constant c_initial_bank_addr    : std_logic_vector(7 downto 0) := (others => '0');
    constant c_initial_page_addr    : std_logic_vector(7 downto 0) := (others => '0');
    constant c_module_freq_hz       : real := 100_000_000.0;

    type t_page is array(0 to 127) of std_logic_vector(7 downto 0);
    type t_bank is array(0 to 255) of t_page;
    type t_mem is array(0 to c_number_of_bank-1) of t_bank;

    function f_init_upper_page_test return t_page;
    function f_init_upper_mem_test return t_mem;
    function f_init_lower_mem_test(
        init_bank_addr : std_logic_vector(7 downto 0)
    ) return t_page;

    constant c_init_mem             : t_mem;
    constant c_init_lower_mem       : t_page;
end package;

package body module_pkg is

    function f_init_upper_page_test return t_page is
        variable v_upper_page : t_page;
    begin
        for addr in 0 to 127 loop
            v_upper_page(addr) := std_logic_vector(to_unsigned(addr, 8));
        end loop;
        return v_upper_page;
    end function;
        

    function f_init_upper_mem_test return t_mem is
        variable v_mem : t_mem;
    begin
        for bank in 0 to c_number_of_bank-1 loop 
            for page in 0 to 255 loop
                for addr in 0 to 127 loop
                    v_mem(bank)(page) := f_init_upper_page_test;
                end loop;
            end loop;
        end loop;
        return v_mem;
    end function;

    function f_init_lower_mem_test(
        init_bank_addr : std_logic_vector(7 downto 0)
    ) return t_page is
        variable v_lower_mem : t_page;
    begin
        for addr in 0 to 127 loop
            if addr = 126 then
                v_lower_mem(addr) := init_bank_addr;
            else
                v_lower_mem(addr) := std_logic_vector(to_unsigned(addr, 8));
            end if;
        end loop;
        return v_lower_mem;
    end function;

    constant c_init_mem             : t_mem := f_init_upper_mem_test;
    constant c_init_lower_mem       : t_page := f_init_lower_mem_test(c_initial_bank_addr); 
end package body;