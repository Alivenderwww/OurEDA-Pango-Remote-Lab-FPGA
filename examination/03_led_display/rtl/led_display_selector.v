module led_display_selector #(
    parameter [7:0]  NUM = 4,
    parameter [0:0]  VALID_SIGNAL = 1'b0,
    parameter [31:0] CLK_CYCLE = 1000
)(
    input  wire             clk,
    input  wire             rstn,
    input  wire [NUM*8-1:0] led_in,
    output  reg [7:0]       led_display_seg,//[DP,G,F,E,D,C,B,A]
    output  reg [NUM-1:0]   led_display_sel
);

reg [31:0] clk_cnt;
always @(posedge clk or negedge rstn) begin
    if (!rstn) clk_cnt <= 0;
    else if(clk_cnt == CLK_CYCLE) clk_cnt <= 0;
    else clk_cnt <= clk_cnt + 1;
end

wire seg_change = (clk_cnt == CLK_CYCLE) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rstn) begin
    if(!rstn) led_display_sel <= {{(NUM-1){~VALID_SIGNAL}}, VALID_SIGNAL};
    else if (seg_change) led_display_sel <= {led_display_sel[NUM-2:0], led_display_sel[NUM-1]};
    else led_display_sel <= led_display_sel;
end

integer i;
always @(*) begin
    for(i=0;i<NUM;i=i+1) begin
        if(led_display_sel[NUM-1-i] == VALID_SIGNAL)
            led_display_seg = led_in[i*8 +: 8] ^ ({8{~VALID_SIGNAL}});
    end
end

endmodule //led_display_ctrl