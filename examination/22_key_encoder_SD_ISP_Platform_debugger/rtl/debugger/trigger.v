module trigger_1bit #(
    parameter PORT_WIDTH   = 32
) (
    input clk,
    input rxclk,
    input rstn,
    input mode_en,
    input [2:0] mode,//8种触发方式
    input testport,
    output reg trig_en
);
reg [2:0] mode_reg;
always @(posedge rxclk or negedge rstn) begin
    if(~rstn)
        mode_reg <= 3'b0;
    else if(mode_en)
        mode_reg <= mode;
    else 
        mode_reg <= mode_reg;
end

//mode: 0   1   2   3   4   5   6
//      x   0   1  up  down
localparam X    = 0;
localparam ZERO = 1;
localparam ONE  = 2;
localparam UP   = 3;
localparam DOWN = 4;
reg testport_d0,testport_d1;
always @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        testport_d0 <= 0;
        testport_d1 <= 0;
    end
    else begin
        testport_d0 <= testport;
        testport_d1 <= testport_d0;
    end
end
//或许应该用组合逻辑？
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        trig_en <= 1;
    else 
        case (mode_reg)
            X :         trig_en <= 1;
            ZERO :      trig_en <= ~testport;
            ONE :       trig_en <= testport;
            UP :        trig_en <= testport_d0 && ~testport_d1;
            DOWN :      trig_en <= ~testport_d0 && testport_d1;
            default:    trig_en <= 1;
        endcase
end
endmodule