library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library module_lib;
context module_lib.module_context;

entity memory_select_logic is
    generic(
        g_number_of_bank        : integer := c_number_of_bank ;
        g_initial_bank_addr     : std_logic_vector(7 downto 0) := c_initial_bank_addr;
        g_initial_page_addr     : std_logic_vector(7 downto 0) := c_initial_page_addr
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
end entity memory_select_logic;

architecture rtl of memory_select_logic is
    type t_axi_state is (idle, rd_state, wr_state, wait_rd_req, wait_wr_req);
    signal state                    : t_axi_state := idle;
    signal shadow_bank_addr         : std_logic_vector(7 downto 0);
    signal shadow_page_addr         : std_logic_vector(7 downto 0);

    signal rd_ready_reg             : std_logic := '0';
    signal wr_ready_reg             : std_logic := '0';
begin
    
    addr_out <= addr_in;
    bank_addr <= shadow_bank_addr;
    page_addr <= shadow_page_addr;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rd_valid <= '0';
                wr_valid <= '0';
                shadow_bank_addr <= g_initial_bank_addr;
                shadow_page_addr <= g_initial_page_addr;
                read_done <= '1';
                write_done <= '1';
            else
                rd_ready_reg <= rd_ready;
                wr_ready_reg <= wr_ready;
                case state is
                    when idle =>
                        if read_req = '1' then
                            state <= rd_state;
                            read_done <= '0';
                        elsif write_req = '1' then
                            state <= wr_state;
                            write_done <= '0';
                        end if;
                    
                    when rd_state =>
                        if send_NACK = '1' then
                            state <= wait_wr_req;
                        else
                            rd_valid <= '1';
                            if rd_ready = '1' then
                                state <= wait_rd_req;
                            end if;
                        end if;
                    
                    when wr_state =>
                        if send_NACK = '1' then
                            state <= wait_wr_req;
                        else
                            wr_valid <= '1';
                            if wr_ready <= '1' then
                                state <= wait_wr_req;
                                mem_wr_data <= write_data;
                            end if;
                        end if;
                    
                    when wait_rd_req =>
                        rd_valid <= '0';
                        if rd_ready_reg = '0' and rd_ready = '1' then
                            read_done <= '1';
                            read_data <= mem_rd_data;
                            if addr_in = x"7E" then
                                shadow_bank_addr <= mem_rd_data;
                            elsif addr_in = x"7F" then
                                shadow_page_addr <= mem_rd_data;
                            end if;
                        end if;
                        if read_req = '0' then
                            state <= idle;
                        end if;

                    when wait_wr_req =>
                        wr_valid <= '0';
                        if wr_ready_reg = '0' and wr_ready = '1' then
                            write_done <= '1';
                            if addr_in = x"7E" then
                                shadow_bank_addr <= write_data;
                            elsif addr_in = x"7F" then
                                shadow_page_addr <= write_data;
                            end if;
                        end if;
                        if write_req = '0' then
                            state <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process;

    invalid_access: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                send_NACK <= '0';
            else
                if write_req = '1' then
                    if addr_in = x"7E" and
                    to_integer(unsigned(write_data)) > g_number_of_bank-1 then
                        send_NACK <= '1';
                    end if;
                else
                    send_NACK <= '0';
                end if;
            end if;
        end if;
    end process;


end architecture;