`timescale 1ns / 1ps
module sim_HSV();

reg  [8:0] hue,sat,val;
wire [7:0] R  ,G  ,B;
reg clk;

always #10 clk <= ~clk;

initial begin
    clk = 0;
    hue = 0;
    sat = ~0;
    val = ~0;
end

always #50 hue <= hue+1;
always @(negedge hue[7]) sat <= sat-1;
always @(negedge sat[7]) val <= val-1;

HSV2RGB #(9,8) HSV2RGB_inst(
    .clk    (clk),                    
    .hue    (hue),
    .sat    (sat),
    .val    (val),
    .R      (R  ),
    .G      (G  ),
    .B      (B  ) 
);



endmodule