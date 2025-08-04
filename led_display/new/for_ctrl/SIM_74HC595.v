module SIM_74HC595 (
    input sck,
    input rstn,
    input rck,
    input ser,
    output QS,
    output reg [7:0] out
);
reg [7:0] out_shift;
//级联串行输出
assign QS = out_shift[7];
//移位寄存器
always @(posedge sck or negedge rstn) begin
    if(~rstn) out_shift <= 8'd0;
    else out_shift <= {out_shift[6:0],ser};
end
//存储寄存器
always @(posedge rck or negedge rstn) begin
    if(~rstn) out <= 0;
    else out <= out_shift;
end
endmodule