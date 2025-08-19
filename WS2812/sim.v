`timescale 1ns / 1ps
module sim();

reg clk, rst;
wire data_stream;

always #20 clk <= ~clk;

initial begin
    clk = 0;
    rst = 0;
    #100
    rst = 1;
    #5000
    rst = 0;
end


top top_inst(
    .sys_clk(clk),
    .rst(rst),
    .dataout(data_stream)
);



endmodule