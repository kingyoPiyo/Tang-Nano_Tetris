//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.2.02Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Sat Sep 05 19:18:24 2020

module Gowin_DP (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb, wreb, ada, dina, adb, dinb);

output [3:0] douta;
output [3:0] doutb;
input clka;
input ocea;
input cea;
input reseta;
input wrea;
input clkb;
input oceb;
input ceb;
input resetb;
input wreb;
input [8:0] ada;
input [3:0] dina;
input [8:0] adb;
input [3:0] dinb;

wire gw_gnd;

assign gw_gnd = 1'b0;

DP dp_inst_0 (
    .DOA(douta[3:0]),
    .DOB(doutb[3:0]),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSEL({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,gw_gnd,ada[8:0],gw_gnd,gw_gnd}),
    .DIA(dina[3:0]),
    .ADB({gw_gnd,gw_gnd,gw_gnd,adb[8:0],gw_gnd,gw_gnd}),
    .DIB(dinb[3:0])
);

defparam dp_inst_0.READ_MODE0 = 1'b0;
defparam dp_inst_0.READ_MODE1 = 1'b0;
defparam dp_inst_0.WRITE_MODE0 = 2'b00;
defparam dp_inst_0.WRITE_MODE1 = 2'b00;
defparam dp_inst_0.BIT_WIDTH_0 = 4;
defparam dp_inst_0.BIT_WIDTH_1 = 4;
defparam dp_inst_0.BLK_SEL = 3'b000;
defparam dp_inst_0.RESET_MODE = "SYNC";
defparam dp_inst_0.INIT_RAM_00 = 256'h0001100000000001100000000001100000000001100000000001111000000111;
defparam dp_inst_0.INIT_RAM_01 = 256'h0000000110000000000110000000000110000000000110000000000110000000;
defparam dp_inst_0.INIT_RAM_02 = 256'h1000000000011000000000011000000000011000000000011000000000011000;
defparam dp_inst_0.INIT_RAM_03 = 256'h1111100000000001100000000001100000000001100000000001100000000001;
defparam dp_inst_0.INIT_RAM_04 = 256'h0000000000000000000000000000000000000000000000000000000011111111;

endmodule //Gowin_DP
