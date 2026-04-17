library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library module_lib;
use module_lib.data_type.all;
use module_lib.module_config.all;

package i2cmci_config is
    constant c_i2cmci_timming_set   : t_i2cmci_timming_set;
    constant c_i2cmci_cycle_set     : t_i2cmci_cycle_set;
    constant c_t_rd_max             : time := 500_000 ns;
    constant c_t_nack_max           : time := 10_000_000 ms;
    constant c_t_wr_max             : time := 80_000_000 ms;
    constant c_t_buf                : time := 20_000 ms;
end package;

package body i2cmci_config is
    function time_to_cycle(
        t           : time
    ) return integer is
        variable cc : integer;
    begin
        cc  := integer(real(t / 1 ns) * c_module_freq_hz
                            / real(1_000_000_000));
        return cc;
    end function;

    function time_to_cycle_set(
        t           : t_i2cmci_timming_set
    ) return t_i2cmci_cycle_set is
        variable cc : t_i2cmci_cycle_set;
    begin
        for i in t_i2cmci_mode loop
            cc(i) := (
                t(i).bitrate,
                time_to_cycle(t(i).min_t_low),
                time_to_cycle(t(i).min_t_high),
                time_to_cycle(t(i).min_t_hd_sta),
                time_to_cycle(t(i).min_t_su_sta),
                time_to_cycle(t(i).min_t_hd_sto),
                time_to_cycle(t(i).min_t_hd_sto),
                time_to_cycle(t(i).min_t_su_dat)
            );
        end loop;
        return cc;
    end function;

    constant c_i2cmci_timming_set   : t_i2cmci_timming_set := (
        mode_400kHz =>  (
            bitrate         => 400_000,
            min_t_low       => 1300 ns,
            min_t_high      => 600 ns,
            min_t_su_sta    => 600 ns,
            min_t_hd_sta    => 600 ns,
            min_t_su_sto    => 600 ns,
            min_t_hd_sto    => 600 ns,
            min_t_su_dat    => 100 ns),
        mode_1000kHz => (
            bitrate         => 1_000_000,
            min_t_low       => 500 ns,
            min_t_high      => 260 ns,
            min_t_hd_sta    => 260 ns,
            min_t_su_sta    => 260 ns,
            min_t_su_sto    => 260 ns,
            min_t_hd_sto    => 260 ns,
            min_t_su_dat    => 100 ns)
    );

    constant c_i2cmci_cycle_set     : t_i2cmci_cycle_set := time_to_cycle_set(c_i2cmci_timming_set);
end package body;
