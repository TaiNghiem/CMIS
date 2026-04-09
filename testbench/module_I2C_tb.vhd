library IEEE;
library module_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.all;
use module_lib.module_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_i2c;
use bitvis_vip_i2c.i2c_bfm_pkg.all;

entity module_I2C_tb is
end entity module_I2C_tb;

architecture tb of module_I2C_tb is

    component module_top
        generic(
            g_SDA_hold_time         : time := c_SDA_hold_time;
            g_module_freq_hz        : integer := c_module_freq_hz
        );
        port(
            clk         : in    std_logic;
            rst         : in    std_logic;
            SCL         : inout std_logic;
            SDA         : inout std_logic
        );
    end component module_top;
    
    constant c_clk_period               : time := 10 ns;
    constant c_target_control_code      : std_logic_vector(6 downto 0) := "1010000";
    constant c_SCL_period               : time := 1_000 ns;

    signal clk                          : std_logic := '0';
    signal rst                          : std_logic := '1';
    signal SCL                          : std_logic := 'H';
    signal SDA                          : std_logic := 'H';

    signal SCL_reg                      : std_logic := 'Z';
    signal SDA_reg                      : std_logic := 'Z';


    constant c_I2C_bfm_config           : t_i2c_bfm_config := (
        enable_10_bits_addressing       => false,
        master_sda_to_scl               => 100 ns,
        master_scl_to_sda               => 155 ns,
        master_stop_condition_hold_time => 155 ns,
        max_wait_scl_change             => 10 ms,
        max_wait_scl_change_severity    => failure,
        max_wait_sda_change             => 10 ms,
        max_wait_sda_change_severity    => failure,
        i2c_bit_time                    => c_SCL_period,
        i2c_bit_time_severity           => failure,
        acknowledge_severity            => failure,
        slave_mode_address              => "000" & unsigned(c_target_control_code),
        slave_mode_address_severity     => failure,
        slave_rw_bit_severity           => failure,
        reserved_address_severity       => warning,
        match_strictness                => MATCH_STD,
        id_for_bfm                      => ID_BFM,
        id_for_bfm_wait                 => ID_BFM_WAIT,
        id_for_bfm_poll                 => ID_BFM_POLL
    );

    signal i2c_if                       : t_i2c_if := init_i2c_if_signals(void);

    procedure i2c_master_quick_command(
        constant addr_value : in unsigned;
        signal i2c_if       : inout t_i2c_if;
        constant msg        : in string;
        constant exp_ack    : in boolean) is
    begin
        i2c_master_quick_command(addr_value,
                                msg,
                                i2c_if,
                                '0',
                                exp_ack,
                                RELEASE_LINE_AFTER_TRANSFER,
                                failure,
                                C_SCOPE,                     -- Use the default
                                shared_msg_id_panel,         -- Use global, shared msg_id_panel
                                c_I2C_bfm_config);         -- Use locally defined configuration or C_I2C_CONFIG_DEFAULT
    end procedure;

begin

    DUT: module_top
        generic map (
            g_SDA_hold_time => c_SDA_hold_time,
            g_module_freq_hz => c_module_freq_hz
        )
        port map (
            clk => clk,
            rst => rst,
            SCL => i2c_if.SCL,
            SDA => i2c_if.SDA
        );

    i2c_if.SCL <= 'H';
    i2c_if.SDA <= 'H';

    p_clk : clock_generator(clk, c_clk_period);

    rst_pulse: process
    begin
        rst <= '1';
        wait for 100 ns;
        report "Time: " & time'image(now) & " - Releasing reset";
        rst <= '0';
        wait;
    end process;

    test: process
    begin
        -- report "Time: " & time'image(now) & " - Starting I2C master quick command test";
        wait until rst = '0';
        wait for 100 ns;
        i2c_master_quick_command(unsigned(c_target_control_code), i2c_if, "Pinging I2C slave, expecting ACK", true);
        wait for 10 us;
            
        std.env.stop;
    end process;

end architecture tb;
