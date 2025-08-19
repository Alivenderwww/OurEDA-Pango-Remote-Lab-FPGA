`timescale 1ns / 1ps
module sim();

reg clk, rstn;
wire data_stream;

always #10 clk <= ~clk;

initial begin
    clk = 0;
    rstn = 1;
    #100
    rstn = 0;
    #5000
    rstn = 1;
end

wire [23:0] wscolor[16];

ws_ctrl_top top_inst(
    .external_clk(clk),
    .external_rstn(rstn),
    .dataout(data_stream)
);

Recv #(
    .WS_NUM(16)
) recv_inst(
    .clk(clk),
    .rstn(rstn),
    .data_stream(data_stream),
    .wscolor(wscolor)
);



endmodule