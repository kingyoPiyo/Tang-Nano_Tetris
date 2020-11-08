/********************************************************
* Title    : LCD Controller
* Date     : 2020/09/04
* Design   : kingyo
********************************************************/
module LCD_Controller (
    input   wire            i_clk,
    input   wire            i_res_n,
    output  wire            o_clk,
    output  reg             o_hsync,
    output  reg             o_vsync,
    output  reg             o_de,
    output  reg     [15:0]  o_lcd_data,

    // To tetris_block
    output  wire    [8:0]   o_block_addr,
    input   wire    [3:0]   i_block_data,
    output  wire    [4:0]   o_pos_x,
    output  wire    [4:0]   o_pos_y,
    input   wire            i_line_remove_pls,  // 1ライン消す毎にパルスが入る
    input   wire            i_game_reset_pls    // コントローラ操作によるゲームリセット
    );

    //==================================================================
    //  LCDパラメータ (ATM0430D25)
    //==================================================================
    localparam DispHPeriodTime  = 531;
    localparam DispWidth        = 480;
    localparam DispHBackPorch   = 43;
    localparam DispHFrontPorch  = 8;
    localparam DispHPulseWidth  = 1;

    localparam DispVPeriodTime  = 288;
    localparam DispHeight       = 272;
    localparam DispVBackPorch   = 12;
    localparam DispVFrontPorch  = 4;
    localparam DispVPulseWidth  = 10;
    

    //==================================================================
    // 水平・垂直カウンタ
    //==================================================================
    reg [ 9:0]  r_hPeriodCnt;
    reg [ 8:0]  r_vPeriodCnt;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_hPeriodCnt[9:0] <= 10'd0;
            r_vPeriodCnt[8:0] <= 9'd0;
        end else begin
            // 水平カウンタ
            if (r_hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                r_hPeriodCnt[9:0] <= 10'd0;
            end else begin
                r_hPeriodCnt[9:0] <= r_hPeriodCnt[9:0] + 10'd1;
            end

            // 垂直カウンタ
            if (r_hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                if (r_vPeriodCnt[8:0] == (DispVPeriodTime - 9'd1)) begin
                    r_vPeriodCnt[8:0] <= 9'd0;
                end else begin
                    r_vPeriodCnt[8:0] <= r_vPeriodCnt[8:0] + 9'd1;
                end
            end
        end
    end

    //==================================================================
    // 書き込み領域判定
    //==================================================================
    reg         r_hInVisibleArea;
    reg         r_vInVisibleArea;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_hInVisibleArea <= 1'd0;
            r_vInVisibleArea <= 1'd0;
        end else begin
            // 書き込み領域判定
            r_hInVisibleArea <= (r_hPeriodCnt[9:0] == DispHBackPorch)  ? 1'b1 :
                                (r_hPeriodCnt[9:0] == DispHBackPorch + DispWidth) ? 1'b0 : r_hInVisibleArea;
            r_vInVisibleArea <= (r_vPeriodCnt[8:0] == DispVBackPorch)  ? 1'b1 :
                                (r_vPeriodCnt[8:0] == DispVBackPorch + DispHeight) ? 1'b0 : r_vInVisibleArea;
        end
    end

    //==================================================================
    //  VRAMアドレス生成
    //==================================================================
    // 表示領域
    wire    w_field_area = (r_hPeriodCnt[9:0] >= 10'd101) && (r_hPeriodCnt[9:0] <= 10'd220) &&
                           (r_vPeriodCnt[8:0] >= 9'd40) && (r_vPeriodCnt[8:0] <= 9'd259);
    wire    w_field_area_delay = (r_hPeriodCnt[9:0] >= 10'd102) && (r_hPeriodCnt[9:0] <= 10'd221) &&
                           (r_vPeriodCnt[8:0] >= 9'd40) && (r_vPeriodCnt[8:0] <= 9'd259);
    reg     [4:0]   r_xcnt;
    reg     [4:0]   r_ycnt;
    reg     [3:0]   r_prcnt0;
    reg     [3:0]   r_prcnt1;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_xcnt <= 5'd0;
            r_ycnt <= 5'd0;
            r_prcnt0 <= 4'd0;
            r_prcnt1 <= 4'd0;
        end else begin
            // 垂直カウンタが一周するタイミングでアドレスリセット
            if (r_vPeriodCnt[8:0] == 9'd0) begin
                r_xcnt <= 5'd0;
                r_ycnt <= 5'd0;
                r_prcnt0 <= 4'd0;
                r_prcnt1 <= 4'd0;
            end
            if (w_field_area) begin
                // 10pixel毎に1++
                if (r_prcnt0 == 4'd9) begin
                    r_prcnt0 <= 4'd0;
                    if (r_xcnt == 5'd11) begin
                        r_xcnt <= 5'd0;
                        if (r_prcnt1 == 4'd9) begin
                            r_prcnt1 <= 4'd0;
                            r_ycnt <= r_ycnt + 5'd1;
                        end else begin
                            r_prcnt1 <= r_prcnt1 + 4'd1;
                        end
                    end else begin
                        r_xcnt <= r_xcnt + 5'd1;
                    end
               end else begin
                   r_prcnt0 <= r_prcnt0 + 4'd1;
               end
            end

        end
    end

    // RAMレイテンシ分遅延
    reg     [3:0]   r_prcnt0_dly;
    reg     [3:0]   r_prcnt1_dly;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_prcnt0_dly <= 4'd0;
            r_prcnt1_dly <= 4'd0;
        end else begin
            r_prcnt0_dly <= r_prcnt0;
            r_prcnt1_dly <= r_prcnt1;
        end
    end

    // VRAMアドレス計算
    assign o_block_addr[8:0] = (r_ycnt[4:0] * 9'd12) + r_xcnt[4:0];
    assign o_pos_x = r_xcnt;
    assign o_pos_y = r_ycnt;

    //==================================================================
    //  ブロック着色
    //==================================================================
    wire    [15:0]  w_block_color_hi =  i_block_data == 4'd0 ? 16'b00000_000000_00000 :
                                        i_block_data == 4'd1 ? 16'b10111_101111_10111 :
                                        i_block_data == 4'd2 ? 16'b00000_111111_11111 :
                                        i_block_data == 4'd3 ? 16'b11111_111111_00000 :
                                        i_block_data == 4'd4 ? 16'b10010_110100_01010 :
                                        i_block_data == 4'd5 ? 16'b11111_000000_00000 :
                                        i_block_data == 4'd6 ? 16'b00000_011100_11000 :
                                        i_block_data == 4'd7 ? 16'b11111_110000_00000 :
                                        i_block_data == 4'd8 ? 16'b11111_011001_11001 :
                                        16'h0000;
    wire    [15:0]  w_block_color_mid = i_block_data == 4'd0 ? 16'b00000_000000_00000 :
                                        i_block_data == 4'd1 ? 16'b01011_010111_01011 :
                                        i_block_data == 4'd2 ? 16'b00000_011111_01111 :
                                        i_block_data == 4'd3 ? 16'b01111_011111_00000 :
                                        i_block_data == 4'd4 ? 16'b01001_011010_00101 :
                                        i_block_data == 4'd5 ? 16'b01111_000000_00000 :
                                        i_block_data == 4'd6 ? 16'b00000_001110_01100 :
                                        i_block_data == 4'd7 ? 16'b01111_011000_00000 :
                                        i_block_data == 4'd8 ? 16'b01111_001100_01100 :
                                        16'h0000;
    wire    [15:0]  w_block_color_low = i_block_data == 4'd0 ? 16'b00000_000000_00000 :
                                        i_block_data == 4'd1 ? 16'b00101_001011_00101 :
                                        i_block_data == 4'd2 ? 16'b00000_001111_00111 :
                                        i_block_data == 4'd3 ? 16'b00111_001111_00000 :
                                        i_block_data == 4'd4 ? 16'b00100_001101_00010 :
                                        i_block_data == 4'd5 ? 16'b00111_000000_00000 :
                                        i_block_data == 4'd6 ? 16'b00000_000111_00110 :
                                        i_block_data == 4'd7 ? 16'b00111_001100_00000 :
                                        i_block_data == 4'd8 ? 16'b00111_000110_00110 :
                                        16'h0000;
    // 輝度設定（影追加）
    wire    [1:0]   w_block_brightness = (r_prcnt0_dly <= 4'd8 && r_prcnt1_dly <= 4'd1) || 
                                         (r_prcnt0_dly <= 4'd1 && r_prcnt1_dly <= 4'd8) ||
                                         (r_prcnt0_dly == 4'd9 && r_prcnt1_dly == 4'd0) ||
                                         (r_prcnt0_dly == 4'd0 && r_prcnt1_dly == 4'd9) ? 2'd0 :
                                         (r_prcnt0_dly >= 4'd2 && r_prcnt0_dly <= 4'd7) &&
                                         (r_prcnt1_dly >= 4'd2 && r_prcnt1_dly <= 4'd7) ? 2'd1 : 2'd2;
    wire    [15:0]  w_block_color = w_block_brightness == 2'd0 ? w_block_color_hi :
                                    w_block_brightness == 2'd1 ? w_block_color_mid : w_block_color_low;


    //==================================================================
    //  LINE数表示
    //==================================================================                              
    // LINE数カウンタ(BCD)
    reg     [3:0]   r_line_cnt_0001;    // 1の位
    reg     [3:0]   r_line_cnt_0010;    // 10の位
    reg     [3:0]   r_line_cnt_0100;    // 100の位
    reg     [3:0]   r_line_cnt_1000;    // 1000の位
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_line_cnt_0001 <= 4'd0;
            r_line_cnt_0010 <= 4'd0;
            r_line_cnt_0100 <= 4'd0;
            r_line_cnt_1000 <= 4'd0;
        end else begin
            if (i_game_reset_pls) begin
                r_line_cnt_0001 <= 4'd0;
                r_line_cnt_0010 <= 4'd0;
                r_line_cnt_0100 <= 4'd0;
                r_line_cnt_1000 <= 4'd0;
            end else if (i_line_remove_pls) begin
                if (r_line_cnt_0001 != 4'd9) begin
                    r_line_cnt_0001 <= r_line_cnt_0001 + 4'd1;
                end else begin
                    r_line_cnt_0001 <= 4'd0;
                    if (r_line_cnt_0010 != 4'd9) begin
                        r_line_cnt_0010 <= r_line_cnt_0010 + 4'd1;
                    end else begin
                        r_line_cnt_0010 <= 4'd0;
                        if (r_line_cnt_0100 != 4'd9) begin
                            r_line_cnt_0100 <= r_line_cnt_0100 + 4'd1;
                        end else begin
                            r_line_cnt_0100 <= 4'd0;
                            if (r_line_cnt_1000 != 4'd9) begin
                                r_line_cnt_1000 <= r_line_cnt_1000 + 4'd1;
                            end else begin
                                r_line_cnt_1000 <= 4'd0;
                            end
                        end
                    end
                end
            end
        end
    end

    // キャラクタROM Readアドレス生成
    wire    [9:0]   w_hPeriodCnt2 = r_hPeriodCnt + 10'd1;   // ROMレイテンシ考慮して先読み
    wire    [5:0]   w_char_font = w_hPeriodCnt2[9:4] == 6'd15 ? 6'd21 : // L
                                  w_hPeriodCnt2[9:4] == 6'd16 ? 6'd18 : // I
                                  w_hPeriodCnt2[9:4] == 6'd17 ? 6'd23 : // N
                                  w_hPeriodCnt2[9:4] == 6'd18 ? 6'd14 : // E
                                  w_hPeriodCnt2[9:4] == 6'd19 ? 6'd41 : // :
                                  w_hPeriodCnt2[9:4] == 6'd20 ? r_line_cnt_1000 :
                                  w_hPeriodCnt2[9:4] == 6'd21 ? r_line_cnt_0100 :
                                  w_hPeriodCnt2[9:4] == 6'd22 ? r_line_cnt_0010 :
                                  r_line_cnt_0001;

    // キャラクタROM
    wire    [63:0]  w_char_data;
    char_rom char_rom (
        .i_clk ( i_clk ),
        .i_res_n ( i_res_n ),
        .i_addr ( w_char_font[5:0] ),
        .o_data ( w_char_data[63:0] )
    );

    // 文字列表示領域
    wire w_char_en = (r_vPeriodCnt[8:4] == 5'd3  &&
                      r_hPeriodCnt[9:4] >= 6'd15 && r_hPeriodCnt[9:4] <= 6'd23);
    

    //==================================================================
    // LCD出力データ合成
    //==================================================================    
    wire    [15:0]  w_char_lcd = ~w_char_en ? 16'h0000 : 
                                 w_char_data[{(3'd7 - r_vPeriodCnt[3:1]), (3'd7 - r_hPeriodCnt[3:1])}] ? 16'hFFFF :
                                 16'h0000;
    wire    [15:0]  w_lcd_data = w_field_area_delay ? w_block_color : w_char_lcd;


    //==================================================================
    // 出力レジスタ
    //==================================================================
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            o_hsync     <= 1'b1;
            o_vsync     <= 1'b1;
            o_de        <= 1'b0;
            o_lcd_data  <= 16'd0;
        end else begin
            o_hsync     <= (r_hPeriodCnt[9:0] < DispHPulseWidth) ? 1'b0 : 1'b1;   // HSYNC信号生成
            o_vsync     <= (r_vPeriodCnt[8:0] < DispVPulseWidth) ? 1'b0 : 1'b1;   // VSYNC信号生成
            o_de        <= r_hInVisibleArea & r_vInVisibleArea;
            o_lcd_data  <= w_lcd_data;
        end
    end
    assign o_clk = i_clk;

endmodule
