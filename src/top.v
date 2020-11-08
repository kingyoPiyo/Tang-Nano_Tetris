/********************************************************
* Title    : Tang-Nano Tetris
* Date     : 2020/09/04
* Design   : kingyo
********************************************************/
module tetris_top (
    // CLK
    input   wire            mco,    // 24MHz

    // Button
    input   wire            res_n,
    input   wire            btn_b,  // 未使用
    
    // LCD
    output  wire            lcd_clk,
    output  wire            lcd_hsync,
    output  wire            lcd_vsync,
    output  wire            lcd_de,
    output  wire    [15:0]  lcd_data,

    // SNES Controller
    output wire             SNES_CLK,
    output wire             SNES_LATCH,
    input  wire             SNES_DATA,

    // Sound output
    output wire             SOUND_OUT
    );

    //==================================================================
    // Wires
    //==================================================================
    wire            clk9m;
    wire    [3:0]   block_data;         // DPRAM Data
    wire    [8:0]   block_addr;         // DPRAM Readアドレス
    wire    [4:0]   w_pos_x;            // 現在のスキャンX座標（ブロック単位）
    wire    [4:0]   w_pos_y;            // 現在のスキャンY座標（ブロック単位）
    wire    [14:0]  w_snes_state;       // SNESコントローラキー状態
    wire            w_snes_state_en;    // SNESコントローラ値取得完了
    wire            w_line_remove_pls;  // 1ライン消去通知パルス
    wire            w_game_reset_pls;   // コントローラ操作によるゲームリセットパルス
    wire            w_blockFixed_se_pls;// ブロック固定時の効果音再生パルス

    //==================================================================
    // PLL
    //==================================================================
    Gowin_PLL pll (
        .clkin ( mco ),     // Input clock 24MHz
        .clkout ( clk9m )   // Output clock 9MHz
    );

    //==================================================================
    // SNES Controller I/F
    //==================================================================
    snes_if snes_if_inst (
        .i_clk ( clk9m ),
        .i_rst_n ( res_n ),
        .o_btn_state ( w_snes_state ),
        .o_btn_state_en ( w_snes_state_en ),
        .o_snes_clk ( SNES_CLK ),
        .o_snes_latch ( SNES_LATCH ),
        .i_snes_data ( SNES_DATA )
    );

    //==================================================================
    // Tetris core
    //==================================================================
    tetris tetris_inst (
        .i_clk ( clk9m ),
        .i_res_n ( res_n ),
        .i_vram_addr ( block_addr ),
        .o_block_data ( block_data ),
        .i_pos_x ( w_pos_x ),
        .i_pos_y ( w_pos_y ),
        .i_snes_state ( w_snes_state ),
        .i_snes_state_en ( w_snes_state_en ),
        .o_line_remove_pls ( w_line_remove_pls ),
        .o_game_reset_pls ( w_game_reset_pls ),
        .o_bgm_fixed_pls ( w_blockFixed_se_pls )
    );

    //==================================================================
    // LCD Controller
    //==================================================================
    LCD_Controller LCD_Controller_inst (
        .i_clk ( clk9m ),
        .i_res_n ( res_n ),
        .o_clk ( lcd_clk ),
        .o_hsync ( lcd_hsync ),
        .o_vsync ( lcd_vsync ),
        .o_de ( lcd_de ),
        .o_lcd_data ( lcd_data ),

        // To Tetris Block
        .o_block_addr ( block_addr ),
        .i_block_data ( block_data ),
        .o_pos_x ( w_pos_x ),
        .o_pos_y ( w_pos_y ),
        .i_line_remove_pls ( w_line_remove_pls ),
        .i_game_reset_pls ( w_game_reset_pls )
    );

    //==================================================================
    // Sound Generator
    //==================================================================
    soundGen soundGen_inst (
        .i_clk ( clk9m ),
        .i_res_n ( res_n ),
        .i_fixed_pls ( w_blockFixed_se_pls ),
        .o_sound ( SOUND_OUT )
    );

endmodule
