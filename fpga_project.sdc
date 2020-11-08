//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2.02 Beta
//Created Time: 2020-09-04 22:24:03
#**************************************************************
# Time Information
#**************************************************************



#**************************************************************
# Create Clock
#**************************************************************
create_clock -name mco -period 41.667 -waveform {0.000 20.834} [get_ports {mco}]
create_generated_clock -name clk9m -source [get_ports {mco}] -master_clock mco -divide_by 8 -multiply_by 3 [get_nets {clkout}]


#**************************************************************
# Set Input Delay
#**************************************************************


#**************************************************************
# Set Output Delay
#**************************************************************
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_clk}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_clk}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_hsync}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_hsync}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_vsync}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_vsync}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_de}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_de}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[0]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[0]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[1]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[1]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[2]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[2]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[3]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[3]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[4]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[4]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[5]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[5]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[6]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[6]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[7]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[7]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[8]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[8]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[9]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[9]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[10]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[10]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[11]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[11]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[12]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[12]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[13]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[13]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[14]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[14]}]
set_output_delay -add_delay -max -clock [get_clocks {clk9m}]  3.000 [get_ports {lcd_data[15]}]
set_output_delay -add_delay -min -clock [get_clocks {clk9m}]  0.000 [get_ports {lcd_data[15]}]


#**************************************************************
# Set Clock Groups
#**************************************************************


#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_ports {res_n}]
set_false_path -from [get_ports {btn_b}]
set_false_path -to [get_ports {SOUND_OUT}]
