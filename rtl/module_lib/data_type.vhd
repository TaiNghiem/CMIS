library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library module_lib;
use module_lib.module_config.all;

package data_type is
    type t_i2cmci_mode is (mode_400kHz, mode_1000kHz);
    type t_page_map is array (natural range<>) of std_logic_vector;
    type t_page is array(0 to 127) of std_logic_vector(7 downto 0);
    type t_bank is array(0 to 255) of t_page;
    type t_mem is array(0 to c_number_of_bank-1) of t_bank;

    type t_i2cmci_timming is record
        bitrate         : integer;
        min_t_low       : time;
        min_t_high      : time;
        min_t_su_sta    : time;
        min_t_hd_sta    : time;
        min_t_su_sto    : time;
        min_t_hd_sto    : time;
        min_t_su_dat    : time;
    end record;

    type t_i2cmci_cycle is record
        bitrate         : integer;
        min_t_low       : integer;
        min_t_high      : integer;
        min_t_su_sta    : integer;
        min_t_hd_sta    : integer;
        min_t_su_sto    : integer;
        min_t_hd_sto    : integer;
        min_t_su_dat    : integer;
    end record;

    type t_i2cmci_timming_set is array(t_i2cmci_mode) of t_i2cmci_timming;
    type t_i2cmci_cycle_set is array(t_i2cmci_mode) of t_i2cmci_cycle;
end package;