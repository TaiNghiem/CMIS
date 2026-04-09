# Setup paths (Modify these for your project)
set project_name    "CMIS_module"
set vhdl_std        "-2008"

# Need UVVM to run tb
# set uvvm_path       "path/to/uvvm"

# Create and Map the Work Library
# 'quietly' keeps the transcript clean
if {[file exists work]} {
    vdel -all -lib work
}
if {[file exists module_lib]} {
    vdel -all -lib module_lib
}
vlib work
vmap work work
vlib module_lib
vmap module_lib module_lib

# 3. Compile Source Files
# List your files in dependency order (Packages -> RTL -> TB)
# puts "--- Compiling RTL and Packages ---"
vcom $vhdl_std -work module_lib ../rtl/module_lib/*.vhd
vcom $vhdl_std -work work ../rtl/*.vhd


# puts "--- Compiling Testbench ---"
# vcom $vhdl_std -work work ./tb/my_testbench.vhd