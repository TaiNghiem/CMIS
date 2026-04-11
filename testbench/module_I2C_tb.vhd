library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.all;

library module_lib;
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
            g_module_freq_hz        : real := c_module_freq_hz
        );
        port(
            clk         : in    std_logic;
            rst         : in    std_logic;
            SCL         : inout std_logic;
            SDA         : inout std_logic
        );
    end component module_top;
    
    constant c_clk_period               : time := 10 ns;
    constant c_target_control_code      : std_logic_vector(6 downto 0) := b"1010_000";
    constant c_SCL_period               : time := 1_000 ns;

    signal clk                          : std_logic := '0';
    signal rst                          : std_logic := '1';
    signal i2c_if                       : t_i2c_if := init_i2c_if_signals(void);

    signal received_data_reg            : t_byte_array(0 to 3);


    constant c_I2C_bfm_config           : t_i2c_bfm_config := (
        enable_10_bits_addressing       => false,
        master_sda_to_scl               => 300 ns,
        master_scl_to_sda               => 355 ns,
        master_stop_condition_hold_time => 355 ns,
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

    constant c_bank_addr                : std_logic_vector(7 downto 0) := x"7E";
    constant c_illegal_bank_value       : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(c_number_of_bank, 8));

    procedure i2c_master_quick_command(
        constant addr_value : in unsigned;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant exp_ack    : in boolean) is
    begin
        i2c_master_quick_command(addr_value,
                                msg,
                                i2c_if,
                                '0',
                                exp_ack,
                                RELEASE_LINE_AFTER_TRANSFER,
                                failure,
                                C_SCOPE,
                                shared_msg_id_panel,
                                c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_transmit(
        constant data       : in std_logic_vector(7 downto 0);
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if) is
    begin
        i2c_master_transmit(unsigned(c_target_control_code),
                            data,
                            msg,
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER,
                            C_SCOPE,
                            shared_msg_id_panel,
                            c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_transmit(
        constant data       : in t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if) is
    begin
        i2c_master_transmit(unsigned(c_target_control_code),
                            data,
                            msg,
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER,
                            C_SCOPE,
                            shared_msg_id_panel,
                            c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_check(
        constant data_exp   : in std_logic_vector(7 downto 0);
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if) is
    begin
        i2c_master_check(unsigned(c_target_control_code),
                        data_exp,
                        msg,
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER,
                        ERROR,
                        C_SCOPE,
                        shared_msg_id_panel,
                        c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_receive(
        variable data       : out t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if) is
    begin
        i2c_master_receive(unsigned(c_target_control_code),
                           data,
                           msg,
                           i2c_if,
                           RELEASE_LINE_AFTER_TRANSFER,
                           C_SCOPE,
                           shared_msg_id_panel,
                           c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_check(
        constant data_exp   : in t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if) is
    begin
        i2c_master_check(unsigned(c_target_control_code),
                        data_exp,
                        msg,
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER,
                        ERROR,
                        C_SCOPE,
                        shared_msg_id_panel,
                        c_I2C_bfm_config);
    end procedure;

    function mem_to_byte_array(mem : t_page) return t_byte_array is
        variable byte_array : t_byte_array(0 to 127);
    begin
        for i in 0 to 127 loop
            byte_array(i) := mem(i);
        end loop;
        return byte_array;
    end function;

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
        variable received_data  : t_byte_array(0 to 127);
    begin
        -- report "Time: " & time'image(now) & " - Starting I2C master quick command test";
        wait until rst = '0';
        wait for 100 ns;
        i2c_master_quick_command(unsigned'(b"111_0001"),
                                "Sending wrong address, expecting NACK",
                                i2c_if, false);
        wait for 100 ns;
        i2c_master_quick_command(unsigned(c_target_control_code),
                                "Pinging I2C target, expecting ACK",
                                i2c_if, true);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: changing I2C target address to 0x7E";
        i2c_master_transmit(c_bank_addr,
                            "Changing address to 0x7E",
                            i2c_if);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: checking bank addr 0x7E";
        i2c_master_check(b"0000_0000",
                        "Checking bank addr 0x7E, expecting 0x00",
                        i2c_if);
        -- wait for 100 ns;
        -- report "**  Time: " & time'image(now) & ". Start: changing bank addr value to illegal value";
        -- i2c_master_transmit(t_byte_array'(c_bank_addr, c_illegal_bank_value),
        --                     "Changing bank addr value to illegal value, expected NACK",
        --                     i2c_if);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: changing bank addr value to 0x01";
        i2c_master_transmit(t_byte_array'(c_bank_addr, x"02"),
                            "Changing bank addr value to 0x01, expected ACK",
                            i2c_if);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: Changing addr to 0x00";
        i2c_master_transmit(x"00",
                            "Changing addr to 0x00, expected ACK",
                            i2c_if);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: Checking all lower page";
        i2c_master_check(mem_to_byte_array(f_init_lower_mem_test(x"02")),
                        "Reading lower mem, expected to match initial value",
                        i2c_if);
        -- i2c_master_check(t_byte_array'(x"00", x"01"),
        --                 "Reading lower mem, expected to match initial value",
        --                 i2c_if);
        -- i2c_master_receive(received_data(0 to 3),
        --                    "Reading lower mem, expected to match initial value",
        --                    i2c_if);
        wait for 100 ns;
        report "**  Time: " & time'image(now) & ". Start: Checking upper page memory";
        i2c_master_check(t_byte_array'(x"7F",mem_to_byte_array(f_init_upper_page_test)),
                        "Reading upper page, expected to match initial value",
                        i2c_if);
        wait for 1 us;
        std.env.stop;
    end process;

end architecture tb;
