library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library module_lib;
use module_lib.module_pkg.all;

entity module_top is
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

    signal rd_valid    : std_logic;
    signal rd_ready    : std_logic;
    signal wr_valid    : std_logic;
    signal wr_ready    : std_logic;
    signal bank_addr   : std_logic_vector(7 downto 0);
    signal page_addr   : std_logic_vector(7 downto 0);
    signal addr_out    : std_logic_vector(7 downto 0);
    signal mem_rd_data : std_logic_vector(7 downto 0);
    signal mem_wr_data : std_logic_vector(7 downto 0);

    component i2c_target
        generic (
            g_SDA_hold_time     : time := 100 ns;
            g_module_freq_hz    : real := 100_000_000.0
        );
        port (
            clk      : in std_logic;
            rst      : in std_logic;
            SCL      : inout std_logic;
            SDA      : inout std_logic;

            read_req    : out std_logic;
            write_req   : out std_logic;
            address     : out std_logic_vector(7 downto 0);
            write_data  : out std_logic_vector(7 downto 0);
            read_data   : in std_logic_vector(7 downto 0);

            read_done   : in std_logic;
            write_done  : in std_logic;
            send_NACK   : in std_logic;
            offset_NACK : in std_logic
        );
    end component;

    component memory_select_logic
        generic(
            g_number_of_bank        : integer := c_number_of_bank ;
            g_initial_bank_addr     : std_logic_vector(7 downto 0) := (others => '0');
            g_initial_page_addr     : std_logic_vector(7 downto 0) := (others => '0')
        );
        port(
            clk         : in    std_logic;
            rst         : in    std_logic;

            read_req    : in std_logic;
            write_req   : in std_logic;
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

    component module_memory
        port(
            clk         : in    std_logic;
            rst         : in    std_logic;

            rd_valid    : in std_logic;
            rd_ready    : out std_logic;
            wr_valid    : in std_logic;
            wr_ready    : out std_logic;

            bank_addr   : in std_logic_vector(7 downto 0);
            page_addr   : in std_logic_vector(7 downto 0);
            addr_in     : in std_logic_vector(7 downto 0);
            mem_rd_data : out std_logic_vector(7 downto 0);
            mem_wr_data : in std_logic_vector(7 downto 0)
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

            read_req    => read_req,
            write_req   => write_req,
            address     => address,
            write_data  => write_data,
            read_data   => read_data,
            read_done   => read_done,
            write_done  => write_done,
            send_NACK   => send_NACK,
            offset_NACK => '0'
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

            read_req    => read_req,
            write_req   => write_req,
            addr_in     => address,
            write_data  => write_data,
            read_data   => read_data,
            read_done   => read_done,
            write_done  => write_done,
            send_NACK   => send_NACK,

            rd_valid    => rd_valid,
            rd_ready    => rd_ready,
            wr_valid    => wr_valid,
            wr_ready    => wr_ready,
            bank_addr   => bank_addr,
            page_addr   => page_addr,
            addr_out    => addr_out,
            mem_rd_data => mem_rd_data,
            mem_wr_data => mem_wr_data
        );

    module_memory_inst : module_memory
        port map (
            clk         => clk,
            rst         => rst,
            rd_valid    => rd_valid,
            rd_ready    => rd_ready,
            wr_valid    => wr_valid,
            wr_ready    => wr_ready,

            bank_addr   => bank_addr,
            page_addr   => page_addr,
            addr_in     => addr_out,
            mem_rd_data => mem_rd_data,
            mem_wr_data => mem_wr_data
        );

end architecture;