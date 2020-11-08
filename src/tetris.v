/********************************************************
* Title    : Tetris
* Date     : 2020/09/05
* Design   : kingyo
********************************************************/
module tetris (
    input   wire            i_clk,
    input   wire            i_res_n,

    // To LCD Controller
    input   wire    [8:0]   i_vram_addr,
    output  wire    [3:0]   o_block_data,
    input   wire    [4:0]   i_pos_x,
    input   wire    [4:0]   i_pos_y,
    output  wire            o_line_remove_pls,
    output  wire            o_game_reset_pls,

    // SNES Controller
    input   wire    [14:0]  i_snes_state,
    input   wire            i_snes_state_en,

    // To BGM
    output  wire            o_bgm_fixed_pls
);
    // テトリミノ初期出現条件
    parameter   INIT_POS_X = 4'd6;
    parameter   INIT_POS_Y = 5'd1;
    parameter   INIT_ANGLE = 3'd0;

    // wires
    wire    [8:0]   w_addr_a;
    wire    [3:0]   w_idata_a;
    wire    [3:0]   w_odata_a;
    wire            w_wen_a;
    wire    [3:0]   w_block_code_ram;

    // Register
    reg     [3:0]   r_block_ptn;        // 0:黒, 1:壁, 2:I, 3:O, 4:S, 5:Z, 6:J, 7:L, 8:T
    reg     [1:0]   r_block_angle;      // 0~3
    reg     [3:0]   r_block_pos_x;      // 左上が0(壁含む)
    reg     [4:0]   r_block_pos_y;      // 左上が0(壁含む)
    reg             r_block_fix_req;    // テトリミノを背景に固定する要求
    reg             r_block_fix_done;   // 固定完了
    reg             r_gameover_state;   // ゲームオーバー状態
    reg     [3:0]   r_block_code;
    reg     [8:0]   r_vram_addr;        
    reg             r_wen;
    reg             r_block_fix_busy_old;
    reg     [8:0]   r_vram_addr_ff;
    reg     [8:0]   r_vram_addr_ff2;
    reg             r_blocken_sel_ff_n;
    reg             r_gameover_trig;

    //==================================================================
    // テトリミノ定義
    // i_pos_x/y       : LCDスキャン位置
    // r_block_pos_x/y : テトリミノの現在位置
    //==================================================================
    // I
    wire    w_blocken_I_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 2 && i_pos_y == r_block_pos_y    );
    wire    w_blocken_I_2 = (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 2);
    wire    w_blocken_I_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 2 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_I_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 2);
    // 現角度
    wire    w_blocken_I_n = (r_block_angle == 2'd0) ? w_blocken_I_1 :
                            (r_block_angle == 2'd1) ? w_blocken_I_2 :
                            (r_block_angle == 2'd2) ? w_blocken_I_3 : w_blocken_I_4;
    // 右回転
    wire    w_blocken_I_r = (r_block_angle == 2'd3) ? w_blocken_I_1 :
                            (r_block_angle == 2'd0) ? w_blocken_I_2 :
                            (r_block_angle == 2'd1) ? w_blocken_I_3 : w_blocken_I_4;
    // 左回転
    wire    w_blocken_I_l = (r_block_angle == 2'd1) ? w_blocken_I_1 :
                            (r_block_angle == 2'd2) ? w_blocken_I_2 :
                            (r_block_angle == 2'd3) ? w_blocken_I_3 : w_blocken_I_4;
    // O
    wire    w_blocken_O =   (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y - 1);
    // S
    wire    w_blocken_S_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y - 1);
    wire    w_blocken_S_2 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_S_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_S_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_S_n = (r_block_angle == 2'd0) ? w_blocken_S_1 :
                            (r_block_angle == 2'd1) ? w_blocken_S_2 :
                            (r_block_angle == 2'd2) ? w_blocken_S_3 : w_blocken_S_4;
    wire    w_blocken_S_r = (r_block_angle == 2'd3) ? w_blocken_S_1 :
                            (r_block_angle == 2'd0) ? w_blocken_S_2 :
                            (r_block_angle == 2'd1) ? w_blocken_S_3 : w_blocken_S_4;
    wire    w_blocken_S_l = (r_block_angle == 2'd1) ? w_blocken_S_1 :
                            (r_block_angle == 2'd2) ? w_blocken_S_2 :
                            (r_block_angle == 2'd3) ? w_blocken_S_3 : w_blocken_S_4;
    // Z
    wire    w_blocken_Z_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    );
    wire    w_blocken_Z_2 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_Z_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_Z_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_Z_n = (r_block_angle == 2'd0) ? w_blocken_Z_1 :
                            (r_block_angle == 2'd1) ? w_blocken_Z_2 :
                            (r_block_angle == 2'd2) ? w_blocken_Z_3 : w_blocken_Z_4;
    wire    w_blocken_Z_r = (r_block_angle == 2'd3) ? w_blocken_Z_1 :
                            (r_block_angle == 2'd0) ? w_blocken_Z_2 :
                            (r_block_angle == 2'd1) ? w_blocken_Z_3 : w_blocken_Z_4;
    wire    w_blocken_Z_l = (r_block_angle == 2'd1) ? w_blocken_Z_1 :
                            (r_block_angle == 2'd2) ? w_blocken_Z_2 :
                            (r_block_angle == 2'd3) ? w_blocken_Z_3 : w_blocken_Z_4;
    // J
    wire    w_blocken_J_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    );
    wire    w_blocken_J_2 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_J_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_J_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_J_n = (r_block_angle == 2'd0) ? w_blocken_J_1 :
                            (r_block_angle == 2'd1) ? w_blocken_J_2 :
                            (r_block_angle == 2'd2) ? w_blocken_J_3 : w_blocken_J_4;
    wire    w_blocken_J_r = (r_block_angle == 2'd3) ? w_blocken_J_1 :
                            (r_block_angle == 2'd0) ? w_blocken_J_2 :
                            (r_block_angle == 2'd1) ? w_blocken_J_3 : w_blocken_J_4;
    wire    w_blocken_J_l = (r_block_angle == 2'd1) ? w_blocken_J_1 :
                            (r_block_angle == 2'd2) ? w_blocken_J_2 :
                            (r_block_angle == 2'd3) ? w_blocken_J_3 : w_blocken_J_4;
    // L
    wire    w_blocken_L_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    );
    wire    w_blocken_L_2 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_L_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y + 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    );
    wire    w_blocken_L_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_L_n = (r_block_angle == 2'd0) ? w_blocken_L_1 :
                            (r_block_angle == 2'd1) ? w_blocken_L_2 :
                            (r_block_angle == 2'd2) ? w_blocken_L_3 : w_blocken_L_4;
    wire    w_blocken_L_r = (r_block_angle == 2'd3) ? w_blocken_L_1 :
                            (r_block_angle == 2'd0) ? w_blocken_L_2 :
                            (r_block_angle == 2'd1) ? w_blocken_L_3 : w_blocken_L_4;
    wire    w_blocken_L_l = (r_block_angle == 2'd1) ? w_blocken_L_1 :
                            (r_block_angle == 2'd2) ? w_blocken_L_2 :
                            (r_block_angle == 2'd3) ? w_blocken_L_3 : w_blocken_L_4;
    // T
    wire    w_blocken_T_1 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1);
    wire    w_blocken_T_2 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_T_3 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x + 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_T_4 = (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x - 1 && i_pos_y == r_block_pos_y    ) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y - 1) ||
                            (i_pos_x == r_block_pos_x     && i_pos_y == r_block_pos_y + 1);
    wire    w_blocken_T_n = (r_block_angle == 2'd0) ? w_blocken_T_1 :
                            (r_block_angle == 2'd1) ? w_blocken_T_2 :
                            (r_block_angle == 2'd2) ? w_blocken_T_3 : w_blocken_T_4;
    wire    w_blocken_T_r = (r_block_angle == 2'd3) ? w_blocken_T_1 :
                            (r_block_angle == 2'd0) ? w_blocken_T_2 :
                            (r_block_angle == 2'd1) ? w_blocken_T_3 : w_blocken_T_4;
    wire    w_blocken_T_l = (r_block_angle == 2'd1) ? w_blocken_T_1 :
                            (r_block_angle == 2'd2) ? w_blocken_T_2 :
                            (r_block_angle == 2'd3) ? w_blocken_T_3 : w_blocken_T_4;

    // 種別選択（現在の回転角）
    wire    w_blocken_sel_n = (r_block_ptn == 4'd2) ? w_blocken_I_n :
                            (r_block_ptn == 4'd3) ? w_blocken_O :
                            (r_block_ptn == 4'd4) ? w_blocken_S_n :
                            (r_block_ptn == 4'd5) ? w_blocken_Z_n :
                            (r_block_ptn == 4'd6) ? w_blocken_J_n :
                            (r_block_ptn == 4'd7) ? w_blocken_L_n : w_blocken_T_n;
    // 種別選択（右回転後）
    wire    w_blocken_sel_r = (r_block_ptn == 4'd2) ? w_blocken_I_r :
                            (r_block_ptn == 4'd3) ? w_blocken_O :
                            (r_block_ptn == 4'd4) ? w_blocken_S_r :
                            (r_block_ptn == 4'd5) ? w_blocken_Z_r :
                            (r_block_ptn == 4'd6) ? w_blocken_J_r :
                            (r_block_ptn == 4'd7) ? w_blocken_L_r : w_blocken_T_r;
    // 種別選択（左回転後）
    wire    w_blocken_sel_l = (r_block_ptn == 4'd2) ? w_blocken_I_l :
                            (r_block_ptn == 4'd3) ? w_blocken_O :
                            (r_block_ptn == 4'd4) ? w_blocken_S_l :
                            (r_block_ptn == 4'd5) ? w_blocken_Z_l :
                            (r_block_ptn == 4'd6) ? w_blocken_J_l :
                            (r_block_ptn == 4'd7) ? w_blocken_L_l : w_blocken_T_l;

    //==================================================================
    // UI更新周期生成
    // 最速でも10回/secくらいにしておく
    // ボタン状態に変化があったときには即時更新パルスを出す
    //==================================================================
    reg [23:0]  r_uiupdate_cnt;
    reg [14:0]  r_old_btnstate; // ボタンの前回状態
    wire        w_uiupdate = (r_uiupdate_cnt == 24'd900000) | (r_old_btnstate != i_snes_state);
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_uiupdate_cnt <= 24'd0;
        end else begin
            r_old_btnstate <= i_snes_state;
            if (w_uiupdate) begin
                r_uiupdate_cnt <= 24'd0;
            end else begin
                r_uiupdate_cnt <= r_uiupdate_cnt + 24'd1;
            end
        end
    end

    //==================================================================
    // ゲームリセット処理（SELECTボタン）
    //==================================================================
    reg     r_game_reset_pls;
    reg     r_snes_btnstate_select_old;
    reg     r_freset_req;   // フィールド初期化要求
    reg     r_freset_done;  // フィールド初期化完了
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_game_reset_pls <= 1'b0;
            r_snes_btnstate_select_old <= 1'b0;
            r_freset_req <= 1'b0;
        end else begin
            r_snes_btnstate_select_old <= i_snes_state[12];
            r_game_reset_pls <= ~r_snes_btnstate_select_old & i_snes_state[12];

            // フィールド初期化要求
            if (r_freset_done) begin
                r_freset_req <= 1'b0;
            end else if (r_game_reset_pls) begin
                r_freset_req <= 1'b1;
            end
        end
    end
    assign  o_game_reset_pls = r_game_reset_pls;

    //==================================================================
    // フィールド初期化処理
    //==================================================================
    reg     [3:0]   r_fresetX;
    reg     [4:0]   r_fresetY;
    wire    [8:0]   w_freset_addr = ({4'd0, r_fresetY} * 9'd12) + {5'd0, r_fresetX};
    reg             r_freset_busy;
    wire    [3:0]   w_freset_data;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_freset_busy <= 1'b0;
            r_fresetX <= 4'd0;
            r_fresetY <= 5'd0;
        end else begin
            if (r_freset_req & ~r_freset_busy && i_vram_addr == 9'd0) begin
                r_freset_busy <= 1'b1;
                r_fresetX <= 4'd0;
                r_fresetY <= 5'd0;
            end else if (r_freset_busy) begin
                if (r_fresetX != 4'd11) begin
                    r_fresetX <= r_fresetX + 4'd1;
                end else begin
                    r_fresetX <= 4'd0;
                    r_fresetY <= r_fresetY + 5'd1;
                end
                if (w_freset_addr == 9'd264) begin
                    r_freset_busy <= 1'b0;
                    r_freset_done <= 1'b1;
                end
            end else begin
                r_freset_done <= 1'b0;
            end
        end
    end
    // 初期フィールドデータ生成
    assign w_freset_data[3:0] = (r_fresetY == 5'd21 || r_fresetX == 4'd0 || r_fresetX == 4'd11) ? 4'd1 :
                                (r_fresetY == 5'd0 && (r_fresetX == 4'd1 || r_fresetX == 4'd2 ||
                                 r_fresetX == 4'd9 || r_fresetX == 4'd10)) ? 4'd1 : 4'd0;

    //==================================================================
    // テトリミノ落下タイミング生成
    //==================================================================
    reg [23:0]  r_drop_cnt;
    wire        w_drop_pls = r_drop_cnt == 24'd5000000;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_drop_cnt <= 24'd0;
        end else begin
            if (w_drop_pls) begin
                r_drop_cnt <= 24'd0;
            end else begin
                r_drop_cnt <= r_drop_cnt + 24'd1;
            end
        end
    end

    //==================================================================
    // テトリミノ当たり判定
    //==================================================================
    /* 現角度 */
    reg         r_atari_r_n;    // 右側
    reg         r_atari_r_n_tmp;
    reg         r_atari_l_n;    // 左側
    reg         r_atari_l_n_tmp;
    reg         r_atari_d_n;    // 下側
    reg         r_atari_d_n_tmp;
    reg         r_atari_ld_n;   // 斜め左下側
    reg         r_atari_ld_n_tmp;
    reg         r_atari_rd_n;   // 斜め右下側
    reg         r_atari_rd_n_tmp;
    /* 右回転 */
    reg         r_atari_r_r;
    reg         r_atari_r_r_tmp;
    /* 左回転 */
    reg         r_atari_r_l;
    reg         r_atari_r_l_tmp;

    reg [3:0]   r_block_code_ram_ff1;
    reg [3:0]   r_block_code_ram_ff2;
    reg [12:0]  r_blocken_sel_ff2_n;

    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_atari_r_n <= 1'b0;
            r_atari_r_n_tmp <= 1'b0;
            r_atari_l_n <= 1'b0;
            r_atari_l_n_tmp <= 1'b0;
            r_atari_d_n <= 1'b0;
            r_atari_d_n_tmp <= 1'b0;
            r_atari_ld_n <= 1'b0;
            r_atari_ld_n_tmp <= 1'b0;
            r_atari_rd_n <= 1'b0;
            r_atari_rd_n_tmp <= 1'b0;
            r_atari_r_r <= 1'b0;
            r_atari_r_r_tmp <= 1'b0;
            r_atari_r_l <= 1'b0;
            r_atari_r_l_tmp <= 1'b0;
            r_blocken_sel_ff2_n <= 13'd0;
        end else begin
            r_vram_addr_ff[8:0] <= i_vram_addr[8:0];
            r_vram_addr_ff2[8:0] <= r_vram_addr_ff[8:0];
            r_blocken_sel_ff_n <= w_blocken_sel_n;

            if (i_vram_addr[8:0] == 9'd0 && r_vram_addr_ff[8:0] == 9'd264) begin
                r_atari_r_n_tmp <= 1'b0;
                r_atari_r_n <= r_atari_r_n_tmp;
                r_atari_l_n_tmp <= 1'b0;
                r_atari_l_n <= r_atari_l_n_tmp;
                r_atari_d_n_tmp <= 1'b0;
                r_atari_d_n <= r_atari_d_n_tmp;
                r_atari_ld_n_tmp <= 1'b0;
                r_atari_ld_n <= r_atari_ld_n_tmp;
                r_atari_rd_n_tmp <= 1'b0;
                r_atari_rd_n <= r_atari_rd_n_tmp;
                r_atari_r_r_tmp <= 1'b0;
                r_atari_r_r <= r_atari_r_r_tmp;
                r_atari_r_l_tmp <= 1'b0;
                r_atari_r_l <= r_atari_r_l_tmp;
            end else if (r_vram_addr_ff[8:0] != i_vram_addr[8:0]) begin 
                // ブロック幅(10pixel)単位でレジスタ更新
                r_blocken_sel_ff2_n[12:0] <= {r_blocken_sel_ff2_n[11:0], r_blocken_sel_ff_n};

                /****** 現角度 ******/
                // 右側検査
                if (r_blocken_sel_ff2_n[0] && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_r_n_tmp <= 1'b1;
                end
                // 左側検査
                if (w_blocken_sel_n && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_l_n_tmp <= 1'b1;
                end
                // 下側検査
                if (r_blocken_sel_ff2_n[11] && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_d_n_tmp <= 1'b1;
                end
                // 斜め左下側検査
                if (r_blocken_sel_ff2_n[10] && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_ld_n_tmp <= 1'b1;
                end
                // 斜め右下側検査
                if (r_blocken_sel_ff2_n[12] && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_rd_n_tmp <= 1'b1;
                end
            end else if (r_vram_addr_ff2[8:0] != r_vram_addr_ff) begin
                /* 回転後衝突判定は1cycle遅延必要 */
                /****** 右回転 ******/
                if (w_blocken_sel_r && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_r_r_tmp <= 1'b1;
                end
                /****** 左回転 ******/
                if (w_blocken_sel_l && w_block_code_ram[3:0] != 4'd0) begin
                    r_atari_r_l_tmp <= 1'b1;
                end
            end
        end
    end

    //==================================================================
    // 1ライン揃ったら消す処理
    // 処理は描画領域外（フィールド下）で行う
    //==================================================================
    reg     [3:0]   r_vram_addr_lineRemoveX;     // X座標
    reg     [4:0]   r_vram_addr_lineRemoveY;     // Y座標
    wire    [8:0]   w_vram_addr_lineRemove = ({4'd0, r_vram_addr_lineRemoveY} * 9'd12) + {5'd0, r_vram_addr_lineRemoveX};
    reg             r_lineRemoveBusy;           // 処理中フラグ
    reg     [3:0]   r_lineRemoveCnt;            // 1ラインのブロック数カウント(0~9, 9で揃ったことになる)
    reg             r_ramlat;                   // RAMレイテンシ制御用
    reg             r_wreb;                     // RAM(PortB)書き込み制御
    reg             r_wreb_old;
    reg             r_line_remove_pls;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_vram_addr_lineRemoveX <= 4'd10;
            r_vram_addr_lineRemoveY <= 5'd20;
            r_lineRemoveBusy <= 1'b0;
            r_lineRemoveCnt <= 4'd0;
            r_wreb <= 1'b0;
            r_wreb_old <= 1'b0;
            r_line_remove_pls <= 1'b0;
        end else begin
            // 1ライン消去処理実行結果をLCD_Controllerへ通知
            r_wreb_old <= r_wreb;
            r_line_remove_pls <= ~r_wreb & r_wreb_old & ~r_freset_busy;

            // フィールド外で処理実行
            if (i_vram_addr == 9'd264 & ~r_lineRemoveBusy) begin
                r_lineRemoveBusy <= 1'b1;
                r_vram_addr_lineRemoveX <= 4'd10;
                r_vram_addr_lineRemoveY <= 5'd20;
                r_lineRemoveCnt <= 4'd0;
                r_ramlat <= 1'b0;
                r_wreb <= 1'b0;
            end else if (r_lineRemoveBusy) begin
                r_ramlat <= ~r_ramlat;
                if (~r_ramlat) begin
                    // アドレス制御
                    if (r_vram_addr_lineRemoveX != 4'd0) begin
                        r_vram_addr_lineRemoveX <= r_vram_addr_lineRemoveX - 4'd1;
                    end else begin
                        r_vram_addr_lineRemoveX <= 4'd10;
                        r_vram_addr_lineRemoveY <= r_vram_addr_lineRemoveY - 5'd1;
                    end
                    if (w_vram_addr_lineRemove == 9'd12) begin
                        // 1ライン消去処理完了
                        r_lineRemoveBusy <= 1'b0;
                        r_wreb <= 1'b0;
                    end
                end else begin
                    if (r_vram_addr_lineRemoveX == 4'd10) begin
                        r_lineRemoveCnt <= 4'd0;
                    end else if (w_odata_a[3:0] != 0) begin
                        r_lineRemoveCnt <= r_lineRemoveCnt + 4'd1;
                        if (r_lineRemoveCnt == 4'd9) begin
                            r_wreb <= 1'b1; // 1ライン揃ったのでRAM(PortB)データシフト
                        end
                    end
                end
            end
        end
    end
    assign  o_line_remove_pls = r_line_remove_pls;


    //==================================================================
    // ブロック生成用乱数カウンタ
    //==================================================================
    reg [31:0]  r_lfsr;
    reg [ 3:0]  r_nextBlockPtn;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_nextBlockPtn <= 4'd2;
        end else begin
            if (r_nextBlockPtn == 4'd8) begin
                r_nextBlockPtn <= 4'd2;
            end else begin
                r_nextBlockPtn <= r_nextBlockPtn + 4'd1;
            end
        end
    end

    //==================================================================
    // ボタン入力に応じた処理
    //==================================================================
    reg r_drop_req;
    reg r_drop_done;
    reg r_block_fix_busy;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_block_ptn <= 3'd2;    // ブロック種類：I
            r_block_pos_x <= INIT_POS_X;  // 出現位置
            r_block_pos_y <= INIT_POS_Y;  // 出現位置
            r_block_angle <= INIT_ANGLE;  // 回転角
            r_block_fix_req <= 1'b0;// 固定要求なし
            r_drop_req <= 1'b0;
            r_drop_done <= 1'b0;
        end else if (~r_gameover_state) begin
            // 落下要求
            if (w_drop_pls) begin
                r_drop_req <= 1'b1;
            end else if (r_drop_done) begin
                r_drop_req <= 1'b0;
            end

            // ブロックの固定を検出して新しいブロックを生成する
            r_block_fix_busy_old <= r_block_fix_busy;
            if (~r_block_fix_busy & r_block_fix_busy_old & ~r_gameover_trig) begin
                r_block_pos_x <= INIT_POS_X;    // 出現位置
                r_block_pos_y <= INIT_POS_Y;    // 出現位置
                r_block_angle <= INIT_ANGLE;    // 角度
                r_block_ptn <= r_nextBlockPtn;  // 種類
            end else if (w_uiupdate & ~r_block_fix_busy) begin
                if (r_drop_req) begin
                    r_drop_done <= 1'b1;
                end

                // 回転(長押し無効)
                if (i_snes_state[ 6] & ~r_old_btnstate[ 6] & ~r_atari_r_r) begin
                    // 右回転
                    r_block_angle <= r_block_angle + 2'd1;
                end else if (i_snes_state[14] & ~r_old_btnstate[14] & ~r_atari_r_l) begin
                    // 左回転
                    r_block_angle <= r_block_angle - 2'd1;
                end else begin

                    // 落下
                    if (r_drop_req | i_snes_state[ 9]) begin
                        if (i_snes_state[ 8] & ~r_atari_ld_n) begin
                            // 左下
                            r_block_pos_x <= r_block_pos_x - 4'd1;
                            r_block_pos_y <= r_block_pos_y + 5'd1;
                        end else if (i_snes_state[ 7] & ~r_atari_rd_n) begin
                            // 右下
                            r_block_pos_x <= r_block_pos_x + 4'd1;
                            r_block_pos_y <= r_block_pos_y + 5'd1;
                        end else if (~r_atari_d_n) begin
                            // 下
                            r_block_pos_y <= r_block_pos_y + 5'd1;
                        end else begin
                            // 固定
                            r_block_fix_req <= 1'b1;
                        end
                    end else begin
                        // 左
                        if (i_snes_state[ 8] & ~r_atari_l_n) r_block_pos_x <= r_block_pos_x - 4'd1;
                        // 右
                        if (i_snes_state[ 7] & ~r_atari_r_n) r_block_pos_x <= r_block_pos_x + 4'd1;
                    end
                end
            end else begin
                r_block_fix_req <= 1'b0;
                r_drop_done <= 1'b0;
            end
        end
    end
    assign w_idata_a[3:0] = r_block_code[3:0];
    assign w_addr_a[8:0] = r_vram_addr[8:0];
    assign w_wen_a = r_wen;

    //==================================================================
    // テトリミノを背景に固定する処理
    //==================================================================
    reg     r_block_fix_req_enter;
    reg     r_block_fix_req_old;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_block_fix_busy <= 1'b0;
            r_block_fix_req_old <= 1'b0;
            r_block_fix_req_enter <= 1'b0;
            r_gameover_trig <= 1'b0;
        end else begin
            // リクエストエッジ検出
            r_block_fix_req_old <= r_block_fix_req;

            if (r_block_fix_req & ~r_block_fix_req_old) begin
                r_block_fix_req_enter <= 1'b1;
            end else if (r_block_fix_req_enter && i_vram_addr == 9'd0 && ~r_block_fix_busy) begin
                r_block_fix_busy <= 1'b1;
                r_block_fix_req_enter <= 1'b0;
            end else if (r_block_fix_busy) begin
                r_wen <= w_blocken_sel_n;
                r_block_code[3:0] <= r_block_ptn[3:0];
                r_vram_addr[8:0] <= i_vram_addr[8:0];

                // 最終アドレスまでスキャンしてたら終了
                if (i_vram_addr == 9'd264) begin
                    r_block_fix_busy <= 1'b0;

                    // ゲームオーバー判定（テトリミノが初期条件の場合）
                    if (r_block_pos_x == INIT_POS_X && r_block_pos_y == INIT_POS_Y && r_block_angle == INIT_ANGLE) begin
                        r_gameover_trig <= 1'b1;
                    end
                end
            end else begin
                r_gameover_trig <= 1'b0;
            end
        end
    end
    assign o_bgm_fixed_pls = r_block_fix_req & ~r_block_fix_req_old;

    //==================================================================
    // ゲームオーバー制御
    //==================================================================
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_gameover_state <= 1'b0;
        end else begin
            if (r_gameover_trig) begin
                // ゲームオーバー状態に遷移
                r_gameover_state <= 1'b1;
            end else if (r_freset_done) begin
                // フィールドクリア完了でゲームオーバー状態解除
                r_gameover_state <= 1'b0;
            end
        end
    end

    //==================================================================
    // ブロック情報格納用DPRAM
    //  - PortA:User Logic
    //  - PortB:LCD Controller、Line消去時の書き込み
    //==================================================================
    Gowin_DP VRAM_inst (
        .douta ( w_odata_a ),       // output [3:0] douta
        .doutb ( w_block_code_ram[3:0] ),// output [3:0] doutb
        .clka ( i_clk ),            // input clka
        .ocea ( 1'b1 ),             // input ocea
        .cea ( 1'b1 ),              // input cea
        .reseta ( ~i_res_n ),       // input reseta
        .wrea ( w_wen_a | r_freset_busy ), // input wrea
        .clkb ( i_clk ),            // input clkb
        .oceb ( 1'b1 ),             // input oceb
        .ceb ( 1'b1 ),              // input ceb
        .resetb ( ~i_res_n ),       // input resetb
        .wreb ( r_wreb ),           // input wreb(ライン消し時に書き込み発生)
        .ada ( r_freset_busy ? w_freset_addr : r_lineRemoveBusy ? w_vram_addr_lineRemove[8:0] : r_vram_addr[8:0] ),  // input [8:0] ada
        .dina ( r_freset_busy ? w_freset_data : w_idata_a[3:0] ),   // input [3:0] dina
        .adb ( r_lineRemoveBusy ? (w_vram_addr_lineRemove[8:0] + 9'd12) : i_vram_addr[8:0] ),  // input [8:0] adb
        .dinb ( w_odata_a )         // input [3:0] dinb (ライン消し時に書き込み発生)
    );

    // 未固定のテトリミノを背景の上に重ねて表示する
    wire    [3:0]   w_all_gray = w_block_code_ram[3:0] != 4'd0 ? 4'd1 : 4'd0;
    assign  o_block_data[3:0] = r_gameover_state ? w_all_gray[3:0] : r_blocken_sel_ff_n ? r_block_ptn[3:0] : w_block_code_ram[3:0];

endmodule
