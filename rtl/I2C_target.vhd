library IEEE;
library module_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use module_lib.module_pkg.all;

entity I2C_target is
    generic(
        g_SDA_hold_time         : time := c_SDA_hold_time;
        g_module_freq_hz        : integer := c_module_freq_hz
    );
    port(
        clk         : in    std_logic;
        rst         : in    std_logic;

        SCL         : inout std_logic;
        SDA         : inout std_logic;

        read_req    : out std_logic;
        write_req   : out std_logic;
        address     : out std_logic_vector(7 downto 0);
        write_data  : out std_logic_vector(7 downto 0);
        read_data   : in std_logic_vector(7 downto 0);

        read_done   : in std_logic;
        write_done  : in std_logic;
        send_NACK   : in std_logic
    );
end entity I2C_target;

architecture rtl of I2C_target is

    constant c_sda_hold_cycle   : integer := (g_SDA_hold_time / 1 sec) * g_module_freq_hz;


    type t_target_state is (idle, get_first_byte,
                        send_ACK, receive_ACK,
                        send_byte, receive_byte,
                        wait_op);
    signal state        : t_target_state := idle;
    
    signal SCL_reg      : std_logic;
    signal SDA_reg      : std_logic;
    
    signal SCL_out      : std_logic;
    signal SDA_out      : std_logic;
    signal byte_out     : std_logic_vector(7 downto 0);
    
    --reg with 1 tick (clock cycle) delay
    signal SCL_reg1     : std_logic;
    signal SDA_reg1     : std_logic;

    signal SCL_rising_edge  : std_logic := '0';
    signal SCL_falling_edge : std_logic := '0';

    signal START_detect     : std_logic := '0';
    signal STOP_detect      : std_logic := '0';

    signal byte_reg         : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count        : integer range 0 to 8 := 0;
    signal read_trans       : std_logic := '0';
    signal write_trans      : std_logic := '0';
    signal op_done          : std_logic := '0';
    signal wait_timer       : integer := 0;
    signal get_value_byte   : std_logic := '0';
    signal incr_addr        : std_logic := '0';
    signal hold_timer       : integer := 0;

    signal illegal_SDA_edge : std_logic;

    signal current_addr     : std_logic_vector(7 downto 0) := "10100000";
    signal value_reg        : std_logic_vector(7 downto 0);

    signal STOP_illegal     : std_logic;
    signal START_illegal    : std_logic;
    signal STOP_legal       : std_logic;
    signal START_legal      : std_logic;
    signal START_repeat     : std_logic;

    signal late_SCL         : std_logic;

    signal SCL_stretch      : std_logic;
    signal ACK_received     : std_logic;

    --debounce?

begin
    SCL_reg <= to_X01(SCL);
    SDA_reg <= to_X01(SDA);

    SDA <= '0' when SDA_out = '0' else 'Z';
    SCL <= '0' when SCL_out = '0' else 'Z'; 

    --reset condition?
    Sampling: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                SCL_reg <= 'Z';
                SDA_reg <= 'Z';
                SCL_reg1 <= 'Z';
                SDA_reg1 <= 'Z';
                SCL_rising_edge <= '0';
                SCL_falling_edge <= '0';
                START_detect <= '0';
                STOP_detect <= '0';
            else
                SCL_reg1 <= SCL_reg;
                SDA_reg1 <= SDA_reg;
                
                SCL_falling_edge <= '0';
                SCL_rising_edge <= '0';
                if SCL_reg = '1' and SCL_reg1 = '0' then
                    SCL_rising_edge <= '1';
                elsif SCL_reg = '0' and SCL_reg1 = '1' then
                    SCL_falling_edge <= '1';
                end if;

                START_detect <= '0';
                STOP_detect <= '0';
                if SCL_reg = '1' and SCL_reg1 = '1' and
                SDA_reg = '0' and SDA_reg1 = '1' then
                    START_detect <= '1';
                elsif SCL_reg = '1' and SCL_reg1 = '1' and
                SDA_reg = '1' and SDA_reg1 = '0' then
                    STOP_detect <= '1';
                end if;
            end if;
        end if;
    end process;

    I2C_state_machine : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= idle;
                SCL_out <= 'Z';
                SDA_out <= 'Z';
            else
                case state is
                    when idle =>
                        bit_count <= 0;
                        read_trans <= '0';
                        write_trans <= '0';
                        wait_timer <= 0;
                        get_value_byte <= '0';
                        byte_reg <= (others => '0');
                        illegal_SDA_edge <= '0';
                        STOP_illegal <= '0';
                        START_illegal <= '0';
                        read_req <= '0';
                        write_req <= '0';
                        
                        if START_detect = '1' then
                            state <= get_first_byte;
                        elsif START_repeat = '1' then
                            state <= get_first_byte;
                            START_repeat <= '0';
                        end if;
                    
                    --during transaction, state only change at scl falling edge
                    when get_first_byte =>
                        if SCL_rising_edge = '1' and bit_count < 8 then
                            byte_reg(7 - bit_count) <= SDA_reg;
                            bit_count <= bit_count + 1;
                        end if;

                        if bit_count = 8 then
                            if byte_reg(7 downto 1) = "1010000" then
                                if SCL_falling_edge = '1' then
                                    state <= send_ACK;
                                    bit_count <= 0;
                                    START_illegal <= '0';
                                    STOP_illegal <= '0';
                                    illegal_SDA_edge <= '0';
                                end if;

                                if byte_reg(0) = '1' then
                                    read_trans <= '1';
                                    read_req <= '1';
                                elsif byte_reg(0) = '0' then
                                    write_trans <= '1';
                                    get_value_byte <= '0';
                                end if;
                            elsif SCL_falling_edge = '1' then
                                    state <= idle;
                            end if;
                        end if;
                        
                        if START_detect = '1' or STOP_detect = '1' then
                            illegal_SDA_edge <= '1';
                            START_illegal <= START_detect;
                            STOP_illegal <= STOP_detect;
                        elsif STOP_legal = '1' or START_legal = '1' then
                            state <= idle;
                            START_repeat <= START_legal;
                        elsif late_SCL = '1' then
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;


                    when send_ACK =>
                        if send_NACK = '1' then
                            SDA_out <= 'Z';
                        else
                            SDA_out <= '0';
                            if SCL_falling_edge = '1' then
                                state <= wait_op;
                                SDA_out <= 'Z';
                                if incr_addr = '1' then
                                    current_addr <= std_logic_vector(unsigned(current_addr) + 1);
                                    incr_addr <= '0';
                                end if;
                                START_illegal <= '0';
                                STOP_illegal <= '0';
                                illegal_SDA_edge <= '0';
                            end if;
                        end if;

                        if START_detect = '1' or STOP_detect = '1' then
                            illegal_SDA_edge <= '1';
                            START_illegal <= START_detect;
                            STOP_illegal <= STOP_detect;
                        elsif STOP_legal = '1' or START_legal = '1' then
                            state <= idle;
                            START_repeat <= START_legal;
                        end if;
                    
                    --handle clock strecht
                    --will switch state while stil stretching the clock even if operation done
                    --to prevent sda change too close to scl release
                    --in case op done before scl falling edge, go to next state immediately
                    when wait_op =>
                        if op_done = '0' then
                            SCL_out <= '0';
                            SCL_stretch <= '1';
                            wait_timer <= 0;
                        else
                            if read_trans = '1' then
                                state <= send_byte;
                                read_req <= '0';
                            elsif write_trans = '1' then
                                state <= receive_byte;
                                write_req <= '0';
                            end if;
                        end if;

                    
                    when send_byte => 
                        if SCL_stretch = '1' then
                            SDA_out <= byte_out(7);             --load first read bit before release scl
                            bit_count <= 1;
                            if wait_timer < 4 then
                                wait_timer <= wait_timer + 1;
                            else
                                SCL_out <= 'Z';
                                SCL_stretch <= '0';
                                wait_timer <= 0;
                            end if;
                        elsif SCL_falling_edge = '1' then
                            if bit_count < 8 then
                                SDA_out <= byte_out(7 - bit_count);
                                bit_count <= bit_count + 1;
                            end if;
                        end if;

                        if SCL_falling_edge = '1' and bit_count = 8 then
                            state <= receive_ACK;
                            bit_count <= 0;
                            SDA_out <= 'Z';
                            incr_addr <= '1';
                            read_req <= '1';
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;

                        if START_detect = '1' or STOP_detect = '1' then
                            illegal_SDA_edge <= '1';
                            START_illegal <= START_detect;
                            STOP_illegal <= STOP_detect;
                        elsif STOP_legal = '1' or START_legal = '1' then
                            state <= idle;
                            START_repeat <= START_legal;
                        elsif late_SCL = '1' then
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;


                    when receive_byte =>
                        if SCL_stretch = '1' then
                            SCL_out <= 'Z';
                            SCL_stretch <= '0';
                        end if;

                        if SCL_rising_edge = '1' then
                            if bit_count < 8 then
                                byte_reg(7 - bit_count) <= SDA_reg;
                                bit_count <= bit_count + 1;
                            end if;
                        end if;

                        if bit_count = 8 and SCL_falling_edge = '1' then
                            state <= send_ACK;
                            bit_count <= 0;
                            if get_value_byte = '0' then
                                get_value_byte <= '1';
                                current_addr <= byte_reg(7 downto 0);
                            elsif get_value_byte = '1' then
                                incr_addr <= '1';                           --addr incr after ACK
                                value_reg <= byte_reg;
                                write_req <= '1';
                            end if;
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;

                        if START_detect = '1' or STOP_detect = '1' then
                            illegal_SDA_edge <= '1';
                            START_illegal <= START_detect;
                            STOP_illegal <= STOP_detect;
                        elsif STOP_legal = '1' or START_legal = '1' then
                            state <= idle;
                            START_repeat <= START_legal;
                        elsif late_SCL = '1' then
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;

                    
                    when receive_ACK =>
                        if SCL_rising_edge = '1' then
                            if SDA_reg <= '1' then
                                state <= idle;
                            elsif SDA_reg <= '0' then
                                ACK_received <= '1';
                            end if;
                        end if;

                        if SCL_falling_edge = '1' then
                            if ACK_received = '1' then
                                state <= wait_op;
                                if incr_addr = '1' then
                                    incr_addr <= '0';
                                    current_addr <= std_logic_vector(unsigned(current_addr) + 1);
                                end if;
                            end if;
                        end if;

                        if START_detect = '1' or STOP_detect = '1' then
                            illegal_SDA_edge <= '1';
                            START_illegal <= START_detect;
                            STOP_illegal <= STOP_detect;
                        elsif STOP_legal = '1' or START_legal = '1' then
                            state <= idle;
                            START_repeat <= START_legal;
                        elsif late_SCL = '1' then
                            START_illegal <= '0';
                            STOP_illegal <= '0';
                            illegal_SDA_edge <= '0';
                        end if;
                    
                    when others =>
                        state <= idle;
                        assert false
                            report "I2CMCI target enter unavailable state!!!"
                            severity error;
                end case;
            end if;
        end if;
    end process;            

    SDA_hold_timer : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                hold_timer <= 0;
                STOP_legal <= '0';
                START_legal <= '0';
                late_SCL <= '0';
            elsif illegal_SDA_edge = '1' then
                late_SCL <= '0';
                if SCL_falling_edge = '0' then
                    if hold_timer < c_SDA_hold_cycle then
                        hold_timer <= hold_timer + 1;
                    else
                        if STOP_illegal = '1' then
                            STOP_legal <= '1';
                        elsif START_legal = '1' then
                            START_legal <= '1';
                        end if;
                    end if;
                elsif SCL_falling_edge = '1' then
                    late_SCL <= '1';
                end if;
            elsif illegal_SDA_edge = '0' then
                hold_timer <= 0;
                STOP_legal <= '0';
                START_legal <= '0';
            end if;
        end if;
    end process;
    
    address <= current_addr;
    op_done <= read_done and write_done;
    write_data <= value_reg;
    byte_out <= read_data;

end architecture;