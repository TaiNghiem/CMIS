library IEEE;
library module_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use module_lib.module_pkg.all;

entity module_memory is
    -- generic(
        -- g_number_of_bank            : integer := c_number_of_bank
    -- );
    port(
        clk         : in    std_logic;
        rst         : in    std_logic;

        rd_valid    : in std_logic;
        rd_ready    : out std_logic;
        wr_valid    : in std_logic;
        wr_ready    : out std_logic;
        bank_addr   : in std_logic_vector;
        page_addr   : in std_logic_vector;
        addr_in     : in std_logic_vector(7 downto 0);
        mem_rd_data : out std_logic_vector(7 downto 0);
        mem_wr_data : in std_logic_vector(7 downto 0)
    );
end entity module_memory;

architecture rtl of module_memory is

    type mem_state is (idle, rd_state, wr_state);
    signal state            : mem_state := idle;
    
    signal lower_mem        : t_page := c_init_lower_mem;
    signal module_memory    : t_mem := c_init_mem;

    signal bank_addr_int    : integer;
    signal page_addr_int    : integer;
    signal addr_int         : integer;

begin
    bank_addr_int <= to_integer(unsigned(bank_addr));
    page_addr_int <= to_integer(unsigned(page_addr));
    addr_int <= to_integer(unsigned(addr_in));

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= idle;
                rd_ready <= '0';
                wr_ready <= '0';
            else
                case state is
                    when idle =>
                        if rd_valid = '1' then
                            rd_ready <= '0';
                            state <= rd_state;
                        elsif wr_valid = '1' then
                            wr_ready <= '0';
                            state <= wr_state;
                        end if;

                    when rd_state =>
                        if addr_int < 128 then
                            mem_rd_data <= lower_mem(addr_int);
                        else
                            mem_rd_data <= module_memory(bank_addr_int)(page_addr_int)(addr_int-128);
                        end if;
                        rd_ready <= '1';
                        state <= idle;

                    when wr_state =>
                        if addr_int < 128 then
                            lower_mem(addr_int) <= mem_wr_data;
                        else
                            module_memory(bank_addr_int)(page_addr_int)(addr_int-128) <= mem_wr_data;
                        end if;
                        wr_ready <= '1';
                        state <= idle;
                    when others =>
                        state <= idle;
                end case;
            end if;
        end if;
    end process;

end architecture;