`timescale 1ns / 100ps

module tb_top ();
    parameter MCO_HZ = 24000000;

	reg		mco = 1'b0;
    reg		res_n = 1'b1;
	
	// LCD
	wire	w_lcd_clk;
	wire	w_lcd_hsync;
	wire	w_lcd_vsync;
	wire	w_lcd_de;
	wire	[15:0]	w_lcd_data;

    // SNES
    wire    w_snes_clk;
    wire    w_snes_latch;
    wire    w_snes_data = 1'b1;
	
	// Tetris
	wire	[8:0]	w_vram_addr;
	wire	[4:0]	w_pos_x;
	wire	[4:0]	w_pos_y;

    // Clock
    always #(500000000 / MCO_HZ) mco <= ~mco;

    // Reset
    initial begin
        res_n = 1'b1;
        #1000;
        res_n = 1'b0;
        #1000;
        res_n = 1'b1;
    end

    // DUT
    tetris_top dut (
        .mco ( mco ),       // 24MHz

        .res_n ( res_n ),
        .btn_b ( 1'b1 ),    // 未使用
        
        .lcd_clk ( w_lcd_clk ),
        .lcd_hsync ( w_lcd_hsync ),
        .lcd_vsync ( w_lcd_vsync ),
        .lcd_de ( w_lcd_de ),
        .lcd_data ( w_lcd_data ),

        .SNES_CLK ( w_snes_clk ),
        .SNES_LATCH ( w_snes_latch ),
        .SNES_DATA ( w_snes_data )
    );

endmodule
