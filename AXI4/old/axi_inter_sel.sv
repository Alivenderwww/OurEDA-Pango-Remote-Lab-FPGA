module axi_inter_sel41 #(
    parameter IN_WIDTH = 2,
    parameter N = 2
)(
    input  wire [IN_WIDTH-1:0] sel,
    output wire [N-1:0]        out,
    input  wire [N-1:0]        inx[0:(2**IN_WIDTH-1)]
);
assign out = inx[sel];
endmodule

module axi_inter_sel14 #(
    parameter OUT_WIDTH = 2,
    parameter N = 2
)(
    input wire [OUT_WIDTH-1:0]  sel,
    input wire [N-1:0]          in,
    output reg [N-1:0]          outx [0:(2**OUT_WIDTH)-1]
);

always_comb begin
    foreach(outx[i]) outx[i] = {N{1'b0}};
    for(int i=0; i<(2**OUT_WIDTH); i++) begin
        if(sel == i) begin
            outx[i] = in; // 选中通道输出输入信号
        end
    end
end

endmodule

module axi_inter_nosel #(
    parameter OUT_WIDTH = 2,
    parameter N = 2
)(
    input wire [N-1:0]   in,
    output reg [N-1:0] outx[0:(2**OUT_WIDTH)-1]
);
always_comb begin
    foreach(outx[i]) outx[i] = in;
end

endmodule