/********************************************************
* Title    : Sound Generator
* Date     : 2020/11/07
* Design   : kingyo
********************************************************/
module soundGen (
    input   wire        i_clk,          // 9MHz
    input   wire        i_res_n,
    input   wire        i_fixed_pls,    // テトリミノ固定時の効果音
    output  wire        o_sound         // delta-sigma DAC OUTPUT
);

    reg     [ 9:0]      r_bgmRomAddr;   // BGM-ROM Read address
    wire    [31:0]      w_bgmRomData;   // BGM-ROM Read data
    wire    [15:0]      w_ddsAddVal;    // DDS Addition value
    reg     [15:0]      r_ddsAddVal1;   // DDS CH1 Addition value
    reg     [15:0]      r_ddsAddVal2;   // DDS CH2 Addition value
    reg                 r_ddsCh1Mute;   // DDS CH1 mute
    reg                 r_ddsCh2Mute;   // DDS CH2 mute

    //==================================================================
    // 1ms enable pulse
    //==================================================================
    reg     [14:0]  r_1msEnableCounter;
    wire            w_1msEnablePls = (r_1msEnableCounter == 14'd8999);
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n | w_1msEnablePls) begin
            r_1msEnableCounter <= 14'd0;
        end else begin
            r_1msEnableCounter <= r_1msEnableCounter + 14'd1;
        end
    end

    //==================================================================
    // BGM ROM
    //==================================================================
    bgm_rom bgm_rom_inst (
        .i_clk ( i_clk ),
        .i_res_n ( i_res_n ),
        .i_addr ( r_bgmRomAddr[9:0] ),
        .o_data ( w_bgmRomData[31:0] )
    );

    //==================================================================
    // BGM ROM controller
    //==================================================================
    reg             r_bgmRomCtrlState;
    reg     [15:0]  r_delayCounterMs;
    reg     [6:0]   r_noteNumCh1;
    reg     [6:0]   r_noteNumCh2;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_bgmRomCtrlState <= 1'd0;
            r_delayCounterMs <= 16'd0;
            r_bgmRomAddr <= 10'd0;
            r_ddsCh1Mute <= 1'b1;
            r_ddsCh2Mute <= 1'b1;
            r_ddsAddVal1 <= 16'd0;
            r_ddsAddVal2 <= 16'd0;
        end else begin
            case (r_bgmRomCtrlState)
                1'd0 : begin
                    // DeltaTime Delay
                    if (w_1msEnablePls) begin
                        if (r_delayCounterMs[15:0] == w_bgmRomData[31:16]) begin
                            r_bgmRomCtrlState <= 1'd1;
                            r_bgmRomAddr <= r_bgmRomAddr + 10'd1;
                        end else begin
                            r_delayCounterMs <= r_delayCounterMs + 16'd1;
                        end
                    end
                end

                1'd1 : begin
                    if (w_bgmRomData[15:12] == 4'd9) begin
                        // Note ON
                        if (w_bgmRomData[11:8] == 4'd0) begin
                            r_ddsAddVal1 <= w_ddsAddVal;
                            r_ddsCh1Mute <= 1'b0;
                        end else begin
                            r_ddsAddVal2 <= w_ddsAddVal;
                            r_ddsCh2Mute <= 1'b0;
                        end
                    end else if (w_bgmRomData[15:12] == 4'd8) begin
                        // Note OFF
                        if (w_bgmRomData[11:8] == 4'd0) begin
                            r_ddsCh1Mute <= 1'b1;
                        end else begin
                            r_ddsCh2Mute <= 1'b1;
                        end
                    end
                    r_bgmRomCtrlState <= 2'd0;
                    r_delayCounterMs <= 16'd0;
                end
            endcase
        end
    end

    //==================================================================
    // Conversion table from MIDI note number to DDS addition value
    //==================================================================
    noteNum_table noteNum_table_inst (
        .i_clk ( i_clk ),
        .i_res_n ( i_res_n ),
        .i_noteNum ( w_bgmRomData[6:0] ),
        .o_data ( w_ddsAddVal[15:0] )
    );

    //==================================================================
    // DDS
    // - IN Clock  : 35156.25Hz(9MHz / 256)
    // - Acc bits  : 17bit
    // - Add bits  : 16bit
    // - Freq reso : 0.26822Hz
    //==================================================================
    // DDS Sampling Timing
    reg     [7:0]   r_ddsPrscCounter;
    wire            w_ddsCounterEn = (r_ddsPrscCounter == 8'hFF);
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_ddsPrscCounter <= 8'd0;
        end else begin
            r_ddsPrscCounter <= r_ddsPrscCounter + 8'd1;
        end
    end

    // Phase accumulator
    reg     [16:0]  r_ddsAccCh1;
    reg     [16:0]  r_ddsAccCh2;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_ddsAccCh1 <= 17'd0;
            r_ddsAccCh2 <= 17'd0;
        end else if (w_ddsCounterEn) begin
            r_ddsAccCh1 <= r_ddsAccCh1 + {1'd0, r_ddsAddVal1};
            r_ddsAccCh2 <= r_ddsAccCh2 + {1'd0, r_ddsAddVal2};
        end
    end    

    //==================================================================
    // Noise Generator
    //==================================================================
    // Oneshot Timer
    reg         r_noise_en;
    reg [7:0]   r_noiseGateCounter;
    wire        w_noiseGateCouterClr = (r_noiseGateCounter == 8'd99);
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_noiseGateCounter <= 8'd0;
            r_noise_en <= 1'b0;
        end else if (i_fixed_pls) begin
            r_noiseGateCounter <= 8'd0;
            r_noise_en <= 1'b1;
        end else if (w_1msEnablePls) begin
            if (w_noiseGateCouterClr) begin
                r_noise_en <= 1'b0;
            end else begin
                r_noiseGateCounter <= r_noiseGateCounter + 8'd1;
            end
        end
    end
    
    // White Noise(LFSR)
    reg [31:0]  r_lfsr;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_lfsr <= 32'd1234; // seed
        end else begin
            if (w_1msEnablePls) begin
                r_lfsr <= (r_lfsr >> 1) | (r_lfsr[31] ^ r_lfsr[2] ^ r_lfsr[1] ^ 1'b1) << 15;
            end
        end
    end
    wire signed [5:0]   w_NoiseOut = r_noise_en ? r_lfsr[5:0] + $signed(-32) : 6'd0;

    //==================================================================
    // Waveform summation
    //==================================================================
    wire signed [5:0]   w_soundCh1 = r_ddsCh1Mute ? 6'd0 : r_ddsAccCh1[16] ? $signed(15) : $signed(-15);
    wire signed [5:0]   w_soundCh2 = r_ddsCh2Mute ? 6'd0 : r_ddsAccCh2[16] ? $signed(15) : $signed(-15);
    wire        [7:0]   w_dac_data = {{2{w_soundCh1[5]}}, w_soundCh1} +
                                     {{2{w_soundCh2[5]}}, w_soundCh2} +
                                     {w_NoiseOut[5], w_NoiseOut, 1'b0} + 
                                     $signed(128);
    
    //==================================================================
    // Delta-Sigma DAC OUTPUT
    //==================================================================
    reg     [8:0]    r_sigma;
    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            r_sigma <= 0;
        end else begin
            r_sigma <= r_sigma[7:0] + w_dac_data[7:0];
        end
    end
    assign  o_sound = r_sigma[8];
    
endmodule
