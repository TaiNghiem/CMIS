# bind wave <Alt-d> {
#     if {[windowattribute wave -floating]} {
#         windowdock wave
#     } else {
#         windowfloat wave
#     }
# }

set vhdl_std        "-2008"

vcom $vhdl_std -work module_lib ../rtl/module_lib/*.vhd
vcom $vhdl_std -work sim_lib ../testbench/sim_lib/*.vhd
vcom $vhdl_std -work work ../rtl/*.vhd
vcom $vhdl_std -work work ../testbench/module_I2C_tb.vhd

vsim -voptargs="+acc" work.module_i2c_tb

add wave -group "constant" \
sim:/module_i2c_tb/DUT/i2c_target_inst/c_sda_hold_cycle

add wave rst clk i2c_if

env module_i2c_tb/test/
add wave -group "process_debug" \
    lower_mem_reg(126) lower_mem_reg(127) bank_value page_value

add wave -divider
env module_i2c_tb/DUT/i2c_target_inst/

add wave -group "I2C_target" \
    state address
add wave -group "I2C_target" \
    -group "Debug" SCL_out SDA_out SCL_reg SDA_reg read_trans write_trans

add wave -group "Byte_Reg" \
    byte_reg current_addr byte_out bit_count

add wave -divider

add wave -group "START_STOP" \
    START_detect STOP_detect
add wave -group "START_STOP" \
    -group "Debug" illegal_SDA_edge STOP_illegal START_illegal START_legal STOP_legal START_repeat

add wave -group "Counter" \
    wait_timer hold_timer

add wave -divider

env module_i2c_tb/DUT/memory_select_logic_inst/

add wave -group "Mem_sel" \
    state
add wave -group "Mem_sel" -group "Read" \
    read_* rd_*
add wave -group "Mem_sel" -group "Write" \
    write_* wr_* send_NACK
add wave -group "Mem_sel" -group "Debug" \
    bank_addr page_addr \
    shadow_bank_addr shadow_page_addr

# large object only view when needed
env module_i2c_tb/DUT/module_memory_inst/
add wave -group "memory" \
    lower_mem(126) lower_mem(127) \

run -all

property wave -radix hex *
configure wave -gridperiod 50ns -timelineunits ns
view wave
seetime wave 0

# windowfloat wave
# Optional: move it to a specific spot (WidthxHeight+Xoffset+Yoffset)
# windowgeom wave -geometry 1200x800+1920+0