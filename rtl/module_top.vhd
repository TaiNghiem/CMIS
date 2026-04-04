library IEEE;
library module_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use module_lib.module_pkg.all;

entity module_top is
    generic(
        g_SDA_hold_time         : time := 100 ns;
        g_module_freq_hz        : integer := 100_000_000
    );
    port(
        clk         : in    std_logic;
        rst         : in    std_logic;

        SCL         : inout std_logic;
        SDA         : inout std_logic;
    );
end entity module_top;

architecture rtl of module_top is

    signal read_req    : std_logic;
    signal write_req   : std_logic;
    signal address     : std_logic_vector(7 downto 0);
    signal write_data  : std_logic_vector(7 downto 0);
    signal read_data   : std_logic_vector(7 downto 0);
    signal read_done   : std_logic;
    signal write_done  : std_logic;
    signal send_NACK   : std_logic;

    component i2c_target
        generic (
            g_SDA_hold_time : time := 100 ns;
            g_module_freq_hz : integer := 100_000_000
        );
        port (
            clk      : in std_logic;
            rst      : in std_logic;
            SCL      : inout std_logic;
            SDA      : inout std_logic;
            read_req : out std_logic;
            ... -- etc
        );
    end component;

    component module_select_logic
        generic(
            g_number_of_bank        : integer := c_number_of_bank ;
            g_initial_bank_addr     : std_logic_vector(7 downto 0) := (others => '0');
            g_initial_page_addr     : std_logic_vector(7 downto 0) := (others => '0')
        );
        port(
            clk         : in    std_logic;
            rst         : in    std_logic;

            read_req    : out std_logic;
            write_req   : out std_logic;
            addr_in     : in std_logic_vector(7 downto 0);
            write_data  : in std_logic_vector(7 downto 0);
            read_data   : out std_logic_vector(7 downto 0);

            read_done   : out std_logic;
            write_done  : out std_logic;
            send_NACK   : out std_logic;

            rd_valid    : out std_logic;
            rd_ready    : in std_logic;
            wr_valid    : out std_logic;
            wr_ready    : in std_logic;
            bank_addr   : out std_logic_vector := g_initial_bank_addr;
            page_addr   : out std_logic_vector := g_initial_page_addr;
            addr_out    : out std_logic_vector(7 downto 0);
            mem_rd_data : in std_logic_vector(7 downto 0);
            mem_wr_data : out std_logic_vector(7 downto 0)
        );
    end component;
begin
    i2c_target_inst : i2c_target
        generic map (
            g_SDA_hold_time => g_SDA_hold_time,
            g_module_freq_hz => g_module_freq_hz
        )
        port map (
            clk => clk,
            rst => rst,
            SCL => SCL,
            SDA => SDA,
            read_req => read_req,
            write_req => write_req,
            address => address,
            write_data => write_data,
            read_data => read_data,
            read_done => read_done,
            write_done => write_done,
            send_NACK => send_NACK
        );
    
    memory_select_logic_inst : memory_select_logic
        generic map (
            g_number_of_bank => c_number_of_bank,
            g_initial_bank_addr => (others => '0'),
            g_initial_page_addr => (others => '0')
        )
        port map (
            clk => clk,
            rst => rst,
            read_req => read_req,
            write_req => write_req,
            addr_in => address,
            write_data => write_data,
            read_data => read_data,
            read_done => read_done,
            write_done => write_done,
            send_NACK => send_NACK,
            

end architecture;