# bind wave <Alt-d> {
#     if {[windowattribute wave -floating]} {
#         windowdock wave
#     } else {
#         windowfloat wave
#     }
# }

set vhdl_std        "-2008"

vcom $vhdl_std -work module_lib ../rtl/module_lib/*.vhd
vcom $vhdl_std -work work ../rtl/*.vhd
vcom $vhdl_std -work work ../testbench/module_I2C_tb.vhd

vsim -voptargs="+acc" work.module_i2c_tb

add wave -group "constant" \
sim:/module_i2c_tb/DUT/i2c_target_inst/c_sda_hold_cycle

add wave rst clk i2c_if

# env module_i2c_tb/test/
# add wave -group "process_debug" received_data(0) received_data(1) received_data(2) received_data(3)

add wave -divider
env module_i2c_tb/DUT/i2c_target_inst/

add wave -group "I2C_target" \
    state address
add wave -group "I2C_target" \
    -group "Debug" SCL SDA SCL_out SDA_out SCL_reg SDA_reg

add wave -group "Byte_Reg" \
    byte_reg current_addr value_reg byte_out

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

# large object only view when needed
# env module_i2c_tb/DUT/module_memory_inst/
# add wave -group "memory" \
#     lower_mem
#     module_memory

run -all

property wave -radix hex *
configure wave -gridperiod 50ns -timelineunits ns
view wave
seetime wave 0

# windowfloat wave
# Optional: move it to a specific spot (WidthxHeight+Xoffset+Yoffset)
# windowgeom wave -geometry 1200x800+1920+0