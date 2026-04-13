library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library module_lib;
use module_lib.module_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_i2c;
use bitvis_vip_i2c.i2c_bfm_pkg.all;

package sim_pkg is
    constant c_seed1    : integer := 1246;
    constant c_seed2    : integer := 0975;    

    type t_page_array is array(0 to 255) of t_byte_array(0 to 127);
    type t_upper_mem_array is array(0 to c_number_of_bank-1) of t_page_array;
    
    function f_page_to_byte_array(mem : t_page) return t_byte_array;
    function f_mem_to_byte_array(mem : t_mem) return t_upper_mem_array; 
    
    function f_reverse_page_memory(
        page_mamory     : t_byte_array(0 to 127);
        is_lower_mem    : boolean
    ) return t_byte_array;

end package sim_pkg;

package body sim_pkg is

    function f_page_to_byte_array(mem : t_page) return t_byte_array is
        variable byte_array : t_byte_array(0 to 127);
    begin
        for i in 0 to 127 loop
            byte_array(i) := mem(i);
        end loop;
        return byte_array;
    end function;

    function f_mem_to_byte_array(mem : t_mem) return t_upper_mem_array is
        variable upper_mem_array : t_upper_mem_array;
    begin
        for bank in 0 to c_number_of_bank-1 loop
            for page in 0 to 255 loop
                upper_mem_array(bank)(page) := f_page_to_byte_array(mem(bank)(page));
            end loop;
        end loop;
        return upper_mem_array;
    end function;

    function f_reverse_page_memory(
        page_mamory     : t_byte_array(0 to 127);
        is_lower_mem    : boolean
    ) return t_byte_array is
        variable reversed_page : t_byte_array(0 to 127);
    begin
        for i in 0 to 127 loop
            if is_lower_mem and i = 126 then
                reversed_page(i) := page_mamory(i);
            else
                reversed_page(i) := page_mamory(127 - i);
            end if;
        end loop;
        return reversed_page;
    end function;

end package body sim_pkg;
