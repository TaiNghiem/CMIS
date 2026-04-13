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

library sim_lib;
use sim_lib.sim_pkg.all;

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

    constant c_bank_addr                : std_logic_vector(7 downto 0) := x"7E";
    constant c_page_addr                : std_logic_vector(7 downto 0) := x"7F";
    constant c_bank_addr_int            : integer := to_integer(unsigned(c_bank_addr));
    constant c_page_addr_int            : integer := to_integer(unsigned(c_page_addr));

    signal clk                          : std_logic := '0';
    signal rst                          : std_logic := '1';
    signal i2c_if                       : t_i2c_if := init_i2c_if_signals(void);

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

    procedure i2c_master_quick_command(
        constant addr_value : in unsigned;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant exp_ack    : in boolean;
        constant action     : in t_action_when_transfer_is_done
        ) is
    begin
        i2c_master_quick_command(addr_value,
                                msg,
                                i2c_if,
                                '0',
                                exp_ack,
                                action,
                                failure,
                                C_SCOPE,
                                shared_msg_id_panel,
                                c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_transmit(
        constant data       : in std_logic_vector(7 downto 0);
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant action     : in t_action_when_transfer_is_done
        ) is
    begin
        i2c_master_transmit(unsigned(c_target_control_code),
                            data,
                            msg,
                            i2c_if,
                            action,
                            C_SCOPE,
                            shared_msg_id_panel,
                            c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_transmit(
        constant data       : in t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant action     : in t_action_when_transfer_is_done
        ) is
        alias a_data        : t_byte_array(0 to data'length-1) is data;
    begin
        i2c_master_transmit(unsigned(c_target_control_code),
                            a_data,
                            msg,
                            i2c_if,
                            action,
                            C_SCOPE,
                            shared_msg_id_panel,
                            c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_check(
        constant data_exp   : in std_logic_vector(7 downto 0);
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant action     : in t_action_when_transfer_is_done
        ) is
    begin
        i2c_master_check(unsigned(c_target_control_code),
                        data_exp,
                        msg,
                        i2c_if,
                        action,
                        ERROR,
                        C_SCOPE,
                        shared_msg_id_panel,
                        c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_receive(
        variable data       : out t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant action     : in t_action_when_transfer_is_done
        ) is
        alias a_data        : t_byte_array(0 to data'length-1) is data;
    begin
        i2c_master_receive(unsigned(c_target_control_code),
                           a_data,
                           msg,
                           i2c_if,
                           action,
                           C_SCOPE,
                           shared_msg_id_panel,
                           c_I2C_bfm_config);
    end procedure;

    procedure i2c_master_check(
        constant data_exp   : in t_byte_array;
        constant msg        : in string;
        signal i2c_if       : inout t_i2c_if;
        constant action     : in t_action_when_transfer_is_done
        ) is
        alias a_data_exp    : t_byte_array(0 to data_exp'length-1) is data_exp;
    begin
        i2c_master_check(unsigned(c_target_control_code),
                        a_data_exp,
                        msg,
                        i2c_if,
                        action,
                        ERROR,
                        C_SCOPE,
                        shared_msg_id_panel,
                        c_I2C_bfm_config);
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
        variable test_rand              : t_rand;
        variable lower_mem_reg          : t_byte_array(0 to 127) := f_page_to_byte_array(c_init_lower_mem);
        variable upper_mem_reg          : t_upper_mem_array := f_mem_to_byte_array(c_init_mem);
        variable bank_value             : integer;
        variable page_value             : integer;
        variable rand_lower_int1        : integer;
        variable rand_lower_int2        : integer;
        variable rand_upper_int1        : integer;
        variable rand_upper_int2        : integer;
        variable rand_byte              : std_logic_vector(7 downto 0);
        variable received_data          : t_byte_array(0 to 127);
    begin
        wait until rst = '0';
        test_rand.set_rand_seeds(c_seed1, c_seed2);

        i2c_master_quick_command(unsigned'(b"111_0001"),
                                "Sending wrong address, expecting NACK",
                                i2c_if, false,
                                RELEASE_LINE_AFTER_TRANSFER);

        i2c_master_quick_command(unsigned(c_target_control_code),
                                "Pinging I2C target, expecting ACK",
                                i2c_if, true,
                                RELEASE_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: changing target address to 0x7E";
        i2c_master_transmit(c_bank_addr,
                            "Changing target address to 0x7E",
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: checking bank addr 0x7E";
        i2c_master_check(b"0000_0000",
                        "Reading bank addr 0x7E, expecting 0x00",
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER);

        -- wait for 100 ns;
        -- rand_byte := test_rand.rand(8, c_number_of_bank, 255);
        -- report "**  Time: " & time'image(now) & ". Start: changing bank addr value to illegal value " & integer'image(to_integer(unsigned(rand_byte)));
        -- i2c_master_transmit(t_byte_array'(c_bank_addr, rand_byte),
        --                     "Changing bank addr value to illegal value, expected NACK",
        --                     i2c_if,
        --                     RELEASE_LINE_AFTER_TRANSFER);

        bank_value := test_rand.rand(0, c_number_of_bank-1);
        lower_mem_reg(c_bank_addr_int) := std_logic_vector(to_unsigned(bank_value, 8));
        page_value := test_rand.rand(0, 255);
        lower_mem_reg(c_page_addr_int) := std_logic_vector(to_unsigned(page_value, 8));

        report "**  Time: " & time'image(now) & ". Start: changing bank addr value";
        i2c_master_transmit(t_byte_array'(c_bank_addr, lower_mem_reg(c_bank_addr_int to c_page_addr_int)),
                            "Writing random value to bank and page addr",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: Changing target addr to 0x00";
        i2c_master_transmit(x"00",
                            "Changing target addr to 0x00",
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: Checking all lower page";
        i2c_master_check(lower_mem_reg,
                        "Reading lower mem",
                        i2c_if,
                        HOLD_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: Checking upper page memory";
        i2c_master_check(t_byte_array'(lower_mem_reg(c_page_addr_int), upper_mem_reg(bank_value)(page_value)),
                        "Reading upper page",
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER);

        lower_mem_reg := f_reverse_page_memory(lower_mem_reg, true);
        page_value := to_integer(unsigned(lower_mem_reg(c_page_addr_int)));
        upper_mem_reg(bank_value)(page_value) := f_reverse_page_memory(upper_mem_reg(bank_value)(page_value), false);

        report "**  Time: " & time'image(now) & ". Start: writing all value to reverse order";
        i2c_master_transmit(t_byte_array'(x"00", lower_mem_reg, upper_mem_reg(bank_value)(page_value)),
                            "Writing all value to reverse",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);

        report "**  Time: " & time'image(now) & ". Start: Checking all mem";
        i2c_master_transmit(x"00",
                    "Changing target Offset to 0x00",
                    i2c_if,
                    HOLD_LINE_AFTER_TRANSFER);
        i2c_master_check(t_byte_array'(lower_mem_reg, upper_mem_reg(bank_value)(page_value)),
                        "Reading all mem",
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER);
        
        for i in 1 to 100 loop
            report "**  Time: " & time'image(now) & ". Start: Random WR test " & integer'image(i);

            bank_value := test_rand.rand(0, c_number_of_bank-1);
            lower_mem_reg(c_bank_addr_int) := std_logic_vector(to_unsigned(bank_value, 8));
            page_value := test_rand.rand(0, 255);
            lower_mem_reg(c_page_addr_int) := std_logic_vector(to_unsigned(page_value, 8));

            rand_lower_int1 := test_rand.rand(0, 125);
            rand_lower_int2 := test_rand.rand(rand_lower_int1, 125);
            for j in 0 to rand_lower_int2-rand_lower_int1 loop
                lower_mem_reg(rand_lower_int1 + j) := test_rand.rand(8);
            end loop;

            rand_upper_int1 := test_rand.rand(0, 127);
            rand_upper_int2 := test_rand.rand(rand_upper_int1, 127);
            for j in 0 to rand_upper_int2-rand_upper_int1 loop
                upper_mem_reg(bank_value)(page_value)(rand_upper_int1 + j) := test_rand.rand(8);
            end loop;
            
            i2c_master_transmit(t_byte_array'(c_bank_addr, lower_mem_reg(c_bank_addr_int to c_page_addr_int)),
                                "Writing random value to bank and page addr",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);

            i2c_master_transmit(c_bank_addr,
                                "Changing target addr to bank addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);

            i2c_master_check(lower_mem_reg(c_bank_addr_int to c_page_addr_int),
                            "Reading bank and page addr values",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);
        
            i2c_master_transmit(t_byte_array'(std_logic_vector(to_unsigned(rand_lower_int1, 8)),
                                            lower_mem_reg(rand_lower_int1 to rand_lower_int2)),
                                "Writing random values to lower mem",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);
            
            i2c_master_transmit(std_logic_vector(to_unsigned(rand_lower_int1, 8)),
                                "Changing target addr to random start addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);
            
            i2c_master_check(lower_mem_reg(rand_lower_int1 to rand_lower_int2),
                            "Reading lower mem",
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER);

            i2c_master_transmit(t_byte_array'(std_logic_vector(to_unsigned(rand_upper_int1+128, 8)),
                                            upper_mem_reg(bank_value)(page_value)(rand_upper_int1 to rand_upper_int2)),
                                "Writing random values to upper mem",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);

            i2c_master_transmit(std_logic_vector(to_unsigned(rand_upper_int1+128, 8)),
                                "Changing target addr to random start addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);

            i2c_master_check(upper_mem_reg(bank_value)(page_value)(rand_upper_int1 to rand_upper_int2),
                            "Reading upper mem",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);
            
        end loop;

        for i in 1 to 100 loop
            report "**  Time: " & time'image(now) & ". Start: Random RW test " & integer'image(i);

            i2c_master_transmit(c_bank_addr,
                                "Changing target addr to bank addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);
            
            i2c_master_check(lower_mem_reg(c_bank_addr_int to c_page_addr_int),
                            "Reading bank and page addr values",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);
            
            bank_value := test_rand.rand(0, c_number_of_bank-1);
            lower_mem_reg(c_bank_addr_int) := std_logic_vector(to_unsigned(bank_value, 8));
            page_value := test_rand.rand(0, 255);
            lower_mem_reg(c_page_addr_int) := std_logic_vector(to_unsigned(page_value, 8));

            i2c_master_transmit(t_byte_array'(c_bank_addr, lower_mem_reg(c_bank_addr_int to c_page_addr_int)),
                                "Writing random value to bank and page addr",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);

            rand_lower_int1 := test_rand.rand(0, 125);
            rand_lower_int2 := test_rand.rand(rand_lower_int1, 125);

            i2c_master_transmit(std_logic_vector(to_unsigned(rand_lower_int1, 8)),
                                "Changing target addr to random start addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);
            
            i2c_master_check(lower_mem_reg(rand_lower_int1 to rand_lower_int2),
                            "Reading lower mem",
                            i2c_if,
                            HOLD_LINE_AFTER_TRANSFER);

            for j in 0 to rand_lower_int2-rand_lower_int1 loop
                lower_mem_reg(rand_lower_int1 + j) := test_rand.rand(8);
            end loop;

            i2c_master_transmit(t_byte_array'(std_logic_vector(to_unsigned(rand_lower_int1, 8)),
                                            lower_mem_reg(rand_lower_int1 to rand_lower_int2)),
                                "Writing random values to lower mem",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);

            rand_upper_int1 := test_rand.rand(0, 127);
            rand_upper_int2 := test_rand.rand(rand_upper_int1, 127);

            i2c_master_transmit(std_logic_vector(to_unsigned(rand_upper_int1+128, 8)),
                                "Changing target addr to random start addr",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);

            i2c_master_check(upper_mem_reg(bank_value)(page_value)(rand_upper_int1 to rand_upper_int2),
                            "Reading upper mem",
                            i2c_if,
                            RELEASE_LINE_AFTER_TRANSFER);

            for j in 0 to rand_upper_int2-rand_upper_int1 loop
                upper_mem_reg(bank_value)(page_value)(rand_upper_int1 + j) := test_rand.rand(8);
            end loop;

            i2c_master_transmit(t_byte_array'(std_logic_vector(to_unsigned(rand_upper_int1+128, 8)),
                                            upper_mem_reg(bank_value)(page_value)(rand_upper_int1 to rand_upper_int2)),
                                "Writing random values to upper mem",
                                i2c_if,
                                RELEASE_LINE_AFTER_TRANSFER);

        end loop;

        i2c_master_transmit(x"00",
                                "Changing target addr to start of lower mem",
                                i2c_if,
                                HOLD_LINE_AFTER_TRANSFER);

        i2c_master_check(lower_mem_reg,
                        "Reading lower mem",
                        i2c_if,
                        RELEASE_LINE_AFTER_TRANSFER);

        -- for i in 0 to c_number_of_bank-1 loop
        --     bank_value := i;
        --     lower_mem_reg(c_bank_addr_int) := std_logic_vector(to_unsigned(bank_value, 8));

        --     i2c_master_transmit(t_byte_array'(c_bank_addr, lower_mem_reg(c_bank_addr_int)),
        --                         "Changing target addr to bank addr",
        --                         i2c_if,
        --                         HOLD_LINE_AFTER_TRANSFER);


        --     for j in 0 to 255 loop
        --         page_value := j;
        --         lower_mem_reg(c_page_addr_int) := std_logic_vector(to_unsigned(page_value, 8));

        --         i2c_master_transmit(t_byte_array'(c_page_addr, lower_mem_reg(c_page_addr_int)),
        --                         "Changing target addr to bank addr",
        --                         i2c_if,
        --                         HOLD_LINE_AFTER_TRANSFER);

        --         i2c_master_check(t_byte_array'(lower_mem_reg(127), upper_mem_reg(bank_value)(page_value)),
        --                         "Reading upper mem",
        --                         i2c_if,
        --                         RELEASE_LINE_AFTER_TRANSFER);
        --     end loop;
        -- end loop;

        wait for 1 us;
        std.env.stop;
    end process;

end architecture tb;
