module axi_inter_sel41 #(
    parameter N = 2
)(
    input wire [  1:0] sel,
    output reg [N-1:0] out,
    input wire [N-1:0] in0,
    input wire [N-1:0] in1,
    input wire [N-1:0] in2,
    input wire [N-1:0] in3
);
always @(*) begin
    case (sel)
        2'b00: out <= in0;
        2'b01: out <= in1;
        2'b10: out <= in2;
        2'b11: out <= in3;
    endcase
end
endmodule

module axi_inter_sel14 #(
    parameter N = 2
)(
    input wire [  1:0]  sel,
    input wire [N-1:0]   in,
    output reg [N-1:0] out0,
    output reg [N-1:0] out1,
    output reg [N-1:0] out2,
    output reg [N-1:0] out3
);
always @(*) begin
    out0 <= (sel == 2'b00)?(in):(0);
    out1 <= (sel == 2'b01)?(in):(0);
    out2 <= (sel == 2'b10)?(in):(0);
    out3 <= (sel == 2'b11)?(in):(0);
end
endmodule

module axi_inter_nosel #(
    parameter N = 2
)(
    input wire [N-1:0]   in,
    output reg [N-1:0] out0,
    output reg [N-1:0] out1,
    output reg [N-1:0] out2,
    output reg [N-1:0] out3
);
always @(*) begin
    out0 <= in;
    out1 <= in;
    out2 <= in;
    out3 <= in;
end
endmodule