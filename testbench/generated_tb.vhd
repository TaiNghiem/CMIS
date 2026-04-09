library IEEE;
library module_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use module_lib.module_pkg.all;

library uvvm_util;
library bitvis_vip_i2c;
use bitvis_vip_i2c.i2c_bfm_pkg.all;

entity gernerated_tb is
end entity gernerated_tb;

architecture tb of gernerated_tb is

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
    
    constant C_CLK_PERIOD       : time := 10 ns;
    constant C_I2C_FREQ_HZ      : integer := 100_000;
    constant C_I2C_SLAVE_ADDR   : std_logic_vector(6 downto 0) := "1010000";
    constant C_I2C_REG_ADDR     : std_logic_vector(7 downto 0) := x"10";
    constant C_I2C_EXPECTED_DATA: std_logic_vector(7 downto 0) := x"55";

    -- I2C Standard timing constants (in ns)
    constant C_TCLK             : time := 10_000 ns;
    constant C_TDATA            : time := 5_000 ns;

    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '1';
    signal SCL                  : std_logic := 'H';     -- Open-drain
    signal SDA                  : std_logic := 'H';     -- Open-drain
    
    -- I2C Master signals (for internal I2C bus control)
    signal scl_master           : std_logic := '1';     -- 1 = release
    signal sda_master           : std_logic := '1';     -- 1 = release

    procedure i2c_start(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
    begin
        sda_master <= '1';
        scl_master <= '1';
        wait for C_TDATA;
        sda_master <= '0';
        wait for C_TDATA;
        scl_master <= '0';
        wait for C_TCLK;
    end procedure;

    procedure i2c_stop(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
    begin
        sda_master <= '0';
        wait for C_TDATA;
        scl_master <= '1';
        wait for C_TCLK;
        sda_master <= '1';
        wait for C_TDATA;
    end procedure;

    procedure i2c_write_bit(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        constant bit_data : std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
    begin
        sda_master <= bit_data;
        wait for C_TDATA;
        scl_master <= '1';
        wait for C_TCLK;
        scl_master <= '0';
        wait for C_TDATA;
    end procedure;

    procedure i2c_read_bit(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        signal SDA       : in  std_logic;
        variable bit_out : out std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
    begin
        sda_master <= '1';
        wait for C_TDATA;
        scl_master <= '1';
        wait for C_TDATA;
        bit_out := SDA;
        wait for C_TCLK - C_TDATA;
        scl_master <= '0';
        wait for C_TDATA;
    end procedure;

    procedure i2c_write_byte(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        signal SDA       : in  std_logic;
        constant data_in : std_logic_vector(7 downto 0);
        variable ack_out : out std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
    begin
        for i in 7 downto 0 loop
            i2c_write_bit(scl_master, sda_master, data_in(i), C_TCLK, C_TDATA);
        end loop;
        i2c_read_bit(scl_master, sda_master, SDA, ack_out, C_TCLK, C_TDATA);
    end procedure;

    procedure i2c_read_byte(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        signal SDA       : in  std_logic;
        variable data_out : out std_logic_vector(7 downto 0);
        constant master_ack : std_logic;
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
        variable bit_read : std_logic;
    begin
        for i in 7 downto 0 loop
            i2c_read_bit(scl_master, sda_master, SDA, bit_read, C_TCLK, C_TDATA);
            data_out(i) := bit_read;
        end loop;

        sda_master <= master_ack;
        wait for C_TDATA;
        scl_master <= '1';
        wait for C_TCLK;
        scl_master <= '0';
        wait for C_TDATA;
        sda_master <= '1';
        wait for C_TDATA;
    end procedure;

    procedure verify_i2c_slave(
        signal scl_master : out std_logic;
        signal sda_master : out std_logic;
        signal SDA        : in  std_logic;
        constant slave_addr   : std_logic_vector(6 downto 0);
        constant register_addr: std_logic_vector(7 downto 0);
        constant expected_data: std_logic_vector(7 downto 0);
        constant C_TCLK   : time;
        constant C_TDATA  : time
    ) is
        variable ack       : std_logic;
        variable read_data : std_logic_vector(7 downto 0);
        variable pass      : boolean := true;
    begin
        report "UVVM I2C Slave Verify: START" severity NOTE;

        i2c_start(scl_master, sda_master, C_TCLK, C_TDATA);
        i2c_write_byte(scl_master, sda_master, SDA, slave_addr & '0', ack, C_TCLK, C_TDATA);
        if ack /= '0' then
            report "ERROR: Slave did not ACK address+W" severity ERROR;
            pass := false;
        end if;

        i2c_write_byte(scl_master, sda_master, SDA, register_addr, ack, C_TCLK, C_TDATA);
        if ack /= '0' then
            report "ERROR: Slave did not ACK register address" severity ERROR;
            pass := false;
        end if;

        i2c_start(scl_master, sda_master, C_TCLK, C_TDATA);
        i2c_write_byte(scl_master, sda_master, SDA, slave_addr & '1', ack, C_TCLK, C_TDATA);
        if ack /= '0' then
            report "ERROR: Slave did not ACK address+R" severity ERROR;
            pass := false;
        end if;

        i2c_read_byte(scl_master, sda_master, SDA, read_data, '1', C_TCLK, C_TDATA);
        i2c_stop(scl_master, sda_master, C_TCLK, C_TDATA);

        if read_data /= expected_data then
            report "ERROR: I2C read data mismatch: expected " & integer'image(to_integer(unsigned(expected_data))) &
                   ", got " & integer'image(to_integer(unsigned(read_data))) severity ERROR;
            pass := false;
        else
            report "NOTE: I2C read data matches expected value" severity NOTE;
        end if;

        if pass then
            report "UVVM I2C Slave Verify: PASSED" severity NOTE;
        else
            report "UVVM I2C Slave Verify: FAILED" severity ERROR;
        end if;
    end procedure;

begin

    DUT : module_top
        generic map (
            g_SDA_hold_time         => C_SDA_HOLD_TIME,
            g_module_freq_hz        => C_I2C_FREQ_HZ
        )
        port map (
            clk         => clk,
            rst         => rst,
            SCL         => SCL,
            SDA         => SDA
        );

    clk_gen: process
    begin
        clk <= '0';
        wait for C_CLK_PERIOD / 2;
        clk <= '1';
        wait for C_CLK_PERIOD / 2;
    end process;

    SCL <= '0' when (scl_master = '0' or SCL'driving_value = '0') else 'H';
    SDA <= '0' when (sda_master = '0' or SDA'driving_value = '0') else 'H';

    process
    begin
        report "========== TESTBENCH START ==========" severity NOTE;
        report "Test: I2C Target Module Verification" severity NOTE;
        
        -- Release I2C bus
        scl_master <= '1';
        sda_master <= '1';
        
        -- Hold reset for several clock cycles
        rst <= '1';
        wait for 10 * C_CLK_PERIOD;
        rst <= '0';
        wait for 10 * C_CLK_PERIOD;
        
        report "Reset released, starting I2C transactions..." severity NOTE;

        -- UVVM-style I2C slave verification helper
        verify_i2c_slave(scl_master, sda_master, SDA, C_I2C_SLAVE_ADDR, C_I2C_REG_ADDR, C_I2C_EXPECTED_DATA, C_TCLK, C_TDATA);

        -- ---------------------------------------------------------------
        -- TEST 1: Verify I2C Bus Idle
        -- ---------------------------------------------------------------
        report "TEST 1: Check I2C bus idle state" severity NOTE;
        wait for 10 * C_CLK_PERIOD;
        assert SCL = 'H' or SCL = '1' report "ERROR: SCL should be high (idle)" severity ERROR;
        assert SDA = 'H' or SDA = '1' report "ERROR: SDA should be high (idle)" severity ERROR;
        report "TEST 1: PASSED" severity NOTE;

        -- ---------------------------------------------------------------
        -- TEST 2: I2C START Condition (SCL high, SDA high->low)
        -- ---------------------------------------------------------------
        report "TEST 2: Generate I2C START condition" severity NOTE;
        wait for C_TDATA;
        sda_master <= '0';  -- Pull SDA low while SCL is high
        wait for C_TCLK;
        report "TEST 2: START condition sent" severity NOTE;

        -- ---------------------------------------------------------------
        -- TEST 3: I2C STOP Condition (SCL high, SDA low->high)
        -- ---------------------------------------------------------------
        report "TEST 3: Generate I2C STOP condition" severity NOTE;
        scl_master <= '0';  -- Pull SCL low
        wait for C_TCLK;
        scl_master <= '1';  -- Release SCL (allow high)
        wait for C_TCLK;
        sda_master <= '1';  -- Release SDA (allow high) after SCL high
        wait for C_TCLK;
        report "TEST 3: STOP condition sent" severity NOTE;

        -- ---------------------------------------------------------------
        -- TEST 4: Release bus and idle
        -- ---------------------------------------------------------------
        report "TEST 4: Release bus and verify idle state" severity NOTE;
        scl_master <= '1';
        sda_master <= '1';
        wait for 20 * C_CLK_PERIOD;
        assert SCL = 'H' or SCL = '1' report "ERROR: SCL should be high after STOP" severity ERROR;
        assert SDA = 'H' or SDA = '1' report "ERROR: SDA should be high after STOP" severity ERROR;
        report "TEST 4: PASSED" severity NOTE;

        -- ---------------------------------------------------------------
        -- Testbench End
        -- ---------------------------------------------------------------
        report "========== TESTBENCH COMPLETE ==========" severity NOTE;
        wait;  -- Stop simulation

    end process;

    process
    begin
        wait until rising_edge(clk);
        -- Add monitoring statements here if needed
        -- report "Time: " & time'image(now) & ", SCL: " & std_logic'image(SCL) & ", SDA: " & std_logic'image(SDA) severity NOTE;
    end process;

end architecture tb;
