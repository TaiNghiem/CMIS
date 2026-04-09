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

add wave -position insertpoint  \
sim:/module_i2c_tb/clk \
sim:/module_i2c_tb/rst \
sim:/module_i2c_tb/SCL \
sim:/module_i2c_tb/SDA \
sim:/module_i2c_tb/i2c_if

add wave -position insertpoint -group "I2C_target" \
sim:/module_i2c_tb/DUT/i2c_target_inst/state \
sim:/module_i2c_tb/DUT/i2c_target_inst/SCL_reg \
sim:/module_i2c_tb/DUT/i2c_target_inst/SDA_reg \
sim:/module_i2c_tb/DUT/i2c_target_inst/SCL \
sim:/module_i2c_tb/DUT/i2c_target_inst/SDA \
sim:/module_i2c_tb/DUT/i2c_target_inst/SCL_out \
sim:/module_i2c_tb/DUT/i2c_target_inst/SDA_out

add wave -position insertpoint -group "START_STOP" \
sim:/module_i2c_tb/DUT/i2c_target_inst/START_detect \
sim:/module_i2c_tb/DUT/i2c_target_inst/STOP_detect \
sim:/module_i2c_tb/DUT/i2c_target_inst/illegal_SDA_edge \
sim:/module_i2c_tb/DUT/i2c_target_inst/STOP_illegal \
sim:/module_i2c_tb/DUT/i2c_target_inst/START_illegal \
sim:/module_i2c_tb/DUT/i2c_target_inst/STOP_legal \
sim:/module_i2c_tb/DUT/i2c_target_inst/START_legal

# large object only view when needed
# add wave -position insertpoint  -group "memory"\
# sim:/module_i2c_tb/DUT/module_memory_inst/lower_mem \
# sim:/module_i2c_tb/DUT/module_memory_inst/module_memory

run -all

see 0
view wave
# windowfloat wave
# Optional: move it to a specific spot (WidthxHeight+Xoffset+Yoffset)
# windowgeom wave -geometry 1200x800+1920+0