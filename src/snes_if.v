/********************************************************
* Title    : SNES Controller I/F
* Date     : 2020/09/05
* Design   : kingyo
* Note     : Signal assignment
            - o_btn_state[ 14] : B
            - o_btn_state[ 13] : Y
            - o_btn_state[ 12] : SELECT
            - o_btn_state[ 11] : START
            - o_btn_state[ 10] : UP
            - o_btn_state[  9] : DOWN
            - o_btn_state[  8] : LEFT
            - o_btn_state[  7] : RIGHT
            - o_btn_state[  6] : A
            - o_btn_state[  5] : X
            - o_btn_state[  4] : L
            - o_btn_state[  3] : R
            - o_btn_state[2:0] : Not use
********************************************************/
module snes_if (
    input   wire            i_clk,
    input   wire            i_rst_n,

    output  reg     [14:0]  o_btn_state,
    output  reg             o_btn_state_en,

    output  reg             o_snes_clk,
    output  reg             o_snes_latch,
    input   wire            i_snes_data
    );

    //==================================================================
    // Enable pulse
    //==================================================================
    reg     [9:0]   r_clk_prsc_cnt;
    wire            w_clk_prsc_pls = (r_clk_prsc_cnt == 10'd899);
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n | w_clk_prsc_pls) begin
            r_clk_prsc_cnt <= 10'd0;
        end else begin
            r_clk_prsc_cnt <= r_clk_prsc_cnt + 10'd1;
        end
    end

    //==================================================================
    // Button state acquisition
    //============================================================-======
    reg     [ 2:0]  r_state;
    reg     [ 3:0]  r_clk_cnt;
    reg     [14:0]  r_btn_stat_shift;
    reg     [ 9:0]  r_delay_cnt;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_state <= 3'd0;
            r_clk_cnt <= 4'd0;
            r_btn_stat_shift <= 15'd0;
            r_delay_cnt <= 9'd0;
            o_snes_clk <= 1'b1;
            o_snes_latch <= 1'b0;
            o_btn_state <= 15'd0;
            o_btn_state_en <= 1'b0;
        end else begin
            if (w_clk_prsc_pls) begin
                case (r_state)
                    // Latch
                    3'd0 : begin
                        r_clk_cnt <= 4'd0;
                        o_snes_latch <= 1'b1;
                        r_state <= 3'd1;
                    end

                    3'd1 : begin
                        o_snes_latch <= 1'b0;
                        r_state <= 3'd2;
                    end

                    // Clock Negedge / Data sampling
                    3'd2 : begin
                        o_snes_clk <= 1'b0;
                        r_state <= 3'd3;
                        r_btn_stat_shift <= {r_btn_stat_shift[13:0], ~i_snes_data};
                    end
                    
                    // Clock Posedge
                    3'd3 : begin
                        o_snes_clk <= 1'b1;
                        if (r_clk_cnt == 4'd14) begin
                            r_state <= 3'd4;    // end
                        end else begin
                            r_state <= 3'd2;
                            r_clk_cnt <= r_clk_cnt + 4'd1;
                        end
                    end
                    
                    // end
                    3'd4 : begin
                        o_btn_state <= r_btn_stat_shift;
                        o_btn_state_en <= 1'b1;
                        r_state <= 3'd5;
                    end

                    // Delay to next sampling
                    3'd5 : begin
                        // Delay to next sampling
                        if (r_delay_cnt == 10'd700) begin
                            r_state <= 3'd0;
                            r_delay_cnt <= 10'd0;
                        end else begin
                            r_delay_cnt <= r_delay_cnt + 10'd1;
                        end
                    end
                endcase
            end else begin
                o_btn_state_en <= 1'b0;
            end
        end
    end

endmodule
