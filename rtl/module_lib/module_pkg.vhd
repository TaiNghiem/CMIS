library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

package module_pkg is
    constant c_number_of_bank       : integer := 4;
    
    type t_page is array(0 to 127) of std_logic_vector(7 downto 0);
    type t_bank is array(0 to 255) of t_page;
    type t_mem is array(0 to c_number_of_bank-1) of t_bank;

    function f_init_mem_test return t_mem;

    constant c_init_mem             : t_mem;
    constant c_init_lower_mem       : t_page;
end package;

package body module_pkg is
    function f_init_mem_test return t_mem is
        variable v_mem : t_mem;
    begin
        for bank in 0 to c_number_of_bank-1 loop  -- Fixed: Loop to c_number_of_bank-1 (0 to 3)
            for page in 0 to 255 loop
                for addr in 0 to 127 loop
                    v_mem(bank)(page)(addr) := std_logic_vector(to_unsigned(addr, 8));
                end loop;
            end loop;
        end loop;
        return v_mem;
    end function;

    function f_init_lower_mem_test return t_page is
        variable v_lower_mem : t_page;
    begin
        for addr in 0 to 127 loop
            v_lower_mem(addr) := std_logic_vector(to_unsigned(addr, 8));
        end loop;
        return v_lower_mem;
    end function;

    constant c_init_mem             : t_mem := f_init_mem_test;
    constant c_init_lower_mem       : t_page := f_init_lower_mem_test;
end package body;