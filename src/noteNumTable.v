 /********************************************************
 * Title    : MIDIノート番号 => DDS加算値変換テーブル
 * Date     : 2020/11/07
 * Design   : kingyo
 ********************************************************/
module noteNum_table (
    input   wire            i_clk,
    input   wire            i_res_n,
    input   wire    [ 6:0]  i_noteNum,
    output  reg     [15:0]  o_data
    )/* synthesis syn_romstyle = "block_rom" */;

    always @(posedge i_clk or negedge i_res_n) begin
        if (~i_res_n) begin
            o_data <= 16'd0;
        end else begin
            case (i_noteNum[6:0])
                7'd0 : o_data <= 16'd30;
                7'd1 : o_data <= 16'd32;
                7'd2 : o_data <= 16'd34;
                7'd3 : o_data <= 16'd36;
                7'd4 : o_data <= 16'd38;
                7'd5 : o_data <= 16'd41;
                7'd6 : o_data <= 16'd43;
                7'd7 : o_data <= 16'd46;
                7'd8 : o_data <= 16'd48;
                7'd9 : o_data <= 16'd51;
                7'd10 : o_data <= 16'd54;
                7'd11 : o_data <= 16'd58;
                7'd12 : o_data <= 16'd61;
                7'd13 : o_data <= 16'd65;
                7'd14 : o_data <= 16'd68;
                7'd15 : o_data <= 16'd72;
                7'd16 : o_data <= 16'd77;
                7'd17 : o_data <= 16'd81;
                7'd18 : o_data <= 16'd86;
                7'd19 : o_data <= 16'd91;
                7'd20 : o_data <= 16'd97;
                7'd21 : o_data <= 16'd103;
                7'd22 : o_data <= 16'd109;
                7'd23 : o_data <= 16'd115;
                7'd24 : o_data <= 16'd122;
                7'd25 : o_data <= 16'd129;
                7'd26 : o_data <= 16'd137;
                7'd27 : o_data <= 16'd145;
                7'd28 : o_data <= 16'd154;
                7'd29 : o_data <= 16'd163;
                7'd30 : o_data <= 16'd172;
                7'd31 : o_data <= 16'd183;
                7'd32 : o_data <= 16'd194;
                7'd33 : o_data <= 16'd205;
                7'd34 : o_data <= 16'd217;
                7'd35 : o_data <= 16'd230;
                7'd36 : o_data <= 16'd244;
                7'd37 : o_data <= 16'd258;
                7'd38 : o_data <= 16'd274;
                7'd39 : o_data <= 16'd290;
                7'd40 : o_data <= 16'd307;
                7'd41 : o_data <= 16'd326;
                7'd42 : o_data <= 16'd345;
                7'd43 : o_data <= 16'd365;
                7'd44 : o_data <= 16'd387;
                7'd45 : o_data <= 16'd410;
                7'd46 : o_data <= 16'd434;
                7'd47 : o_data <= 16'd460;
                7'd48 : o_data <= 16'd488;
                7'd49 : o_data <= 16'd517;
                7'd50 : o_data <= 16'd547;
                7'd51 : o_data <= 16'd580;
                7'd52 : o_data <= 16'd614;
                7'd53 : o_data <= 16'd651;
                7'd54 : o_data <= 16'd690;
                7'd55 : o_data <= 16'd731;
                7'd56 : o_data <= 16'd774;
                7'd57 : o_data <= 16'd820;
                7'd58 : o_data <= 16'd869;
                7'd59 : o_data <= 16'd921;
                7'd60 : o_data <= 16'd975;
                7'd61 : o_data <= 16'd1033;
                7'd62 : o_data <= 16'd1095;
                7'd63 : o_data <= 16'd1160;
                7'd64 : o_data <= 16'd1229;
                7'd65 : o_data <= 16'd1302;
                7'd66 : o_data <= 16'd1379;
                7'd67 : o_data <= 16'd1461;
                7'd68 : o_data <= 16'd1548;
                7'd69 : o_data <= 16'd1640;
                7'd70 : o_data <= 16'd1738;
                7'd71 : o_data <= 16'd1841;
                7'd72 : o_data <= 16'd1951;
                7'd73 : o_data <= 16'd2067;
                7'd74 : o_data <= 16'd2190;
                7'd75 : o_data <= 16'd2320;
                7'd76 : o_data <= 16'd2458;
                7'd77 : o_data <= 16'd2604;
                7'd78 : o_data <= 16'd2759;
                7'd79 : o_data <= 16'd2923;
                7'd80 : o_data <= 16'd3097;
                7'd81 : o_data <= 16'd3281;
                7'd82 : o_data <= 16'd3476;
                7'd83 : o_data <= 16'd3683;
                7'd84 : o_data <= 16'd3902;
                7'd85 : o_data <= 16'd4134;
                7'd86 : o_data <= 16'd4379;
                7'd87 : o_data <= 16'd4640;
                7'd88 : o_data <= 16'd4916;
                7'd89 : o_data <= 16'd5208;
                7'd90 : o_data <= 16'd5518;
                7'd91 : o_data <= 16'd5846;
                7'd92 : o_data <= 16'd6193;
                7'd93 : o_data <= 16'd6562;
                7'd94 : o_data <= 16'd6952;
                7'd95 : o_data <= 16'd7365;
                7'd96 : o_data <= 16'd7803;
                7'd97 : o_data <= 16'd8267;
                7'd98 : o_data <= 16'd8759;
                7'd99 : o_data <= 16'd9280;
                7'd100 : o_data <= 16'd9832;
                7'd101 : o_data <= 16'd10416;
                7'd102 : o_data <= 16'd11036;
                7'd103 : o_data <= 16'd11692;
                7'd104 : o_data <= 16'd12387;
                7'd105 : o_data <= 16'd13124;
                7'd106 : o_data <= 16'd13904;
                7'd107 : o_data <= 16'd14731;
                7'd108 : o_data <= 16'd15607;
                7'd109 : o_data <= 16'd16535;
                7'd110 : o_data <= 16'd17518;
                7'd111 : o_data <= 16'd18559;
                7'd112 : o_data <= 16'd19663;
                7'd113 : o_data <= 16'd20832;
                7'd114 : o_data <= 16'd22071;
                7'd115 : o_data <= 16'd23383;
                7'd116 : o_data <= 16'd24774;
                7'd117 : o_data <= 16'd26247;
                7'd118 : o_data <= 16'd27808;
                7'd119 : o_data <= 16'd29461;
                7'd120 : o_data <= 16'd31213;
                7'd121 : o_data <= 16'd33069;
                7'd122 : o_data <= 16'd35036;
                7'd123 : o_data <= 16'd37119;
                7'd124 : o_data <= 16'd39326;
                7'd125 : o_data <= 16'd41665;
                7'd126 : o_data <= 16'd44142;
                7'd127 : o_data <= 16'd46767;
            endcase
        end
    end

endmodule
