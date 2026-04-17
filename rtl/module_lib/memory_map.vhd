library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library module_lib;
use module_lib.module_config.all;
use module_lib.data_type.all;

package memory_map is
    constant c_supported_page_mask  : t_page_map(0 to 255)(0 to 255);
end package;

package body memory_map is
    constant c_1a1b_page_mask       : t_page_map(0 to 255)(26 to 27) := (
        others => (others => '0')
    );
    constant c_1c_page_mask         : t_page_map(0 to 255)(28 to 28) :=  (
        others => (others => '0')
    );
    constant c_b0ff_page_mask       : t_page_map(0 to 255)(176 to 255) := (
        others => (others => '0')
    );

    function gen_page_map return t_page_map is
        variable pm     : t_page_map := (others => (others => '0'));
    begin
        if c_lm02_mem_model(7) = '1' then
            pm(0)(0) := '1';
        else
            pm(0)(0 to 2)   := (others => '1');
            pm(0)(3 to 5)   := (c_03_user_nvram,
                                c_04_laser_cap,
                                c_05_cmis_ff);
            pm(0)(6 to 7)   := (others => c_0607_res_mod);
            pm(0)(8 to 12)  := (others => c_080b_cmis_lt);
            for i in 0 to (c_number_of_lane-1)/8 loop
                pm(i)(16 to 25) := ('1',
                                    '1',
                                    c_12_tunable,
                                    c_13_diag_ctrl,
                                    c_14_diag_res,
                                    c_15_timing,
                                    c_16_net_path,
                                    c_17_flags_masks,
                                    c_18_cfg_ext,
                                    c_19_stat_ext);
                pm(i)(29 to 31) := (c_1d_host_lane_sw,
                                    c_1e1f_custom,
                                    c_1e1f_custom);
            pm(i)(32 to 47) := (others => '1');
            end loop;
            pm(0 to 1)(159)     := c_9f_cdb_local;
            pm(0 to 1)(160 to 175)  := (others => c_a0af_cdb_ext);
        end if;
        return pm;
    end function;

    constant c_supported_page_mask  : t_page_map := gen_page_map when c_lm02_mem_model = '1';


end package body;