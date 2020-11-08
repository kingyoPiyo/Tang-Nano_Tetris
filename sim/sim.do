vlib work
vmap work work

vlog \
	-L work \
	-l vlog.log \
	-work work \
	-timescale "1ns / 100ps"  \
	-f filelist.txt 

vsim tb_top -wlf vsim.wlf -wlfcachesize 512

#add wave -r -radix hexadecimal sim:/tb_top/*

############################ WAVE ############################
configure wave -namecolwidth 300

# TOP
add wave -group top_tb /tb_top/mco
add wave -group top_tb /tb_top/res_n
add wave -group top_tb /tb_top/w_lcd_clk
add wave -group top_tb /tb_top/w_lcd_hsync
add wave -group top_tb /tb_top/w_lcd_vsync
add wave -group top_tb /tb_top/w_lcd_de
add wave -group top_tb -radix hexadecimal /tb_top/w_lcd_data
add wave -group top_tb /tb_top/w_snes_clk
add wave -group top_tb /tb_top/w_snes_latch
add wave -group top_tb /tb_top/w_snes_data
# TETRIS
add wave -group tetris -radix hexadecimal /tb_top/dut/tetris_inst/i_vram_addr
add wave -group tetris -radix hexadecimal /tb_top/dut/tetris_inst/o_block_data
add wave -group tetris -radix hexadecimal /tb_top/dut/tetris_inst/i_pos_x
add wave -group tetris -radix hexadecimal /tb_top/dut/tetris_inst/i_pos_y
add wave -group tetris -radix hexadecimal /tb_top/dut/tetris_inst/w_block_data_ram
##############################################################

#run -all
run 40ms
WaveRestoreZoom {0 ns} {40 ms}